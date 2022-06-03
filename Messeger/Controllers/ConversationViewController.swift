//
//  ViewController.swift
//  Messeger
//
//  Created by MAC on 31/05/2022.
//

import UIKit
import FirebaseAuth

class ConversationViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateUser()
    }
    
    private func validateUser() {
        let currentUser = FirebaseAuth.Auth.auth().currentUser
        if currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            
            present(nav, animated: false)
        }
    }
    
    
}

