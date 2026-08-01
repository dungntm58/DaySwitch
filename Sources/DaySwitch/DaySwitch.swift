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
        static let sunRim = #colorLiteral(red: 0.9254901961, green: 0.7450980392, blue: 0.2117647059, alpha: 1)
        static let sunShadow = #colorLiteral(red: 0.2823529412, green: 0.2431372549, blue: 0.1176470588, alpha: 1)
        static let spaceBar = #colorLiteral(red: 0.5411764706, green: 0.8980392157, blue: 1, alpha: 1)
        static let cloud = PlatformColor.white
        /// "Dark Cloud" in the design: the layer that trails the white one.
        static let cloudShade = #colorLiteral(red: 0.9450980392, green: 0.9450980392, blue: 0.9450980392, alpha: 1)
    }

    enum Night {
        static let moon = #colorLiteral(red: 0.8549019608, green: 0.8509803922, blue: 0.8431372549, alpha: 1)
        static let moonRim = #colorLiteral(red: 0.5803921569, green: 0.5647058824, blue: 0.5529411765, alpha: 1)
        static let moonShadow = PlatformColor.black
        static let hole = #colorLiteral(red: 0.7647058824, green: 0.7607843137, blue: 0.7450980392, alpha: 1)
        static let spaceBar = #colorLiteral(red: 0.09803921569, green: 0.09411764706, blue: 0.1450980392, alpha: 1)
        static let mountain = #colorLiteral(red: 0.7254901961, green: 0.7647058824, blue: 0.8039215686, alpha: 1)
        /// The range behind, dark enough to read as further off.
        static let mountainFar = #colorLiteral(red: 0.3490196078, green: 0.3764705882, blue: 0.4039215686, alpha: 1)
        static let star = #colorLiteral(red: 0.8509803922, green: 0.8509803922, blue: 0.8509803922, alpha: 1)
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
    /// Idle motion swings out and comes back, so it wants to ease out of each end of
    /// the swing as well as into it.
    static let idleTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

    /// A circle anchored by the top-left corner of its bounding box.
    typealias Circle = (x: CGFloat, y: CGFloat, diameter: CGFloat)

    /// Moon craters, in top-left coordinates relative to the indicator.
    static let moonHoles: [Circle] = [
        (13, 11, 12),
        (35, 18, 16),
        (22, 34, 8),
    ]

    /// The two cloud layers, in top-left coordinates relative to the track. Each
    /// cloud is the union of its puffs; the shade is the same shape grown a couple
    /// of points, so it reads as a lip along the top-left of the white one. Both
    /// run off the track and get clipped back to it.
    ///
    /// The design places the track at (8, 17) on its canvas and draws at the same
    /// scale, so these are the design's numbers less that origin.
    static let cloud: [Circle] = [
        (55, 48, 18),
        (66, 42, 23),
        (81, 21, 64),
        (139, 35, 25),
    ]

    static let cloudShade: [Circle] = [
        (52, 44, 22),
        (64, 38, 26),
        (79, 17, 68),
        (137, 31, 29),
    ]

    /// A bird glyph anchored by the top-left corner of its box. `width` scales the
    /// glyph, which is otherwise fixed.
    typealias Bird = (x: CGFloat, y: CGFloat, width: CGFloat)

    /// Birds, in the same top-left track coordinates as the clouds.
    static let birds: [Bird] = [
        (130, 13, 8),
        (144, 15, 8),
        (137, 20, 6),
    ]

    /// The glyph is authored this wide and scaled from there; `birdDepth` is how
    /// far the band drops below the curve that shapes it.
    static let birdWidth: CGFloat = 8
    static let birdDepth: CGFloat = 1

    /// A wingbeat carries the tips this far either side of the resting glyph, in the
    /// same authored units as `birdWidth`, and takes this long to get from one end of
    /// the swing to the other, so a whole beat is twice that.
    static let birdSwing: CGFloat = 1.5
    static let birdFlapDuration: CFTimeInterval = 0.3

    /// The ridge line of the near range, in the same top-left track coordinates as
    /// the clouds. Closing the shape draws a straight line from the last point back
    /// to the first, so both ends sit below the track and the fill runs off it, the
    /// way the clouds run off the sides.
    static let ridge: [CGPoint] = [
        CGPoint(x: -2.9, y: 62),
        CGPoint(x: 16.5, y: 25),
        CGPoint(x: 20.2, y: 44.7),
        CGPoint(x: 23, y: 34.3),
        CGPoint(x: 30.4, y: 55.5),
        CGPoint(x: 37, y: 43),
        CGPoint(x: 39.9, y: 49.8),
        CGPoint(x: 43.6, y: 37.2),
        CGPoint(x: 56.6, y: 53.1),
        CGPoint(x: 61, y: 41.1),
        CGPoint(x: 84.2, y: 62),
    ]

    /// The range behind the first one. It is mostly hidden, and shows as an edge
    /// along the near range's slopes wherever these peaks clear them.
    static let farRidge: [CGPoint] = [
        CGPoint(x: 24, y: 62),
        CGPoint(x: 37, y: 40.2),
        CGPoint(x: 45.5, y: 49),
        CGPoint(x: 52.6, y: 41.8),
        CGPoint(x: 57.6, y: 52.1),
        CGPoint(x: 68, y: 43.8),
        CGPoint(x: 83.2, y: 62),
    ]

    /// A four-pointed star. Unlike the clouds and the birds it is anchored by its
    /// centre, which is what the glyph is symmetric about.
    typealias Star = (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)

    /// Stars, in the same top-left track coordinates as the clouds.
    static let stars: [Star] = [
        (22.5, 10, 2.1, 3.1),
        (34.5, 30.5, 4, 4),
        (55, 16, 4.9, 6.5),
        (61.5, 36, 2.1, 3.1),
        (87, 20, 5, 5),
    ]

    /// How far the control point between two arms sits from the centre, as a
    /// fraction of the arm: 0 pinches the sides all the way in, 0.5 leaves them
    /// straight and the star a diamond.
    static let starPinch: CGFloat = 0.2

    /// A blink takes a star down to `starDim` and back. Each star takes
    /// `starBlinkSpread` longer over it than the one before, so the field drifts out
    /// of step instead of pulsing as one.
    static let starDim: Float = 0.15
    static let starBlinkDuration: CFTimeInterval = 0.85
    static let starBlinkSpread: CFTimeInterval = 0.19

    /// The halo around the sun: a glow that leaves the sun's rim at full strength and
    /// falls away from there, so it shims into the disc instead of ringing it. The
    /// indicator and the track's left cap are concentric — the sun's rim sits 26 out
    /// from the centre and the cap 30 — so the band it has to work in is even the whole
    /// way round. It reaches past that band, which is what keeps the falloff still
    /// going where the capsule cuts it off rather than stopping short of the edge.
    static let sunHaloCenter = CGPoint(x: inset + indicatorSize / 2, y: height / 2)
    static let sunHaloReach: (rest: CGFloat, swell: CGFloat) = (31, 36)
    static let sunHaloOpacity: (rest: CGFloat, swell: CGFloat) = (0.35, 0.75)
    /// Half a breath: the glow swells and settles back over twice this.
    static let sunHaloDuration: CFTimeInterval = 1.1

    /// Where a scene's figures head as it gives way to the other one, in track points
    /// from where they rest. Downward-positive, like `shadowDrop`. The birds climb out
    /// of the top-right corner and the cloud slides off the right edge, both away from
    /// the sun they leave behind; the ranges go the other way, off the left edge they
    /// already sit against. The crossfade runs alongside, so none of them has to reach
    /// cover.
    static let cloudExit = CGSize(width: 34, height: 0)
    static let birdExit = CGSize(width: 26, height: -24)
    static let rangeExit = CGSize(width: -34, height: 0)
    /// The halo belongs to the sun rather than to the sky, so it leaves with it: the
    /// same trip the indicator makes from one end of the track to the other.
    static let sunHaloExit = CGSize(width: width - inset * 2 - indicatorSize, height: 0)

    /// How far the lit face sits from the rim behind it: `width` points away from
    /// the shadow, `height` points up. What the face leaves uncovered is the rim,
    /// a thin crescent hugging the shaded edge. Downward-positive, like `shadowDrop`.
    static let faceOffset = CGSize(width: 1, height: -2)

    // AppKit lays out layers from the bottom-left, UIKit from the top-left. The
    // declarations below are that same flip, kept here so no drawing code has to
    // restate it.

    /// Converts a downward-positive offset into the platform's layer coordinate space.
    static func vertical(_ downward: CGFloat) -> CGFloat {
#if os(macOS)
        -downward
#else
        downward
#endif
    }

    static let shadowDrop = vertical(2)

    /// A downward-positive offset as a layer transform in the platform's coordinate space.
    static func translation(_ offset: CGSize) -> CATransform3D {
        CATransform3DMakeTranslation(offset.width, vertical(offset.height), 0)
    }

    /// Converts a top-anchored `y` into the platform's layer coordinate space.
    static func y(fromTop top: CGFloat, height: CGFloat, in container: CGFloat) -> CGFloat {
#if os(macOS)
        container - top - height
#else
        top
#endif
    }

    /// The same flip for paths, which cannot be repositioned a rect at a time.
    static func topLeftTransform(in container: CGFloat) -> CGAffineTransform {
#if os(macOS)
        CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: container)
#else
        .identity
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

    /// The same for motion that never settles: the property swings between the two
    /// values for as long as the layer is around, `duration` to a swing, starting
    /// `phase` of the way through one. Only the presented value moves, so the layer
    /// still reads as the design has it.
    func loop(_ keyPath: String, from: Any?, to: Any?, duration: CFTimeInterval, phase: Double = 0) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = duration
        animation.fromValue = from
        animation.toValue = to
        animation.timingFunction = Constant.idleTimingFunction
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timeOffset = duration * phase
        add(animation, forKey: keyPath + "Loop")
    }
}

open class DaySwitch: PlatformControl {
    private lazy var mainLayer = createMainLayer()
    // The figures are held on to a scene at a time: each group leaves its own way
    // when the scene it belongs to does.
    // The halo rides above the track's inner shadow rather than in the day scene, so
    // it needs a clip of its own; the glow inside it is what moves and breathes.
    private lazy var sunHaloLayer = createSunHaloLayer()
    private lazy var sunHaloClipLayer = createSceneryLayer([sunHaloLayer])
    private lazy var cloudLayers = [createPuffLayer(Constant.cloudShade, color: PlatformColor.Day.cloudShade),
                                    createPuffLayer(Constant.cloud, color: PlatformColor.Day.cloud)]
    private lazy var birdLayers = Constant.birds.map(createBirdLayer)
    private lazy var starLayers = Constant.stars.map(createStarLayer)
    private lazy var rangeLayers = [createRidgeLayer(Constant.farRidge, color: PlatformColor.Night.mountainFar),
                                    createRidgeLayer(Constant.ridge, color: PlatformColor.Night.mountain)]
    private lazy var daySceneryLayer = createSceneryLayer(cloudLayers + birdLayers)
    private lazy var nightSceneryLayer = createSceneryLayer(starLayers + rangeLayers)
    private lazy var innerShadowLayer = createInnerShadowLayer()
    private lazy var indicatorLayer = createIndicatorLayer()
    private lazy var moonHoleLayer = createMoonHoleLayer()
    private lazy var rimLayer = createRimLayer()

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
        // Scenery, so it goes under the track's own shading and under the indicator.
        mainLayer.addSublayer(daySceneryLayer)
        mainLayer.addSublayer(nightSceneryLayer)
        mainLayer.addSublayer(innerShadowLayer)
        // Over that shadow: the halo works the same band of track the shadow darkens,
        // and underneath it the glow comes out grubby rather than bright.
        mainLayer.addSublayer(sunHaloClipLayer)
        mainLayer.addSublayer(indicatorLayer)
        // The holes and the rim are children of the indicator, so they ride it for
        // free — both at rest and through the slide animation.
        indicatorLayer.addSublayer(moonHoleLayer)
        indicatorLayer.addSublayer(rimLayer)

        layoutMainLayer()
        applyState(needsAnimate: false)
        updateContentsScale()
        startIdleAnimations()
#if os(iOS)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(startIdleAnimations),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
#endif
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
        updateRim(needsAnimate: needsAnimate)
        updateScenery(needsAnimate: needsAnimate)
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

    func updateScenery(needsAnimate: Bool) {
        let dayOpacity: Float = isDayLight ? 1 : 0
        let nightOpacity: Float = 1 - dayOpacity
        daySceneryLayer.opacity = dayOpacity
        nightSceneryLayer.opacity = nightOpacity
        // The clip carries the crossfade, which leaves the glow's own opacity free to
        // do nothing but breathe.
        sunHaloClipLayer.opacity = dayOpacity
        updateExit(of: [sunHaloLayer], by: Constant.sunHaloExit, isShowing: isDayLight, needsAnimate: needsAnimate)
        updateExit(of: cloudLayers, by: Constant.cloudExit, isShowing: isDayLight, needsAnimate: needsAnimate)
        updateExit(of: birdLayers, by: Constant.birdExit, isShowing: isDayLight, needsAnimate: needsAnimate)
        updateExit(of: rangeLayers, by: Constant.rangeExit, isShowing: !isDayLight, needsAnimate: needsAnimate)
        guard needsAnimate else {
            return
        }
        daySceneryLayer.animate("opacity", to: dayOpacity)
        nightSceneryLayer.animate("opacity", to: nightOpacity)
        sunHaloClipLayer.animate("opacity", to: dayOpacity)
    }

    /// Figures sit where the design puts them while their scene is showing and off by
    /// `offset` while it is not, so a switch carries them out that way and a switch
    /// back brings them in from it, under the crossfade either way. The stars are left
    /// out: they have nowhere to go, they only fade.
    func updateExit(of layers: [CALayer], by offset: CGSize, isShowing: Bool, needsAnimate: Bool) {
        let transform = isShowing ? CATransform3DIdentity : Constant.translation(offset)
        for layer in layers {
            layer.transform = transform
            guard needsAnimate else {
                continue
            }
            layer.animate("transform", to: transform)
        }
    }

    func updateRim(needsAnimate: Bool) {
        let fillColor = isDayLight ? PlatformColor.Day.sunRim : PlatformColor.Night.moonRim
        let path = rimPath()

        rimLayer.fillColor = fillColor.cgColor
        rimLayer.path = path

        guard needsAnimate else {
            return
        }
        rimLayer.animate("fillColor", to: fillColor.cgColor)
        rimLayer.animate("path", to: path)
    }

    /// The indicator circle with the lit face punched out of it. The face sits on
    /// the side the light comes from, so the crescent left over is the far edge.
    func rimPath() -> CGPath {
        let size = Constant.indicatorSize
        let circle = CGRect(x: 0, y: 0, width: size, height: size)
        let face = circle.offsetBy(dx: isDayLight ? -Constant.faceOffset.width : Constant.faceOffset.width,
                                   dy: Constant.vertical(Constant.faceOffset.height))

        let path = CGMutablePath()
        path.addEllipse(in: circle)
        path.addEllipse(in: face)
        return path
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
        let scenery = [daySceneryLayer, nightSceneryLayer, sunHaloClipLayer]
        for layer in [innerShadowLayer, rimLayer] + scenery + scenery.flatMap({ $0.sublayers ?? [] }) {
            layer.contentsScale = scale
            layer.mask?.contentsScale = scale
        }
    }

    var platformScale: CGFloat {
#if os(macOS)
        window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
#else
        let scale = traitCollection.displayScale
        return scale > 0 ? scale : 2
#endif
    }

    /// The motion each scene keeps up while it is showing: the birds beat their wings
    /// and the stars blink, each slightly out of step with the rest of its group so
    /// neither reads as one figure repeated. iOS strips animations off layers when the
    /// app goes to the background, so this runs again on the way back rather than only
    /// at setup.
    @objc
    func startIdleAnimations() {
        // Both halves of the breath run off the one duration, so the glow reaches its
        // furthest exactly when it is at its brightest.
        sunHaloLayer.loop("locations",
                          from: sunHaloLocations(reach: Constant.sunHaloReach.rest),
                          to: sunHaloLocations(reach: Constant.sunHaloReach.swell),
                          duration: Constant.sunHaloDuration)
        sunHaloLayer.loop("colors",
                          from: sunHaloColors(alpha: Constant.sunHaloOpacity.rest),
                          to: sunHaloColors(alpha: Constant.sunHaloOpacity.swell),
                          duration: Constant.sunHaloDuration)
        for (index, (bird, layer)) in zip(Constant.birds, birdLayers).enumerated() {
            layer.loop("path",
                       from: birdPath(bird, swing: -Constant.birdSwing),
                       to: birdPath(bird, swing: Constant.birdSwing),
                       duration: Constant.birdFlapDuration,
                       phase: Double(index) / Double(birdLayers.count))
        }
        for (index, layer) in starLayers.enumerated() {
            layer.loop("opacity",
                       from: Float(1),
                       to: Constant.starDim,
                       duration: Constant.starBlinkDuration + Double(index) * Constant.starBlinkSpread,
                       phase: Double(index) / Double(starLayers.count))
        }
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

    /// Figures, back to front, clipped to the track: a whole scene of them, or the one
    /// the halo amounts to. The clip stays put while what is inside it moves, which is
    /// what lets a figure run off the track and be trimmed by it.
    func createSceneryLayer(_ figures: [CALayer]) -> CALayer {
        let rect = CGRect(x: 0, y: 0, width: Constant.width, height: Constant.height)
        let radius = Constant.cornerRadius

        let mask = CAShapeLayer()
        mask.frame = rect
        mask.path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

        let layer = CALayer()
        layer.frame = rect
        layer.mask = mask
        for figure in figures {
            layer.addSublayer(figure)
        }
        return layer
    }

    func createRidgeLayer(_ ridge: [CGPoint], color: PlatformColor) -> CAShapeLayer {
        let path = CGMutablePath()
        path.addLines(between: ridge, transform: Constant.topLeftTransform(in: Constant.height))
        path.closeSubpath()

        let layer = CAShapeLayer()
        layer.frame = CGRect(x: 0, y: 0, width: Constant.width, height: Constant.height)
        layer.path = path
        layer.fillColor = color.cgColor
        return layer
    }

    /// One star. They never overlap, so a single path could draw them all, but they
    /// blink on their own schedules and an opacity is a per-layer thing.
    func createStarLayer(_ star: Constant.Star) -> CAShapeLayer {
        let transform = Constant.topLeftTransform(in: Constant.height)

        // Four arms out to the tips, each neighbouring pair joined by a curve that
        // pulls back in towards the centre, which is what tapers the arms to points.
        let (armX, armY) = (star.width / 2, star.height / 2)
        let (pinchX, pinchY) = (armX * Constant.starPinch, armY * Constant.starPinch)
        let tips = [CGPoint(x: star.x, y: star.y - armY),
                    CGPoint(x: star.x + armX, y: star.y),
                    CGPoint(x: star.x, y: star.y + armY),
                    CGPoint(x: star.x - armX, y: star.y)]
        let pinches = [CGPoint(x: star.x + pinchX, y: star.y - pinchY),
                       CGPoint(x: star.x + pinchX, y: star.y + pinchY),
                       CGPoint(x: star.x - pinchX, y: star.y + pinchY),
                       CGPoint(x: star.x - pinchX, y: star.y - pinchY)]

        let path = CGMutablePath()
        path.move(to: tips[0], transform: transform)
        for (index, pinch) in pinches.enumerated() {
            path.addQuadCurve(to: tips[(index + 1) % tips.count], control: pinch, transform: transform)
        }
        path.closeSubpath()

        let layer = CAShapeLayer()
        layer.frame = CGRect(x: 0, y: 0, width: Constant.width, height: Constant.height)
        layer.path = path
        layer.fillColor = PlatformColor.Night.star.cgColor
        return layer
    }

    /// The sun's halo. White, the same as the cloud and the birds, so that thinning it
    /// reads as brightness rather than as a colour of its own — the sun's yellow thinned
    /// over this sky turns green, since the sky's green channel already outruns it.
    ///
    /// Centred on the sun, so it needs no flipping: the track's midline is the same
    /// distance from either edge.
    func createSunHaloLayer() -> CAGradientLayer {
        let reach = Constant.sunHaloReach.swell
        let center = Constant.sunHaloCenter

        let layer = CAGradientLayer()
        layer.frame = CGRect(x: center.x - reach, y: center.y - reach, width: reach * 2, height: reach * 2)
        // A radial gradient runs from `startPoint` out to the ellipse `endPoint` traces,
        // both in unit coordinates, so these two describe a circle of `reach` about the
        // centre of a layer that is twice that across.
        layer.type = .radial
        layer.startPoint = CGPoint(x: 0.5, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 1)
        layer.colors = sunHaloColors(alpha: Constant.sunHaloOpacity.rest)
        layer.locations = sunHaloLocations(reach: Constant.sunHaloReach.rest)
        return layer
    }

    /// White fading to a transparent white rather than to `clear`, which is a
    /// transparent black and would drag the falloff through grey on its way out.
    func sunHaloColors(alpha: CGFloat) -> [CGColor] {
        [PlatformColor.Day.cloud.withAlphaComponent(alpha).cgColor,
         PlatformColor.Day.cloud.withAlphaComponent(0).cgColor]
    }

    /// Full strength out to the sun's rim, where the disc stops covering it, and spent
    /// by `reach`. Both as fractions of the layer, which spans the furthest it can reach.
    func sunHaloLocations(reach: CGFloat) -> [NSNumber] {
        let extent = Constant.sunHaloReach.swell
        return [NSNumber(value: Double(Constant.indicatorSize / 2 / extent)),
                NSNumber(value: Double(reach / extent))]
    }

    func createBirdLayer(_ bird: Constant.Bird) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.frame = CGRect(x: 0, y: 0, width: Constant.width, height: Constant.height)
        layer.path = birdPath(bird)
        layer.fillColor = PlatformColor.Day.cloud.cgColor
        return layer
    }

    /// The bird glyph, its wings carried `swing` points from where the design rests
    /// them. Every swing draws the same run of segments, so one path tweens into the
    /// next and the wings read as beating rather than cutting from pose to pose.
    func birdPath(_ bird: Constant.Bird, swing: CGFloat = 0) -> CGPath {
        let scale = bird.width / Constant.birdWidth
        let placement = CGAffineTransform(translationX: bird.x, y: bird.y)
            .scaledBy(x: scale, y: scale)
            .concatenating(Constant.topLeftTransform(in: Constant.height))

        // Wings dip, rise and dip again across the box: the tips hang at `tip`,
        // the two meet in the middle at `join`, and `lift` pulls each one up in
        // between. The band is that curve traced out and then back a point lower,
        // rather than stroked, which is what keeps its depth even out to the tips.
        let (tip, join, lift): (CGFloat, CGFloat, CGFloat) = (1.7, 0.55, -1.15)
        let width = Constant.birdWidth
        let depth = Constant.birdDepth

        // The tips take the whole swing and the curve behind them half of it, each in
        // proportion to how far out along the wing it sits. That pivots the wings about
        // the body they meet at, where moving the two together would just bob the glyph.
        let (tipY, liftY) = (tip + swing, lift + swing / 2)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: tipY), transform: placement)
        path.addQuadCurve(to: CGPoint(x: width / 2, y: join),
                          control: CGPoint(x: width / 4, y: liftY), transform: placement)
        path.addQuadCurve(to: CGPoint(x: width, y: tipY),
                          control: CGPoint(x: width * 3 / 4, y: liftY), transform: placement)
        path.addLine(to: CGPoint(x: width, y: tipY + depth), transform: placement)
        path.addQuadCurve(to: CGPoint(x: width / 2, y: join + depth),
                          control: CGPoint(x: width * 3 / 4, y: liftY + depth), transform: placement)
        path.addQuadCurve(to: CGPoint(x: 0, y: tipY + depth),
                          control: CGPoint(x: width / 4, y: liftY + depth), transform: placement)
        path.closeSubpath()
        return path
    }

    /// Overlapping puffs fill as one silhouette under the non-zero rule, which is
    /// what keeps the seams between them from showing.
    func createPuffLayer(_ puffs: [Constant.Circle], color: PlatformColor) -> CAShapeLayer {
        let path = CGMutablePath()
        for puff in puffs {
            path.addEllipse(in: CGRect(x: puff.x,
                                       y: Constant.y(fromTop: puff.y, height: puff.diameter, in: Constant.height),
                                       width: puff.diameter,
                                       height: puff.diameter))
        }

        let layer = CAShapeLayer()
        layer.frame = CGRect(x: 0, y: 0, width: Constant.width, height: Constant.height)
        layer.path = path
        layer.fillColor = color.cgColor
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

    func createRimLayer() -> CAShapeLayer {
        let rect = CGRect(x: 0, y: 0, width: Constant.indicatorSize, height: Constant.indicatorSize)

        // Even-odd over the two circles also fills the sliver of the face that
        // overhangs the indicator; the mask trims that back off.
        let mask = CAShapeLayer()
        mask.frame = rect
        mask.path = CGPath(ellipseIn: rect, transform: nil)

        let layer = CAShapeLayer()
        layer.frame = rect
        layer.fillRule = .evenOdd
        layer.mask = mask
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
