//
//  DaySwitch+SwiftUI.swift
//  DaySwitch
//
//  Created by Robert on 04/05/2023.
//

import SwiftUI
import Combine

#if os(macOS)
import AppKit

@available(macOS 10.15, *)
public typealias PlatformViewRepresentable = NSViewRepresentable
#else
import UIKit

@available(iOS 13, *)
public typealias PlatformViewRepresentable = UIViewRepresentable
#endif

@available(macOS 10.15, iOS 13, *)
public struct DayToggle: PlatformViewRepresentable {
    @Binding var isDayLight: Bool

    public init(isDayLight: Binding<Bool>) {
        self._isDayLight = isDayLight
    }

#if os(macOS)
    public func makeNSView(context: Context) -> DaySwitch {
        makePlatformView(context: context)
    }

    public func updateNSView(_ nsView: DaySwitch, context: Context) {
        updatePlatformView(nsView, context: context)
    }

    @available(macOS 13.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize, nsView: DaySwitch, context: Context) -> CGSize? {
        sizeThatFits(proposal, platformView: nsView, context: context)
    }
#else
    public func makeUIView(context: Context) -> DaySwitch {
        makePlatformView(context: context)
    }

    public func updateUIView(_ uiView: DaySwitch, context: Context) {
        updatePlatformView(uiView, context: context)
    }

    @available(iOS 16.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: DaySwitch, context: Context) -> CGSize? {
        sizeThatFits(proposal, platformView: uiView, context: context)
    }
#endif

    private func makePlatformView(context: Context) -> DaySwitch {
        let view = DaySwitch(frame: CGRect(x: 0, y: 0, width: Constant.width, height: Constant.height))
        view.isDayLight = isDayLight
        context.coordinator.observe(from: view)
        return view
    }

    private func updatePlatformView(_ view: DaySwitch, context: Context) {
        view.isDayLight = isDayLight
    }

    @available(macOS 13.0, iOS 16.0, *)
    private func sizeThatFits(_ proposal: ProposedViewSize, platformView: DaySwitch, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions(by: platformView.intrinsicContentSize)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(isDayLight: $isDayLight)
    }

    public class Coordinator {
        @Binding var isDayLight: Bool

        private var cancellable: AnyCancellable?

        init(isDayLight: Binding<Bool>) {
            self._isDayLight = isDayLight
        }

        func observe(from view: DaySwitch) {
            cancellable = view.publisher(for: \.isDayLight)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] value in
                    self?.isDayLight = value
                }
        }
    }
}

#if DEBUG
@available(macOS 10.15, iOS 13, *)
struct DayToggle_Previews: PreviewProvider {
    static var previews: some View {
        Container()
            .previewLayout(.sizeThatFits)
    }

    struct Container: View {
        @State var isDayLight: Bool = true

        var body: some View {
            VStack {
                DayToggle(isDayLight: $isDayLight)
                    .fixedSize()
                Text(isDayLight ? "Day" : "Night")
            }
        }
    }
}
#endif
