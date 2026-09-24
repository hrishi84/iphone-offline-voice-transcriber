import Foundation

@MainActor
final class TranscriberViewModel: ObservableObject {
    @Published private(set) var state: TranscriberState = .idle

    private let audioRecorder: AudioRecorderService
    private let transcriptionEngine: TranscriptionEngine
    private var modelsLoaded = false

    init(
        audioRecorder: AudioRecorderService = AudioRecorderService(),
        transcriptionEngine: TranscriptionEngine = FluidAudioTranscriptionEngine()
    ) {
        self.audioRecorder = audioRecorder
        self.transcriptionEngine = transcriptionEngine
    }

    /// Ensures the model is downloaded/loaded, then starts recording.
    /// Call this from the record button.
    func toggleRecording() {
        if case .recording = state {
            stopAndTranscribe()
            return
        }

        guard !state.isBusy else { return }

        Task {
            await ensureModelsLoaded()
            guard modelsLoaded else { return }
            await startRecording()
        }
    }

    func dismissResult() {
        state = .idle
    }

    private func ensureModelsLoaded() async {
        guard !modelsLoaded else { return }

        state = .downloadingModel
        do {
            try await transcriptionEngine.loadModels()
            modelsLoaded = true
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func startRecording() async {
        guard await AudioRecorderService.requestPermission() else {
            state = .error("Microphone permission denied. Enable it in Settings to record.")
            return
        }

        do {
            try audioRecorder.start()
            state = .recording
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func stopAndTranscribe() {
        state = .transcribing

        Task {
            do {
                let samples = try audioRecorder.stop()
                let rawText = try await transcriptionEngine.transcribe(samples: samples)
                state = .result(TextCleanup.clean(rawText))
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}
