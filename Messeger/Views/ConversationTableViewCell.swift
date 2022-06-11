//
//  ConversationTableViewCell.swift
//  Messeger
//
//  Created by MAC on 06/06/2022.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    public static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 50
        avatar.layer.masksToBounds = true
        return avatar
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 100,
                                     height: 100)
        
        userNameLabel.frame = CGRect(x: 10 + userImageView.right,
                                     y: 10,
                                     width: contentView.width - 2 - userImageView.width,
                                     height: (contentView.height - 20) / 2)
        
        userMessageLabel.frame = CGRect(x: 10 + userImageView.right,
                                        y: 5 + userNameLabel.bottom,
                                        width: contentView.width - 2 - userImageView.width,
                                        height: (contentView.height - 20) / 2)
        
    }
    
    func configure(with model: Conversation) {
        userNameLabel.text = model.name
        userMessageLabel.text = model.latestMessage.message
        
        let path = "/images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.getDownloadURL(for: path,
                                             completion: {[weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("Cannot fetch download url - \(error)")
            }
        })
    }
}
