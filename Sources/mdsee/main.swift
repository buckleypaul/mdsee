import AppKit
import Foundation

func printUsage() {
    fputs("Usage: mdsee [--theme <name>] <file.md>\n", stderr)
    fputs("       mdsee --list-themes\n", stderr)
}

func printError(_ message: String) {
    fputs("Error: \(message)\n", stderr)
}

// Check if we're running as the detached child process
let isDetached = ProcessInfo.processInfo.environment["MDSEE_DETACHED"] == "1"

// Parse command line arguments
var args = Array(CommandLine.arguments.dropFirst())
var themeName: String?
var filePath: String?

// Handle --list-themes
if args.contains("--list-themes") {
    let engine = ThemeEngine()
    let themes = engine.listThemes()
    if themes.isEmpty {
        print("No themes found.")
    } else {
        print("Available themes:")
        for theme in themes {
            print("  - \(theme)")
        }
    }
    exit(0)
}

// Parse arguments
while !args.isEmpty {
    let arg = args.removeFirst()
    if arg == "--theme" || arg == "-t" {
        guard !args.isEmpty else {
            printError("--theme requires a theme name")
            printUsage()
            exit(1)
        }
        themeName = args.removeFirst()
    } else if arg.starts(with: "-") {
        printError("Unknown option: \(arg)")
        printUsage()
        exit(1)
    } else {
        filePath = arg
    }
}

guard let path = filePath else {
    printUsage()
    exit(1)
}

// Load config and apply defaults
let config = AppConfig.load()
if themeName == nil {
    themeName = config.theme
}

let fileURL = URL(fileURLWithPath: path).standardizedFileURL

// Validate file exists
let fileManager = FileManager.default
guard fileManager.fileExists(atPath: fileURL.path) else {
    printError("File does not exist: \(path)")
    exit(1)
}

// Validate file is readable
guard fileManager.isReadableFile(atPath: fileURL.path) else {
    printError("File is not readable: \(path)")
    exit(1)
}

if !isDetached {
    // Spawn a detached child process and exit
    let executablePath = CommandLine.arguments[0]

    // Build environment with MDSEE_DETACHED=1
    var env = ProcessInfo.processInfo.environment
    env["MDSEE_DETACHED"] = "1"
    if let theme = themeName {
        env["MDSEE_THEME"] = theme
    }
    let envStrings = env.map { "\($0.key)=\($0.value)" }
    let envCStrings = envStrings.map { strdup($0) } + [nil]

    // Build arguments (theme is passed via environment to avoid complex arg parsing)
    let argsCStrings = [strdup(executablePath), strdup(fileURL.path), nil]

    var pid: pid_t = 0
    var fileActions: posix_spawn_file_actions_t?
    posix_spawn_file_actions_init(&fileActions)

    // Redirect stdin/stdout/stderr to /dev/null to fully detach
    posix_spawn_file_actions_addopen(&fileActions, STDIN_FILENO, "/dev/null", O_RDONLY, 0)
    posix_spawn_file_actions_addopen(&fileActions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0)
    posix_spawn_file_actions_addopen(&fileActions, STDERR_FILENO, "/dev/null", O_WRONLY, 0)

    var attr: posix_spawnattr_t?
    posix_spawnattr_init(&attr)
    posix_spawnattr_setflags(&attr, Int16(POSIX_SPAWN_SETSID))

    let result = posix_spawn(&pid, executablePath, &fileActions, &attr, argsCStrings, envCStrings)

    posix_spawn_file_actions_destroy(&fileActions)
    posix_spawnattr_destroy(&attr)

    // Free allocated strings
    for ptr in argsCStrings { free(ptr) }
    for ptr in envCStrings { free(ptr) }

    if result != 0 {
        printError("Failed to spawn detached process: \(String(cString: strerror(result)))")
        exit(1)
    }

    // Parent exits, returning control to terminal
    exit(0)
}

// Detached child process: start the application
// Theme can come from environment (passed by parent) or config
let effectiveTheme = ProcessInfo.processInfo.environment["MDSEE_THEME"] ?? themeName

let app = NSApplication.shared
let delegate = AppDelegate(fileURL: fileURL, themeName: effectiveTheme)
app.delegate = delegate
app.run()
