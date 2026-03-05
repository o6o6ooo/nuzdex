import SwiftUI

struct ContentView: View {
    @State private var showingGamePicker = false
    @AppStorage("selectedGame") private var selectedGameRaw = GameId.emerald.rawValue
    
    private var selectedGame: GameId {
            GameId(rawValue: selectedGameRaw) ?? .emerald
    }

    var body: some View {
        NavigationStack {
            TabView {
                RoutesView(game: selectedGame)
                    .tabItem { Label("Routes", systemImage: "map") }

                BossesView(game: selectedGame)
                    .tabItem { Label("Bosses", systemImage: "person.3") }

                BattlesView(game: selectedGame)
                    .tabItem { Label("Battles", systemImage: "flame") }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingGamePicker = true } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Text(selectedGame.shortCode)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showingGamePicker) {
                GamePickerView(selectedGameRaw: $selectedGameRaw)
            }
        }
    }
}

#Preview {
    ContentView()
}
