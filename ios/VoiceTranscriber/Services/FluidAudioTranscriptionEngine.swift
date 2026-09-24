import FluidAudio
import Foundation

enum TranscriptionEngineError: LocalizedError {
    case modelsNotLoaded
    case emptyTranscript

    var errorDescription: String? {
        switch self {
        case .modelsNotLoaded:
            return "The transcription model hasn't finished loading yet."
        case .emptyTranscript:
            return "Didn't catch that — try again."
        }
    }
}

/// Runs NVIDIA Parakeet TDT 0.6B v2 entirely on-device via FluidAudio
/// (https://github.com/FluidInference/FluidAudio), which ships a
/// pre-converted Core ML build of the model and executes it on the Apple
/// Neural Engine. The model itself is downloaded once from Hugging Face and
/// cached locally by FluidAudio; every call after that is fully offline.
///
/// NOTE: `AsrModels.downloadAndLoad(version:)`, `AsrManager.loadModels(_:)`
/// and `AsrManager.transcribe(_:source:)` reflect FluidAudio's documented API
/// shape at the time this was written. This project was authored without a
/// Swift toolchain available, so these calls have not been compiled against
/// the real package. If Xcode reports a mismatch after resolving the
/// FluidAudio package, this is the only file that needs to change.
final class FluidAudioTranscriptionEngine: TranscriptionEngine {
    private var asrManager: AsrManager?

    func loadModels() async throws {
        let models = try await AsrModels.downloadAndLoad(version: .v2)
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        asrManager = manager
    }

    func transcribe(samples: [Float]) async throws -> String {
        guard let asrManager else {
            throw TranscriptionEngineError.modelsNotLoaded
        }

        let result = try await asrManager.transcribe(samples, source: .microphone)
        let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw TranscriptionEngineError.emptyTranscript
        }
        return text
    }
}
