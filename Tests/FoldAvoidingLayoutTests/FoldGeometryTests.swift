import CoreGraphics
import SwiftUI
import Testing

@testable import FoldAvoidingLayout

/// `ReservedRegion` has no public initializer and the iPhone Duo simulator in
/// the Xcode 27.1 beta reports none, so the fold geometry is exercised through
/// plain rectangles and ranges. Reading the real regions is the only part left
/// to a folded device.
@Suite struct FoldGeometryTests {
  // MARK: - bands(from:axis:)

  @Test("A vertical fold divides a horizontal stack, not a vertical one")
  func bands_keepsOnlyRectsRunningAcrossTheAxis() {
    let fold = CGRect(x: 413.5, y: 0, width: 40, height: 635)
    #expect(FoldGeometry.bands(from: [fold], axis: .horizontal) == [413.5...453.5])
    #expect(FoldGeometry.bands(from: [fold], axis: .vertical).isEmpty)
  }

  @Test("A horizontal fold divides a vertical stack, not a horizontal one")
  func bands_horizontalFoldDividesVerticalAxis() {
    let fold = CGRect(x: 0, y: 300, width: 635, height: 40)
    #expect(FoldGeometry.bands(from: [fold], axis: .vertical) == [300...340])
    #expect(FoldGeometry.bands(from: [fold], axis: .horizontal).isEmpty)
  }

  // MARK: - slots

  @Test("Without a fold, subviews split the extent evenly around the spacing")
  func slots_withoutFold_splitsEvenly() {
    let slots = FoldGeometry.slots(
      extent: 800, count: 2, bands: [], containerExtent: 800, spacing: 8)
    #expect(slots == [.init(start: 0, length: 396), .init(start: 404, length: 396)])
  }

  /// The inner display's layout sits inside 16pt padding, so the fold measured
  /// in the container is 16pt further along than in the layout.
  @Test("Two subviews land one on each side of the fold, neither reaching into it")
  func slots_twoSubviews_landEitherSideOfTheFold() {
    let fold: ClosedRange<CGFloat> = 413.5...453.5
    let slots = FoldGeometry.slots(
      extent: 835, count: 2, bands: [fold], containerExtent: 867, spacing: 8)
    #expect(slots == [.init(start: 0, length: 397.5), .init(start: 437.5, length: 397.5)])
    let foldInLayout: ClosedRange<CGFloat> = 397.5...437.5
    for slot in slots {
      let range = slot.start...(slot.start + slot.length)
      // Touching the fold's edge is fine; reaching into it is not.
      #expect(range.upperBound <= foldInLayout.lowerBound || range.lowerBound >= foldInLayout.upperBound)
    }
  }

  /// The fold is at the display's centre, but the vertical bar takes space on
  /// the trailing side, so the two stretches beside the fold differ in width.
  /// Side-by-side cards of different sizes read as unequal choices.
  @Test("An off-centre fold still gives equal widths, aligned to the outer edges")
  func slots_offCentreFold_equalizesLengths() {
    let slots = FoldGeometry.slots(
      extent: 800, count: 2, bands: [440...480], containerExtent: 800, spacing: 8)
    #expect(slots == [.init(start: 0, length: 320), .init(start: 480, length: 320)])
  }

  @Test("A single subview takes the wider side of the fold")
  func slots_singleSubview_takesTheWiderSide() {
    let slots = FoldGeometry.slots(
      extent: 800, count: 1, bands: [300...340], containerExtent: 800, spacing: 0)
    #expect(slots == [.init(start: 340, length: 460)])
  }

  @Test("Extra subviews share the leading stretch, at the same width")
  func slots_moreSubviewsThanStretches_share() {
    let slots = FoldGeometry.slots(
      extent: 800, count: 3, bands: [380...420], containerExtent: 800, spacing: 10)
    #expect(
      slots == [
        .init(start: 0, length: 185),
        .init(start: 195, length: 185),
        .init(start: 615, length: 185),
      ])
  }

  @Test("A fold outside the layout is ignored")
  func slots_ignoresBandsOutsideTheLayout() {
    let slots = FoldGeometry.slots(
      extent: 400, count: 2, bands: [500...540], containerExtent: 400, spacing: 0)
    #expect(slots == [.init(start: 0, length: 200), .init(start: 200, length: 200)])
  }

  /// Without this a fold covering the whole layout would leave nowhere to put
  /// anything, and the screen would render empty.
  @Test("A fold covering everything falls back to the whole extent")
  func slots_fullyCovered_fallsBackToTheWholeExtent() {
    let slots = FoldGeometry.slots(
      extent: 400, count: 1, bands: [-10...410], containerExtent: 400, spacing: 0)
    #expect(slots == [.init(start: 0, length: 400)])
  }
}
