import Cocoa

public class EnigmaDocumentPluginController {
    public static let shared = EnigmaDocumentPluginController()
    
    public var plugIns: [EnigmaDocumentPluginProtocol] = []
    
    public func load(sortedIdentifiers: [String] = [], completion: () -> ()) {
        var plugInsDictionary: [String:EnigmaDocumentPluginProtocol] = [:]
        var plugIns: [EnigmaDocumentPluginProtocol] = []
        
        if
            let builtInPlugInsURL = Bundle.main.builtInPlugInsURL,
            let plugInURLs = try? FileManager.default.contentsOfDirectory(at: builtInPlugInsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]) {
            
            plugInURLs.forEach { plugInURL in
                if
                    let plugInBundle = Bundle(url: plugInURL),
                    let principalClass = plugInBundle.principalClass as? EnigmaDocumentPlugin.Type,
                    let instance = principalClass.init() as? EnigmaDocumentPluginProtocol {
                    plugInsDictionary[instance.identifer] = instance
                }
            }
        }
        
        for sortedIdentifier in sortedIdentifiers {
            if let plugIn = plugInsDictionary[sortedIdentifier] {
                plugIns.append(plugIn)
                plugInsDictionary[sortedIdentifier] = nil
            }
        }
        
        plugIns.append(contentsOf: plugInsDictionary.flatMap { $0.value })
        
        self.plugIns = plugIns
        completion()
    }
}
