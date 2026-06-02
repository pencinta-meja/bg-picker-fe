//
//  AddBoardGameFormScreen.swift
//  bg-picker
//

import SwiftUI
import PhotosUI

struct AddBoardGameFormScreen: View {
    let onSave: (BoardGame) -> Void
    @Environment(\.dismiss) private var dismiss

    // MARK: – Form State

    @State private var name = ""
    @State private var oneLiner = ""
    @State private var desc = ""

    @State private var minPlayers = 1
    @State private var maxPlayers = 4

    @State private var minPlayTime = 30
    @State private var maxPlayTime = 60

    @State private var selectedGenres: Set<Genre> = []

    @State private var complexity: Float = 2.5
    @State private var rating: Float = 0.0

    @State private var photoItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var savedImagePath: String?

    // Genre sheet
    @State private var showGenrePicker = false

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Photo
                Section("Photo") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        if let img = selectedImage {
                            img
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("Select thumbnail photo")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .frame(height: 120)
                        }
                    }
                    .onChange(of: photoItem) { _, item in
                        Task { await loadPhoto(from: item) }
                    }
                }

                // MARK: Basic Info
                Section("Info") {
                    TextField("Game name *", text: $name)
                    TextField("One-liner tagline", text: $oneLiner)
                }

                // MARK: Description
                Section("Description") {
                    TextEditor(text: $desc)
                        .frame(minHeight: 80)
                }

                // MARK: Players
                Section("Players") {
                    Stepper("Min: \(minPlayers)", value: $minPlayers, in: 1...maxPlayers)
                    Stepper("Max: \(maxPlayers)", value: $maxPlayers, in: minPlayers...20)
                }

                // MARK: Play Time
                Section("Play time") {
                    Stepper("Min: \(minPlayTime) min", value: $minPlayTime, in: 5...maxPlayTime, step: 5)
                    Stepper("Max: \(maxPlayTime) min", value: $maxPlayTime, in: minPlayTime...600, step: 5)
                }

                // MARK: Genre
                Section("Genre") {
                    Button {
                        showGenrePicker = true
                    } label: {
                        HStack {
                            Text(selectedGenres.isEmpty
                                 ? "Select genres"
                                 : selectedGenres.map(\.rawValue).sorted().joined(separator: ", "))
                                .foregroundColor(selectedGenres.isEmpty ? .secondary : .primary)
                                .lineLimit(2)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // MARK: Complexity
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Complexity")
                            Spacer()
                            Text(String(format: "%.1f / 5.0", complexity))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        Slider(value: $complexity, in: 0...5, step: 0.5)
                            .tint(complexityColor)
                    }
                } header: {
                    Text("Complexity & Rating")
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Your rating")
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: Float(star) <= rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .onTapGesture { rating = Float(star) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveGame()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showGenrePicker) {
                GenrePickerSheet(selectedGenres: $selectedGenres)
            }
        }
    }

    // MARK: – Helpers

    private var complexityColor: Color {
        switch complexity {
        case 0..<2: return .green
        case 2..<3.5: return .orange
        default: return .red
        }
    }

    @MainActor
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }

        // Save to documents directory
        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: url)
            savedImagePath = url.path
        }
        selectedImage = Image(uiImage: uiImage)
    }

    private func saveGame() {
        let game = BoardGame(
            name: name.trimmingCharacters(in: .whitespaces),
            oneLiner: oneLiner,
            desc: desc,
            complexity: complexity,
            rating: rating,
            genres: Array(selectedGenres),
            thumbnailPath: savedImagePath,
            minPlayers: minPlayers,
            maxPlayers: maxPlayers,
            minPlayingTime: minPlayTime,
            maxPlayingTime: maxPlayTime
        )
        onSave(game)
        dismiss()
    }
}

// MARK: – Genre Picker Sheet

private struct GenrePickerSheet: View {
    @Binding var selectedGenres: Set<Genre>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(Genre.allCases, id: \.self) { genre in
                Button {
                    if selectedGenres.contains(genre) {
                        selectedGenres.remove(genre)
                    } else {
                        selectedGenres.insert(genre)
                    }
                } label: {
                    HStack {
                        Text(genre.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedGenres.contains(genre) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("Select Genres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    AddBoardGameFormScreen { game in
        print("Saved: \(game.name)")
    }
}
