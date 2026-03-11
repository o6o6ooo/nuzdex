import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BattlesView: View {
	let game: GameId
	@AppStorage("selectedStarterType") private var selectedStarterRaw = StarterType.grass.rawValue
	@State private var battles: [BossBattle] = []
	private let topContentInset: CGFloat = 72

	private var selectedStarter: StarterType {
		StarterType(rawValue: selectedStarterRaw) ?? .grass
	}

	var body: some View {
		ScrollView {
			if battles.isEmpty {
				VStack(spacing: 22) {
					starterPicker
					ContentUnavailableView(
						"No Battle Data Yet",
						systemImage: "tray",
						description: Text("Add JSON files under data for \(game.rawValue).")
					)
				}
				.padding(.top, topContentInset)
				.padding(.horizontal, 20)
			} else {
				VStack(spacing: 18) {
					starterPicker
					LazyVStack(spacing: 16) {
						ForEach(battles) { battle in
							BattleEntryCard(battle: battle)
						}
					}
					.padding(.horizontal, 14)
					.padding(.bottom, 20)
				}
				.padding(.top, topContentInset)
			}
		}
		.onAppear(perform: load)
		.onChange(of: game.rawValue) { _, _ in load() }
		.onChange(of: selectedStarterRaw) { _, _ in load() }
	}

	private var starterPicker: some View {
		VStack(spacing: 14) {
			Text("Starter Type")
				.font(.headline.weight(.semibold))

			HStack(spacing: 18) {
				ForEach(StarterType.allCases, id: \.rawValue) { starter in
					Button {
						selectedStarterRaw = starter.rawValue
					} label: {
						Text(starter.shortCode)
							.font(.title3.weight(.bold))
							.foregroundStyle(.white)
							.frame(width: 52, height: 52)
							.background(Circle().fill(Color(hex: starter.bubbleHex)))
							.overlay {
								Circle()
									.stroke(Color.primary.opacity(selectedStarter == starter ? 0.22 : 0.08), lineWidth: selectedStarter == starter ? 2 : 1)
							}
							.overlay(alignment: .topTrailing) {
								if selectedStarter == starter {
									Image(systemName: "checkmark.circle.fill")
										.font(.caption)
										.foregroundStyle(.white, .blue)
										.offset(x: 3, y: -3)
								}
							}
							.scaleEffect(selectedStarter == starter ? 1.0 : 0.96)
							.animation(.easeInOut(duration: 0.15), value: selectedStarter)
					}
					.buttonStyle(.plain)
				}
			}
		}
		.padding(.horizontal, 20)
	}

	private func load() {
		battles = BattleDataStore.battles(for: game, starterBranch: selectedStarterRaw)
	}
}

private struct BattleEntryCard: View {
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
							.fontWeight(.semibold)
						Text(battle.battleLabel)
							.font(.footnote)
							.foregroundStyle(.secondary)
					}

					Spacer()

					if let primaryType = battle.primaryType {
						BattleTypeBadge(type: primaryType, size: 42)
					}
				}
			}
			.buttonStyle(.plain)

			if isExpanded {
				ForEach(battle.party) { pokemon in
					BattlePokemonCard(pokemon: pokemon)
				}
			}
		}
		.padding(.horizontal, 2)
		.padding(.vertical, 8)
	}
}

private struct BattlePokemonCard: View {
	let pokemon: PartyPokemon

	private let imageSlotWidth: CGFloat = 92
	private let movesColumnGap: CGFloat = 34

	var body: some View {
		let leftMoves = Array(pokemon.moves.prefix(2))
		let rightMoves = Array(pokemon.moves.dropFirst(2).prefix(2))

		VStack(alignment: .leading, spacing: 10) {
			HStack(alignment: .firstTextBaseline, spacing: 12) {
				Text("\(pokemon.level)")
					.font(.title.weight(.semibold))
					.monospacedDigit()

				Text(pokemon.name)
					.font(.title3)
					.fontWeight(.semibold)

				Text("\(pokemon.baseStats)")
					.font(.body)
					.monospacedDigit()

				Spacer(minLength: 8)
				ForEach(pokemon.types, id: \.rawValue) { type in
					BattleTypeBadge(type: type, size: 30)
				}
			}

			HStack(alignment: .top, spacing: 10) {
				HStack(alignment: .top, spacing: movesColumnGap) {
					VStack(alignment: .leading, spacing: 14) {
						ForEach(leftMoves) { move in
							BattleMoveCell(move: move)
						}
					}

					VStack(alignment: .leading, spacing: 14) {
						ForEach(rightMoves) { move in
							BattleMoveCell(move: move)
						}
					}
				}

				BattlePokemonSprite(name: pokemon.name, width: imageSlotWidth)
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

private struct BattlePokemonSprite: View {
	let name: String
	let width: CGFloat

	var body: some View {
#if canImport(UIKit)
		Group {
			if let image = BattleSpriteStore.uiImage(for: name) {
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
private enum BattleSpriteStore {
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

private struct BattleMoveCell: View {
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

				BattleTypeBadge(type: move.type, size: 22)

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

private struct BattleTypeBadge: View {
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

private enum StarterType: String, CaseIterable {
	case grass
	case fire
	case water

	var shortCode: String {
		switch self {
		case .grass: return "G"
		case .fire: return "F"
		case .water: return "W"
		}
	}

	var bubbleHex: String {
		switch self {
		case .grass: return "#04A44D"
		case .fire: return "#EA2428"
		case .water: return "#5D99D0"
		}
	}
}
