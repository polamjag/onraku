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

func showToastWithMessage(_ message: String, withSystemImage: String?) {
    NotificationCenter.default.post(
        name: NSNotification.ShowToastRequest,
        object: nil,
        userInfo: ["message": message, "systemImage": withSystemImage ?? ""]
    )
}

struct ToastView: View {
    @State var message: String = ""
    @State var systemImage: String = ""
    @State var isShown: Bool = false
    @State var opacity: Double = 0

    var body: some View {
        Group {
            if isShown {
                // explicitly set zIndex to avoid bug
                // https://sarunw.com/posts/how-to-fix-zstack-transition-animation-in-swiftui/
                ToastContentView(message: message, systemImage: systemImage).zIndex(10)
            }
        }.onReceive(
            NotificationCenter.default.publisher(for: NSNotification.ShowToastRequest),
            perform: { obj in
                if let userInfo = obj.userInfo, let gotMessage = userInfo["message"] as? String,
                    let systemImage = userInfo["systemImage"] as? String
                {
                    Task {
                        await MainActor.run {
                            self.message = gotMessage
                            self.systemImage = systemImage

                            withAnimation(.easeIn(duration: 0.15)) {
                                print("showing")
                                self.isShown = true
                            }
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 1.7,
                                execute: {
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        print("hiding")
                                        self.isShown = false
                                    }
                                })
                        }
                    }
                }
            }
        ).allowsHitTesting(false)
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
        ToastContentView(message: "Lolem Ipsum", systemImage: "text.insert").preferredColorScheme(
            .light)
        ToastContentView(message: "Lolem Ipsum Dot Sitor Amet", systemImage: "text.insert")
            .preferredColorScheme(
                .dark)
    }
}
