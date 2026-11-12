import AVFoundation
import Observation
import Speech

nonisolated enum VoiceTap {
    static func authorizeSpeech() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    static func recognize(with recognizer: SFSpeechRecognizer, request: SFSpeechAudioBufferRecognitionRequest, update: @escaping @Sendable (String) -> Void) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, _ in
            if let result {
                update(result.bestTranscription.formattedString)
            }
        }
    }

    static func install(on node: AVAudioInputNode, format: AVAudioFormat, request: SFSpeechAudioBufferRecognitionRequest?, file: AVAudioFile?, level: @escaping @Sendable (Float) -> Void) {
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request?.append(buffer)
            try? file?.write(from: buffer)
            guard let samples = buffer.floatChannelData?[0] else { return }
            let count = Int(buffer.frameLength)
            guard count > 0 else { return }
            var sum: Float = 0
            for index in 0..<count {
                sum += samples[index] * samples[index]
            }
            level((sum / Float(count)).squareRoot())
        }
    }
}

@Observable
final class VoiceRecorder {
    private(set) var isRecording = false
    private(set) var transcript = ""
    private(set) var levels: [CGFloat] = []
    private(set) var elapsed: TimeInterval = 0
    private(set) var fileURL: URL?
    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var started = Date()
    @ObservationIgnored private var tick = 0

    private static var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent("Kin", isDirectory: true).appendingPathComponent("Voice", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func start() async -> Bool {
        PanelGuard.holds += 1
        let microphone = await AVCaptureDevice.requestAccess(for: .audio)
        let speech = microphone ? await VoiceTap.authorizeSpeech() : false
        PanelGuard.holds -= 1
        guard microphone else { return false }
        clear(deleting: true)
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { return false }
        let url = Self.folder.appendingPathComponent(UUID().uuidString + ".m4a")
        let settings: [String: Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: format.sampleRate, AVNumberOfChannelsKey: Int(format.channelCount)]
        let file = try? AVAudioFile(forWriting: url, settings: settings)
        var live: SFSpeechAudioBufferRecognitionRequest?
        if speech, let recognizer = SFSpeechRecognizer(), recognizer.isAvailable {
            let created = SFSpeechAudioBufferRecognitionRequest()
            created.shouldReportPartialResults = true
            live = created
            task = VoiceTap.recognize(with: recognizer, request: created) { text in
                Task { @MainActor [weak self] in
                    self?.transcript = text
                }
            }
        }
        request = live
        VoiceTap.install(on: input, format: format, request: live, file: file) { level in
            Task { @MainActor [weak self] in
                self?.push(level)
            }
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            return false
        }
        fileURL = file == nil ? nil : url
        started = Date()
        isRecording = true
        return true
    }

    func stop() {
        guard isRecording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        request?.endAudio()
        elapsed = Date().timeIntervalSince(started)
        isRecording = false
    }

    func clear(deleting: Bool) {
        if isRecording {
            stop()
        }
        task?.cancel()
        task = nil
        request = nil
        if deleting, let fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        fileURL = nil
        transcript = ""
        levels = []
        elapsed = 0
        tick = 0
    }

    private func push(_ level: Float) {
        guard isRecording else { return }
        elapsed = Date().timeIntervalSince(started)
        tick += 1
        guard tick % 3 == 0 else { return }
        levels.append(min(1, CGFloat(level) * 10))
        if levels.count > 56 {
            levels.removeFirst(levels.count - 56)
        }
    }
}
