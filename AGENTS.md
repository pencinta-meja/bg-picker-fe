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

- `bg-picker/App`: the `@main` entry point. Composition root — the only place that builds `GameKitManager.shared` and `AppRouter` and wires them together.
- `bg-picker/Services`: platform integration boundaries — `GameKitManager`, `BGGService`, and the `RoomSession` protocol the UI depends on.
- `bg-picker/Models`: backend-independent domain and presentation values.
- `bg-picker/Extensions`: small standard-library helpers such as `Array+Chunk`.
- `bg-picker/Credentials`: `SecretVariables` plus the untracked `Secrets.xcconfig`.
- `bg-picker/UI/UIRouter`: navigation — `Route`, `AppRouter`, and `RouteDestinationView`.
- `bg-picker/UI/UIStores`: in-memory session state shared across screens, cleared when a room ends.
- `bg-picker/UI/UIMocks`: `#if DEBUG` conformers for previews. Nothing here ships in Release.
- `bg-picker/UI/UIVIew/CommonComponents`: shared SwiftUI components.
- `bg-picker/UI/UIVIew/Screens`: feature-organized SwiftUI screens and transient view models.
- `bg-picker/UI/UIResources`: `Assets`, `Colors`, and `Images` asset catalogs.
- `bg-picker/Documentation.docc`: the documentation catalog.
- `bg-picker/GameCenterResources.gamekit`: the local Game Center configuration resource.

`UIVIew` is spelled that way on disk. Match it or rename the folder deliberately; do not guess at `UIView`.

The Xcode project uses a file-system-synchronized root group. New Swift files placed inside `bg-picker/` are normally discovered automatically and should not require manual `project.pbxproj` source entries.

## GameKit Architecture

`RoomSession` (`bg-picker/Services/RoomSession.swift`) is the frontend-facing multiplayer boundary. Screens hold `any RoomSession` and never name a concrete type, so matchmaking behavior stays out of UI code.

- `GameKitManager.shared` is the production conformer and the only type that imports GameKit.
- `PreviewRoomSession` (`bg-picker/UI/UIMocks`, `#if DEBUG`) is the preview conformer. It poses the screens in any state without authenticating — which matters because contributors hold separate Individual memberships, so only the App ID's owner can sign in at all.

The protocol carries what the UI reads — `isAuthenticated`, `isActivityReady`, `hasActiveRoom`, `matchState`, `statusMessage`, `errorMessage`, `partyCode`, `partyURL`, `roomMemberCount`, `presentedViewController` — plus `authenticate()`, `createRoom()`, `joinRoom(code:)`, `disconnect()` and `dismissPresentedController()`. `players` stays off it: `GKPlayer` has no public initializer, so no fake can produce one and the UI gets `roomMemberCount` (local player included) instead.

Packet traffic — `send(_:type:reliably:)`, `receivedPackets`, `onPacketReceived` — is still `GameKitManager`-only. Add it to `RoomSession` when a screen needs it, not before.

`GameKitManager` is `@Observable` rather than `ObservableObject`, because `@ObservedObject` cannot hold a protocol while Observation tracks reads made through `any RoomSession` correctly. `PartyCode.normalize(_:)` sits in the same file for party-code text formatting that involves no GameKit.

The required Game Activity identifier is `boardgameroom`. It must be configured in App Store Connect with party-code support, synchronous play, and a 2–6 player range.

Do not reintroduce `GKMatchmakerViewController`, custom server room IDs, or backend matchmaking unless the product requirements explicitly change.

QR codes contain `GKGameActivity.partyURL` and are rendered locally with Core Image. The receiving player scans them with the system Camera; an in-app scanner is not currently part of the product.

## Navigation

`AppRouter` (`bg-picker/UI/UIRouter`) is the coordinator. It owns the stack as a typed `[Route]` — not `NavigationPath`, which erases its elements and would hide whether the room screen is still present — and every write funnels through one private `update(to:)`, including the writes SwiftUI makes itself when the user swipes back.

- Screens never hold a `NavigationPath` or a path `Binding`. They take `AppRouter` and call `push(_:)`, `pop()`, `popToLobby()` or `enterRoom()`.
- `RouteDestinationView` is the single `switch` from `Route` to a screen. `LobbyScreen` hands every destination to it.
- **The screen that opens a room routes to it.** `CreateRoomScreen` and `JoinRoomScreen` each watch their own `room.partyCode` and push `.categoryPreference`. The lobby does not reach forward on their behalf.
- `LobbyScreen` keeps exactly one forward move, guarded by `router.isAtLobby`: a room that arrives through `player(_:wantsToPlay:)` when another player accepts a party link and no setup screen is open.
- `onFlowEnded` fires when `.categoryPreference` leaves the stack or the stack empties, and is wired once in `bg-picker/App`. It disconnects the room if one is active and clears `SessionGameStore`. It is deliberately safe to run twice.

Do not put flow lifecycle back into a screen: no `NavigationPath` rebuilding, and no reading `path.count` as a proxy for "the user went back".

## Implementation Rules

- Keep session data transient and in memory.
- BGG exposes two different link axes: `boardgamecategory` (what a game is about) and `boardgamemechanic` (how it is played). This app models categories only, as `BoardGameCategory`, folded into 13 pickable `BoardGameCategoryGroup`s. Do not reintroduce a type named `Mechanic` holding category values.
- Fetched session data belongs in a store under `bg-picker/UI/UIStores`, reached through its `.shared` instance. A view model holds only its own screen's state — if two screens need the same data, it is store state, not view-model state.
- Give stores an internal `init()` alongside `.shared` so previews and tests can use an isolated instance.
- Keep networking and platform APIs behind focused service types.
- Keep SwiftUI views declarative; move matchmaking decisions into `GameKitManager` and navigation decisions into `AppRouter`.
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
