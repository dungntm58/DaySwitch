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
public typealias PlatformBezierPath = NSBezierPath
#endif
#if os(iOS)
public typealias PlatformView = UIView
public typealias PlatformControl = UIControl
public typealias PlatformGestureRecognizer = UIGestureRecognizer
public typealias PlatformColor = UIColor
public typealias PlatformBezierPath = UIBezierPath
#endif

extension PlatformColor {
    enum Day {
        static let sun = #colorLiteral(red: 1, green: 0.8298229575, blue: 0.2543709278, alpha: 1)
        static let darkSun = #colorLiteral(red: 0.9254901961, green: 0.7450980392, blue: 0.2117647059, alpha: 1)
        static let sunShadow = #colorLiteral(red: 0.2823529412, green: 0.2431372549, blue: 0.1176470588, alpha: 1)
        static let spaceBar = #colorLiteral(red: 0.5411764706, green: 0.8980392157, blue: 1, alpha: 1)
        static let cloud = PlatformColor.white
        static let darkCloud = #colorLiteral(red: 0.9450980392, green: 0.9450980392, blue: 0.9450980392, alpha: 1)
    }

    enum Night {
        static let moon = #colorLiteral(red: 0.8549019608, green: 0.8509803922, blue: 0.8431372549, alpha: 1)
        static let darkMoon = #colorLiteral(red: 0.5803921569, green: 0.5647058824, blue: 0.5529411765, alpha: 1)
        static let moonShadow = PlatformColor.black
        static let hole = #colorLiteral(red: 0.7647058824, green: 0.7607843137, blue: 0.7450980392, alpha: 1)
        static let holeShadow = #colorLiteral(red: 0.337254902, green: 0.337254902, blue: 0.337254902, alpha: 1)
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
        CGRect(x: (self.width - width) * 0.5 + origin.x, y: (self.height - height) * 0.5 + origin.y, width: width, height: height)
    }
}

open class DaySwitch: PlatformControl {
    var boundsObservation: NSKeyValueObservation?

    private lazy var mainLayer = CALayer()
    private lazy var indicatorLayer = createIndicatorLayer()
    private lazy var moonHoleLayer = createMoonHoleLayer()
    private lazy var cloudLayer = createCloudLayer()
    private lazy var starLayers = [
        CGRect(x: 21, y: 8, width: 3, height: 4),
        CGRect(x: 52, y: 12, width: 6, height: 8),
        CGRect(x: 92, y: 17, width: 6, height: 6),
        CGRect(x: 28, y: 32, width: 5, height: 5),
        CGRect(x: 60, y: 34, width: 3, height: 4)
    ].map(createStarLayer)

    @objc
    open var isDayLight: Bool = true {
        didSet {
            if isDayLight == oldValue {
                return
            }
#if os(macOS)
        if let action {
            NSApp.sendAction(action, to: target, from: self)
        }
#endif
#if os(iOS)
        sendActions(for: .valueChanged)
#endif
            layoutLayer(needsAnimate: true)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    open override var intrinsicContentSize: CGSize {
        CGSize(width: Constant.width, height: Constant.height)
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
            boundsObservation?.invalidate()
            return
        }
        boundsObservation = observe(\.bounds) { `self`, _ in
            self.layoutLayer(needsAnimate: false)
        }
    }

    func commonInit() {
#if os(macOS)
        wantsLayer = true
        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(toggleValue(_:))))
        guard let layer else {
            return
        }
#endif
#if os(iOS)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleValue(_:))))
#endif
        layoutLayer(needsAnimate: false)
#if os(macOS)
        starLayers.forEach {
            $0.frame.origin.y = mainLayer.bounds.height - $0.frame.origin.y - $0.frame.height
        }
#endif
        layer.addSublayer(mainLayer)
        mainLayer.addSublayer(indicatorLayer)
        mainLayer.addSublayer(moonHoleLayer)
        indicatorLayer.sublayers?.first?.backgroundColor = PlatformColor.Day.darkSun.cgColor
        starLayers.forEach(mainLayer.addSublayer(_:))
    }

    func layoutLayer(needsAnimate: Bool) {
        updateMainLayer(needsAnimate: needsAnimate)
        updateIndicator(needsAnimate: needsAnimate)
        updateCloud(needsAnimate: needsAnimate)
        updateMoonHole(needsAnimate: needsAnimate)
        updateStars(needsAnimate: needsAnimate)
    }

    func updateMainLayer(needsAnimate: Bool) {
        let mainBackgroundColor = isDayLight ? PlatformColor.Day.spaceBar : PlatformColor.Night.spaceBar
        mainLayer.frame = bounds.centerRect(width: Constant.width, height: Constant.height)
        mainLayer.backgroundColor = mainBackgroundColor.cgColor
        mainLayer.cornerRadius = Constant.height * 0.5
        guard needsAnimate else {
            return
        }
        mainLayer.add(backgroundAnimation(toValue: mainBackgroundColor), forKey: "backgroundColorAnim")
    }

    func updateIndicator(needsAnimate: Bool) {
        let backgroundColor = isDayLight ? PlatformColor.Day.sun : PlatformColor.Night.moon
        indicatorLayer.backgroundColor = backgroundColor.cgColor
        let frame = CGRect(x: isDayLight ? 4 : mainLayer.frame.width - 4 - indicatorLayer.bounds.width, y: indicatorLayer.frame.origin.y, width: indicatorLayer.bounds.width, height: indicatorLayer.bounds.height)
        indicatorLayer.frame = frame
        let shadowColor = isDayLight ? PlatformColor.Day.sunShadow : PlatformColor.Night.moonShadow
        indicatorLayer.shadowColor = shadowColor.cgColor
        let shadowOpacity: Float = isDayLight ? 0.25 : 0.2
        indicatorLayer.shadowOpacity = shadowOpacity
#if os(macOS)
        let shadowOffset = isDayLight ? CGSize(width: 2, height: -2) : CGSize(width: -2, height: -2)
#endif
#if os(iOS)
        let shadowOffset = isDayLight ? CGSize(width: 2, height: 2) : CGSize(width: -2, height: 2)
#endif
        indicatorLayer.shadowOffset = shadowOffset

        guard needsAnimate else {
            return
        }
        indicatorLayer.add(backgroundAnimation(toValue: backgroundColor), forKey: "backgroundColorAnim")
        indicatorLayer.add(frameAnimation(toValue: frame), forKey: "frameAnim")
        shadowAnimation(toShadowColor: shadowColor, shadowOpacity: shadowOpacity, shadowOffset: shadowOffset)
            .forEach { key, value in
                indicatorLayer.add(value, forKey: key)
            }
    }

    func updateCloud(needsAnimate: Bool) {
        guard needsAnimate else {
            return
        }
    }

    func updateMoonHole(needsAnimate: Bool) {
        let opacity: Float = isDayLight ? 0 : 1
        moonHoleLayer.opacity = opacity
        let frame = CGRect(x: isDayLight ? 4 : mainLayer.frame.width - 4 - moonHoleLayer.bounds.width, y: moonHoleLayer.frame.origin.y, width: moonHoleLayer.bounds.width, height: moonHoleLayer.bounds.height)
        moonHoleLayer.frame = frame
        guard needsAnimate else {
            return
        }
        moonHoleLayer.add(opacityAnimation(toValue: opacity), forKey: "opacityAnim")
        indicatorLayer.add(frameAnimation(toValue: frame), forKey: "frameAnim")
    }

    func updateStars(needsAnimate: Bool) {
        let opacity: Float = isDayLight ? 0 : 1
        starLayers.forEach { $0.opacity = opacity }
        guard needsAnimate else {
            return
        }
        let opacityAnim = opacityAnimation(toValue: opacity)
        starLayers.forEach {
            $0.add(opacityAnim, forKey: "opacityAnim")
        }
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
        let size = mainLayer.bounds.height - 8
        layer.frame = CGRect(x: 4, y: 4, width: size, height: size)
        layer.cornerRadius = size * 0.5
        layer.shadowRadius = 2
        return layer
    }

    func createCloudLayer() -> CALayer {
        let layer = CALayer()
        return layer
    }

    func createMoonHoleLayer() -> CALayer {
        let layer = CALayer()
        let size = mainLayer.bounds.height - 8
        layer.frame = CGRect(x: 4, y: 4, width: size, height: size)

        let hole1 = CAShapeLayer()
        hole1.backgroundColor = PlatformColor.Night.hole.cgColor
        layer.addSublayer(hole1)

        let hole2 = CAShapeLayer()
        hole2.backgroundColor = PlatformColor.Night.hole.cgColor
        layer.addSublayer(hole2)

        let hole3 = CAShapeLayer()
        hole3.backgroundColor = PlatformColor.Night.hole.cgColor
        layer.addSublayer(hole3)

#if os(macOS)
        hole1.frame = CGRect(x: 13, y: size - 11 - 12, width: 12, height: 12)
        hole2.frame = CGRect(x: 35, y: size - 18 - 13, width: 13, height: 13)
        hole3.frame = CGRect(x: 22, y: size - 34 - 8, width: 8, height: 8)
#endif
#if os(iOS)
        hole1.frame = CGRect(x: 13, y: 11, width: 12, height: 12)
        hole2.frame = CGRect(x: 35, y: 18, width: 13, height: 13)
        hole3.frame = CGRect(x: 22, y: 34, width: 8, height: 8)
#endif
        hole1.cornerRadius = hole1.frame.width * 0.5
        hole2.cornerRadius = hole2.frame.width * 0.5
        hole3.cornerRadius = hole3.frame.width * 0.5

        return layer
    }

    func createStarLayer(frame: CGRect) -> CALayer {
        let layer = CAShapeLayer()
        layer.fillColor = PlatformColor.Night.star.cgColor
        layer.frame = frame
        let path = CGMutablePath()
        path.move(to: CGPoint(x: frame.width * 0.5, y: 0))
        let controlPoint = CGPoint(x: frame.width * 0.5, y: frame.height * 0.5)
        path.addCurve(to: CGPoint(x: 0, y: frame.height * 0.5), control1: controlPoint, control2: controlPoint)
        path.addCurve(to: CGPoint(x: frame.width * 0.5, y: frame.height), control1: controlPoint, control2: controlPoint)
        path.addCurve(to: CGPoint(x: frame.width, y: frame.height * 0.5), control1: controlPoint, control2: controlPoint)
        path.addCurve(to: CGPoint(x: frame.width * 0.5, y: 0), control1: controlPoint, control2: controlPoint)
        layer.path = path
        return layer
    }
}

func animation(keyPath: String, toValue value: Any?, duration: CFTimeInterval, timingFunction: CAMediaTimingFunction) -> CAAnimation {
    let anim = CABasicAnimation(keyPath: keyPath)
    anim.duration = duration
    anim.toValue = value
    anim.timingFunction = timingFunction
    return anim
}

func shadowAnimation(toShadowColor color: PlatformColor? = nil, shadowOpacity: Float? = nil, shadowOffset: CGSize? = nil, duration: CFTimeInterval = Constant.duration, timingFunction: CAMediaTimingFunction = Constant.timingFunction) -> [String: CAAnimation] {
    var dict: [String: CAAnimation] = [:]
    dict["shadowColorAnim"] = color.flatMap { animation(keyPath: "shadowColor", toValue: $0.cgColor, duration: duration, timingFunction: timingFunction) }
    dict["shadowOpacityAnim"] = shadowOpacity.flatMap { animation(keyPath: "shadowOpacity", toValue: $0, duration: duration, timingFunction: timingFunction) }
    dict["shadowOffsetAnim"] = shadowOffset.flatMap { animation(keyPath: "shadowOffset", toValue: $0, duration: duration, timingFunction: timingFunction) }
    return dict
}

func backgroundAnimation(toValue value: PlatformColor, duration: CFTimeInterval = Constant.duration, timingFunction: CAMediaTimingFunction = Constant.timingFunction) -> CAAnimation {
    animation(keyPath: "backgroundColor", toValue: value.cgColor, duration: duration, timingFunction: timingFunction)
}

func frameAnimation(toValue value: CGRect, duration: CFTimeInterval = Constant.duration, timingFunction: CAMediaTimingFunction = Constant.timingFunction) -> CAAnimation {
    animation(keyPath: "frame", toValue: value, duration: duration, timingFunction: timingFunction)
}

func opacityAnimation(toValue value: Float, duration: CFTimeInterval = Constant.duration, timingFunction: CAMediaTimingFunction = Constant.timingFunction) -> CAAnimation {
    animation(keyPath: "opacity", toValue: value, duration: duration, timingFunction: timingFunction)
}

extension CGRect {
    func multiply(by value: CGFloat) -> CGRect {
        .init(x: origin.x * value, y: origin.y * value, width: width * value, height: height * value)
    }
}

extension CGSize {
    func multiply(by value: CGFloat) -> CGSize {
        .init(width: width * value, height: height * value)
    }
}
