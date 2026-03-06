import SwiftUI

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
				.font(.system(size: 18, weight: .semibold))

			HStack(spacing: 18) {
				ForEach(StarterType.allCases, id: \.rawValue) { starter in
					Button {
						selectedStarterRaw = starter.rawValue
					} label: {
						Text(starter.shortCode)
							.font(.system(size: 22, weight: .bold))
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
										.font(.system(size: 14))
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
						.font(.system(size: 34, weight: .bold, design: .rounded))
						.monospacedDigit()

					VStack(alignment: .leading, spacing: 0) {
						Text(battle.trainerName)
							.font(.title2)
							.fontWeight(.bold)
						Text(battle.battleLabel)
							.font(.system(size: 13, weight: .regular))
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

	private let imageSlotWidth: CGFloat = 44
	private let movesColumnGap: CGFloat = 34

	var body: some View {
		let leftMoves = Array(pokemon.moves.prefix(2))
		let rightMoves = Array(pokemon.moves.dropFirst(2).prefix(2))

		VStack(alignment: .leading, spacing: 10) {
			HStack(alignment: .firstTextBaseline, spacing: 12) {
				Text("\(pokemon.level)")
					.font(.system(size: 24, weight: .heavy, design: .rounded))
					.monospacedDigit()

				Text(pokemon.name)
					.font(.title3)
					.fontWeight(.bold)

				Text("\(pokemon.baseStats)")
					.font(.system(size: 17, weight: .regular))
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

				Color.clear
					.frame(width: imageSlotWidth)
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

private struct BattleMoveCell: View {
	let move: MoveInfo

	var body: some View {
		VStack(alignment: .leading, spacing: 7) {
			Text(move.name)
				.font(.system(size: 14, weight: .medium))
				.lineLimit(1)

			HStack(spacing: 6) {
				Image(systemName: move.category.symbol)
					.font(.caption2)
					.frame(width: 22, height: 22)
					.background(Circle().fill(move.category.tint))

				BattleTypeBadge(type: move.type, size: 22)

				if let power = move.power {
					Text("\(power)")
						.font(.system(size: 12, weight: .regular))
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
