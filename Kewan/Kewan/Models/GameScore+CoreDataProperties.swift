import Foundation
import CoreData

public extension GameScore {
    @nonobjc class func fetchRequest() -> NSFetchRequest<GameScore> {
        return NSFetchRequest<GameScore>(entityName: "GameScore")
    }

    @NSManaged var id: UUID
    @NSManaged var date: Date
    @NSManaged var level: Int16
    @NSManaged var score: Int16
    @NSManaged var totalTime: Double
    @NSManaged var userId: String?
}
