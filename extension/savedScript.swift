//
//  savedScript.swift
//  extension
//
//  Created by Kristoffer Eriksson on 2020-10-31.
//

import UIKit

class savedScript: NSObject, Codable {
    
    var url : URL?
    var text: String?
    
    init(url: URL, text: String){
        self.url = url
        self.text = text
    }

}
