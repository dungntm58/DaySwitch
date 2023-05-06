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
        DaySwitch(frame: .zero)
    }

    public func updateNSView(_ nsView: DaySwitch, context: Context) {
        nsView.isDayLight = isDayLight
    }
#endif
#if os(iOS)
    public func makeUIView(context: Context) -> DaySwitch {
        let `switch` = DaySwitch(frame: .zero)
        `switch`.isDayLight = isDayLight
        return `switch`
    }

    public func updateUIView(_ uiView: DaySwitch, context: Context) {
        uiView.isDayLight = isDayLight
    }
#endif
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
                .frame(width: Constant.width, height: Constant.height)
        }
    }
}
#endif
