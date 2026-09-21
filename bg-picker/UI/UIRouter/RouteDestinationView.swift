//
//  RouteDestinationView.swift
//  bg-picker
//
//  Created by Danniel on 21/09/26.
//
//  The single place a `Route` becomes a screen. `LobbyScreen` hands every destination here
//  rather than carrying the switch itself.
//

import SwiftUI

struct RouteDestinationView: View {
    let route: Route
    let room: any RoomSession
    let router: AppRouter

    var body: some View {
        switch route {
        case .createRoom:
            CreateRoomScreen(room: room, router: router)
        case .joinRoom:
            JoinRoomScreen(room: room, router: router)
        case .categoryPreference:
            PreferenceScreen(room: room, router: router)
        case .swiping:
            SwipeScreen(router: router)
        case .podium:
            PodiumScreen()
        }
    }
}
