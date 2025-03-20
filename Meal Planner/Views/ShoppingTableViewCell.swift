import UIKit

class ShoppingTableViewCell: UITableViewCell {

    @IBOutlet weak var ingredientLabel: UILabel!
    @IBOutlet weak var recipeLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!

    var onDelete: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }

    func configure(with item: ShoppingItem) {
        ingredientLabel.text = item.ingredientName
        recipeLabel.text = "Recipe: \(item.recipeName)"
        deleteButton.setImage(UIImage(systemName: "trash.circle"), for: .normal)
    }

    @objc private func deleteButtonTapped() {
        onDelete?()
    }
}
