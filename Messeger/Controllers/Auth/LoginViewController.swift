//
//  LoginViewController.swift
//  Messeger
//
//  Created by MAC on 31/05/2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import FBSDKLoginKit

class LoginViewController: UIViewController {
    
    private let snipper = JGProgressHUD(style: .dark)
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0   ))
        field.leftViewMode = .always
        field.keyboardType = UIKeyboardType.emailAddress
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0   ))
        field.leftViewMode = .always
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton:UIButton = {
        let button = UIButton()
        button.setTitle("Log in", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        loginButton.addTarget(self,
                              action: #selector(loginTapped),
                              for: .touchUpInside)
        facebookLoginButton.delegate = self
        
        
        emailField.delegate = self
        passwordField.delegate = self
        
        // Add subview
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let width = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width-width) / 2,
                                 y: 40,
                                 width: width,
                                 height: width)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 10,
                                  width: scrollView.width-60,
                                  height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width-60,
                                     height: 52)
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 10,
                                   width: scrollView.width-60,
                                   height: 52)
        
        facebookLoginButton.frame = CGRect(x: 30,
                                           y: loginButton.bottom + 10,
                                           width: scrollView.width-60,
                                           height: 52)
        
    }
    
    @objc private func loginTapped() {
        emailField.resignFirstResponder()
        emailField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else  {
            alertUserLoginError()
            return
        }
        // Show Snipper
        snipper.show(in: view)
        // Firebase Login
        FirebaseAuth.Auth.auth().signIn( withEmail: email, password: password, completion: {[weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.snipper.dismiss(animated: true)
            }
            
            UserDefaults.standard.setValue(email, forKey: "email")
            let safeEmail = DatabaseManager.getSafeEmail(emailAddress: email)
            DatabaseManager.shared.fetchDataFor(path: safeEmail,completion: {result in
                switch result {
                    
                case .success(let data):
                    //                    guard case let firstName != user["first_name"] as? String, let lastName != user["last_name"] as? String else {
                    //                        return
                    //
                    //                    }
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("Error while fetch user - \(error)")
                }
            })
//            UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
            let em = UserDefaults.standard.value(forKey: "email") as? String ?? "Not defiend"
            print("Login email is: \(em)")
            
            guard let result = authResult, error == nil else {
                print("Cannot login to \(email)")
                return
            }
            let user = result.user
            print(user)
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
    }
    
    private func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginTapped()
        }
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            return
        }
        print("token: \(token)")
        
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "id,first_name,last_name,email,picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completion: {_, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to gragh data: \(String(describing: error))")
                return
            }
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let picture = result["picture"] as? [String:Any],
                  let data = picture["data"] as? [String:Any],
                  let pictureUrl = data["url"] as? String,
                  let userEmail = result["email"] as? String else {
                print("Cannot fetch data")
                return
            }
            
            print("Picture: \(picture)")
           
            
            UserDefaults.standard.setValue(userEmail, forKey: "email")
            UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
            
            DatabaseManager.shared.userExists(with: userEmail, complition: {exists in
                if !exists {
                    let user = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: userEmail)
                    DatabaseManager.shared.insertUser(with: user, completion: {success in
                        if success {
                            print("User inserted successfully")
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            
                            
                            URLSession.shared.dataTask(with: url, completionHandler: {data, _, error in
                                guard let data = data, error == nil else  {
                                    print("Cannot download profile picture -\(String(describing: error))")
                                    return
                                }
                                
                                let filename = user.profilePictureUrl
                                print("File name is -\(filename)")
                                
                                StorageManager.shared.uploadProfilePicture(with: data,
                                                                           fileName: filename,
                                                                           complition: {result in
                                    switch result {
                                   
                                    case .success(let url):
                                        UserDefaults.standard.set(url, forKey: "profile_picture_url")
                                        print("Image fetched from facebook: \(url)")
                                    case .failure(let error):
                                        print("Cannot upload image from facebook - \(error)")
                                    }
                                    
                                   
                                })
                            }).resume()
                        }
                        
                    })
                }
                
                let credential = FacebookAuthProvider.credential(withAccessToken: token)
                FirebaseAuth.Auth.auth().signIn(with: credential, completion: {[weak self] authResult, error in
                    guard let strongSelf = self, authResult != nil, error == nil else {
                        if error != nil {
                            print("Login Failed with facebook credentials: \(String(describing: error))")
                        }
                        return
                    }
                    strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                })
            })
            
        })
    }
    
    
}
