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
    
    @IBOutlet weak var TemplateListCombo: NSComboButton!
    
    var currentDrive = RamDisk()

    override func viewDidLoad() {
        super.viewDidLoad()

        SaveTemplateButton.isEnabled = false
        DeleteTemplateButton.isEnabled = false
        CreateButton.isEnabled = false
        DismountButton.isEnabled = false
        
        TemplateListCombo.isHidden = true
        SaveTemplateButton.isHidden = true
        DeleteTemplateButton.isHidden = true
        
        SizeSlider.minValue = 64
        SizeSlider.maxValue = Double(getAvailableRamSizeInMB())
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    @IBAction func OnCreate(_ sender: Any) {
        DismountButton.isEnabled = false
        CreateButton.isEnabled = false
        SizeSlider.isEnabled = false
        DriveName.isEnabled = false
        SizeNumField.isEnabled = false
        checkValidity()
        createNewRamDisk(name: DriveName.stringValue, megabytes: Int(SizeNumField.stringValue) ?? 0)
    }
    
    @IBAction func OnDismount(_ sender: Any) {
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
    }
    
    @IBAction func OnDeleteTemplate(_ sender: Any) {
    }
    
    @IBAction func OnSelectTemplate(_ sender: Any) {
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
    
    @IBAction func OnSetDriveSizeUnit(_ sender: Any) {
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
//            SaveTemplateButton.isEnabled = true
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

