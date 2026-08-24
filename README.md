# Board Game Picker

Board Game Picker is a SwiftUI iOS app for helping a group agree on a board game. This repository is currently a UI-only shell while its previous backend and local database architecture are replaced.

## Current state

- The app launches into a Create Room / Join Room lobby.
- Matchmaking actions are intentionally disabled until GameKit is integrated.
- Preference, swipe-card, detail, and podium UI remain available as reusable presentation code.
- Swipe state is transient and starts with an empty list.
- There is no backend client, local database, bundled CSV, persistent cache, or fallback game catalog.

## Planned integrations

### GameKit

Game Center will provide player identity, internet matchmaking, invitations, match lifecycle, and peer-to-peer session messages. Native Game Center invitations will replace the old custom room-code flow.

### BoardGameGeek

The host will load a public BoardGameGeek collection through its XML API. Collection data will remain in memory for the active session and will be shared with matched players through GameKit.

BoardGameGeek API registration and token handling must be designed before this integration is added. No API token belongs in source control.

## Project structure

- `Model`: backend-independent presentation/domain values.
- `View`: SwiftUI screens and reusable components.
- `ViewModel`: transient screen state only.
- `Utils`: platform helpers such as haptic feedback.
