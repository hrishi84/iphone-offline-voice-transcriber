import AVFoundation
import Combine

class AudioRecorderService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var duration: String = ""
    @Published var errorMessage: String?

    var audioData: Data?

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingStartTime: Date?

    override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session setup failed: \(error.localizedDescription)"
        }
    }

    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.errorMessage = "Microphone permission denied"
                }
            }
        }
    }

    func startRecording() {
        let fileURL = getDocumentsDirectory().appendingPathComponent("recording.wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            DispatchQueue.main.async {
                self.isRecording = true
                self.recordingStartTime = Date()
                self.errorMessage = nil
                self.startTimer()
            }
        } catch {
            errorMessage = "Recording failed: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()

        let fileURL = getDocumentsDirectory().appendingPathComponent("recording.wav")

        do {
            audioData = try Data(contentsOf: fileURL)
        } catch {
            errorMessage = "Failed to read recording: \(error.localizedDescription)"
        }

        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

    func clearRecording() {
        audioData = nil
        duration = ""
        recordingStartTime = nil
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = self.recordingStartTime {
                let elapsed = Date().timeIntervalSince(startTime)
                let minutes = Int(elapsed) / 60
                let seconds = Int(elapsed) % 60
                let centiseconds = Int((elapsed * 100).truncatingRemainder(dividingBy: 100))

                DispatchQueue.main.async {
                    self.duration = String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
                }
            }
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
