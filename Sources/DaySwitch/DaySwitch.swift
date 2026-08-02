//
//  DaySwitch.swift
//  DaySwitch
//
//  Created by Robert on 01/05/2023.
//

#if os(macOS)
import AppKit

public typealias PlatformControl = NSControl
public typealias PlatformGestureRecognizer = NSGestureRecognizer
public typealias PlatformColor = NSColor
#elseif os(iOS)
import UIKit

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
    /// The track, and the indicator on it, each in its own coordinates. Every figure is
    /// framed to the whole track and draws in its coordinates, so the design's numbers
    /// can be used as they are.
    static let bounds = CGRect(x: 0, y: 0, width: width, height: height)
    static let indicatorBounds = CGRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize)
    /// The track's outline, which the scenery and the inner shadow are both clipped to.
    static let capsule = CGPath(roundedRect: bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    /// Where the indicator rests at either end of the track.
    static let indicatorRestX: (day: CGFloat, night: CGFloat) = (inset, width - inset - indicatorSize)
    static let shadowRadius: CGFloat = 2
    static let duration: CFTimeInterval = 0.35
    static let timingFunction = CAMediaTimingFunction(name: .easeIn)
    /// Idle motion swings out and comes back, so it wants to ease out of each end of
    /// the swing as well as into it.
    static let idleTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    /// None of the idle motion is quick enough to need every frame a 120Hz display can
    /// give it, and a display asked for fewer is allowed to stay down at that rate. The
    /// wingbeat is the fastest of them and so the one that would show it first; the glow
    /// takes a second to breathe and the stars the best part of one to blink.
    static let idleFrameRate: (halo: Float, star: Float, bird: Float) = (30, 30, 60)
    /// The slowest any of them may be stepped at, whatever else the display is doing.
    static let idleFrameRateFloor: Float = 30

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
    static let sunHaloExit = CGSize(width: indicatorRestX.night - indicatorRestX.day, height: 0)

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

    /// The same flip for paths, which cannot be repositioned a rect at a time. Every
    /// path here is authored in track coordinates, so the track is the container.
#if os(macOS)
    static let topLeftTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: height)
#else
    static let topLeftTransform = CGAffineTransform.identity
#endif
}

private extension CGRect {
    func centerRect(width: CGFloat, height: CGFloat) -> CGRect {
        insetBy(dx: (self.width - width) / 2, dy: (self.height - height) / 2)
    }
}

private extension CALayer {
    /// Moves a path authored in track coordinates into the layer's own, which is where
    /// the layer's frame has already put it.
    func localised(_ path: CGPath) -> CGPath {
        var offset = CGAffineTransform(translationX: -frame.minX, y: -frame.minY)
        return path.copy(using: &offset) ?? path
    }

    /// Clips the layer to `path`, which is in the layer's own coordinates, so the
    /// layer has to be framed before this is called.
    ///
    /// Every clip here is the layer's own bounds with the corners taken off, which
    /// `cornerRadius` and `masksToBounds` would also do, and would do without the render
    /// pass a mask costs. It is not the same clip, though. A mask multiplies its own
    /// antialiased edge into the figure's, and the design was traced against the softer
    /// rim that leaves: swapping the scenery over to a corner radius firms up the pixels
    /// where the cloud runs off the track and takes the day scene from 2.41 to 2.49 mean
    /// error against `day.png`. The pass is a fixed 160x60 and the idle loops no longer
    /// run unwatched, so it is not worth the edge.
    func clip(to path: CGPath) {
        let shape = CAShapeLayer()
        shape.frame = bounds
        shape.path = path
        mask = shape
    }

    /// Sets a property, and when the change is meant to be seen happening, animates to
    /// it as well. `Value` is generic rather than `Any` so that the call site's own type
    /// is what gets boxed: a `Float` written as one stays a `Float`, where `Any` would
    /// let a literal in a ternary widen it to a `Double` and quietly change the
    /// animation's end value.
    func set<Value>(_ keyPath: String, to value: Value, animated: Bool) {
        setValue(value, forKeyPath: keyPath)
        guard animated else {
            return
        }
        animate(keyPath, to: value)
    }

    /// Keys the animation on `<keyPath>Anim`, so the key and the property it
    /// animates cannot drift apart.
    func animationKey(_ keyPath: String) -> String {
        keyPath + "Anim"
    }

    func animate(_ keyPath: String, to value: Any?) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = Constant.duration
        animation.toValue = value
        animation.timingFunction = Constant.timingFunction
        add(animation, forKey: animationKey(keyPath))
    }

    /// Whether `animate` still has one in flight on this property.
    func isAnimating(_ keyPath: String) -> Bool {
        animation(forKey: animationKey(keyPath)) != nil
    }

    /// The same for motion that never settles: the property swings between the two
    /// values for as long as the loop is on the layer, `duration` to a swing, starting
    /// `phase` of the way through one, and stepped no faster than `frameRate`. Only the
    /// presented value moves, so the layer still reads as the design has it.
    func loop(_ keyPath: String,
              from: Any?,
              to: Any?,
              duration: CFTimeInterval,
              phase: Double = 0,
              frameRate: Float) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = duration
        animation.fromValue = from
        animation.toValue = to
        animation.timingFunction = Constant.idleTimingFunction
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timeOffset = duration * phase
        if #available(macOS 12, iOS 15, *) {
            animation.preferredFrameRateRange = CAFrameRateRange(minimum: Constant.idleFrameRateFloor,
                                                                 maximum: frameRate,
                                                                 preferred: frameRate)
        }
        add(animation, forKey: keyPath + Self.loopSuffix)
    }

    /// Keys every loop on `<keyPath>Loop`, which is what lets them be found again as a
    /// group without the caller having to remember what it started.
    static let loopSuffix = "Loop"

    var hasLoops: Bool {
        animationKeys()?.contains { $0.hasSuffix(Self.loopSuffix) } ?? false
    }

    func removeLoops() {
        for key in animationKeys() ?? [] where key.hasSuffix(Self.loopSuffix) {
            removeAnimation(forKey: key)
        }
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

    /// `dynamic` as well as `@objc`: without it the setter is called directly rather
    /// than through the runtime, so KVO never fires and the SwiftUI binding only ever
    /// sees the value it was made with.
    @objc
    dynamic open var isDayLight: Bool = true {
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

    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateIdleAnimations()
    }
#else
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutMainLayer()
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        updateContentsScale()
        updateIdleAnimations()
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
        updateIdleAnimations()
        // Which window posted it does not matter: the switch only has to look again at
        // whether its own is one somebody can see, and occlusion changes are rare enough
        // that looking is cheaper than keeping track of whose window is whose.
#if os(macOS)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateIdleAnimations),
                                               name: NSWindow.didChangeOcclusionStateNotification,
                                               object: nil)
#else
        // iOS strips animations off layers when the app goes to the background, so the
        // loops have to go back on on the way in rather than only at setup.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateIdleAnimations),
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
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.hideSceneryThatHasLeft()
        }
        updateMainLayer(needsAnimate: needsAnimate)
        updateIndicator(needsAnimate: needsAnimate)
        updateMoonHole(needsAnimate: needsAnimate)
        updateRim(needsAnimate: needsAnimate)
        updateScenery(needsAnimate: needsAnimate)
        CATransaction.commit()
        // The scene coming back is unhidden by now, so this is where its loops go on.
        updateIdleAnimations()
    }

    /// A scene that has faded out is still a tree of perpetual animations, and Core
    /// Animation has no reason to know that nobody can see them: the birds go on beating
    /// and the halo goes on breathing behind a transparent layer. Hiding the scene takes
    /// it out of the render tree and taking its loops off stops it asking for frames.
    ///
    /// Only once the crossfade is over. Switching back mid-fade leaves the first
    /// transaction's completion arriving while the second fade is still running, and the
    /// scene it would hide is still on screen.
    func hideSceneryThatHasLeft() {
        guard !daySceneryLayer.isAnimating(#keyPath(CALayer.opacity)) else {
            return
        }
        daySceneryLayer.isHidden = !isDayLight
        sunHaloClipLayer.isHidden = !isDayLight
        nightSceneryLayer.isHidden = isDayLight
        updateIdleAnimations()
    }

    func updateMainLayer(needsAnimate: Bool) {
        let backgroundColor = isDayLight ? PlatformColor.Day.spaceBar : PlatformColor.Night.spaceBar
        mainLayer.set(#keyPath(CALayer.backgroundColor), to: backgroundColor.cgColor, animated: needsAnimate)
    }

    func updateIndicator(needsAnimate: Bool) {
        let backgroundColor = isDayLight ? PlatformColor.Day.sun : PlatformColor.Night.moon
        let shadowColor = isDayLight ? PlatformColor.Day.sunShadow : PlatformColor.Night.moonShadow
        let shadowOpacity: Float = isDayLight ? 0.25 : 0.2
        let shadowOffset = CGSize(width: isDayLight ? 2 : -2, height: Constant.shadowDrop)
        let restX = isDayLight ? Constant.indicatorRestX.day : Constant.indicatorRestX.night

        indicatorLayer.set(#keyPath(CALayer.backgroundColor), to: backgroundColor.cgColor, animated: needsAnimate)
        indicatorLayer.set(#keyPath(CALayer.frame),
                           to: Constant.indicatorBounds.offsetBy(dx: restX, dy: Constant.inset),
                           animated: needsAnimate)
        indicatorLayer.set(#keyPath(CALayer.shadowColor), to: shadowColor.cgColor, animated: needsAnimate)
        indicatorLayer.set(#keyPath(CALayer.shadowOpacity), to: shadowOpacity, animated: needsAnimate)
        indicatorLayer.set(#keyPath(CALayer.shadowOffset), to: shadowOffset, animated: needsAnimate)
    }

    func updateMoonHole(needsAnimate: Bool) {
        let opacity: Float = isDayLight ? 0 : 1
        moonHoleLayer.set(#keyPath(CALayer.opacity), to: opacity, animated: needsAnimate)
    }

    func updateScenery(needsAnimate: Bool) {
        let dayOpacity: Float = isDayLight ? 1 : 0
        let nightOpacity: Float = 1 - dayOpacity
        // Both scenes have to be in the render tree while they cross over each other;
        // whichever has gone once that is done is put back out of it.
        for layer in [daySceneryLayer, nightSceneryLayer, sunHaloClipLayer] {
            layer.isHidden = false
        }
        daySceneryLayer.set(#keyPath(CALayer.opacity), to: dayOpacity, animated: needsAnimate)
        nightSceneryLayer.set(#keyPath(CALayer.opacity), to: nightOpacity, animated: needsAnimate)
        // The clip carries the crossfade, which leaves the glow's own opacity free to
        // do nothing but breathe.
        sunHaloClipLayer.set(#keyPath(CALayer.opacity), to: dayOpacity, animated: needsAnimate)
        updateExit(of: [sunHaloLayer], by: Constant.sunHaloExit, isShowing: isDayLight, needsAnimate: needsAnimate)
        updateExit(of: cloudLayers, by: Constant.cloudExit, isShowing: isDayLight, needsAnimate: needsAnimate)
        updateExit(of: birdLayers, by: Constant.birdExit, isShowing: isDayLight, needsAnimate: needsAnimate)
        updateExit(of: rangeLayers, by: Constant.rangeExit, isShowing: !isDayLight, needsAnimate: needsAnimate)
    }

    /// Figures sit where the design puts them while their scene is showing and off by
    /// `offset` while it is not, so a switch carries them out that way and a switch
    /// back brings them in from it, under the crossfade either way. The stars are left
    /// out: they have nowhere to go, they only fade.
    func updateExit(of layers: [CALayer], by offset: CGSize, isShowing: Bool, needsAnimate: Bool) {
        let transform = isShowing ? CATransform3DIdentity : Constant.translation(offset)
        for layer in layers {
            layer.set(#keyPath(CALayer.transform), to: transform, animated: needsAnimate)
        }
    }

    func updateRim(needsAnimate: Bool) {
        let fillColor = isDayLight ? PlatformColor.Day.sunRim : PlatformColor.Night.moonRim
        rimLayer.set(#keyPath(CAShapeLayer.fillColor), to: fillColor.cgColor, animated: needsAnimate)
        rimLayer.set(#keyPath(CAShapeLayer.path), to: rimPath(), animated: needsAnimate)
    }

    /// The indicator circle with the lit face punched out of it. The face sits on
    /// the side the light comes from, so the crescent left over is the far edge.
    func rimPath() -> CGPath {
        let circle = Constant.indicatorBounds
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
    /// neither reads as one figure repeated.
    ///
    /// A loop nobody can see is still a loop. Core Animation goes on driving the display
    /// for it whether the scene it belongs to has faded out, the view has left its window
    /// or the window has gone behind another one — and where iOS at least strips
    /// animations off on the way to the background, macOS never takes them off at all. So
    /// each group is put on only while there is somebody who could be looking at it, and
    /// taken off again when there is not.
    ///
    /// A group's stagger rides on each layer's own phase rather than on when the group
    /// started, so it comes back the way it went. What a figure does lose is where in its
    /// own swing it was, and it loses that behind a scene nobody is watching.
    @objc
    func updateIdleAnimations() {
        setLoops(on: [sunHaloLayer],
                 running: isOnScreen && !sunHaloClipLayer.isHidden,
                 start: startHaloBreathing)
        setLoops(on: birdLayers,
                 running: isOnScreen && !daySceneryLayer.isHidden,
                 start: startBirdsFlapping)
        setLoops(on: starLayers,
                 running: isOnScreen && !nightSceneryLayer.isHidden,
                 start: startStarsBlinking)
    }

    /// Puts a group of loops on or takes them off, and leaves a group that is already
    /// the way it is being asked for alone: a loop re-added would start its swing over,
    /// and what drives this arrives whether or not anything has actually changed.
    func setLoops(on layers: [CALayer], running: Bool, start: () -> Void) {
        guard running != layers.contains(where: \.hasLoops) else {
            return
        }
        guard running else {
            for layer in layers {
                layer.removeLoops()
            }
            return
        }
        start()
    }

    /// Whether the switch is anywhere anybody could be looking at it. A view out of a
    /// window is nowhere; on macOS a window can also be behind another one, miniaturised
    /// or off in a space that is not the current one, and the system says which.
    var isOnScreen: Bool {
#if os(macOS)
        window?.occlusionState.contains(.visible) ?? false
#else
        window != nil
#endif
    }

    func startHaloBreathing() {
        // Both halves of the breath run off the one duration, so the glow reaches its
        // furthest exactly when it is at its brightest.
        sunHaloLayer.loop("locations",
                          from: sunHaloLocations(reach: Constant.sunHaloReach.rest),
                          to: sunHaloLocations(reach: Constant.sunHaloReach.swell),
                          duration: Constant.sunHaloDuration,
                          frameRate: Constant.idleFrameRate.halo)
        sunHaloLayer.loop("colors",
                          from: sunHaloColors(alpha: Constant.sunHaloOpacity.rest),
                          to: sunHaloColors(alpha: Constant.sunHaloOpacity.swell),
                          duration: Constant.sunHaloDuration,
                          frameRate: Constant.idleFrameRate.halo)
    }

    func startBirdsFlapping() {
        for (index, (bird, layer)) in zip(Constant.birds, birdLayers).enumerated() {
            layer.loop("path",
                       from: layer.localised(birdPath(bird, swing: -Constant.birdSwing)),
                       to: layer.localised(birdPath(bird, swing: Constant.birdSwing)),
                       duration: Constant.birdFlapDuration,
                       phase: Double(index) / Double(birdLayers.count),
                       frameRate: Constant.idleFrameRate.bird)
        }
    }

    func startStarsBlinking() {
        for (index, layer) in starLayers.enumerated() {
            layer.loop("opacity",
                       from: Float(1),
                       to: Constant.starDim,
                       duration: Constant.starBlinkDuration + Double(index) * Constant.starBlinkSpread,
                       phase: Double(index) / Double(starLayers.count),
                       frameRate: Constant.idleFrameRate.star)
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
        let rect = Constant.bounds
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

        let layer = CAShapeLayer()
        layer.frame = rect
        layer.path = path
        layer.fillRule = .evenOdd
        layer.fillColor = PlatformColor.black.cgColor
        layer.shadowColor = PlatformColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowOpacity = 0.2
        layer.shadowRadius = Constant.shadowRadius
        layer.clip(to: Constant.capsule)
        return layer
    }

    /// Figures, back to front, clipped to the track: a whole scene of them, or the one
    /// the halo amounts to. The clip stays put while what is inside it moves, which is
    /// what lets a figure run off the track and be trimmed by it.
    func createSceneryLayer(_ figures: [CALayer]) -> CALayer {
        let layer = CALayer()
        layer.frame = Constant.bounds
        layer.clip(to: Constant.capsule)
        for figure in figures {
            layer.addSublayer(figure)
        }
        return layer
    }

    /// A figure, framed to what it draws rather than to the whole track, so it carries
    /// the glyph and not the sky behind it. Paths are authored in track coordinates —
    /// the design's own numbers — and the frame takes its origin back out of them.
    /// `box` is for a figure that moves inside its layer and so needs room beyond the
    /// pose it is built in.
    func createFigureLayer(_ path: CGPath, color: PlatformColor, in box: CGRect? = nil) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.frame = box ?? path.boundingBox
        layer.path = layer.localised(path)
        layer.fillColor = color.cgColor
        return layer
    }

    func createRidgeLayer(_ ridge: [CGPoint], color: PlatformColor) -> CAShapeLayer {
        let path = CGMutablePath()
        path.addLines(between: ridge, transform: Constant.topLeftTransform)
        path.closeSubpath()
        return createFigureLayer(path, color: color)
    }

    /// One star. They never overlap, so a single path could draw them all, but they
    /// blink on their own schedules and an opacity is a per-layer thing.
    func createStarLayer(_ star: Constant.Star) -> CAShapeLayer {
        let transform = Constant.topLeftTransform

        // Four arms out to the tips, each neighbouring pair joined by a curve that pulls
        // back in towards the centre, which is what tapers the arms to points. The
        // control between two arms is those two added together and reeled back in.
        let arms = [CGVector(dx: 0, dy: -star.height / 2),
                    CGVector(dx: star.width / 2, dy: 0),
                    CGVector(dx: 0, dy: star.height / 2),
                    CGVector(dx: -star.width / 2, dy: 0)]
        func point(along arm: CGVector, out reach: CGFloat = 1) -> CGPoint {
            CGPoint(x: star.x + arm.dx * reach, y: star.y + arm.dy * reach)
        }

        let path = CGMutablePath()
        path.move(to: point(along: arms[0]), transform: transform)
        for (index, arm) in arms.enumerated() {
            let next = arms[(index + 1) % arms.count]
            let between = CGVector(dx: arm.dx + next.dx, dy: arm.dy + next.dy)
            path.addQuadCurve(to: point(along: next),
                              control: point(along: between, out: Constant.starPinch),
                              transform: transform)
        }
        path.closeSubpath()
        return createFigureLayer(path, color: PlatformColor.Night.star)
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
        // The wings beat past the pose the glyph is built in, so the layer is sized to
        // the whole swing rather than to where the path happens to start.
        let box = birdPath(bird, swing: -Constant.birdSwing).boundingBox
            .union(birdPath(bird, swing: Constant.birdSwing).boundingBox)
        return createFigureLayer(birdPath(bird), color: PlatformColor.Day.cloud, in: box)
    }

    /// The bird glyph, its wings carried `swing` points from where the design rests
    /// them. Every swing draws the same run of segments, so one path tweens into the
    /// next and the wings read as beating rather than cutting from pose to pose.
    func birdPath(_ bird: Constant.Bird, swing: CGFloat = 0) -> CGPath {
        let scale = bird.width / Constant.birdWidth
        let placement = CGAffineTransform(translationX: bird.x, y: bird.y)
            .scaledBy(x: scale, y: scale)
            .concatenating(Constant.topLeftTransform)

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

        // A point in the glyph's own units, placed on the track.
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x, y: y).applying(placement)
        }

        let path = CGMutablePath()
        path.move(to: at(0, tipY))
        path.addQuadCurve(to: at(width / 2, join), control: at(width / 4, liftY))
        path.addQuadCurve(to: at(width, tipY), control: at(width * 3 / 4, liftY))
        path.addLine(to: at(width, tipY + depth))
        path.addQuadCurve(to: at(width / 2, join + depth), control: at(width * 3 / 4, liftY + depth))
        path.addQuadCurve(to: at(0, tipY + depth), control: at(width / 4, liftY + depth))
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
        return createFigureLayer(path, color: color)
    }

    func createIndicatorLayer() -> CALayer {
        let layer = CALayer()
        layer.frame = Constant.indicatorBounds.offsetBy(dx: Constant.indicatorRestX.day, dy: Constant.inset)
        layer.cornerRadius = Constant.indicatorSize / 2
        layer.shadowRadius = Constant.shadowRadius
        // The silhouette is a known circle, so hand it over rather than making
        // Core Animation blur the layer's alpha channel offscreen every frame.
        layer.shadowPath = CGPath(ellipseIn: Constant.indicatorBounds, transform: nil)
        return layer
    }

    func createRimLayer() -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.frame = Constant.indicatorBounds
        layer.fillRule = .evenOdd
        // Even-odd over the two circles also fills the sliver of the face that
        // overhangs the indicator; the clip trims that back off.
        layer.clip(to: CGPath(ellipseIn: Constant.indicatorBounds, transform: nil))
        return layer
    }

    func createMoonHoleLayer() -> CALayer {
        let layer = CALayer()
        layer.frame = Constant.indicatorBounds
        for hole in Constant.moonHoles {
            let holeLayer = CALayer()
            holeLayer.backgroundColor = PlatformColor.Night.hole.cgColor
            holeLayer.frame = CGRect(x: hole.x,
                                     y: Constant.y(fromTop: hole.y, height: hole.diameter, in: Constant.indicatorSize),
                                     width: hole.diameter,
                                     height: hole.diameter)
            holeLayer.cornerRadius = hole.diameter / 2
            layer.addSublayer(holeLayer)
        }
        return layer
    }
}
