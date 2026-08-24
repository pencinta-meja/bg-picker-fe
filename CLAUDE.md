# Claude Project Instructions

Read and follow [`AGENTS.md`](./AGENTS.md) before modifying this repository. It is the canonical source for architecture, GameKit boundaries, build commands, verification, and repository safety rules.

Additional working expectations:

- Inspect the relevant Swift files and `git status` before editing.
- Preserve existing uncommitted work and avoid unrelated cleanup.
- Prefer implementing and verifying a complete vertical behavior over leaving disconnected scaffolding.
- Keep GameKit details inside `GameKitManager`; SwiftUI screens should consume its published state and public methods.
- Do not introduce a backend, database, persistence layer, mock catalog, fake room, or third-party QR dependency without an explicit requirement.
- Build with the full Xcode developer directory and code signing disabled, using the command documented in `AGENTS.md`.
- State clearly when App Store Connect configuration or multi-device Game Center testing is still required outside the repository.

If this file conflicts with `AGENTS.md`, follow `AGENTS.md` unless the user explicitly gives a newer instruction.
