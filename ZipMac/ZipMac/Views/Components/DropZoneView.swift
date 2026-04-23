import SwiftUI

struct DropZoneView: View {
    let title: String
    let subtitle: String
    let onDrop: ([URL]) -> Void
    var onTap: (() -> Void)? = nil

    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 48))
                .foregroundColor(isTargeted ? .accentColor : .secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(isTargeted ? .accentColor : .secondary.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isTargeted ? Color.accentColor.opacity(0.05) : Color.clear)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            onTap?()
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
            return true
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    onDrop([url])
                }
            }
        }
    }
}
