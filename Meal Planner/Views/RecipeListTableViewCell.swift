import UIKit

class RecipeListTableViewCell: UITableViewCell {

    @IBOutlet weak var recipeImageView: UIImageView!
    @IBOutlet weak var recipeNameLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var cookingTimeLabel: UILabel!

    func configure(with recipe: Recipe) {
        recipeNameLabel.text = recipe.name
        caloriesLabel.text = "\(Int(recipe.calories)) kcal"
        cookingTimeLabel.text = recipe.totalTime > 0 ? "\(recipe.totalTime) mins" : "N/A"
        
        if let url = URL(string: recipe.imageUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.recipeImageView.image = UIImage(data: data)
                        self.recipeImageView.contentMode = .scaleAspectFill
                        self.recipeImageView.clipsToBounds = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.recipeImageView.image = UIImage(named: "placeholder")
                    }
                }
            }.resume()
        } else {
            recipeImageView.image = UIImage(named: "placeholder")
        }
    }
}
