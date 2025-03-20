import UIKit

class RecipeTableViewCell: UITableViewCell {
    @IBOutlet weak var recipeImageView: UIImageView!
    

    private var imageDownloadTask: URLSessionDataTask?

    func configure(with recipe: Recipe) {
        recipeImageView.image = UIImage(named: "placeholder") // Set a placeholder image

        // Cancel previous download task if the cell is reused
        imageDownloadTask?.cancel()

        if let imageUrl = URL(string: recipe.imageUrl) {
            imageDownloadTask = URLSession.shared.dataTask(with: imageUrl) { data, _, error in
                if let data = data, error == nil {
                    DispatchQueue.main.async {
                        self.recipeImageView.image = UIImage(data: data)
                    }
                }
            }
            imageDownloadTask?.resume()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        recipeImageView.image = UIImage(named: "placeholder") // Reset to placeholder
        imageDownloadTask?.cancel() // Cancel ongoing image download
        imageDownloadTask = nil
    }
}
