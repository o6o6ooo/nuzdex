import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RoutesView: View {
	let game: GameId
	@State private var routes: [RouteEntry] = []
	@State private var selectedNote: RoutePokemonNote?
	private let topContentInset: CGFloat = 56

	private let spriteColumns = [
		GridItem(.adaptive(minimum: 56, maximum: 56), spacing: 6, alignment: .leading)
	]

	var body: some View {
		ScrollView {
			if routes.isEmpty {
				ContentUnavailableView(
					"No Route Data Yet",
					systemImage: "tray",
					description: Text("Add JSON files under data for \(game.rawValue).")
				)
				.padding(.top, topContentInset + 24)
			} else {
				LazyVStack(alignment: .leading, spacing: 32) {
					ForEach(routes) { route in
						VStack(alignment: .leading, spacing: 14) {
							Text(route.routeName)
								.font(.system(size: 18, weight: .semibold))

							LazyVGrid(columns: spriteColumns, alignment: .leading, spacing: 8) {
								ForEach(Array(route.pokemon.enumerated()), id: \.offset) { _, pokemon in
									Button {
										showNoteIfAvailable(for: pokemon)
									} label: {
										RouteSprite(name: pokemon.name, size: 56)
									}
									.buttonStyle(.plain)
								}
							}
						}
					}
				}
				.padding(.top, topContentInset)
				.padding(.horizontal, 20)
				.padding(.bottom, 24)
			}
		}
		.onAppear(perform: load)
		.onChange(of: game.rawValue) { _, _ in load() }
		.alert(item: $selectedNote) { note in
			Alert(
				title: Text(note.name),
				message: Text(note.notes),
				dismissButton: .default(Text("OK"))
			)
		}
	}

	private func load() {
		routes = RouteDataStore.routes(for: game)
	}

	private func showNoteIfAvailable(for pokemon: RoutePokemon) {
		let trimmed = pokemon.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		guard !trimmed.isEmpty else { return }
		selectedNote = RoutePokemonNote(name: pokemon.name, notes: trimmed)
	}
}

private struct RouteEntry: Identifiable, Decodable {
	let routeName: String
	let pokemon: [RoutePokemon]

	var id: String { routeName }

	enum CodingKeys: String, CodingKey {
		case routeName
		case pokemon
		case pokemonNames
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		routeName = try container.decode(String.self, forKey: .routeName)
		let decoded =
			(try? container.decodeIfPresent([RoutePokemon].self, forKey: .pokemon)) ??
			(try? container.decodeIfPresent([RoutePokemon].self, forKey: .pokemonNames)) ??
			(try? container.decodeIfPresent([String].self, forKey: .pokemon))?.map { RoutePokemon(name: $0, notes: nil) } ??
			(try? container.decodeIfPresent([String].self, forKey: .pokemonNames))?.map { RoutePokemon(name: $0, notes: nil) } ??
			[]
		pokemon = decoded.sorted(by: Self.pokemonSort)
	}

	private static func pokemonSort(lhs: RoutePokemon, rhs: RoutePokemon) -> Bool {
		lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
	}
}

private struct RoutePokemon: Decodable, Hashable {
	let name: String
	let notes: String?

	enum CodingKeys: String, CodingKey {
		case name
		case notes
	}

	init(name: String, notes: String?) {
		self.name = name
		self.notes = notes
	}

	init(from decoder: Decoder) throws {
		if let single = try? decoder.singleValueContainer(),
		   let name = try? single.decode(String.self) {
			self.init(name: name, notes: nil)
			return
		}

		let container = try decoder.container(keyedBy: CodingKeys.self)
		name = try container.decode(String.self, forKey: .name)
		notes = try container.decodeIfPresent(String.self, forKey: .notes)
	}
}

private struct RoutePokemonNote: Identifiable {
	let id = UUID()
	let name: String
	let notes: String
}

private enum RouteDataStore {
	static func routes(for game: GameId) -> [RouteEntry] {
		let url: URL?
		switch game {
		case .emerald:
			url =
				Bundle.main.url(forResource: "routes", withExtension: "json", subdirectory: "data/emerald") ??
				Bundle.main.url(forResource: "routes", withExtension: "json")
		default:
			url = nil
		}

		guard let url else { return [] }
		return decodeRoutes(from: url).sorted(by: routeSort)
	}

	private static func decodeRoutes(from url: URL) -> [RouteEntry] {
		do {
			let data = try Data(contentsOf: url)
			let decoder = JSONDecoder()
			if let routes = try? decoder.decode([RouteEntry].self, from: data) {
				return routes
			}
			if let route = try? decoder.decode(RouteEntry.self, from: data) {
				return [route]
			}
			return []
		} catch {
			return []
		}
	}

	private static func routeSort(lhs: RouteEntry, rhs: RouteEntry) -> Bool {
		let l = routeNumber(from: lhs.routeName)
		let r = routeNumber(from: rhs.routeName)
		if l != r { return l < r }
		return lhs.routeName.localizedCaseInsensitiveCompare(rhs.routeName) == .orderedAscending
	}

	private static func routeNumber(from routeName: String) -> Int {
		let digits = routeName.filter(\.isNumber)
		return Int(digits) ?? Int.max
	}
}

private struct RouteSprite: View {
	let name: String
	let size: CGFloat

	var body: some View {
#if canImport(UIKit)
		Group {
			if let image = RouteSpriteStore.uiImage(for: name) {
				Image(uiImage: image)
					.resizable()
					.interpolation(.none)
					.scaledToFit()
			} else {
				Color.clear
			}
		}
		.frame(width: size, height: size)
#else
		Color.clear
			.frame(width: size, height: size)
#endif
	}
}

#if canImport(UIKit)
private enum RouteSpriteStore {
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
