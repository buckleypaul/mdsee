import AppKit
import Foundation

func printUsage() {
    fputs("Usage: mdsee <file.md>\n", stderr)
}

func printError(_ message: String) {
    fputs("Error: \(message)\n", stderr)
}

// Check if we're running as the detached child process
let isDetached = ProcessInfo.processInfo.environment["MDSEE_DETACHED"] == "1"

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

if !isDetached {
    // Spawn a detached child process and exit
    let executablePath = CommandLine.arguments[0]

    // Build environment with MDSEE_DETACHED=1
    var env = ProcessInfo.processInfo.environment
    env["MDSEE_DETACHED"] = "1"
    let envStrings = env.map { "\($0.key)=\($0.value)" }
    let envCStrings = envStrings.map { strdup($0) } + [nil]

    // Build arguments
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
let app = NSApplication.shared
let delegate = AppDelegate(fileURL: fileURL)
app.delegate = delegate
app.run()
