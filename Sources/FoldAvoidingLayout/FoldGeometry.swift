import SwiftUI

/// The geometry behind keeping content off the fold, over plain rectangles and
/// ranges.
///
/// `ReservedRegion` has no public initializer, so this is kept apart from the
/// system query for unit tests to exercise.
enum FoldGeometry {
  /// A subview's place along the axis, as an offset from the layout's leading
  /// edge rather than an absolute coordinate, so measuring and placing agree
  /// however the layout is positioned.
  struct Slot: Equatable {
    var start: CGFloat
    var length: CGFloat
  }

  /// `rects` as ranges along `axis`. Only a rect that runs across `axis`
  /// divides it: a vertical fold divides a horizontal stack, not a vertical one.
  static func bands(from rects: [CGRect], axis: Axis) -> [ClosedRange<CGFloat>] {
    rects.compactMap { rect in
      switch axis {
      case .horizontal:
        guard rect.height >= rect.width else { return nil }
        return rect.minX...rect.maxX
      case .vertical:
        guard rect.width >= rect.height else { return nil }
        return rect.minY...rect.maxY
      }
    }
  }

  /// Where `count` subviews go along a layout `extent` long, keeping clear of
  /// `bands`.
  ///
  /// The bands divide the extent into free stretches. With as many subviews as
  /// stretches the subviews take one each, so none of them lies across a band.
  /// With fewer, they take the widest stretches; with more, the extras share
  /// one.
  ///
  /// `bands` are measured in a container `containerExtent` long that this
  /// layout sits centred in — symmetric padding, which is what the callers use.
  static func slots(
    extent: CGFloat,
    count: Int,
    bands: [ClosedRange<CGFloat>],
    containerExtent: CGFloat,
    spacing: CGFloat
  ) -> [Slot] {
    guard count > 0, extent > 0 else { return [] }
    var stretches = [ClosedRange<CGFloat>(uncheckedBounds: (0, extent))]
    for band in layoutBands(bands, extent: extent, containerExtent: containerExtent) {
      stretches = stretches.flatMap { stretch -> [ClosedRange<CGFloat>] in
        guard band.overlaps(stretch) else { return [stretch] }
        var pieces: [ClosedRange<CGFloat>] = []
        if band.lowerBound > stretch.lowerBound {
          pieces.append(stretch.lowerBound...band.lowerBound)
        }
        if band.upperBound < stretch.upperBound {
          pieces.append(band.upperBound...stretch.upperBound)
        }
        return pieces
      }
    }
    if stretches.isEmpty { stretches = [0...extent] }

    // Fewer subviews than stretches: give them the widest ones, so a single
    // element lands in the roomier half rather than always the leading one.
    if count < stretches.count {
      stretches =
        stretches
        .sorted { ($0.upperBound - $0.lowerBound) > ($1.upperBound - $1.lowerBound) }
        .prefix(count)
        .sorted { $0.lowerBound < $1.lowerBound }
    }

    // More subviews than stretches: the extras share one, spread in order.
    var share = Array(repeating: 0, count: stretches.count)
    for index in 0..<count {
      share[index * stretches.count / count] += 1
    }
    let groups = zip(stretches, share).filter { $0.1 > 0 }.map { stretch, share in
      let total = stretch.upperBound - stretch.lowerBound
      // A stretch narrower than the gaps would give a negative width, so drop
      // the gaps rather than propose one.
      let gaps = min(spacing * CGFloat(share - 1), total)
      return (
        stretch: stretch, share: share,
        gap: share > 1 ? gaps / CGFloat(share - 1) : 0,
        each: max(0, (total - gaps) / CGFloat(share))
      )
    }

    // The fold is at the display's centre but the content area is not — the
    // vertical bar takes one side — so the stretches differ in width. Give
    // every subview the narrowest one's length: side-by-side choices of
    // different sizes read as unequal. The leading group keeps the leading
    // edge and the trailing group the trailing edge, so the columns stay
    // aligned with the full-width content above and below them.
    let each = groups.map(\.each).min() ?? 0
    return groups.enumerated().flatMap { index, group -> [Slot] in
      let width = each * CGFloat(group.share) + group.gap * CGFloat(group.share - 1)
      let start: CGFloat
      switch index {
      case 0 where groups.count > 1:
        start = group.stretch.lowerBound
      case groups.count - 1 where groups.count > 1:
        start = group.stretch.upperBound - width
      default:
        let room = group.stretch.upperBound - group.stretch.lowerBound
        start = group.stretch.lowerBound + (room - width) / 2
      }
      return (0..<group.share).map {
        Slot(start: start + (each + group.gap) * CGFloat($0), length: each)
      }
    }
  }

  /// `bands` shifted from the container's coordinate space into the layout's.
  private static func layoutBands(
    _ bands: [ClosedRange<CGFloat>],
    extent: CGFloat,
    containerExtent: CGFloat
  ) -> [ClosedRange<CGFloat>] {
    let inset = max(0, (containerExtent - extent) / 2)
    return
      bands
      .map { ($0.lowerBound - inset)...($0.upperBound - inset) }
      .filter { $0.upperBound > 0 && $0.lowerBound < extent }
      .sorted { $0.lowerBound < $1.lowerBound }
  }
}
