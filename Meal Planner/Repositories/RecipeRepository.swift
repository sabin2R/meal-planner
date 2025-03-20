import Foundation
import FirebaseFirestore

/// Repository for managing recipe data
class RecipeRepository {
    private let db = Firestore.firestore()
    private let baseURL = "https://api.edamam.com/api/recipes/v2"
    private let appID = "99a707fa"
    private let appKey = "fc6a3d3ac3e7e9f5bad3a108b2282742"

    // MARK: - Fetch Recipes
    /// Fetches recipes from cache or API and returns the result.
    /// - Parameters:
    ///   - limit: Number of recipes to fetch.
    ///   - completion: Closure returning an array of `Recipe`.
    func fetchRecipes(for limit: Int, completion: @escaping ([Recipe]) -> Void) {
        // Step 1: Try fetching cached recipes
        fetchCachedRecipes(limit: limit) { [weak self] cachedRecipes in
            guard let self = self else { return }
            if !cachedRecipes.isEmpty {
                print("Returning cached recipes.")
                completion(cachedRecipes)
                return
            }

            // Step 2: If no cache, fetch from API
            self.fetchRecipesFromAPI(limit: limit) { apiRecipes in
                print("Fetched \(apiRecipes.count) recipes from API.")
                self.cacheRecipesInFirebase(apiRecipes)
                completion(apiRecipes)
            }
        }
    }

    // MARK: - Fetch Recipes from API
    private func fetchRecipesFromAPI(limit: Int, completion: @escaping ([Recipe]) -> Void) {
        guard var urlComponents = URLComponents(string: baseURL) else {
            print("Invalid base URL.")
            completion([])
            return
        }

        // API Query Parameters
        urlComponents.queryItems = [
            URLQueryItem(name: "type", value: "public"),
            URLQueryItem(name: "app_id", value: appID),
            URLQueryItem(name: "app_key", value: appKey),
            URLQueryItem(name: "q", value: "healthy"),
            URLQueryItem(name: "field", value: "label"),
            URLQueryItem(name: "field", value: "image"),
            URLQueryItem(name: "field", value: "calories"),
            URLQueryItem(name: "field", value: "totalTime"),
            URLQueryItem(name: "field", value: "ingredientLines"),
            URLQueryItem(name: "field", value: "dietLabels"),
            URLQueryItem(name: "field", value: "healthLabels"),
            URLQueryItem(name: "field", value: "totalNutrients"),
            URLQueryItem(name: "field", value: "source"),
            URLQueryItem(name: "field", value: "url")
        ]

        guard let url = urlComponents.url else {
            print("Failed to construct URL.")
            completion([])
            return
        }

        // Fetching data from API
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Error fetching recipes from API: \(String(describing: error))")
                completion([])
                return
            }

            do {
                // Decoding API Response
                let response = try JSONDecoder().decode(RecipeAPIResponse.self, from: data)
                let recipes = response.hits.prefix(limit).compactMap { hit -> Recipe? in
                    let recipeData = hit.recipe
                    let ingredients = recipeData.ingredientLines?.map { Ingredient(name: $0, quantity: "N/A") } ?? []
                    let tags = (recipeData.dietLabels ?? []) + (recipeData.healthLabels ?? [])

                    return Recipe(
                        id: UUID().uuidString,
                        name: recipeData.label,
                        imageUrl: recipeData.image,
                        calories: recipeData.calories,
                        protein: recipeData.totalNutrients?["PROCNT"]?.quantity ?? 0,
                        carbs: recipeData.totalNutrients?["CHOCDF"]?.quantity ?? 0,
                        fat: recipeData.totalNutrients?["FAT"]?.quantity ?? 0,
                        totalTime: recipeData.totalTime ?? 0,
                        ingredients: ingredients,
                        tags: tags,
                        source: recipeData.source,
                        url: recipeData.url
                    )
                }
                completion(recipes)
            } catch {
                print("Error decoding recipes: \(error)")
                completion([])
            }
        }.resume()
    }

    // MARK: - Cache Recipes in Firebase
    private func cacheRecipesInFirebase(_ recipes: [Recipe]) {
        let recipesCollection = db.collection("recipes")

        recipes.forEach { recipe in
            recipesCollection.document(recipe.id).setData(recipe.toDictionary()) { error in
                if let error = error {
                    print("Error caching recipe \(recipe.name): \(error)")
                } else {
                    print("Successfully cached recipe: \(recipe.name)")
                }
            }
        }
    }

    // MARK: - Fetch Cached Recipes
    func fetchCachedRecipes(limit: Int, completion: @escaping ([Recipe]) -> Void) {
        db.collection("recipes")
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching cached recipes: \(error)")
                    completion([])
                    return
                }

                // Decoding cached recipes
                let recipes = snapshot?.documents.compactMap { document in
                    Recipe(from: document.data())
                } ?? []
                completion(recipes)
            }
    }
}
