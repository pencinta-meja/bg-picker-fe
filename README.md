# Board Game Picker

Board Game Picker is a SwiftUI iOS app for helping a group agree on a board game. It uses Game Center for temporary multiplayer rooms and keeps session data in memory.

## Current state

- The app launches into a four-screen room setup flow: Lobby, Geeklist Link,
  Room Code Join, and Preference/Waiting Room.
- Game Center party codes and party URLs connect 2–6 players without an application backend.
- Hosts enter a BoardGameGeek geeklist URL before creating a room. The list is
  fetched and turned into the swipe deck; nothing is cached between sessions.
- Guests join with one native, paste-friendly party-code field. The QR affordance
  on the Join screen is intentionally noninteractive; scanning is not implemented.
- The Preference screen displays the live party code, locally generated QR image,
  connected-player count, readiness, and optional in-memory category-group choices.
- Preference, swipe-card, detail, and podium UI remain available as reusable presentation code.
- The host explicitly starts after every connected player is ready and synchronized.
- Swipe cards are built from one host-shuffled canonical deck. Progress and results are
  synchronized between peers but remain transient.
- There is no backend client, local database, bundled CSV, persistent cache, or fallback game catalog.

### GameKit

Game Center provides player identity, party-code matchmaking, match lifecycle, and peer-to-peer session messages through the iOS 26 `GKGameActivity` API.

The `RoomSession` protocol is the frontend boundary; screens depend on `any RoomSession`, never on GameKit. `GameKitManager.shared` conforms to it at runtime, and the DEBUG-only `PreviewRoomSession` conforms to it in Xcode previews so screens can be built without a Game Center sign-in.

- Call `authenticate()` once when the app starts.
- Call `createRoom()` to generate and start a new `XXX-XXX` party-code room.
- Call `joinRoom(code:)` to join an existing party-code room.
- Observe the room phase, participants, canonical deck, local progress, result groups,
  party code/URL, and honest error state through `RoomSession`.
- Use `setReady(categories:)`, `setNotReady()`, `startGame()`,
  `recordDecision(gameID:accepted:)`, `finishSwiping()`, and `refreshResults()` for the
  domain workflow. Views never encode or decode GameKit packets.
- Call `disconnect()` when the room ends.

`GameKitManager` is the only GameKit importer. It translates reliable, versioned peer
packets into the domain state owned by `SessionGameStore`; its generic packet helper
remains manager-only.

Room QR images are generated locally with Core Image; no QR package is required.

#### Session workflow

1. The host fetches one geeklist and shares the complete `BGGItem` source. Encoded data is
   split into 24 KiB chunks and verified with SHA-256 before a peer becomes source-ready.
2. Connected players choose zero or more `BoardGameCategoryGroup` values and become ready.
   The groups are combined as a union; if everyone selects nothing, the full geeklist is used.
3. Start requires 2–6 connected players, every connected player ready, every player source-
   synchronized, and at least one matching game. Start freezes the roster and canonical order.
4. New identities are rejected after Start. A frozen player with the same Game Center player
   ID may reconnect and receives the source, room snapshot, canonical deck, and saved progress.
5. Every swipe sends an idempotent revisioned progress snapshot. A player can finish only
   after deciding the complete deck; zero accepted games is valid, and the first finished
   submission cannot be changed.
6. Results include only finished submissions and never wait for the whole frozen roster.
   Vote ties keep canonical order, zero-vote games are omitted, and new results appear only
   after pulling to refresh or reopening Podium.

If the authority disconnects after Start, the connected frozen player with the lowest Game
Center player ID becomes authority. A returning original host remains a normal participant.
The entire room is unrecoverable after every peer leaves because there is deliberately no
server or persistent storage.

#### App Store Connect setup

The application cannot load a room definition until its Game Center configuration contains a matching Game Activity:

1. Enable Game Center for the app identifier and target.
2. In App Store Connect, create a Game Activity with identifier `boardgameroom`.
3. Enable party-code support, select synchronous play, and configure 2 minimum and 6 maximum players.
4. Make the activity available for the build being tested.
5. Test matchmaking on two Game Center-enabled devices or supported test accounts.

If this setup is missing, the lobby intentionally reports that `boardgameroom` is unavailable instead of simulating a room.

Each contributor signs with their own bundle identifier and team, supplied through the untracked `bg-picker/Credentials/Secrets.xcconfig` (see the documentation catalog). Step 5 therefore applies per developer: separate app records are separate Game Center namespaces, so contributors cannot match against each other and each must test multiplayer within their own build.

### BoardGameGeek geeklist loading

`BGGService` loads a public geeklist in two pulls, because a geeklist entry carries
only an object id and a name:

1. `GET /xmlapi/geeklist/{id}` — the entries. Only `subtype == "boardgame"` is kept.
2. `GET /xmlapi2/thing?id=…&stats=1` — full detail for those ids, batched 20 at a time.

`stats=1` is required: it is the only way to get `averageweight` (complexity, a 1-5
scale) and `average` (the community rating). `BoardGameCard.init(item:)` maps the result
into display values, rendering `—` wherever BGG returned nothing rather than inventing a
zero. Both endpoints answer `202` while queuing a response, so requests retry.

The API token is read from `Secrets.xcconfig` through `SecretVariables`. No API token
belongs in source control.

Results live in `SessionGameStore.shared` for the active session — `games` keeps the
decoded `BGGItem`s so later filtering has the domain fields, and `cards` is the mapped
canonical deck. The host shares the source through GameKit once per connection; later
progress packets contain only game IDs and decisions, not artwork. `clear()` runs when a
room ends, so one room never inherits another's deck.

### Navigation

`AppRouter` owns the navigation stack as a typed `[Route]`, and screens express intent
through it — `push(_:)`, `pop()`, `popToLobby()`, `enterRoom()` — rather than holding a
`NavigationPath` binding. `RouteDestinationView` is the single `switch` from a `Route` to a
screen.

The screen that opens a room is the one that routes to it: `CreateRoomScreen` and
`JoinRoomScreen` each watch their own `room.partyCode` and push the preference screen. The
lobby only handles the room it did not ask for — Game Center accepting a scanned party link
while nothing is pushed.

Leaving the room, by button or by back gesture, fires the router's `onFlowEnded`, wired once
in `App`: it disconnects an active room and clears `SessionGameStore`.

## Project structure

- `App`: the `@main` entry point and composition root.
- `Models`: backend-independent presentation/domain values.
- `Services`: platform boundaries — `GameKitManager`, `BGGService`, and the `RoomSession`
  protocol the UI depends on.
- `Extensions`: small standard-library helpers.
- `Credentials`: `SecretVariables` and the untracked `Secrets.xcconfig`.
- `UI/UIRouter`: `Route`, `AppRouter`, `RouteDestinationView`.
- `UI/UIStores`: `SessionGameStore`, the loaded geeklist games and load status for the current room.
- `UI/UIMocks`: `#if DEBUG` conformers for previews, such as `PreviewRoomSession`; nothing here
  ships in Release.
- `UI/UIVIew/CommonComponents`: reusable visual components and the shared app background.
- `UI/UIVIew/Screens`: the room-setup, preference, swipe, and podium screens, plus transient
  swipe state.
- `UI/UIResources`: the asset catalogs.
- `Documentation.docc`: the documentation catalog.
- `GameCenterResources.gamekit`: the local Game Center configuration resource.
- `bg-pickerTests`: reducer and in-memory session tests for filtering, readiness,
  reconnection, idempotency, authority election, immutable submissions, and results.

`UIVIew` is spelled that way on disk.

## Verification

Run the unit suite on an installed iOS simulator, then run the generic-device build with
signing disabled. Game Center matchmaking, reconnection, and migration still require at
least two eligible real accounts/devices; simulator tests do not prove those platform paths.
