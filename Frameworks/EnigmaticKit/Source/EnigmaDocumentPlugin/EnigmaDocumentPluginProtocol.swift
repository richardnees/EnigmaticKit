import Cocoa

public protocol EnigmaDocumentPluginProtocol: class {
    var displayName: String { get }
    var identifer: String { get }
    var storyboard: NSStoryboard? { get }
    var viewController: NSViewController? { get }
}
