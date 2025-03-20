import Foundation

struct RecipeAPIResponse: Codable {
    let hits: [Hit]
}

struct Hit: Codable {
    let recipe: RecipeData
}

struct RecipeData: Codable {
    let label: String                  // Recipe name
    let image: String                  // Recipe image URL
    let calories: Double               // Calories per serving
    let totalTime: Int?                // Total cooking time
    let dietLabels: [String]?          // Diet labels (e.g., "Low-Carb")
    let healthLabels: [String]?        // Health labels (e.g., "Gluten-Free")
    let cautions: [String]?            // Cautions (e.g., "Peanuts")
    let ingredientLines: [String]?     // List of ingredients
    let totalNutrients: [String: Nutrient]? // Nutritional info
    let source: String?                // Recipe source
    let url: String? 
}

struct Nutrient: Codable {
    let label: String                  // Nutrient name
    let quantity: Double               // Quantity of the nutrient
    let unit: String                   // Unit of the nutrient (e.g., "g", "mg")
}
