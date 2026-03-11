import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BossesView: View {
	let game: GameId
	@State private var battles: [BossBattle] = []
	private let topContentInset: CGFloat = 56

	var body: some View {
		ScrollView {
			if battles.isEmpty {
				ContentUnavailableView(
					"No Boss Data Yet",
						systemImage: "tray",
						description: Text("Add JSON files under data for \(game.rawValue).")
					)
					.padding(.top, topContentInset + 24)
			} else {
				LazyVStack(spacing: 16) {
					ForEach(battles) { battle in
						BossBattleCard(battle: battle)
					}
				}
				.padding(.top, topContentInset)
				.padding(.horizontal, 14)
				.padding(.bottom, 20)
			}
		}
		.onAppear(perform: load)
		.onChange(of: game.rawValue) { _, _ in load() }
	}

	private func load() {
		battles = BossDataStore.battles(for: game)
	}
}

private struct BossBattleCard: View {
	let battle: BossBattle
	@State private var isExpanded = false

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			Button {
				withAnimation(.easeInOut(duration: 0.2)) {
					isExpanded.toggle()
				}
			} label: {
					HStack(alignment: .top, spacing: 10) {
						Image(systemName: "chevron.right")
							.font(.subheadline.weight(.semibold))
							.foregroundStyle(.primary)
						.rotationEffect(.degrees(isExpanded ? 90 : 0))
						.frame(width: 18, height: 18)
						.padding(.top, 6)

					Text("\(battle.levelCap)")
						.font(.largeTitle.weight(.semibold))
						.monospacedDigit()

					VStack(alignment: .leading, spacing: 0) {
						Text(battle.trainerName)
							.font(.title2)
							.fontWeight(.bold)
						Text(battle.battleLabel)
							.font(.footnote)
							.foregroundStyle(.secondary)
					}

					Spacer()

					if let primaryType = battle.primaryType {
						TypeBadge(type: primaryType, size: 42)
					}
				}
			}
			.buttonStyle(.plain)

			if isExpanded {
				ForEach(battle.party) { pokemon in
					PokemonCard(pokemon: pokemon)
				}
			}
		}
		.padding(.horizontal, 2)
		.padding(.vertical, 8)
	}
}

private struct PokemonCard: View {
	let pokemon: PartyPokemon

	private let imageSlotWidth: CGFloat = 92
	private let movesColumnGap: CGFloat = 34

	var body: some View {
		let leftMoves = Array(pokemon.moves.prefix(2))
		let rightMoves = Array(pokemon.moves.dropFirst(2).prefix(2))

		VStack(alignment: .leading, spacing: 10) {
			HStack(alignment: .firstTextBaseline, spacing: 12) {
				Text("\(pokemon.level)")
					.font(.title.weight(.bold))
					.monospacedDigit()

				Text(pokemon.name)
					.font(.title3)
					.fontWeight(.bold)

				Text("\(pokemon.baseStats)")
					.font(.body)
					.monospacedDigit()

				Spacer(minLength: 8)
				ForEach(pokemon.types, id: \.rawValue) { type in
					TypeBadge(type: type, size: 30)
				}
			}

			HStack(alignment: .top, spacing: 10) {
				HStack(alignment: .top, spacing: movesColumnGap) {
					VStack(alignment: .leading, spacing: 14) {
						ForEach(leftMoves) { move in
							MoveCell(move: move)
						}
					}

					VStack(alignment: .leading, spacing: 14) {
						ForEach(rightMoves) { move in
							MoveCell(move: move)
						}
					}
				}

				BossPokemonSprite(name: pokemon.name, width: imageSlotWidth)
			}

			if let heldItem = pokemon.heldItem {
				Label(heldItem, systemImage: "carrot")
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 12)
				.stroke(Color.gray.opacity(0.25), lineWidth: 1)
		)
	}
}

private struct BossPokemonSprite: View {
	let name: String
	let width: CGFloat

	var body: some View {
#if canImport(UIKit)
		Group {
			if let image = BossSpriteStore.uiImage(for: name) {
				Image(uiImage: image)
					.resizable()
					.interpolation(.none)
					.scaledToFit()
			} else {
				Color.clear
			}
		}
		.frame(width: width, height: width, alignment: .bottomTrailing)
#else
		Color.clear
			.frame(width: width, height: width, alignment: .bottomTrailing)
#endif
	}
}

#if canImport(UIKit)
private enum BossSpriteStore {
	static func uiImage(for pokemonName: String) -> UIImage? {
		let resource = normalizedResourceName(from: pokemonName)
		let url =
			Bundle.main.url(forResource: resource, withExtension: "png", subdirectory: "data/sprites") ??
			Bundle.main.url(forResource: resource, withExtension: "png")
		guard let url else { return nil }
		return UIImage(contentsOfFile: url.path)
	}

	private static func normalizedResourceName(from name: String) -> String {
		let lowered = name.lowercased()
		let kept = lowered.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
		return String(String.UnicodeScalarView(kept))
	}
}
#endif

private struct MoveCell: View {
	let move: MoveInfo

	var body: some View {
		VStack(alignment: .leading, spacing: 7) {
			Text(move.name)
				.font(.subheadline.weight(.medium))
				.lineLimit(1)

			HStack(spacing: 6) {
				Image(systemName: move.category.symbol)
					.font(.caption2)
					.frame(width: 22, height: 22)
					.background(Circle().fill(move.category.tint))

				TypeBadge(type: move.type, size: 22)

				if let power = move.power {
					Text("\(power)")
						.font(.caption)
						.monospacedDigit()
						.lineLimit(1)
						.fixedSize(horizontal: true, vertical: false)
				}
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

private struct TypeBadge: View {
	let type: PokeType
	let size: CGFloat

	var body: some View {
		Text(type.shortCode)
			.font(.system(size: size * 0.42, weight: .bold))
			.foregroundStyle(.white)
			.frame(width: size, height: size)
			.background(Circle().fill(Color(hex: type.bubbleHex)))
	}
}
