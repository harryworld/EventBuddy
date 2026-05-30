# WWDCBuddy for Raycast

A Raycast extension that wraps the [`wwdcbuddy`](../docs/wwdcbuddy-cli.md) command line tool so you can browse and update your WWDCBuddy data without leaving Raycast.

## Commands

- **Search Events** — browse and search events, filter by attending, view details, open the event URL, and jump to attendees.
- **Search Friends** — browse and search friends, view details, toggle favorite, edit contact fields, and view their relations.
- **Browse Relations** — browse attending/wishlist relations for all events, scoped by event or friend, with an unlink action.

Read commands query the shared app-group SQLite database directly. Update commands (toggle favorite, edit friend, unlink) queue a command to the WWDCBuddy macOS app, which opens to save and sync the change.

## Requirements

- macOS with the WWDCBuddy app installed.
- The `wwdcbuddy` CLI installed (WWDCBuddy → Settings → Data & CLI → Install CLI). By default it lands in `~/.local/bin`.

## Preferences

- **wwdcbuddy CLI Path** — path to the binary. Leave as `wwdcbuddy` to auto-resolve from `~/.local/bin`, Homebrew, and `/usr/local/bin`, or set an absolute path.
- **Database Path** — optional override for the SQLite database used by read commands (sets `EVENTBUDDY_DATABASE_PATH`).

## Development

```sh
npm install
npm run dev      # run in Raycast with hot reload
npm run build    # type-check and build
npm run lint     # lint
```
