import FirebaseAuth
import FirebaseFirestore

/// Manager class for handling Firebase Authentication and Firestore integration
class FirebaseAuthManager {
    
    // Singleton instance
    static let shared = FirebaseAuthManager()
    
    private let db = Firestore.firestore() // Firestore instance for database operations
    
    private init() {}
    
    // MARK: - Sign Up
    /**
     Signs up a user with the provided email, password, and name.
     - Parameters:
       - email: The user's email.
       - password: The user's password.
       - name: The user's display name.
       - completion: A closure that returns a `Result` with a success message or an error.
     */
    func signUpUser(email: String, password: String, name: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "FirebaseAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User creation failed."])))
                return
            }
            
            // Update the user's display name
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.commitChanges { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // Create a Firestore document for the new user
                    self.createUserDocument(userID: user.uid, name: name, email: email) { firestoreResult in
                        switch firestoreResult {
                        case .success:
                            completion(.success("User signed up successfully!"))
                        case .failure(let firestoreError):
                            completion(.failure(firestoreError))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Login
    /**
     Logs in a user with the provided email and password.
     - Parameters:
       - email: The user's email.
       - password: The user's password.
       - completion: A closure that returns a `Result` with a success message or an error.
     */
    func loginUser(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // Authentication failed, return the error
                completion(.failure(error))
                return
            }

            guard let authResult = authResult else {
                // No auth result returned, treat as failure
                completion(.failure(NSError(domain: "FirebaseAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login failed. Invalid credentials."])))
                return
            }

            // User successfully authenticated
            completion(.success(authResult))
        }
    }





    // Fetch user data from Firestore
    func fetchUserData(userID: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user document: \(error)") // Debugging log
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                print("No data found for userID: \(userID)") // Debugging log
                completion(.failure(NSError(domain: "Firestore", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data found"])))
                return
            }
            
            var dataWithUserID = data
            dataWithUserID["userID"] = userID // Add userID to the dictionary if it's missing
            
            print("Fetched user data: \(data)") // Debugging log
            if let user = User(from: data) {
                completion(.success(user))
            } else {
                print("Error decoding user data.") // Debugging log
                completion(.failure(NSError(domain: "Firestore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error decoding user data"])))
            }
        }
    }


    
    // MARK: - Handle Auth Errors
    /**
     Converts Firebase Authentication errors into user-friendly error messages.
     - Parameter error: The error received from Firebase Authentication.
     - Returns: A user-friendly error message.
     */
    func handleAuthError(_ error: Error) -> String {
        if let errorCode = AuthErrorCode(rawValue: (error as NSError).code) {
            switch errorCode {
            case .emailAlreadyInUse:
                return "This email is already in use. Please use a different email."
            case .weakPassword:
                return "The password is too weak. Please choose a stronger password."
            case .invalidEmail:
                return "The email address is invalid. Please enter a valid email."
            case .userNotFound:
                return "No account found with this email. Please sign up first."
            case .wrongPassword:
                return "Incorrect password. Please try again."
            
            default:
                return error.localizedDescription
            }
        } else {
            return error.localizedDescription
        }
    }
    
    // MARK: - Firestore User Document
    /**
     Creates a user document in Firestore upon signup.
     - Parameters:
       - userID: The Firebase Authentication UID of the user.
       - name: The user's name to be stored in Firestore.
       - email: The user's email to be stored in Firestore.
       - completion: A closure that returns a `Result` indicating success or failure.
     */
    private func createUserDocument(userID: String, name: String, email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userData: [String: Any] = [
            "userID": userID,
            "name": name,
            "email": email,
            "allergies": [] // Default value for allergies
        ]
        
        db.collection("users").document(userID).setData(userData) { error in
            if let error = error {
                print("Error creating Firestore user document: \(error)")
                completion(.failure(error))
            } else {
                print("Firestore user document created successfully for userID: \(userID)")
                completion(.success(()))
            }
        }
    }
}
