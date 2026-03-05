//
//  BossesView.swift
//  Nuzdex
//
//  Created by Sakura Wallace on 27/02/2026.
//

import SwiftUI

struct BossesView: View {
    let game: GameId
    var body: some View {
        Text("Bosses for \(game.rawValue)")
    }
}
