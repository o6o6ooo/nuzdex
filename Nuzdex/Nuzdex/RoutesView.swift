import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RoutesView: View {
	let game: GameId
	@State private var routes: [RouteEntry] = []
	private let topContentInset: CGFloat = 56

	private let spriteColumns = [
		GridItem(.adaptive(minimum: 56, maximum: 56), spacing: 6, alignment: .leading)
	]

	private var routeIndexEntries: [RouteIndexEntry] {
		var seen = Set<String>()
		var entries: [RouteIndexEntry] = []
		for route in routes {
			let label = route.indexKey
			if seen.insert(label).inserted {
				entries.append(RouteIndexEntry(label: label, targetId: route.id))
			}
		}
		return entries
	}

	var body: some View {
		ScrollViewReader { proxy in
			ZStack(alignment: .topTrailing) {
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
										.font(.headline.weight(.semibold))

									LazyVGrid(columns: spriteColumns, alignment: .leading, spacing: 8) {
										ForEach(route.pokemon.indices, id: \.self) { index in
											let pokemon = route.pokemon[index]
											RouteSprite(name: pokemon.name, size: 56)
										}
									}
								}
								.id(route.id)
							}
						}
						.padding(.top, topContentInset)
						.padding(.horizontal, 20)
						.padding(.bottom, 24)
					}
				}

				if !routeIndexEntries.isEmpty {
					RouteIndexBar(entries: routeIndexEntries) { target in
						withAnimation(.easeInOut(duration: 0.18)) {
							proxy.scrollTo(target, anchor: .top)
						}
					}
					.padding(.top, topContentInset + 6)
					.padding(.trailing, 4)
				}
			}
		}
		.onAppear(perform: load)
		.onChange(of: game.rawValue) { _, _ in load() }
	}

	private func load() {
		routes = RouteDataStore.routes(for: game)
	}
}

private struct RouteIndexEntry: Identifiable {
	let label: String
	let targetId: String

	var id: String { label }
}

private struct RouteIndexBar: View {
	let entries: [RouteIndexEntry]
	let onSelect: (String) -> Void

	var body: some View {
		VStack(spacing: 2) {
			ForEach(entries) { entry in
				Button(entry.label) {
					onSelect(entry.targetId)
				}
				.buttonStyle(.plain)
				.font(.caption2.weight(.semibold))
				.foregroundStyle(.secondary)
				.frame(width: 20, height: 14)
				.contentShape(Rectangle())
			}
		}
		.padding(.vertical, 6)
		.padding(.horizontal, 2)
		.background(
			RoundedRectangle(cornerRadius: 8, style: .continuous)
				.fill(.ultraThinMaterial.opacity(0.55))
		)
	}
}

private struct RouteEntry: Identifiable, Decodable {
	let routeName: String
	let pokemon: [RoutePokemon]

	var id: String { routeName }

	var indexKey: String {
		let lower = routeName.lowercased()
		if lower.hasPrefix("route ") {
			let digits = routeName.filter(\.isNumber)
			if digits.count >= 2 {
				return String(digits.prefix(2))
			}
			if let first = digits.first {
				return String(first)
			}
		}

		if let first = routeName.first {
			return String(first).uppercased()
		}
		return "#"
	}

	enum CodingKeys: String, CodingKey {
		case routeName
		case pokemon
		case pokemonNames
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		routeName = try container.decode(String.self, forKey: .routeName)
		let decoded = Self.decodePokemon(from: container)
		pokemon = decoded.sorted(by: Self.pokemonSort)
	}

	private static func decodePokemon(from container: KeyedDecodingContainer<CodingKeys>) -> [RoutePokemon] {
		if let pokemon = try? container.decodeIfPresent([RoutePokemon].self, forKey: .pokemon) {
			return pokemon
		}

		if let pokemonNames = try? container.decodeIfPresent([RoutePokemon].self, forKey: .pokemonNames) {
			return pokemonNames
		}

		if let names = try? container.decodeIfPresent([String].self, forKey: .pokemon) {
			return names.map { RoutePokemon(name: $0) }
		}

		if let names = try? container.decodeIfPresent([String].self, forKey: .pokemonNames) {
			return names.map { RoutePokemon(name: $0) }
		}

		return []
	}

	nonisolated private static func pokemonSort(lhs: RoutePokemon, rhs: RoutePokemon) -> Bool {
		lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
	}
}

private struct RoutePokemon: Decodable, Hashable {
	let name: String

	enum CodingKeys: String, CodingKey {
		case name
	}

	init(name: String) {
		self.name = name
	}

	init(from decoder: Decoder) throws {
		if let single = try? decoder.singleValueContainer(),
		   let name = try? single.decode(String.self) {
			self.init(name: name)
			return
		}

		let container = try decoder.container(keyedBy: CodingKeys.self)
		let name = try container.decode(String.self, forKey: .name)
		self.init(name: name)
	}
}

	private enum RouteDataStore {
		static func routes(for game: GameId) -> [RouteEntry] {
			let url: URL?
		switch game {
		case .emerald:
			url =
				Bundle.main.url(forResource: "routes_emerald", withExtension: "json", subdirectory: "data/emerald") ??
				Bundle.main.url(forResource: "routes_emerald", withExtension: "json")
		case .fireRed:
			url =
				Bundle.main.url(forResource: "routes_firered", withExtension: "json", subdirectory: "data/firered") ??
				Bundle.main.url(forResource: "routes_firered", withExtension: "json")
		case .leafGreen:
			url =
				Bundle.main.url(forResource: "routes_leafgreen", withExtension: "json", subdirectory: "data/leafgreen") ??
				Bundle.main.url(forResource: "routes_leafgreen", withExtension: "json")
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

	nonisolated private static func routeSort(lhs: RouteEntry, rhs: RouteEntry) -> Bool {
		let l = routeNumber(from: lhs.routeName)
		let r = routeNumber(from: rhs.routeName)
		if l != r { return l < r }
		return lhs.routeName.localizedCaseInsensitiveCompare(rhs.routeName) == .orderedAscending
	}

	nonisolated private static func routeNumber(from routeName: String) -> Int {
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
