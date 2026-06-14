import Darwin
import Foundation

enum ConsoleColor: String {
    case reset = "\u{001B}[0m"
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"
    case blue = "\u{001B}[34m"
    case magenta = "\u{001B}[35m"
    case cyan = "\u{001B}[36m"
    case white = "\u{001B}[37m"
}

final class ConsoleIO {
    private let colorsEnabled: Bool

    init(colorsEnabled: Bool = true) {
        self.colorsEnabled = colorsEnabled
    }

    func printBanner() {
        write("=== Crystals & Dragons ===", color: .magenta)
        write("Commands: N/S/E/W, get, drop, eat, open, fight, inventory, status, help, quit", color: .cyan)
        write("", color: .reset)
    }

    func write(_ message: String, color: ConsoleColor = .white) {
        if colorsEnabled {
            print("\(color.rawValue)\(message)\(ConsoleColor.reset.rawValue)")
        } else {
            print(message)
        }
    }

    func prompt(_ message: String) -> String? {
        Swift.print(message, terminator: " ")
        fflush(stdout)
        return readLine()
    }

    func promptWithTimeout(_ message: String, timeoutSeconds: Int) -> String? {
        Swift.print(message, terminator: " ")
        fflush(stdout)

        var descriptor = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
        let result = poll(&descriptor, 1, Int32(timeoutSeconds * 1000))
        guard result > 0 else { return nil }
        return readLine()
    }

    func readPositiveInteger(prompt: String) -> Int? {
        while let input = self.prompt(prompt) {
            if let value = Int(input), value > 1 {
                return value
            }
            write("Please enter an integer greater than 1.", color: .yellow)
        }
        return nil
    }
}
