import SwiftUI

struct BattlesView: View {
    let game: GameId
    var body: some View {
        Text("Battles for \(game.rawValue)")
    }
}
