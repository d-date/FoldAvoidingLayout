# FoldAvoidingLayout

A SwiftUI layout that keeps side-by-side content off the fold of a foldable iPhone.

```swift
import FoldAvoidingLayout

struct ChoicesView: View {
  var body: some View {
    GeometryReader { geometry in
      let layout = geometry.foldAvoidingLayout(axis: .horizontal, spacing: 8)
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

## Where it fits next to ArrangementView

iOS 27.1 adds `ArrangementView`, a container that places a primary and a secondary view by the display's size, the reserved regions and the active fold. Where it fits, consider it first: the system decides the arrangement, including whether each view is shown, and can animate the change between poses.

This package is for what it does not cover:

- **Earlier iOS.** `ArrangementView` needs iOS 27.1. This layout runs from iOS 16 and builds with older SDKs; before iOS 27.1 it is a plain stack.
- **Inside a scroll view.** Apple advises against putting `ArrangementView` inside `List` or `ScrollView`. Side-by-side choices in a scrolling form are exactly where this layout is used.
- **Not two views.** `ArrangementView` takes a primary and a secondary. This layout takes any number of subviews: a single one goes on the wider side, and extras share a side.

For two views outside a scroll view on iOS 27.1, reach for `ArrangementView` first, and keep this layout where you need its placement: every subview kept to one side of the fold, at the same width on both sides.

## Seeing it in the simulator

The iPhone Duo simulator in Xcode 27.1 reports the fold. Fold it in Device Hub and the layout splits; to see where the fold is, draw the division regions over your view:

```swift
content.overlay {
  GeometryReader { proxy in
    ForEach(proxy.reservedRegions(kind: .division)) { region in
      Rectangle()
        .fill(.orange.opacity(0.3))
        .frame(width: region.frame.width, height: region.frame.height)
        .position(x: region.frame.midX, y: region.frame.midY)
    }
  }
}
```

With the inner display landscape and folded, the region is a 40pt band across the middle with 20pt margins on each side; the layout keeps clear of both.

## Testing

`ReservedRegion` has no public initializer, so the geometry is exercised through plain rectangles and ranges; the thin adapter that turns the system's division regions into rectangles is checked in the simulator.

```
swift test
```

## Requirements

iOS 16, macOS 13, tvOS 16, visionOS 1. Swift 6. The fold is only read on iOS 27.1 and later, built with the iOS 27.1 SDK or newer.

## License

MIT
