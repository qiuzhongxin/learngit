import Foundation
import CoreData

public extension LearnedWord {
    @nonobjc class func fetchRequest() -> NSFetchRequest<LearnedWord> {
        return NSFetchRequest<LearnedWord>(entityName: "LearnedWord")
    }

    @NSManaged var id: UUID
    @NSManaged var english: String
    @NSManaged var chinese: String
    @NSManaged var learningDate: Date
    @NSManaged var reviewCount: Int16
    @NSManaged var userId: String?
    @NSManaged var phonetic: String?
}
