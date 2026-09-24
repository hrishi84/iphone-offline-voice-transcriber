import Foundation

/// Drives the single source of truth the UI renders from.
enum TranscriberState: Equatable {
    case idle
    case downloadingModel
    case recording
    case transcribing
    case result(String)
    case error(String)

    var isBusy: Bool {
        switch self {
        case .downloadingModel, .recording, .transcribing:
            return true
        case .idle, .result, .error:
            return false
        }
    }
}
