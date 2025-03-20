import UIKit

class IngredientTableViewCell: UITableViewCell {

    @IBOutlet weak var ingredientLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!

    func configure(with ingredient: Ingredient) {
        ingredientLabel.text = ingredient.name
        quantityLabel.text = ingredient.quantity
    }
}
