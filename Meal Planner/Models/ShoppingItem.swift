import Foundation

struct ShoppingItem {
    let id: String
    let ingredientName: String
    let recipeName: String

    init(ingredientName: String, recipeName: String, id: String = UUID().uuidString) {
        self.id = id
        self.ingredientName = ingredientName
        self.recipeName = recipeName
    }

    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let ingredientName = dictionary["ingredientName"] as? String,
              let recipeName = dictionary["recipeName"] as? String else {
            return nil
        }
        self.id = id
        self.ingredientName = ingredientName
        self.recipeName = recipeName
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "ingredientName": ingredientName,
            "recipeName": recipeName
        ]
    }
}
