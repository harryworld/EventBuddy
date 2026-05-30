/**
 * The CLI emits SQLite timestamps like "2025-06-07 16:00:00.000" (UTC, no zone).
 * Parse them into a Date, treating the value as UTC.
 */
export function parseCliDate(value: string | null | undefined): Date | null {
  if (!value) return null;
  const normalized = value.trim().replace(" ", "T");
  const withZone = /[zZ]|[+-]\d{2}:?\d{2}$/.test(normalized)
    ? normalized
    : `${normalized}Z`;
  const date = new Date(withZone);
  return Number.isNaN(date.getTime()) ? null : date;
}

export function formatDateTime(value: string | null | undefined): string {
  const date = parseCliDate(value);
  if (!date) return value ?? "";
  return date.toLocaleString(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  });
}

export function formatDate(value: string | null | undefined): string {
  const date = parseCliDate(value);
  if (!date) return value ?? "";
  return date.toLocaleDateString(undefined, { dateStyle: "medium" });
}

export function getYear(value: string | null | undefined): string | null {
  const date = parseCliDate(value);
  if (!date) return null;
  return String(date.getFullYear());
}
