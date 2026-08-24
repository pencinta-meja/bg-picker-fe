//
//  MyGamesScreen.swift
//  bg-picker
//

import SwiftUI
import SwiftData

struct MyGamesScreen: View {
    @Environment(CollectionViewModel.self) private var viewModel
    @State private var showAddForm = false

    var body: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .ignoresSafeArea()

            if viewModel.isEmpty {
                emptyStateView
            } else {
                gameListView
            }

            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showAddForm = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(width: 60, height: 60)
                            .background(Color("PrimaryButton"))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("My Games")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddForm) {
            AddBoardGameFormScreen { game in
                viewModel.addGame(game)
            }
        }
    }



    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.grid.2x2")
                .font(.system(size: 52))
                .foregroundColor(.white.opacity(0.4))

            Text("Your collection is empty")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Tap the + button to add your first game")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

   

    private var gameListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.games) { game in
                    GameRowCard(game: game)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
}



struct GameThumbnailImage: View {
    let path: String?
    var size: CGFloat = 64

    var body: some View {
        Group {
            if let path {
                if path.hasPrefix("http") {
                    AsyncImage(url: URL(string: path)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure, .empty:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                } else if let uiImage = UIImage(contentsOfFile: path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }

    private var placeholder: some View {
        ZStack {
            Color.white.opacity(0.1)
            Image(systemName: "photo")
                .foregroundColor(.white.opacity(0.4))
        }
    }
}



private struct GameRowCard: View {
    let game: BoardGame

    var body: some View {
        HStack(spacing: 14) {
            GameThumbnailImage(path: game.thumbnailPath)

            VStack(alignment: .leading, spacing: 4) {
                Text(game.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                if !game.oneLiner.isEmpty {
                    Text(game.oneLiner)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Label("\(game.minPlayers)–\(game.maxPlayers)", systemImage: "person.2")
                    Label("\(game.minPlayingTime)–\(game.maxPlayingTime) min", systemImage: "clock")
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            if let firstGenre = game.genres.first {
                Text(firstGenre.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("PrimaryButton").opacity(0.25))
                    .foregroundColor(Color("PrimaryButton"))
                    .clipShape(Capsule())
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}


#Preview {
    let container = try! ModelContainer(
        for: BoardGame.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let viewModel = CollectionViewModel(modelContext: container.mainContext)

    return NavigationStack {
        MyGamesScreen()
    }
    .environment(viewModel)
    .modelContainer(container)
}
