//
//  AppDelegate.swift
//  Example
//
//  Created by Nacho Soto on 11/30/18.
//  Copyright © 2018 Nacho Soto. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let images = ImagesViewController(fetcher: ImageFetcher())
        let navigationController = UINavigationController(rootViewController: images)
        
        self.window = UIWindow()
        self.window!.rootViewController = navigationController
        self.window!.makeKeyAndVisible()
        
        self.configureEvents(imagesViewController: images,
                             navigationController:  navigationController)
        
        return true
    }
    
    private func configureEvents(
        imagesViewController: ImagesViewController,
        navigationController: UINavigationController
    ) {
        imagesViewController.openImageRequests
            .map(FullScreenImageViewController.init)
            .observeValues { navigationController.pushViewController($0, animated: true) }
    }
}
