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
/// `AsrManager.transcribe(_:decoderState:language:)` takes a caller-owned
/// `TdtDecoderState` (it carries the RNN-T decoder's LSTM state across calls
/// for streaming use). Since this app transcribes one complete recording at
/// a time rather than streaming, a fresh `TdtDecoderState` is created per
/// call via `.make()` so recordings never share state.
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

        var decoderState = TdtDecoderState.make()
        let result = try await asrManager.transcribe(samples, decoderState: &decoderState)
        let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw TranscriptionEngineError.emptyTranscript
        }
        return text
    }
}
