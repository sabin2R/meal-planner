import UIKit

class RecipeListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    private let recipeRepository = RecipeRepository()
    private var recipes: [Recipe] = []
    private var filteredRecipes: [Recipe] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
        loadRecipes()
    }

    // MARK: - Setup Methods
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
    }

    private func setupSearchBar() {
        searchBar.delegate = self
    }

    // MARK: - Load Recipes
    private func loadRecipes() {
        recipeRepository.fetchRecipes(for: 10) { [weak self] recipes in
            guard let self = self else { return }
            self.recipes = recipes
            self.filteredRecipes = recipes
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredRecipes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeListCell", for: indexPath) as? RecipeListTableViewCell else {
            return UITableViewCell()
        }
        let recipe = filteredRecipes[indexPath.row]
        cell.configure(with: recipe)
        return cell
    }

    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Deselect the row
        
    }

    // Prepare for Segue to RecipeDetailViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromRecipeList",
           let destinationVC = segue.destination as? RecipeDetailViewController,
           let indexPath = tableView.indexPathForSelectedRow { // Get the selected row index
            let selectedRecipe = recipes[indexPath.row]
            destinationVC.recipe = selectedRecipe
            print("Passing recipe: \(selectedRecipe) to RecipeDetailViewController.")
        }
    }




    // MARK: - SearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredRecipes = recipes
        } else {
            filteredRecipes = recipes.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
    }
}
