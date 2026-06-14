import Foundation

enum Command {
    case move(Direction)
    case get(String)
    case drop(String)
    case eat(String)
    case open(String)
    case fight
    case inventory
    case help
    case status
    case quit
    case invalid(String)
}

enum CommandParser {
    static func parse(_ raw: String) -> Command {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid("Empty command.") }

        let components = trimmed.split(separator: " ").map { String($0).lowercased() }
        guard let keyword = components.first else {
            return .invalid("Empty command.")
        }

        switch keyword {
        case "n": return .move(.north)
        case "s": return .move(.south)
        case "w": return .move(.west)
        case "e": return .move(.east)
        case "get":
            return components.count >= 2 ? .get(components[1]) : .invalid("Usage: get [item].")
        case "drop":
            return components.count >= 2 ? .drop(components[1]) : .invalid("Usage: drop [item].")
        case "eat":
            return components.count >= 2 ? .eat(components[1]) : .invalid("Usage: eat [item].")
        case "open":
            return components.count >= 2 ? .open(components[1]) : .invalid("Usage: open [item].")
        case "fight": return .fight
        case "inventory", "inv": return .inventory
        case "status": return .status
        case "help": return .help
        case "quit", "exit": return .quit
        default:
            return .invalid("Unknown command: \(keyword).")
        }
    }
}
