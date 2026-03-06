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
					.tabItem { Label("Routes", systemImage: "mappin.and.ellipse") }
				
				BossesView(game: selectedGame)
					.tabItem { Label("Bosses", systemImage: "person.3") }
				
				BattlesView(game: selectedGame)
					.tabItem { Label("Battles", systemImage: "person.line.dotted.person.fill") }
			}
			.safeAreaInset(edge: .top) {
				HStack {
					Button {
						showingGamePicker = true
					} label: {
						ZStack {
							Circle()
								.fill(Color(hex: selectedGame.bubbleHex))
							
							Text(selectedGame.shortCode)
								.font(.caption2)
								.fontWeight(.bold)
								.foregroundStyle(selectedGame.textColor)
						}
						.frame(width: 36, height: 36)
					}
					.buttonStyle(.plain)
					.frame(width: 44, height: 44)
					
					Spacer()
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 6)
				.background(.clear)
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
