import Cocoa

class PasswordWindowController: NSWindowController {

    static let storyboardName = NSStoryboard.Name(String(describing: PasswordWindowController.self))

    static let storyboard: NSStoryboard = {
        let storyboard = NSStoryboard(
            name: PasswordWindowController.storyboardName,
            bundle: Bundle(for: PasswordWindowController.self))
        return storyboard
    }()
    
    static func makeWindowController() -> PasswordWindowController {
        let windowController = storyboard.instantiateInitialController() as! PasswordWindowController
        return windowController
    }

    var passwordViewController: PasswordViewController? {
        return contentViewController as? PasswordViewController
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
}

class PasswordPanelController: PasswordWindowController {
    
    static let identifier = NSStoryboard.SceneIdentifier(String(describing: PasswordPanelController.self))
    
    static func makePanelController() -> PasswordPanelController {
        let windowController = storyboard.instantiateController(withIdentifier: identifier) as! PasswordPanelController
        return windowController
    }
}

class PasswordSheetController: PasswordWindowController {

    static let identifier = NSStoryboard.SceneIdentifier(String(describing: PasswordSheetController.self))
    
    static func makeSheetController() -> PasswordSheetController {
        let windowController = storyboard.instantiateController(withIdentifier: identifier) as! PasswordSheetController
        return windowController
    }
}

