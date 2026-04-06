import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BossBattle: Identifiable, Decodable {
	let game: GameId
	let category: BattleCategory
	let trainerId: String
	let trainerName: String
	let battleLabel: String
	let primaryType: PokeType?
	let levelCap: Int
	let starterBranch: String?
	let party: [PartyPokemon]

	var id: String { "\(game.rawValue)-\(trainerId)" }
}

extension GameId {
	var dataDirectoryName: String? {
		switch self {
		case .ruby:
			return "ruby"
		case .sapphire:
			return "sapphire"
		case .emerald:
			return "emerald"
		case .platinum:
			return "platinum"
		case .fireRed:
			return "firered"
		case .leafGreen:
			return "leafgreen"
		default:
			return nil
		}
	}

	var battlesJSONSubdirectory: String? {
		guard let dataDirectoryName else { return nil }
		return "data/\(dataDirectoryName)/battles"
	}

	var bossesJSONSubdirectories: [String] {
		guard let dataDirectoryName else { return [] }
		return [
			"data/\(dataDirectoryName)/gymleaders",
			"data/\(dataDirectoryName)/elite4",
		]
	}

	var routeResourceName: String? {
		guard let dataDirectoryName else { return nil }
		return "routes_\(dataDirectoryName)"
	}
}

enum BattleDataStore {
	@MainActor
	static func battles(for game: GameId, starterBranch: String) -> [BossBattle] {
		let battles = loadAllJSONBattles(for: game).filter { battle in
			battle.game == game && (battle.category == .rival || battle.category == .evilTeam || battle.category == .other)
		}

		let filtered = battles.filter { battle in
			guard let branch = battle.starterBranch else { return true }
			return branch == starterBranch
		}

		return filtered.sorted(by: battleSort)
	}

	@MainActor
	private static func loadAllJSONBattles(for game: GameId) -> [BossBattle] {
		let rootURLs = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
		let extraURLs = game.battlesJSONSubdirectory
			.flatMap { Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: $0) } ?? []

		let urls = Array(Set(rootURLs + extraURLs))
			.sorted { $0.lastPathComponent < $1.lastPathComponent }
		return urls.compactMap(decode)
	}

	private static func decode(url: URL) -> BossBattle? {
		do {
			let data = try Data(contentsOf: url)
			return try JSONDecoder().decode(BossBattle.self, from: data)
		} catch {
			return nil
		}
	}

	private static func battleSort(lhs: BossBattle, rhs: BossBattle) -> Bool {
		if lhs.levelCap != rhs.levelCap { return lhs.levelCap < rhs.levelCap }
		if lhs.battleLabel != rhs.battleLabel { return lhs.battleLabel < rhs.battleLabel }
		return lhs.trainerName < rhs.trainerName
	}
}

enum BattleCategory: String, Decodable {
	case gymLeader
	case eliteFour
	case rival
	case evilTeam
	case other
}

struct PartyPokemon: Identifiable, Decodable {
	let baseStats: Int
	let name: String
	let level: Int
	let types: [PokeType]
	let heldItem: String?
	let moves: [MoveInfo]

	var id: String { "\(name)-\(level)-\(baseStats)" }
}

struct MoveInfo: Identifiable, Decodable {
	let name: String
	let category: MoveCategory
	let type: PokeType
	let power: Int?

	var id: String { name }
}

enum MoveCategory: String, Decodable {
	case status
	case physical
	case special

	var symbol: String {
		switch self {
		case .status: return "circle.lefthalf.filled"
		case .physical: return "burst.fill"
		case .special:
#if canImport(UIKit)
			return UIImage(systemName: "target") != nil ? "target" : "smallcircle.filled.circle"
#else
			return "smallcircle.filled.circle"
#endif
		}
	}

	var tint: Color {
		switch self {
		case .status: return Color(hex: "#DFDFDF")
		case .physical: return Color(hex: "#F0D6D8")
		case .special: return Color(hex: "#CFE7E5")
		}
	}
}

enum PokeType: String, Decodable {
	case normal
	case fire
	case water
	case electric
	case grass
	case ice
	case fighting
	case poison
	case ground
	case flying
	case psychic
	case bug
	case rock
	case ghost
	case dragon
	case dark
	case steel
	case fairy

	var shortCode: String {
		switch self {
		case .normal: return "N"
		case .fire: return "F"
		case .water: return "W"
		case .electric: return "E"
		case .grass: return "G"
		case .ice: return "I"
		case .fighting: return "F"
		case .poison: return "P"
		case .ground: return "G"
		case .flying: return "F"
		case .psychic: return "P"
		case .bug: return "B"
		case .rock: return "R"
		case .ghost: return "G"
		case .dragon: return "D"
		case .dark: return "D"
		case .steel: return "S"
		case .fairy: return "F"
		}
	}

	var bubbleHex: String {
		switch self {
		case .normal: return "#E0E0E0"
		case .fire: return "#DD2728"
		case .water: return "#5C9BD1"
		case .electric: return "#FCD746"
		case .grass: return "#009A4B"
		case .ice: return "#89CFF0"
		case .fighting: return "#F26522"
		case .poison: return "#607CAC"
		case .ground: return "#E8C99A"
		case .flying: return "#B5D7FF"
		case .psychic: return "#F59EC3"
		case .bug: return "#5A7D6D"
		case .rock: return "#A98470"
		case .ghost: return "#094886"
		case .dragon: return "#007AFF"
		case .dark: return "#6D6C70"
		case .steel: return "#A5C3DE"
		case .fairy: return "#F7D6D6"
		}
	}
}

enum BossDataStore {
	@MainActor
	static func battles(for game: GameId) -> [BossBattle] {
		let battles = loadAllJSONBattles(for: game).filter { battle in
			battle.game == game && (battle.category == .gymLeader || battle.category == .eliteFour)
		}
		return battles.sorted(by: battleSort)
	}

	@MainActor
	private static func loadAllJSONBattles(for game: GameId) -> [BossBattle] {
		let rootURLs = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
		let extraURLs = game.bossesJSONSubdirectories.flatMap {
			Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: $0) ?? []
		}

		let urls = Array(Set(rootURLs + extraURLs))
			.sorted { $0.lastPathComponent < $1.lastPathComponent }
		return urls.compactMap(decode)
	}

	private static func decode(url: URL) -> BossBattle? {
		do {
			let data = try Data(contentsOf: url)
			return try JSONDecoder().decode(BossBattle.self, from: data)
		} catch {
			print("Failed to load \(url.lastPathComponent): \(error)")
			return nil
		}
	}

	private static func battleSort(lhs: BossBattle, rhs: BossBattle) -> Bool {
		let lCategory = categoryOrder(lhs.category)
		let rCategory = categoryOrder(rhs.category)
		if lCategory != rCategory { return lCategory < rCategory }
		if lhs.levelCap != rhs.levelCap { return lhs.levelCap < rhs.levelCap }
		return lhs.trainerName < rhs.trainerName
	}

	private static func categoryOrder(_ category: BattleCategory) -> Int {
		switch category {
		case .gymLeader: return 0
		case .eliteFour: return 1
		default: return 2
		}
	}
}
