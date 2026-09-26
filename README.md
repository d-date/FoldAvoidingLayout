# FoldAvoidingLayout

A SwiftUI layout that keeps side-by-side content off the fold of a foldable iPhone, and a way to see it working in the iPhone Duo simulator, which does not report the fold.

```swift
import FoldAvoidingLayout

struct ChoicesView: View {
  @Environment(\.simulatedFolds) private var simulatedFolds

  var body: some View {
    GeometryReader { geometry in
      let layout = geometry.foldAvoidingLayout(
        axis: .horizontal, spacing: 8, simulatedFolds: simulatedFolds)
      ScrollView {
        layout {
          PhysicalCardButton()
          MobileCardButton()
        }
        .padding(.horizontal, 16)
      }
    }
  }
}
```

## What it does

- **Splits at the fold.** With a fold across the axis, each subview gets its own side of it, so none of them lies across the hinge. With fewer subviews than sides, they take the widest; with more, the extras share the leading side.
- **Keeps the sides equal.** The fold sits at the centre of the display, but the content area usually does not — a vertical bar takes one side — so the two sides differ in width. Every subview gets the narrower side's width, aligned to the outer edges, so side-by-side choices look like equals.
- **Falls back to a plain stack.** Without a fold — every other device, and a flat iPhone Duo — `foldAvoidingLayout` returns an `HStackLayout` / `VStackLayout`. It returns `AnyLayout` either way, so switching keeps the subviews' identity: a text field does not lose focus when the device is folded.
- **Builds with older Xcode.** The system fold is read with `GeometryProxy.reservedRegions(kind: .division)`, which only exists in the iOS 27.1 SDK. The call is compiled only when SwiftUI is 8.0.85 or later (the iOS 27.1 SDK); older toolchains build and see no fold.

## Seeing it in the simulator

In the Xcode 27.1 beta, the iPhone Duo simulator returns no reserved regions in any pose — closed, open flat or folded — even with `.includeInactive`. The hinge itself is simulated, but no region reaches the app, so fold-avoiding code never runs there. ([Blake Crosley observed the same](https://blakecrosley.com/blog/xcode-27-1-beta-iphone-duo-simulator).) This may change in a later Xcode.

So the fold is injectable. `\.simulatedFolds` takes rectangles in the window's coordinate space, margins included; `nil`, the default, reads the system's active division regions.

**Previews**

```swift
#Preview(traits: .fixedLayout(width: 867, height: 635)) {
  ChoicesView()
    .environment(\.simulatedFolds, [CGRect(x: 413.5, y: 0, width: 40, height: 635)])
}
```

**The running app** — apply the modifier near the root and launch with `-SimulateFold YES` (Scheme ▸ Run ▸ Arguments, or `xcrun simctl launch <device> <bundle-id> -SimulateFold YES`):

```swift
RootView()
  #if DEBUG && os(iOS)
    .simulatesFoldFromLaunchArgument()
  #endif
```

The modifier is only compiled into debug builds of the package.

It puts a 40pt fold across the middle of the inner display — vertical when it is wider than tall, horizontal otherwise — and none on the outer display. The 40pt is the width reported for iPhone Duo's division region; it has not been measured on a device.

## Testing

`ReservedRegion` has no public initializer, so the geometry is exercised through plain rectangles and ranges. The only part left to a folded device is the thin adapter that turns the system's division regions into rectangles. The same approach as [SwiftUICalendar #21](https://github.com/maniramezan/SwiftUICalendar/pull/21).

```
swift test
```

## Requirements

iOS 16, macOS 13, tvOS 16, visionOS 1. Swift 6. The fold is only read on iOS 27.1 and later, built with the iOS 27.1 SDK or newer.

## License

MIT
