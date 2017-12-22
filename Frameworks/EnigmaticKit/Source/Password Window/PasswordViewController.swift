import Cocoa
import EnigmaticCore

public protocol PasswordViewControllerDelegate: class {
    func passwordViewController(_ passwordViewController: PasswordViewController, choosePassword password: String, completion: @escaping (Bool) -> Void)
    func passwordViewControllerDidCancel(_ passwordViewController: PasswordViewController)
    
    var transform: Enigma.Transform { get }
    var allowsKeychainAccess: Bool { get }
    var shouldAddToKeychain: Bool { get set }
    var displaysDescription: Bool { get }
    var autofillPassword: String? { get }
}

public class PasswordViewController: NSViewController {
    
    @IBOutlet weak var descriptionStackView: NSStackView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    
    @IBOutlet weak var passwordStackView: NSStackView!
    @IBOutlet weak var passwordField: NSSecureTextField!
    
    @IBOutlet weak var verifyPasswordStackView: NSStackView!
    @IBOutlet weak var verifyPasswordField: NSSecureTextField!
    
    @IBOutlet weak var warningLabel: NSTextField!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var addToKeychainButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var okButton: NSButton!
    
    public weak var delegate: PasswordViewControllerDelegate?
    
    public override func viewWillAppear() {
        super.viewWillAppear()
    
        guard let delegate = delegate else {
            fatalError("PasswordViewController requires a PasswordViewControllerDelegate")
        }

        passwordField.stringValue = ""
        verifyPasswordField.stringValue = ""
        
        progressIndicator.stopAnimation(nil)
        progressIndicator.alphaValue = 0.0

        switch delegate.transform {
        case .decrypt:

            passwordField.stringValue = delegate.autofillPassword ?? ""
            passwordField.nextKeyView = addToKeychainButton

            titleLabel.stringValue = NSLocalizedString("Decryption", comment: "Needs comment")
            descriptionLabel.stringValue = NSLocalizedString("Enter password to decrypt text.", comment: "Needs comment")
            verifyPasswordStackView.isHidden = true
            warningLabel.isHidden = true
            
            okButton.title = NSLocalizedString("Decrypt", comment: "Needs comment")
        case .encrypt:
            
            passwordField.nextKeyView = verifyPasswordField

            titleLabel.stringValue = NSLocalizedString("Encryption", comment: "Needs comment")
            descriptionLabel.stringValue = NSLocalizedString("Enter password to encrypt data.", comment: "Needs comment")
            verifyPasswordStackView.isHidden = false
            warningLabel.isHidden = true

            okButton.title = NSLocalizedString("Encrypt", comment: "Needs comment")
        }

        descriptionStackView.isHidden = !delegate.displaysDescription
        addToKeychainButton.isHidden = !delegate.allowsKeychainAccess
        okButton.isEnabled = !passwordField.stringValue.isEmpty
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(passwordField)
    }
    
    @IBAction func addToKeychain(_ sender: NSButton) {
        guard let delegate = delegate else {
            fatalError("PasswordViewController requires a PasswordViewControllerDelegate")
        }
        
        delegate.shouldAddToKeychain = addToKeychainButton.state == .on
    }
    
    @IBAction func choosePassword(_ sender: NSButton) {
        guard let delegate = delegate else {
            fatalError("PasswordViewController requires a PasswordViewControllerDelegate")
        }
        
        progressIndicator.startAnimation(nil)
        progressIndicator.animator().alphaValue = 1.0
        passwordField.isEnabled = false
        verifyPasswordField.isEnabled = false
        addToKeychainButton.isEnabled = false
        okButton.isEnabled = false

        let successCompletion: ((Bool) -> Void) = { success in
            self.progressIndicator.stopAnimation(nil)
            self.progressIndicator.animator().alphaValue = 0.0
            self.passwordField.isEnabled = true
            self.verifyPasswordField.isEnabled = true
            self.addToKeychainButton.isEnabled = true
            self.okButton.isEnabled = true
        }
        
        delegate.passwordViewController(self, choosePassword: passwordField.stringValue, completion: successCompletion)
    }

    @IBAction func cancel(_ sender: NSButton) {
        delegate?.passwordViewControllerDidCancel(self)
    }
}

extension PasswordViewController: NSTextFieldDelegate {
    
    public override func controlTextDidChange(_ obj: Notification) {
        guard let delegate = delegate else {
            fatalError("PasswordViewController requires a PasswordViewControllerDelegate")
        }
        
        switch delegate.transform {
        case .encrypt:
            if
                passwordField.stringValue == verifyPasswordField.stringValue,
                passwordField.stringValue.isEmpty == false,
                verifyPasswordField.stringValue.isEmpty == false {
                warningLabel.isHidden = true
                warningLabel.stringValue = ""
                okButton.isEnabled = true
            } else {
                warningLabel.stringValue = NSLocalizedString("Passwords don't match", comment: "Needs comment")
                warningLabel.isHidden = false
                okButton.isEnabled = false
            }

        case .decrypt:
            okButton.isEnabled = !passwordField.stringValue.isEmpty
        }
    }
}
