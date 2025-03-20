import UIKit
import FirebaseFirestore
import FirebaseAuth

class AllergyViewController: UIViewController {

    // Outlets for allergy buttons
    @IBOutlet weak var glutenButton: UIButton!
    @IBOutlet weak var fishButton: UIButton!
    @IBOutlet weak var milkButton: UIButton!
    @IBOutlet weak var soyButton: UIButton!
    @IBOutlet weak var dairyButton: UIButton!
    @IBOutlet weak var eggButton: UIButton!
    @IBOutlet weak var peanutButton: UIButton!
    @IBOutlet weak var wheatButton: UIButton!

    // Outlets for navigation buttons
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!

    // Outlets for scrollView
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var selectedAllergies = Set<String>()
    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAllergyButtons()
    }

    private func configureAllergyButtons() {
        let allergyButtons = [glutenButton, fishButton, milkButton, soyButton, dairyButton, eggButton, peanutButton, wheatButton]
        
        for button in allergyButtons {
            button?.layer.cornerRadius = 10
            button?.layer.borderWidth = 1
            button?.layer.borderColor = UIColor.systemGray.cgColor
            button?.setTitleColor(.systemGray, for: .normal)
            button?.setTitleColor(.white, for: .selected)
            button?.backgroundColor = .clear
        }
    }

    @IBAction func allergyButtonTapped(_ sender: UIButton) {
        guard let allergy = sender.titleLabel?.text else { return }

        if sender.isSelected {
            // Deselect the allergy
            selectedAllergies.remove(allergy)
            sender.isSelected = false
            sender.backgroundColor = .clear
        } else {
            // Select the allergy
            selectedAllergies.insert(allergy)
            sender.isSelected = true
            sender.backgroundColor = .systemBlue
        }
    }

    @IBAction func nextButtonTapped(_ sender: UIButton) {
        // Save allergies to the database and mark onboarding as complete
        saveAllergiesToDatabase {
            self.markOnboardingComplete()
            self.navigateToHomeScreen()
        }
    }

    @IBAction func previousButtonTapped(_ sender: UIButton) {
        // Navigate back to the Onboarding Screen
        if storyboard?.instantiateViewController(withIdentifier: "OnboardingViewController") is OnboardingViewController {
            navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func skipButtonTapped(_ sender: UIButton) {
        // Mark onboarding as complete and navigate to the Home Screen
        markOnboardingComplete()
        navigateToHomeScreen()
    }

    private func saveAllergiesToDatabase(completion: @escaping () -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user ID found")
            completion()
            return
        }

        let userAllergies = Array(selectedAllergies)
        db.collection("users").document(userID).setData(["allergies": userAllergies], merge: true) { error in
            if let error = error {
                print("Error saving allergies: \(error)")
            } else {
                print("Allergies saved successfully!")
                self.markOnboardingComplete()
            }
            completion()
        }
    }

    private func markOnboardingComplete() {
        print("Marking onboarding as complete") // Debugging log
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
        // Optionally update Firestore
           if let userID = Auth.auth().currentUser?.uid {
               Firestore.firestore().collection("users").document(userID).updateData(["onboardingComplete": true]) { error in
                   if let error = error {
                       print("Error updating onboarding status in Firestore: \(error.localizedDescription)")
                   }
               }
           }
        navigateToHomeScreen()
    }

    private func navigateToHomeScreen() {
        if let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            self.navigationController?.setViewControllers([tabBarController], animated: true)
        }
    }
}
