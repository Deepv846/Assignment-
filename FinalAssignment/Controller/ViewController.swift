//
//  ViewController.swift
//  Assignment
//
//  Created by Deep Vora on 07/09/24.
//

import UIKit
import SwiftKeychainWrapper
import CoreData


class ViewController: UIViewController {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtHost: UITextField!
    @IBOutlet weak var btnSignin: UIButton!
    
    @IBOutlet weak var vwLogin: UIView!
    
    var activityView: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUIData()
    }


    
    func setUIData()
    {
        vwLogin.layer.cornerRadius = 10
        btnSignin.layer.cornerRadius = 15
        
        
    }
    
    func showActivityIndicator() {
        activityView = UIActivityIndicatorView(style: .large)
        activityView?.center = self.view.center
        self.view.addSubview(activityView!)
        activityView?.startAnimating()
    }

    func hideActivityIndicator(){
        if (activityView != nil){
            activityView?.stopAnimating()
        }
    }
    
    
    @objc private func loginButtonTapped() {
          guard let username = txtEmail.text, !username.isEmpty,
                let password = txtPassword.text, !password.isEmpty else {
              showAlert(message: "Fields cannot be empty.")
              return
          }
          
          guard isValidEmail(username) else {
              showAlert(message: "Username must be a valid email.")
              return
          }
          
          guard password.count >= 6 else {
              showAlert(message: "Password must be at least 6 characters long.")
              return
          }
          
          Task {
              await performLogin(username: username, password: password)
          }
      }
   
      
      private func saveTokenToKeychain(token: String) {
          let keychainQuery: [String: Any] = [
              kSecClass as String: kSecClassGenericPassword,
              kSecAttrAccount as String: "authToken",
              kSecValueData as String: token.data(using: .utf8) ?? Data()
          ]
          SecItemDelete(keychainQuery as CFDictionary)
          SecItemAdd(keychainQuery as CFDictionary, nil)
      }
      
      private func loadTokenFromKeychain() -> String? {
          let keychainQuery: [String: Any] = [
              kSecClass as String: kSecClassGenericPassword,
              kSecAttrAccount as String: "userToken",
              kSecReturnData as String: kCFBooleanTrue!,
              kSecMatchLimit as String: kSecMatchLimitOne
          ]
          
          var dataTypeRef: AnyObject? = nil
          let status: OSStatus = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
          
          if status == noErr {
              if let data = dataTypeRef as? Data {
                  return String(data: data, encoding: .utf8)
              }
          }
          return nil
      }
      
      private func saveUser(username: String, password: String, token: String) {
          guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
          let context = appDelegate.persistentContainer.viewContext
          
          let user = Login(context: context)
          user.username = username
          user.token = token
        
          do {
              try context.save()
          } catch {
              print("Failed saving user data")
          }
      }
      
      private func performLogin(username: String, password: String) async {
          let url = URL(string: "https://mofa.onice.io/teamchatapi/iwauthentication.login.plain")!
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
          
          let body = "username=\(username)&password=\(password)"
          request.httpBody = body.data(using: .utf8)
          
          do {
              let (data, response) = try  await URLSession.shared.data(for: request)
              
             let httpResponse = response as? HTTPURLResponse
             hideActivityIndicator()
             print(httpResponse?.statusCode)
              
              if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                  if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                     let token = json["token"] as? String {
                      saveUser(username: username, password: password, token: token)
                      saveTokenToKeychain(token: token)
                      navigateToChannelsScreen()
                  }
              } else {
                  showAlert(message: "Login failed. Please check your credentials.")
              }
          } catch {
              showAlert(message: "An error occurred: \(error.localizedDescription)")
          }
      }
      
      private func navigateToChannelsScreen() {
          let secondViewController = (self.storyboard?.instantiateViewController(withIdentifier: "ChannelsViewController") as? ChannelsViewController)!
          self.navigationController?.pushViewController(secondViewController, animated: true)
      }

   
    @IBAction func btnSignPressed(_ sender: Any) {
        
        showActivityIndicator()
       loginButtonTapped()
    }
    
}


extension ViewController
{
    func isValidEmail(_ email: String) -> Bool {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
            return emailPred.evaluate(with: email)
        }
    
    func showAlert(message: String) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    
}

