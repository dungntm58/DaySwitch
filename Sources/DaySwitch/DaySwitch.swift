//
//  DaySwitch.swift
//  DaySwitch
//
//  Created by Robert on 01/05/2023.
//

#if os(macOS)
import AppKit

public typealias PlatformView = NSView
public typealias PlatformControl = NSControl
public typealias PlatformGestureRecognizer = NSGestureRecognizer
public typealias PlatformColor = NSColor
#elseif os(iOS)
import UIKit

public typealias PlatformView = UIView
public typealias PlatformControl = UIControl
public typealias PlatformGestureRecognizer = UIGestureRecognizer
public typealias PlatformColor = UIColor
#else
#error("DaySwitch supports macOS and iOS only")
#endif

private extension PlatformColor {
    enum Day {
        static let sun = #colorLiteral(red: 1, green: 0.8298229575, blue: 0.2543709278, alpha: 1)
        static let sunShadow = #colorLiteral(red: 0.2823529412, green: 0.2431372549, blue: 0.1176470588, alpha: 1)
        static let spaceBar = #colorLiteral(red: 0.5411764706, green: 0.8980392157, blue: 1, alpha: 1)
    }

    enum Night {
        static let moon = #colorLiteral(red: 0.8549019608, green: 0.8509803922, blue: 0.8431372549, alpha: 1)
        static let moonShadow = PlatformColor.black
        static let hole = #colorLiteral(red: 0.7647058824, green: 0.7607843137, blue: 0.7450980392, alpha: 1)
        static let spaceBar = #colorLiteral(red: 0.09803921569, green: 0.09411764706, blue: 0.1450980392, alpha: 1)
    }
}

enum Constant {
    static let width: CGFloat = 160
    static let height: CGFloat = 60
    static let cornerRadius = height / 2
    /// Gap between the track edge and the indicator.
    static let inset: CGFloat = 4
    static let indicatorSize = height - inset * 2
    static let shadowRadius: CGFloat = 2
    static let duration: CFTimeInterval = 0.35
    static let timingFunction = CAMediaTimingFunction(name: .easeIn)

    /// Moon craters, in top-left coordinates relative to the indicator.
    static let moonHoles: [(x: CGFloat, y: CGFloat, diameter: CGFloat)] = [
        (13, 11, 12),
        (35, 18, 16),
        (22, 34, 8),
    ]

    /// AppKit lays out layers from the bottom-left, UIKit from the top-left. The
    /// two declarations below are that same flip, kept here so no drawing code
    /// has to restate it.
#if os(macOS)
    static let shadowDrop: CGFloat = -2
#else
    static let shadowDrop: CGFloat = 2
#endif

    /// Converts a top-anchored `y` into the platform's layer coordinate space.
    static func y(fromTop top: CGFloat, height: CGFloat, in container: CGFloat) -> CGFloat {
#if os(macOS)
        container - top - height
#else
        top
#endif
    }
}

private extension CGRect {
    func centerRect(width: CGFloat, height: CGFloat) -> CGRect {
        insetBy(dx: (self.width - width) / 2, dy: (self.height - height) / 2)
    }
}

private extension CALayer {
    /// Keys the animation on `<keyPath>Anim`, so the key and the property it
    /// animates cannot drift apart.
    func animate(_ keyPath: String, to value: Any?) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = Constant.duration
        animation.toValue = value
        animation.timingFunction = Constant.timingFunction
        add(animation, forKey: keyPath + "Anim")
    }
}

open class DaySwitch: PlatformControl {
    private lazy var mainLayer = createMainLayer()
    private lazy var innerShadowLayer = createInnerShadowLayer()
    private lazy var indicatorLayer = createIndicatorLayer()
    private lazy var moonHoleLayer = createMoonHoleLayer()

    @objc
    open var isDayLight: Bool = true {
        didSet {
            guard isDayLight != oldValue else {
                return
            }
#if os(macOS)
            if let action {
                NSApp.sendAction(action, to: target, from: self)
            }
#else
            sendActions(for: .valueChanged)
#endif
            applyState(needsAnimate: true)
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
    open override func layout() {
        super.layout()
        layoutMainLayer()
    }

    open override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        updateContentsScale()
    }
#else
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutMainLayer()
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        updateContentsScale()
    }
#endif
}

private extension DaySwitch {
    func commonInit() {
#if os(macOS)
        wantsLayer = true
        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(toggleValue(_:))))
        guard let layer else {
            return
        }
#else
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleValue(_:))))
#endif
        layer.addSublayer(mainLayer)
        mainLayer.addSublayer(innerShadowLayer)
        mainLayer.addSublayer(indicatorLayer)
        // The holes are a child of the indicator, so they ride it for free — both
        // at rest and through the slide animation.
        indicatorLayer.addSublayer(moonHoleLayer)

        layoutMainLayer()
        applyState(needsAnimate: false)
        updateContentsScale()
    }

    /// `mainLayer` is the only layer whose geometry depends on `bounds`; every
    /// other layer is sized from `Constant` and positioned within it.
    func layoutMainLayer() {
        mainLayer.frame = bounds.centerRect(width: Constant.width, height: Constant.height)
    }

    func applyState(needsAnimate: Bool) {
        updateMainLayer(needsAnimate: needsAnimate)
        updateIndicator(needsAnimate: needsAnimate)
        updateMoonHole(needsAnimate: needsAnimate)
    }

    func updateMainLayer(needsAnimate: Bool) {
        let backgroundColor = isDayLight ? PlatformColor.Day.spaceBar : PlatformColor.Night.spaceBar
        mainLayer.backgroundColor = backgroundColor.cgColor
        guard needsAnimate else {
            return
        }
        mainLayer.animate("backgroundColor", to: backgroundColor.cgColor)
    }

    func updateIndicator(needsAnimate: Bool) {
        let backgroundColor = isDayLight ? PlatformColor.Day.sun : PlatformColor.Night.moon
        let shadowColor = isDayLight ? PlatformColor.Day.sunShadow : PlatformColor.Night.moonShadow
        let shadowOpacity: Float = isDayLight ? 0.25 : 0.2
        let shadowOffset = CGSize(width: isDayLight ? 2 : -2, height: Constant.shadowDrop)
        var frame = indicatorLayer.frame
        frame.origin.x = isDayLight ? Constant.inset : Constant.width - Constant.inset - frame.width

        indicatorLayer.backgroundColor = backgroundColor.cgColor
        indicatorLayer.frame = frame
        indicatorLayer.shadowColor = shadowColor.cgColor
        indicatorLayer.shadowOpacity = shadowOpacity
        indicatorLayer.shadowOffset = shadowOffset

        guard needsAnimate else {
            return
        }
        indicatorLayer.animate("backgroundColor", to: backgroundColor.cgColor)
        indicatorLayer.animate("frame", to: frame)
        indicatorLayer.animate("shadowColor", to: shadowColor.cgColor)
        indicatorLayer.animate("shadowOpacity", to: shadowOpacity)
        indicatorLayer.animate("shadowOffset", to: shadowOffset)
    }

    func updateMoonHole(needsAnimate: Bool) {
        let opacity: Float = isDayLight ? 0 : 1
        moonHoleLayer.opacity = opacity
        guard needsAnimate else {
            return
        }
        moonHoleLayer.animate("opacity", to: opacity)
    }

    /// Layers created in code default to `contentsScale` 1, so a `CAShapeLayer` rasterises
    /// its path at 1x and gets scaled up on a retina display. Against `mainLayer`, whose
    /// `cornerRadius` the compositor draws at device resolution, that mismatch shows up as
    /// stair-stepping along the curves.
    func updateContentsScale() {
        let scale = platformScale
        guard innerShadowLayer.contentsScale != scale else {
            return
        }
        innerShadowLayer.contentsScale = scale
        innerShadowLayer.mask?.contentsScale = scale
    }

    var platformScale: CGFloat {
#if os(macOS)
        window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
#else
        let scale = traitCollection.displayScale
        return scale > 0 ? scale : 2
#endif
    }

    @objc
    func toggleValue(_ gesture: PlatformGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        isDayLight.toggle()
    }

    func createMainLayer() -> CALayer {
        let layer = CALayer()
        layer.cornerRadius = Constant.cornerRadius
        return layer
    }

    func createInnerShadowLayer() -> CAShapeLayer {
        let rect = CGRect(x: 0, y: 0, width: Constant.width, height: Constant.height)
        let radius = Constant.cornerRadius

        // Even-odd fill of "everything outside the capsule" casts its shadow inwards,
        // the mask then keeps only the part that falls inside the capsule.
        //
        // The hole is nudged one point out so the opaque fill stops short of the
        // mask's antialiased rim. Where the two edges overlap they multiply
        // (fill alpha * mask alpha) and leave a seam along the curves.
        let inset: CGFloat = 1
        let holeRect = rect.insetBy(dx: -inset, dy: -inset)
        let path = CGMutablePath()
        path.addRect(rect.insetBy(dx: -radius, dy: -radius))
        path.addPath(CGPath(roundedRect: holeRect, cornerWidth: radius + inset, cornerHeight: radius + inset, transform: nil))

        let mask = CAShapeLayer()
        mask.frame = rect
        mask.path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

        let layer = CAShapeLayer()
        layer.frame = rect
        layer.path = path
        layer.fillRule = .evenOdd
        layer.fillColor = PlatformColor.black.cgColor
        layer.shadowColor = PlatformColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowOpacity = 0.2
        layer.shadowRadius = Constant.shadowRadius
        layer.mask = mask
        return layer
    }

    func createIndicatorLayer() -> CALayer {
        let size = Constant.indicatorSize
        let layer = CALayer()
        layer.frame = CGRect(x: Constant.inset, y: Constant.inset, width: size, height: size)
        layer.cornerRadius = size / 2
        layer.shadowRadius = Constant.shadowRadius
        // The silhouette is a known circle, so hand it over rather than making
        // Core Animation blur the layer's alpha channel offscreen every frame.
        layer.shadowPath = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: size, height: size), transform: nil)
        return layer
    }

    func createMoonHoleLayer() -> CALayer {
        let size = Constant.indicatorSize
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: size, height: size)
        for hole in Constant.moonHoles {
            let holeLayer = CALayer()
            holeLayer.backgroundColor = PlatformColor.Night.hole.cgColor
            holeLayer.frame = CGRect(x: hole.x,
                                     y: Constant.y(fromTop: hole.y, height: hole.diameter, in: size),
                                     width: hole.diameter,
                                     height: hole.diameter)
            holeLayer.cornerRadius = hole.diameter / 2
            layer.addSublayer(holeLayer)
        }
        return layer
    }
}
