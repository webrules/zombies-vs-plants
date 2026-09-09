import XCTest
@testable import MoonbridgeGarden

final class GardenProjectionTests: XCTestCase {
    func testEveryCellRoundTripsAtSeveralWindowSizes() {
        for size in [CGSize(width: 520, height: 360), CGSize(width: 1000, height: 620),
                     CGSize(width: 1600, height: 700)] {
            let p = GardenProjection(size: size)
            for row in 0..<5 {
                for column in 0..<9 {
                    for dx in [0.01, 0.5, 0.99] {
                        for dy in [0.01, 0.5, 0.99] {
                            let point = p.point(column: CGFloat(column)+dx, row: CGFloat(row)+dy)
                            XCTAssertEqual(p.cell(at: point), GridCell(row: row, column: column))
                        }
                    }
                }
            }
        }
    }

    func testExactGridEdgesUseHalfOpenCellBounds() {
        let p = GardenProjection(size: CGSize(width: 930, height: 610))
        for row in 0..<5 {
            for column in 0..<9 {
                XCTAssertEqual(p.cell(at: p.point(column: CGFloat(column),row: CGFloat(row))),
                               GridCell(row: row,column: column))
            }
            XCTAssertNil(p.cell(at: p.point(column: 9,row: CGFloat(row)+0.5)))
        }
        XCTAssertNil(p.cell(at:p.point(column:4.5,row:5)))
    }

    func testSceneryAndOutsideEdgesAreNotClampedIntoCells() {
        let p = GardenProjection(size: CGSize(width: 1000, height: 600))
        for point in [CGPoint.zero, CGPoint(x: 999,y: 300), CGPoint(x: 470,y: 599),
                      CGPoint(x: -1,y: 300), CGPoint(x: CGFloat.infinity,y: 300),
                      p.point(column: -0.01,row: 2.5), p.point(column: 9.01,row: 2.5),
                      p.point(column: 4.5,row: -0.01), p.point(column: 4.5,row: 5.01)] {
            XCTAssertNil(p.cell(at: point))
        }
        XCTAssertNil(GardenProjection(size: .zero).cell(at: .zero))
    }

    func testUprightLaneFrameMatchesProjectedAnchorsAndEnemyEntrances() {
        let size = CGSize(width: 1200, height: 680)
        let p = GardenProjection(size: size)
        let logical = CGSize(width: size.width*0.78,height: size.height*0.69)
        for row in 0..<5 {
            let origin = p.laneOrigin(row: row, logicalSize: logical)
            let s = p.depthScale(CGFloat(row)+0.5)
            for column in [-0.5, 0.5, 4.5, 8.5, 9.95] {
                let projected = p.point(column: column, row: CGFloat(row)+0.5)
                XCTAssertEqual(origin.x + column*logical.width/9*s, projected.x, accuracy: 0.00001)
                XCTAssertEqual(origin.y + (CGFloat(row)+0.5)*logical.height/5*s, projected.y, accuracy: 0.00001)
            }

        }
        XCTAssertLessThan(p.spriteScale(row: 0), p.spriteScale(row: 4))
        let farWidth = p.point(column:9,row:0).x-p.point(column:0,row:0).x
        let nearWidth = p.point(column:9,row:5).x-p.point(column:0,row:5).x
        XCTAssertLessThan(farWidth,nearWidth)
        XCTAssertLessThan(p.point(column:0,row:1).y-p.point(column:0,row:0).y,
                          p.point(column:0,row:5).y-p.point(column:0,row:4).y)
    }
}
