import {
  Action,
  ActionPanel,
  Color,
  Form,
  Icon,
  List,
  showToast,
  Toast,
  useNavigation,
} from "@raycast/api";
import { useState } from "react";
import { useAsync } from "./lib/use-async";
import { runJson, runRaw } from "./lib/cli";
import { FriendRow } from "./lib/types";
import { formatDateTime } from "./lib/format";
import { RelationsList } from "./browse-relations";

type Filter = "all" | "favorites";

export default function SearchFriends() {
  const [filter, setFilter] = useState<Filter>("all");
  const favoritesOnly = filter === "favorites";
  const { data, isLoading, revalidate } = useAsync(
    async () => {
      const args = ["friend", "list"];
      if (favoritesOnly) args.push("--favorites");
      return runJson<FriendRow[]>(args);
    },
    [favoritesOnly],
    {
      onError: (error) => {
        showToast({
          style: Toast.Style.Failure,
          title: "Failed to load friends",
          message: error.message,
        });
      },
    },
  );

  const friends = data ?? [];

  return (
    <List
      isLoading={isLoading}
      isShowingDetail
      searchBarPlaceholder="Search friends by name, company, title…"
      searchBarAccessory={
        <List.Dropdown
          tooltip="Filter"
          value={filter}
          onChange={(value) => setFilter(value as Filter)}
        >
          <List.Dropdown.Item title="All Friends" value="all" />
          <List.Dropdown.Item title="Favorites" value="favorites" />
        </List.Dropdown>
      }
    >
      <List.EmptyView title="No Friends" icon={Icon.PersonCircle} />
      {friends.map((friend) => (
        <FriendItem key={friend.id} friend={friend} onReload={revalidate} />
      ))}
    </List>
  );
}

function FriendItem({
  friend,
  onReload,
}: {
  friend: FriendRow;
  onReload: () => void;
}) {
  const subtitleParts = [friend.jobTitle, friend.company].filter(Boolean);
  const keywords = [
    friend.company ?? "",
    friend.jobTitle ?? "",
    friend.email ?? "",
  ].filter(Boolean);

  return (
    <List.Item
      title={friend.name}
      keywords={keywords}
      icon={
        friend.isFavorite
          ? { source: Icon.Star, tintColor: Color.Yellow }
          : { source: Icon.Person, tintColor: Color.SecondaryText }
      }
      accessories={
        subtitleParts.length ? [{ text: subtitleParts.join(" · ") }] : undefined
      }
      detail={<FriendDetail friend={friend} />}
      actions={<FriendActions friend={friend} onReload={onReload} />}
    />
  );
}

function FriendDetail({ friend }: { friend: FriendRow }) {
  const social = Object.entries(friend.socialMediaHandles ?? {});
  const md = [`# ${friend.name}`];
  if (friend.notes) {
    md.push("", "## Notes", friend.notes);
  }

  return (
    <List.Item.Detail
      markdown={md.join("\n")}
      metadata={
        <List.Item.Detail.Metadata>
          <List.Item.Detail.Metadata.Label
            title="Favorite"
            icon={
              friend.isFavorite
                ? { source: Icon.Star, tintColor: Color.Yellow }
                : Icon.Minus
            }
          />
          {friend.company ? (
            <List.Item.Detail.Metadata.Label
              title="Company"
              text={friend.company}
            />
          ) : null}
          {friend.jobTitle ? (
            <List.Item.Detail.Metadata.Label
              title="Title"
              text={friend.jobTitle}
            />
          ) : null}
          <List.Item.Detail.Metadata.Separator />
          {friend.email ? (
            <List.Item.Detail.Metadata.Link
              title="Email"
              text={friend.email}
              target={`mailto:${friend.email}`}
            />
          ) : null}
          {friend.phone ? (
            <List.Item.Detail.Metadata.Label
              title="Phone"
              text={friend.phone}
            />
          ) : null}
          {social.length ? (
            <>
              <List.Item.Detail.Metadata.Separator />
              {social.map(([platform, handle]) => (
                <List.Item.Detail.Metadata.Label
                  key={platform}
                  title={platform}
                  text={handle}
                />
              ))}
            </>
          ) : null}
          <List.Item.Detail.Metadata.Separator />
          <List.Item.Detail.Metadata.Label
            title="Updated"
            text={formatDateTime(friend.updatedAt)}
          />
        </List.Item.Detail.Metadata>
      }
    />
  );
}

function FriendActions({
  friend,
  onReload,
}: {
  friend: FriendRow;
  onReload: () => void;
}) {
  async function toggleFavorite() {
    const next = !friend.isFavorite;
    const toast = await showToast({
      style: Toast.Style.Animated,
      title: next ? "Adding to favorites…" : "Removing from favorites…",
      message: "Waiting for WWDCBuddy to process the command.",
    });
    try {
      await runRaw(["friend", "update", friend.id, "--favorite", String(next)]);
      toast.style = Toast.Style.Success;
      toast.title = next ? "Marked as favorite" : "Removed from favorites";
      toast.message = undefined;
      onReload();
    } catch (error) {
      toast.style = Toast.Style.Failure;
      toast.title = "Update failed";
      toast.message = error instanceof Error ? error.message : String(error);
    }
  }

  return (
    <ActionPanel>
      <Action.Push
        title="Edit Friend"
        icon={Icon.Pencil}
        target={<EditFriendForm friend={friend} onSaved={onReload} />}
      />
      <Action
        title={friend.isFavorite ? "Remove from Favorites" : "Mark as Favorite"}
        icon={friend.isFavorite ? Icon.StarDisabled : Icon.Star}
        shortcut={{ modifiers: ["cmd"], key: "f" }}
        onAction={toggleFavorite}
      />
      <Action.Push
        title="Show Relations"
        icon={Icon.TwoPeople}
        target={
          <RelationsList friendId={friend.id} navigationTitle={friend.name} />
        }
      />
      {friend.email ? (
        <Action.CopyToClipboard
          title="Copy Email"
          content={friend.email}
          icon={Icon.Envelope}
        />
      ) : null}
      <Action.CopyToClipboard
        title="Copy Friend Id"
        content={friend.id}
        icon={Icon.Clipboard}
        shortcut={{ modifiers: ["cmd", "shift"], key: "." }}
      />
      <Action
        title="Reload"
        icon={Icon.ArrowClockwise}
        shortcut={{ modifiers: ["cmd"], key: "r" }}
        onAction={onReload}
      />
    </ActionPanel>
  );
}

interface EditValues {
  name: string;
  company: string;
  jobTitle: string;
  email: string;
  phone: string;
  notes: string;
}

function EditFriendForm({
  friend,
  onSaved,
}: {
  friend: FriendRow;
  onSaved: () => void;
}) {
  const { pop } = useNavigation();
  const [isSubmitting, setIsSubmitting] = useState(false);

  const original: EditValues = {
    name: friend.name ?? "",
    company: friend.company ?? "",
    jobTitle: friend.jobTitle ?? "",
    email: friend.email ?? "",
    phone: friend.phone ?? "",
    notes: friend.notes ?? "",
  };

  const flagFor: Record<keyof EditValues, string> = {
    name: "--name",
    company: "--company",
    jobTitle: "--job-title",
    email: "--email",
    phone: "--phone",
    notes: "--notes",
  };

  async function submit(values: EditValues) {
    if (!values.name.trim()) {
      await showToast({
        style: Toast.Style.Failure,
        title: "Name is required",
      });
      return;
    }

    const args = ["friend", "update", friend.id];
    (Object.keys(flagFor) as (keyof EditValues)[]).forEach((key) => {
      if (values[key] !== original[key]) {
        args.push(flagFor[key], values[key]);
      }
    });

    if (args.length === 3) {
      await showToast({
        style: Toast.Style.Failure,
        title: "No changes to save",
      });
      return;
    }

    setIsSubmitting(true);
    const toast = await showToast({
      style: Toast.Style.Animated,
      title: "Saving…",
      message: "Waiting for WWDCBuddy to process the command.",
    });
    try {
      await runRaw(args);
      toast.style = Toast.Style.Success;
      toast.title = "Friend updated";
      toast.message = undefined;
      onSaved();
      pop();
    } catch (error) {
      toast.style = Toast.Style.Failure;
      toast.title = "Update failed";
      toast.message = error instanceof Error ? error.message : String(error);
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Form
      isLoading={isSubmitting}
      navigationTitle={`Edit ${friend.name}`}
      actions={
        <ActionPanel>
          <Action.SubmitForm
            title="Save Changes"
            icon={Icon.Check}
            onSubmit={submit}
          />
        </ActionPanel>
      }
    >
      <Form.Description text="Updates are queued to WWDCBuddy, which opens to save and sync them." />
      <Form.TextField id="name" title="Name" defaultValue={original.name} />
      <Form.TextField
        id="company"
        title="Company"
        defaultValue={original.company}
      />
      <Form.TextField
        id="jobTitle"
        title="Job Title"
        defaultValue={original.jobTitle}
      />
      <Form.TextField id="email" title="Email" defaultValue={original.email} />
      <Form.TextField id="phone" title="Phone" defaultValue={original.phone} />
      <Form.TextArea id="notes" title="Notes" defaultValue={original.notes} />
    </Form>
  );
}
