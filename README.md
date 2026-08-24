# Board Game Picker

Board Game Picker is a SwiftUI iOS app for helping a group agree on a board game. It uses Game Center for temporary multiplayer rooms and keeps session data in memory.

## Current state

- The app launches into a working Create Room / Join Room lobby.
- Game Center party codes and party URLs connect 2–6 players without an application backend.
- Hosts can share a room code, QR code, or system share link.
- Guests can type the room code or scan the QR with the iPhone Camera app.
- Preference, swipe-card, detail, and podium UI remain available as reusable presentation code.
- Swipe state is transient and starts with an empty list.
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

The room console supports QR/link sharing, connected-player inspection, and reliable-message testing. QR images are generated locally with Core Image; no QR package is required.

#### App Store Connect setup

The application cannot load a room definition until its Game Center configuration contains a matching Game Activity:

1. Enable Game Center for the app identifier and target.
2. In App Store Connect, create a Game Activity with identifier `board-game-room`.
3. Enable party-code support, select synchronous play, and configure 2 minimum and 6 maximum players.
4. Make the activity available for the build being tested.
5. Test matchmaking on two Game Center-enabled devices or supported test accounts.

If this setup is missing, the lobby intentionally reports that `board-game-room` is unavailable instead of simulating a room.

### Planned BoardGameGeek integration

The host will load a public BoardGameGeek collection through its XML API. Collection data will remain in memory for the active session and will be shared with matched players through GameKit.

BoardGameGeek API registration and token handling must be designed before this integration is added. No API token belongs in source control.

## Project structure

- `Model`: backend-independent presentation/domain values.
- `View`: SwiftUI screens and reusable components.
- `ViewModel`: transient screen state only.
- `Utils`: platform helpers such as haptic feedback.
