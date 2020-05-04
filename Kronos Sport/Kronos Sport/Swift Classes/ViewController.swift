//
//  ViewController.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import OAuthSwift

import UIKit
import SafariServices

class ViewController: OAuthViewController{
    // oauth swift object (retain)
    var oauthswift: OAuthSwift?
    
    lazy var internalWebViewController: WebViewController = {
        let controller = WebViewController()
        controller.view = UIView(frame: UIScreen.main.bounds) // needed if no nib or not loaded from storyboard
        controller.delegate = self
        controller.viewDidLoad() // allow WebViewController to use this ViewController as parent to be presented
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let _ = internalWebViewController.webView
        // init now web view handler
        doOAuthSpotify()
    }

    func doOAuthSpotify(){
        let oauthswift = OAuth2Swift(
            consumerKey:    "XXX",
            consumerSecret: "XXX",
            authorizeUrl:   "https://accounts.spotify.com/en/authorize",
            accessTokenUrl: "https://accounts.spotify.com/api/token",
            responseType:   "code"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        
        let _ = oauthswift.authorize(
            withCallbackURL: URL.callbackURL,
            scope: "user-library-modify",
            state: state) { result in
                print("OAuth returns...")
                switch result {
                case .success(let (credential, _, _)):
                    print("OK")
                    print("OK \(credential.oauthToken)") // or oauthswift.client.credential....
                    
                    // NOW YOU CAN DO REQUEST, using the token in your network api of your choise or use one provided
                    // oauthswift.client.get(url...) { result in ...
                    
                    
                case .failure(let error):
                    print("failure")
                    print(error.description)
                }
        }
    }

    func getURLHandler() -> OAuthSwiftURLHandlerType {
        if internalWebViewController.parent == nil {
            print(type(of: internalWebViewController))
            self.addChild(internalWebViewController)
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
        return internalWebViewController
    }

}

extension URL {
    var isCallbackURL: Bool {
        return self.scheme == "kronos" // could check also url.path == oauth-callback
    }
    static var callbackURL = URL(string: "kronos://oauth-callback/")! // MUST BE DECLARED ON SPOTIFY
}


extension ViewController: OAuthWebViewControllerDelegate {

    func oauthWebViewControllerDidPresent() {
        
    }
    func oauthWebViewControllerDidDismiss() {
        
    }
    
    func oauthWebViewControllerWillAppear() {
        
    }
    func oauthWebViewControllerDidAppear() {
        
    }
    func oauthWebViewControllerWillDisappear() {
        
    }
    func oauthWebViewControllerDidDisappear() {
        // Ensure all listeners are removed if presented web view close
        oauthswift?.cancel()
    }
}
