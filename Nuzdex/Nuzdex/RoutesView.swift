import SwiftUI

struct RoutesView: View {
	let game: GameId
	var body: some View {
		Text("Routes for \(game.rawValue)")
	}
}
