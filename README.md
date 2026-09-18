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
  connected-player count, and optional in-memory category-group choices.
- Preference, swipe-card, detail, and podium UI remain available as reusable presentation code.
- Swipe cards are built from the host's geeklist, and swipe state is transient.
- There is no backend client, local database, bundled CSV, persistent cache, or fallback game catalog.

### GameKit

Game Center provides player identity, party-code matchmaking, match lifecycle, and peer-to-peer session messages through the iOS 26 `GKGameActivity` API.

`GameKitManager.shared` is the frontend boundary:

- Call `authenticate()` once when the app starts.
- Call `createRoom()` to generate and start a new `XXX-XXX` party-code room.
- Call `joinRoom(code:)` to join an existing party-code room.
- Call `send(_:type:reliably:)` with any `Encodable` value to send a typed packet to every connected player.
- Observe `partyCode`, `partyURL`, `players`, `matchState`, `statusMessage`, and `receivedPackets`, or set `onPacketReceived` for event-driven handling.
- Call `disconnect()` when the room ends.

Room QR images are generated locally with Core Image; no QR package is required.

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
deck. `clear()` runs when a room ends, so one room never inherits another's deck. The
data is not yet shared with matched players through GameKit.

## Project structure

- `Models`: backend-independent presentation/domain values.
- `Services`: platform boundaries — `GameKitManager` and `BGGService`.
- `Stores`: `SessionGameStore`, the loaded geeklist games and load status for the current room.
- `UI/CommonComponents`: reusable visual components and the shared app background.
- `UI/Screens/RoomSetup`: the four room-setup screens.
- `UI/Screens/SwipeScreen`: swipe UI and transient swipe state.
- `ViewTest`: `#if DEBUG` harnesses only; nothing here ships in Release.
- `Utils`: platform helpers such as haptic feedback.
