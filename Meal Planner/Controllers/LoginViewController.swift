import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupLabel: UILabel!

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Adds keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Removes keyboard observers
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - UI Configuration
    func configureUI() {
        loginButton.layer.cornerRadius = 8
        
        // Add gesture recognizer to the signupLabel
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSignupLabel))
        signupLabel.isUserInteractionEnabled = true
        signupLabel.addGestureRecognizer(tapGesture)
    }

    // MARK: - Keyboard Handling
    @objc func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = keyboardFrame.height
    }

    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset.bottom = 0
    }

    // MARK: - Navigation
    @objc func didTapSignupLabel() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let signupVC = storyboard.instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController {
            navigationController?.pushViewController(signupVC, animated: true)
        }
    }

    // MARK: - Login Action
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        print("Login button tapped.") // Debug log
        guard let email = emailTextField.text, !email.isEmpty, isValidEmail(email),
              let password = passwordTextField.text, !password.isEmpty else {
            print("Error: Invalid email or password.") // Debug log
            showAlert(title: "Error", message: "Please enter a valid email and password.")
            return
        }

        print("Attempting to sign in with email: \(email)") // Debug log

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Login failed: \(error.localizedDescription)") // Debug log
                    self?.showAlert(title: "Login Failed", message: error.localizedDescription)
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    print("Error: Firebase authentication returned no user.") // Debug log
                    self?.showAlert(title: "Error", message: "Unexpected error occurred. Please try again.")
                    return
                }

                print("Successfully authenticated. Fetching Firestore user data...") // Debug log

                // Fetch additional user data from Firestore
                FirebaseAuthManager.shared.fetchUserData(userID: firebaseUser.uid) { result in
                    switch result {
                    case .success(let user):
                        print("User data fetched successfully: \(user)") // Debug log
                        self?.handleLoginSuccess(user: user)
                    case .failure(let error):
                        print("Error fetching user data: \(error.localizedDescription)") // Debug log
                        self?.showAlert(title: "Error", message: "Failed to fetch user data: \(error.localizedDescription)")
                    }
                }
            }
        }
    }






    // MARK: - Handle Successful Login
    private func handleLoginSuccess(user: User) {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        print("Has completed onboarding: \(hasCompletedOnboarding)") // Debugging log
        
        if user.allergies.isEmpty {
            // Navigate to onboarding if no allergies set
            performSegue(withIdentifier: "toOnboardingScreen", sender: nil)
        } else {
            // Mark onboarding complete and navigate to home
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.synchronize()
            
            navigateToHomeScreen()
        }
    }

    private func navigateToHomeScreen() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
        
        if let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            self.navigationController?.setViewControllers([tabBarController], animated: true)
        }
    }


    // MARK: - Show Alert
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Email Validation
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

