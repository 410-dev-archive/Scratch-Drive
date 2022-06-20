//
//  ViewController.swift
//  Scratch Drive
//
//  Created by Hoyoun Song on 2022/06/20.
//

import Cocoa

class ViewController: NSViewController {
    
    
    @IBOutlet weak var DriveName: NSTextField!
    @IBOutlet weak var SizeSlider: NSSlider!
    @IBOutlet weak var SizeNumField: NSTextField!
    
    @IBOutlet weak var CreateButton: NSButton!
    @IBOutlet weak var DismountButton: NSButton!
    @IBOutlet weak var SaveTemplateButton: NSButton!
    @IBOutlet weak var DeleteTemplateButton: NSButton!
    
    @IBOutlet weak var TemplateListCombo: NSComboBox!
    
    var currentDrive = RamDisk()
    
    var templates: [RamDisk] = []
    
    func updateTemplates() {
        let parse = Configs.parseConfig()
        if parse.1 {
            templates = parse.0
        }else{
            errorMessage(title: "Error", contents: "Failed to create / load configuration file.")
            exit(9)
        }
        
        TemplateListCombo.removeAllItems()
        TemplateListCombo.stringValue = ""
        
        for template in templates {
            TemplateListCombo.addItem(withObjectValue: "\(template.getName()) (\(template.megabytes)MB)")
        }
        
        if templates.count > 0 {
            TemplateListCombo.stringValue = "\(templates[0].getName()) (\(templates[0].megabytes)MB)"
            OnSelectTemplate("")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        updateTemplates()
        
        CreateButton.isEnabled = false
        DismountButton.isEnabled = false
        SaveTemplateButton.isEnabled = false
        DeleteTemplateButton.isEnabled = false
        
        checkValidity()
        
        SizeSlider.minValue = 64
        SizeSlider.maxValue = Double(getAvailableRamSizeInMB())
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    @IBAction func OnCreate(_ sender: Any) {
        if !checkInputValid() {
            errorMessage(title: "Invalid Input", contents: "Please fill both drive name and size.")
            return
        }
        
        DismountButton.isEnabled = false
        CreateButton.isEnabled = false
        SizeSlider.isEnabled = false
        DriveName.isEnabled = false
        SizeNumField.isEnabled = false
        checkValidity()
        createNewRamDisk(name: DriveName.stringValue, megabytes: Int(SizeNumField.stringValue) ?? 0)
    }
    
    @IBAction func OnDismount(_ sender: Any) {
        if !checkInputValid() {
            errorMessage(title: "Invalid Input", contents: "Please fill both drive name and size.")
            return
        }
        let exitCode = sh("bash", "-c", "diskutil eject '\(currentDrive.getName())'")
        if exitCode == 0 || !currentDrive.isMounted() {
            DismountButton.isEnabled = false
            CreateButton.isEnabled = true
            SizeSlider.isEnabled = true
            DriveName.isEnabled = true
            SizeNumField.isEnabled = true
        }else{
            errorMessage(title: "Error", contents: "Unable to dismount scratch drive.")
        }
       
    }
    
    @IBAction func OnSaveTemplate(_ sender: Any) {
        if !checkInputValid() {
            errorMessage(title: "Invalid Input", contents: "Please fill both drive name and size.")
            return
        }
        currentDrive.setName(name: DriveName.stringValue)
        currentDrive.setMegabytes(mb: Int(SizeNumField.stringValue) ?? 0)
        let result = Configs.addTemplate(rd: currentDrive)
        if !result {
            errorMessage(title: "Error", contents: "Failed to save template")
        }
        updateTemplates()
    }
    
    @IBAction func OnDeleteTemplate(_ sender: Any) {
        if !checkInputValid() {
            errorMessage(title: "Invalid Input", contents: "Please fill both drive name and size.")
            return
        }
        let result = Configs.deleteTemplate(name: currentDrive.getName())
        if !result {
            errorMessage(title: "Error", contents: "Failed to save template")
        }
        updateTemplates()
    }
    
    @IBAction func OnSelectTemplate(_ sender: Any) {
        let params = TemplateListCombo.stringValue.components(separatedBy: " (")
        var name: String = ""
        
        var index: Int = 0
        for param in params {
            if index < params.count - 1 {
                name += param
            }
            if index < params.count - 2 {
                name += " "
            }
            index += 1
        }
        
        currentDrive = Configs.loadTemplate(name: name)
        DriveName.stringValue = currentDrive.getName()
        SizeSlider.integerValue = currentDrive.megabytes
        SizeNumField.stringValue = String(currentDrive.megabytes)
        
        checkValidity()
    }
    
    @IBAction func OnHelp(_ sender: Any) {
        popupMessage(title: "Scratch Drive Manual", contents: "Scratch Drive is a tool to make a ramdisk for macOS. A ramdisk is a virtual disk that is running on the memory, which is volatile (Data will be removed once computer shuts down) but is faster than the traditional storages.\n\nYou can dynamically set the size of the scratch drive by sliding the slider or manually setting the number of megabytes. You may only set to 80% of the physical RAM size for the system stability. It is highly not recommended to quit or close the app since the mount info is not preserved after the application is closed, which will lead to unsafe eject of ramdisk.")
    }
    
    @IBAction func OnSlideUpdate(_ sender: Any) {
        SizeNumField.stringValue = String(SizeSlider.integerValue)
        checkValidity()
    }
    
    @IBAction func OnSetDriveName(_ sender: Any) {
        checkValidity()
    }
    
    @IBAction func OnSetDriveSize(_ sender: Any) {
        SizeSlider.integerValue = Int(SizeNumField.integerValue)
        checkValidity()
    }
    
    public func checkInputValid() -> Bool {
        return DriveName.stringValue.count > 0 && SizeNumField.stringValue.count > 0
    }
    
    @discardableResult
    public func errorMessage(title: String, contents: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = contents
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Dismiss")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    @discardableResult
    public func popupMessage(title: String, contents: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = contents
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Dismiss")
        return alert.runModal() == .alertFirstButtonReturn
    }

    
    func checkValidity() {
        let size = SizeSlider.integerValue
        let size2 = SizeNumField.integerValue
        
        if size < 64 || size2 < 64 {
            SizeSlider.integerValue = 64
            SizeNumField.stringValue = "64"
        }
        
        else if size > getAvailableRamSizeInMB() || size2 > getAvailableRamSizeInMB() {
            SizeSlider.integerValue = getAvailableRamSizeInMB()
            SizeNumField.stringValue = String(getAvailableRamSizeInMB())
        }
        
        if SizeNumField.stringValue.count == 0 {
            SizeNumField.stringValue = "64"
            SizeSlider.integerValue = 64
        }
            
        if DriveName.stringValue.count > 0 && SizeNumField.stringValue.count > 0 {
            CreateButton.isEnabled = true
            SaveTemplateButton.isEnabled = true
        }
        
        if DriveName.stringValue.count > 0 {
            DeleteTemplateButton.isEnabled = true
        }
    }
    
    
    func createNewRamDisk(name: String, megabytes: Int) {
        
        currentDrive.setMegabytes(mb: megabytes)
        currentDrive.setName(name: name)
        
        if currentDrive.isMounted() {
            errorMessage(title: "Disk Already Mounted", contents: "One of external, internal, ramdisk with the same name is already mounted. Please try again with different name.")
            return
        }else{
            let exitCode = sh("bash", "-c", "diskutil erasevolume HFS+ '\(currentDrive.getName())' $(hdiutil attach -nobrowse -nomount ram://\(currentDrive.getBlockSize()))")
            
            if exitCode == 0 {
                DismountButton.isEnabled = true
                CreateButton.isEnabled = false
                SizeSlider.isEnabled = false
                DriveName.isEnabled = false
                SizeNumField.isEnabled = false
            }else{
                errorMessage(title: "Error", contents: "Failed to create scratch drive.")
            }
            
        }
    }
    
    @discardableResult
    public func sh(_ args: String...) -> Int32 {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
    
    func getRamSizeInMB() -> Int {
        return Int(ProcessInfo().physicalMemory / 1024 / 1024)
    }

    func getRamSizeInGB() -> Int {
        return getRamSizeInMB() / 1024
    }
    
    func getAvailableRamSizeInMB() -> Int {
        return Int(round(Double(getRamSizeInMB()) * 0.8))
    }
    
    func getAvailableRamSizeInGB() -> Int {
        return Int(round(Double(getRamSizeInGB()) * 0.8))
    }
}

