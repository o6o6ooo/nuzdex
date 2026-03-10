import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RoutesView: View {
	let game: GameId
	@State private var routes: [RouteEntry] = []
	@State private var visibleNoteText: String?
	@State private var visibleNoteTargetId: String?
	@State private var noteDisplayToken = 0
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
								ForEach(route.pokemon.indices, id: \.self) { index in
									let pokemon = route.pokemon[index]
									let targetId = "\(route.id.uuidString)-\(index)"
									Button {
										showNoteIfAvailable(for: pokemon, targetId: targetId)
									} label: {
										RouteSprite(name: pokemon.name, size: 56)
									}
									.buttonStyle(.plain)
									.anchorPreference(
										key: RouteNoteAnchorKey.self,
										value: .bounds
									) { [targetId: $0] }
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
		.overlayPreferenceValue(RouteNoteAnchorKey.self) { anchors in
			GeometryReader { proxy in
				if let targetId = visibleNoteTargetId,
				   let visibleNoteText,
				   let anchor = anchors[targetId] {
					let frame = proxy[anchor]
					RouteInlineNote(text: visibleNoteText)
						.position(x: frame.midX, y: frame.minY - 8)
				}
			}
		}
		.onAppear(perform: load)
		.onChange(of: game.rawValue) { _, _ in load() }
	}

	private func load() {
		routes = RouteDataStore.routes(for: game)
	}

	private func showNoteIfAvailable(for pokemon: RoutePokemon, targetId: String) {
		let trimmed = pokemon.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		guard !trimmed.isEmpty else { return }
		noteDisplayToken += 1
		let token = noteDisplayToken
		visibleNoteText = trimmed
		visibleNoteTargetId = targetId
		DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
			guard token == noteDisplayToken else { return }
			visibleNoteText = nil
			visibleNoteTargetId = nil
		}
	}
}

private struct RouteInlineNote: View {
	let text: String

	var body: some View {
		Text(text)
			.font(.footnote)
			.foregroundStyle(.primary)
			.lineLimit(2)
			.multilineTextAlignment(.center)
			.padding(.horizontal, 3)
			.padding(.vertical, 2)
			.fixedSize(horizontal: true, vertical: true)
			.background(
				RoundedRectangle(cornerRadius: 4, style: .continuous)
					.fill(Color(.systemBackground))
					.overlay(
						RoundedRectangle(cornerRadius: 4, style: .continuous)
							.stroke(Color.primary.opacity(0.18), lineWidth: 1)
					)
			)
	}
}

private struct RouteNoteAnchorKey: PreferenceKey {
	static var defaultValue: [String: Anchor<CGRect>] = [:]

	static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
		value.merge(nextValue(), uniquingKeysWith: { _, new in new })
	}
}

private struct RouteEntry: Identifiable, Decodable {
	let id = UUID()
	let routeName: String
	let pokemon: [RoutePokemon]

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
			return names.map { RoutePokemon(name: $0, notes: nil) }
		}

		if let names = try? container.decodeIfPresent([String].self, forKey: .pokemonNames) {
			return names.map { RoutePokemon(name: $0, notes: nil) }
		}

		return []
	}

	nonisolated private static func pokemonSort(lhs: RoutePokemon, rhs: RoutePokemon) -> Bool {
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
		let name = try container.decode(String.self, forKey: .name)
		let notes = try container.decodeIfPresent(String.self, forKey: .notes)
		self.init(name: name, notes: notes)
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
