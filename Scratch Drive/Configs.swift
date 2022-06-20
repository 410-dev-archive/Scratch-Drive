//
//  Configs.swift
//  Scratch Drive
//
//  Created by Hoyoun Song on 2022/06/20.
//

import Foundation
class Configs {
    static var CONFIG_PATH: String = "${USERDIR}.ramdiskconf"
    
    
//    Create an empty config file
    static func createConfig() -> Bool {
        return fs_writeFile(path: CONFIG_PATH, content: "!ScratchDrive Config File!")
    }
    
//    Check if config file exists
//    This does not create a config file
    static func isConfigReady() -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: CONFIG_PATH.replacingOccurrences(of: "${USERDIR}", with: getHomeDirectory()))
    }
    
    
//    Convert a text file to object array
//    This method will check if config file exists.
//    If not, it will create one.
    static func parseConfig() -> ([RamDisk], Bool) {
        
//        Check if config exists
        if !isConfigReady() {
            print("Config not ready!")
            let bool = createConfig() // If not, create one
            if !bool {
                return ([], false)
            }
        }
        
        print("Config ready!")
        
//        Split by lines
        let lines = fs_readFile(path: CONFIG_PATH).components(separatedBy: "\n")
        
//        Create an array with type of RamDisk
        var components: [RamDisk] = []
        
        
//        For each line,
        for line in lines {
            
//            Check if it is comment
            if line.starts(with: "!") {
                continue
            }
            
//            Create an object, then parse from the line
            let rd = RamDisk()
            let parseSuccess = rd.fromString(infoStr: line)
            if parseSuccess {
                components.append(rd)
            }
        }
        
        return (components, true)
    }
    
    
//    Add object to config
    static func addTemplate(rd: RamDisk) -> Bool {
        var rds = parseConfig().0
        
        for rdi in rds {
            if rdi.getName().elementsEqual(rd.getName()) {
                return false
            }
        }
        
        rds.append(rd)
        
        return saveConfig(configs: rds)
    }
    
    
//    Delete object from config
    static func deleteTemplate(name: String) -> Bool {
        var rds = parseConfig().0
        
        var index = 0
        for rd in rds {
            if rd.getName().elementsEqual(name) {
                rds.remove(at: index)
                index -= 1
            }
            index += 1
        }
        
        return saveConfig(configs: rds)
    }
    
    static func loadTemplate(name: String) -> RamDisk {
        
        let rds = parseConfig().0
        
        for rd in rds {
            if rd.getName().elementsEqual(name) {
                return rd
            }
        }
        
        return RamDisk()
    }
    
    static func saveConfig(configs: [RamDisk]) -> Bool {
        var str: String = ""
        
        for rd in configs {
            str += rd.toInfoString() + "\n"
        }
        print("content:\n\(str)")
        print("pth:\(CONFIG_PATH.replacingOccurrences(of: "${USERDIR}", with: getHomeDirectory()))")
        return fs_writeFile(path: CONFIG_PATH, content: str)
    }
    
    
    static func fs_readFile(path: String) -> String {
        do{
            let filepath = URL.init(fileURLWithPath: path.replacingOccurrences(of: "${USERDIR}", with: getHomeDirectory()))
            let content = try String(contentsOf: filepath, encoding: .utf8)
            return content
        }catch{
            exit(1)
        }
    }
    
    static func fs_writeFile(path: String, content: String) -> Bool {
        let file = path.replacingOccurrences(of: "${USERDIR}", with: getHomeDirectory())
        let fileUrl = URL(fileURLWithPath: file)
        
        if let data: Data = content.data(using: String.Encoding.utf8) { // String to Data
            do {
                try data.write(to: fileUrl)
                return true
            } catch let e {
                print(e.localizedDescription)
                return false
            }
        }
        
        return false

    }
    
    static func getHomeDirectory() -> String{
        let fsutil = FileManager.default
        var homeurl = fsutil.homeDirectoryForCurrentUser.absoluteString
        if homeurl.contains("file://"){
            homeurl = homeurl.replacingOccurrences(of: "file://", with: "")
        }
        return homeurl
    }
}
