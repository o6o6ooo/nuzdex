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

    // バブルサイズ（小さくしたいとのことなので）
    private let bubbleSize: CGFloat = 78
    private let gap: CGFloat = 18

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                // バブル
                bubbleCluster
                    .contentShape(Rectangle())

                // フォーカス時、Openボタン以外をタップで閉じるための透明レイヤーをバブルの上に
                if focused != nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                focused = nil
                            }
                        }
                        .zIndex(1) // ← これ追加
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

        return GeometryReader { geo in
            ZStack {
                ForEach(indexed, id: \.1.id) { index, game in
                    bubbleView(index: index, game: game, size: geo.size)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // ✅ ヒットテスト領域を画面いっぱいに
        }
    }
    
    private func generateLayout() {
        let items = Array(GameId.allCases)
        let horizontalSpacing = bubbleSize + gap
        let verticalSpacing = bubbleSize * 0.86 + gap // 0.86 ≒ sqrt(3)/2 for hex packing
        
        let count = items.count
        // Calculate number of columns needed (ceil of sqrt)
        let columns = Int(ceil(sqrt(Double(count))))
        // Calculate number of rows needed
        _ = Int(ceil(Double(count) / Double(columns)))
        
        var positions: [CGPoint] = []
        
        for idx in 0..<count {
            let row = idx / columns
            let col = idx % columns
            
            // x offset
            let xOffset = CGFloat(col) * horizontalSpacing + (row % 2 == 1 ? horizontalSpacing / 2 : 0)
            // y offset
            let yOffset = CGFloat(row) * verticalSpacing
            
            positions.append(CGPoint(x: xOffset, y: yOffset))
        }
        
        // Center the cluster around (0,0)
        // Calculate bounding box
        let xs = positions.map { $0.x }
        let ys = positions.map { $0.y }
        
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        
        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2
        
        var newLayout: [GameId: CGPoint] = [:]
        
        for (index, game) in items.enumerated() {
            let pos = positions[index]
            newLayout[game] = CGPoint(x: pos.x - centerX, y: pos.y - centerY)
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
            layout = newLayout
        }
    }
    
    @ViewBuilder
    private func bubbleView(index: Int, game: GameId, size: CGSize) -> some View {
        let base = layout[game] ?? .zero
        let centerX = size.width / 2
        let centerY = size.height / 2

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
        // ✅ ここがポイント：画面中央 + base で“本当の座標”に置く
        .position(x: centerX + base.x, y: centerY + base.y)
        .opacity(focused == nil || focused == game ? 1.0 : 0.35)
        .allowsHitTesting(focused == nil || focused == game)
        .zIndex(focused == game ? 999 : Double(100 - index))
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

