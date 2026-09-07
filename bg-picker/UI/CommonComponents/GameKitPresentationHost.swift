import SwiftUI
import UIKit

struct GameKitPresentationHost<Content: View>: View {
    @ObservedObject var manager: GameKitManager
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .fullScreenCover(
                isPresented: Binding(
                    get: { manager.presentedViewController != nil },
                    set: { isPresented in
                        if !isPresented {
                            manager.dismissPresentedController()
                        }
                    }
                )
            ) {
                if let controller = manager.presentedViewController {
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
