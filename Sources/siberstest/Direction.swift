import Foundation

enum Direction: String, CaseIterable, Comparable {
    case north = "N"
    case south = "S"
    case west = "W"
    case east = "E"

    var name: String { rawValue }

    static func < (lhs: Direction, rhs: Direction) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    private var sortOrder: Int {
        switch self {
        case .north: return 0
        case .south: return 1
        case .west: return 2
        case .east: return 3
        }
    }

    var delta: (dx: Int, dy: Int) {
        switch self {
        case .north: return (0, -1)
        case .south: return (0, 1)
        case .west: return (-1, 0)
        case .east: return (1, 0)
        }
    }

    var opposite: Direction {
        switch self {
        case .north: return .south
        case .south: return .north
        case .west: return .east
        case .east: return .west
        }
    }
}
