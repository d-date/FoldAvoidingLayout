import SwiftUI

#if os(iOS)

  /// Stacks its subviews along `axis`, keeping each one clear of the bands it is
  /// given — the fold, in practice.
  ///
  /// The bands divide the axis into free stretches. With as many subviews as
  /// stretches the subviews take one each, so none of them lies across the fold.
  /// With more subviews than stretches the extras share one.
  ///
  /// ## Coordinate space
  ///
  /// `bands` are measured from the leading edge of `containerExtent`, which is
  /// the `GeometryProxy` the fold was read from. This layout is usually placed
  /// inside padding, so its own width is smaller; the difference is split evenly
  /// and subtracted, which is correct for the symmetric padding the callers use.
  /// Both the measuring and the placing pass run the same conversion, so the
  /// width a subview is measured at is the width it is placed at.
  struct RegionAvoidingLayout: Layout {
    /// Ranges to keep subviews out of, in the container's coordinate space.
    var bands: [ClosedRange<CGFloat>]
    /// Extent of the geometry the bands were measured in.
    var containerExtent: CGFloat
    var axis: Axis
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
      // Pass the cross axis through untouched, nil included. Resolving it here
      // would propose the 10pt `replacingUnspecifiedDimensions` default to the
      // subviews, which in a scroll view is every measurement.
      let cross = crossValue(of: proposal)
      let extent = alongValue(of: proposal) ?? idealExtent(of: subviews)
      let slots = slots(extent: extent, count: subviews.count)
      let crossExtents = zip(subviews, slots).map { subview, slot in
        crossExtent(of: subview.sizeThatFits(sizeProposal(along: slot.length, cross: cross)))
      }
      return size(along: extent, cross: crossExtents.max() ?? 0)
    }

    /// What the subviews want along the axis, for the rare proposal that leaves
    /// it unspecified.
    private func idealExtent(of subviews: Subviews) -> CGFloat {
      let total = subviews.reduce(CGFloat.zero) { $0 + extent(of: $1.sizeThatFits(.unspecified)) }
      return total + spacing * CGFloat(max(0, subviews.count - 1))
    }

    func placeSubviews(
      in bounds: CGRect,
      proposal: ProposedViewSize,
      subviews: Subviews,
      cache: inout ()
    ) {
      let slots = slots(extent: extent(of: bounds.size), count: subviews.count)
      for (subview, slot) in zip(subviews, slots) {
        let proposal = sizeProposal(along: slot.length, cross: crossExtent(of: bounds.size))
        switch axis {
        case .horizontal:
          subview.place(
            at: CGPoint(x: bounds.minX + slot.start, y: bounds.minY),
            anchor: .topLeading,
            proposal: proposal
          )
        case .vertical:
          subview.place(
            at: CGPoint(x: bounds.minX, y: bounds.minY + slot.start),
            anchor: .topLeading,
            proposal: proposal
          )
        }
      }
    }

    private func slots(extent: CGFloat, count: Int) -> [FoldGeometry.Slot] {
      FoldGeometry.slots(
        extent: extent,
        count: count,
        bands: bands,
        containerExtent: containerExtent,
        spacing: spacing
      )
    }

    // MARK: - Axis helpers

    private func extent(of size: CGSize) -> CGFloat {
      axis == .horizontal ? size.width : size.height
    }

    private func crossExtent(of size: CGSize) -> CGFloat {
      axis == .horizontal ? size.height : size.width
    }

    private func size(along: CGFloat, cross: CGFloat) -> CGSize {
      axis == .horizontal
        ? CGSize(width: along, height: cross) : CGSize(width: cross, height: along)
    }

    private func sizeProposal(along: CGFloat, cross: CGFloat?) -> ProposedViewSize {
      axis == .horizontal
        ? ProposedViewSize(width: along, height: cross)
        : ProposedViewSize(width: cross, height: along)
    }

    private func alongValue(of proposal: ProposedViewSize) -> CGFloat? {
      axis == .horizontal ? proposal.width : proposal.height
    }

    private func crossValue(of proposal: ProposedViewSize) -> CGFloat? {
      axis == .horizontal ? proposal.height : proposal.width
    }
  }

#endif
extension GeometryProxy {
  /// A stack along `axis` whose subviews stay clear of the fold.
  ///
  /// Falls back to a plain stack when there is no fold to avoid — which is
  /// every device but a folded iPhone Duo — so the common case keeps
  /// `HStack`'s own distribution rather than this layout's even split.
  ///
  /// `AnyLayout` rather than two hierarchies so switching keeps the subviews'
  /// state: a text field does not lose focus when the device is folded.
  public func foldAvoidingLayout(axis: Axis, spacing: CGFloat) -> AnyLayout {
    // Only iOS has a fold to avoid; elsewhere this is a plain stack. The
    // method itself stays available everywhere so multiplatform views do not
    // need their own conditional compilation.
    #if os(iOS)
      let bands = FoldGeometry.bands(from: systemFolds(), axis: axis)
      guard !bands.isEmpty else { return plainLayout(axis: axis, spacing: spacing) }
      return AnyLayout(
        RegionAvoidingLayout(
          bands: bands,
          containerExtent: axis == .horizontal ? size.width : size.height,
          axis: axis,
          spacing: spacing
        )
      )
    #else
      return plainLayout(axis: axis, spacing: spacing)
    #endif
  }

  #if os(iOS)
    /// The system's active folds in this geometry's coordinate space, margins
    /// included.
    private func systemFolds() -> [CGRect] {
      // `reservedRegions` exists only in the iOS 27.1 SDK, and `#available`
      // cannot hide a symbol from an older SDK. SwiftUI 8.0.85 is the version
      // that SDK ships (8.0.84 in 27.0), so older toolchains still build and
      // simply see no fold.
      #if canImport(SwiftUI, _version: 8.0.85)
        guard #available(iOS 27.1, *) else { return [] }
        return reservedRegions(kind: .division).filter(\.isActive).map { region in
          CGRect(
            x: region.frame.minX - region.margins.leading,
            y: region.frame.minY - region.margins.top,
            width: region.frame.width + region.margins.leading + region.margins.trailing,
            height: region.frame.height + region.margins.top + region.margins.bottom
          )
        }
      #else
        return []
      #endif
    }
  #endif

  private func plainLayout(axis: Axis, spacing: CGFloat) -> AnyLayout {
    axis == .horizontal
      ? AnyLayout(HStackLayout(alignment: .top, spacing: spacing))
      : AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
  }
}
