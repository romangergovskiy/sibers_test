import Foundation

struct LabyrinthGenerator<RandomSource: RandomNumberGenerator> {
    private var randomSource: RandomSource

    init(randomSource: RandomSource) {
        self.randomSource = randomSource
    }

    mutating func makeWorld(roomCount: Int) -> World {
        let dimensions = Self.factorizedDimensions(for: roomCount)
        let width = dimensions.width
        let height = dimensions.height

        var rooms: [Position: Room] = [:]
        for y in 0..<height {
            for x in 0..<width {
                rooms[Position(x: x, y: y)] = Room(
                    doors: [],
                    items: [],
                    isDark: false,
                    isPermanentlyLit: false,
                    monster: nil
                )
            }
        }

        let start = Position(x: Int.random(in: 0..<width, using: &randomSource), y: Int.random(in: 0..<height, using: &randomSource))
        generateConnectedMaze(in: &rooms, width: width, height: height)
        addExtraDoors(in: &rooms, width: width, height: height)

        var allPositions = Array(rooms.keys)
        allPositions.shuffle(using: &randomSource)

        let keyPosition = allPositions.removeFirst()
        let chestPosition = allPositions.removeFirst(whereNotEqualTo: keyPosition) ?? start
        let torchPosition = allPositions.removeFirst(whereNotEqualTo: chestPosition) ?? start
        let swordPosition = allPositions.removeFirst(whereNotEqualTo: torchPosition) ?? start

        rooms[keyPosition]?.items.append(.key)
        rooms[chestPosition]?.items.append(.chest)
        rooms[torchPosition]?.items.append(.torchlight)
        rooms[swordPosition]?.items.append(.sword)

        let darkRoomsCount = max(1, roomCount / 6)
        for position in allPositions.prefix(darkRoomsCount) where position != start {
            rooms[position]?.isDark = true
        }

        for position in allPositions.dropFirst(darkRoomsCount).prefix(max(2, roomCount / 5)) {
            let energy = Int.random(in: 5...15, using: &randomSource)
            rooms[position]?.items.append(.food(energy: energy))
        }

        for position in allPositions.shuffled(using: &randomSource).prefix(max(2, roomCount / 4)) {
            let coins = Int.random(in: 30...600, using: &randomSource)
            rooms[position]?.items.append(.gold(coins: coins))
        }

        let monsterNames = ["dragon", "goblin", "wraith", "manticore", "troll"]
        for position in allPositions.shuffled(using: &randomSource).prefix(max(1, roomCount / 5)) where position != start {
            rooms[position]?.monster = Monster(name: monsterNames.randomElement(using: &randomSource) ?? "beast", isAlive: true)
        }

        let pathToKey = shortestPathLength(in: rooms, from: start, to: keyPosition) ?? roomCount
        let pathToChest = shortestPathLength(in: rooms, from: keyPosition, to: chestPosition) ?? roomCount
        let baseStepLimit = max(20, pathToKey + pathToChest + (roomCount / 2))

        return World(width: width, height: height, startPosition: start, baseStepLimit: baseStepLimit, rooms: rooms)
    }

    // MARK: Private methods

    private static func factorizedDimensions(for roomCount: Int) -> (width: Int, height: Int) {
        var width = Int(Double(roomCount).squareRoot())
        width = max(width, 1)
        while roomCount % width != 0 {
            width -= 1
        }
        return (width, roomCount / width)
    }

    private mutating func generateConnectedMaze(in rooms: inout [Position: Room], width: Int, height: Int) {
        var visited = Set<Position>()
        let root = Position(x: 0, y: 0)
        var stack: [Position] = [root]
        visited.insert(root)

        while let current = stack.last {
            let candidates = Direction.allCases
                .map { ($0, current.moved($0)) }
                .filter { direction, next in
                    (0..<width).contains(next.x) && (0..<height).contains(next.y) && !visited.contains(next)
                }

            if let selected = candidates.randomElement(using: &randomSource) {
                let direction = selected.0
                let next = selected.1
                rooms[current]?.doors.insert(direction)
                rooms[next]?.doors.insert(direction.opposite)
                visited.insert(next)
                stack.append(next)
            } else {
                _ = stack.popLast()
            }
        }
    }

    private mutating func addExtraDoors(in rooms: inout [Position: Room], width: Int, height: Int) {
        for y in 0..<height {
            for x in 0..<width {
                let position = Position(x: x, y: y)
                for direction in Direction.allCases {
                    guard Double.random(in: 0...1, using: &randomSource) < 0.2 else { continue }
                    let next = position.moved(direction)
                    guard (0..<width).contains(next.x), (0..<height).contains(next.y) else { continue }
                    rooms[position]?.doors.insert(direction)
                    rooms[next]?.doors.insert(direction.opposite)
                }
            }
        }
    }

    private func shortestPathLength(in rooms: [Position: Room], from start: Position, to goal: Position) -> Int? {
        if start == goal { return 0 }
        var queue: [Position] = [start]
        var distance: [Position: Int] = [start: 0]

        while !queue.isEmpty {
            let current = queue.removeFirst()
            guard let room = rooms[current], let currentDistance = distance[current] else { continue }
            for direction in room.doors {
                let next = current.moved(direction)
                guard distance[next] == nil, rooms[next] != nil else { continue }
                if next == goal { return currentDistance + 1 }
                distance[next] = currentDistance + 1
                queue.append(next)
            }
        }
        return nil
    }
}

// MARK: Helpers

private extension Array where Element == Position {
    mutating func removeFirst(whereNotEqualTo forbidden: Position) -> Position? {
        guard let index = firstIndex(where: { $0 != forbidden }) else { return nil }
        return remove(at: index)
    }
}
