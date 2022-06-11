//
//  ChatViewController.swift
//  Messeger
//
//  Created by MAC on 04/06/2022.
//

import UIKit
import MessageKit
import InputBarAccessoryView


struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String  {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}


class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public let otherSenderEmail: String
    public let conversationId: String?
    
    public var isNewConversation = false
    
    private var messages = [Message]()
    
    private let selfSender: Sender? = {
        guard let email = UserDefaults.standard.value(forKey: "email")  as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.getSafeEmail(emailAddress: email)
        let sender = Sender(photoURL: "1",
                            senderId: safeEmail,
                            displayName: "Mohammed Osman")
        return sender;
    } ()
    
    
    init(with email: String, id: String?) {
        self.otherSenderEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
        if let convId = conversationId {
            listenForMessages(with: convId)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    private func listenForMessages(with id:String) {
        DatabaseManager.shared.getAllMessages(with: id, completion: {[weak self] result in
            switch result {
                
            case .success(let fetchedMessages):
                guard !fetchedMessages.isEmpty else {
                    return
                }
                
                self?.messages = fetchedMessages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    self?.messagesCollectionView.scrollToLastItem()
                }
            case .failure(let error):
                print("Error while fetching messages: \(error)")
            }
        })
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let messageId = createMessageId(),
              let sender = self.selfSender else {
            return
        }
        
        
        
        // Create new conversation
        let message = Message(sender: sender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        // Send message in convo
        if isNewConversation {
           
            let safeEmail = DatabaseManager.getSafeEmail(emailAddress: self.otherSenderEmail)
            DatabaseManager.shared.createNewConversation(with: safeEmail,
                                                         name: self.title ?? "User",
                                                         firstMessage: message,
                                                         completion: {success in
                
                if success {
                    print("Message sent to: \(self.otherSenderEmail)")
                    self.isNewConversation = false
                } else {
                    print("Cannot send message")
                }
                
            })
        } else {
            // append messeage to the collection
            guard let conversationId = conversationId else {
                return
            }
            guard let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId,
                                               otherUserEmail: self.otherSenderEmail,
                                               name: name,
                                               newMessage: message,
                                               completion: {success in
                if success {
                    print("Message sent successfully")
                } else {
                    print("Failed to send message")
                }
            })
        }
    }
    
    
    private func createMessageId() -> String? {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email")  as? String else {
            return nil
        }
        
        
        let dateString = Self.dateFormatter.string(from: Date())
        
        let safeEmail = DatabaseManager.getSafeEmail(emailAddress: currentUserEmail)
        
        let uniqueId = "\(otherSenderEmail)_\(safeEmail)_\(dateString)"
        print("Unique ID: \(uniqueId)")
        return uniqueId
    }
}

extension ChatViewController: MessagesDataSource,
                              MessagesLayoutDelegate,
                              MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        guard let sender = self.selfSender else {
            
            return Sender(photoURL: "", senderId: "1", displayName: "Test Sender")
            
        }
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
    
}
