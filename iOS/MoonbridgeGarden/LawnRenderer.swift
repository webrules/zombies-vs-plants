import SwiftUI

@MainActor
enum LawnRenderer {
    static func draw(context: inout GraphicsContext, size: CGSize, game: GameModel, hoveredCell: GridCell? = nil) {
        guard size.width > 0, size.height > 0 else { return }
        let projection = GardenProjection(size: size)
        GardenTerrain.draw(context: &context, projection: projection, time: game.elapsed,
                           waterLanes: game.waterLanes, hazard: game.terrainHazard)
        if let cell = hoveredCell {
            let c = CGFloat(cell.column), r = CGFloat(cell.row)
            let outline = GardenTerrain.polygon([
                projection.point(column:c,row:r), projection.point(column:c+1,row:r),
                projection.point(column:c+1,row:r+1), projection.point(column:c,row:r+1)
            ])
            context.fill(outline,with:.color(.yellow.opacity(0.12)))
            context.stroke(outline,with:.color(.yellow.opacity(0.65)),lineWidth:1.5)
        }
        let logicalSize = CGSize(width: size.width * 0.78, height: size.height * 0.69)
        for row in 0..<GameModel.rows {
            var laneContext = context
            let origin = projection.laneOrigin(row: row, logicalSize: logicalSize)
            let scale = projection.depthScale(CGFloat(row) + 0.5)
            laneContext.translateBy(x: origin.x, y: origin.y)
            laneContext.scaleBy(x: scale, y: scale)
            drawLane(context: &laneContext, size: logicalSize, game: game, row: row)
        }
        drawCornFlight(context: &context, projection: projection, game: game)
        for zombie in game.zombies where zombie.strikeCharge > 0 {
            guard let target = zombie.lightningTarget else { continue }
            let q = projection.point(column: CGFloat(target.column)+0.5, row: CGFloat(target.row)+0.5)
            let s = projection.spriteScale(row: target.row)
            let r = 28*s
            var bolt = Path()
            bolt.move(to: CGPoint(x:q.x+12*s,y:q.y-110*s))
            bolt.addLine(to: CGPoint(x:q.x-7*s,y:q.y-65*s))
            bolt.addLine(to: CGPoint(x:q.x+10*s,y:q.y-65*s))
            bolt.addLine(to: q)
            context.stroke(bolt,with:.color(.cyan.opacity(0.65)),style:StrokeStyle(lineWidth:3*s,lineJoin:.round))
            context.stroke(Path(ellipseIn:CGRect(x:q.x-r,y:q.y-r*0.35,width:r*2,height:r*0.7)),
                           with:.color(.cyan),style:StrokeStyle(lineWidth:3,dash:[5,4]))
            context.draw(Text("LIGHTNING TARGET").font(.system(size: max(9,10*s),weight:.black)).foregroundStyle(.white),
                         at:CGPoint(x:q.x,y:q.y-40*s))
        }
        if game.waveBannerRemaining > 0 {
            let t = game.waveBannerRemaining / 2.2
            let alpha = min(1, (1-t)*5) * min(1, t*3)
            let banner = CGRect(x: size.width*0.12, y: size.height*0.43, width: size.width*0.76, height: 64)
            context.fill(Path(roundedRect: banner, cornerRadius: 18), with: .color(.black.opacity(alpha*0.75)))
            let label = game.wave == 3 ? "FINAL WAVE • FOUR BOSSES APPROACH" : "GARDEN WAVE \(game.wave)"
            context.draw(Text(label).font(.system(size: min(24, size.width/28), weight: .black, design: .rounded)).foregroundStyle(.yellow.opacity(alpha)), at: CGPoint(x: banner.midX, y: banner.midY))
        }
        if game.isPaused {
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.45)))
            context.draw(Text("PAUSED").font(.system(size: 46, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: size.width/2, y: size.height/2))
        }
    }

    private static func drawLane(context: inout GraphicsContext, size: CGSize, game: GameModel, row: Int) {
        let cw = size.width / CGFloat(GameModel.columns)
        let rh = size.height / CGFloat(GameModel.rows)

        for (cell, plant) in game.plants.sorted(by: { $0.key.column < $1.key.column }) where cell.row == row {
            let bob = sin(game.elapsed * 2.6 + Double(cell.column)) * 2.2
            let center = CGPoint(x: (CGFloat(cell.column) + 0.5) * cw, y: (CGFloat(cell.row) + 0.5) * rh - 26 * min(cw,rh)/82 + bob)
            groundShadow(context: &context, at: CGPoint(x:center.x,y:(CGFloat(row)+0.5)*rh),
                         width: 42*min(cw,rh)/82, depth: 10*min(cw,rh)/82)
            drawLitSprite(context: &context, center: center, scale: min(cw, rh) / 82) { layer in
                drawPlant(context: &layer, plant: plant, center: center, scale: min(cw, rh) / 82, time: game.elapsed)
            }
        }

        if let tanuki = game.tanukiEvent, tanuki.row == row {
            let center = CGPoint(x: size.width * 0.50 + CGFloat(sin(game.elapsed * 7)) * 9,
                                 y: (CGFloat(tanuki.row) + 0.48) * rh)
            let r = min(cw, rh) * 0.19
            drawContactShadow(context: &context, center: center, width: r * 2.5, depth: r * 0.45, opacity: 0.32)
            context.fill(Path(ellipseIn: CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2)), with: .radialGradient(Gradient(colors: [Color(red: 0.76, green: 0.57, blue: 0.34), .brown, Color(red: 0.20, green: 0.15, blue: 0.11)]), center: CGPoint(x: center.x-r*0.4,y:center.y-r*0.5), startRadius: 0, endRadius: r*1.7))
            context.fill(Path(ellipseIn: CGRect(x: center.x-r*0.72, y: center.y-r*0.52, width: r*0.30, height: r*0.24)), with: .color(.white))
            context.fill(Path(ellipseIn: CGRect(x: center.x+r*0.42, y: center.y-r*0.52, width: r*0.30, height: r*0.24)), with: .color(.white))
            context.fill(Path(ellipseIn: CGRect(x: center.x-r*0.18, y: center.y-r*0.12, width: r*0.36, height: r*0.28)), with: .color(.black))
            context.draw(Text("TANUKI TRICK!  •  CARD DISGUISE").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.yellow), at: CGPoint(x: size.width * 0.5, y: center.y - rh * 0.33))
        }

        for (cell, plant) in game.plants where cell.row == row && plant.kind == .charmMushroom {
            if let targetID = plant.charmTargetID, let target = game.zombies.first(where: { $0.id == targetID }) {
                let mushroom = CGPoint(x:(CGFloat(cell.column)+0.5)*cw,y:(CGFloat(cell.row)+0.5)*rh-44*min(cw,rh)/82)
                let targetPoint = CGPoint(x:(CGFloat(target.x)+0.5)*cw,y:(CGFloat(target.row)+0.5)*rh)
                var path=Path(); path.move(to:mushroom); path.addLine(to:targetPoint)
                context.stroke(path,with:.color(.purple.opacity(0.55)),style:StrokeStyle(lineWidth:2,dash:[5,5]))
                let r=min(cw,rh)*0.22
                context.stroke(Path(ellipseIn:CGRect(x:targetPoint.x-r,y:targetPoint.y-r,width:r*2,height:r*2)),with:.color(.purple.opacity(0.8)),style:StrokeStyle(lineWidth:3,dash:[6,4]))
                context.draw(Text("CHARM TARGET").font(.system(size:9,weight:.black,design:.rounded)).foregroundStyle(.white),at:CGPoint(x:targetPoint.x,y:targetPoint.y-r*1.6))
            }
        }

        if let charm = game.charmBurst, charm.row == row {
            let y=(CGFloat(charm.row)+0.5)*rh
            for i in 0..<8 {
                let x=(CGFloat(i)+0.5)*cw+sin(game.elapsed*5+Double(i))*10
                let r=min(cw,rh)*CGFloat(0.10+0.025*sin(game.elapsed*8+Double(i)))
                context.fill(Path(ellipseIn:CGRect(x:x-r,y:y-r*2.4,width:r*2,height:r*4.8)),with:.color(.purple.opacity(charm.remaining/0.72)))
            }
            context.draw(Text("CHARMED!").font(.system(size:14,weight:.black,design:.rounded)).foregroundStyle(.purple.opacity(charm.remaining/0.72)),at:CGPoint(x:size.width/2,y:y-rh*0.36))
        }

        for pea in game.peas where pea.row == row {
            let ground = CGPoint(x:(CGFloat(pea.x)+0.5)*cw,y:(CGFloat(pea.row)+0.5)*rh)
            let center = CGPoint(x: ground.x, y: ground.y-44*min(cw,rh)/82)
            let radius = max(4, min(cw, rh) * 0.075)
            groundShadow(context:&context,at:ground,width:radius*2,depth:radius*0.55)
            var trail = Path()
            trail.move(to: CGPoint(x: center.x - radius * 4.2, y: center.y))
            trail.addLine(to: CGPoint(x: center.x - radius, y: center.y))
            let shotColor: Color = pea.flaming ? .orange : pea.icy ? .cyan : .green
            context.stroke(trail, with: .linearGradient(Gradient(colors: [.clear, shotColor.opacity(0.72)]), startPoint: CGPoint(x: center.x-radius*4, y: center.y), endPoint: center), style: StrokeStyle(lineWidth: radius * 0.8, lineCap: .round))
            let peaColors: [Color] = pea.flaming ? (pea.steamed ? [.white, .orange, .cyan] : [.yellow, .orange, .red]) : pea.icy ? [.white, .cyan, .blue] : [.yellow, Color(red: 0.35, green: 0.85, blue: 0.20), Color(red:0.09,green:0.32,blue:0.11)]
            context.fill(Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2)), with: .radialGradient(Gradient(colors: peaColors), center: center, startRadius: 0, endRadius: radius))
            context.fill(Path(ellipseIn: CGRect(x: center.x-radius*0.45, y: center.y-radius*0.55, width: radius*0.65, height: radius*0.55)), with: .color(.white.opacity(0.65)))
            context.stroke(Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2)), with: .color(.black.opacity(0.25)), lineWidth: 1.5)
        }

        if let burst = game.pepperBurst, burst.row == row {
            let y = (CGFloat(burst.row) + 0.52) * rh
            context.fill(Path(CGRect(x: 0, y: y-rh*0.32, width: size.width, height: rh*0.64)), with: .linearGradient(Gradient(colors: [.red.opacity(0.06), .orange.opacity(0.34), .red.opacity(0.08)]), startPoint: CGPoint(x: 0, y: y), endPoint: CGPoint(x: size.width, y: y)))
            for column in 0..<GameModel.columns {
                let x = (CGFloat(column)+0.5)*cw
                let flare = 0.55 + CGFloat(sin(game.elapsed*24 + Double(column))) * 0.18
                var flame = Path()
                flame.move(to: CGPoint(x:x-cw*0.23,y:y+rh*0.24))
                flame.addQuadCurve(to: CGPoint(x:x,y:y-rh*0.30-flare*rh*0.12), control: CGPoint(x:x-cw*0.08,y:y-rh*0.18))
                flame.addQuadCurve(to: CGPoint(x:x+cw*0.23,y:y+rh*0.24), control: CGPoint(x:x+cw*0.08,y:y-rh*0.11))
                flame.closeSubpath()
                context.fill(flame, with: .linearGradient(Gradient(colors:[.yellow.opacity(0.95),.orange.opacity(0.9),.red.opacity(0.55)]), startPoint: CGPoint(x:x,y:y-rh*0.3), endPoint: CGPoint(x:x,y:y+rh*0.25)))
            }
            context.draw(Text("RED HOT!  •  LANE CLEAR").font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(.white.opacity(0.85)), at: CGPoint(x:size.width/2,y:y-rh*0.34))
        }

        if let target = game.cornTarget, target.row == row {
            let center = CGPoint(x:(CGFloat(target.column)+0.5)*cw, y:(CGFloat(target.row)+0.5)*rh)
            let r = min(cw,rh)*0.28
            context.stroke(Path(ellipseIn:CGRect(x:center.x-r,y:center.y-r*0.4,width:r*2,height:r*0.8)),with:.color(.yellow.opacity(0.92)),style:StrokeStyle(lineWidth:3,dash:[7,5]))
            var cross=Path(); cross.move(to:CGPoint(x:center.x-r*1.5,y:center.y)); cross.addLine(to:CGPoint(x:center.x+r*1.5,y:center.y)); cross.move(to:CGPoint(x:center.x,y:center.y-r*1.5)); cross.addLine(to:CGPoint(x:center.x,y:center.y+r*1.5)); context.stroke(cross,with:.color(.red.opacity(0.9)),lineWidth:2)
            context.draw(Text("TARGET").font(.system(size:10,weight:.black,design:.rounded)).foregroundStyle(.white),at:CGPoint(x:center.x,y:center.y-r*1.75))
        }
        if let blast = game.cornBlast, blast.cell.row == row {
            let t = blast.remaining / 0.82
            let center = CGPoint(x:(CGFloat(blast.cell.column)+0.5)*cw,y:(CGFloat(blast.cell.row)+0.5)*rh)
            let radius = min(cw,rh)*CGFloat(0.4+1.5*(1-t))
            context.fill(Path(ellipseIn:CGRect(x:center.x-radius,y:center.y-radius,width:radius*2,height:radius*2)),with:.radialGradient(Gradient(colors:[.yellow.opacity(t),.orange.opacity(t*0.75),.clear]),center:center,startRadius:0,endRadius:radius))
            context.stroke(Path(ellipseIn:CGRect(x:center.x-radius,y:center.y-radius,width:radius*2,height:radius*2)),with:.color(.red.opacity(t)),lineWidth:4)
        }

        for orb in game.iceOrbs where orb.row == row {
            let ground = CGPoint(x:(CGFloat(orb.x)+0.5)*cw,y:(CGFloat(orb.row)+0.5)*rh)
            let center = CGPoint(x: ground.x, y: ground.y-44*min(cw,rh)/82)
            let r = min(cw,rh)*0.13
            groundShadow(context:&context,at:ground,width:r*2.4,depth:r*0.6)
            var trail = Path(); trail.move(to: CGPoint(x: center.x+r, y:center.y)); trail.addLine(to: CGPoint(x:center.x+r*4.2,y:center.y))
            context.stroke(trail, with: .linearGradient(Gradient(colors: [.cyan.opacity(0.8), .clear]), startPoint: center, endPoint: CGPoint(x:center.x+r*4,y:center.y)), style: StrokeStyle(lineWidth:r*1.15,lineCap:.round))
            context.fill(Path(ellipseIn:CGRect(x:center.x-r*1.7,y:center.y-r*1.7,width:r*3.4,height:r*3.4)), with:.radialGradient(Gradient(colors:[.white.opacity(0.85),.cyan.opacity(0.55),.blue.opacity(0.05)]),center:center,startRadius:0,endRadius:r*1.7))
            for i in 0..<6 {
                let a = Double(i) * Double.pi / 3 + orb.age * 5
                let p = CGPoint(x:center.x+cos(a)*r*1.3,y:center.y+sin(a)*r*1.3)
                context.fill(Path(ellipseIn:CGRect(x:p.x-2,y:p.y-2,width:4,height:4)),with:.color(.white))
            }
        }

        for sun in game.sunSparks where sun.cell.row == row {
            let t = sun.age / 1.35
            let center = CGPoint(x: (CGFloat(sun.cell.column) + 0.5) * cw + sin(t * Double.pi * 2) * 8,
                                 y: (CGFloat(sun.cell.row) + 0.42) * rh - CGFloat(t) * rh * 0.72)
            let radius = min(cw, rh) * CGFloat(0.13 + sin(t * Double.pi) * 0.05)
            context.fill(Path(ellipseIn: CGRect(x: center.x-radius*1.7, y: center.y-radius*1.7, width: radius*3.4, height: radius*3.4)), with: .radialGradient(Gradient(colors: [.yellow.opacity(0.7 * (1-t)), .clear]), center: center, startRadius: 0, endRadius: radius*1.7))
            context.fill(Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2)), with: .color(.yellow.opacity(1-t*0.8)))
            context.draw(Text("+25").font(.caption.bold()).foregroundStyle(.white.opacity(1-t)), at: CGPoint(x: center.x, y: center.y-radius*1.7))
        }

        for zombie in game.zombies.sorted(by: { $0.x < $1.x }) where zombie.row == row {
            let ground = CGPoint(x:(CGFloat(zombie.x)+0.5)*cw,y:(CGFloat(row)+0.5)*rh)
            let engaged: Bool
            if zombie.charmed {
                engaged = game.zombies.contains {
                    !$0.charmed && $0.row == row && $0.x > zombie.x && $0.x - zombie.x < 0.95
                }
            } else {
                engaged = game.plants.keys.contains {
                    $0.row == row && Double($0.column) <= zombie.x && zombie.x - Double($0.column) < 0.78
                }
            }
            ZombieRenderer.draw(context: &context, zombie: zombie, ground: ground,
                                scale: min(cw, rh) / 82 * 0.90, engaged: engaged)
        }

        drawLaneImpacts(context: &context, size: size, game: game, row: row)
    }

        private static func drawLitSprite(context: inout GraphicsContext, center: CGPoint, scale s: CGFloat,
                                          content: (inout GraphicsContext) -> Void) {
            // Lighting is clipped to the actual painted silhouette, including every equipment variant.
            // Uniform scale keeps characters upright; relief comes from illumination, not a skew.
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: Color(red:0.06,green:0.12,blue:0.10).opacity(0.55),
                                        radius: 1.3*s, x: 2*s, y: 2*s))
                layer.drawLayer { sprite in
                    content(&sprite)
                    sprite.blendMode = .sourceAtop
                    let r: CGFloat = 75*s
                    sprite.fill(Path(CGRect(x:center.x-r,y:center.y-r,width:r*2,height:r*2)),
                                with:.linearGradient(Gradient(stops:[
                                    .init(color:Color(red:1,green:0.91,blue:0.66).opacity(0.36),location:0),
                                    .init(color:.clear,location:0.43),
                                    .init(color:Color(red:0.04,green:0.13,blue:0.12).opacity(0.40),location:1)
                                ]),startPoint:CGPoint(x:center.x-r*0.55,y:center.y-r*0.65),
                                   endPoint:CGPoint(x:center.x+r*0.50,y:center.y+r*0.5)))
                }
            }
        }

        private static func drawCornFlight(context: inout GraphicsContext, projection: GardenProjection, game: GameModel) {
            for missile in game.cornMissiles {
                let p = CGFloat(min(1,max(0,missile.progress)))
                let column = CGFloat(missile.origin.column) + 0.5 + CGFloat(missile.target.column-missile.origin.column)*p
                let row = CGFloat(missile.origin.row) + 0.5 + CGFloat(missile.target.row-missile.origin.row)*p
                let ground = projection.point(column:column,row:row)
                let s = projection.spriteScale(row:missile.origin.row)*(1-p) + projection.spriteScale(row:missile.target.row)*p
                let q = CGPoint(x:ground.x,y:ground.y-sin(p * .pi)*projection.size.height*0.22-(1-p)*25*s)
                let r = 9*s
                context.fill(Path(ellipseIn:CGRect(x:ground.x-r,y:ground.y-r*0.25,width:r*2,height:r*0.5)),
                             with:.color(.black.opacity(0.2)))
                var trail = Path(); trail.move(to:CGPoint(x:q.x-22*s,y:q.y+7*s)); trail.addLine(to:q)
                context.stroke(trail,with:.linearGradient(Gradient(colors:[.clear,.orange,.yellow]),
                                                          startPoint:CGPoint(x:q.x-22*s,y:q.y+7*s),endPoint:q),
                               style:StrokeStyle(lineWidth:5*s,lineCap:.round))
                context.fill(Path(ellipseIn:CGRect(x:q.x-r,y:q.y-r,width:r*2,height:r*2)),
                             with:.radialGradient(Gradient(colors:[.white,.yellow,.orange]),center:CGPoint(x:q.x-r*0.3,y:q.y-r*0.4),
                                                  startRadius:0,endRadius:r*1.5))
                var husk = Path(); husk.move(to:CGPoint(x:q.x-r,y:q.y+r*1.6)); husk.addLine(to:CGPoint(x:q.x,y:q.y+r*0.3)); husk.addLine(to:CGPoint(x:q.x+r,y:q.y+r*1.6))
                context.stroke(husk,with:.color(.green),lineWidth:2*s)
            }
        }

    private static func drawLaneImpacts(context: inout GraphicsContext, size: CGSize, game: GameModel, row: Int) {
        let cw = size.width / CGFloat(GameModel.columns)
        let rh = size.height / CGFloat(GameModel.rows)
        if let bomb = game.pendingBomb, bomb.cell.row == row {
            let ground = CGPoint(x:(CGFloat(bomb.cell.column)+0.5)*cw,y:(CGFloat(row)+0.5)*rh)
            let center = CGPoint(x:ground.x,y:ground.y-24*min(cw,rh)/82)
            groundShadow(context:&context,at:ground,width:55*min(cw,rh)/82,depth:12*min(cw,rh)/82)
            drawLitSprite(context: &context, center: center, scale: min(cw, rh) / 82) { layer in
                drawCherryBomb(context: &layer, center: center, scale: min(cw, rh) / 82,
                               progress: 1 - bomb.remaining / 0.75, time: game.elapsed)
            }
        }

        if let explosion = game.explosion, explosion.cell.row == row {
            let center = CGPoint(x: (CGFloat(explosion.cell.column) + 0.5) * cw, y: (CGFloat(explosion.cell.row) + 0.5) * rh)
            let t = explosion.remaining / 0.65
            let radius = min(cw, rh) * CGFloat(1.8 - t)
            let colors: [Color] = [.yellow.opacity(t), .orange.opacity(t * 0.8), .red.opacity(t * 0.25)]
            for (i, color) in colors.enumerated().reversed() {
                let r = radius * CGFloat(i + 1) / 3
                context.fill(Path(ellipseIn: CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2)), with: .color(color))
            }
        }

        for particle in game.particles where particle.cell.row == row {
            let t = particle.age / particle.life
            let center = CGPoint(x: (CGFloat(particle.cell.column) + 0.5 + particle.dx) * cw,
                                 y: (CGFloat(particle.cell.row) + 0.5 + particle.dy) * rh)
            let radius = min(cw, rh) * CGFloat(0.07 * (1-t) + 0.018)
            let color: Color = switch particle.colorIndex {
            case 0: .yellow; case 1: .orange; case 2: .red; case 4: .cyan; case 5: .orange; case 6: .black.opacity(0.55); case 7: .white; case 8: .cyan; case 9: .purple; default: .brown
            }
            context.fill(Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2)), with: .color(color.opacity(1-t)))
        }

    }

    private static func drawPlant(context: inout GraphicsContext, plant: Plant, center: CGPoint, scale baseScale: CGFloat, time: Double) {
        let entrance = min(1, max(0.08, plant.age / 0.28))
        let bounce = entrance < 1 ? 0.78 + CGFloat(sin(entrance * Double.pi)) * 0.35 : 1
        let s = baseScale * CGFloat(entrance) * bounce
        let recoil = plant.kind == .peaShooter || plant.kind == .gatlingPeaShooter ? CGFloat(plant.recoil / 0.22) * 7*s : 0
        let center = CGPoint(x: center.x - recoil, y: center.y)
        context.stroke(Path(ellipseIn: CGRect(x: center.x-25*s, y: center.y-37*s, width: 50*s, height: 60*s)), with: .color(.black.opacity(0.16)), lineWidth: 2*s)
        if plant.age < 0.55 {
            let glow = baseScale * CGFloat(50 + plant.age * 35)
            context.stroke(Path(ellipseIn: CGRect(x: center.x-glow, y: center.y-glow*0.45, width: glow*2, height: glow*0.9)), with: .color(.white.opacity(1-plant.age/0.55)), lineWidth: 3)
        }
        if plant.hitFlash > 0 {
            let flash = CGRect(x: center.x-35*s, y: center.y-42*s, width: 70*s, height: 82*s)
            context.fill(Path(ellipseIn: flash), with: .color(.red.opacity(plant.hitFlash * 0.8)))
        }
        let stem = CGRect(x: center.x - 4*s, y: center.y - 2*s, width: 8*s, height: 34*s)
        context.fill(Path(roundedRect: stem, cornerRadius: 4*s), with: material(.green, in: stem))
        let leafL = CGRect(x: center.x - 22*s, y: center.y + 15*s, width: 22*s, height: 12*s)
        let leafR = CGRect(x: center.x, y: center.y + 10*s, width: 24*s, height: 13*s)
        context.fill(Path(ellipseIn: leafL), with: .color(.green))
        context.fill(Path(ellipseIn: leafR), with: .color(.green))

        switch plant.kind {
        case .sunflower:
            for i in 0..<12 {
                let angle = CGFloat(i) * CGFloat.pi / 6 + CGFloat(time * 0.16)
                let p = CGPoint(x: center.x + cos(angle)*22*s, y: center.y - 10*s + sin(angle)*22*s)
                context.fill(Path(ellipseIn: CGRect(x: p.x-9*s, y: p.y-6*s, width: 18*s, height: 12*s)), with: .color(.yellow))
            }
            let face = CGRect(x: center.x-18*s, y: center.y-28*s, width: 36*s, height: 36*s)
            context.fill(Path(ellipseIn: face), with: material(Color(red: 0.55, green: 0.27, blue: 0.08), in: face))
            drawFace(context: &context, center: CGPoint(x: center.x, y: center.y-10*s), scale: s, happy: true)
        case .peaShooter:
            let head = CGRect(x: center.x-22*s, y: center.y-29*s, width: 43*s, height: 39*s)
            context.fill(Path(ellipseIn: head), with: material(Color(red: 0.25, green: 0.72, blue: 0.16), in: head))
            let snout = CGRect(x: center.x+12*s, y: center.y-23*s, width: 31*s, height: 24*s)
            context.fill(Path(roundedRect: snout, cornerRadius: 11*s), with: material(Color(red: 0.19, green: 0.62, blue: 0.12), in: snout))
            context.fill(Path(ellipseIn: CGRect(x: center.x+31*s, y: center.y-18*s, width: 8*s, height: 13*s)), with: .color(.black.opacity(0.65)))
            context.fill(Path(ellipseIn: CGRect(x: center.x-5*s, y: center.y-19*s, width: 6*s, height: 8*s)), with: .color(.black))
        case .wallPlant:
            let body = CGRect(x: center.x-27*s, y: center.y-34*s, width: 54*s, height: 67*s)
            context.fill(Path(roundedRect: body, cornerRadius: 18*s), with: material(Color(red: 0.64, green: 0.39, blue: 0.16), in: body))
            context.stroke(Path(roundedRect: body, cornerRadius: 18*s), with: .color(.brown), lineWidth: 3*s)
            drawFace(context: &context, center: CGPoint(x: center.x, y: center.y-6*s), scale: s, happy: false)
        case .cherryBomb: break
        case .redHotPepper:
            drawPepper(context: &context, center: center, scale: s, progress: max(0, min(1, 1 - plant.actionTimer / 0.9)), time: time)
        case .cornCannon:
            drawCornCannon(context: &context, center: center, scale: s, time: time)
        case .charmMushroom:
            drawCharmMushroom(context: &context, center: center, scale: s, progress: max(0, min(1, 1 - plant.actionTimer)), time: time)
        case .icePeaShooter:
            drawIcePeaShooter(context: &context, center: center, scale: s, time: time)
        case .flameStake:
            drawFlameStake(context: &context, center: center, scale: s, time: time)
        case .gatlingPeaShooter:
            drawGatlingPeaShooter(context: &context, center: center, scale: s, time: time, burstShotsRemaining: plant.burstShotsRemaining)
        }

        if plant.freezeTimer > 0 {
            let frost = min(1, plant.freezeTimer / 0.45)
            context.fill(Path(ellipseIn: CGRect(x:center.x-31*s,y:center.y-35*s,width:62*s,height:73*s)), with:.color(.cyan.opacity(0.12+frost*0.12)))
            for i in 0..<7 {
                let a = Double(i) * Double.pi * 2 / 7 + time * 0.45
                let p = CGPoint(x:center.x+cos(a)*30*s,y:center.y+sin(a)*32*s)
                var crystal = Path(); crystal.move(to:CGPoint(x:p.x,y:p.y-7*s)); crystal.addLine(to:CGPoint(x:p.x+4*s,y:p.y)); crystal.addLine(to:CGPoint(x:p.x,y:p.y+7*s)); crystal.addLine(to:CGPoint(x:p.x-4*s,y:p.y)); crystal.closeSubpath()
                context.fill(crystal,with:.color(.cyan.opacity(0.7)))
            }
        }
        if plant.burnTimer > 0 {
            let flame = min(1, plant.burnTimer / 0.5)
            context.draw(Text("🔥").font(.system(size: 14*s)).foregroundStyle(.orange.opacity(flame)), at: CGPoint(x: center.x+25*s, y: center.y-35*s))
        }

        let maxHP: Double = plant.kind == .wallPlant ? 520 : plant.kind == .peaShooter || plant.kind == .icePeaShooter ? 125 : plant.kind == .redHotPepper ? 85 : plant.kind == .cornCannon ? 180 : plant.kind == .charmMushroom ? 90 : plant.kind == .flameStake ? 180 : plant.kind == .gatlingPeaShooter ? 140 : 100
        let ratio = max(0, min(1, plant.hp / maxHP))
        let bar = CGRect(x: center.x-25*s, y: center.y+38*s, width: 50*s, height: 5*s)
        context.fill(Path(roundedRect: bar, cornerRadius: 2*s), with: .color(.black.opacity(0.25)))
        context.fill(Path(roundedRect: CGRect(x: bar.minX, y: bar.minY, width: bar.width*ratio, height: bar.height), cornerRadius: 2*s), with: .color(ratio > 0.4 ? .green : .red))
    }

    private static func drawContactShadow(context: inout GraphicsContext, center: CGPoint, width: CGFloat, depth: CGFloat, opacity: Double) {
        let shadow = CGRect(x: center.x - width * 0.5, y: center.y + depth * 2.1, width: width, height: depth)
        context.fill(Path(ellipseIn: shadow), with: .radialGradient(Gradient(colors: [.black.opacity(min(0.62, opacity + 0.14)), .clear]), center: CGPoint(x: shadow.midX, y: shadow.midY), startRadius: 0, endRadius: width * 0.55))
        var groundLine = Path()
        groundLine.move(to: CGPoint(x: shadow.minX + width * 0.12, y: shadow.midY))
        groundLine.addLine(to: CGPoint(x: shadow.maxX - width * 0.12, y: shadow.midY))
        context.stroke(groundLine, with: .color(.white.opacity(0.10)), lineWidth: max(1, depth * 0.08))
    }

    private static func material(_ color: Color, in rect: CGRect) -> GraphicsContext.Shading {
        .radialGradient(Gradient(stops: [
            .init(color: Color(red: 0.95, green: 0.91, blue: 0.72), location: 0),
            .init(color: color, location: 0.22),
            .init(color: color, location: 0.58),
            .init(color: Color(red: 0.07, green: 0.14, blue: 0.12), location: 1)
        ]), center: CGPoint(x: rect.minX+rect.width*0.27, y: rect.minY+rect.height*0.23),
                        startRadius: 0, endRadius: max(rect.width, rect.height)*0.96)
    }

    private static func groundShadow(context: inout GraphicsContext, at point: CGPoint, width: CGFloat, depth: CGFloat) {
        let rect = CGRect(x:point.x-width/2,y:point.y-depth/2,width:width,height:depth)
        context.fill(Path(ellipseIn:rect),with:.radialGradient(Gradient(colors:[.black.opacity(0.5),.clear]),
                                                               center:point,startRadius:0,endRadius:width*0.55))
    }

    private static func drawFace(context: inout GraphicsContext, center: CGPoint, scale s: CGFloat, happy: Bool) {
        for dx in [-7.0, 7.0] {
            context.fill(Path(ellipseIn: CGRect(x: center.x+CGFloat(dx)*s-2*s, y: center.y-4*s, width: 4*s, height: 6*s)), with: .color(.black))
        }
        var mouth = Path()
        mouth.move(to: CGPoint(x: center.x-7*s, y: center.y+7*s))
        mouth.addQuadCurve(to: CGPoint(x: center.x+7*s, y: center.y+7*s), control: CGPoint(x: center.x, y: center.y+(happy ? 14 : 1)*s))
        context.stroke(mouth, with: .color(.black.opacity(0.7)), lineWidth: 2*s)
    }

    private static func drawPepper(context: inout GraphicsContext, center: CGPoint, scale s: CGFloat, progress: Double, time: Double) {
        let pulse = 1 + CGFloat(sin(time * 18)) * 0.05 + CGFloat(progress) * 0.12
        let r = s * pulse
        if progress > 0 {
            let glow = 28*r*CGFloat(progress)
            context.fill(Path(ellipseIn: CGRect(x:center.x-glow,y:center.y-28*r-glow,width:glow*2,height:glow*2)), with:.radialGradient(Gradient(colors:[.red.opacity(0.28),.clear]),center:center,startRadius:0,endRadius:glow))
        }
        let body = CGRect(x:center.x-17*r,y:center.y-29*r,width:34*r,height:57*r)
        context.fill(Path(roundedRect:body,cornerRadius:16*r),with:material(.red,in:body))
        context.stroke(Path(roundedRect:body,cornerRadius:16*r),with:.color(.red.opacity(0.75)),lineWidth:2*r)
        var tip = Path(); tip.move(to:CGPoint(x:center.x-4*r,y:center.y+24*r)); tip.addQuadCurve(to:CGPoint(x:center.x+18*r,y:center.y+43*r),control:CGPoint(x:center.x+18*r,y:center.y+27*r)); tip.addQuadCurve(to:CGPoint(x:center.x+7*r,y:center.y+24*r),control:CGPoint(x:center.x+13*r,y:center.y+38*r))
        context.fill(tip,with:.color(.red.opacity(0.82)))
        var stem = Path(); stem.move(to:CGPoint(x:center.x-2*r,y:center.y-26*r)); stem.addQuadCurve(to:CGPoint(x:center.x+4*r,y:center.y-40*r),control:CGPoint(x:center.x-11*r,y:center.y-38*r)); stem.addQuadCurve(to:CGPoint(x:center.x+14*r,y:center.y-33*r),control:CGPoint(x:center.x+17*r,y:center.y-45*r))
        context.stroke(stem,with:.color(.green),style:StrokeStyle(lineWidth:5*r,lineCap:.round))
        context.fill(Path(ellipseIn:CGRect(x:center.x-8*r,y:center.y-13*r,width:5*r,height:7*r)),with:.color(.black))
        context.fill(Path(ellipseIn:CGRect(x:center.x+5*r,y:center.y-13*r,width:5*r,height:7*r)),with:.color(.black))
        var mouth=Path(); mouth.move(to:CGPoint(x:center.x-7*r,y:center.y+4*r)); mouth.addQuadCurve(to:CGPoint(x:center.x+7*r,y:center.y+4*r),control:CGPoint(x:center.x,y:center.y+12*r)); context.stroke(mouth,with:.color(.black),lineWidth:2*r)
        if progress > 0 {
            for i in 0..<3 {
                let p = CGPoint(x:center.x+CGFloat(sin(time*20+Double(i)))*18*r,y:center.y-45*r-CGFloat(i)*7*r)
                context.fill(Path(ellipseIn:CGRect(x:p.x-3*r,y:p.y-3*r,width:6*r,height:6*r)),with:.color(i == 0 ? .yellow : .orange))
            }
            context.draw(Text("!\nFIRE").font(.system(size:9*r,weight:.black,design:.rounded)).foregroundStyle(.white),at:CGPoint(x:center.x,y:center.y-54*r))
        }
    }

    private static func drawCornCannon(context: inout GraphicsContext, center: CGPoint, scale s: CGFloat, time: Double) {
        let base = CGRect(x:center.x-30*s,y:center.y+2*s,width:60*s,height:28*s)
        context.fill(Path(roundedRect:base,cornerRadius:9*s),with:material(Color(red:0.22,green:0.42,blue:0.18),in:base))
        context.stroke(Path(roundedRect:base,cornerRadius:9*s),with:.color(.yellow.opacity(0.7)),lineWidth:2*s)
        let stalk=CGRect(x:center.x-10*s,y:center.y-25*s,width:20*s,height:44*s)
        context.fill(Path(roundedRect:stalk,cornerRadius:8*s),with:material(Color(red:0.30,green:0.58,blue:0.18),in:stalk))
        let barrel=CGRect(x:center.x-6*s,y:center.y-55*s,width:18*s,height:58*s)
        context.fill(Path(roundedRect:barrel,cornerRadius:8*s),with:material(Color(red:0.89,green:0.68,blue:0.12),in:barrel))
        context.stroke(Path(roundedRect:barrel,cornerRadius:8*s),with:.color(.brown),lineWidth:2*s)
        context.fill(Path(ellipseIn:CGRect(x:center.x-3*s,y:center.y-56*s,width:12*s,height:9*s)),with:.color(.yellow))
        for i in 0..<4 {
            let a=Double(i)*Double.pi/2+time*0.5
            let px = center.x + CGFloat(cos(a))*25*s
            let py = center.y - 3*s + CGFloat(sin(a))*9*s
            let kernel = CGRect(x:px-6*s,y:py-3*s,width:12*s,height:6*s)
            context.fill(Path(ellipseIn:kernel),with:.color(.yellow.opacity(0.9)))
        }
        context.fill(Path(ellipseIn:CGRect(x:center.x-3*s,y:center.y-17*s,width:6*s,height:7*s)),with:.color(.black))
        context.draw(Text("CORN").font(.system(size:7*s,weight:.black,design:.rounded)).foregroundStyle(.white),at:CGPoint(x:center.x,y:center.y+15*s))
    }

    private static func drawCharmMushroom(context: inout GraphicsContext, center: CGPoint, scale s: CGFloat, progress: Double, time: Double) {
        let pulse=1+CGFloat(sin(time*7))*0.05+CGFloat(progress)*0.08
        let r=s*pulse
        let stem=CGRect(x:center.x-8*r,y:center.y-4*r,width:16*r,height:39*r)
        context.fill(Path(roundedRect:stem,cornerRadius:7*r),with:material(Color(red:0.78,green:0.70,blue:0.78),in:stem))
        let cap=CGRect(x:center.x-29*r,y:center.y-34*r,width:58*r,height:42*r)
        context.fill(Path(ellipseIn:cap),with:material(.purple,in:cap))
        context.stroke(Path(ellipseIn:cap),with:.color(.purple.opacity(0.75)),lineWidth:2*r)
        for i in 0..<5 {
            let a=Double(i)*Double.pi*2/5+time*0.22
            let p=CGPoint(x:center.x+CGFloat(cos(a))*18*r,y:center.y-14*r+CGFloat(sin(a))*10*r)
            context.fill(Path(ellipseIn:CGRect(x:p.x-4*r,y:p.y-4*r,width:8*r,height:8*r)),with:.color(.yellow.opacity(0.9)))
        }
        context.fill(Path(ellipseIn:CGRect(x:center.x-8*r,y:center.y-19*r,width:5*r,height:7*r)),with:.color(.black))
        context.fill(Path(ellipseIn:CGRect(x:center.x+5*r,y:center.y-19*r,width:5*r,height:7*r)),with:.color(.black))
        var smile=Path(); smile.move(to:CGPoint(x:center.x-8*r,y:center.y-6*r)); smile.addQuadCurve(to:CGPoint(x:center.x+8*r,y:center.y-6*r),control:CGPoint(x:center.x,y:center.y+3*r)); context.stroke(smile,with:.color(.black),lineWidth:2*r)
        if progress > 0 {
            for i in 0..<4 {
                let a=Double(i)*Double.pi/2+time*3
                let p=CGPoint(x:center.x+CGFloat(cos(a))*29*r,y:center.y-14*r+CGFloat(sin(a))*20*r)
                context.fill(Path(ellipseIn:CGRect(x:p.x-3*r,y:p.y-3*r,width:6*r,height:6*r)),with:.color(.pink.opacity(0.85)))
            }
            context.draw(Text("❤").font(.system(size:10*r)).foregroundStyle(.pink),at:CGPoint(x:center.x,y:center.y-47*r))
        }
    }

    private static func drawIcePeaShooter(context: inout GraphicsContext, center: CGPoint, scale s: CGFloat, time: Double) {
        let head = CGRect(x: center.x-22*s, y: center.y-29*s, width: 43*s, height: 39*s)
        context.fill(Path(ellipseIn: head), with: material(.cyan,in:head))
        let snout = CGRect(x: center.x+12*s, y: center.y-23*s, width: 31*s, height: 24*s)
        context.fill(Path(roundedRect: snout, cornerRadius: 11*s), with: material(.blue,in:snout))
        context.fill(Path(ellipseIn: CGRect(x: center.x+31*s, y: center.y-18*s, width: 8*s, height: 13*s)), with: .color(.white.opacity(0.85)))
        context.fill(Path(ellipseIn: CGRect(x: center.x-5*s, y: center.y-19*s, width: 6*s, height: 8*s)), with: .color(.black))
        for i in 0..<4 {
            let angle = time * 1.8 + Double(i) * Double.pi / 2
            let p = CGPoint(x: center.x + CGFloat(cos(angle))*24*s, y: center.y-8*s + CGFloat(sin(angle))*25*s)
            context.fill(Path(ellipseIn: CGRect(x:p.x-3*s,y:p.y-3*s,width:6*s,height:6*s)), with: .color(.white.opacity(0.8)))
        }
        context.draw(Text("ICE").font(.system(size: 7*s, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: center.x, y: center.y+15*s))
    }

    private static func drawFlameStake(context: inout GraphicsContext, center: CGPoint, scale s: CGFloat, time: Double) {
        let wood = CGRect(x:center.x-12*s, y:center.y-35*s, width:24*s, height:72*s)
        context.fill(Path(roundedRect:wood,cornerRadius:7*s),with:material(Color(red:0.56,green:0.29,blue:0.12),in:wood))
        context.stroke(Path(roundedRect:wood,cornerRadius:7*s),with:.color(.brown),lineWidth:2*s)
        for i in 0..<3 {
            let x=center.x+CGFloat(i-1)*6*s
            var flame=Path(); flame.move(to:CGPoint(x:x-8*s,y:center.y-26*s)); flame.addQuadCurve(to:CGPoint(x:x,y:center.y-57*s-CGFloat(sin(time*7+Double(i)))*5*s),control:CGPoint(x:x-2*s,y:center.y-43*s)); flame.addQuadCurve(to:CGPoint(x:x+8*s,y:center.y-26*s),control:CGPoint(x:x+4*s,y:center.y-41*s)); flame.closeSubpath()
            context.fill(flame,with:.linearGradient(Gradient(colors:[.yellow,.orange,.red.opacity(0.65)]),startPoint:CGPoint(x:x,y:center.y-58*s),endPoint:CGPoint(x:x,y:center.y-24*s)))
        }
        context.draw(Text("FIRE").font(.system(size:7*s,weight:.black,design:.rounded)).foregroundStyle(.white),at:CGPoint(x:center.x,y:center.y+14*s))
    }

    private static func drawGatlingPeaShooter(context: inout GraphicsContext, center: CGPoint, scale s: CGFloat, time: Double, burstShotsRemaining: Int) {
        let head = CGRect(x:center.x-24*s,y:center.y-30*s,width:46*s,height:42*s)
        context.fill(Path(ellipseIn:head),with:material(Color(red:0.20,green:0.68,blue:0.17),in:head))
        context.stroke(Path(ellipseIn:head),with:.color(.green.opacity(0.9)),lineWidth:2*s)
        let base = CGPoint(x:center.x+14*s,y:center.y-8*s)
        for i in 0..<4 {
            let angle = time * 8 + Double(i) * Double.pi / 2
            let end = CGPoint(x:base.x+CGFloat(cos(angle))*30*s,y:base.y+CGFloat(sin(angle))*30*s)
            var barrel=Path(); barrel.move(to:base); barrel.addLine(to:end)
            context.stroke(barrel,with:.color(Color(red:0.16,green:0.38,blue:0.12)),style:StrokeStyle(lineWidth:6*s,lineCap:.round))
            context.fill(Path(ellipseIn:CGRect(x:end.x-4*s,y:end.y-4*s,width:8*s,height:8*s)),with:.color(.yellow.opacity(0.8)))
        }
        context.fill(Path(ellipseIn:CGRect(x:center.x-6*s,y:center.y-19*s,width:6*s,height:8*s)),with:.color(.black))
        context.draw(Text("GATLING").font(.system(size:6*s,weight:.black,design:.rounded)).foregroundStyle(.white),at:CGPoint(x:center.x,y:center.y+15*s))
        if burstShotsRemaining > 0 {
            context.draw(Text("BURST \(burstShotsRemaining)").font(.system(size:7*s,weight:.black,design:.rounded)).foregroundStyle(.yellow),at:CGPoint(x:center.x,y:center.y-48*s))
        }
    }

    private static func drawCherryBomb(context: inout GraphicsContext, center: CGPoint, scale s: CGFloat, progress: Double, time: Double) {
        let pulse = 1 + sin(time * 18) * 0.08 + progress * 0.18
        let scale = s * CGFloat(pulse)
        for dx in [-13.0, 13.0] {
            let berry = CGRect(x: center.x+CGFloat(dx)*scale-16*scale, y: center.y-9*scale, width: 32*scale, height: 34*scale)
            context.fill(Path(ellipseIn: berry), with: material(progress > 0.65 ? .orange : .red,in:berry))
            context.stroke(Path(ellipseIn: berry), with: .color(.black.opacity(0.35)), lineWidth: 2*scale)
        }
        var stems = Path(); stems.move(to: CGPoint(x: center.x-10*scale, y: center.y-8*scale)); stems.addQuadCurve(to: CGPoint(x: center.x, y: center.y-34*scale), control: CGPoint(x: center.x-8*scale, y: center.y-30*scale)); stems.addQuadCurve(to: CGPoint(x: center.x+12*scale, y: center.y-8*scale), control: CGPoint(x: center.x+8*scale, y: center.y-30*scale))
        context.stroke(stems, with: .color(.green), style: StrokeStyle(lineWidth: 5*scale, lineCap: .round))
        let spark = CGPoint(x: center.x+CGFloat(sin(time*35))*7*scale, y: center.y-38*scale)
        context.fill(Path(ellipseIn: CGRect(x: spark.x-5*scale, y: spark.y-5*scale, width: 10*scale, height: 10*scale)), with: .color(.yellow))
        context.draw(Text("!").font(.system(size: 18*scale, weight: .black)).foregroundStyle(.white), at: center)
    }
}
