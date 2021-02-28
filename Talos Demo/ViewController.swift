//
//  ViewController.swift
//  Talos Demo
//
//  Created by Dr. Alberto Rodriguez on 2/20/21.
//

import Cocoa
import PythonKit      // From TensorFlow Team.
import WebKit

//PythonLibrary.useVersion(3,8)

class ViewController: NSViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet var backView: NSView!
    @IBOutlet weak var openEDFPushButton: NSButton!
    @IBOutlet weak var edfLocationTextField: NSTextField!
    @IBOutlet weak var talosLocationTextField: NSTextField!
    @IBOutlet weak var talosExecutableButton: NSButton!
    var files: [URL] = []      // List of files from Folder
    var url: URL!
    var folderMonitor: FolderMonitor!
    var currentPath: String!
    private var monitoringFlag = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PythonLibrary.useVersion(3,9)
        print("From XCode: ", Python.version)
       
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    //MARK - FolderMonitor Helper Functions
    func handleChanges() {
        let files = (try? FileManager.default.contentsOfDirectory(at: self.url, includingPropertiesForKeys: nil, options: .producesRelativePathURLs)) ?? []
        DispatchQueue.main.async {
            self.files = files
            self.checkForHTMLfileAndDisplay(files: self.files)
        }
    }
    
    func checkForHTMLfileAndDisplay(files:[URL]){
        for file in files{
            //print("Here is file", file.lastPathComponent)
            if( file.lastPathComponent.contains("html")){
                //print("We should open file ", file.lastPathComponent)
                if( self.currentPath != nil && self.monitoringFlag){
                    print("We are trying to open......", self.currentPath + file.lastPathComponent)
                    let url = NSURL.fileURL(withPath: self.currentPath + file.lastPathComponent)
                    self.webView.loadFileURL(url, allowingReadAccessTo: url)
                    self.folderMonitor.stopMonitoring()
                    self.monitoringFlag = false
                }
            }
        }
    }

    //MARK - Actions
    //EEG Files
    @IBAction func openEDFPushButtonAction(_ sender: Any) {
        let dialog = NSOpenPanel();                                        // Open a dialog
        dialog.title                   = "Choose an .edf file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["edf"];
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
                
                if (result != nil) {
                    let pathWFilename = result!.path                        // File + Path from FileSystem
                    self.edfLocationTextField.stringValue = pathWFilename   // Show File + Path to user
                    DispatchQueue.main.async{
                        self.monitoringFlag = true
                        self.currentPath = self.returnPath(str: pathWFilename)               // Extract Path
                        self.url = URL(fileURLWithPath: self.currentPath)                    // Make it into a URL for monitoring
                        self.folderMonitor = FolderMonitor(url: self.url)                    // Create Object of FolderMonitor Type.
                        self.folderMonitor.folderDidChange = { [weak self] in self?.handleChanges()}
                        self.folderMonitor.startMonitoring()                    // Start Monitoring
                        self.handleChanges()                                    // Handle the callbacks from the OS
                    }
                                                       
                }
        } else {
                return
        }
    }
 
    
    @IBAction func findTalosButtonAction(_ sender: Any) {
        let dialog = NSOpenPanel();
        dialog.title                   = "Choose a .py file containing Talos";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["py"];
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
                if (result != nil) {
                    let path = result!.path
                    self.talosLocationTextField.stringValue = path
                }
        } else {
                return
        }
    }
    
    
    @IBAction func executeTalosPushButton(_ sender: Any) {
        if(self.talosLocationTextField.stringValue.isEmpty || self.edfLocationTextField.stringValue.isEmpty){
            print("Warning: Make sure to complete your selection...")
        }
        else{
            self.runPythonCode()
           
            
        }
    }
    
    //MARK-User Defined Functions
    func runPythonCode(){
        let sys = Python.import("sys")                                             // Used to execute System commands
        // When executing from a secondary python script you will need
        let str = self.talosLocationTextField.stringValue                          // Path + File (Extract Path)
        let talosFilePath = self.returnPath(str: str)                              // Helper Methods
        let talosPythonNameWithExtension = self.returNameWithExtension(str: str)
        let components = talosPythonNameWithExtension.components(separatedBy: ".")
        sys.path.append(String(talosFilePath))
        let example = Python.import(components[0])   // Filename without extension
        let response = example.run(String(talosFilePath) + "TalosDemoNoRun.py")       //
        //let response = example.run()
        print(response)                              // This is the response from Python... Get ready to load HTML file
    }
    
    //MARK - Helper functions
    func returnPath(str: String)->String{
        let lastIndex = str.lastIndex(of: "/")
        let offsetIndex = str.index(lastIndex!, offsetBy: 1)
        let filePath = str[str.startIndex..<offsetIndex]
        return(String(filePath))
    }
    
    func returNameWithExtension(str: String)->String{
        let lastIndex = str.lastIndex(of: "/")
        let offsetIndex = str.index(lastIndex!, offsetBy: 1)
        let fileWithExtension = str[offsetIndex...]       //lastIndex!..<str.endIndex]
        return(String(fileWithExtension))
    }
}

