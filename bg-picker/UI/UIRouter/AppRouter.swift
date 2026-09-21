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
    /// A typed array rather than `NavigationPath` so the router can see what is on the
    /// stack — `NavigationPath` erases its elements, and the teardown below has to know
    /// whether the room screen is still there.
    private(set) var path: [Route] = []

    /// Fires when the room flow ends: the preference screen left the stack, or the stack
    /// emptied. The interactive back gesture never calls `pop()`, so this has to be driven
    /// by the path itself. Wired at the composition root, and safe to run twice.
    @ObservationIgnored
    var onFlowEnded: (() -> Void)?

    var isAtLobby: Bool { path.isEmpty }

    /// Hand this to `NavigationStack`; SwiftUI's writes then land in `update(to:)` too.
    var pathBinding: Binding<[Route]> {
        Binding(
            get: { self.path },
            set: { self.update(to: $0) }
        )
    }

    func push(_ route: Route) {
        update(to: path + [route])
    }

    func pop() {
        guard !path.isEmpty else { return }
        update(to: path.dropLast())
    }

    func popToLobby() {
        update(to: [])
    }

    /// A room arrived with no setup screen on screen — Game Center accepting a scanned party
    /// link through `player(_:wantsToPlay:)`. Resets the stack to that one route.
    func enterRoom() {
        update(to: [.categoryPreference])
    }

    private func update(to newPath: some Sequence<Route>) {
        let wasInRoom = path.contains(.categoryPreference)
        let wasInFlow = !path.isEmpty

        path = Array(newPath)

        let leftRoom = wasInRoom && !path.contains(.categoryPreference)
        let returnedToLobby = wasInFlow && path.isEmpty

        if leftRoom || returnedToLobby {
            onFlowEnded?()
        }
    }
}
