.PHONY: help setup generate build test run clean

help:
	@echo "iPhone Offline Voice Transcriber - Available Commands"
	@echo ""
	@echo "setup          - Install XcodeGen (macOS/Homebrew only)"
	@echo "generate       - Generate the Xcode project from ios/project.yml"
	@echo "build          - Compile-check the app (use Xcode + a physical device for real runs)"
	@echo "test           - Run the Swift unit tests"
	@echo "clean          - Remove the generated Xcode project and build artifacts"

setup:
	brew install xcodegen
	@echo "XcodeGen installed. Run 'make generate' next."

generate:
	cd ios && xcodegen generate

build: generate
	cd ios && xcodebuild build \
		-project VoiceTranscriber.xcodeproj \
		-scheme VoiceTranscriber \
		-configuration Debug \
		-destination 'generic/platform=iOS'

test: generate
	cd ios && xcodebuild test \
		-project VoiceTranscriber.xcodeproj \
		-scheme VoiceTranscriber \
		-destination 'platform=iOS Simulator,name=iPhone 15'

clean:
	rm -rf ios/VoiceTranscriber.xcodeproj
	rm -rf ios/DerivedData
	rm -rf ~/Library/Developer/Xcode/DerivedData/VoiceTranscriber-*
