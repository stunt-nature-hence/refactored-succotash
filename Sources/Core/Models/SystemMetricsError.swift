import Foundation

public enum SystemMetricsError: Error, Sendable {
    case permissionDenied(String)
    case kernelAPIError(String)
    case invalidData(String)
    case networkError(String)
    case unknown(Error)
    
    public var localizedDescription: String {
        switch self {
        case .permissionDenied(let msg):
            return "Permission denied: \(msg)"
        case .kernelAPIError(let msg):
            return "Kernel API error: \(msg)"
        case .invalidData(let msg):
            return "Invalid data: \(msg)"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
