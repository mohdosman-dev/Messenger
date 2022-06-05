//
//  ChatViewController.swift
//  Messeger
//
//  Created by MAC on 04/06/2022.
//

import UIKit
import MessageKit


struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}


class ChatViewController: MessagesViewController {
    
    private var messages = [Message]()
    
    private let sender: Sender = Sender(photoURL: "1",
                                        senderId: "1",
                                        displayName: "Mohammed Osman")
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append(Message(sender: sender,
                                messageId: "1",
                                sentDate: Date(),
                                kind: .text("Hello World!")))
        
        
        messages.append(Message(sender: sender,
                                messageId: "2",
                                sentDate: Date(),
                                kind: .text("Hello World!,Hello World!,Hello World!,Hello World!,Hello World!,Hello World!,Hello World!,Hello World!,Hello World!,Hello World!,Hello World!")))
        
        
        messages.append(Message(sender: sender,
                                messageId: "1",
                                sentDate: Date(),
                                kind: .text("Hello World!")))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
}


extension ChatViewController: MessagesDataSource,
                              MessagesLayoutDelegate,
                              MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
