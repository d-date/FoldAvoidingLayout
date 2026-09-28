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
