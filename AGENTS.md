# Repository Guide

## Project Overview

Board Game Picker is a SwiftUI app targeting iOS 26 or later. It helps a group connect through Game Center and eventually agree on a board game.

The project intentionally has:

- No custom backend.
- No local database or SwiftData model.
- No bundled CSV catalog, persistent cache, or fallback game data.
- No fake users, rooms, matches, or results in production paths.

Game Center owns player authentication, party-code matchmaking, match lifecycle, and peer-to-peer messages. BoardGameGeek **geeklist** loading is implemented in `BGGService`: one pull for the geeklist, a second batched pull through `/thing?stats=1` for the details the cards display. Collection loading is not implemented and is not planned.

## Source Layout

- `bg-picker/Services`: platform integration boundaries — `GameKitManager` and `BGGService`.
- `bg-picker/Models`: backend-independent domain and presentation values.
- `bg-picker/UI/CommonComponents`: shared SwiftUI components.
- `bg-picker/UI/Screens`: feature-organized SwiftUI screens and transient view models.
- `bg-picker/Stores`: in-memory session state shared across screens, cleared when a room ends.
- `bg-picker/Utils`: platform helpers such as haptics.
- `bg-picker/ViewTest`: `#if DEBUG` harnesses only. Nothing here ships in Release.
- `bg-picker/Resources/Images.xcassets`: app colors, icons, and images.

The Xcode project uses a file-system-synchronized root group. New Swift files placed inside `bg-picker/` are normally discovered automatically and should not require manual `project.pbxproj` source entries.

## GameKit Architecture

`GameKitManager.shared` is the frontend-facing multiplayer boundary. Views should call the manager instead of importing matchmaking behavior into UI code.

The manager currently provides:

- `authenticate()` for Game Center authentication.
- `createRoom()` for a new GameKit party-code activity.
- `joinRoom(code:)` for joining by party code.
- `send(_:type:reliably:)` for typed match packets.
- `disconnect()` for ending the transient room session.

The required Game Activity identifier is `boardgameroom`. It must be configured in App Store Connect with party-code support, synchronous play, and a 2–6 player range.

Do not reintroduce `GKMatchmakerViewController`, custom server room IDs, or backend matchmaking unless the product requirements explicitly change.

QR codes contain `GKGameActivity.partyURL` and are rendered locally with Core Image. The receiving player scans them with the system Camera; an in-app scanner is not currently part of the product.

## Implementation Rules

- Keep session data transient and in memory.
- Fetched session data belongs in a store under `bg-picker/Stores`, reached through its `.shared` instance. A view model holds only its own screen's state — if two screens need the same data, it is store state, not view-model state.
- Give stores an internal `init()` alongside `.shared` so previews and tests can use an isolated instance.
- Keep networking and platform APIs behind focused service types.
- Keep SwiftUI views declarative; move lifecycle and matchmaking decisions into `GameKitManager`.
- Represent loading, unavailable, empty, waiting, connected, cancelled, and failure states honestly.
- Do not add sample games or simulated multiplayer success to runtime code.
- Prefer Apple frameworks over new dependencies when they already provide the required capability.
- Preserve the purple visual language and existing reusable components unless a design change is requested.
- Use `@MainActor` for UI-observed services and handle GameKit callback isolation explicitly.
- Never commit credentials, API tokens, provisioning profiles, or developer-specific account data.

## Build and Verification

Signing is per developer. `PRODUCT_BUNDLE_IDENTIFIER` and `DEVELOPMENT_TEAM` are not hard-coded in `project.pbxproj`; they resolve from `MY_BUNDLE_ID` and `MY_DEVELOPMENT_TEAM` in the untracked `bg-picker/Credentials/Secrets.xcconfig`. Do not reintroduce literal bundle identifiers or team IDs into the project file — the contributors hold separate Individual memberships, and a hard-coded App ID breaks signing for everyone but its owner. See the documentation catalog for setup.

The selected command-line developer directory may point at Command Line Tools instead of Xcode. Set `DEVELOPER_DIR` for command-line builds:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project bg-picker.xcodeproj \
  -scheme bg-picker \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/bg-picker-derived \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Before handing off a change:

1. Run `git diff --check`.
2. Build for generic iOS with code signing disabled.
3. Search for stale references when removing or renaming a feature.
4. For GameKit behavior, describe any real-device checks that remain. End-to-end matchmaking requires Game Center-enabled accounts and the App Store Connect activity configuration.

Do not treat simulator-only behavior as proof that Game Center matchmaking works. Use at least two eligible players/devices for the final multiplayer test.

## Working With Existing Changes

The worktree may contain user-owned or unfinished edits. Inspect `git status` before changing files, preserve unrelated modifications, and do not reset or discard work unless explicitly requested.

When updating project documentation, keep this file and `README.md` consistent. `CLAUDE.md` delegates the shared repository rules to this file and should remain brief.
