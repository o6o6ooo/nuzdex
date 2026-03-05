import SwiftUI

struct BossesView: View {
	let game: GameId
	var body: some View {
		Text("Bosses for \(game.rawValue)")
	}
}
