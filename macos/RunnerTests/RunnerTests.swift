import Cocoa
import FlutterMacOS
import Security
import XCTest
@testable import Dry_Eye_Widget

class RunnerTests: XCTestCase {

  func testLargeWindowDoesNotMatchSmallerDisplayElsewhere() {
    XCTAssertFalse(FullscreenGeometry.coversDisplay(
      window: CGRect(x: 100, y: 100, width: 1600, height: 1000),
      displays: [
        CGRect(x: 0, y: 0, width: 2560, height: 1440),
        CGRect(x: 2560, y: 0, width: 1280, height: 800),
      ]))
  }

  func testFullscreenOnDisplayWithNegativeCoordinates() {
    let display = CGRect(x: -1920, y: -1080, width: 1920, height: 1080)
    XCTAssertTrue(FullscreenGeometry.coversDisplay(window: display, displays: [display]))
  }

  func testMaximizedWindowBelowMenuBarIsNotFullscreen() {
    XCTAssertFalse(FullscreenGeometry.coversDisplay(
      window: CGRect(x: 0, y: 25, width: 1920, height: 1055),
      displays: [CGRect(x: 0, y: 0, width: 1920, height: 1080)]))
  }

  func testDisplayEdgeRoundingAllowsOnePoint() {
    XCTAssertTrue(FullscreenGeometry.coversDisplay(
      window: CGRect(x: 1, y: 1, width: 1918, height: 1078),
      displays: [CGRect(x: 0, y: 0, width: 1920, height: 1080)]))
  }

  func testEmptyDisplayDoesNotMatch() {
    XCTAssertFalse(FullscreenGeometry.coversDisplay(
      window: CGRect(x: 0, y: 0, width: 1920, height: 1080), displays: [.zero]))
  }

  func testKeychainUpdatesExistingValueWithoutAddingRecord() {
    let replacement = Data("replacement".utf8)
    var value = Data("previous".utf8)
    let status = KeychainWriter.write(replacement, query: [:], update: { _, attributes in
      value = (attributes as NSDictionary)[kSecValueData] as! Data
      return errSecSuccess
    }, add: { _, _ in
      XCTFail("Updating an existing record must not add another record")
      return errSecDuplicateItem
    })
    XCTAssertEqual(status, errSecSuccess)
    XCTAssertEqual(value, replacement)
  }

  func testKeychainWriteFailurePreservesPreviousValue() {
    let previous = Data("previous".utf8)
    var value = previous
    let status = KeychainWriter.write(Data("replacement".utf8), query: [:], update: { _, _ in
      errSecInteractionNotAllowed
    }, add: { _, _ in
      value = Data()
      XCTFail("A failed update must not replace the existing record")
      return errSecSuccess
    })
    XCTAssertEqual(status, errSecInteractionNotAllowed)
    XCTAssertEqual(value, previous)
  }

  func testKeychainAddsMissingValueAndReturnsWriteFailure() {
    var attempts = 0
    let status = KeychainWriter.write(Data("value".utf8), query: [:], update: { _, _ in
      errSecItemNotFound
    }, add: { _, _ in
      attempts += 1
      return errSecNotAvailable
    })
    XCTAssertEqual(attempts, 1)
    XCTAssertEqual(status, errSecNotAvailable)
  }

}
