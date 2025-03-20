import Foundation

struct User {
    let userID: String
    let name: String
    let email: String
    var allergies: [String] = [] // Default is an empty array
    var profileImageUrl: String? // Optional profile image URL
    var calorieIntake: Int? // Optional daily calorie intake
    var proteinIntake: Double? // Individual protein intake
    var carbIntake: Double? // Individual carbohydrate intake
    var fatIntake: Double? // Individual fat intake

    init(
        userID: String,
        name: String,
        email: String,
        allergies: [String] = [],
        profileImageUrl: String? = nil,
        calorieIntake: Int? = nil,
        proteinIntake: Double? = nil,
        carbIntake: Double? = nil,
        fatIntake: Double? = nil
    ) {
        self.userID = userID
        self.name = name
        self.email = email
        self.allergies = allergies
        self.profileImageUrl = profileImageUrl
        self.calorieIntake = calorieIntake
        self.proteinIntake = proteinIntake
        self.carbIntake = carbIntake
        self.fatIntake = fatIntake
    }

    init?(from dictionary: [String: Any]) {
        guard
            let userID = dictionary["userID"] as? String,
            let name = dictionary["name"] as? String,
            let email = dictionary["email"] as? String
        else {
            print("Required user fields missing in Firestore document.") // Debugging log
            return nil
        }

        self.userID = userID
        self.name = name
        self.email = email
        self.allergies = dictionary["allergies"] as? [String] ?? []
        self.profileImageUrl = dictionary["profileImageUrl"] as? String
        self.calorieIntake = dictionary["calorieIntake"] as? Int
        self.proteinIntake = dictionary["proteinIntake"] as? Double
        self.carbIntake = dictionary["carbIntake"] as? Double
        self.fatIntake = dictionary["fatIntake"] as? Double
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userID": userID,
            "name": name,
            "email": email,
            "allergies": allergies
        ]
        if let profileImageUrl = profileImageUrl {
            dict["profileImageUrl"] = profileImageUrl
        }
        if let calorieIntake = calorieIntake {
            dict["calorieIntake"] = calorieIntake
        }
        if let proteinIntake = proteinIntake {
            dict["proteinIntake"] = proteinIntake
        }
        if let carbIntake = carbIntake {
            dict["carbIntake"] = carbIntake
        }
        if let fatIntake = fatIntake {
            dict["fatIntake"] = fatIntake
        }
        return dict
    }
}
