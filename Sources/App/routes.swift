import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: EpisodesController())
    try app.register(collection: DevicesController())
    try app.register(collection: SocketHandler.shared)
    try app.register(collection: EpisodesMetaController())
}
