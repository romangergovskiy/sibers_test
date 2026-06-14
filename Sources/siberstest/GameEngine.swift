import Foundation

final class GameEngine {
    private var world: World
    private let io: ConsoleIO

    private var currentPosition: Position
    private var previousPosition: Position
    private var inventory: [InventoryItem] = []
    private var remainingSteps: Int
    private var coins: Int = 0
    private var isGameOver = false

    init(world: World, io: ConsoleIO) {
        self.world = world
        self.io = io
        self.currentPosition = world.startPosition
        self.previousPosition = world.startPosition
        self.remainingSteps = world.baseStepLimit
    }

    func run() {
        io.write("Step limit: \(remainingSteps)", color: .yellow)

        while !isGameOver {
            guard remainingSteps > 0 else {
                io.write("You died of hunger in the dragon dungeon. Game over.", color: .red)
                return
            }

            describeCurrentRoom()

            if handleMonsterEncounterIfNeeded() {
                continue
            }

            guard let raw = io.prompt(">") else {
                io.write("Input stream closed. Exiting.", color: .red)
                return
            }

            let command = CommandParser.parse(raw)
            execute(command, asMonsterReaction: false)
        }
    }

    private func describeCurrentRoom() {
        guard let room = world.rooms[currentPosition] else { return }
        let isDarkNow = room.isDark && !(room.isPermanentlyLit || hasItem(.torchlight))

        if isDarkNow {
            io.write("Can’t see anything in this dark place!", color: .blue)
            io.write("Steps left: \(remainingSteps)", color: .yellow)
            return
        }

        let doors = room.doors.sorted().map(\.name).joined(separator: ", ")
        let itemList = room.items.isEmpty ? "none" : room.items.map(\.description).joined(separator: ", ")
        io.write("You are in the room \(currentPosition). There are \(room.doors.count) doors: \(doors). Items in the room: \(itemList).", color: .white)
        io.write("Steps left: \(remainingSteps) | Coins: \(coins)", color: .yellow)

        if let monster = room.monster, monster.isAlive {
            io.write("There is an evil \(monster.name) in the room!", color: .red)
        }
    }

    private func handleMonsterEncounterIfNeeded() -> Bool {
        guard let room = world.rooms[currentPosition], let monster = room.monster, monster.isAlive else {
            return false
        }

        let raw = io.promptWithTimeout("Monster is closing in! Enter command within 5 seconds:", timeoutSeconds: 5)
        guard let rawCommand = raw else {
            applyDamage(percent: 10, reason: "You were too slow.")
            knockBack()
            return true
        }

        let roll = Int.random(in: 0..<3)
        switch roll {
        case 0:
            applyDamage(percent: 10, reason: "Monster hits you.")
            knockBack()
            return true
        case 1:
            applyDamage(percent: 10, reason: "You execute command but get wounded.")
            execute(CommandParser.parse(rawCommand), asMonsterReaction: true)
            return true
        default:
            execute(CommandParser.parse(rawCommand), asMonsterReaction: true)
            return true
        }
    }

    private func execute(_ command: Command, asMonsterReaction _: Bool) {
        if isCurrentRoomDarkForPlayer() {
            if case .move = command {
            } else {
                io.write("It is too dark. You can only move.", color: .yellow)
                if remainingSteps <= 0 && !isGameOver {
                    isGameOver = true
                }
                return
            }
        }

        var consumedStep = false
        switch command {
        case .move(let direction):
            consumedStep = move(direction)
        case .get(let itemName):
            getItem(named: itemName)
        case .drop(let itemName):
            dropItem(named: itemName)
        case .eat(let itemName):
            eatItem(named: itemName)
        case .open(let itemName):
            open(itemName: itemName)
        case .fight:
            fight()
        case .inventory:
            printInventory()
        case .status:
            printStatus()
        case .help:
            io.write("Commands: N/S/E/W, get [item], drop [item], eat [item], open chest, fight, inventory, status, help, quit", color: .cyan)
        case .quit:
            io.write("Goodbye.", color: .yellow)
            isGameOver = true
        case .invalid(let message):
            io.write(message, color: .yellow)
        }

        if consumedStep && !isGameOver {
            remainingSteps -= 1
        }

        if remainingSteps <= 0 && !isGameOver {
            io.write("Your strength is gone. Game over.", color: .red)
            isGameOver = true
        }
    }

    // MARK: Command handlers

    private func move(_ direction: Direction) -> Bool {
        guard let room = world.rooms[currentPosition] else { return false }
        guard room.doors.contains(direction) else {
            io.write("You hit a wall. No door there.", color: .yellow)
            return false
        }

        let next = currentPosition.moved(direction)
        guard world.contains(next) else {
            io.write("You can't move outside the labyrinth.", color: .yellow)
            return false
        }

        previousPosition = currentPosition
        currentPosition = next
        return true
    }

    private func getItem(named name: String) {
        guard var room = world.rooms[currentPosition] else { return }
        let isDarkNow = room.isDark && !(room.isPermanentlyLit || hasItem(.torchlight))
        if isDarkNow {
            io.write("It is too dark. You can only move.", color: .yellow)
            return
        }

        guard let index = room.items.firstIndex(where: { $0.commandName == name }) else {
            io.write("No \(name) in this room.", color: .yellow)
            return
        }

        let item = room.items[index]
        switch item {
        case .chest:
            io.write("Chest is too heavy to carry.", color: .yellow)
            return
        case .gold(let amount):
            coins += amount
            room.items.remove(at: index)
            world.rooms[currentPosition] = room
            io.write("You collect \(amount) coins.", color: .green)
        default:
            room.items.remove(at: index)
            world.rooms[currentPosition] = room
            if let inv = item.toInventoryItem {
                inventory.append(inv)
                io.write("Picked up \(item.commandName).", color: .green)
            }
        }
    }

    private func dropItem(named name: String) {
        guard var room = world.rooms[currentPosition] else { return }
        let isDarkNow = room.isDark && !(room.isPermanentlyLit || hasItem(.torchlight))
        if isDarkNow {
            io.write("It is too dark. You can only move.", color: .yellow)
            return
        }

        guard let index = inventory.firstIndex(where: { $0.commandName == name }) else {
            io.write("You do not have \(name).", color: .yellow)
            return
        }

        let item = inventory.remove(at: index)
        let roomItem: RoomItem
        switch item {
        case .key: roomItem = .key
        case .torchlight:
            roomItem = .torchlight
            if room.isDark {
                room.isPermanentlyLit = true
            }
        case .sword: roomItem = .sword
        case .food(let energy): roomItem = .food(energy: energy)
        }
        room.items.append(roomItem)
        world.rooms[currentPosition] = room
        io.write("Dropped \(name).", color: .green)
    }

    private func eatItem(named name: String) {
        guard name == "food" else {
            io.write("You can only eat food.", color: .yellow)
            return
        }

        guard let index = inventory.firstIndex(where: {
            if case .food = $0 { return true }
            return false
        }) else {
            io.write("You have no food in inventory.", color: .yellow)
            return
        }

        guard case .food(let energy) = inventory.remove(at: index) else { return }
        remainingSteps += energy
        io.write("You eat food and gain +\(energy) steps.", color: .green)
    }

    private func open(itemName: String) {
        guard itemName == "chest" else {
            io.write("You can only open chest.", color: .yellow)
            return
        }

        guard let room = world.rooms[currentPosition], room.items.contains(where: {
            if case .chest = $0 { return true }
            return false
        }) else {
            io.write("No chest in this room.", color: .yellow)
            return
        }

        guard hasItem(.key) else {
            io.write("You need a key to open the chest.", color: .yellow)
            return
        }

        io.write("You open the chest with the key and find the Holy Grail.", color: .green)
        io.write("Victory!", color: .green)
        isGameOver = true
    }

    private func fight() {
        guard hasItem(.sword) else {
            io.write("You need a sword to fight.", color: .yellow)
            return
        }

        guard var room = world.rooms[currentPosition], let monster = room.monster, monster.isAlive else {
            io.write("No monster to fight here.", color: .yellow)
            return
        }

        room.monster?.isAlive = false
        world.rooms[currentPosition] = room
        io.write("You slay the \(monster.name).", color: .green)
    }

    private func printInventory() {
        if inventory.isEmpty {
            io.write("Inventory is empty.", color: .yellow)
            return
        }
        io.write("Inventory: \(inventory.map(\.description).joined(separator: ", "))", color: .cyan)
    }

    private func printStatus() {
        io.write("Position: \(currentPosition), steps left: \(remainingSteps), coins: \(coins)", color: .cyan)
    }

    // MARK: Utility

    private func hasItem(_ item: InventoryItem) -> Bool {
        inventory.contains(item)
    }

    private func isCurrentRoomDarkForPlayer() -> Bool {
        guard let room = world.rooms[currentPosition] else { return false }
        return room.isDark && !(room.isPermanentlyLit || hasItem(.torchlight))
    }

    private func knockBack() {
        currentPosition = previousPosition
        io.write("Monster throws you back to \(currentPosition).", color: .red)
    }

    private func applyDamage(percent: Int, reason: String) {
        let loss = max(1, Int(Double(world.baseStepLimit) * (Double(percent) / 100.0)))
        remainingSteps -= loss
        io.write("\(reason) -\(loss) steps.", color: .red)
    }
}
