import SwiftUI

@MainActor
enum LawnRenderer {
    static func draw(context: inout GraphicsContext, size: CGSize, game: GameModel) {
        let cw = size.width / CGFloat(GameModel.columns)
        let rh = size.height / CGFloat(GameModel.rows)

        // Original code-drawn Japanese garden: layered moss, raked paths, water, lanterns and a gate.
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(colors: [Color(red: 0.58, green: 0.80, blue: 0.38), Color(red: 0.23, green: 0.53, blue: 0.28)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

        let water = CGRect(x: 0, y: size.height*0.455, width: size.width, height: size.height*0.09)
        context.fill(Path(water), with: .linearGradient(Gradient(colors: [Color.cyan.opacity(0.50), Color.blue.opacity(0.34), Color.white.opacity(0.28)]), startPoint: CGPoint(x: 0, y: water.minY), endPoint: CGPoint(x: size.width, y: water.maxY)))
        for i in 0..<10 {
            let y = water.minY + CGFloat(i % 3) * water.height/4 + water.height*0.18
            var ripple = Path(); ripple.move(to: CGPoint(x: CGFloat(i)*size.width/9 - 18, y: y)); ripple.addQuadCurve(to: CGPoint(x: CGFloat(i)*size.width/9 + 34, y: y), control: CGPoint(x: CGFloat(i)*size.width/9+8, y: y-5))
            context.stroke(ripple, with: .color(.white.opacity(0.35)), lineWidth: 1.5)
        }

        for row in 0..<GameModel.rows {
            for column in 0..<GameModel.columns {
                let rect = CGRect(x: CGFloat(column) * cw, y: CGFloat(row) * rh, width: cw, height: rh)
                if (row + column).isMultiple(of: 2) {
                    context.fill(Path(rect), with: .color(Color(red: 0.92, green: 0.88, blue: 0.69).opacity(0.11)))
                }
                context.stroke(Path(rect), with: .color(.white.opacity(0.16)), lineWidth: 1)
                drawGrassTuft(context: &context, at: CGPoint(x: rect.midX + cw * 0.25, y: rect.maxY - 5), scale: min(cw, rh) / 70)
                let stone = CGRect(x: rect.midX-cw*0.23, y: rect.midY-rh*0.16, width: cw*0.46, height: rh*0.32)
                context.fill(Path(ellipseIn: stone), with: .color(Color(red: 0.78, green: 0.76, blue: 0.67).opacity(0.25)))
                context.stroke(Path(ellipseIn: stone), with: .color(.white.opacity(0.16)), lineWidth: 1)
            }
        }

        drawToriiGate(context: &context, size: size, cellWidth: cw)
        drawBamboo(context: &context, x: size.width-cw*0.09, height: size.height, time: game.elapsed)
        for row in [0, 4] {
            drawLantern(context: &context, at: CGPoint(x: cw*1.2, y: (CGFloat(row)+0.55)*rh), scale: min(cw,rh)/90)
            drawLantern(context: &context, at: CGPoint(x: cw*7.8, y: (CGFloat(row)+0.55)*rh), scale: min(cw,rh)/90)
        }
        for i in 0..<18 {
            let drift = CGFloat((game.elapsed * (8 + Double(i%4))).truncatingRemainder(dividingBy: Double(size.width+40)))
            let x = (CGFloat(i*71).truncatingRemainder(dividingBy: size.width)) + drift - 20
            let y = CGFloat((i*43)%Int(max(1,size.height))) + sin(game.elapsed+Double(i))*5
            drawMapleLeaf(context: &context, at: CGPoint(x: x.truncatingRemainder(dividingBy: size.width), y: y), scale: 0.55+CGFloat(i%3)*0.14, angle: game.elapsed+Double(i))
        }

        for (cell, plant) in game.plants {
            let bob = sin(game.elapsed * 2.6 + Double(cell.column)) * 2.2
            let center = CGPoint(x: (CGFloat(cell.column) + 0.5) * cw, y: (CGFloat(cell.row) + 0.55) * rh + bob)
            drawPlant(context: &context, plant: plant, center: center, scale: min(cw, rh) / 82, time: game.elapsed)
        }

        for pea in game.peas {
            let center = CGPoint(x: (CGFloat(pea.x) + 0.5) * cw, y: (CGFloat(pea.row) + 0.48) * rh)
            let radius = max(4, min(cw, rh) * 0.075)
            var trail = Path()
            trail.move(to: CGPoint(x: center.x - radius * 4.2, y: center.y))
            trail.addLine(to: CGPoint(x: center.x - radius, y: center.y))
            context.stroke(trail, with: .linearGradient(Gradient(colors: [.clear, .green.opacity(0.55)]), startPoint: CGPoint(x: center.x-radius*4, y: center.y), endPoint: center), style: StrokeStyle(lineWidth: radius * 0.8, lineCap: .round))
            context.fill(Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2)), with: .color(Color(red: 0.20, green: 0.65, blue: 0.12)))
            context.fill(Path(ellipseIn: CGRect(x: center.x-radius*0.45, y: center.y-radius*0.55, width: radius*0.65, height: radius*0.55)), with: .color(.white.opacity(0.65)))
            context.stroke(Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2)), with: .color(.black.opacity(0.25)), lineWidth: 1.5)
        }

        if let burst = game.pepperBurst {
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

        if let target = game.cornTarget {
            let center = CGPoint(x:(CGFloat(target.column)+0.5)*cw, y:(CGFloat(target.row)+0.5)*rh)
            let r = min(cw,rh)*0.28
            context.stroke(Path(ellipseIn:CGRect(x:center.x-r,y:center.y-r,width:r*2,height:r*2)),with:.color(.yellow.opacity(0.92)),style:StrokeStyle(lineWidth:3,dash:[7,5]))
            var cross=Path(); cross.move(to:CGPoint(x:center.x-r*1.5,y:center.y)); cross.addLine(to:CGPoint(x:center.x+r*1.5,y:center.y)); cross.move(to:CGPoint(x:center.x,y:center.y-r*1.5)); cross.addLine(to:CGPoint(x:center.x,y:center.y+r*1.5)); context.stroke(cross,with:.color(.red.opacity(0.9)),lineWidth:2)
            context.draw(Text("TARGET").font(.system(size:10,weight:.black,design:.rounded)).foregroundStyle(.white),at:CGPoint(x:center.x,y:center.y-r*1.75))
        }
        for missile in game.cornMissiles {
            let start = CGPoint(x:(CGFloat(missile.origin.column)+0.5)*cw, y:(CGFloat(missile.origin.row)+0.4)*rh)
            let end = CGPoint(x:(CGFloat(missile.target.column)+0.5)*cw, y:(CGFloat(missile.target.row)+0.5)*rh)
            let p = min(1,max(0,missile.progress))
            let point = CGPoint(x:start.x+(end.x-start.x)*CGFloat(p), y:start.y+(end.y-start.y)*CGFloat(p)-sin(p*Double.pi)*rh*1.4)
            var trail=Path(); trail.move(to:CGPoint(x:point.x-cw*0.32,y:point.y+rh*0.08)); trail.addLine(to:point)
            context.stroke(trail,with:.linearGradient(Gradient(colors:[.yellow.opacity(0),.orange,.yellow]),startPoint:CGPoint(x:point.x-cw*0.3,y:point.y),endPoint:point),style:StrokeStyle(lineWidth:rh*0.10,lineCap:.round))
            let kernel=CGRect(x:point.x-cw*0.12,y:point.y-rh*0.12,width:cw*0.24,height:rh*0.24)
            context.fill(Path(ellipseIn:kernel),with:.color(.yellow))
            context.stroke(Path(ellipseIn:kernel),with:.color(.brown),lineWidth:2)
            var husk=Path(); husk.move(to:CGPoint(x:point.x-cw*0.08,y:point.y+rh*0.08)); husk.addLine(to:CGPoint(x:point.x-cw*0.17,y:point.y+rh*0.2)); husk.addLine(to:CGPoint(x:point.x-cw*0.02,y:point.y+rh*0.10)); husk.addLine(to:CGPoint(x:point.x+cw*0.12,y:point.y+rh*0.2)); context.stroke(husk,with:.color(.green),lineWidth:3)
        }
        if let blast = game.cornBlast {
            let t = blast.remaining / 0.82
            let center = CGPoint(x:(CGFloat(blast.cell.column)+0.5)*cw,y:(CGFloat(blast.cell.row)+0.5)*rh)
            let radius = min(cw,rh)*CGFloat(0.4+1.5*(1-t))
            context.fill(Path(ellipseIn:CGRect(x:center.x-radius,y:center.y-radius,width:radius*2,height:radius*2)),with:.radialGradient(Gradient(colors:[.yellow.opacity(t),.orange.opacity(t*0.75),.clear]),center:center,startRadius:0,endRadius:radius))
            context.stroke(Path(ellipseIn:CGRect(x:center.x-radius,y:center.y-radius,width:radius*2,height:radius*2)),with:.color(.red.opacity(t)),lineWidth:4)
        }

        for orb in game.iceOrbs {
            let center = CGPoint(x: (CGFloat(orb.x)+0.5)*cw, y: (CGFloat(orb.row)+0.48)*rh)
            let r = min(cw,rh)*0.13
            var trail = Path(); trail.move(to: CGPoint(x: center.x+r, y:center.y)); trail.addLine(to: CGPoint(x:center.x+r*4.2,y:center.y))
            context.stroke(trail, with: .linearGradient(Gradient(colors: [.cyan.opacity(0.8), .clear]), startPoint: center, endPoint: CGPoint(x:center.x+r*4,y:center.y)), style: StrokeStyle(lineWidth:r*1.15,lineCap:.round))
            context.fill(Path(ellipseIn:CGRect(x:center.x-r*1.7,y:center.y-r*1.7,width:r*3.4,height:r*3.4)), with:.radialGradient(Gradient(colors:[.white.opacity(0.85),.cyan.opacity(0.55),.blue.opacity(0.05)]),center:center,startRadius:0,endRadius:r*1.7))
            for i in 0..<6 {
                let a = Double(i) * Double.pi / 3 + orb.age * 5
                let p = CGPoint(x:center.x+cos(a)*r*1.3,y:center.y+sin(a)*r*1.3)
                context.fill(Path(ellipseIn:CGRect(x:p.x-2,y:p.y-2,width:4,height:4)),with:.color(.white))
            }
        }

        for sun in game.sunSparks {
            let t = sun.age / 1.35
            let center = CGPoint(x: (CGFloat(sun.cell.column) + 0.5) * cw + sin(t * Double.pi * 2) * 8,
                                 y: (CGFloat(sun.cell.row) + 0.42) * rh - CGFloat(t) * rh * 0.72)
            let radius = min(cw, rh) * CGFloat(0.13 + sin(t * Double.pi) * 0.05)
            context.fill(Path(ellipseIn: CGRect(x: center.x-radius*1.7, y: center.y-radius*1.7, width: radius*3.4, height: radius*3.4)), with: .radialGradient(Gradient(colors: [.yellow.opacity(0.7 * (1-t)), .clear]), center: center, startRadius: 0, endRadius: radius*1.7))
            context.fill(Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2)), with: .color(.yellow.opacity(1-t*0.8)))
            context.draw(Text("+25").font(.caption.bold()).foregroundStyle(.white.opacity(1-t)), at: CGPoint(x: center.x, y: center.y-radius*1.7))
        }

        for zombie in game.zombies {
            let gait = sin(zombie.age * (zombie.kind == .hammerGiant ? 3.1 : 6.2))
            let center = CGPoint(x: (CGFloat(zombie.x) + 0.5) * cw, y: (CGFloat(zombie.row) + 0.56) * rh + gait * 3)
            drawZombie(context: &context, zombie: zombie, center: center, scale: min(cw, rh) / 82, gait: gait)
        }

        if let bomb = game.pendingBomb {
            let center = CGPoint(x: (CGFloat(bomb.cell.column) + 0.5) * cw, y: (CGFloat(bomb.cell.row) + 0.53) * rh)
            drawCherryBomb(context: &context, center: center, scale: min(cw, rh) / 82,
                           progress: 1 - bomb.remaining / 0.75, time: game.elapsed)
        }

        if let explosion = game.explosion {
            let center = CGPoint(x: (CGFloat(explosion.cell.column) + 0.5) * cw, y: (CGFloat(explosion.cell.row) + 0.5) * rh)
            let t = explosion.remaining / 0.65
            let radius = min(cw, rh) * CGFloat(1.8 - t)
            let colors: [Color] = [.yellow.opacity(t), .orange.opacity(t * 0.8), .red.opacity(t * 0.25)]
            for (i, color) in colors.enumerated().reversed() {
                let r = radius * CGFloat(i + 1) / 3
                context.fill(Path(ellipseIn: CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2)), with: .color(color))
            }
        }

        for particle in game.particles {
            let t = particle.age / particle.life
            let center = CGPoint(x: (CGFloat(particle.cell.column) + 0.5 + particle.dx) * cw,
                                 y: (CGFloat(particle.cell.row) + 0.5 + particle.dy) * rh)
            let radius = min(cw, rh) * CGFloat(0.07 * (1-t) + 0.018)
            let color: Color = switch particle.colorIndex {
            case 0: .yellow; case 1: .orange; case 2: .red; case 4: .cyan; case 5: .orange; case 6: .black.opacity(0.55); case 8: .cyan; default: .brown
            }
            context.fill(Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2)), with: .color(color.opacity(1-t)))
        }

        if game.waveBannerRemaining > 0 {
            let t = game.waveBannerRemaining / 2.2
            let alpha = min(1, (1-t)*5) * min(1, t*3)
            let y = size.height * 0.5 + CGFloat(t-0.5) * 18
            let banner = CGRect(x: size.width*0.27, y: y-42, width: size.width*0.46, height: 84)
            context.fill(Path(roundedRect: banner, cornerRadius: 24), with: .color(.black.opacity(alpha*0.68)))
            let label = game.wave == 3 ? "FINAL WAVE • THREE BOSSES APPROACH" : "GARDEN WAVE \(game.wave)"
            context.draw(Text(label).font(.system(size: game.wave == 3 ? 24 : 34, weight: .black, design: .rounded)).foregroundStyle(.yellow.opacity(alpha)), at: CGPoint(x: banner.midX, y: banner.midY))
        }

        if game.isPaused {
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.45)))
            context.draw(Text("PAUSED").font(.system(size: 46, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: size.width/2, y: size.height/2))
        }
    }

    private static func drawGrassTuft(context: inout GraphicsContext, at point: CGPoint, scale: CGFloat) {
        var path = Path()
        path.move(to: point)
        path.addLine(to: CGPoint(x: point.x - 4*scale, y: point.y - 8*scale))
        path.move(to: point)
        path.addLine(to: CGPoint(x: point.x + 1*scale, y: point.y - 10*scale))
        path.move(to: point)
        path.addLine(to: CGPoint(x: point.x + 5*scale, y: point.y - 6*scale))
        context.stroke(path, with: .color(.green.opacity(0.42)), lineWidth: max(1, 1.4*scale))
    }

    private static func drawPlant(context: inout GraphicsContext, plant: Plant, center: CGPoint, scale baseScale: CGFloat, time: Double) {
        let entrance = min(1, max(0.08, plant.age / 0.28))
        let bounce = entrance < 1 ? 0.78 + CGFloat(sin(entrance * Double.pi)) * 0.35 : 1
        let s = baseScale * CGFloat(entrance) * bounce
        let recoil = plant.kind == .peaShooter ? CGFloat(plant.recoil / 0.22) * 7*s : 0
        let center = CGPoint(x: center.x - recoil, y: center.y)
        if plant.age < 0.55 {
            let glow = baseScale * CGFloat(50 + plant.age * 35)
            context.stroke(Path(ellipseIn: CGRect(x: center.x-glow, y: center.y-glow*0.45, width: glow*2, height: glow*0.9)), with: .color(.white.opacity(1-plant.age/0.55)), lineWidth: 3)
        }
        if plant.hitFlash > 0 {
            let flash = CGRect(x: center.x-35*s, y: center.y-42*s, width: 70*s, height: 82*s)
            context.fill(Path(ellipseIn: flash), with: .color(.red.opacity(plant.hitFlash * 0.8)))
        }
        let stem = CGRect(x: center.x - 4*s, y: center.y - 2*s, width: 8*s, height: 34*s)
        context.fill(Path(roundedRect: stem, cornerRadius: 4*s), with: .color(Color(red: 0.15, green: 0.55, blue: 0.12)))
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
            context.fill(Path(ellipseIn: face), with: .color(Color(red: 0.55, green: 0.27, blue: 0.08)))
            drawFace(context: &context, center: CGPoint(x: center.x, y: center.y-10*s), scale: s, happy: true)
        case .peaShooter:
            let head = CGRect(x: center.x-22*s, y: center.y-29*s, width: 43*s, height: 39*s)
            context.fill(Path(ellipseIn: head), with: .color(Color(red: 0.25, green: 0.72, blue: 0.16)))
            let snout = CGRect(x: center.x+12*s, y: center.y-23*s, width: 31*s, height: 24*s)
            context.fill(Path(roundedRect: snout, cornerRadius: 11*s), with: .color(Color(red: 0.19, green: 0.62, blue: 0.12)))
            context.fill(Path(ellipseIn: CGRect(x: center.x+31*s, y: center.y-18*s, width: 8*s, height: 13*s)), with: .color(.black.opacity(0.65)))
            context.fill(Path(ellipseIn: CGRect(x: center.x-5*s, y: center.y-19*s, width: 6*s, height: 8*s)), with: .color(.black))
        case .wallPlant:
            let body = CGRect(x: center.x-27*s, y: center.y-34*s, width: 54*s, height: 67*s)
            context.fill(Path(roundedRect: body, cornerRadius: 18*s), with: .color(Color(red: 0.64, green: 0.39, blue: 0.16)))
            context.stroke(Path(roundedRect: body, cornerRadius: 18*s), with: .color(.brown), lineWidth: 3*s)
            drawFace(context: &context, center: CGPoint(x: center.x, y: center.y-6*s), scale: s, happy: false)
        case .cherryBomb: break
        case .redHotPepper:
            drawPepper(context: &context, center: center, scale: s, progress: max(0, min(1, 1 - plant.actionTimer / 0.9)), time: time)
        case .cornCannon:
            drawCornCannon(context: &context, center: center, scale: s, time: time)
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

        let maxHP: Double = plant.kind == .wallPlant ? 520 : plant.kind == .peaShooter ? 125 : plant.kind == .redHotPepper ? 85 : plant.kind == .cornCannon ? 180 : 100
        let ratio = max(0, min(1, plant.hp / maxHP))
        let bar = CGRect(x: center.x-25*s, y: center.y+38*s, width: 50*s, height: 5*s)
        context.fill(Path(roundedRect: bar, cornerRadius: 2*s), with: .color(.black.opacity(0.25)))
        context.fill(Path(roundedRect: CGRect(x: bar.minX, y: bar.minY, width: bar.width*ratio, height: bar.height), cornerRadius: 2*s), with: .color(ratio > 0.4 ? .green : .red))
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
        context.fill(Path(roundedRect:body,cornerRadius:16*r),with:.linearGradient(Gradient(colors:[.red,.orange,.red.opacity(0.78)]),startPoint:body.origin,endPoint:CGPoint(x:body.maxX,y:body.maxY)))
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
        context.fill(Path(roundedRect:base,cornerRadius:9*s),with:.color(Color(red:0.22,green:0.42,blue:0.18)))
        context.stroke(Path(roundedRect:base,cornerRadius:9*s),with:.color(.yellow.opacity(0.7)),lineWidth:2*s)
        let stalk=CGRect(x:center.x-10*s,y:center.y-25*s,width:20*s,height:44*s)
        context.fill(Path(roundedRect:stalk,cornerRadius:8*s),with:.color(Color(red:0.30,green:0.58,blue:0.18)))
        let barrel=CGRect(x:center.x-6*s,y:center.y-55*s,width:18*s,height:58*s)
        context.fill(Path(roundedRect:barrel,cornerRadius:8*s),with:.color(Color(red:0.89,green:0.68,blue:0.12)))
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

    private static func drawZombie(context: inout GraphicsContext, zombie: Zombie, center: CGPoint, scale baseScale: CGFloat, gait: Double) {
        if zombie.kind == .hammerGiant {
            drawHammerGiant(context: &context, zombie: zombie, center: center, scale: baseScale, gait: gait)
            return
        }
        if zombie.kind == .iceDoctor {
            drawIceDoctor(context: &context, zombie: zombie, center: center, scale: baseScale, gait: gait)
            return
        }
        if zombie.kind == .thunderShogun {
            drawThunderShogun(context: &context, zombie: zombie, center: center, scale: baseScale, gait: gait)
            return
        }
        let spawn = min(1, max(0.12, zombie.age / 0.52))
        let s = baseScale * CGFloat(spawn)
        if zombie.age < 0.75 {
            let r = 38 * baseScale * CGFloat(1.3-zombie.age)
            context.stroke(Path(ellipseIn: CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2)), with: .color(.purple.opacity(0.8-zombie.age)), lineWidth: 4)
        }
        if zombie.hitFlash > 0 {
            context.fill(Path(ellipseIn: CGRect(x: center.x-30*s, y: center.y-50*s, width: 60*s, height: 100*s)), with: .color(.white.opacity(0.7)))
        }
        let skin = Color(red: 0.62, green: 0.70, blue: 0.48)
        let body = CGRect(x: center.x-18*s, y: center.y-2*s, width: 38*s, height: 43*s)
        context.fill(Path(roundedRect: body, cornerRadius: 7*s), with: .color(Color(red: 0.30, green: 0.18, blue: 0.23)))
        for plate in 0..<3 {
            let armor = CGRect(x:center.x-22*s,y:center.y+CGFloat(plate*11)*s,width:44*s,height:9*s)
            context.fill(Path(roundedRect:armor,cornerRadius:3*s),with:.color(plate.isMultiple(of:2) ? Color.red.opacity(0.72) : Color(red:0.55,green:0.12,blue:0.15)))
            context.stroke(Path(roundedRect:armor,cornerRadius:3*s),with:.color(.black.opacity(0.35)),lineWidth:1.2*s)
        }
        let head = CGRect(x: center.x-20*s, y: center.y-39*s, width: 39*s, height: 42*s)
        context.fill(Path(roundedRect: head, cornerRadius: 12*s), with: .color(skin))
        context.stroke(Path(roundedRect: head, cornerRadius: 12*s), with: .color(.black.opacity(0.35)), lineWidth: 2*s)
        context.fill(Path(ellipseIn: CGRect(x: center.x-10*s, y: center.y-27*s, width: 8*s, height: 9*s)), with: .color(.white))
        context.fill(Path(ellipseIn: CGRect(x: center.x+6*s, y: center.y-27*s, width: 8*s, height: 9*s)), with: .color(.white))
        context.fill(Path(ellipseIn: CGRect(x: center.x-7*s, y: center.y-25*s, width: 4*s, height: 5*s)), with: .color(.black))
        context.fill(Path(ellipseIn: CGRect(x: center.x+8*s, y: center.y-25*s, width: 4*s, height: 5*s)), with: .color(.black))
        var jaw = Path()
        jaw.move(to: CGPoint(x: center.x-8*s, y: center.y-11*s))
        jaw.addLine(to: CGPoint(x: center.x+10*s, y: center.y-8*s))
        context.stroke(jaw, with: .color(.black.opacity(0.7)), lineWidth: 2*s)
        for dx in [-11.0, 10.0] {
            context.fill(Path(roundedRect: CGRect(x: center.x+CGFloat(dx)*s, y: center.y+36*s, width: 8*s, height: 23*s), cornerRadius: 3*s), with: .color(Color(red: 0.23, green: 0.20, blue: 0.25)))
        }
        if zombie.kind == .bucketHead {
            let helmet = CGRect(x:center.x-25*s,y:center.y-59*s,width:50*s,height:25*s)
            context.fill(Path(roundedRect:helmet,cornerRadius:10*s),with:.linearGradient(Gradient(colors:[Color(red:0.16,green:0.18,blue:0.22),Color(red:0.38,green:0.17,blue:0.20)]),startPoint:helmet.origin,endPoint:CGPoint(x:helmet.maxX,y:helmet.maxY)))
            context.stroke(Path(roundedRect:helmet,cornerRadius:10*s),with:.color(.orange.opacity(0.7)),lineWidth:2*s)
            var crest = Path(); crest.move(to:CGPoint(x:center.x-15*s,y:center.y-58*s)); crest.addQuadCurve(to:CGPoint(x:center.x+15*s,y:center.y-58*s),control:CGPoint(x:center.x,y:center.y-78*s)); crest.addQuadCurve(to:CGPoint(x:center.x-15*s,y:center.y-58*s),control:CGPoint(x:center.x,y:center.y-66*s))
            context.fill(crest,with:.color(.yellow.opacity(0.8)))
            context.fill(Path(CGRect(x:center.x-31*s,y:center.y-38*s,width:62*s,height:6*s)),with:.color(Color(red:0.18,green:0.16,blue:0.2)))
        } else {
            context.fill(Path(roundedRect:CGRect(x:center.x-23*s,y:center.y-42*s,width:46*s,height:7*s),cornerRadius:2*s),with:.color(.red))
            context.fill(Path(ellipseIn:CGRect(x:center.x-5*s,y:center.y-55*s,width:10*s,height:12*s)),with:.color(.black.opacity(0.8)))
        }
        let ratio = max(0, zombie.hp / zombie.kind.maxHP)
        let bar = CGRect(x: center.x-22*s, y: center.y-51*s-(zombie.kind == .bucketHead ? 15*s : 0), width: 44*s, height: 5*s)
        context.fill(Path(roundedRect: bar, cornerRadius: 2*s), with: .color(.black.opacity(0.28)))
        context.fill(Path(roundedRect: CGRect(x: bar.minX, y: bar.minY, width: bar.width*ratio, height: bar.height), cornerRadius: 2*s), with: .color(.red))
    }

    private static func drawHammerGiant(context: inout GraphicsContext, zombie: Zombie, center: CGPoint, scale baseScale: CGFloat, gait: Double) {
        let spawn = min(1, max(0.08, zombie.age / 0.8))
        let s = baseScale * 1.34 * CGFloat(spawn)
        let skin = Color(red: 0.43, green: 0.58, blue: 0.35)
        if zombie.age < 1.0 {
            let r = 50 * baseScale * CGFloat(1.6-zombie.age)
            context.fill(Path(ellipseIn: CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2)), with: .radialGradient(Gradient(colors: [.purple.opacity(0.55), .clear]), center: center, startRadius: 0, endRadius: r))
        }
        let body = CGRect(x: center.x-27*s, y: center.y-15*s, width: 54*s, height: 62*s)
        context.fill(Path(roundedRect: body, cornerRadius: 13*s), with: .color(Color(red: 0.20, green: 0.12, blue: 0.20)))
        for plate in 0..<4 {
            let armor = CGRect(x:center.x-35*s,y:center.y-7*s+CGFloat(plate)*12*s,width:70*s,height:10*s)
            context.fill(Path(roundedRect:armor,cornerRadius:4*s),with:.color(plate.isMultiple(of:2) ? Color(red:0.58,green:0.08,blue:0.12) : Color(red:0.30,green:0.08,blue:0.13)))
            context.stroke(Path(roundedRect:armor,cornerRadius:4*s),with:.color(.yellow.opacity(0.45)),lineWidth:1.5*s)
        }
        for dx in [-35.0, 21.0] {
            context.fill(Path(roundedRect:CGRect(x:center.x+CGFloat(dx)*s,y:center.y-14*s,width:28*s,height:22*s),cornerRadius:8*s),with:.color(Color(red:0.48,green:0.07,blue:0.10)))
        }
        let head = CGRect(x: center.x-26*s, y: center.y-58*s, width: 52*s, height: 49*s)
        context.fill(Path(roundedRect: head, cornerRadius: 15*s), with: .color(skin))
        context.stroke(Path(roundedRect: head, cornerRadius: 15*s), with: .color(.black.opacity(0.42)), lineWidth: 3*s)
        context.fill(Path(roundedRect: CGRect(x: center.x-35*s, y: center.y-68*s, width: 70*s, height: 17*s), cornerRadius: 7*s), with: .color(Color(red: 0.14, green: 0.12, blue: 0.17)))
        var horns = Path(); horns.move(to:CGPoint(x:center.x-29*s,y:center.y-64*s)); horns.addQuadCurve(to:CGPoint(x:center.x-47*s,y:center.y-88*s),control:CGPoint(x:center.x-48*s,y:center.y-67*s)); horns.addQuadCurve(to:CGPoint(x:center.x-18*s,y:center.y-65*s),control:CGPoint(x:center.x-35*s,y:center.y-76*s)); horns.move(to:CGPoint(x:center.x+29*s,y:center.y-64*s)); horns.addQuadCurve(to:CGPoint(x:center.x+47*s,y:center.y-88*s),control:CGPoint(x:center.x+48*s,y:center.y-67*s)); horns.addQuadCurve(to:CGPoint(x:center.x+18*s,y:center.y-65*s),control:CGPoint(x:center.x+35*s,y:center.y-76*s))
        context.fill(horns,with:.color(.yellow.opacity(0.9)))
        for dx in [-12.0, 9.0] {
            context.fill(Path(ellipseIn: CGRect(x: center.x+CGFloat(dx)*s, y: center.y-43*s, width: 9*s, height: 10*s)), with: .color(.white))
            context.fill(Path(ellipseIn: CGRect(x: center.x+(CGFloat(dx)+3)*s, y: center.y-40*s, width: 4*s, height: 5*s)), with: .color(.black))
        }
        var mouth = Path(); mouth.move(to: CGPoint(x: center.x-12*s, y: center.y-23*s)); mouth.addLine(to: CGPoint(x: center.x+13*s, y: center.y-20*s))
        context.stroke(mouth, with: .color(.black.opacity(0.75)), lineWidth: 3*s)

        for dx in [-17.0, 10.0] {
            let legLift = CGFloat(dx < 0 ? gait : -gait) * 3*s
            context.fill(Path(roundedRect: CGRect(x: center.x+CGFloat(dx)*s, y: center.y+40*s+legLift, width: 13*s, height: 27*s), cornerRadius: 4*s), with: .color(Color(red: 0.18, green: 0.16, blue: 0.20)))
        }

        // The raised hammer is the warning: it slowly lifts, glows, then snaps down on impact.
        let chargeProgress = zombie.strikeCharge > 0 ? 1 - zombie.strikeCharge / 1.35 : 0
        let angle = zombie.strikeCharge > 0 ? (-1.15 + chargeProgress * 0.72) : (-0.34 + gait * 0.05)
        let shoulder = CGPoint(x: center.x+20*s, y: center.y-4*s)
        let hammerEnd = CGPoint(x: shoulder.x + cos(angle)*62*s, y: shoulder.y + sin(angle)*62*s)
        var handle = Path(); handle.move(to: shoulder); handle.addLine(to: hammerEnd)
        context.stroke(handle, with: .color(Color(red: 0.42, green: 0.25, blue: 0.10)), style: StrokeStyle(lineWidth: 8*s, lineCap: .round))
        let headRect = CGRect(x: hammerEnd.x-20*s, y: hammerEnd.y-14*s, width: 42*s, height: 28*s)
        if zombie.strikeCharge > 0 {
            context.fill(Path(ellipseIn: headRect.insetBy(dx: -10*s, dy: -10*s)), with: .color(.orange.opacity(0.22 + chargeProgress*0.38)))
        }
        context.fill(Path(roundedRect: headRect, cornerRadius: 5*s), with: .color(Color(red: 0.29, green: 0.32, blue: 0.34)))
        context.stroke(Path(roundedRect: headRect, cornerRadius: 5*s), with: .color(.black.opacity(0.55)), lineWidth: 3*s)

        let ratio = max(0, zombie.hp / zombie.kind.maxHP)
        let bar = CGRect(x: center.x-42*s, y: center.y-78*s, width: 84*s, height: 8*s)
        context.fill(Path(roundedRect: bar, cornerRadius: 4*s), with: .color(.black.opacity(0.5)))
        context.fill(Path(roundedRect: CGRect(x: bar.minX, y: bar.minY, width: bar.width*ratio, height: bar.height), cornerRadius: 4*s), with: .linearGradient(Gradient(colors: [.red, .orange]), startPoint: CGPoint(x: bar.minX, y: bar.midY), endPoint: CGPoint(x: bar.maxX, y: bar.midY)))
        context.draw(Text("HAMMER SHOGUN • 3 BOMBS").font(.system(size: 7*s, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: bar.midX, y: bar.minY-7*s))
    }

    private static func drawIceDoctor(context: inout GraphicsContext, zombie: Zombie, center: CGPoint, scale baseScale: CGFloat, gait: Double) {
        let spawn = min(1,max(0.08,zombie.age/0.82))
        let s = baseScale*1.20*CGFloat(spawn)
        if zombie.age < 1.1 {
            let r = 55*baseScale*CGFloat(1.5-zombie.age)
            context.fill(Path(ellipseIn:CGRect(x:center.x-r,y:center.y-r,width:r*2,height:r*2)),with:.radialGradient(Gradient(colors:[.cyan.opacity(0.65),.blue.opacity(0.15),.clear]),center:center,startRadius:0,endRadius:r))
        }
        let backpack = CGRect(x:center.x+20*s,y:center.y-21*s,width:27*s,height:57*s)
        context.fill(Path(roundedRect:backpack,cornerRadius:8*s),with:.color(Color(red:0.12,green:0.31,blue:0.42)))
        context.stroke(Path(roundedRect:backpack,cornerRadius:8*s),with:.color(.cyan.opacity(0.8)),lineWidth:2*s)
        let body = CGRect(x:center.x-29*s,y:center.y-17*s,width:60*s,height:64*s)
        context.fill(Path(roundedRect:body,cornerRadius:14*s),with:.linearGradient(Gradient(colors:[Color(red:0.12,green:0.23,blue:0.38),Color(red:0.27,green:0.58,blue:0.66)]),startPoint:body.origin,endPoint:CGPoint(x:body.maxX,y:body.maxY)))
        for y in [0.0, 15.0, 30.0] {
            let plate = CGRect(x:center.x-34*s,y:center.y+CGFloat(y)*s,width:68*s,height:11*s)
            context.stroke(Path(roundedRect:plate,cornerRadius:4*s),with:.color(.cyan.opacity(0.6)),lineWidth:2*s)
        }
        for dx in [-39.0,23.0] {
            context.fill(Path(roundedRect:CGRect(x:center.x+CGFloat(dx)*s,y:center.y-18*s,width:30*s,height:25*s),cornerRadius:9*s),with:.color(Color(red:0.22,green:0.46,blue:0.58)))
        }
        let helmet = CGRect(x:center.x-30*s,y:center.y-66*s,width:61*s,height:54*s)
        context.fill(Path(roundedRect:helmet,cornerRadius:17*s),with:.color(Color(red:0.16,green:0.32,blue:0.46)))
        context.stroke(Path(roundedRect:helmet,cornerRadius:17*s),with:.color(.white.opacity(0.65)),lineWidth:3*s)
        let visor = CGRect(x:center.x-23*s,y:center.y-51*s,width:47*s,height:18*s)
        context.fill(Path(roundedRect:visor,cornerRadius:8*s),with:.linearGradient(Gradient(colors:[.cyan.opacity(0.35),.white.opacity(0.8)]),startPoint:visor.origin,endPoint:CGPoint(x:visor.maxX,y:visor.maxY)))
        for dx in [-10.0,10.0] { context.fill(Path(ellipseIn:CGRect(x:center.x+CGFloat(dx)*s-2*s,y:center.y-44*s,width:5*s,height:6*s)),with:.color(.blue)) }
        // Original snow-medic crest.
        var snow = Path()
        for i in 0..<3 { let a = Double(i) * Double.pi / 3; snow.move(to:CGPoint(x:center.x-cos(a)*11*s,y:center.y-62*s-sin(a)*11*s)); snow.addLine(to:CGPoint(x:center.x+cos(a)*11*s,y:center.y-62*s+sin(a)*11*s)) }
        context.stroke(snow,with:.color(.white),style:StrokeStyle(lineWidth:2*s,lineCap:.round))
        for dx in [-19.0, 9.0] {
            let lift = CGFloat(dx<0 ? gait : -gait)*2*s
            context.fill(Path(roundedRect:CGRect(x:center.x+CGFloat(dx)*s,y:center.y+42*s+lift,width:14*s,height:25*s),cornerRadius:4*s),with:.color(Color(red:0.08,green:0.17,blue:0.28)))
        }
        let charge = zombie.strikeCharge > 0 ? 1-zombie.strikeCharge/1.4 : 0
        let orbCenter = CGPoint(x:center.x-43*s,y:center.y-5*s)
        let orbRadius = (8+charge*17)*s
        if zombie.strikeCharge > 0 {
            context.fill(Path(ellipseIn:CGRect(x:orbCenter.x-orbRadius*1.8,y:orbCenter.y-orbRadius*1.8,width:orbRadius*3.6,height:orbRadius*3.6)),with:.radialGradient(Gradient(colors:[.white.opacity(0.9),.cyan.opacity(0.45),.clear]),center:orbCenter,startRadius:0,endRadius:orbRadius*1.8))
            context.draw(Text("ICE ORB").font(.system(size:7*s,weight:.black)).foregroundStyle(.white),at:CGPoint(x:orbCenter.x,y:orbCenter.y-27*s))
        }
        let ratio=max(0,zombie.hp/zombie.kind.maxHP)
        let bar=CGRect(x:center.x-48*s,y:center.y-82*s,width:96*s,height:8*s)
        context.fill(Path(roundedRect:bar,cornerRadius:4*s),with:.color(.black.opacity(0.55)))
        context.fill(Path(roundedRect:CGRect(x:bar.minX,y:bar.minY,width:bar.width*ratio,height:bar.height),cornerRadius:4*s),with:.linearGradient(Gradient(colors:[.cyan,.blue]),startPoint:CGPoint(x:bar.minX,y:bar.midY),endPoint:CGPoint(x:bar.maxX,y:bar.midY)))
        context.draw(Text("ARMORED ICE DOCTOR • 5 BOMBS").font(.system(size:6.5*s,weight:.black,design:.rounded)).foregroundStyle(.white),at:CGPoint(x:bar.midX,y:bar.minY-7*s))
    }

    private static func drawThunderShogun(context: inout GraphicsContext, zombie: Zombie, center: CGPoint, scale baseScale: CGFloat, gait: Double) {
        let spawn = min(1,max(0.06,zombie.age/1.0))
        let s = baseScale * 1.58 * CGFloat(spawn)
        let armor = Color(red:0.08,green:0.12,blue:0.25)
        if zombie.age < 1.25 {
            let r=62*baseScale*CGFloat(1.55-zombie.age)
            context.fill(Path(ellipseIn:CGRect(x:center.x-r,y:center.y-r,width:r*2,height:r*2)),with:.radialGradient(Gradient(colors:[.cyan.opacity(0.55),.purple.opacity(0.22),.clear]),center:center,startRadius:0,endRadius:r))
        }
        let cloak=CGRect(x:center.x-43*s,y:center.y-22*s,width:86*s,height:90*s)
        context.fill(Path(roundedRect:cloak,cornerRadius:18*s),with:.linearGradient(Gradient(colors:[armor,.purple.opacity(0.8)]),startPoint:cloak.origin,endPoint:CGPoint(x:cloak.maxX,y:cloak.maxY)))
        for y in [0.0,18.0,36.0,54.0] {
            let plate=CGRect(x:center.x-49*s,y:center.y-12*s+CGFloat(y)*s,width:98*s,height:13*s)
            context.fill(Path(roundedRect:plate,cornerRadius:5*s),with:.color(y.truncatingRemainder(dividingBy:36)==0 ? .cyan.opacity(0.36) : .purple.opacity(0.48)))
            context.stroke(Path(roundedRect:plate,cornerRadius:5*s),with:.color(.yellow.opacity(0.65)),lineWidth:2*s)
        }
        let head=CGRect(x:center.x-39*s,y:center.y-82*s,width:78*s,height:64*s)
        context.fill(Path(roundedRect:head,cornerRadius:20*s),with:.color(Color(red:0.10,green:0.16,blue:0.27)))
        context.stroke(Path(roundedRect:head,cornerRadius:20*s),with:.color(.cyan.opacity(0.8)),lineWidth:3*s)
        let crest=CGRect(x:center.x-50*s,y:center.y-93*s,width:100*s,height:16*s)
        context.fill(Path(roundedRect:crest,cornerRadius:8*s),with:.color(.yellow.opacity(0.85)))
        for dx in [-23.0,19.0] { context.fill(Path(ellipseIn:CGRect(x:center.x+CGFloat(dx)*s,y:center.y-62*s,width:12*s,height:14*s)),with:.color(.cyan)); context.fill(Path(ellipseIn:CGRect(x:center.x+(CGFloat(dx)+4)*s,y:center.y-59*s,width:5*s,height:6*s)),with:.color(.white)) }
        var mask=Path(); mask.move(to:CGPoint(x:center.x-20*s,y:center.y-35*s)); mask.addLine(to:CGPoint(x:center.x+24*s,y:center.y-31*s)); context.stroke(mask,with:.color(.white.opacity(0.75)),lineWidth:3*s)
        for dx in [-27.0,15.0] { let lift=CGFloat(dx<0 ? gait : -gait)*3*s; context.fill(Path(roundedRect:CGRect(x:center.x+CGFloat(dx)*s,y:center.y+57*s+lift,width:18*s,height:31*s),cornerRadius:5*s),with:.color(Color(red:0.05,green:0.08,blue:0.17))) }
        let shoulder=CGPoint(x:center.x+35*s,y:center.y-1*s)
        let hammerEnd=CGPoint(x:shoulder.x+42*s,y:shoulder.y+40*s)
        var handle=Path(); handle.move(to:shoulder); handle.addLine(to:hammerEnd); context.stroke(handle,with:.color(.brown),style:StrokeStyle(lineWidth:10*s,lineCap:.round))
        context.fill(Path(roundedRect:CGRect(x:hammerEnd.x-28*s,y:hammerEnd.y-18*s,width:58*s,height:37*s),cornerRadius:8*s),with:.color(.gray.opacity(0.9)))
        context.stroke(Path(roundedRect:CGRect(x:hammerEnd.x-28*s,y:hammerEnd.y-18*s,width:58*s,height:37*s),cornerRadius:8*s),with:.color(.cyan),lineWidth:3*s)

        if let target=zombie.lightningTarget, zombie.strikeCharge>0 {
            let cellW=baseScale*82*1.8, cellH=baseScale*82
            let tx=(CGFloat(target.column)+0.5)*cellW, ty=(CGFloat(target.row)+0.5)*cellH
            var bolt=Path(); bolt.move(to:CGPoint(x:tx,y:0)); bolt.addLine(to:CGPoint(x:tx-10*s,y:ty*0.25)); bolt.addLine(to:CGPoint(x:tx+8*s,y:ty*0.52)); bolt.addLine(to:CGPoint(x:tx-7*s,y:ty*0.78)); bolt.addLine(to:CGPoint(x:tx,y:ty))
            context.stroke(bolt,with:.color(.cyan.opacity(0.8)),style:StrokeStyle(lineWidth:4*s,lineCap:.round,lineJoin:.round))
            let marker=CGRect(x:tx-22*s,y:ty-22*s,width:44*s,height:44*s)
            context.stroke(Path(ellipseIn:marker),with:.color(.cyan),style:StrokeStyle(lineWidth:3*s,dash:[8,5]))
            context.draw(Text("LIGHTNING TARGET").font(.system(size:8*s,weight:.black,design:.rounded)).foregroundStyle(.white),at:CGPoint(x:tx,y:ty-30*s))
        }
        let bar=CGRect(x:center.x-62*s,y:center.y-111*s,width:124*s,height:10*s)
        context.fill(Path(roundedRect:bar,cornerRadius:5*s),with:.color(.black.opacity(0.62)))
        context.fill(Path(roundedRect:CGRect(x:bar.minX,y:bar.minY,width:bar.width*max(0,zombie.hp/zombie.kind.maxHP),height:bar.height),cornerRadius:5*s),with:.linearGradient(Gradient(colors:[.cyan,.purple,.red]),startPoint:CGPoint(x:bar.minX,y:bar.midY),endPoint:CGPoint(x:bar.maxX,y:bar.midY)))
        context.draw(Text("THUNDER SHOGUN • FINAL BOSS").font(.system(size:8*s,weight:.black,design:.rounded)).foregroundStyle(.white),at:CGPoint(x:bar.midX,y:bar.minY-9*s))
        if zombie.strikeCharge>0 { context.draw(Text("LIGHTNING CHARGING • 2.4s WARNING").font(.system(size:8*s,weight:.black,design:.rounded)).foregroundStyle(.cyan),at:CGPoint(x:center.x,y:center.y+94*s)) }
    }

    private static func drawToriiGate(context: inout GraphicsContext, size: CGSize, cellWidth: CGFloat) {
        let red = Color(red:0.68,green:0.09,blue:0.10)
        context.fill(Path(CGRect(x:0,y:0,width:cellWidth*0.10,height:size.height)),with:.color(red.opacity(0.55)))
        context.fill(Path(roundedRect:CGRect(x:cellWidth*0.03,y:size.height*0.04,width:cellWidth*0.18,height:size.height*0.92),cornerRadius:3),with:.color(red.opacity(0.82)))
        context.fill(Path(roundedRect:CGRect(x:0,y:size.height*0.07,width:cellWidth*0.43,height:10),cornerRadius:4),with:.color(red))
        context.fill(Path(roundedRect:CGRect(x:0,y:size.height*0.12,width:cellWidth*0.34,height:6),cornerRadius:3),with:.color(Color(red:0.23,green:0.08,blue:0.08)))
    }

    private static func drawBamboo(context: inout GraphicsContext, x: CGFloat, height: CGFloat, time: Double) {
        for i in 0..<3 {
            let bx=x+CGFloat(i)*9
            var stem=Path(); stem.move(to:CGPoint(x:bx,y:height)); stem.addQuadCurve(to:CGPoint(x:bx+sin(time*0.6+Double(i))*4,y:0),control:CGPoint(x:bx-5,y:height*0.5))
            context.stroke(stem,with:.color(Color(red:0.12,green:0.38,blue:0.16).opacity(0.8)),lineWidth:6)
            for j in 1..<6 {
                let y=height*CGFloat(j)/6
                context.fill(Path(ellipseIn:CGRect(x:bx-16,y:y-5,width:18,height:8)),with:.color(Color(red:0.20,green:0.52,blue:0.18).opacity(0.7)))
            }
        }
    }

    private static func drawLantern(context: inout GraphicsContext, at p: CGPoint, scale s: CGFloat) {
        context.fill(Path(roundedRect:CGRect(x:p.x-5*s,y:p.y-6*s,width:10*s,height:35*s),cornerRadius:3*s),with:.color(Color(red:0.40,green:0.39,blue:0.35).opacity(0.7)))
        let roof=CGRect(x:p.x-18*s,y:p.y-18*s,width:36*s,height:10*s)
        context.fill(Path(roundedRect:roof,cornerRadius:4*s),with:.color(Color(red:0.26,green:0.25,blue:0.23)))
        let lamp=CGRect(x:p.x-12*s,y:p.y-9*s,width:24*s,height:19*s)
        context.fill(Path(roundedRect:lamp,cornerRadius:4*s),with:.radialGradient(Gradient(colors:[.yellow.opacity(0.75),.orange.opacity(0.18)]),center:CGPoint(x:lamp.midX,y:lamp.midY),startRadius:0,endRadius:lamp.width))
    }

    private static func drawMapleLeaf(context: inout GraphicsContext, at p: CGPoint, scale s: CGFloat, angle: Double) {
        var leaf=Path(); let points=8
        for i in 0..<points { let a = Double(i) * Double.pi * 2 / Double(points) + angle; let r = (i%2==0 ? 7.0:3.0) * Double(s); let q=CGPoint(x:p.x+cos(a)*r,y:p.y+sin(a)*r); if i==0 { leaf.move(to:q) } else { leaf.addLine(to:q) } }
        leaf.closeSubpath(); context.fill(leaf,with:.color((Int(angle)%2==0 ? Color.red : Color.orange).opacity(0.38)))
    }

    private static func drawCherryBomb(context: inout GraphicsContext, center: CGPoint, scale s: CGFloat, progress: Double, time: Double) {
        let pulse = 1 + sin(time * 18) * 0.08 + progress * 0.18
        let scale = s * CGFloat(pulse)
        for dx in [-13.0, 13.0] {
            let berry = CGRect(x: center.x+CGFloat(dx)*scale-16*scale, y: center.y-9*scale, width: 32*scale, height: 34*scale)
            context.fill(Path(ellipseIn: berry), with: .color(progress > 0.65 ? .orange : .red))
            context.stroke(Path(ellipseIn: berry), with: .color(.black.opacity(0.35)), lineWidth: 2*scale)
        }
        var stems = Path(); stems.move(to: CGPoint(x: center.x-10*scale, y: center.y-8*scale)); stems.addQuadCurve(to: CGPoint(x: center.x, y: center.y-34*scale), control: CGPoint(x: center.x-8*scale, y: center.y-30*scale)); stems.addQuadCurve(to: CGPoint(x: center.x+12*scale, y: center.y-8*scale), control: CGPoint(x: center.x+8*scale, y: center.y-30*scale))
        context.stroke(stems, with: .color(.green), style: StrokeStyle(lineWidth: 5*scale, lineCap: .round))
        let spark = CGPoint(x: center.x+CGFloat(sin(time*35))*7*scale, y: center.y-38*scale)
        context.fill(Path(ellipseIn: CGRect(x: spark.x-5*scale, y: spark.y-5*scale, width: 10*scale, height: 10*scale)), with: .color(.yellow))
        context.draw(Text("!").font(.system(size: 18*scale, weight: .black)).foregroundStyle(.white), at: center)
    }
}
