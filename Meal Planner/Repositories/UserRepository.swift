import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserRepository {
    
    private let db = Firestore.firestore()
    
    // Fetch user data from Firestore for the home screen header
    func fetchUserData(completion: @escaping (User?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No authenticated user found.")
            completion(nil)
            return
        }

        let userDoc = db.collection("users").document(userID)
        userDoc.getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("No user data found for userID: \(userID)")
                completion(nil)
                return
            }
            
            if let user = User(from: data) {
                completion(user)
            } else {
                print("Error decoding user data")
                completion(nil)
            }
        }
    }
    
    // Save allergies to Firestore
    func saveUserAllergies(allergies: [String], completion: @escaping (Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let userDoc = db.collection("users").document(userID)
        userDoc.updateData(["allergies": allergies]) { error in
            if let error = error {
                print("Error saving allergies: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Fetch user allergies from Firestore
    func fetchUserAllergies(completion: @escaping ([String]) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        let userDoc = db.collection("users").document(userID)
        userDoc.getDocument { document, error in
            if let document = document, document.exists, let allergies = document.data()?["allergies"] as? [String] {
                completion(allergies)
            } else {
                print("Error fetching allergies: \(error?.localizedDescription ?? "No error")")
                completion([])
            }
        }
    }
}
