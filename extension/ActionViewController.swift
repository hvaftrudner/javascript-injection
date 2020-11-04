//
//  ActionViewController.swift
//  extension
//
//  Created by Kristoffer Eriksson on 2020-10-26.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {

    @IBOutlet var script: UITextView!
   
    var pageTitle = ""
    var pageURL = ""
    
    var scripts = ["alert": "alert(document.title);", "alert name": "alert(1234);"]
    var saved = [savedScript]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(loadScripts))
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        // load last script typed
        let defaults = UserDefaults.standard
        if let savedScripts = defaults.object(forKey: "saved") as? Data {
            let jsonDecoder = JSONDecoder()
            do {
                saved = try jsonDecoder.decode([savedScript].self, from: savedScripts)
                print("loaded script")
            } catch {
                print("failed to load saved scripts")
            }
        }
            
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) {
                    [weak self] (dict, error) in
                    guard let itemDictionary = dict as? NSDictionary else { return }
                    guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else {return}
                    //print(javaScriptValues)
                    self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["URL"] as? String ?? ""
                    
                    DispatchQueue.main.async {
                        self?.title = self?.pageTitle
                        self?.script.text = self?.saved[0].text
                    }
                    
                }
            }
        }
        

    }
    
    @objc func loadScripts(){
        let ac = UIAlertController(title: "Load Scripts", message: "load scripts", preferredStyle: .alert)
        for i in scripts{
            ac.addAction(UIAlertAction(title: i.key, style: .default) {_ in
                
                self.script.text = i.value
            })
        }
        
        present(ac, animated: true)
    }
    
    @objc func save(){
        let jsonEncoder = JSONEncoder()
        
        if let savedData = try? jsonEncoder.encode(saved){
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "saved")
            print("its saved")
        } else{
            print("could not save data")
        }
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        let item = NSExtensionItem()
        let argument: NSDictionary = ["customJavaScript": script.text!]
        let webDictionary : NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
        item.attachments = [customJavaScript]
        extensionContext?.completeRequest(returningItems: [item])
        
        // saveing typed script before running it
        guard let url = URL(string: pageURL ) else {return}
        guard let text = script.text else {return}
        
        let scriptSave = savedScript(url: url , text: text)
        saved.append(scriptSave)
        save()
    }
    
    @objc func adjustForKeyboard(notification: Notification){
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        script.scrollIndicatorInsets = script.contentInset
        
        let selectedRange = script.selectedRange
        script.scrollRangeToVisible(selectedRange)
    }
}
