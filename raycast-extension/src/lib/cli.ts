import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { getPreferenceValues } from "@raycast/api";

const execFileAsync = promisify(execFile);

interface Preferences {
  cliPath?: string;
  databasePath?: string;
}

const COMMON_BIN_DIRS = [
  join(homedir(), ".local", "bin"),
  "/opt/homebrew/bin",
  "/usr/local/bin",
  "/usr/bin",
];

/** Expand a leading `~` to the user's home directory. */
function expandHome(path: string): string {
  if (path === "~") return homedir();
  if (path.startsWith("~/")) return join(homedir(), path.slice(2));
  return path;
}

/**
 * Resolve the absolute path to the wwdcbuddy binary. Raycast spawns processes
 * without the user's interactive shell PATH, so we resolve known locations
 * ourselves when the preference is a bare command name.
 */
export function resolveCliPath(): string {
  const { cliPath } = getPreferenceValues<Preferences>();
  const configured = (cliPath ?? "wwdcbuddy").trim() || "wwdcbuddy";

  if (configured.includes("/")) {
    return expandHome(configured);
  }

  for (const dir of COMMON_BIN_DIRS) {
    const candidate = join(dir, configured);
    if (existsSync(candidate)) {
      return candidate;
    }
  }

  // Fall back to the bare name and let the OS resolve it.
  return configured;
}

function buildEnv(): NodeJS.ProcessEnv {
  const { databasePath } = getPreferenceValues<Preferences>();
  const env = { ...process.env };
  const trimmed = databasePath?.trim();
  if (trimmed) {
    env.EVENTBUDDY_DATABASE_PATH = expandHome(trimmed);
  }
  // Ensure common locations are on PATH for the spawned process.
  env.PATH = [...COMMON_BIN_DIRS, env.PATH ?? ""].filter(Boolean).join(":");
  return env;
}

export class CliError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CliError";
  }
}

/** Run the CLI and parse its JSON output. */
export async function runJson<T>(args: string[]): Promise<T> {
  const stdout = await runRaw([...args, "--json"]);
  try {
    return JSON.parse(stdout) as T;
  } catch {
    throw new CliError("Could not parse CLI output as JSON.");
  }
}

/** Run the CLI and return raw stdout. */
export async function runRaw(args: string[]): Promise<string> {
  const bin = resolveCliPath();
  try {
    const { stdout } = await execFileAsync(bin, args, {
      env: buildEnv(),
      maxBuffer: 16 * 1024 * 1024,
      timeout: 60_000,
    });
    return stdout;
  } catch (error) {
    throw new CliError(formatCliError(error, bin));
  }
}

function formatCliError(error: unknown, bin: string): string {
  const err = error as NodeJS.ErrnoException & { stderr?: string };
  if (err?.code === "ENOENT") {
    return `Could not find the wwdcbuddy CLI at "${bin}". Install it from the WWDCBuddy app (Settings > Data & CLI) or set the CLI path in this extension's preferences.`;
  }
  const stderr = (err?.stderr ?? "").trim();
  if (stderr) {
    return stderr.replace(/^error:\s*/i, "");
  }
  return err?.message ?? "The wwdcbuddy CLI failed.";
}
