//
//  DatabaseManager.swift
//  Messeger
//
//  Created by MAC on 01/06/2022.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
}

// MARK - Account Management
extension DatabaseManager {
    
    public func userExists(with email:String,
                           complition: @escaping((Bool) -> Void)) {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard  snapshot.value as? String != nil else {
                complition(false)
                return
            }
            complition(true)
        })
    }
    
    /// inserts user to database @param user:ChatAppUser
    public func insertUser(with user:ChatAppUser) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.firstName,
        ])
    }
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    // let profilePictureUrl: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}
