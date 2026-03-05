//
//  BattlesView.swift
//  Nuzdex
//
//  Created by Sakura Wallace on 27/02/2026.
//

import SwiftUI

struct BattlesView: View {
    let game: GameId
    var body: some View {
        Text("Battles for \(game.rawValue)")
    }
}
