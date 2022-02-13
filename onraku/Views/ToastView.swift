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

func showToastWithMessage(_ message: String) {
    NotificationCenter.default.post(
        name: NSNotification.ShowToastRequest,
        object: nil,
        userInfo: ["message": message]
    )
}

struct ToastView: View {
    @State var message: String = ""
    @State var isShown: Bool = false
    @State var opacity: Double = 0

    var body: some View {
        Group {
            if isShown {
                // explicitly set zIndex to avoid bug
                // https://sarunw.com/posts/how-to-fix-zstack-transition-animation-in-swiftui/
                ToastContentView(message: message).zIndex(10)
            }
        }.onReceive(
            NotificationCenter.default.publisher(for: NSNotification.ShowToastRequest),
            perform: { obj in
                if let userInfo = obj.userInfo, let gotMessage = userInfo["message"] as? String {
                    Task {
                        await MainActor.run {
                            self.message = gotMessage
                            withAnimation(.easeIn(duration: 0.15)) {
                                print("showing")
                                self.isShown = true
                            }
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 1.2,
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
    var body: some View {
        Text(message)
            .opacity(0.8)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial)
            .cornerRadius(8)
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastContentView(message: "Foo Bar").preferredColorScheme(.light)

    }
}
