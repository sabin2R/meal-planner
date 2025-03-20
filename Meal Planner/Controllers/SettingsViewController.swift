import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    //@IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logoutButton: UIButton!

    // MARK: - Properties
    private let options = ["Change Password", "Edit Profile", "Allergy Preferences"]
    private let db = Firestore.firestore()
    private var userData: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        fetchAndDisplayUserProfile()
    }

    // MARK: - Setup UI
    private func setupUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill

        editProfileButton.addTarget(self, action: #selector(changeProfilePictureTapped), for: .touchUpInside)
        logoutButton.layer.cornerRadius = 8
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }

    // MARK: - Fetch User Profile
    private func fetchAndDisplayUserProfile() {
        guard let user = Auth.auth().currentUser else { return }

        // Fetch profile image from Firebase Storage or Auth
        if let photoURL = user.photoURL {
            DispatchQueue.global().async {
                if let imageData = try? Data(contentsOf: photoURL) {
                    DispatchQueue.main.async {
                        self.profileImageView.image = UIImage(data: imageData)
                    }
                }
            }
        }

        // Fetch user data from Firestore
        db.collection("users").document(user.uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error)")
                return
            }

            if let document = document, document.exists, let data = document.data() {
                self.userData = User(from: data)
                DispatchQueue.main.async {
                    self.nameLabel.text = self.userData?.name ?? "Unknown User"
                    //self.emailLabel.text = self.userData?.email ?? "Unknown Email"
                }
            }
        }
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCell", for: indexPath) as? SettingsTableViewCell else {
            return UITableViewCell()
        }
        cell.textLabel?.text = options[indexPath.row]
        return cell
    }

    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch options[indexPath.row] {
        case "Change Password":
            presentChangePasswordAlert()
        case "Edit Profile":
            presentEditProfileAlert()
        case "Allergy Preferences":
            presentEditAllergiesAlert()
        default:
            break
        }
    }

    // MARK: - Change Password
    private func presentChangePasswordAlert() {
        let alertController = UIAlertController(title: "Change Password", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Old Password"
            textField.isSecureTextEntry = true
        }
        alertController.addTextField { textField in
            textField.placeholder = "New Password"
            textField.isSecureTextEntry = true
        }
        let saveAction = UIAlertAction(title: "Update", style: .default) { _ in
            guard let oldPassword = alertController.textFields?[0].text,
                  let newPassword = alertController.textFields?[1].text else {
                return
            }
            self.updatePassword(oldPassword: oldPassword, newPassword: newPassword)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    private func updatePassword(oldPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }

        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                print("Error reauthenticating: \(error)")
                return
            }
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    print("Error updating password: \(error)")
                } else {
                    print("Password updated successfully.")
                }
            }
        }
    }

    // MARK: - Edit Profile
    private func presentEditProfileAlert() {
        let alertController = UIAlertController(title: "Edit Profile", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Name"
            textField.text = self.userData?.name
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let newName = alertController.textFields?.first?.text else { return }
            self.updateUserProfileName(newName: newName)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    private func updateUserProfileName(newName: String) {
        guard let user = Auth.auth().currentUser else { return }
        let userRef = db.collection("users").document(user.uid)

        userRef.updateData(["name": newName]) { error in
            if let error = error {
                print("Error updating name: \(error)")
            } else {
                print("Name updated successfully.")
                self.nameLabel.text = newName
            }
        }
    }

    // MARK: - Allergy Preferences
    private func presentEditAllergiesAlert() {
        let alertController = UIAlertController(title: "Edit Allergies", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Comma-separated allergies"
            textField.text = self.userData?.allergies.joined(separator: ", ")
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let allergiesText = alertController.textFields?.first?.text else { return }
            let allergies = allergiesText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            self.updateUserAllergies(newAllergies: allergies)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    private func updateUserAllergies(newAllergies: [String]) {
        guard let user = Auth.auth().currentUser else { return }
        let userRef = db.collection("users").document(user.uid)

        userRef.updateData(["allergies": newAllergies]) { error in
            if let error = error {
                print("Error updating allergies: \(error)")
            } else {
                print("Allergies updated successfully.")
                self.userData?.allergies = newAllergies
            }
        }
    }

    // MARK: - Change Profile Picture
    @objc private func changeProfilePictureTapped() {
        presentImagePicker()
    }

    private func presentImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }

    private func uploadProfileImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let user = Auth.auth().currentUser else {
            print("Failed to get image data or user is not authenticated.")
            return
        }

        let storageRef = Storage.storage().reference().child("profile_images/\(user.uid)")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error fetching download URL: \(error.localizedDescription)")
                    return
                }

                guard let url = url else {
                    print("No URL returned after upload.")
                    return
                }

                print("Profile image successfully uploaded. URL: \(url.absoluteString)")
                self.updateUserProfilePhotoURL(url)
            }
        }
    }



    private func updateUserProfilePhotoURL(_ url: URL) {
        guard let user = Auth.auth().currentUser else { return }

        let userRef = Firestore.firestore().collection("users").document(user.uid)
        userRef.updateData(["profileImageUrl": url.absoluteString]) { error in
            if let error = error {
                print("Error updating profile image URL in Firestore: \(error.localizedDescription)")
            } else {
                print("Profile image URL successfully updated in Firestore.")
            }
        }

        // Update the Firebase Authentication user's photoURL
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.photoURL = url
        changeRequest.commitChanges { error in
            if let error = error {
                print("Error updating profile photo URL: \(error.localizedDescription)")
            } else {
                print("Profile photo updated successfully.")
                self.fetchAndDisplayUserProfile()
            }
        }
    }


    // MARK: - Logout
    @IBAction func logoutTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            UserDefaults.standard.synchronize()
            navigateToLoginScreen()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
            showAlert(title: "Logout Failed", message: "Unable to log out. Please try again.")
        }
    }
    func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true, completion: nil)
        }


    private func navigateToLoginScreen() {
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            sceneDelegate.window?.rootViewController = loginVC
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        if let editedImage = info[.editedImage] as? UIImage {
            self.profileImageView.image = editedImage
            uploadProfileImage(editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            self.profileImageView.image = originalImage
            uploadProfileImage(originalImage)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
