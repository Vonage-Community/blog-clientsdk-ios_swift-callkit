//
//  ViewController.swift
//  PhoneToApp
//
//  Created by Abdulhakim Ajetunmobi on 06/07/2020.
//  Copyright © 2020 Vonage. All rights reserved.
//

import UIKit
import VonageClientSDKVoice

class ViewController: UIViewController {
    
    private let connectionStatusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        ClientManager.shared.delegate = self
        
        connectionStatusLabel.text = ""
        connectionStatusLabel.textAlignment = .center
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(connectionStatusLabel)
        
        view.addConstraints([
            connectionStatusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            connectionStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}

extension ViewController: ClientManagerDelegate {
    /*
     When the Client status changes,
     This function will update the connectionStatusLabel.
     */
    func clientStatusUpdated(_ clientManager: ClientManager, status: String) {
        DispatchQueue.main.async {
            self.connectionStatusLabel.text = status
        }
    }
}
