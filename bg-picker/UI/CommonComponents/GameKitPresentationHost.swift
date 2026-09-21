import SwiftUI
import UIKit

struct GameKitPresentationHost<Content: View>: View {
    let session: any RoomSession
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .fullScreenCover(
                isPresented: Binding(
                    get: { session.presentedViewController != nil },
                    set: { isPresented in
                        if !isPresented {
                            session.dismissPresentedController()
                        }
                    }
                )
            ) {
                if let controller = session.presentedViewController {
                    UIKitControllerHost(controller: controller)
                        .ignoresSafeArea()
                }
            }
    }
}

private struct UIKitControllerHost: UIViewControllerRepresentable {
    let controller: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
