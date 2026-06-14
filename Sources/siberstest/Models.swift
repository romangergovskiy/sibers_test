import Foundation

struct Position: Hashable, CustomStringConvertible {
    let x: Int
    let y: Int

    func moved(_ direction: Direction) -> Position {
        Position(x: x + direction.delta.dx, y: y + direction.delta.dy)
    }

    var description: String { "[\(x),\(y)]" }
}

enum InventoryItem: Hashable, CustomStringConvertible {
    case key
    case torchlight
    case sword
    case food(energy: Int)

    var commandName: String {
        switch self {
        case .key: return "key"
        case .torchlight: return "torchlight"
        case .sword: return "sword"
        case .food: return "food"
        }
    }

    var description: String {
        switch self {
        case .food(let energy):
            return "food(+\(energy))"
        default:
            return commandName
        }
    }
}

enum RoomItem: Hashable, CustomStringConvertible {
    case key
    case chest
    case torchlight
    case sword
    case food(energy: Int)
    case gold(coins: Int)

    var commandName: String {
        switch self {
        case .key: return "key"
        case .chest: return "chest"
        case .torchlight: return "torchlight"
        case .sword: return "sword"
        case .food: return "food"
        case .gold: return "gold"
        }
    }

    var description: String {
        switch self {
        case .gold(let coins):
            return "gold (\(coins) coins)"
        case .food(let energy):
            return "food(+\(energy))"
        default:
            return commandName
        }
    }

    var isPortable: Bool {
        if case .chest = self { return false }
        return true
    }

    var toInventoryItem: InventoryItem? {
        switch self {
        case .key: return .key
        case .torchlight: return .torchlight
        case .sword: return .sword
        case .food(let energy): return .food(energy: energy)
        case .chest, .gold: return nil
        }
    }
}

struct Monster {
    let name: String
    var isAlive: Bool
}

struct Room {
    var doors: Set<Direction>
    var items: [RoomItem]
    var isDark: Bool
    var isPermanentlyLit: Bool
    var monster: Monster?
}

struct World {
    let width: Int
    let height: Int
    let startPosition: Position
    let baseStepLimit: Int
    var rooms: [Position: Room]

    func contains(_ position: Position) -> Bool {
        (0..<width).contains(position.x) && (0..<height).contains(position.y)
    }
}
