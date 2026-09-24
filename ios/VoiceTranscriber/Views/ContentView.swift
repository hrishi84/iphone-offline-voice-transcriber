import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject var viewModel: TranscriberViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Voice Transcriber")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                statusCard

                if case .result(let text) = viewModel.state {
                    transcriptCard(text)
                }

                Spacer()

                recordButton

                if case .error(let message) = viewModel.state {
                    errorBanner(message)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var statusCard: some View {
        VStack(spacing: 12) {
            Image(systemName: isRecording ? "mic.fill" : "mic")
                .font(.system(size: 48))
                .foregroundColor(isRecording ? .red : .blue)
                .animation(.easeInOut(duration: 0.3), value: isRecording)

            Text(statusText)
                .font(.headline)

            if case .downloadingModel = viewModel.state {
                Text("First run only — downloading the on-device model. Stay on Wi-Fi.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func transcriptCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcription")
                .font(.headline)

            Text(text)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            HStack(spacing: 16) {
                Button(action: { copy(text) }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray4))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }

                ShareLink(item: text) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: { viewModel.dismissResult() }) {
                    Label("Clear", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray4))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }

    private var recordButton: some View {
        Button(action: { viewModel.toggleRecording() }) {
            Label(isRecording ? "Stop" : "Start", systemImage: isRecording ? "stop.fill" : "play.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(isRecording ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .disabled(isTranscribingOrDownloading)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color(.systemOrange).opacity(0.1))
        .cornerRadius(8)
    }

    private func copy(_ text: String) {
        UIPasteboard.general.string = text
    }

    private var isRecording: Bool {
        if case .recording = viewModel.state { return true }
        return false
    }

    private var isTranscribingOrDownloading: Bool {
        switch viewModel.state {
        case .transcribing, .downloadingModel:
            return true
        default:
            return false
        }
    }

    private var statusText: String {
        switch viewModel.state {
        case .idle, .result, .error:
            return "Ready"
        case .downloadingModel:
            return "Downloading model…"
        case .recording:
            return "Recording…"
        case .transcribing:
            return "Transcribing…"
        }
    }
}

#Preview {
    ContentView(viewModel: TranscriberViewModel())
}
