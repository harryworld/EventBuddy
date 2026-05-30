import {
  Action,
  ActionPanel,
  Color,
  Icon,
  List,
  showToast,
  Toast,
} from "@raycast/api";
import { useMemo, useState } from "react";
import { useAsync } from "./lib/use-async";
import { runJson } from "./lib/cli";
import { EventRow } from "./lib/types";
import { formatDate, formatDateTime, getYear } from "./lib/format";
import { RelationsList } from "./browse-relations";

export default function SearchEvents() {
  const [year, setYear] = useState<string>("all");
  const [attendingOnly, setAttendingOnly] = useState(false);

  const { data, isLoading, revalidate } = useAsync(
    async () => runJson<EventRow[]>(["event", "list"]),
    [],
    {
      onError: (error) => {
        showToast({
          style: Toast.Style.Failure,
          title: "Failed to load events",
          message: error.message,
        });
      },
    },
  );

  const events = data ?? [];

  const years = useMemo(() => {
    const set = new Set<string>();
    for (const event of events) {
      const value = getYear(event.startDate);
      if (value) set.add(value);
    }
    return Array.from(set).sort((a, b) => Number(b) - Number(a));
  }, [events]);

  const filtered = useMemo(
    () =>
      events.filter((event) => {
        if (year !== "all" && getYear(event.startDate) !== year) return false;
        if (attendingOnly && !event.isAttending) return false;
        return true;
      }),
    [events, year, attendingOnly],
  );

  const toggleAttending = () => setAttendingOnly((value) => !value);

  const activeFilters = [
    attendingOnly ? "Attending" : null,
    year !== "all" ? year : null,
  ].filter(Boolean);
  const navigationTitle = activeFilters.length
    ? `Events · ${activeFilters.join(" · ")}`
    : "Events";

  return (
    <List
      isLoading={isLoading}
      navigationTitle={navigationTitle}
      searchBarPlaceholder="Search events by title, location, type…"
      isShowingDetail
      searchBarAccessory={
        <List.Dropdown
          tooltip="Filter by Year"
          value={year}
          onChange={setYear}
          storeValue
        >
          <List.Dropdown.Item
            title="All Years"
            value="all"
            icon={Icon.Calendar}
          />
          <List.Dropdown.Section title="Year">
            {years.map((value) => (
              <List.Dropdown.Item key={value} title={value} value={value} />
            ))}
          </List.Dropdown.Section>
        </List.Dropdown>
      }
    >
      <List.EmptyView
        title="No Events"
        description="No events match your filters."
        icon={Icon.Calendar}
      />
      {filtered.map((event) => (
        <EventItem
          key={event.id}
          event={event}
          attendingOnly={attendingOnly}
          onToggleAttending={toggleAttending}
          onReload={revalidate}
        />
      ))}
    </List>
  );
}

function EventItem({
  event,
  attendingOnly,
  onToggleAttending,
  onReload,
}: {
  event: EventRow;
  attendingOnly: boolean;
  onToggleAttending: () => void;
  onReload: () => void;
}) {
  const keywords = [
    event.location,
    event.eventType,
    event.address ?? "",
  ].filter(Boolean);

  return (
    <List.Item
      title={event.title}
      keywords={keywords}
      icon={
        event.isAttending
          ? { source: Icon.CheckCircle, tintColor: Color.Green }
          : { source: Icon.Calendar, tintColor: Color.SecondaryText }
      }
      accessories={[
        { tag: { value: formatDate(event.startDate), color: Color.Blue } },
      ]}
      detail={<EventDetail event={event} />}
      actions={
        <ActionPanel>
          <Action.Push
            title="Show Attendees"
            icon={Icon.TwoPeople}
            target={
              <RelationsList eventId={event.id} navigationTitle={event.title} />
            }
          />
          <Action
            title={attendingOnly ? "Show All Events" : "Show Attending Only"}
            icon={attendingOnly ? Icon.Calendar : Icon.CheckCircle}
            shortcut={{ modifiers: ["cmd", "shift"], key: "a" }}
            onAction={onToggleAttending}
          />
          {event.url ? <Action.OpenInBrowser url={event.url} /> : null}
          <Action.CopyToClipboard
            title="Copy Event Id"
            content={event.id}
            icon={Icon.Clipboard}
          />
          <Action.CopyToClipboard
            title="Copy Title"
            content={event.title}
            shortcut={{ modifiers: ["cmd", "shift"], key: "." }}
          />
          <Action
            title="Reload"
            icon={Icon.ArrowClockwise}
            shortcut={{ modifiers: ["cmd"], key: "r" }}
            onAction={onReload}
          />
        </ActionPanel>
      }
    />
  );
}

function EventDetail({ event }: { event: EventRow }) {
  const md = [
    `# ${event.title}`,
    "",
    event.eventDescription || "_No description._",
  ];
  if (event.notes) {
    md.push("", "## Notes", event.notes);
  }

  return (
    <List.Item.Detail
      markdown={md.join("\n")}
      metadata={
        <List.Item.Detail.Metadata>
          <List.Item.Detail.Metadata.TagList title="Status">
            {event.isAttending ? (
              <List.Item.Detail.Metadata.TagList.Item
                text="Attending"
                color={Color.Green}
              />
            ) : (
              <List.Item.Detail.Metadata.TagList.Item
                text="Not Attending"
                color={Color.SecondaryText}
              />
            )}
            {event.isCustomEvent ? (
              <List.Item.Detail.Metadata.TagList.Item
                text="Custom"
                color={Color.Purple}
              />
            ) : null}
          </List.Item.Detail.Metadata.TagList>
          <List.Item.Detail.Metadata.Label
            title="Type"
            text={event.eventType}
          />
          <List.Item.Detail.Metadata.Label
            title="Starts"
            text={formatDateTime(event.startDate)}
          />
          <List.Item.Detail.Metadata.Label
            title="Ends"
            text={formatDateTime(event.endDate)}
          />
          {event.originalTimezoneIdentifier ? (
            <List.Item.Detail.Metadata.Label
              title="Timezone"
              text={event.originalTimezoneIdentifier}
            />
          ) : null}
          <List.Item.Detail.Metadata.Separator />
          <List.Item.Detail.Metadata.Label
            title="Location"
            text={event.location || "—"}
          />
          {event.address ? (
            <List.Item.Detail.Metadata.Label
              title="Address"
              text={event.address}
            />
          ) : null}
          <List.Item.Detail.Metadata.Separator />
          <List.Item.Detail.Metadata.Label
            title="Requires Ticket"
            icon={event.requiresTicket ? Icon.Checkmark : Icon.Minus}
          />
          <List.Item.Detail.Metadata.Label
            title="Requires Registration"
            icon={event.requiresRegistration ? Icon.Checkmark : Icon.Minus}
          />
          {event.url ? (
            <List.Item.Detail.Metadata.Link
              title="URL"
              text={event.url}
              target={event.url}
            />
          ) : null}
        </List.Item.Detail.Metadata>
      }
    />
  );
}
