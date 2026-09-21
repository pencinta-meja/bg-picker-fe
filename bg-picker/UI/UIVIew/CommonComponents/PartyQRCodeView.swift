import CoreImage.CIFilterBuiltins
import SwiftUI

struct PartyQRCodeView: View {
    let url: URL

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        Group {
            if let image = qrImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("Room invitation QR code")
            } else {
                ContentUnavailableView(
                    "QR unavailable",
                    systemImage: "qrcode",
                    description: Text("Share the room code instead.")
                )
            }
        }
    }

    private var qrImage: UIImage? {
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage?.transformed(
            by: CGAffineTransform(scaleX: 12, y: 12)
        ), let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
