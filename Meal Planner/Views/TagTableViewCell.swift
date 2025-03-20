import UIKit

class TagTableViewCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var stackView: UIStackView! // For displaying tags
    @IBOutlet weak var sourceLabel: UILabel! // Label for source text
    @IBOutlet weak var sourceLinkLabel: UILabel! // Label for source URL link

    // MARK: - Configuration
    func configure(with tags: [String], source: String?, sourceURL: String?) {
        // Clear previous tags
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add tags to the stack view
        for tag in tags {
            let label = UILabel()
            label.text = tag
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .white
            label.backgroundColor = .systemBlue
            label.textAlignment = .center
            label.layer.cornerRadius = 8
            label.clipsToBounds = true
            label.setContentHuggingPriority(.required, for: .horizontal)
            stackView.addArrangedSubview(label)
        }

        // Configure source label
        if let source = source, !source.isEmpty {
            sourceLabel.text = "Source: \(source)"
            sourceLabel.isHidden = false
        } else {
            sourceLabel.isHidden = true
        }

        // Configure source link label
        if let sourceURL = sourceURL, !sourceURL.isEmpty {
            sourceLinkLabel.text = sourceURL
            sourceLinkLabel.textColor = .systemBlue
            sourceLinkLabel.isHidden = false
            // Add a tap gesture recognizer to handle link tapping
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSourceLink))
            sourceLinkLabel.isUserInteractionEnabled = true
            sourceLinkLabel.addGestureRecognizer(tapGesture)
        } else {
            sourceLinkLabel.isHidden = true
        }
    }

    // MARK: - Actions
    @objc private func didTapSourceLink() {
        guard let urlString = sourceLinkLabel.text, let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
