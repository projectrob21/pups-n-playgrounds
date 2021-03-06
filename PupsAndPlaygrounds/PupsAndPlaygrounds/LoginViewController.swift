//
//  LoginViewController.swift
//  PupsAndPlaygrounds
//
//  Created by William Robinson on 11/18/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import UIKit
import SnapKit
import Firebase

final class LoginViewController: UIViewController {
    
    // MARK: Properties
    let loginView = LoginView()
    let containerVC = (UIApplication.shared.delegate as? AppDelegate)?.containerViewController
    let store = DataStore.shared
    
    // MARK: Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginView.emailField.delegate = self
        loginView.passwordField.delegate = self
        
        loginView.loginButton.addTarget(self, action: #selector(loginButtonTouched), for: .touchUpInside)
        
        loginView.createAccountButton.addTarget(self, action: #selector(createAccountButtonTouched), for: .touchUpInside)
        loginView.skipButton.addTarget(self, action: #selector(skipButtonTouched), for: .touchUpInside)
        loginView.forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTouched), for: .touchUpInside)
        
        view.addSubview(loginView)
        loginView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    override func viewDidLayoutSubviews() {
        loginView.topView.layer.addSublayer(CustomBorder(.bottom, UIColor.white, 3, loginView.topView.frame))
        loginView.middleView.layer.addSublayer(CustomBorder(.bottom, UIColor.white, 3, loginView.middleView.frame))
        
        loginView.emailField.layer.addSublayer(CustomBorder(.bottom, UIColor.white, 1, loginView.emailField.frame))
        loginView.passwordField.layer.addSublayer(CustomBorder(.bottom, UIColor.white, 1, loginView.passwordField.frame))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        _ = view.endEditing(true)
    }
    
    // MARK: Action Methods
    func loginButtonTouched() {
        guard let email = loginView.emailField.text else { print("error unwrapping user email"); return }
        guard let password = loginView.passwordField.text else { print("error unwrapping user password"); return }
        
        FIRClient.login(email: email, password: password) {
            self.containerVC?.childVC = MainTabBarController()
            self.containerVC?.setup(forAnimation: .slideDown)
        }
    }
    
    func createAccountButtonTouched() {
        self.containerVC?.childVC = CreateAccountViewController()
        self.containerVC?.setup(forAnimation: .slideUp)
    }
    
    func skipButtonTouched() {
        FIRAuth.auth()?.signInAnonymously { user, error in
            guard error == nil else  { print("error signing user in anonymously"); return }
            
            let mainTBC = MainTabBarController()
            self.containerVC?.childVC = mainTBC
            self.containerVC?.setup(forAnimation: .slideDown)
        }
    }
    
    func forgotPasswordTouched() {
        let alertController = UIAlertController(title: "Enter E-Mail", message: "We'll send you a password reset e-mail", preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: "Send", style: .default) { (action) in
            let emailField = alertController.textFields![0]
            if let email = emailField.text {
                
                FIRAuth.auth()?.sendPasswordReset(withEmail: email, completion: { (error) in
                    // Handle error
                    if let error = error {
                        
                        let alertController = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                            self.dismiss(animated: true, completion: nil)
                        })
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                        // Success
                    } else {
                        let alertController = UIAlertController(title: "Success", message: "Password reset e-mail sent", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                            self.dismiss(animated: true, completion: nil)
                        })
                        alertController.addAction(okAction)
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                })
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        alertController.addTextField { (textfield) in
            textfield.placeholder = "Enter E-mail"
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
}
