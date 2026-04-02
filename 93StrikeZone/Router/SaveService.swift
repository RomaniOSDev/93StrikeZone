//
//  SaveService.swift
//  97RaidAlert
//
//  Created by Xeova Nuoc on 28.02.2026.
//

import Foundation

struct SaveService {
    
    static var lastUrl: URL? {
        get { UserDefaults.standard.url(forKey: "LastUrl") }
        set { UserDefaults.standard.set(newValue, forKey: "LastUrl") }
    }
}
