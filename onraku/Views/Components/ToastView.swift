//
//  ToastView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/14.
//

import SwiftUI

extension NSNotification {
    static let ShowToastRequest = Notification.Name.init("ShowToastRequest")
}

func showToastWithMessage(_ message: String, systemImage: String?) async {
    await MainActor.run {
        NotificationCenter.default.post(
            name: NSNotification.ShowToastRequest,
            object: nil,
            userInfo: ["message": message, "systemImage": systemImage ?? ""]
        )
    }
}

struct ToastView: View {
    @State var message: String = ""
    @State var systemImage: String = ""
    @State var isShown: Bool = false
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        Group {
            if isShown {
                // explicitly set zIndex to avoid bug
                // https://sarunw.com/posts/how-to-fix-zstack-transition-animation-in-swiftui/
                ToastContentView(message: message, systemImage: systemImage).zIndex(10)
            }
        }.onReceive(
            NotificationCenter.default.publisher(
                for: NSNotification.ShowToastRequest),
            perform: { obj in
                if let userInfo = obj.userInfo,
                    let gotMessage = userInfo["message"] as? String,
                    let systemImage = userInfo["systemImage"] as? String
                {
                    dismissTask?.cancel()
                    message = gotMessage
                    self.systemImage = systemImage

                    withAnimation(.easeIn(duration: 0.15)) {
                        isShown = true
                    }

                    dismissTask = Task {
                        try? await Task.sleep(nanoseconds: 1_700_000_000)
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            withAnimation(.easeOut(duration: 0.25)) {
                                isShown = false
                            }
                            dismissTask = nil
                        }
                    }
                }
            }
        )
        .onDisappear {
            dismissTask?.cancel()
            dismissTask = nil
        }
        .allowsHitTesting(false)
    }
}

struct ToastContentView: View {
    var message: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            if !systemImage.isEmpty {
                Image(systemName: systemImage).font(.system(size: 32)).opacity(0.8)
            }
            Text(message)
        }.opacity(0.8)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(.thinMaterial)
            .cornerRadius(8)
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            ToastContentView(message: "Playing 12 Songs Next", systemImage: "text.insert")
        }
        .preferredColorScheme(.light)
        .previewDisplayName("Light")

        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            ToastContentView(message: "Shuffling 24 Songs", systemImage: "shuffle")
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark")
    }
}
