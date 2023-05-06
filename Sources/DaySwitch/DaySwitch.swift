//
//  DaySwitch.swift
//  DaySwitch
//
//  Created by Robert on 01/05/2023.
//

#if os(macOS)
import AppKit
#endif
#if os(iOS)
import UIKit
#endif

#if os(macOS)
public typealias PlatformView = NSView
public typealias PlatformControl = NSControl
public typealias PlatformGestureRecognizer = NSGestureRecognizer
public typealias PlatformColor = NSColor
public typealias PlatformRect = NSRect
public typealias PlatformSize = NSSize
#endif
#if os(iOS)
public typealias PlatformView = UIView
public typealias PlatformControl = UIControl
public typealias PlatformGestureRecognizer = UIGestureRecognizer
public typealias PlatformColor = UIColor
public typealias PlatformRect = CGRect
public typealias PlatformSize = CGSize
#endif

extension PlatformColor {
    enum Day {
        static let sun = #colorLiteral(red: 1, green: 0.8298229575, blue: 0.2543709278, alpha: 1)
        static let darkSun = #colorLiteral(red: 0.9254901961, green: 0.7450980392, blue: 0.2117647059, alpha: 1)
        static let spaceBar = #colorLiteral(red: 0.5411764706, green: 0.8980392157, blue: 1, alpha: 1)
        static let cloud = PlatformColor.white
        static let darkCloud = #colorLiteral(red: 0.9450980392, green: 0.9450980392, blue: 0.9450980392, alpha: 1)
    }

    enum Night {
        static let moon = #colorLiteral(red: 0.8549019608, green: 0.8509803922, blue: 0.8431372549, alpha: 1)
        static let darkMoon = #colorLiteral(red: 0.5803921569, green: 0.5647058824, blue: 0.5529411765, alpha: 1)
        static let hole = #colorLiteral(red: 0.7647058824, green: 0.7607843137, blue: 0.7450980392, alpha: 1)
        static let spaceBar = #colorLiteral(red: 0.09803921569, green: 0.09411764706, blue: 0.1450980392, alpha: 1)
        static let star = PlatformColor.white
        static let mountain = #colorLiteral(red: 0.7254901961, green: 0.7647058824, blue: 0.8039215686, alpha: 1)
        static let darkMountain = #colorLiteral(red: 0.3490196078, green: 0.3764705882, blue: 0.4039215686, alpha: 1)
    }
}

enum Constant {
    static let width: CGFloat = 160
    static let height: CGFloat = 60
    static let duration: CFTimeInterval = 0.35
    static let timingFunction = CAMediaTimingFunction(name: .easeIn)
}

extension CGRect {
    func centerRect(width: CGFloat, height: CGFloat) -> CGRect {
        CGRect(x: (self.width - width) / 2 + origin.x, y: (self.height - height) / 2 + origin.y, width: width, height: height)
    }
}

open class DaySwitch: PlatformControl {
    lazy var boundsObservation = observe(\.bounds) { `self`, change in
        self.mainLayer.frame = self.bounds.centerRect(width: Constant.width, height: Constant.height)
    }

    lazy var mainLayer = CALayer()
    lazy var indicatorLayer = createIndicatorLayer()

    @objc
    open var isDayLight: Bool = true {
        didSet {
            didChangeState()
        }
    }

    public override init(frame: PlatformRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    open override var intrinsicContentSize: PlatformSize {
        PlatformSize(width: Constant.width, height: Constant.height)
    }

#if os(macOS)
    open override func viewDidMoveToSuperview() {
        platformDidMoveToSuperview()
    }
#endif
#if os(iOS)
    open override func didMoveToSuperview() {
        platformDidMoveToSuperview()
    }
#endif
}

private extension DaySwitch {
    func platformDidMoveToSuperview() {
        if superview == nil {
            return boundsObservation.invalidate()
        }
        _ = boundsObservation
    }

    func commonInit() {
#if os(macOS)
        guard let layer else {
            return
        }
        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(toggleValue(_:))))
#endif
#if os(iOS)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleValue(_:))))
#endif
        layer.addSublayer(mainLayer)
        mainLayer.frame = bounds.centerRect(width: Constant.width, height: Constant.height)
        mainLayer.cornerRadius = Constant.height / 2

        mainLayer.backgroundColor = PlatformColor.Day.spaceBar.cgColor
        mainLayer.addSublayer(indicatorLayer)

        indicatorLayer.backgroundColor = PlatformColor.Day.sun.cgColor
        indicatorLayer.sublayers?.first?.backgroundColor = PlatformColor.Day.darkSun.cgColor
    }

    func didChangeState() {
        let mainBackgroundColor = isDayLight ? PlatformColor.Day.spaceBar : PlatformColor.Night.spaceBar
        mainLayer.backgroundColor = mainBackgroundColor.cgColor
        mainLayer.add(backgroundAnimation(toValue: mainBackgroundColor), forKey: "backgroundColorAnim")

        let indicatorBackgroundColor = isDayLight ? PlatformColor.Day.sun : PlatformColor.Night.moon
        indicatorLayer.backgroundColor = indicatorBackgroundColor.cgColor
        let indicatorFrame = CGRect(x: isDayLight ? 4 : Constant.width - 4 - indicatorLayer.bounds.width, y: indicatorLayer.frame.origin.y, width: indicatorLayer.bounds.width, height: indicatorLayer.bounds.height)
        indicatorLayer.frame = indicatorFrame
        indicatorLayer.add(backgroundAnimation(toValue: indicatorBackgroundColor), forKey: "backgroundColorAnim")
        indicatorLayer.add(frameAnimation(toValue: indicatorFrame), forKey: "frameAnim")
    }

    @objc
    func toggleValue(_ gesture: PlatformGestureRecognizer) {
        switch gesture.state {
        case .ended:
            isDayLight.toggle()
        default:
            break
        }
    }

    func createIndicatorLayer() -> CALayer {
        let layer = CALayer()
        let size = Constant.height - 8
        layer.frame = CGRect(x: 4, y: 4, width: size, height: size)
        layer.cornerRadius = size / 2
        return layer
    }
}

func backgroundAnimation(toValue value: PlatformColor, duration: CFTimeInterval = Constant.duration, timingFunction: CAMediaTimingFunction = Constant.timingFunction) -> CAAnimation {
    let anim = CABasicAnimation(keyPath: "backgroundColor")
    anim.duration = duration
    anim.toValue = value.cgColor
    anim.timingFunction = timingFunction
    return anim
}

func frameAnimation(toValue value: CGRect, duration: CFTimeInterval = Constant.duration, timingFunction: CAMediaTimingFunction = Constant.timingFunction) -> CAAnimation {
    let anim = CABasicAnimation(keyPath: "frame")
    anim.duration = duration
    anim.toValue = value
    anim.timingFunction = timingFunction
    return anim
}
