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

// MARK: - Account Management
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
    public func insertUser(with user:ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName,
        ], withCompletionBlock: {error, _ in
            guard error == nil else {
                print("Failed to add user")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value, with: {snapshot in
                if var usersCollection = snapshot.value as? [[String: Any]] {
                    // Append new user to exists
                    let newElement =  [
                        "name": "\(user.firstName) \(user.lastName)",
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: {error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                } else {
                    // Create user array
                    let newCollection: [[String: Any]] = [
                        [
                            "name": "\(user.firstName) \(user.lastName)",
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: {error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            })
            
            
        })
    }
    
    public func fetchAllUsers(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: {snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            
            completion(.success(value))
        })
    }
    
    public static func getSafeEmail(emailAddress: String) -> String {
        
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    public enum DatabaseErrors: Error {
        case failedToFetch
    }
}


// MARK: - Sending messages / conversations
extension DatabaseManager {
    
    /// Create a new converation
    /// - Parameters:
    ///   - otherUserEmail: <#otherUserEmail description#>
    ///   - name: <#name description#>
    ///   - firstMessage: <#firstMessage description#>
    ///   - completion: <#completion description#>
    public func createNewConversation(with otherUserEmail: String, name:String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.getSafeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: {snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                print("Cannot get user")
                completion(false)
                return
            }
            
            let stringDate = ChatViewController.dateFormatter.string(from: firstMessage.sentDate)
            
            var message = ""
            switch firstMessage.kind {
                
            case .text(let msg):
                message = msg
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            let conversationID = "conversation_\(firstMessage.messageId)"
            let newConversation: [String: Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": stringDate,
                    "is_read": false,
                    "message": message,
                ]
            ]
            
            let otherUserNewConversation: [String: Any] = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name": name,
                "latest_message": [
                    "date": stringDate,
                    "is_read": false,
                    "message": message,
                ]
            ]
            
            // update recipient conversation
            self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value,
                                                                                 with: {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String:Any]] {
                    // Append
                    conversations.append(otherUserNewConversation)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    // Create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([otherUserNewConversation])
                }
            })
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // Conversation exists
                // append new message
                conversations.append(newConversation)
                userNode["conversations"] = conversations
                
                ref.setValue(userNode, withCompletionBlock: {[weak self] error, result in
                    guard error == nil else {
                        print("Failed to add conversation")
                        completion(false)
                        return
                    }
                    self?.finishCreateConversation(name: name,
                                                   conversationID: conversationID,
                                                   firstMessage: firstMessage,
                                                   completion: completion)
                })
            } else {
                // Conversation doesn't exist
                // Create new one
                userNode["conversations"] = [
                    newConversation
                ]
                
                ref.setValue(userNode, withCompletionBlock: {[weak self] error, result in
                    guard error == nil else {
                        print("Failed to add conversation")
                        completion(false)
                        return
                    }
                    self?.finishCreateConversation(name: name,
                                                   conversationID: conversationID,
                                                   firstMessage: firstMessage,
                                                   completion: completion)
                    
                })
            }
        })
        
    }
    
    private func finishCreateConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        
        let stringDate = ChatViewController.dateFormatter.string(from: firstMessage.sentDate)
        
        
        var messageString = ""
        switch firstMessage.kind {
        case .text(let msg):
            messageString = msg
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        
        guard let curretEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        //        let safeEmail = DatabaseManager.getSafeEmail(emailAddress: curretEmail)
        let safeConversationID = DatabaseManager.getSafeEmail(emailAddress: conversationID)
        
        let message: [String:Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content":messageString,
            "date": stringDate,
            "sender_email": curretEmail,
            "is_read": false,
            "name": name,
        ]
        let value: [[String: Any]] = [
            message
        ]
        database.child("\(safeConversationID)/messages").setValue(value,  withCompletionBlock: {error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    /// Get all convetsations
    public func getAllConversations(for email: String,
                                    completion: @escaping (Result<[Conversation], Error>) -> Void) {
        let ref = self.database.child("\(email)")
        ref.observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [String:Any],
            let conversationsValue = value["conversations"] as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            let conversations: [Conversation] = conversationsValue.compactMap({dictionary in
                guard let convID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String:Any],
                      let isRead = latestMessage["is_read"] as? Bool,
                      let message = latestMessage["message"] as? String,
                      let date = latestMessage["date"] as? String else {
                    return nil
                }
                let conversation = Conversation(
                    id: convID,
                    otherUserEmail: otherUserEmail,
                    name: name,
                    latestMessage: LatestMessage(date: date,
                                                 message: message,
                                                 isRead: isRead)
                )
                
                return conversation
            })
            
            completion(.success(conversations))
        })
    }
    
    /// Get all messages in conversation
    public func getAllMessages(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        let safeId = DatabaseManager.getSafeEmail(emailAddress: id)
        let ref = database.child("\(safeId)")
        ref.observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [String: Any],
            let messagesValue = value["messages"] as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            let messages: [Message] = messagesValue.compactMap({dictionary in
                guard let messageID = dictionary["id"] as? String,
                      // let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let content = dictionary["content"] as? String,
                      // let isRead = dictionary["is_read"] as? Bool,
                      let name = dictionary["name"] as? String else {
                    return nil
                }
                let date = ChatViewController.dateFormatter.date(from: dateString)
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                let msg = Message(sender: sender,
                                  messageId: messageID,
                                  sentDate: date ?? Date(),
                                  kind: .text(content))
                
                return msg
            })
            completion(.success(messages))
        })
    }
    
    /// Send message to conversation
    public func sendMessage(to id: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureUrl: String {
        return "\(safeEmail)_profile_picture.png"
    }
}
