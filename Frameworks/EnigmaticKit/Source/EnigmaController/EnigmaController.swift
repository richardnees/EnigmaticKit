import Cocoa
import EnigmaticCore

public class EnigmaController: NSObject {
    var passwordWindowController = PasswordWindowController.makeWindowController()
    public weak var sourceWindow: NSWindow?
    
    public var queue = EnigmaController.defaultQueue
    
    public var decryptedData: Data?
    public var encryptedData: Data?
    
    public var transform: Enigma.Transform = .encrypt
    
    public var displayMode: EnigmaController.DisplayMode = .regular
    public var displaysDescription: Bool = false
    
    public var keychainAccount: String?
    public var allowsKeychainAccess: Bool = false
    public var shouldAddToKeychain: Bool = false
    public var autoDecryptUsingKeychain: Bool = false

    public static var defaultQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .background
        return queue
    }()
    
    public func runModal() -> NSApplication.ModalResponse {
        
        if autoDecryptUsingKeychain == true,
            decryptUsingKeychain() == .OK {
            return .OK
        }

        passwordWindowController = PasswordPanelController.makePanelController()
        passwordWindowController.passwordViewController?.delegate = self
        guard let passwordWindow = passwordWindowController.window as? PasswordPanel else {
            return .abort
        }

        passwordWindow.level = .statusBar
        
        switch displayMode {
        case .regular:
            passwordWindow.appearance = NSAppearance(named: .aqua)
            passwordWindow.styleMask = [.titled, .nonactivatingPanel]
        case .HUD:
            passwordWindow.appearance = NSAppearance(named: .vibrantDark)
            passwordWindow.styleMask = [.titled, .utilityWindow, .nonactivatingPanel, .hudWindow]
        }
        
        NSApp.activate(ignoringOtherApps: true)
        return NSApp.runModal(for: passwordWindow)
    }
    
    public func beginSheetModal(completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil) {
        
        if autoDecryptUsingKeychain == true,
            decryptUsingKeychain() == .OK {
            handler?(.OK)
            return
        }

        passwordWindowController = PasswordSheetController.makeSheetController()
        passwordWindowController.passwordViewController?.delegate = self
        guard let passwordWindow = passwordWindowController.window as? PasswordSheet else {
            handler?(.abort)
            return
        }

        guard let sourceWindow = sourceWindow else {
            handler?(.abort)
            return
        }

        passwordWindow.appearance = NSAppearance(named: .aqua)
        passwordWindow.styleMask = [.borderless, .titled, .nonactivatingPanel]
        
        sourceWindow.beginSheet(passwordWindow) { response in
            handler?(response)
        }
    }
    
    func decryptUsingKeychain() -> NSApplication.ModalResponse {
        if
            transform == .decrypt,
            let encryptedData = encryptedData,
            let password = autofillPassword {
            let decryptDataTransform = EnigmaDataTransformOperation(transform: .decrypt, password: password)
            decryptDataTransform.inputData = encryptedData
            queue.addOperation(decryptDataTransform)
            queue.waitUntilAllOperationsAreFinished()
            
            guard let data = decryptDataTransform.outputData else {
                if let error = decryptDataTransform.error {
                    present(error: error)
                }
                return .continue
            }
            
            decryptedData = data
            
            return .OK
        }
        
        return .continue
    }
    
    func decrypt(with password: String, completion: @escaping (Bool) -> Void) {
        guard let encryptedData = encryptedData else {
            present(error: EnigmaError.noData)
            completion(false)
            return
        }
        
        let decryptDataTransform = EnigmaDataTransformOperation(transform: .decrypt, password: password)
        decryptDataTransform.inputData = encryptedData
        queue.addOperation(decryptDataTransform)
        queue.waitUntilAllOperationsAreFinished()

        guard let data = decryptDataTransform.outputData else {
            if let error = decryptDataTransform.error {
                present(error: error)
            }
            completion(false)
            return
        }
        
        decryptedData = data

        if self.shouldAddToKeychain {
            let keychainSaveOperation = EnigmaKeychainSavePasswordOperation()
            keychainSaveOperation.account = keychainAccount
            keychainSaveOperation.password = password
            keychainSaveOperation.data = encryptedData
            queue.addOperation(keychainSaveOperation)
            queue.waitUntilAllOperationsAreFinished()
        }
        
        self.finishSession(with: .OK)
        completion(true)
    }
    
    func encrypt(with password: String, completion: @escaping (Bool) -> Void) {
        guard let decryptedData = decryptedData else {
            present(error: EnigmaError.noContent)
            completion(false)
            return
        }

        let encryptDataTransform = EnigmaDataTransformOperation(transform: .encrypt, password: password)
        encryptDataTransform.inputData = decryptedData
        queue.addOperation(encryptDataTransform)
        queue.waitUntilAllOperationsAreFinished()
        
        guard let data = encryptDataTransform.outputData else {
            if let error = encryptDataTransform.error {
                present(error: error)
            }
            completion(false)
            return
        }
        
        encryptedData = data

        if self.shouldAddToKeychain {
            let keychainSaveOperation = EnigmaKeychainSavePasswordOperation()
            keychainSaveOperation.account = keychainAccount
            keychainSaveOperation.password = password
            keychainSaveOperation.data = encryptedData
            queue.addOperation(keychainSaveOperation)
            queue.waitUntilAllOperationsAreFinished()
        }
        
        self.finishSession(with: .OK)
        completion(true)
    }
        
    func finishSession(with response: NSApplication.ModalResponse) {
        guard let passwordWindow = passwordWindowController.window else { return }
        
        DispatchQueue.main.async {
            if
                passwordWindow.isSheet,
                let sourceWindow = self.sourceWindow {
                sourceWindow.endSheet(passwordWindow, returnCode: response)
            } else if passwordWindow.isVisible {
                passwordWindow.orderOut(nil)
                NSApp.stopModal(withCode: response)
            }
        }
    }
    
    func present(error: Error) {
        guard let passwordWindow = passwordWindowController.window else { return }
        
        DispatchQueue.main.async {
            let alert = NSAlert(error: error)
            if
                passwordWindow.isSheet,
                let sourceWindow = self.sourceWindow {
                alert.window.appearance = sourceWindow.appearance
                alert.beginSheetModal(for: sourceWindow)
            } else if passwordWindow.isVisible {
                alert.window.appearance = passwordWindow.appearance
                alert.beginSheetModal(for: passwordWindow)
            } else {
                alert.runModal()
            }
        }
    }
}
