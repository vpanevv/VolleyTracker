import SwiftUI

struct PlayerPhotoView: View {
    let photoData: Data?
    let name: String
    let size: CGFloat
    var backgroundColor: Color = .volleyballOrange

    private var initials: String {
        let parts = name.split(separator: " ")
        return String(parts.compactMap { $0.first }.prefix(2)).uppercased()
    }

    var body: some View {
        Group {
            if let data = photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    backgroundColor
                    Text(initials.isEmpty ? "?" : initials)
                        .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
    }
}
