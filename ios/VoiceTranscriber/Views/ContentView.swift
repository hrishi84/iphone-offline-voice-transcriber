import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorderService()
    @StateObject private var transcriber = TranscriptionService()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text("Voice Transcriber")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                // Recording Status
                VStack(spacing: 12) {
                    Image(systemName: audioRecorder.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 48))
                        .foregroundColor(audioRecorder.isRecording ? .red : .blue)
                        .animation(.easeInOut(duration: 0.3), value: audioRecorder.isRecording)

                    Text(audioRecorder.isRecording ? "Recording..." : "Ready")
                        .font(.headline)

                    if !audioRecorder.duration.isEmpty {
                        Text(audioRecorder.duration)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Transcription Result
                if !transcriber.result.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcription")
                            .font(.headline)

                        Text(transcriber.result)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }

                Spacer()

                // Controls
                HStack(spacing: 16) {
                    Button(action: toggleRecording) {
                        Label(audioRecorder.isRecording ? "Stop" : "Start", systemImage: audioRecorder.isRecording ? "stop.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(audioRecorder.isRecording ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(transcriber.isProcessing)

                    if !transcriber.result.isEmpty {
                        Button(action: clearTranscription) {
                            Label("Clear", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray4))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                    }
                }

                // Error Message
                if let error = audioRecorder.errorMessage ?? transcriber.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color(.systemOrange).opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                audioRecorder.requestMicrophonePermission()
            }
        }
    }

    private func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            if let audioData = audioRecorder.audioData {
                transcriber.transcribe(audioData: audioData)
            }
        } else {
            audioRecorder.startRecording()
        }
    }

    private func clearTranscription() {
        transcriber.clearResult()
        audioRecorder.clearRecording()
    }
}

#Preview {
    ContentView()
}
