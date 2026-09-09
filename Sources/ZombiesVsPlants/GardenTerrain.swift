import SwiftUI

@MainActor
enum GardenTerrain {
    static func polygon(_ points: [CGPoint]) -> Path {
        Path { p in
            guard let first = points.first else { return }
            p.move(to: first)
            for point in points.dropFirst() { p.addLine(to: point) }
            p.closeSubpath()
        }
    }

    static func lane(_ projection: GardenProjection, row: Int, inset: CGFloat = 0) -> Path {
        polygon([
            projection.point(column: 0, row: CGFloat(row) + inset),
            projection.point(column: 9, row: CGFloat(row) + inset),
            projection.point(column: 9, row: CGFloat(row + 1) - inset),
            projection.point(column: 0, row: CGFloat(row + 1) - inset)
        ])
    }

    static func draw(context: inout GraphicsContext, projection p: GardenProjection, time: Double,
                     waterLanes: Set<Int>, hazard: TerrainHazard? = nil) {
        let size = p.size
        let bounds = CGRect(origin: .zero, size: size)
        context.fill(Path(bounds), with: .linearGradient(
            Gradient(colors: [Color(red: 0.12, green: 0.25, blue: 0.23),
                              Color(red: 0.29, green: 0.40, blue: 0.28)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

        // A single stream bends around the garden, never through the planting cells.
        var stream = Path()
        stream.move(to: CGPoint(x: size.width * 0.79, y: size.height * 0.12))
        stream.addCurve(to: CGPoint(x: size.width * 0.87, y: size.height * 0.94),
                        control1: CGPoint(x: size.width * 0.96, y: size.height * 0.37),
                        control2: CGPoint(x: size.width * 0.87, y: size.height * 0.68))
        stream.addQuadCurve(to: CGPoint(x: size.width * 0.08, y: size.height * 0.98),
                            control: CGPoint(x: size.width * 0.52, y: size.height * 1.06))
        context.stroke(stream, with: .color(Color(red: 0.07, green: 0.15, blue: 0.14)),
                       style: StrokeStyle(lineWidth: size.width * 0.11, lineCap: .round))
        context.stroke(stream, with: .linearGradient(
            Gradient(colors: [Color(red: 0.22, green: 0.57, blue: 0.57),
                              Color(red: 0.08, green: 0.30, blue: 0.35)]),
            startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)),
                       style: StrokeStyle(lineWidth: size.width * 0.075, lineCap: .round))
        for i in 0..<45 {
            let y = size.height * (0.22 + CGFloat(i % 20) * 0.036)
            let x = size.width * (0.88 + sin(CGFloat(i) * 1.7) * 0.016)
            let a = CGPoint(x: x + sin(time + Double(i)) * 3, y: y)
            var ripple = Path()
            ripple.move(to: a)
            ripple.addQuadCurve(to: CGPoint(x: a.x + 15, y: a.y - 1),
                                control: CGPoint(x: a.x + 7, y: a.y - 3))
            context.stroke(ripple, with: .color(.mint.opacity(0.27)), lineWidth: 1)
        }

        for row in 0..<5 {
            let far = p.point(column: 0, row: CGFloat(row))
            let near = p.point(column: 9, row: CGFloat(row + 1))
            let turf = lane(p, row: row)
            context.fill(turf.offsetBy(dx: 0, dy: 8), with: .color(.black.opacity(0.4)))
            context.fill(turf, with: .linearGradient(
                Gradient(colors: [Color(red: 0.34, green: 0.49, blue: 0.22),
                                  Color(red: 0.49, green: 0.62, blue: 0.28),
                                  Color(red: 0.23, green: 0.39, blue: 0.18)]),
                startPoint: far, endPoint: CGPoint(x: far.x, y: near.y)))
            // Seeded damp lanes retain their gameplay identity as subtle wet moss.
            if waterLanes.contains(row) {
                context.fill(turf, with: .color(.teal.opacity(0.14)))
            }
            if let hazard, hazard.lanes.contains(row) {
                let hazardColor: Color = switch hazard.kind {
                case .wet: .teal
                case .frost: .cyan
                case .shadow: .purple
                }
                context.fill(turf, with: .color(hazardColor.opacity(0.18)))
                for stripe in 0..<7 {
                    let y = CGFloat(stripe + 1) / 8
                    let start = p.point(column: 0, row: CGFloat(row) + y)
                    let end = p.point(column: 9, row: CGFloat(row) + y)
                    var mark = Path()
                    mark.move(to: start)
                    mark.addLine(to: end)
                    context.stroke(mark, with: .color(hazardColor.opacity(0.24)),
                                   style: StrokeStyle(lineWidth: 1.5, dash: [4, 8]))
                }
            }
            for i in 0..<120 {
                let col = CGFloat((i * 47 + row * 19) % 997) / 997 * 9
                let depth = CGFloat(row) + 0.12 + CGFloat((i * 31) % 97) / 97 * 0.70
                let q = p.point(column: col, row: depth)
                let s = p.depthScale(depth)
                context.fill(Path(ellipseIn: CGRect(x: q.x, y: q.y, width: 9*s, height: 2*s)),
                             with: .color((i % 3 == 0 ? Color.yellow : Color.black).opacity(0.08)))
                if i.isMultiple(of: 4) {
                    var blades = Path()
                    blades.move(to: q)
                    blades.addLine(to: CGPoint(x: q.x - 2*s, y: q.y - 4*s))
                    blades.move(to: q)
                    blades.addLine(to: CGPoint(x: q.x + 3*s, y: q.y - 3*s))
                    context.stroke(blades, with: .color(.yellow.opacity(0.16)), lineWidth: 1)
                }
            }
            // Small planting guides, not checkerboard tiles, preserve continuous terraces.
            for col in 0..<9 {
                let q = p.point(column: CGFloat(col) + 0.5, row: CGFloat(row) + 0.5)
                let r = 19 * p.spriteScale(row: row)
                context.stroke(Path(ellipseIn: CGRect(x: q.x-r, y: q.y-r*0.30, width: r*2, height: r*0.6)),
                               with: .color(.white.opacity(0.12)), style: StrokeStyle(lineWidth: 1, dash: [2, 5]))
            }
            for i in 0..<34 {
                let q = p.point(column: CGFloat(i) * 9 / 34, row: CGFloat(row + 1))
                rock(context: &context, at: CGPoint(x:q.x,y:q.y+CGFloat((i*7+row)%5)-2),
                     size: CGSize(width: size.width * (0.023+CGFloat(i%3)*0.003) * p.depthScale(CGFloat(row + 1)),
                                  height: 6 + CGFloat((i*3+row) % 5)), seed: i)
            }
            let entrance = p.point(column: 9, row: CGFloat(row) + 0.5)
            let bridgeWidth = size.width * (0.93 - entrance.x / size.width)
            let bridge = CGRect(x: entrance.x - 4, y: entrance.y - 10, width: bridgeWidth, height: 20)
            context.fill(Path(roundedRect: bridge.offsetBy(dx: 1, dy: 6), cornerRadius: 5),
                         with: .color(.black.opacity(0.45)))
            context.fill(Path(roundedRect: bridge, cornerRadius: 5), with: .linearGradient(
                Gradient(colors: [Color(red: 0.76, green: 0.74, blue: 0.61), Color(red: 0.39, green: 0.43, blue: 0.37)]),
                startPoint: CGPoint(x: 0, y: bridge.minY), endPoint: CGPoint(x: 0, y: bridge.maxY)))
            for j in 1..<5 {
                let x = bridge.minX + bridge.width * CGFloat(j) / 5
                var seam = Path()
                seam.move(to: CGPoint(x: x, y: bridge.minY + 2))
                seam.addLine(to: CGPoint(x: x-2, y: bridge.maxY-2))
                context.stroke(seam, with: .color(.black.opacity(0.25)), lineWidth: 1)
            }
        }
        drawBuilding(context: &context, size: size)
        drawGate(context: &context, size: size)
        // Peripheral vegetation leaves every playable lane and enemy entrance exposed.
        for i in 0..<30 {
            let right = i.isMultiple(of: 2)
            let x = size.width * (right ? 0.975 : 0.025)
            let y = size.height * (0.20 + CGFloat(i / 2) * 0.051)
            rock(context: &context, at: CGPoint(x: x, y: y), size: CGSize(width: 24 + CGFloat(i % 4)*6, height: 18), seed: i)
            fern(context: &context, at: CGPoint(x: x, y: y), scale: 0.7 + CGFloat(i % 3)*0.2)
        }
        for i in 0..<16 {
            let x = size.width * (0.83 + CGFloat(i % 8) * 0.022)
            let y = size.height * (i < 8 ? 0.15 : 0.97)
            var stalk = Path()
            stalk.move(to: CGPoint(x: x, y: y))
            stalk.addLine(to: CGPoint(x: x+3, y: y-50))
            context.stroke(stalk, with: .color(Color(red: 0.39, green: 0.57, blue: 0.24)), lineWidth: 4)
            for j in 0..<4 {
                let q = CGPoint(x: x + 2, y: y - CGFloat(j)*12)
                context.fill(polygon([q, CGPoint(x:q.x+17,y:q.y-13), CGPoint(x:q.x+5,y:q.y-5)]),
                             with: .color(Color(red: 0.16, green: 0.35, blue: 0.19)))
            }
        }
        for (x, y, s) in [(0.08,0.19,1.0), (0.91,0.17,1.1), (0.02,0.84,0.7), (0.96,0.86,0.7)] {
            maple(context: &context, at: CGPoint(x: size.width*x, y: size.height*y),
                  scale: min(size.width/850, size.height/540)*s, time: time)
        }
        for row in [0, 2, 4] {
            let left = p.point(column: -0.38, row: CGFloat(row) + 0.6)
            lantern(context: &context, at: left, scale: p.depthScale(CGFloat(row)))
            lantern(context: &context, at: CGPoint(x: size.width*0.95, y: left.y), scale: 0.85)
        }
    }

    private static func rock(context: inout GraphicsContext, at q: CGPoint, size: CGSize, seed: Int) {
        let w = size.width, h = size.height
        let shape = polygon([CGPoint(x:q.x-w*0.5,y:q.y), CGPoint(x:q.x-w*0.35,y:q.y-h*0.7),
                             CGPoint(x:q.x+w*0.14,y:q.y-h), CGPoint(x:q.x+w*0.5,y:q.y-h*0.25),
                             CGPoint(x:q.x+w*0.4,y:q.y+h*0.2), CGPoint(x:q.x-w*0.3,y:q.y+h*0.25)])
        context.fill(shape.offsetBy(dx: 1, dy: 3), with: .color(.black.opacity(0.35)))
        context.fill(shape, with: .linearGradient(
            Gradient(colors: [Color(red: 0.60, green: 0.62, blue: 0.48), Color(red: 0.25, green: 0.30, blue: 0.25)]),
            startPoint: CGPoint(x:q.x-w/2,y:q.y-h), endPoint: CGPoint(x:q.x+w/2,y:q.y+h/2)))
        if seed % 3 != 0 {
            context.fill(Path(ellipseIn: CGRect(x:q.x-w*0.35,y:q.y-h*0.7,width:w*0.65,height:h*0.4)),
                         with: .color(Color(red: 0.32, green: 0.44, blue: 0.16).opacity(0.85)))
        }
    }

    private static func fern(context: inout GraphicsContext, at p: CGPoint, scale s: CGFloat) {
        for i in -2...2 {
            let end = CGPoint(x:p.x+CGFloat(i)*10*s,y:p.y-(22-CGFloat(abs(i))*4)*s)
            var stem = Path(); stem.move(to:p); stem.addLine(to:end)
            context.stroke(stem, with: .color(.green.opacity(0.55)), lineWidth: 1)
            for j in 1...4 {
                let t = CGFloat(j)/5
                let q = CGPoint(x:p.x+(end.x-p.x)*t,y:p.y+(end.y-p.y)*t)
                context.fill(polygon([q,CGPoint(x:q.x-7*s,y:q.y-5*s),CGPoint(x:q.x,y:q.y-2*s),
                                      CGPoint(x:q.x+6*s,y:q.y-6*s)]),
                             with:.color(Color(red:0.22,green:0.43,blue:0.22)))
            }
        }
    }

    private static func maple(context: inout GraphicsContext, at p: CGPoint, scale s: CGFloat, time: Double) {
        var trunk = Path(); trunk.move(to:p); trunk.addQuadCurve(to:CGPoint(x:p.x-9*s,y:p.y-62*s),
                                                               control:CGPoint(x:p.x+12*s,y:p.y-35*s))
        context.stroke(trunk, with:.color(Color(red:0.20,green:0.15,blue:0.12)), style:StrokeStyle(lineWidth:8*s,lineCap:.round))
        for i in 0..<42 {
            let angle = Double(i)*2.4
            let radius = sqrt(Double(i)/42)*55*Double(s)
            let q = CGPoint(x:p.x+cos(angle)*radius+sin(time*0.6+Double(i))*s,
                            y:p.y-65*s+sin(angle)*radius*0.46)
            let r = (10+CGFloat(i%4))*s
            let color = i%3 == 0 ? Color(red:0.83,green:0.26,blue:0.13) : Color(red:0.51,green:0.10,blue:0.09)
            var cluster = Path()
            for j in 0..<14 {
                let a = Double(j)*Double.pi/7 + angle
                let reach = j.isMultiple(of:2) ? r : r*0.53
                let v = CGPoint(x:q.x+cos(a)*reach,y:q.y+sin(a)*reach*0.65)
                if j == 0 { cluster.move(to:v) } else { cluster.addLine(to:v) }
            }
            cluster.closeSubpath()
            context.fill(cluster, with:.radialGradient(Gradient(colors:[color,Color(red:0.29,green:0.10,blue:0.10)]),
                                                        center:CGPoint(x:q.x-r*0.3,y:q.y-r*0.3),startRadius:0,endRadius:r*1.4))
            var vein = Path(); vein.move(to:q); vein.addLine(to:CGPoint(x:q.x+r*0.45,y:q.y-r*0.25))
            context.stroke(vein,with:.color(.orange.opacity(0.23)),lineWidth:0.7*s)
        }
    }

    private static func lantern(context: inout GraphicsContext, at p: CGPoint, scale s: CGFloat) {
        context.fill(Path(ellipseIn:CGRect(x:p.x-22*s,y:p.y-32*s,width:44*s,height:44*s)),
                     with:.radialGradient(Gradient(colors:[.orange.opacity(0.28),.clear]),
                                          center:CGPoint(x:p.x,y:p.y-10*s),startRadius:0,endRadius:22*s))
        context.fill(Path(CGRect(x:p.x-3*s,y:p.y-16*s,width:6*s,height:18*s)),with:.color(.gray))
        context.fill(Path(CGRect(x:p.x-7*s,y:p.y-28*s,width:14*s,height:14*s)),
                     with:.linearGradient(Gradient(colors:[.yellow, .orange]),startPoint:CGPoint(x:p.x,y:p.y-28*s),endPoint:p))
        context.fill(polygon([CGPoint(x:p.x-12*s,y:p.y-28*s),CGPoint(x:p.x,y:p.y-36*s),
                              CGPoint(x:p.x+12*s,y:p.y-28*s)]),with:.color(Color(red:0.24,green:0.29,blue:0.25)))
    }

    private static func drawGate(context: inout GraphicsContext, size: CGSize) {
        let x = size.width*0.48, y = size.height*0.17, s = min(size.width/850,size.height/540)
        for dx in [-54.0,54.0] {
            let rect = CGRect(x:x+dx*s,y:y-69*s,width:10*s,height:71*s)
            context.fill(Path(rect),with:.linearGradient(Gradient(colors:[.red,Color(red:0.35,green:0.08,blue:0.06)]),
                                                         startPoint:CGPoint(x:rect.minX,y:0),endPoint:CGPoint(x:rect.maxX,y:0)))
        }
        var roof = Path()
        roof.move(to:CGPoint(x:x-80*s,y:y-74*s)); roof.addQuadCurve(to:CGPoint(x:x+80*s,y:y-74*s),control:CGPoint(x:x,y:y-57*s))
        context.stroke(roof,with:.color(Color(red:0.12,green:0.16,blue:0.14)),style:StrokeStyle(lineWidth:12*s,lineCap:.round))
        context.stroke(roof.offsetBy(dx:0,dy:7*s),with:.color(Color(red:0.71,green:0.17,blue:0.09)),lineWidth:6*s)
        context.fill(Path(CGRect(x:x-65*s,y:y-43*s,width:130*s,height:7*s)),with:.color(Color(red:0.64,green:0.13,blue:0.08)))
    }

    private static func drawBuilding(context: inout GraphicsContext, size: CGSize) {
        let x = size.width*0.005, y = size.height*0.25, w = size.width*0.10, h = size.height*0.31
        context.fill(Path(CGRect(x:x,y:y,width:w,height:h)),with:.color(Color(red:0.31,green:0.23,blue:0.17)))
        context.fill(Path(CGRect(x:x+4,y:y+10,width:w*0.62,height:h-20)),with:.color(Color(red:0.72,green:0.66,blue:0.47)))
        for i in 1..<6 {
            let yy = y+CGFloat(i)*h/6
            context.fill(Path(CGRect(x:x+4,y:yy,width:w*0.62,height:2)),with:.color(.brown))
        }
        for i in 1..<4 {
            context.fill(Path(CGRect(x:x+CGFloat(i)*w*0.16,y:y+10,width:2,height:h-20)),with:.color(.brown))
        }
        let roof = polygon([CGPoint(x:x-5,y:y),CGPoint(x:x+w*0.36,y:y-h*0.30),
                            CGPoint(x:x+w*1.16,y:y-h*0.12),CGPoint(x:x+w*1.35,y:y+5)])
        context.fill(roof,with:.linearGradient(Gradient(colors:[Color(red:0.33,green:0.39,blue:0.35),.black]),
                                               startPoint:CGPoint(x:x,y:y-h*0.3),endPoint:CGPoint(x:x,y:y+5)))
    }
}
