import AVFoundation
import Observation

@Observable
final class AudioPreview {
    private(set) var playing: String?
    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var token = 0

    func toggle(_ url: URL) {
        if playing == url.path {
            stop()
            return
        }
        stop()
        guard let created = try? AVAudioPlayer(contentsOf: url) else { return }
        player = created
        created.play()
        playing = url.path
        token += 1
        let current = token
        let length = created.duration
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(length + 0.1))
            guard let self, self.token == current else { return }
            self.stop()
        }
    }

    func stop() {
        token += 1
        player?.stop()
        player = nil
        playing = nil
    }
}
