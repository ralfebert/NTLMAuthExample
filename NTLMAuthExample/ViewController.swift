//
//  ViewController.swift
//  NTLMAuthExample
//
//  Created by Ralf Ebert on 01.07.20.
//  Copyright © 2020 Ralf Ebert. All rights reserved.
//

import Foundation
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var execButton: UIButton!
    
    var username: String? = nil
    var password: String? = nil
    
    lazy var urlSession : URLSession = {
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    
    @IBAction func execButtonTapped(sender: UIButton) {
        
        let url = URL(string: "http://www.example.com")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60000)
        
        //let body = "some body"
        //request.httpMethod = "POST"
        //request.httpBody = body.data(using: .utf8)
        
        let task = urlSession.dataTask(with: request)
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func login(username: String?, password: String?) {
        self.username = username
        self.password = password
    }
    
    func presentLogin() {
        let alertView = UIAlertController(title: "Please login", message: "You need to provide credentials to make this call.", preferredStyle: .alert)
        
        let loginAction = UIAlertAction(title: "Login", style: .default) { action in
            let username = alertView.textFields![0] as UITextField
            let password = alertView.textFields![1] as UITextField
            
            self.login(username: username.text, password: password.text)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        
        alertView.addTextField { textField in
            textField.placeholder = "Username"
        }
        
        alertView.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alertView.addAction(cancelAction)
        alertView.addAction(loginAction)
        
        self.present(alertView, animated: true, completion: {})
    }

    func doesHaveCredentials() -> Bool {
        guard let _ = self.username else { return false }
        guard let _ = self.password else { return false }
        
        return true
    }
}


extension ViewController: URLSessionDelegate {

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        print("got challenge")
        
        guard challenge.previousFailureCount == 0 else {
            print("too many failures")
            self.username = nil
            self.password = nil
            challenge.sender?.cancel(challenge)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM else {
            print("unknown authentication method \(challenge.protectionSpace.authenticationMethod)")
            challenge.sender?.cancel(challenge)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        guard self.doesHaveCredentials() else {
            challenge.sender?.cancel(challenge)
            completionHandler(.cancelAuthenticationChallenge, nil)
            DispatchQueue.main.async {
                self.presentLogin()
            }
            return
        }
        
        let credentials = URLCredential(user: self.username!, password: self.password!, persistence: .forSession)
        challenge.sender?.use(credentials, for: challenge)
        completionHandler(.useCredential, credentials)
    }
    
}

extension ViewController: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

        guard let httpResponse = response as? HTTPURLResponse else { return }
        print(httpResponse.description)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("done with error: ", error)
    }
    
}
