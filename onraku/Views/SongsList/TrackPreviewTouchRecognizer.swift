//
//  TrackPreviewTouchRecognizer.swift
//  onraku
//

import SwiftUI
import UIKit

struct TrackPreviewTouchRecognizer: UIViewRepresentable {
    let onBegan: (CGPoint, CGFloat) -> Void
    let onChanged: (CGPoint, CGFloat) -> Void
    let onEnded: () -> Void

    func makeUIView(context: Context) -> TouchAttachmentView {
        let view = TouchAttachmentView(frame: .zero)
        view.backgroundColor = .clear
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: TouchAttachmentView, context: Context) {
        context.coordinator.onBegan = onBegan
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
        uiView.coordinator = context.coordinator
        context.coordinator.installRecognizer(from: uiView)
    }

    static func dismantleUIView(_ uiView: TouchAttachmentView, coordinator: Coordinator) {
        coordinator.uninstallRecognizer()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBegan: onBegan, onChanged: onChanged, onEnded: onEnded)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onBegan: (CGPoint, CGFloat) -> Void
        var onChanged: (CGPoint, CGFloat) -> Void
        var onEnded: () -> Void

        private weak var sourceView: UIView?
        private weak var attachedView: UIView?
        private weak var scrollView: UIScrollView?
        private weak var navigationController: UINavigationController?
        private var previousScrollEnabled: Bool?
        private var disabledBackGestureStates: [GestureEnabledState] = []
        private var initialTouchLocation: CGPoint?
        private var isSeekingWithTouch = false
        private var recognizer: UILongPressGestureRecognizer?

        private let seekActivationDistance: CGFloat = 80

        init(
            onBegan: @escaping (CGPoint, CGFloat) -> Void,
            onChanged: @escaping (CGPoint, CGFloat) -> Void,
            onEnded: @escaping () -> Void
        ) {
            self.onBegan = onBegan
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        func installRecognizer(from sourceView: UIView) {
            guard let targetView = sourceView.previewGestureAttachmentTarget else {
                return
            }

            self.sourceView = sourceView
            guard attachedView !== targetView else {
                return
            }

            uninstallRecognizer()

            let recognizer = UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleLongPress(_:))
            )
            recognizer.minimumPressDuration = 0.45
            recognizer.allowableMovement = 24
            recognizer.cancelsTouchesInView = true
            recognizer.delaysTouchesBegan = false
            recognizer.delaysTouchesEnded = false
            recognizer.delegate = self
            targetView.addGestureRecognizer(recognizer)

            self.attachedView = targetView
            self.scrollView = targetView.enclosingScrollView
            self.navigationController = targetView.enclosingNavigationController
            self.recognizer = recognizer
        }

        func uninstallRecognizer() {
            restoreBackNavigation()
            restoreScrolling()
            if let recognizer, let attachedView {
                attachedView.removeGestureRecognizer(recognizer)
            }
            recognizer = nil
            attachedView = nil
            scrollView = nil
            navigationController = nil
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let window = view.window
            let location = recognizer.location(in: window)
            let screenWidth =
                window?.windowScene?.screen.bounds.width
                ?? window?.bounds.width
                ?? 1

            switch recognizer.state {
            case .began:
                navigationController = navigationController ?? view.enclosingNavigationController
                suspendScrolling()
                suspendBackNavigation()
                onBegan(location, screenWidth)
                initialTouchLocation = location
                isSeekingWithTouch = false
            case .changed:
                if shouldSeek(with: location) {
                    onChanged(location, screenWidth)
                }
            case .ended, .cancelled, .failed:
                onEnded()
                restoreBackNavigation()
                restoreScrolling()
                initialTouchLocation = nil
                isSeekingWithTouch = false
            default:
                break
            }
        }

        private func shouldSeek(with location: CGPoint) -> Bool {
            if isSeekingWithTouch {
                return true
            }

            guard let initialTouchLocation else {
                return false
            }

            let horizontalDistance = abs(location.x - initialTouchLocation.x)
            guard horizontalDistance >= seekActivationDistance else {
                return false
            }

            isSeekingWithTouch = true
            return true
        }

        private func suspendScrolling() {
            guard previousScrollEnabled == nil, let scrollView else {
                return
            }
            previousScrollEnabled = scrollView.isScrollEnabled
            scrollView.isScrollEnabled = false
        }

        private func restoreScrolling() {
            guard let previousScrollEnabled else {
                return
            }
            scrollView?.isScrollEnabled = previousScrollEnabled
            self.previousScrollEnabled = nil
        }

        private func suspendBackNavigation() {
            guard disabledBackGestureStates.isEmpty else {
                return
            }

            let window = attachedView?.window ?? sourceView?.window
            let candidates =
                ([navigationController?.interactivePopGestureRecognizer].compactMap { $0 }
                + (window?.leftEdgePanGestureRecognizers ?? []))
                .reduce(into: [UIGestureRecognizer]()) { result, recognizer in
                    guard !result.contains(where: { $0 === recognizer }) else {
                        return
                    }
                    result.append(recognizer)
                }

            disabledBackGestureStates = candidates.map { recognizer in
                let state = GestureEnabledState(recognizer: recognizer)
                recognizer.isEnabled = false
                return state
            }
        }

        private func restoreBackNavigation() {
            for state in disabledBackGestureStates {
                state.recognizer?.isEnabled = state.wasEnabled
            }
            disabledBackGestureStates = []
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            guard let sourceView else {
                return true
            }

            let location = touch.location(in: sourceView)
            if !sourceView.bounds.isEmpty {
                return sourceView.bounds.contains(location)
            }

            guard let attachedView else {
                return true
            }
            let attachedLocation = touch.location(in: attachedView)
            return attachedLocation.x < attachedView.bounds.maxX - 52
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            if otherGestureRecognizer is UIScreenEdgePanGestureRecognizer {
                return false
            }

            return true
        }

        private final class GestureEnabledState {
            weak var recognizer: UIGestureRecognizer?
            let wasEnabled: Bool

            init(recognizer: UIGestureRecognizer) {
                self.recognizer = recognizer
                self.wasEnabled = recognizer.isEnabled
            }
        }
    }

    final class TouchAttachmentView: UIView {
        weak var coordinator: Coordinator?

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            coordinator?.installRecognizer(from: self)
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.installRecognizer(from: self)
        }
    }
}

extension UIView {
    fileprivate var previewGestureAttachmentTarget: UIView? {
        var currentView = superview
        while let view = currentView {
            if view is UITableViewCell || view is UICollectionViewCell {
                return view
            }
            currentView = view.superview
        }

        return superview
    }

    fileprivate var enclosingScrollView: UIScrollView? {
        var currentView: UIView? = self
        while let view = currentView {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            currentView = view.superview
        }

        return nil
    }

    fileprivate var enclosingNavigationController: UINavigationController? {
        var currentResponder: UIResponder? = self
        while let responder = currentResponder {
            if let navigationController = responder as? UINavigationController {
                return navigationController
            }

            if let viewController = responder as? UIViewController,
                let navigationController = viewController.navigationController
            {
                return navigationController
            }

            currentResponder = responder.next
        }

        return nil
    }

    fileprivate var leftEdgePanGestureRecognizers: [UIScreenEdgePanGestureRecognizer] {
        let ownRecognizers =
            (gestureRecognizers ?? []).compactMap { recognizer in
                recognizer as? UIScreenEdgePanGestureRecognizer
            }
            .filter { $0.edges.contains(.left) }

        return ownRecognizers + subviews.flatMap(\.leftEdgePanGestureRecognizers)
    }
}
