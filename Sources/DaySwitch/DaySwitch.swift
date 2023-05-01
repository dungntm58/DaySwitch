//
//  DaySwitch.swift
//  DaySwitch
//
//  Created by Robert on 01/05/2023.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if os(macOS)
public typealias PlatformControl = NSControl
public typealias PlatformRect = NSRect
public typealias PlatformSize = NSSize
#else
public typealias PlatformControl = UIControl
public typealias PlatformRect = CGRect
public typealias PlatformSize = CGSize
#endif

open class DaySwitch: PlatformControl {
    

    open override var intrinsicContentSize: PlatformSize {
        PlatformSize(width: 100, height: 60)
    }

    func createSunLayer() -> CALayer {
        let layer = CALayer()
        let size = bounds.height - 4
        layer.frame = .init(x: 2, y: 2, width: size, height: size)
        layer.cornerRadius = size / 2
        return layer
    }
}
