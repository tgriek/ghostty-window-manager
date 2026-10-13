/// A grid of `rows` × `cols` cells, filled row-major.
public struct GridSpec: Equatable, Sendable, CustomStringConvertible {
    public static let maxDimension = 99

    public let rows: Int
    public let cols: Int

    public init?(rows: Int, cols: Int) {
        guard (1...Self.maxDimension).contains(rows), (1...Self.maxDimension).contains(cols) else { return nil }
        self.rows = rows
        self.cols = cols
    }

    private init(uncheckedRows rows: Int, cols: Int) {
        self.rows = rows
        self.cols = cols
    }

    public var cellCount: Int { rows * cols }
    public var description: String { "\(rows)x\(cols)" }

    /// Parses `RxC` (e.g. `2x3`, `2X3`). Rejects zero, signs, whitespace and anything else.
    public static func parse(_ text: String) -> GridSpec? {
        let parts = text.lowercased().split(separator: "x", omittingEmptySubsequences: false)
        guard parts.count == 2, let rows = dimension(parts[0]), let cols = dimension(parts[1]) else { return nil }
        return GridSpec(rows: rows, cols: cols)
    }

    private static func dimension(_ text: Substring) -> Int? {
        guard !text.isEmpty, text.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return Int(text)
    }

    /// 1–3 windows → 1 row, 4–8 → 2 rows, 9+ → 3 rows; columns = ceil(count / rows).
    public static func auto(count: Int) -> GridSpec {
        precondition(count > 0, "auto grid needs at least one window")
        let rows = count <= 3 ? 1 : (count <= 8 ? 2 : 3)
        return GridSpec(uncheckedRows: rows, cols: (count + rows - 1) / rows)
    }
}
