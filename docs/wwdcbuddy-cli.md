# WWDCBuddy CLI

The macOS app bundles `wwdcbuddy`, a Rust command line tool for reading and updating WWDCBuddy data.

## Install

Open WWDCBuddy on macOS, go to Settings > Data & CLI, then choose Install CLI. The app installs `wwdcbuddy` into `~/.local/bin` by default; sandboxed builds may ask you to confirm that folder.

Make sure the install folder is on your shell path:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

To uninstall the command, choose Remove CLI in the same settings section. This removes the installed shim only; the CLI helper remains bundled inside WWDCBuddy.

## Read Data

```sh
wwdcbuddy event list
wwdcbuddy event list --favorites
wwdcbuddy friend list
wwdcbuddy friend get <friend-id>
wwdcbuddy relation list
wwdcbuddy relation list --event-id <event-id>
wwdcbuddy relation list --friend-id <friend-id>
```

Add `--json` to any command for machine-readable output.
For events, `--favorites` lists events marked as attending in WWDCBuddy.

## Update Data

Updates are queued to the Mac app instead of writing app tables directly. The app performs the save through `EventPersistenceService`, then asks SQLiteData/CloudKit to push local changes if iCloud sync is enabled.

```sh
wwdcbuddy friend update <friend-id> --company "Apple" --job-title "Developer"
wwdcbuddy friend update <friend-id> --favorite true --social github=harryworld
wwdcbuddy relation link <event-id> <friend-id> --kind attending
wwdcbuddy relation unlink <event-id> <friend-id> --kind wish
```

By default, mutating commands wait up to 15 seconds for WWDCBuddy to process the command. Use `--no-wait` to only queue the command.

## Database Path

The default database is:

```text
~/Library/Group Containers/group.com.buildwithharry.EventBuddy/EventBuddy.sqlite
```

Override it for read commands with `--database` or `EVENTBUDDY_DATABASE_PATH`.
