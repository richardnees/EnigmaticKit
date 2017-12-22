import Foundation
import EnigmaticCore

extension EnigmaController: PasswordViewControllerDelegate {
    public var autofillPassword: String? {
        let keychainMatchOperation = EnigmaKeychainMatchPasswordOperation()
        keychainMatchOperation.data = encryptedData
        queue.addOperation(keychainMatchOperation)
        queue.waitUntilAllOperationsAreFinished()
        return keychainMatchOperation.password
    }
    
    public func passwordViewController(_ passwordViewController: PasswordViewController, choosePassword password: String, completion: @escaping (Bool) -> Void) {
        switch transform {
        case .decrypt:
            decrypt(with: password, completion: completion)
        case .encrypt:
            encrypt(with: password, completion: completion)
        }
    }
    
    public func passwordViewControllerDidCancel(_ passwordViewController: PasswordViewController) {
        finishSession(with: .cancel)
    }
}
