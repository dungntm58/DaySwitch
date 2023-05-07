//
//  DaySwitch+SwiftUI.swift
//  DaySwitch
//
//  Created by Robert on 04/05/2023.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif
#if os(iOS)
import UIKit
#endif

#if os(macOS)
@available(macOS 10.15, *)
public typealias PlatformViewRepresentable = NSViewRepresentable
#endif
#if os(iOS)
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
#endif
#if os(iOS)
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
    func makePlatformView(context: Context) -> DaySwitch {
        let view = DaySwitch(frame: CGRect(x: 0, y: 0, width: Constant.width, height: Constant.height))
        view.isDayLight = isDayLight
        return view
    }

    func updatePlatformView(_ view: DaySwitch, context: Context) {
        view.isDayLight = isDayLight
    }

    @available(macOS 13.0, iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, platformView: DaySwitch, context: Context) -> CGSize? {
        if let width = proposal.width, let height = proposal.height {
            return CGSize(width: width, height: height)
        } else {
            return CGSize(width: Constant.width, height: Constant.height)
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
        @State var isDayLight: Bool = false

        var body: some View {
            DayToggle(isDayLight: $isDayLight)
                .fixedSize()
        }
    }
}
#endif
