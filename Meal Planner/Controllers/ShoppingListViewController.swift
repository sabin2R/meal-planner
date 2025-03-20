import UIKit
import FirebaseFirestore
import FirebaseAuth

class ShoppingListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backButton: UIButton! // Back button outlet

    // MARK: - Properties
    private let db = Firestore.firestore()
    var shoppingItems: [ShoppingItem] = [] // All shopping list items
    var selectedRecipe: Recipe? // Recipe passed from the previous screen
    var previousScreen: UIViewController? // Reference to the previous screen

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        print("ShoppingListViewController loaded.")

        if let recipe = selectedRecipe {
            print("Selected recipe: \(recipe.name)")
            saveIngredientsToDatabase(for: recipe)
        } else {
            print("No selected recipe. Fetching all shopping lists.")
            fetchAllShoppingLists()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ShoppingListViewController: viewWillAppear called")
        fetchAllShoppingLists()
    }

    // MARK: - Setup TableView
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        print("TableView setup completed.")
    }

    // MARK: - Save Ingredients to Database
    private func saveIngredientsToDatabase(for recipe: Recipe) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }

        print("Saving ingredients for recipe: \(recipe.name)")
        let dispatchGroup = DispatchGroup()

        for ingredient in recipe.ingredients {
            let newItem = [
                "id": UUID().uuidString,
                "ingredientName": ingredient.name,
                "recipeName": recipe.name,
                "userId": userId
            ]

            print("Checking if ingredient exists: \(ingredient.name)")
            dispatchGroup.enter()
            db.collection("shoppingList")
                .whereField("ingredientName", isEqualTo: ingredient.name)
                .whereField("recipeName", isEqualTo: recipe.name)
                .whereField("userId", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error checking ingredient existence: \(error)")
                        dispatchGroup.leave()
                        return
                    }

                    if snapshot?.documents.isEmpty ?? true {
                        print("Ingredient does not exist. Adding: \(ingredient.name)")
                        self.db.collection("shoppingList").document(newItem["id"]!).setData(newItem) { error in
                            if let error = error {
                                print("Error adding ingredient: \(error)")
                            } else {
                                print("Ingredient added successfully: \(ingredient.name)")
                            }
                            dispatchGroup.leave()
                        }
                    } else {
                        print("Ingredient already exists: \(ingredient.name)")
                        dispatchGroup.leave()
                    }
                }
        }

        dispatchGroup.notify(queue: .main) {
            print("Finished saving ingredients. Fetching updated shopping list.")
            self.fetchAllShoppingLists()
        }
    }

    // MARK: - Fetch All Shopping Lists
    private func fetchAllShoppingLists() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }

        print("Fetching all shopping lists for userId: \(userId)")
        db.collection("shoppingList")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching shopping lists: \(error)")
                    return
                }

                self.shoppingItems = snapshot?.documents.compactMap {
                    ShoppingItem(from: $0.data())
                } ?? []

                print("Fetched shopping lists. Number of items: \(self.shoppingItems.count)")
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = shoppingItems.count
        print("Number of rows in table: \(count)")
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShoppingCell", for: indexPath) as? ShoppingTableViewCell else {
            print("Error: Unable to dequeue ShoppingCell")
            return UITableViewCell()
        }
        let item = shoppingItems[indexPath.row]
        cell.configure(with: item)
        print("Configured cell for item: \(item.ingredientName)")
        cell.onDelete = { [weak self] in
            self?.deleteShoppingItem(item, at: indexPath)
        }
        return cell
    }

    // MARK: - Delete Shopping Item
    private func deleteShoppingItem(_ item: ShoppingItem, at indexPath: IndexPath) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }

        print("Deleting item: \(item.ingredientName) for userId: \(userId)")

        db.collection("shoppingList")
            .whereField("id", isEqualTo: item.id)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error finding shopping item to delete: \(error)")
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("Shopping item not found for deletion")
                    return
                }

                self.db.collection("shoppingList").document(document.documentID).delete { error in
                    if let error = error {
                        print("Error deleting shopping item: \(error)")
                    } else {
                        print("Shopping item deleted successfully: \(item.ingredientName)")
                        DispatchQueue.main.async {
                            self.shoppingItems.remove(at: indexPath.row)
                            self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                    }
                }
            }
    }

    // MARK: - Back Button Action
    @IBAction func backButtonTapped(_ sender: UIButton) {
        print("Back button tapped.")
        if let previousVC = previousScreen {
            navigationController?.popToViewController(previousVC, animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}
