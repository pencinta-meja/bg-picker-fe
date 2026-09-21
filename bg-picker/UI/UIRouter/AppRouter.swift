//
//  AppRouter.swift
//  bg-picker
//
//  Created by Danniel on 21/09/26.
//
//  Owns the navigation stack so screens can express intent ("show preferences") instead of
//  performing stack surgery. Every write funnels through `update(to:)`, including the ones
//  SwiftUI makes itself when the user swipes back.
//

import Observation
import SwiftUI

@Observable
@MainActor
final class AppRouter {
    private(set) var path = NavigationPath()

    /// Fires when the stack returns to the lobby. The interactive back gesture never calls
    /// `pop()`, so this has to be driven by the path itself. Wired at the composition root.
    @ObservationIgnored
    var onReturnToLobby: (() -> Void)?

    var isAtLobby: Bool { path.isEmpty }

    /// Hand this to `NavigationStack`; SwiftUI's writes then land in `update(to:)` too.
    var pathBinding: Binding<NavigationPath> {
        Binding(
            get: { self.path },
            set: { self.update(to: $0) }
        )
    }

    func push(_ route: Route) {
        var updated = path
        updated.append(route)
        update(to: updated)
    }

    func pop() {
        guard !path.isEmpty else { return }
        var updated = path
        updated.removeLast()
        update(to: updated)
    }

    func popToLobby() {
        update(to: NavigationPath())
    }

    /// Swap the top of the stack. A setup screen calls this once its room exists: it has done
    /// its job, and leaving it underneath would put a dead form with a permanently disabled
    /// button between the room and the lobby.
    func replace(with route: Route) {
        var updated = path
        if !updated.isEmpty {
            updated.removeLast()
        }
        updated.append(route)
        update(to: updated)
    }

    /// A room arrived with no setup screen on screen — Game Center accepting a scanned party
    /// link through `player(_:wantsToPlay:)`. Resets the stack to that one route.
    func enterRoom() {
        var destination = NavigationPath()
        destination.append(Route.categoryPreference)
        update(to: destination)
    }

    private func update(to newPath: NavigationPath) {
        let wasInFlow = !path.isEmpty
        path = newPath

        if wasInFlow, path.isEmpty {
            onReturnToLobby?()
        }
    }
}
