import AppKit
import Foundation

func printUsage() {
    fputs("Usage: mdsee <file.md>\n", stderr)
}

func printError(_ message: String) {
    fputs("Error: \(message)\n", stderr)
}

// Parse command line arguments
let args = CommandLine.arguments
guard args.count == 2 else {
    printUsage()
    exit(1)
}

let filePath = args[1]
let fileURL = URL(fileURLWithPath: filePath).standardizedFileURL

// Validate file exists
let fileManager = FileManager.default
guard fileManager.fileExists(atPath: fileURL.path) else {
    printError("File does not exist: \(filePath)")
    exit(1)
}

// Validate file is readable
guard fileManager.isReadableFile(atPath: fileURL.path) else {
    printError("File is not readable: \(filePath)")
    exit(1)
}

// Start the application
let app = NSApplication.shared
let delegate = AppDelegate(fileURL: fileURL)
app.delegate = delegate
app.run()
