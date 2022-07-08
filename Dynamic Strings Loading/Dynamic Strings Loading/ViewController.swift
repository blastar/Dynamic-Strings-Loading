//
//  ViewController.swift
//  Dynamic Strings Loading
//
//  Created by Krzysztof Deneka on 08/07/2022.
//

import UIKit

struct LangResource {
    let langEN: String
    let langES: String
    let langDE: String
}

class ViewController: UIViewController {
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    
    var currentBundle = Bundle.main
    
    static let bundleName = "LiveLocalizable.bundle"
    
    let manager = FileManager.default
    lazy var bundlePath: URL = {
        let documents = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
        let bundlePath = documents.appendingPathComponent(ViewController.bundleName, isDirectory: true)
        return bundlePath
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        update()
    }
    
    @IBAction func load1st(_ sender: Any) {
        let res = LangResource(langEN: "https://gist.github.com/blastar/eef4578ae60fcb2219a2c380e04f418c/raw/b0d0b95fefca36c9f14ff2901edba59af4608250/gistfile1.txt", langES: "https://gist.github.com/blastar/8e79f346fccb9277ab9476c7ae98ad65/raw/e0181ee9605573a8194fddc682e6ce16a741d7e1/gistfile1.txt", langDE: "https://gist.github.com/blastar/0f893b8a8e9ef478d3520ae8bfb2e38c/raw/c0a325672fcb76f5d17f41f68b85c554a346a259/gistfile1.txt")
        loadStrings(res)
    }
    
    func update() {
        print("currentBundle \(currentBundle)")

        label1.text = NSLocalizedString("label1", tableName: "", bundle: currentBundle, value: "", comment: "")
        label2.text = NSLocalizedString("label2", tableName: "", bundle: currentBundle, value: "", comment: "")
        label3.text = NSLocalizedString("label3", tableName: "", bundle: currentBundle, value: "", comment: "")
    }
    
    func setCurrentBundle(forLanguage: String) {
        do {
            currentBundle = try returnCurrentBundleForLanguage(lang: forLanguage)
        } catch {
            currentBundle = Bundle(path: getPathForLocalLanguage(language: "en"))!
        }
        print("currentBundle \(currentBundle)")
    }
    
    func getPathForLocalLanguage(language: String) -> String {
        return Bundle.main.path(forResource: language, ofType: "lproj")!
    }
    
    func returnCurrentBundleForLanguage(lang:String) throws -> Bundle {
        if manager.fileExists(atPath: bundlePath.path) == false {
            return Bundle(path: getPathForLocalLanguage(language: lang))!
        }
        do {
            let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
            _ = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let enumerator = FileManager.default.enumerator(at: bundlePath ,
                                                            includingPropertiesForKeys: resourceKeys,
                                                            options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                return true
            })!
            for case let folderURL as URL in enumerator {
                _ = try folderURL.resourceValues(forKeys: Set(resourceKeys))
                if folderURL.lastPathComponent == ("\(lang).lproj"){
                    let enumerator2 = FileManager.default.enumerator(at: folderURL,
                                                                     includingPropertiesForKeys: resourceKeys,
                                                                     options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                        return true
                    })!
                    for case let fileURL as URL in enumerator2 {
                        _ = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                        if fileURL.lastPathComponent == "Localizable.strings" {
                            return Bundle(url: folderURL)!
                        }
                    }
                }
            }
        } catch {
            return Bundle(path: getPathForLocalLanguage(language: lang))!
        }
        return Bundle(path: getPathForLocalLanguage(language: lang))!
    }
    
    func loadStrings(_ res: LangResource) {
        let taskEN = URLSession.shared.dataTask(with: URL(string: res.langEN)!) { [weak self] data, response, error in
            guard let dataResponse = data,
                  error == nil else {
                print(error?.localizedDescription ?? "Response Error")
                return
                
            }
            let textEN = String(decoding: dataResponse, as: UTF8.self)
  
            let taskES = URLSession.shared.dataTask(with: URL(string: res.langES)!) { [weak self] data, response, error in
                guard let dataResponse = data,
                      error == nil else {
                    print(error?.localizedDescription ?? "Response Error")
                    return
                    
                }
                let textES = String(decoding: dataResponse, as: UTF8.self)
      
                let taskDE = URLSession.shared.dataTask(with: URL(string: res.langDE)!) { [weak self] data, response, error in
                    guard let dataResponse = data,
                          error == nil else {
                        print(error?.localizedDescription ?? "Response Error")
                        return
                        
                    }
                    let textDE = String(decoding: dataResponse, as: UTF8.self)
          
                    try? self?.writeToBundle(en: textEN, es: textES, de: textDE)
                    
                    DispatchQueue.main.async { [weak self] in
                        let locale = NSLocale.current.languageCode
                        self?.setCurrentBundle(forLanguage: locale!)
                        self?.update()
                    }
                }
                
                taskDE.resume()
            }
            
            taskES.resume()
        }
        
        taskEN.resume()
        
    }
    
    func writeToBundle(en: String, es: String, de: String) throws -> Bundle {
        if manager.fileExists(atPath: bundlePath.path) == true {
            try manager.removeItem(atPath: bundlePath.path)
        }
        if manager.fileExists(atPath: bundlePath.path) == false {
            try manager.createDirectory(at: bundlePath, withIntermediateDirectories: true, attributes: [FileAttributeKey.protectionKey : FileProtectionType.complete])
        }
        
        let langPathEN = bundlePath.appendingPathComponent("en.lproj", isDirectory: true)
        if manager.fileExists(atPath: langPathEN.path) == false {
            try manager.createDirectory(at: langPathEN, withIntermediateDirectories: true, attributes: [FileAttributeKey.protectionKey : FileProtectionType.complete])
        }
        let filePathEN = langPathEN.appendingPathComponent("Localizable.strings")
        let dataEN = en.data(using: .utf32)
        manager.createFile(atPath: filePathEN.path, contents: dataEN, attributes: [FileAttributeKey.protectionKey : FileProtectionType.complete])
        
        let langPathES = bundlePath.appendingPathComponent("es.lproj", isDirectory: true)
        if manager.fileExists(atPath: langPathES.path) == false {
            try manager.createDirectory(at: langPathES, withIntermediateDirectories: true, attributes: [FileAttributeKey.protectionKey : FileProtectionType.complete])
        }
        let filePathES = langPathES.appendingPathComponent("Localizable.strings")
        let dataES = es.data(using: .utf32)
        manager.createFile(atPath: filePathES.path, contents: dataES, attributes: [FileAttributeKey.protectionKey : FileProtectionType.complete])
        
        let langPathDE = bundlePath.appendingPathComponent("de.lproj", isDirectory: true)
        if manager.fileExists(atPath: langPathDE.path) == false {
            try manager.createDirectory(at: langPathDE, withIntermediateDirectories: true, attributes: [FileAttributeKey.protectionKey : FileProtectionType.complete])
        }
        let filePathDE = langPathDE.appendingPathComponent("Localizable.strings")
        let dataDE = de.data(using: .utf32)
        manager.createFile(atPath: filePathDE.path, contents: dataDE, attributes: [FileAttributeKey.protectionKey : FileProtectionType.complete])

        
        let localBundle = Bundle(url: bundlePath)!
        return localBundle
    }
}

