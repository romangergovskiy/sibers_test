import Foundation

@main
struct SiberstestApp {
    static func main() {
        let io = ConsoleIO()
        io.printBanner()

        guard let roomCount = io.readPositiveInteger(prompt: "Enter number of rooms:") else {
            io.write("Failed to read room count. Exiting.", color: .red)
            return
        }

        var generator = LabyrinthGenerator(randomSource: SystemRandomNumberGenerator())
        let world = generator.makeWorld(roomCount: roomCount)

        let engine = GameEngine(world: world, io: io)
        engine.run()
    }
}
