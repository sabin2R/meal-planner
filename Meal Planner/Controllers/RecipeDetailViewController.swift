import UIKit

protocol RecipeDetailDelegate: AnyObject {
    func updateNutritionalInfo(calories: Int, protein: Double, carbs: Double, fat: Double)
}
class RecipeDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var recipeImageView: UIImageView!
    @IBOutlet weak var recipeTitleLabel: UILabel!
    @IBOutlet weak var cookingTimeLabel: UILabel!
    @IBOutlet weak var energyLabel: UILabel!
    @IBOutlet weak var proteinLabel: UILabel!
    @IBOutlet weak var carbsLabel: UILabel!
    @IBOutlet weak var fatLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startCookingButton: UIButton!
    @IBOutlet weak var createShoppingListButton: UIButton!
    // Back button outlet
    @IBOutlet weak var backButton: UIButton!

    // MARK: - Properties
    var recipe: Recipe?
    weak var delegate: RecipeDetailDelegate?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        print("RecipeDetailViewController loaded")
        if let recipe = recipe {
            print("Received Recipe: \(recipe)")
            populateRecipeDetails()
        } else {
            print("Recipe is nil in RecipeDetailViewController.")
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        startCookingButton.layer.cornerRadius = 8
        createShoppingListButton.layer.cornerRadius = 8
        recipeImageView.contentMode = .scaleAspectFill
        recipeImageView.clipsToBounds = true
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
    }

    // MARK: - Populate Recipe Details
    private func populateRecipeDetails() {
        guard let recipe = recipe else {
            print("Recipe is nil")
            return
        }
        print("Populating Recipe Details: \(recipe)")
        recipeTitleLabel.text = recipe.name
        cookingTimeLabel.text = recipe.totalTime > 0 ? "\(recipe.totalTime) mins" : "N/A"
        energyLabel.text = "\(Int(recipe.calories)) kcal"
        proteinLabel.text = "\(recipe.protein) g Protein"
        carbsLabel.text = "\(recipe.carbs) g Carbs"
        fatLabel.text = "\(recipe.fat) g Fat"

        if let imageUrl = URL(string: recipe.imageUrl) {
            URLSession.shared.dataTask(with: imageUrl) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.recipeImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        }
    }
    
    
    // MARK: - Button Actions
       @IBAction func backButtonTapped(_ sender: UIButton) {
           if let navigationController = self.navigationController {
               // If this view controller is pushed on a navigation stack
               navigationController.popViewController(animated: true)
           } else {
               // If this view controller is presented modally
               self.dismiss(animated: true, completion: nil)
           }
       }

    // MARK: - TableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Ingredients and Tags
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return recipe?.ingredients.count ?? 0
        } else {
            return 1 // Single row for tags
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // Ingredient Cell
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath) as? IngredientTableViewCell,
                  let ingredient = recipe?.ingredients[indexPath.row] else {
                return UITableViewCell()
            }
            cell.configure(with: ingredient)
            return cell
        } else {
            // Tag Cell
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell", for: indexPath) as? TagTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(
                        with: recipe?.tags ?? [],
                        source: recipe?.source,
                        sourceURL: recipe?.url
                    )
                    return cell
        }
    }

    // MARK: - Button Actions
    @IBAction func startCookingTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Cooking Started", message: "Do you want to finish cooking?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Finish", style: .default, handler: { [weak self] _ in
            guard let self = self, let recipe = self.recipe else { return }
            print("Cooking finished! Updating intake...")
            
            self.delegate?.updateNutritionalInfo(
                calories: Int(recipe.calories),
                protein: recipe.protein,
                carbs: recipe.carbs,
                fat: recipe.fat
            )
            
            // Notify the delegate to upload the values to the database
            if let homeVC = self.delegate as? HomeViewController {
                homeVC.updateUserIntakeInDatabase(
                    calories: Int(recipe.calories),
                    protein: recipe.protein,
                    carbs: recipe.carbs,
                    fat: recipe.fat
                )
            }
        }))
        present(alert, animated: true)
    }

   

    @IBAction func createShoppingListTapped(_ sender: UIButton) {
        // Perform the segue to navigate to the ShoppingListViewController
            performSegue(withIdentifier: "toShoppingListScreen", sender: self)
        }

        // Prepare for segue
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "toShoppingListScreen",
               let destinationVC = segue.destination as? ShoppingListViewController {
                destinationVC.selectedRecipe = recipe // Pass the selected recipe
                destinationVC.previousScreen = self // Reference to the current screen
            }
        }
}
