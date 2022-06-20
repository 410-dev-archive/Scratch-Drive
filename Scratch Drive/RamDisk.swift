//
//  RamDisk.swift
//  Scratch Drive
//
//  Created by Hoyoun Song on 2022/06/20.
//

import Foundation
class RamDisk {
    
    var name: String = ""
    var megabytes: Int = 0
    
    
    
    func getBlockSize() -> Int {
        return megabytes * 2048
    }
    
    func getName() -> String {
        return name
    }
    
    func setMegabytes(mb: Int) {
        megabytes = mb
    }
    
    func setGigabytes(gb: Int) {
        megabytes = gb * 1024
    }
    
    func setName(name: String) {
        self.name = name
    }
    
    func toInfoString() -> String {
        return "\(name):\((megabytes))"
    }
    
    func fromString(infoStr: String) -> Bool {
        if !infoStr.contains(":") {
            return false
        }
        let info = infoStr.components(separatedBy: ":")
        name = info[0]
        megabytes = Int(info[1]) ?? 1
        return true
    }
    
    func isMounted() -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: "/Volumes/\(name)")
    }
    
}
