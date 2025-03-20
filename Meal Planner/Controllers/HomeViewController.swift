import UIKit
import FirebaseAuth
import FirebaseFirestore

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, RecipeDetailDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var calorieLabel: UILabel!
    @IBOutlet weak var proteinLabel: UILabel!
    @IBOutlet weak var fatLabel: UILabel!
    @IBOutlet weak var carbLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!

    let userRepository = UserRepository()
    let recipeRepository = RecipeRepository()

    var user: User?
    var recipes: [Recipe] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        loadUserData()
        loadRecipes()
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
    }

    private func loadUserData() {
        userRepository.fetchUserData { [weak self] user in
            guard let self = self else { return }
            self.user = user
            DispatchQueue.main.async {
                self.updateHeaderView(with: user)
            }
        }
    }

    private func updateHeaderView(with user: User?) {
        guard let user = user else { return }
        print("Updating header view with user data: \(user)")
        DispatchQueue.main.async {
            self.calorieLabel.text = "\(user.calorieIntake ?? 0) kcal"
                    self.proteinLabel.text = "\(user.proteinIntake ?? 0) g "
                    self.carbLabel.text = "\(user.carbIntake ?? 0) g "
                    self.fatLabel.text = "\(user.fatIntake ?? 0) g"
        }

        if let profileUrl = user.profileImageUrl, let url = URL(string: profileUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.profileImageView.image = UIImage(data: data)
                        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.width / 2
                        self.profileImageView.clipsToBounds = true
                    }
                }
            }.resume()
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
            profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
            profileImageView.clipsToBounds = true
        }
    }
    
    // Update header view dynamically
        private func updateHeaderViewWithRecipeDetails(calories: Int, protein: Double, carbs: Double, fat: Double) {
            DispatchQueue.main.async {
                self.calorieLabel.text = "\(calories) kcal"
                self.proteinLabel.text = "\(protein) g "
                self.fatLabel.text = "\(fat) g "
                self.carbLabel.text = "\(carbs) g "
            }
            print("Updated header with nutritional details: \(calories) kcal, \(protein) g protein, \(carbs) g carbs, \(fat) g fat")
        }

    private func loadRecipes() {
        recipeRepository.fetchRecipes(for: 5) { [weak self] recipes in
            guard let self = self else { return }
            self.recipes = recipes
            for recipe in recipes {
                print("Recipe Name: \(recipe.name), Image URL: \(recipe.imageUrl)")
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath) as? RecipeTableViewCell else {
            fatalError("Unable to dequeue RecipeTableViewCell")
        }
        let recipe = recipes[indexPath.row]
        cell.configure(with: recipe)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Deselect the row
        
    }
    
    // MARK: - Delegate Method
        func updateNutritionalInfo(calories: Int, protein: Double, carbs: Double, fat: Double) {
            print("Received nutritional info from RecipeDetailViewController")
            updateHeaderViewWithRecipeDetails(calories: calories, protein: protein, carbs: carbs, fat: fat)
        }
    
    // Prepare for Segue to RecipeDetailViewController
       override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "ShowRecipeDetailSegue",
              let destinationVC = segue.destination as? RecipeDetailViewController,
              let indexPath = tableView.indexPathForSelectedRow { // Get the selected row index
               let selectedRecipe = recipes[indexPath.row]
               destinationVC.recipe = selectedRecipe
               destinationVC.delegate = self // Set the delegate to HomeViewController
               print("Passing recipe: \(selectedRecipe) to RecipeDetailViewController.")
           }
       }
    
     func updateUserIntakeInDatabase(calories: Int, protein: Double, carbs: Double, fat: Double) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            
            var existingCalories = 0
            var existingProtein = 0.0
            var existingCarbs = 0.0
            var existingFat = 0.0
            
            if let data = snapshot?.data() {
                existingCalories = data["calorieIntake"] as? Int ?? 0
                existingProtein = data["proteinIntake"] as? Double ?? 0
                existingCarbs = data["carbIntake"] as? Double ?? 0
                existingFat = data["fatIntake"] as? Double ?? 0
            }
            
            // Update the intake values
            let updatedData: [String: Any] = [
                "calorieIntake": existingCalories + calories,
                "proteinIntake": existingProtein + protein,
                "carbIntake": existingCarbs + carbs,
                "fatIntake": existingFat + fat
            ]
            
            userRef.updateData(updatedData) { error in
                if let error = error {
                    print("Error updating user intake: \(error)")
                } else {
                    print("User intake updated successfully in the database.")
                    self.loadUserData() // Reload the updated data
                }
            }
        }
    }




    @IBAction func menuButtonTapped(_ sender: UIButton) {
        print("Menu button tapped")
    }
}
