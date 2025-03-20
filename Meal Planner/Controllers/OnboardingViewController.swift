import UIKit

class OnboardingViewController: UIViewController {

    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Customize button UI (optional)
        nextButton.layer.cornerRadius = 8
    }

    @IBAction func nextButtonTapped(_ sender: UIButton) {
        // Navigate to AllergyViewController
        if let allergyVC = storyboard?.instantiateViewController(withIdentifier: "AllergyViewController") as? AllergyViewController {
            navigationController?.pushViewController(allergyVC, animated: true)
        }
    }
}
