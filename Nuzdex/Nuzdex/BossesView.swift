import SwiftUI

struct BossesView: View {
	let game: GameId
	@State private var battles: [BossBattle] = []

	var body: some View {
		ScrollView {
			if battles.isEmpty {
				ContentUnavailableView(
					"No Boss Data Yet",
					systemImage: "tray",
					description: Text("Add JSON files under data for \(game.rawValue).")
				)
				.padding(.top, 40)
			} else {
				LazyVStack(spacing: 16) {
					ForEach(battles) { battle in
						BossBattleCard(battle: battle)
					}
				}
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
	@State private var isExpanded = true

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
						.font(.system(size: 34, weight: .heavy))
						.monospacedDigit()

					VStack(alignment: .leading, spacing: 0) {
						Text(battle.trainerName)
							.font(.title2)
							.fontWeight(.bold)
						Text(battle.battleLabel)
							.font(.subheadline)
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

	private let levelColumnWidth: CGFloat = 52
	private let movesLeadingInset: CGFloat = 12
	private let imageSlotWidth: CGFloat = 44
	private let movesColumnGap: CGFloat = 34

	var body: some View {
		let leftMoves = Array(pokemon.moves.prefix(2))
		let rightMoves = Array(pokemon.moves.dropFirst(2).prefix(2))

		VStack(alignment: .leading, spacing: 10) {
			HStack(alignment: .firstTextBaseline, spacing: 12) {
				Text("\(pokemon.level)")
					.font(.system(size: 24, weight: .heavy))
					.monospacedDigit()
					.frame(width: levelColumnWidth, alignment: .trailing)

				Text(pokemon.name)
					.font(.title3)
					.fontWeight(.bold)

				Text("\(pokemon.baseStats)")
					.font(.system(size: 17, weight: .regular))
					.monospacedDigit()

				Spacer(minLength: 8)
				ForEach(pokemon.types, id: \.rawValue) { type in
					TypeBadge(type: type, size: 30)
				}
			}

			HStack(alignment: .top, spacing: 0) {
				Color.clear
					.frame(width: movesLeadingInset)

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

					Color.clear
							.frame(maxWidth: imageSlotWidth)
					}
				}

			if let heldItem = pokemon.heldItem {
				Label(heldItem, systemImage: "shippingbox")
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

private struct MoveCell: View {
	let move: MoveInfo

	var body: some View {
		VStack(alignment: .leading, spacing: 7) {
			Text(move.name)
				.font(.system(size: 14, weight: .regular))
				.lineLimit(1)

			HStack(spacing: 6) {
				Image(systemName: move.category.symbol)
					.font(.caption2)
					.frame(width: 22, height: 22)
					.background(Circle().fill(move.category.tint))

				TypeBadge(type: move.type, size: 24)

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
