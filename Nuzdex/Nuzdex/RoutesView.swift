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
								ForEach(route.pokemon, id: \.self) { pokemon in
									RouteSprite(name: pokemon, size: 56)
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
	}

	private func load() {
		routes = RouteDataStore.routes(for: game)
	}
}

private struct RouteEntry: Identifiable, Decodable {
	let routeName: String
	let pokemon: [String]

	var id: String { routeName }

	enum CodingKeys: String, CodingKey {
		case routeName
		case pokemon
		case pokemonNames
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		routeName = try container.decode(String.self, forKey: .routeName)
		if let pokemon = try container.decodeIfPresent([String].self, forKey: .pokemon) {
			self.pokemon = pokemon
		} else {
			self.pokemon = try container.decodeIfPresent([String].self, forKey: .pokemonNames) ?? []
		}
	}
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
		return lhs.routeName < rhs.routeName
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
