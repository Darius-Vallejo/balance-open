//
//  RootViewController.swift
//  BalanceiOS
//
//  Created by Red Davis on 05/09/2017.
//  Copyright © 2017 Balanced Software, Inc. All rights reserved.
//

import SnapKit
import UIKit


internal final class RootViewController: UIViewController
{
    // Internal
    
    // Private
    private let rootTabBarController = UITabBarController()
    private let accountsListViewController = AccountsListViewController()
    private let transactionsListViewController = TransactionsListViewController()
    private let settingsViewController = SettingsViewController()
    
    // MARK: Initialization
    
    internal required init()
    {
        super.init(nibName: nil, bundle: nil)
        
        // Tab bar controller
        let accountsListNavigationController = UINavigationController(rootViewController: self.accountsListViewController)
        let transactionsListNavigationController = UINavigationController(rootViewController: self.transactionsListViewController)
        let settingsNavigationController = UINavigationController(rootViewController: self.settingsViewController)
        
        self.rootTabBarController.viewControllers = [
            accountsListNavigationController,
            transactionsListNavigationController,
            settingsNavigationController
        ]
        
        // Add as child view controller
        self.addChildViewController(self.rootTabBarController)
        
        // Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(self.accountAddedNotification(_:)), name: Notifications.AccountAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.invalidCredentialsNotification(_:)), name: Notifications.InvalidCredentials, object: nil)
    }

    internal required init?(coder aDecoder: NSCoder)
    {
        abort()
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setUIDefaults()
        
        // Root tab bar controller
        self.view.addSubview(self.rootTabBarController.view)

        self.rootTabBarController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        // Sync
        syncManager.sync()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Presentation
    
    private func presentSplashScreen() {
        let splashScreenViewController = SplashScreenViewController()
        let navigationController = UINavigationController(rootViewController: splashScreenViewController)
        
        self.present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: UI Defaults
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if self.rootTabBarController.selectedIndex == 0 {
            return .lightContent
        }
        
        return .default
    }
    
    private func setUIDefaults()
    {
        UITabBar.appearance().barTintColor = UIColor.black
        UITabBar.appearance().tintColor = UIColor.white
    }
    
    // MARK: Notifications
    
    @objc private func accountAddedNotification(_ notification: Notification) {
        syncManager.sync()
    }
    
    @objc private func invalidCredentialsNotification(_ notification: Notification) {
        guard let institution = notification.object as? Institution else {
            return
        }
        
        let message = "We do not have the correct credentials for your account \"\(institution.displayName)\"."
        let alertController = UIAlertController(title: "Unauthorized", message: message, preferredStyle: .alert)
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Reauth action
        let reauthAction = UIAlertAction(title: "Update Credentials", style: .default) { (_) in
            switch institution.source {
            case .coinbase:
                self.dismiss(animated: true, completion: nil)
                CoinbaseApi.authenticate()
            default:
                let newCredentialBasedAccountViewController = AddCredentialBasedAccountViewController(source: institution.source)
                let navigationController = UINavigationController(rootViewController: newCredentialBasedAccountViewController)
                self.present(navigationController, animated: true, completion: nil)
            }
        }
        
        alertController.addAction(reauthAction)
        
        // Present
        self.present(alertController, animated: true, completion: nil)
    }
}
