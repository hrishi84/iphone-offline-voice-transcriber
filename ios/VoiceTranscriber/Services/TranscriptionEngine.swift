import Foundation

/// Seam between the app and whatever on-device ASR library backs it.
///
/// The only conformer today is `FluidAudioTranscriptionEngine`. Keeping this
/// protocol separate means that if FluidAudio's actual method names differ
/// from what's assumed there (verify against the resolved package's own
/// Documentation/ASR/GettingStarted.md once Xcode pulls it in), only that one
/// file needs to change — nothing else in the app references FluidAudio types.
protocol TranscriptionEngine {
    /// Loads (downloading on first run, then reading from cache) the ASR model.
    func loadModels() async throws

    /// Transcribes 16kHz mono Float32 samples into text.
    func transcribe(samples: [Float]) async throws -> String
}
