import UIKit
import FirebaseAuth

class SignupViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var loginLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    // MARK: - Configure UI
    func configureUI() {
        signupButton.layer.cornerRadius = 8
        
        // Add gesture recognizer to the loginLabel
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLoginLabel))
        loginLabel.isUserInteractionEnabled = true
        loginLabel.addGestureRecognizer(tapGesture)
        // Disable automatic strong passwords for the password text field
        passwordTextField.textContentType = .oneTimeCode
    }

    // MARK: - Keyboard Handling
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = keyboardFrame.height
    }

    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset.bottom = 0
    }

    // MARK: - Navigation
    @objc func didTapLoginLabel() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Signup Action
    @IBAction func signupButtonTapped(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(title: "Error", message: "Name cannot be empty.")
            return
        }
        
        guard name.count >= 3 else {
            showAlert(title: "Error", message: "Name must be at least 3 characters long.")
            return
        }
        
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(title: "Error", message: "Email cannot be empty.")
            return
        }
        
        guard isValidEmail(email) else {
            showAlert(title: "Error", message: "Please enter a valid email address.")
            return
        }
        
        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Password cannot be empty.")
            return
        }
        
        guard isValidPassword(password) else {
            showAlert(title: "Error", message: "Password must be at least 8 characters, contain one uppercase letter, one lowercase letter, one number, and one special character.")
            return
        }
        
        // Firebase signup
        // Call the FirebaseAuthManager to sign up the user
        FirebaseAuthManager.shared.signUpUser(email: email, password: password, name: name) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    // Show success alert and navigate back to the login page
                    self?.showAlert(title: "Success", message: message) {
                        self?.navigationController?.popViewController(animated: true)
                    }
                case .failure(let error):
                    // Handle FirebaseAuth errors using AuthErrorCode
                    if let errorCode = AuthErrorCode(rawValue: (error as NSError).code) {
                        var errorMessage = error.localizedDescription
                        switch errorCode {
                        case .emailAlreadyInUse:
                            errorMessage = "This email is already in use. Please use a different email."
                        case .weakPassword:
                            errorMessage = "The password is too weak. Please choose a stronger password."
                        case .invalidEmail:
                            errorMessage = "The email address is invalid. Please enter a valid email."
                        default:
                            errorMessage = error.localizedDescription
                        }
                        // Show an error alert with a user-friendly message
                        self?.showAlert(title: "Error", message: errorMessage)
                    } else {
                        // Fallback for unexpected errors
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    // MARK: - Email Validation
    /// Validates the email format using a regular expression
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // MARK: - Password Validation
    /// Validates the password for length and character requirements
    private func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[#$^+=!*()@%&]).{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }

    // MARK: - Show Alert
    /// Displays an alert with the provided title and message
    /// - Parameters:
    ///   - title: The title of the alert
    ///   - message: The message of the alert
    ///   - completion: Optional completion handler after the alert is dismissed
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true, completion: nil)
    }
}
