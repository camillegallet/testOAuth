//
//  ViewController.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import OAuthSwift

#if os(iOS)
import UIKit
import SafariServices
#elseif os(OSX)
import AppKit
#endif

class ViewController: OAuthViewController{
    // oauth swift object (retain)
    var oauthswift: OAuthSwift?
    
    var currentParameters = [String: String]()
    let formData = Semaphore<FormViewControllerData>()
    
    lazy var internalWebViewController: WebViewController = {
        let controller = WebViewController()
        #if os(OSX)
        controller.view = NSView(frame: NSRect(x:0, y:0, width: 450, height: 500)) // needed if no nib or not loaded from storyboard
        #elseif os(iOS)
        controller.view = UIView(frame: UIScreen.main.bounds) // needed if no nib or not loaded from storyboard
        #endif
        controller.delegate = self
        controller.viewDidLoad() // allow WebViewController to use this ViewController as parent to be presented
        return controller
    }()
    
}

extension ViewController: OAuthWebViewControllerDelegate {
    #if os(iOS) || os(tvOS)
    
    func oauthWebViewControllerDidPresent() {
        
    }
    func oauthWebViewControllerDidDismiss() {
        
    }
    #endif
    
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

extension ViewController {
    
    // MARK: - do authentification
    func doAuthService(service: String) {

    }
    
    func doOAuthTest(_ serviceParameters: [String:String]){
        print(serviceParameters)
        let oauthswift = OAuth2Swift(
            consumerKey:    "YbCkiZe3-uAKj-XeugzG1WTu",
            consumerSecret: "_P68mzofmEDhNZHu7LXFGUJWAXcML98VYSuVRv29NFUSAa01",
            authorizeUrl:   "https://authorization-server.com/authorize",
            responseType:   "code"
        )

        self.oauthswift = oauthswift
        oauthswift.encodeCallbackURL = true
        oauthswift.encodeCallbackURLQuery = false
        oauthswift.authorizeURLHandler = getURLHandler()
        
        let redirectURL = "https://www.oauth.com/playground/authorization-code.html"
        
        let state = "ej5m6zmYn5GAPiXM"
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: redirectURL)!,scope: "photo+offline_access", state:state) { result in
            switch result {
            case .success(let (credential, _, _)):
                print("succes")
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                print(oauthswift.client.credential.oauthToken)
                oauthswift.client.get("http://mobi.kronos-sport.com") { result in
                    switch result {
                    case .success(let response):
                        let dataString = response.string
                        print(dataString)
                    case .failure(let error):
                        print(error)
                    }
                }
            case .failure(let error):
                print("failure")
                print(error.description)
            }
        }
    }
    
    
    // MARK: Spotify
    func doOAuthSpotify(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://accounts.spotify.com/en/authorize",
            accessTokenUrl: "https://accounts.spotify.com/api/token",
            responseType:   "code"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        
        let _ = oauthswift.authorize(
            withCallbackURL: URL(string: "kronos://oauth-callback/spotify")!,
            scope: "user-library-modify",
            state: state) { result in
                print("OAuth returns...")
                switch result {
                case .success(let (credential, _, _)):
                    print("OK")
                    self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                case .failure(let error):
                    print("failure")
                    print(error.description)
                }
        }
    }
    
    // MARK: Imgur
    func doOAuthImgur(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://api.imgur.com/oauth2/authorize",
            accessTokenUrl: "https://api.imgur.com/oauth2/token",
            responseType:   "token"
        )
        self.oauthswift = oauthswift
        oauthswift.encodeCallbackURL = true
        oauthswift.encodeCallbackURLQuery = false
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        
        let _ = oauthswift.authorize(
            withCallbackURL: URL(string: "kronos://oauth-callback/imgur")!,
            scope: "",
            state: state) { result in
                switch result {
                case .success(let (credential, _, _)):
                    self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                case .failure(let error):
                    print(error.description)
                }
        }
    }
    
}

let services = Services()
let DocumentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
let FileManager: FileManager = Foundation.FileManager.default

extension ViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load config from files
        initConf()
        
        let _ = internalWebViewController.webView
        // init now web view handler
        let param = ["consumerSecret": "1448b6616f2947919657805f8e8e46c2", "name": "Spotify", "consumerKey": "6bc86e063ab9416b86d8e17a4b3d2727"]
        doOAuthSpotify(param)
        //doAuthService(service:"Kronos")
    }
    
    // MARK: utility methods
    
    var confPath: String {
        let appPath = "\(DocumentDirectory)/.oauth/"
        if !FileManager.fileExists(atPath: appPath) {
            do {
                try FileManager.createDirectory(atPath: appPath, withIntermediateDirectories: false, attributes: nil)
            }catch {
                print("Failed to create \(appPath)")
            }
        }
        return "\(appPath)Services.plist"
    }
    
    func initConf() {
        initConfOld()
        print("Load configuration from \n\(self.confPath)")
        
        // Load config from model file
        if let path = Bundle.main.path(forResource: "Services", ofType: "plist") {
            services.loadFromFile(path)
            
            if !FileManager.fileExists(atPath: confPath) {
                do {
                    try FileManager.copyItem(atPath: path, toPath: confPath)
                }catch {
                    print("Failed to copy empty conf to\(confPath)")
                }
            }
        }
        services.loadFromFile(confPath)
    }
    
    func initConfOld() { // TODO Must be removed later
        services["Kronos"] = Kronos
        services["Twitter"] = Twitter
        services["Salesforce"] = Salesforce
        services["Flickr"] = Flickr
        services["Github"] = Github
        services["Instagram"] = Instagram
        services["Foursquare"] = Foursquare
        services["Fitbit"] = Fitbit
        services["Withings"] = Withings
        services["Linkedin"] = Linkedin
        services["Linkedin2"] = Linkedin2
        services["Dropbox"] = Dropbox
        services["Dribbble"] = Dribbble
        services["BitBucket"] = BitBucket
        services["GoogleDrive"] = GoogleDrive
        services["Smugmug "] =  Smugmug
        services["Intuit"] = Intuit
        services["Zaim"] = Zaim
        services["Tumblr"] = Tumblr
        services["Slack"] = Slack
        services["Uber"] = Uber
        services["Digu"] = Digu
    }
    
    func snapshot() -> Data {
        #if os(iOS)
        UIGraphicsBeginImageContext(self.view.frame.size)
        self.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let fullScreenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        UIImageWriteToSavedPhotosAlbum(fullScreenshot!, nil, nil, nil)
        return fullScreenshot!.jpegData(compressionQuality: 0.5)!
        #elseif os(OSX)
        let rep: NSBitmapImageRep = self.view.bitmapImageRepForCachingDisplay(in: self.view.bounds)!
        self.view.cacheDisplay(in: self.view.bounds, to:rep)
        return rep.tiffRepresentation!
        #endif
    }
    
    func showAlertView(title: String, message: String) {
        #if os(iOS)
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        #elseif os(OSX)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "Close")
        alert.runModal()
        #endif
    }
    
    func showTokenAlert(name: String?, credential: OAuthSwiftCredential) {
        var message = "oauth_token:\(credential.oauthToken)"
        if !credential.oauthTokenSecret.isEmpty {
            message += "\n\noauth_token_secret:\(credential.oauthTokenSecret)"
        }
        self.showAlertView(title: name ?? "Service", message: message)
        
        if let service = name {
            services.updateService(service, dico: ["authentified":"1"])
            // TODO refresh graphic
        }
    }
    
    // MARK: handler
    
    func getURLHandler() -> OAuthSwiftURLHandlerType {
            if internalWebViewController.parent == nil {
                print(type(of: internalWebViewController))
                self.addChild(internalWebViewController)
                navigationController?.setNavigationBarHidden(true, animated: false)
            }
            return internalWebViewController
    }
    //(I)
    //let webViewController: WebViewController = internalWebViewController
    //(S)
    //var urlForWebView:?URL = nil
    
    
    override func prepare(for segue: OAuthStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboards.Main.formSegue {
            #if os(OSX)
            let controller = segue.destinationController as? FormViewController
            #else
            let controller = segue.destination as? FormViewController
            #endif
            // Fill the controller
            if let controller = controller {
                controller.delegate = self
            }
        }
        
        super.prepare(for: segue, sender: sender)
    }
    
}

public typealias Queue = DispatchQueue
// MARK: - Table

#if os(iOS)
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.keys.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "Cell")
        let service = services.keys[indexPath.row]
        cell.textLabel?.text = service
        
        if let parameters = services[service] , Services.parametersEmpty(parameters) {
            cell.textLabel?.textColor = UIColor.red
        }
        if let parameters = services[service], let authentified = parameters["authentified"], authentified == "1" {
            cell.textLabel?.textColor = UIColor.green
        }
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let service: String = services.keys[indexPath.row]
        
        DispatchQueue.global(qos: .background).async {
            self.doAuthService(service: service)
        }
        tableView.deselectRow(at: indexPath, animated:true)
    }
}
#elseif os(OSX)
extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    // MARK: NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return services.keys.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return services.keys[row]
    }
    
    // MARK: NSTableViewDelegate
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        let service = services.keys[row]
        if let parameters = services[service], Services.parametersEmpty(parameters) {
            rowView.backgroundColor = NSColor.red
        }
        if let parameters = services[service], let authentified = parameters["authentified"], authentified == "1" {
            rowView.backgroundColor  = NSColor.green
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView {
            let row = tableView.selectedRow
            if  row != -1 {
                let service: String = services.keys[row]
                
                
                DispatchQueue.global(qos: .background).async {
                    self.doAuthService(service: service)
                }
                tableView.deselectRow(row)
            }
        }
    }
}
#endif

#if os(iOS)
import SafariServices
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
@available(iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
extension ViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.topWindow ?? ASPresentationAnchor()
    }
}
#endif

struct FormViewControllerData {
    var key: String
    var secret: String
    var handlerType: URLHandlerType
}

extension ViewController: FormViewControllerDelegate {
    
    var key: String? { return self.currentParameters["consumerKey"] }
    var secret: String? {return self.currentParameters["consumerSecret"] }
    
    func didValidate(key: String?, secret: String?, handlerType: URLHandlerType) {
        self.dismissForm()
        
        self.formData.publish(data: FormViewControllerData(key: key ?? "", secret: secret ?? "", handlerType: handlerType))
    }
    
    func didCancel() {
        self.dismissForm()
        
        self.formData.cancel()
    }
    
    func dismissForm() {
        #if os(iOS)
        /*self.dismissViewControllerAnimated(true) { // without animation controller
         print("form dismissed")
         }*/
        let _ = self.navigationController?.popViewController(animated: true)
        #endif
    }
}

// Little utility class to wait on data
class Semaphore<T> {
    let segueSemaphore = DispatchSemaphore(value: 0)
    var data: T?
    
    func waitData(timeout: DispatchTime? = nil) -> T? {
        if let timeout = timeout {
            let _ = segueSemaphore.wait(timeout: timeout) // wait user
        } else {
            segueSemaphore.wait()
        }
        return data
    }
    
    func publish(data: T) {
        self.data = data
        segueSemaphore.signal()
    }
    
    func cancel() {
        segueSemaphore.signal()
    }
}
