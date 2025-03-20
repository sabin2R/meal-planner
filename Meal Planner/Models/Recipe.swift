import Foundation

struct Recipe {
    let id: String
    let name: String
    let imageUrl: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let totalTime: Int
    let ingredients: [Ingredient]
    let tags: [String]
    let source: String?
    let url: String?        // Added URL
    
    init(id: String = UUID().uuidString, name: String, imageUrl: String, calories: Double, protein: Double = 0, carbs: Double = 0, fat: Double = 0, totalTime: Int = 0, ingredients: [Ingredient] = [], tags: [String] = [], source: String? = nil, url: String? = nil) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.totalTime = totalTime
        self.ingredients = ingredients
        self.tags = tags
        self.source = source
        self.url = url
    }
    
    init?(from dictionary: [String: Any]) {
        guard
            let id = dictionary["id"] as? String,
            let name = dictionary["name"] as? String,
            let imageUrl = dictionary["imageUrl"] as? String,
            let calories = dictionary["calories"] as? Double
        else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.calories = calories
        self.protein = dictionary["protein"] as? Double ?? 0
        self.carbs = dictionary["carbs"] as? Double ?? 0
        self.fat = dictionary["fat"] as? Double ?? 0
        self.totalTime = dictionary["totalTime"] as? Int ?? 0
        self.ingredients = (dictionary["ingredients"] as? [[String: String]])?.compactMap { Ingredient(from: $0) } ?? []
        self.tags = dictionary["tags"] as? [String] ?? []
        self.source = dictionary["source"] as? String
        self.url = dictionary["url"] as? String
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "imageUrl": imageUrl,
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "totalTime": totalTime,
            "ingredients": ingredients.map { $0.toDictionary() },
            "tags": tags,
            "source": source ?? "",
            "url": url ?? ""
        ]
    }
}

struct Ingredient {
    let name: String
    let quantity: String

    init(name: String, quantity: String) {
        self.name = name
        self.quantity = quantity
    }
    
    init?(from dictionary: [String: String]) {
        guard let name = dictionary["name"], let quantity = dictionary["quantity"] else {
            return nil
        }
        self.name = name
        self.quantity = quantity
    }
    
    func toDictionary() -> [String: String] {
        return [
            "name": name,
            "quantity": quantity
        ]
    }
}
