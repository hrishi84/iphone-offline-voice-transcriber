import AVFoundation

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case engineStartFailed(Error)
    case converterCreationFailed
    case noSamplesCaptured

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied."
        case .engineStartFailed(let error):
            return "Could not start the audio engine: \(error.localizedDescription)"
        case .converterCreationFailed:
            return "Could not set up audio format conversion."
        case .noSamplesCaptured:
            return "No audio was captured."
        }
    }
}

/// Captures microphone audio live and exposes it as 16kHz mono Float32
/// samples, the format FluidAudio's Parakeet model expects. Avoids ever
/// round-tripping through a file or a raw `Data` reinterpret-cast.
final class AudioRecorderService {
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16_000,
        channels: 1,
        interleaved: false
    )!

    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var capturedSamples: [Float] = []
    private let sampleQueue = DispatchQueue(label: "com.example.VoiceTranscriber.audioSampleQueue")

    var isRunning: Bool { engine.isRunning }

    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioRecorderError.converterCreationFailed
        }
        self.converter = converter

        sampleQueue.sync { capturedSamples.removeAll() }

        inputNode.installTap(onBus: 0, bufferSize: 4_096, format: inputFormat) { [weak self] buffer, _ in
            self?.convertAndStore(buffer)
        }

        do {
            engine.prepare()
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            throw AudioRecorderError.engineStartFailed(error)
        }
    }

    /// Stops capture and returns everything recorded as 16kHz mono Float32 samples.
    func stop() throws -> [Float] {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        let samples = sampleQueue.sync { capturedSamples }
        guard !samples.isEmpty else {
            throw AudioRecorderError.noSamplesCaptured
        }
        return samples
    }

    private func convertAndStore(_ buffer: AVAudioPCMBuffer) {
        guard let converter else { return }

        let outputCapacity = AVAudioFrameCount(
            Double(buffer.frameLength) * (targetFormat.sampleRate / buffer.format.sampleRate) + 1
        )
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputCapacity) else {
            return
        }

        var error: NSError?
        var consumed = false
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if consumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            outStatus.pointee = .haveData
            return buffer
        }

        guard error == nil, let channelData = outputBuffer.floatChannelData else { return }
        let frameCount = Int(outputBuffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))

        sampleQueue.sync {
            capturedSamples.append(contentsOf: samples)
        }
    }
}
