import Foundation
import CoreData

@objc(WordFavorite)
public class WordFavorite: NSManagedObject {
}

extension WordFavorite {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WordFavorite> {
        return NSFetchRequest<WordFavorite>(entityName: "WordFavorite")
    }
    
    @NSManaged public var favoritesData: Data?
} 