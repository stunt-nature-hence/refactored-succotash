import Foundation
import os.log

public enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public final class Logger: @unchecked Sendable {
    public static let shared = Logger()
    
    private let osLog: OSLog
    private var isEnabled: Bool
    private let minimumLevel: LogLevel
    
    private init() {
        self.osLog = OSLog(subsystem: "com.systemmonitor", category: "Performance")
        #if DEBUG
        self.isEnabled = true
        self.minimumLevel = .debug
        #else
        self.isEnabled = false
        self.minimumLevel = .error
        #endif
    }
    
    public func setEnabled(_ enabled: Bool) {
        self.isEnabled = enabled
    }
    
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    private func log(_ message: String, level: LogLevel, file: String, function: String, line: Int) {
        guard isEnabled, level >= minimumLevel else { return }
        
        let filename = (file as NSString).lastPathComponent
        let prefix = "[\(levelString(level))] [\(filename):\(line)] \(function)"
        
        let osLogType: OSLogType
        switch level {
        case .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        }
        
        os_log("%{public}s: %{public}s", log: osLog, type: osLogType, prefix, message)
    }
    
    private func levelString(_ level: LogLevel) -> String {
        switch level {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        }
    }
}
