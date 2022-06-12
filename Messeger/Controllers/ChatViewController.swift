//
//  ChatViewController.swift
//  Messeger
//
//  Created by MAC on 04/06/2022.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage


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


struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
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
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.delegate = self
        messageInputBar.delegate = self
        setupBarButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    private func setupBarButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 36, height: 36), animated: true)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside({[weak self] _ in
            self?.presentPhotoInputActionSheet()
        })
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentPhotoInputActionSheet()  {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attache", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Image", style: .default, handler: {[ weak self ]_ in
            self?.presentPhotoInputAction()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {[weak self] _ in
            self?.presentVideoInputAction()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputAction() {
        let phoyoActionSheet = UIAlertController(title: "Add Photo",
                                                 message: "Where would you like to attach photo from?",
                                                 preferredStyle: .actionSheet)
        phoyoActionSheet.addAction(UIAlertAction(title: "Camera",
                                                 style: .default,
                                                 handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.allowsEditing = true
            picker.delegate = self
            self?.present(picker, animated: true)
            
        }))
        phoyoActionSheet.addAction(UIAlertAction(title: "Library",
                                                 style: .default,
                                                 handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.allowsEditing = true
            picker.delegate = self
            self?.present(picker, animated: true)
            
        }))
        phoyoActionSheet.addAction(UIAlertAction(title: "Cancel",
                                                 style: .cancel,
                                                 handler: nil))
        present(phoyoActionSheet, animated: true)
    }
    
    
    private func presentVideoInputAction() {
        let phoyoActionSheet = UIAlertController(title: "Add Video",
                                                 message: "Where would you like to attach video from?",
                                                 preferredStyle: .actionSheet)
        phoyoActionSheet.addAction(UIAlertAction(title: "Camera",
                                                 style: .default,
                                                 handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            self?.present(picker, animated: true)
            
        }))
        phoyoActionSheet.addAction(UIAlertAction(title: "Library",
                                                 style: .default,
                                                 handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            self?.present(picker, animated: true)
            
        }))
        phoyoActionSheet.addAction(UIAlertAction(title: "Cancel",
                                                 style: .cancel,
                                                 handler: nil))
        present(phoyoActionSheet, animated: true)
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

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
              let imageData = image.pngData(),
              let messageId = createMessageId(),
              let conversationId = conversationId,
              let name = self.title,
              let selfSender = selfSender else {
            return
        }
        
        let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
        StorageManager.shared.uploadMessagePhoto(with: imageData,
                                                 fileName: fileName,
                                                 complition: {[weak self] result in
            
            guard let strongSelf = self else {
                return
            }
            
            switch result {
                
            case .success(let stringURL):
                print("Image uploaded successfully - \(stringURL)")
                guard let url = URL(string: stringURL),
                      let placeholder = UIImage(systemName: "plus") else {
                    return
                }
                let media = Media(url: url,
                                  image: nil,
                                  placeholderImage: placeholder,
                                  size: .zero)
                
                let message = Message(sender: selfSender,
                                      messageId: messageId,
                                      sentDate: Date(),
                                      kind: .photo(media))
                
                DatabaseManager.shared.sendMessage(to: conversationId,
                                                   otherUserEmail: strongSelf.otherSenderEmail,
                                                   name: name,
                                                   newMessage: message,
                                                   completion: { [weak self] success in
                    if success {
                        print("Image media sent successfully")
                    } else {
                        print("Cannot send message media")
                    }
                })
            case .failure(let error):
                print("Cannot upload image - \(error)")
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // Here we can download media to display it
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
            
        case .photo(let media):
            guard let url = media.url else {
                return
            }
           
            imageView.sd_setImage(with: url, completed: { _, error, _, url in
                guard error == nil else {
                    print("Error while download image: \(String(describing: error))")
                    return
                }
            })
        default:
            break
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let media):
            guard let url = media.url else {
                return
            }
            
            let vc = PhotoViewerViewController(with: url)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
