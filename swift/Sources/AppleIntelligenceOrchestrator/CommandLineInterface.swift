import Foundation

public enum CommandLineInterface {
    
    public static func displayMainMenu() {
        print(CommandConstants.HelpText.mainMenu)
    }
    
    public static func displaySuccess(_ message: String) {
        print("\(CommandConstants.UIPrefix.success)\(message)")
    }
    
    public static func displayError(_ message: String) {
        // Print to stderr to distinguish errors in scripts/pipes
        let err = "\(CommandConstants.UIPrefix.error)\(message)\n"
        FileHandle.standardError.write(err.data(using: .utf8) ?? Data())
    }
}
