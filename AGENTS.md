# Build and Run

Run the iOS app in Simulator using `xcodebuildmcp` after every source code change.

Use `EventBuddy.xcodeproj` with the `EventBuddy` scheme. Before the first build/run in a session, call `session_show_defaults`; if defaults are missing, set the project path, scheme, and an available iOS simulator before calling `build_run_sim`.

Run the Mac app using Xcode MCP, not `xcodebuildmcp`.

Use `EventBuddy.xcodeproj` with the `EventBuddyMac` scheme and the Mac destination. If the active Xcode scheme is not `EventBuddyMac`, switch it in Xcode first, then run through Xcode MCP.

# AGENTS
