//
//  ContentView.swift
//  Nuzdex
//
//  Created by Sakura Wallace on 27/02/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var showingGamePicker = false

    var body: some View {
        NavigationStack {
            TabView {
                RoutesView()
                    .tabItem { Label("Routes", systemImage: "map") }

                BossesView()
                    .tabItem { Label("Bosses", systemImage: "person.3") }

                BattlesView()
                    .tabItem { Label("Battles", systemImage: "flame") }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingGamePicker = true
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingGamePicker) {
                GamePickerView()
            }
        }
    }
}

#Preview {
    ContentView()
}
