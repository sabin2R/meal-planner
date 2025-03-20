import UIKit

class SettingsTableViewCell: UITableViewCell {

    // MARK: - Outlets
//    @IBOutlet weak var oldPasswordTextField: UITextField!
//    @IBOutlet weak var newPasswordTextField: UITextField!
//    @IBOutlet weak var updateButton: UIButton!

    // MARK: - Callback
    var onUpdateTapped: ((_ oldPassword: String?, _ newPassword: String?) -> Void)?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        //setupUI()
    }

    // MARK: - Setup
//    private func setupUI() {
//        updateButton.layer.cornerRadius = 8
//    }

    // MARK: - Actions
//    @IBAction func updateButtonTapped(_ sender: UIButton) {
//        let oldPassword = oldPasswordTextField.text
//        let newPassword = newPasswordTextField.text
//        onUpdateTapped?(oldPassword, newPassword)
    }

