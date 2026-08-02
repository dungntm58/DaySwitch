# DaySwitch

A day/night toggle for macOS and iOS, drawn entirely in Core Animation layers — no
images, no asset catalog.

<p align="center">
  <img src="Assets/demo.gif" alt="The switch toggling between its day and night scenes" width="176">
</p>

Each side is a small scene rather than a colour: the sun carries a halo that breathes,
clouds drift under a pair of birds beating their wings, and the night sky keeps two
mountain ranges under stars that blink out of step with one another. Switching sides
sends each group of figures off its own way while the two scenes cross over.

## Requirements

| | |
| --- | --- |
| Platforms | macOS 10.13+, iOS 12+ |
| SwiftUI wrapper (`DayToggle`) | macOS 10.15+, iOS 13+ |
| Swift | 5.8+ |

## Installation

Swift Package Manager — add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dungntm58/DaySwitch.git", branch: "main"),
]
```

or in Xcode, **File → Add Package Dependencies…** and paste the repository URL.

## Usage

### SwiftUI

```swift
import SwiftUI
import DaySwitch

struct ContentView: View {
    @State private var isDayLight = true

    var body: some View {
        DayToggle(isDayLight: $isDayLight)
            .fixedSize()
    }
}
```

### AppKit

```swift
import DaySwitch

let toggle = DaySwitch(frame: .zero)
toggle.translatesAutoresizingMaskIntoConstraints = false
toggle.target = self
toggle.action = #selector(dayLightDidChange(_:))

@objc func dayLightDidChange(_ sender: DaySwitch) {
    print(sender.isDayLight)
}
```

### UIKit

```swift
import DaySwitch

let toggle = DaySwitch(frame: .zero)
toggle.translatesAutoresizingMaskIntoConstraints = false
toggle.addTarget(self, action: #selector(dayLightDidChange(_:)), for: .valueChanged)

@objc func dayLightDidChange(_ sender: DaySwitch) {
    print(sender.isDayLight)
}
```

`DaySwitch` is an `NSControl` / `UIControl` subclass. A click or tap toggles
`isDayLight`; setting it in code animates the same way. The control draws at a fixed
160 × 60 — its `intrinsicContentSize` — and centres that in whatever frame it is
given.

## Licence

MIT. See [LICENSE](LICENSE).
