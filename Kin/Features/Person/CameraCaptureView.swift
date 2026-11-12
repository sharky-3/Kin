import SwiftUI

struct CameraCaptureView: View {
    let onCapture: (NSImage) -> Void
    let onCancel: () -> Void
    @State private var camera = CameraModel()
    @State private var unavailable = false

    var body: some View {
        VStack(spacing: 22) {
            Text("Take photo")
                .font(.system(size: 19, weight: .bold))
            ZStack {
                if unavailable {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                } else {
                    CameraPreview(session: camera.session)
                }
            }
            .frame(width: 190, height: 190)
            .background(.black.opacity(0.35))
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1))
            if unavailable {
                Text("Kin can't use the camera. Allow it in System Settings › Privacy & Security › Camera.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Button(action: { camera.capture() }) {
                    Circle()
                        .fill(.white)
                        .frame(width: 46, height: 46)
                        .padding(5)
                        .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
            PillButton(title: "Cancel", action: onCancel)
                .frame(width: 120)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .task {
            camera.onCapture = { [weak camera] image in
                camera?.stop()
                onCapture(image)
            }
            unavailable = !(await camera.start())
        }
        .onDisappear { camera.stop() }
    }
}
