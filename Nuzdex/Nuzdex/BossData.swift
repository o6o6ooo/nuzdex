import SwiftUI

struct BossBattle: Identifiable, Decodable {
	let game: GameId
	let category: BattleCategory
	let trainerId: String
	let trainerName: String
	let battleLabel: String
	let primaryType: PokeType?
	let levelCap: Int
	let party: [PartyPokemon]

	var id: String { "\(game.rawValue)-\(trainerId)" }
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
		case .physical: return "figure.strengthtraining.traditional"
		case .special: return "scope"
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
		case .normal: return "#D9D9DC"
		case .fire: return "#E82127"
		case .water: return "#5C98D0"
		case .electric: return "#F0CD3D"
		case .grass: return "#039648"
		case .ice: return "#7FC4E8"
		case .fighting: return "#F76B1B"
		case .poison: return "#E796C2"
		case .ground: return "#E0C493"
		case .flying: return "#A7C6EB"
		case .psychic: return "#E796C2"
		case .bug: return "#5B816E"
		case .rock: return "#A78570"
		case .ghost: return "#165295"
		case .dragon: return "#1775E6"
		case .dark: return "#6C6C72"
		case .steel: return "#9AB7D4"
		case .fairy: return "#E8C8CC"
		}
	}
}

enum BossDataStore {
	static func battles(for game: GameId) -> [BossBattle] {
		let filePaths: [String]
		switch game {
		case .emerald:
			filePaths = ["data/emerald/elite4/glacia"]
		default:
			filePaths = []
		}

		return filePaths.compactMap(load)
	}

	private static func load(path: String) -> BossBattle? {
		let parts = path.split(separator: "/")
		guard let fileName = parts.last else { return nil }
		let subdir = parts.dropLast().joined(separator: "/")

		if let url = Bundle.main.url(
			forResource: String(fileName),
			withExtension: "json",
			subdirectory: subdir.isEmpty ? nil : String(subdir)
		) {
			return decode(url: url)
		}

		if let url = Bundle.main.url(forResource: String(fileName), withExtension: "json") {
			return decode(url: url)
		}

		return nil
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
}
