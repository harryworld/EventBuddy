import {
  Action,
  ActionPanel,
  Alert,
  Color,
  confirmAlert,
  Icon,
  List,
  showToast,
  Toast,
} from "@raycast/api";
import { useState } from "react";
import { useAsync } from "./lib/use-async";
import { runJson, runRaw } from "./lib/cli";
import { RelationRow, RelationshipKind } from "./lib/types";

type KindFilter = "all" | RelationshipKind;

const KIND_META: Record<
  RelationshipKind,
  { label: string; icon: Icon; color: Color }
> = {
  attending: { label: "Attending", icon: Icon.CheckCircle, color: Color.Green },
  wish: { label: "Wishlist", icon: Icon.Star, color: Color.Yellow },
};

export default function BrowseRelations() {
  return <RelationsList />;
}

export function RelationsList({
  eventId,
  friendId,
  navigationTitle,
}: {
  eventId?: string;
  friendId?: string;
  navigationTitle?: string;
}) {
  const [kind, setKind] = useState<KindFilter>("all");
  const scopedToEvent = Boolean(eventId);

  const { data, isLoading, revalidate } = useAsync(
    async () => {
      const args = ["relation", "list"];
      if (kind !== "all") args.push("--kind", kind);
      if (eventId) args.push("--event-id", eventId);
      if (friendId) args.push("--friend-id", friendId);
      return runJson<RelationRow[]>(args);
    },
    [kind, eventId, friendId],
    {
      onError: (error) => {
        showToast({
          style: Toast.Style.Failure,
          title: "Failed to load relations",
          message: error.message,
        });
      },
    },
  );

  const relations = data ?? [];

  async function unlink(relation: RelationRow) {
    const confirmed = await confirmAlert({
      title: "Remove Relation?",
      message: `Unlink ${relation.friendName ?? relation.friendId} from ${relation.eventTitle ?? relation.eventId}.`,
      primaryAction: { title: "Unlink", style: Alert.ActionStyle.Destructive },
    });
    if (!confirmed) return;

    const toast = await showToast({
      style: Toast.Style.Animated,
      title: "Unlinking…",
      message: "Waiting for WWDCBuddy to process the command.",
    });
    try {
      await runRaw([
        "relation",
        "unlink",
        relation.eventId,
        relation.friendId,
        "--kind",
        relation.kind,
      ]);
      toast.style = Toast.Style.Success;
      toast.title = "Relation removed";
      toast.message = undefined;
      revalidate();
    } catch (error) {
      toast.style = Toast.Style.Failure;
      toast.title = "Failed to unlink";
      toast.message = error instanceof Error ? error.message : String(error);
    }
  }

  return (
    <List
      isLoading={isLoading}
      navigationTitle={navigationTitle}
      searchBarPlaceholder="Search by event or friend…"
      searchBarAccessory={
        <List.Dropdown
          tooltip="Relationship Kind"
          value={kind}
          onChange={(value) => setKind(value as KindFilter)}
        >
          <List.Dropdown.Item title="All" value="all" />
          <List.Dropdown.Item
            title="Attending"
            value="attending"
            icon={Icon.CheckCircle}
          />
          <List.Dropdown.Item title="Wishlist" value="wish" icon={Icon.Star} />
        </List.Dropdown>
      }
    >
      <List.EmptyView title="No Relations" icon={Icon.TwoPeople} />
      {relations.map((relation) => {
        const meta = KIND_META[relation.kind];
        return (
          <List.Item
            key={`${relation.kind}-${relation.id}`}
            title={
              scopedToEvent
                ? (relation.friendName ?? relation.friendId)
                : (relation.eventTitle ?? relation.eventId)
            }
            subtitle={
              scopedToEvent
                ? undefined
                : (relation.friendName ?? relation.friendId)
            }
            keywords={[
              relation.eventTitle ?? "",
              relation.friendName ?? "",
            ].filter(Boolean)}
            icon={{ source: meta.icon, tintColor: meta.color }}
            accessories={[{ tag: { value: meta.label, color: meta.color } }]}
            actions={
              <ActionPanel>
                <Action
                  title="Unlink Relation"
                  icon={Icon.Trash}
                  style={Action.Style.Destructive}
                  onAction={() => unlink(relation)}
                />
                <Action.CopyToClipboard
                  title="Copy Event Id"
                  content={relation.eventId}
                  icon={Icon.Calendar}
                />
                <Action.CopyToClipboard
                  title="Copy Friend Id"
                  content={relation.friendId}
                  icon={Icon.Person}
                />
                <Action
                  title="Reload"
                  icon={Icon.ArrowClockwise}
                  shortcut={{ modifiers: ["cmd"], key: "r" }}
                  onAction={revalidate}
                />
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}
