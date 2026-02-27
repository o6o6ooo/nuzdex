import SwiftUI

// MARK: - Hex Color

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r, g, b: Double
        switch cleaned.count {
        case 6:
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Models

enum GameId: String, CaseIterable, Identifiable {
    case ruby = "Ruby"
        case sapphire = "Sapphire"
        case emerald = "Emerald"
        case fireRed = "Fire Red"
        case leafGreen = "Leaf Green"
        case diamond = "Diamond"
        case pearl = "Pearl"
        case platinum = "Platinum"
        case heartGold = "Heart Gold"
        case soulSilver = "Soul Silver"
        case black = "Black"
        case white = "White"
        case black2 = "Black 2"
        case white2 = "White 2"
        case renegadePlatinum = "Renegade Platinum"

    var id: String { rawValue }

    var shortCode: String {
        switch self {
        case .ruby: return "R"
        case .sapphire: return "S"
        case .emerald: return "E"
        case .fireRed: return "FR"
        case .leafGreen: return "LG"
        case .diamond: return "D"
        case .pearl: return "P"
        case .platinum: return "Pt"
        case .heartGold: return "HG"
        case .soulSilver: return "SS"
        case .black: return "B"
        case .white: return "W"
        case .black2: return "B2"
        case .white2: return "W2"
        case .renegadePlatinum: return "Pt*"
        }
    }

    // ✅ あなたの色をここで hex 指定（後で増やせる）
    var bubbleHex: String {
        switch self {
        case .ruby: return "#DD2728"
        case .sapphire: return "#2480F2"
        case .emerald: return "#027145"
        case .fireRed: return "#F26522"
        case .leafGreen: return "#B8DCD3"
        case .diamond: return "#4F89B7"
        case .pearl: return "#E4A8AA"
        case .platinum: return "#E5E5EA"
        case .heartGold: return "#FCD746"
        case .soulSilver: return "#A5C3DE"
        case .black: return "#2A3140"
        case .white: return "#FEF9EF"
        case .black2: return "#2A3140"
        case .white2: return "#FEF9EF"
        case .renegadePlatinum: return "#E5E5EA"
        }
    }

    var textColor: Color {
        switch self {
        case .white, .white2, .renegadePlatinum:
            return Color(hex: "#2A3140")
            default:
            return .white
        }
    }
}

// MARK: - View

struct GamePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedGame") private var selectedGameRaw = GameId.emerald.rawValue

    // どれが「フォーカス（拡大）」されてるか
    @State private var focused: GameId? = nil
    @State private var layout: [GameId: CGPoint] = [:]
    @State private var centerGame: GameId = .emerald
    @State private var wobbleSeed: [GameId: Double] = [:]
    private let wobbleAmplitude: CGFloat = 10

    // ✅ ぬるっと感：指のドラッグ量で全体がちょい動く（watchっぽい）
    @State private var pan: CGSize = .zero
    @GestureState private var isPanning: Bool = false

    private var selectedGame: GameId {
        GameId(rawValue: selectedGameRaw) ?? .emerald
    }

    // バブルサイズ（小さくしたいとのことなので）
    private let bubbleSize: CGFloat = 78
    private let gap: CGFloat = 18

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景（真っ白でもOK。薄いグラデにしたいなら後で）
                Color(.systemBackground)
                    .ignoresSafeArea()

                // バブル配置（中央寄せ）
                bubbleCluster
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(panGesture)
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: pan)
                    .animation(.spring(response: 0.28, dampingFraction: 0.85), value: focused)

                // フォーカス中は背景タップで閉じる
                if focused != nil {
                    Color.black.opacity(0.001) // タップ受け用（見えない）
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                focused = nil
                            }
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                focused = nil
                generateLayout()
            }
        }
    }

    // MARK: - Bubble Cluster

    private var bubbleCluster: some View {
        let items = Array(GameId.allCases)
        let indexed = Array(items.enumerated())

        return TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                ForEach(indexed, id: \.1.id) { index, game in
                    bubbleView(index: index, game: game, t: t)
                }
            }
            .padding(24)
            .offset(y: -20)
        }
    }
    
    private func generateLayout() {
        var rng = SystemRandomNumberGenerator()
        let items = Array(GameId.allCases)

        let minDist: CGFloat = 86   // バブル直径(80) + 余白(6) くらい
        let bounds: CGFloat = 165   // クラスターの広がり
        let maxTriesPerItem = 400

        var newLayout: [GameId: CGPoint] = [:]
        var newSeed: [GameId: Double] = [:]

        func ok(_ p: CGPoint) -> Bool {
            for (_, q) in newLayout {
                let dx = p.x - q.x, dy = p.y - q.y
                if (dx*dx + dy*dy) < (minDist*minDist) { return false }
            }
            return true
        }

        for game in items {
            var placed: CGPoint? = nil

            for _ in 0..<maxTriesPerItem {
                let x = CGFloat.random(in: -bounds...bounds, using: &rng)
                let y = CGFloat.random(in: -bounds...bounds, using: &rng)
                let p = CGPoint(x: x, y: y)

                if ok(p) {
                    placed = p
                    break
                }
            }

            // どうしても置けない時は少し妥協（最後の保険）
            newLayout[game] = placed ?? CGPoint(
                x: CGFloat.random(in: -bounds...bounds, using: &rng),
                y: CGFloat.random(in: -bounds...bounds, using: &rng)
            )

            newSeed[game] = Double.random(in: 0...1000, using: &rng)
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
            layout = newLayout
            wobbleSeed = newSeed
        }
    }
    
    @ViewBuilder
    private func bubbleView(index: Int, game: GameId, t: TimeInterval) -> some View {
        let base = layout[game] ?? .zero
        let seed = wobbleSeed[game] ?? 0

        // フォーカス中は揺れ止める（読みやすい）
        let wobbleOn = (focused == nil)

        // それぞれ違う周期でゆらゆら
        let s = seed
        let wx = wobbleOn ? (
          CGFloat(sin(t * 0.73 + s)) +
          0.6 * CGFloat(sin(t * 1.11 + s * 1.7)) +
          0.35 * CGFloat(sin(t * 1.73 + s * 0.4))
        ) * (wobbleAmplitude / 1.95) : 0

        let wy = wobbleOn ? (
          CGFloat(cos(t * 0.61 + s * 1.3)) +
          0.55 * CGFloat(cos(t * 1.27 + s)) +
          0.3 * CGFloat(cos(t * 1.91 + s * 2.1))
        ) * (wobbleAmplitude / 1.85) : 0

        Bubble(
            shortTitle: game.shortCode,
            fullTitle: game.rawValue,
            fill: Color(hex: game.bubbleHex),
            text: game.textColor,
            size: bubbleSize,
            isFocused: focused == game,
            onTap: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                    focused = (focused == game ? nil : game)
                }
            },
            onOpen: {
                selectedGameRaw = game.rawValue
                dismiss()
            }
        )
        .offset(
            x: base.x + wx + parallax(for: index).width,
            y: base.y + wy + parallax(for: index).height
        )
        .opacity(focused == nil || focused == game ? 1.0 : 0.35)
        .allowsHitTesting(focused == nil || focused == game)
        .zIndex(focused == game ? 999 : Double(100 - index))
    }

    // ✅ ぬるっと感：ドラッグ量を index ごとに弱めて反映（パララックス）
    private func parallax(for index: Int) -> CGSize {
        let strength = max(0.18, 0.55 - Double(index) * 0.06) // 奥行き差
        return CGSize(
            width: pan.width * strength,
            height: pan.height * strength
        )
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isPanning) { _, state, _ in
                state = true
            }
            .onChanged { value in
                // フォーカス中は動かさない（見やすさ優先）
                guard focused == nil else { return }
                pan = CGSize(
                    width: clamp(value.translation.width, -22, 22),
                    height: clamp(value.translation.height, -22, 22)
                )
            }
            .onEnded { _ in
                // ふわっと中心に戻る
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    pan = .zero
                }
            }
    }

    private func clamp(_ v: CGFloat, _ minV: CGFloat, _ maxV: CGFloat) -> CGFloat {
        min(max(v, minV), maxV)
    }
}

// MARK: - Bubble

struct Bubble: View {
    let shortTitle: String
    let fullTitle: String
    let fill: Color
    let text: Color
    let size: CGFloat
    let isFocused: Bool
    let onTap: () -> Void
    let onOpen: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(fill)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 12)

                VStack(spacing: 10) {
                    if isFocused {
                        // ✅ フルネーム（2行まで）
                        Text(fullTitle)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(text)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 12)

                        // ✅ Open ピル（はみ出さないサイズに）
                        Button(action: onOpen) {
                            Text("Open")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(.ultraThinMaterial)
                                )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        Text(shortTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(text)
                    }
                }
            }
            .frame(width: size, height: size)
            // ✅ フォーカス時はかなり大きく（Openが収まる）
            .scaleEffect(isFocused ? 1.3 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct GamePickerView_Previews: PreviewProvider {
    static var previews: some View {
        GamePickerView()
    }
}
