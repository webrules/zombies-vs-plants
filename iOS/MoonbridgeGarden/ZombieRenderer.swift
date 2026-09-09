import SwiftUI

struct ZombiePose {
    let stride: CGFloat
    let lift: CGFloat
    let bob: CGFloat
    let reach: CGFloat
    let charge: CGFloat
    let facing: CGFloat

    init(zombie: Zombie, engaged: Bool) {
        let charging = zombie.strikeCharge > 0 && !zombie.charmed
        let phase = zombie.kind == .dancerSamurai ? zombie.dancePhase : zombie.age * (zombie.kind.isBoss ? 3.4 : 5.2)
        let walking = !engaged && !charging
        stride = walking ? CGFloat(sin(phase)) * 9 : 0
        lift = walking ? CGFloat(cos(phase)) * 4 : 0
        bob = walking ? -abs(CGFloat(cos(phase))) * 1.4 : 0
        reach = engaged && !charging ? CGFloat(0.5 + 0.5 * sin(zombie.age * 8)) : 0
        let duration: Double = switch zombie.kind {
        case .hammerGiant: 1.35
        case .iceDoctor: 1.4
        case .flameGiant: 1.1
        case .thunderShogun: 2.4
        default: 1
        }
        charge = charging ? CGFloat(max(0, min(1, 1 - zombie.strikeCharge / duration))) : 0
        facing = zombie.charmed ? -1 : 1
    }
}

@MainActor
enum ZombieRenderer {
    private struct Palette {
        let lacquer: Color
        let cloth: Color
        let metal: Color
        let skin: Color
        let light: Color
        let stature: CGFloat
        let breadth: CGFloat

        init(_ kind: ZombieKind) {
            metal = Color(red: 0.48, green: 0.43, blue: 0.31)
            switch kind {
            case .regular:
                lacquer = Color(red: 0.36, green: 0.12, blue: 0.10)
                cloth = Color(red: 0.25, green: 0.24, blue: 0.18)
                skin = Color(red: 0.48, green: 0.53, blue: 0.38)
                light = .init(red: 0.84, green: 0.75, blue: 0.39)
                stature = 1; breadth = 0.92
            case .bucketHead, .hammerGiant:
                lacquer = Color(red: 0.30, green: 0.09, blue: 0.10)
                cloth = Color(red: 0.14, green: 0.16, blue: 0.19)
                skin = Color(red: 0.44, green: 0.49, blue: 0.35)
                light = .init(red: 0.91, green: 0.57, blue: 0.25)
                stature = kind == .hammerGiant ? 1.32 : 1.04
                breadth = kind == .hammerGiant ? 1.22 : 1.08
            case .dancerSamurai:
                lacquer = Color(red: 0.36, green: 0.18, blue: 0.27)
                cloth = Color(red: 0.26, green: 0.12, blue: 0.19)
                skin = Color(red: 0.55, green: 0.56, blue: 0.41)
                light = .init(red: 0.92, green: 0.63, blue: 0.30)
                stature = 1; breadth = 0.88
            case .iceDoctor:
                lacquer = Color(red: 0.16, green: 0.32, blue: 0.40)
                cloth = Color(red: 0.31, green: 0.39, blue: 0.41)
                skin = Color(red: 0.49, green: 0.60, blue: 0.60)
                light = .cyan
                stature = 1.22; breadth = 1.07
            case .flameGiant:
                lacquer = Color(red: 0.24, green: 0.18, blue: 0.14)
                cloth = Color(red: 0.23, green: 0.13, blue: 0.10)
                skin = Color(red: 0.43, green: 0.35, blue: 0.24)
                light = .orange
                stature = 1.30; breadth = 1.18
            case .thunderShogun:
                lacquer = Color(red: 0.14, green: 0.20, blue: 0.31)
                cloth = Color(red: 0.22, green: 0.16, blue: 0.30)
                skin = Color(red: 0.44, green: 0.52, blue: 0.55)
                light = .cyan
                stature = 1.48; breadth = 1.20
            }
        }
    }

    // All anatomy is drawn in a foot-anchored local frame. Only the figure is mirrored;
    // health, status text, and ground effects stay in the lane's upright coordinate frame.
    static func draw(context: inout GraphicsContext, zombie: Zombie, ground: CGPoint,
                     scale: CGFloat, engaged: Bool) {
        let palette = Palette(zombie.kind)
        let spawn = CGFloat(min(1, max(0.08, zombie.age / 0.65)))
        let s = scale * palette.stature * spawn
        let pose = ZombiePose(zombie: zombie, engaged: engaged)
        var local = context
        local.translateBy(x: ground.x, y: ground.y)
        local.scaleBy(x: s, y: s)
        let shadow = CGRect(x: -25 * palette.breadth, y: -4, width: 50 * palette.breadth, height: 10)
        local.fill(Path(ellipseIn: shadow), with: .radialGradient(
            Gradient(colors: [.black.opacity(0.5), .clear]), center: .zero, startRadius: 0, endRadius: 28))
        local.fill(polygon([(-12, -2), (18, -2), (45, 14), (32, 17)]),
                   with: .linearGradient(Gradient(colors: [.black.opacity(0.22), .clear]),
                                         startPoint: .zero, endPoint: CGPoint(x: 40, y: 16)))

        var figure = local
        figure.scaleBy(x: pose.facing, y: 1)
        figure.drawLayer { body in
            drawLeg(context: &body, side: 1, pose: pose, palette: palette)
            var upper = body
            upper.translateBy(x: -pose.reach * 2, y: pose.bob)
            drawCloak(context: &upper, palette: palette, time: zombie.age)
            drawEquipment(context: &upper, zombie: zombie, pose: pose, palette: palette, rear: true)
            drawArm(context: &upper, front: false, pose: pose, palette: palette, zombie: zombie)
            drawLeg(context: &body, side: -1, pose: pose, palette: palette)
            drawTorso(context: &upper, palette: palette, zombie: zombie)
            drawHead(context: &upper, palette: palette, zombie: zombie, pose: pose)
            drawArm(context: &upper, front: true, pose: pose, palette: palette, zombie: zombie)
            drawEquipment(context: &upper, zombie: zombie, pose: pose, palette: palette, rear: false)
            if zombie.hitFlash > 0 {
                body.blendMode = .sourceAtop
                body.fill(Path(CGRect(x: -90, y: -200, width: 180, height: 220)),
                          with: .color(.white.opacity(min(0.75, zombie.hitFlash * 4))))
            }
        }
        drawStatus(context: &local, zombie: zombie, palette: palette)
    }

    private static func drawLeg(context: inout GraphicsContext, side: CGFloat, pose: ZombiePose, palette: Palette) {
        let stride = pose.stride * side
        let hip = CGPoint(x: side * 9, y: -43)
        let knee = CGPoint(x: side * 9 - stride * 0.55 - 3, y: -24)
        let ankle = CGPoint(x: side * 10 + stride, y: -6 - max(0, pose.lift * side))
        var leg = context
        if side > 0 { leg.opacity = 0.72 }
        bone(context: &leg, from: hip, to: knee, width: 14, color: palette.cloth)
        bone(context: &leg, from: knee, to: ankle, width: 9, color: palette.lacquer)
        for i in 0..<4 {
            let t = CGFloat(i) / 5
            let p = CGPoint(x: knee.x + (ankle.x - knee.x) * t, y: knee.y + (ankle.y - knee.y) * t)
            stroke(context: &leg, points: [(p.x - 4, p.y), (p.x + 3, p.y + 1)], color: palette.metal.opacity(0.8), width: 1)
        }
        let boot = polygon([(ankle.x - 5, ankle.y - 4), (ankle.x + 5, ankle.y - 3),
                            (ankle.x + 7, ankle.y + 4), (ankle.x - 13, ankle.y + 4),
                            (ankle.x - 14, ankle.y + 1), (ankle.x - 8, ankle.y - 1)])
        surface(context: &leg, path: boot, color: palette.cloth, metal: false)
        stroke(context: &leg, points: [(ankle.x - 13, ankle.y + 3), (ankle.x + 6, ankle.y + 3)],
               color: Color(red: 0.49, green: 0.44, blue: 0.30), width: 1.6)
    }

    private static func drawCloak(context: inout GraphicsContext, palette: Palette, time: Double) {
        let flutter = CGFloat(sin(time * 2.8)) * 3
        let cape = polygon([(-16, -84), (19, -82), (25, -64), (30 + flutter, -30),
                            (20, -33), (16 + flutter, -27), (9, -32), (-13, -32), (-20, -45)])
        surface(context: &context, path: cape, color: palette.cloth, metal: false)
        for i in 0..<5 {
            let x = CGFloat(i) * 7 - 11
            stroke(context: &context, points: [(x, -75), (x + 1, -54), (x + flutter + 3, -34)],
                   color: i.isMultiple(of: 2) ? .black.opacity(0.32) : .white.opacity(0.12), width: 2)
        }
    }

    private static func drawTorso(context: inout GraphicsContext, palette p: Palette, zombie: Zombie) {
        var c = context
        c.scaleBy(x: p.breadth, y: 1)
        let chest = polygon([(-17, -86), (-5, -90), (13, -86), (21, -75), (16, -49),
                             (9, -43), (-16, -48), (-22, -68)])
        surface(context: &c, path: chest, color: p.lacquer, metal: true)
        // Curved, overlapping lamellar plates read as volume rather than horizontal stripes.
        for row in 0..<4 {
            let y = CGFloat(row) * 7 - 79
            plate(context: &c, rect: CGRect(x: -18, y: y, width: 32 - CGFloat(row), height: 9),
                  color: p.lacquer, trim: p.metal, seed: row + 7)
        }
        surface(context: &c, path: polygon([(-20, -52), (16, -49), (16, -43), (-20, -45)]),
                color: p.cloth, metal: false)
        surface(context: &c, path: Path(ellipseIn: CGRect(x: -6, y: -52, width: 8, height: 7)),
                color: p.metal, metal: true)
        for side in [-1.0, 1.0] {
            var skirt = c
            skirt.translateBy(x: side * 10, y: -44)
            skirt.rotate(by: .degrees(side * (7 + sin(zombie.age * 3) * 2)))
            for row in 0..<3 {
                plate(context: &skirt, rect: CGRect(x: -8, y: CGFloat(row) * 5, width: 18, height: 7),
                      color: p.lacquer, trim: p.metal, seed: row + 18)
            }
        }
        stroke(context: &c, points: [(-12, -87), (-7, -70), (9, -51)], color: .black.opacity(0.7), width: 5)
        stroke(context: &c, points: [(-13, -87), (-8, -70), (8, -51)], color: p.metal, width: 2.5)
        if zombie.kind == .flameGiant || zombie.kind == .thunderShogun {
            let seams: [(CGFloat, CGFloat)] = [(-13, -79), (-7, -74), (-11, -65), (0, -59), (-3, -51)]
            stroke(context: &c, points: seams, color: p.light.opacity(0.2), width: 5)
            stroke(context: &c, points: seams, color: p.light.opacity(0.85), width: 1.1)
        }
    }

    private static func drawArm(context: inout GraphicsContext, front: Bool, pose: ZombiePose,
                                palette p: Palette, zombie: Zombie) {
        let side: CGFloat = front ? -1 : 1
        let shoulder = CGPoint(x: side * 19 * p.breadth, y: -80)
        let raised = zombie.strikeCharge > 0 && !zombie.charmed
        let reach = front ? pose.reach * 15 : pose.reach * 6
        let elbow = CGPoint(x: shoulder.x + side * 4 - reach,
                            y: raised && front ? -88 - pose.charge * 10 : -62 + side * pose.stride * 0.3)
        let hand = handPoint(zombie: zombie, pose: pose, front: front, breadth: p.breadth)
        var arm = context
        if !front { arm.opacity = 0.75 }
        bone(context: &arm, from: shoulder, to: elbow, width: 11, color: p.cloth)
        bone(context: &arm, from: elbow, to: hand, width: 8, color: p.lacquer)
        for i in 0..<3 {
            plate(context: &arm, rect: CGRect(x: shoulder.x - 10, y: shoulder.y - 5 + CGFloat(i) * 5,
                                             width: 22, height: 8), color: p.lacquer, trim: p.metal, seed: i + 31)
        }
        surface(context: &arm, path: Path(ellipseIn: CGRect(x: hand.x - 4, y: hand.y - 3, width: 9, height: 10)),
                color: p.skin, metal: false)
        for i in 0..<3 {
            stroke(context: &arm, points: [(hand.x - 3 + CGFloat(i) * 2, hand.y + 1),
                                          (hand.x - 2 + CGFloat(i) * 2, hand.y + 5)],
                   color: .black.opacity(0.5), width: 0.7)
        }
    }

    private static func handPoint(zombie: Zombie, pose: ZombiePose, front: Bool, breadth: CGFloat) -> CGPoint {
        if front && zombie.strikeCharge > 0 && !zombie.charmed {
            return CGPoint(x: -29 - pose.charge * 6, y: -101 - pose.charge * 8)
        }
        if front && zombie.kind == .dancerSamurai {
            return CGPoint(x: -34, y: -78 + CGFloat(sin(zombie.dancePhase)) * 12)
        }
        return CGPoint(x: (front ? -23 : 20) * breadth - pose.reach * (front ? 23 : 10) - pose.stride * (front ? 0.5 : -0.5),
                       y: -47 - pose.reach * 15)
    }

    private static func drawHead(context: inout GraphicsContext, palette p: Palette, zombie: Zombie, pose: ZombiePose) {
        var c = context
        c.translateBy(x: -4 - pose.reach * 2, y: -95)
        c.rotate(by: .degrees(-4 - Double(pose.reach) * 5))
        surface(context: &c, path: polygon([(-5, 3), (7, 3), (8, 13), (-6, 13)]), color: p.skin, metal: false)
        // Asymmetric brow, cheek, nose and jaw planes give the face a three-quarter view.
        var skull = Path()
        skull.move(to: CGPoint(x: -13, y: -13))
        skull.addCurve(to: CGPoint(x: 11, y: -15), control1: CGPoint(x: -10, y: -24), control2: CGPoint(x: 7, y: -24))
        skull.addCurve(to: CGPoint(x: 10, y: 2), control1: CGPoint(x: 16, y: -9), control2: CGPoint(x: 13, y: -3))
        skull.addLine(to: CGPoint(x: 6, y: 9))
        skull.addLine(to: CGPoint(x: -3, y: 10))
        skull.addLine(to: CGPoint(x: -11, y: 4))
        skull.addLine(to: CGPoint(x: -15, y: -5))
        skull.closeSubpath()
        surface(context: &c, path: skull, color: p.skin, metal: false)
        weather(context: &c, path: skull, seed: 53, count: 24, color: .black.opacity(0.17))
        c.fill(polygon([(2, -17), (11, -13), (12, -2), (6, 7), (0, 7), (4, -4)]), with: .color(.black.opacity(0.23)))
        c.fill(polygon([(-13, -1), (-7, -4), (-3, 0), (-8, 4)]), with: .color(.black.opacity(0.29)))
        c.fill(polygon([(4, 0), (11, -3), (8, 5), (3, 6)]), with: .color(.black.opacity(0.24)))
        for (x, w) in [(-12.0, 8.5), (2.0, 6.0)] {
            let socket = CGRect(x: x, y: -11, width: w, height: 5.5)
            c.fill(Path(ellipseIn: socket), with: .color(Color(red: 0.10, green: 0.13, blue: 0.10)))
            c.fill(Path(ellipseIn: CGRect(x: x + 1.6, y: -9.5, width: w * 0.40, height: 2)),
                   with: .color(p.light.opacity(0.86)))
            stroke(context: &c, points: [(x - 1, -12.4), (x + w, -10.4)], color: p.skin, width: 2.8)
        }
        surface(context: &c, path: polygon([(-4, -12), (-1, -10), (-2, -3), (-6, -2), (-7, -4)]),
                color: p.skin, metal: false)
        stroke(context: &c, points: [(-10, 3), (-6, 2), (0, 4), (5, 3)], color: .black.opacity(0.85), width: 2)
        for i in 0..<4 {
            c.fill(polygon([(CGFloat(i) * 3 - 8, 2.5), (CGFloat(i) * 3 - 6, 3),
                            (CGFloat(i) * 3 - 6.5, 4.5)]), with: .color(Color(red: 0.74, green: 0.70, blue: 0.51)))
        }
        stroke(context: &c, points: [(-10, -16), (-6, -17), (-1, -15)], color: .white.opacity(0.18), width: 0.8)
        stroke(context: &c, points: [(6, -16), (3, -12), (6, -3)], color: .black.opacity(0.48), width: 0.8)
        drawHelmet(context: &c, zombie: zombie, palette: p)
    }

    private static func drawHelmet(context: inout GraphicsContext, zombie: Zombie, palette p: Palette) {
        let kind = zombie.kind
        if kind == .regular || kind == .dancerSamurai {
            surface(context: &context, path: polygon([(-15, -19), (-9, -24), (7, -24), (13, -19), (12, -15), (-15, -14)]),
                    color: p.cloth, metal: false)
            let tail = CGFloat(sin(zombie.age * 4)) * 3
            surface(context: &context, path: polygon([(11, -18), (25, -16 + tail), (21, -12 + tail), (10, -15)]),
                    color: p.lacquer, metal: false)
            stroke(context: &context, points: [(-14, -16), (12, -17)], color: p.light.opacity(0.6), width: 1.1)
            if kind == .regular {
                surface(context: &context, path: Path(ellipseIn: CGRect(x: 2, y: -30, width: 8, height: 9)),
                        color: Color(red: 0.14, green: 0.16, blue: 0.12), metal: false)
            }
            return
        }
        for i in 0..<3 {
            plate(context: &context, rect: CGRect(x: 7, y: -9 + CGFloat(i) * 4, width: 12, height: 6),
                  color: p.lacquer, trim: p.metal, seed: 61 + i)
        }
        var dome = Path()
        dome.move(to: CGPoint(x: -19, y: -15))
        dome.addCurve(to: CGPoint(x: 17, y: -14), control1: CGPoint(x: -17, y: -39), control2: CGPoint(x: 14, y: -36))
        dome.addQuadCurve(to: CGPoint(x: -19, y: -15), control: CGPoint(x: -2, y: -10))
        surface(context: &context, path: dome, color: p.lacquer, metal: true)
        weather(context: &context, path: dome, seed: 77, count: 16, color: p.metal.opacity(0.55))
        for i in 0..<4 {
            let x = CGFloat(i) * 7 - 12
            var rib = Path()
            rib.move(to: CGPoint(x: -2, y: -31))
            rib.addQuadCurve(to: CGPoint(x: x, y: -15), control: CGPoint(x: x, y: -27))
            context.stroke(rib, with: .color(p.metal.opacity(0.65)), lineWidth: 0.9)
        }
        surface(context: &context, path: polygon([(-23, -16), (-6, -19), (19, -15), (17, -11), (-25, -12)]),
                color: p.lacquer, metal: true)
        if kind == .iceDoctor {
            crystal(context: &context, at: CGPoint(x: -3, y: -28), height: 16, color: .cyan)
            let visor = polygon([(-16, -11), (9, -10), (9, -5), (-13, -4)])
            context.fill(visor, with: .linearGradient(Gradient(colors: [.cyan.opacity(0.15), .white.opacity(0.40), .cyan.opacity(0.12)]),
                                                       startPoint: CGPoint(x: -16, y: -11), endPoint: CGPoint(x: 9, y: -4)))
        } else {
            for side in [-1.0, 1.0] {
                let horn = polygon([(side * 6, -25), (side * 15, -29), (side * 25, -44),
                                    (side * 22, -26), (side * 9, -19)])
                surface(context: &context, path: horn, color: kind == .flameGiant ? p.lacquer : p.metal, metal: true)
            }
            if kind.isBoss {
                surface(context: &context, path: polygon([(-11, 1), (-3, -1), (3, 1), (11, -1), (9, 9), (-5, 10)]),
                        color: p.lacquer, metal: true)
                for i in 0..<4 {
                    stroke(context: &context, points: [(CGFloat(i) * 4 - 6, 4), (CGFloat(i) * 4 - 5, 7)],
                           color: p.metal, width: 1)
                }
            }
        }
    }

    private static func drawEquipment(context: inout GraphicsContext, zombie: Zombie, pose: ZombiePose,
                                       palette p: Palette, rear: Bool) {
        let kind = zombie.kind
        let hand = handPoint(zombie: zombie, pose: pose, front: true, breadth: p.breadth)
        if rear {
            if kind == .iceDoctor {
                for x in [18.0, 28.0] {
                    surface(context: &context, path: Path(roundedRect: CGRect(x: x, y: -82, width: 10, height: 35), cornerRadius: 4),
                            color: p.lacquer, metal: true)
                    stroke(context: &context, points: [(x + 3, -76), (x + 3, -55)], color: p.light.opacity(0.8), width: 2)
                    crystal(context: &context, at: CGPoint(x: x + 5, y: -84), height: 13, color: .cyan)
                }
            } else if kind == .thunderShogun {
                let flutter = CGFloat(sin(zombie.age * 2)) * 3
                stroke(context: &context, points: [(15, -42), (25, -120)], color: p.metal, width: 2.2)
                surface(context: &context, path: polygon([(25, -119), (45, -116), (44 + flutter, -72), (32, -76), (21, -72)]),
                        color: p.cloth, metal: false)
                stroke(context: &context, points: [(35, -109), (29, -98), (37, -100), (30, -86)], color: p.metal, width: 2)
            } else {
                stroke(context: &context, points: [(10, -60), (32, -29)], color: .black.opacity(0.7), width: 4)
                stroke(context: &context, points: [(11, -60), (31, -29)], color: p.metal.opacity(0.7), width: 1)
            }
            return
        }
        switch kind {
        case .hammerGiant, .thunderShogun:
            var weapon = context
            weapon.translateBy(x: hand.x, y: hand.y)
            weapon.rotate(by: .degrees(zombie.strikeCharge > 0 && !zombie.charmed ? -18 - Double(pose.charge) * 20 : -48 + Double(pose.reach) * 64))
            bone(context: &weapon, from: CGPoint(x: 0, y: 10), to: CGPoint(x: 0, y: -33), width: 4, color: p.cloth)
            for i in 0..<5 {
                stroke(context: &weapon, points: [(-2, CGFloat(i) * 4 - 8), (2, CGFloat(i) * 4 - 6)], color: p.metal, width: 0.9)
            }
            let hammer = polygon([(-17, -45), (11, -45), (16, -40), (16, -25), (-17, -25)])
            surface(context: &weapon, path: hammer, color: Color(red: 0.30, green: 0.33, blue: 0.32), metal: true)
            weapon.fill(polygon([(11, -45), (16, -40), (16, -25), (11, -29)]), with: .color(.black.opacity(0.4)))
            weather(context: &weapon, path: hammer, seed: 33, count: 18, color: p.metal.opacity(0.6))
            stroke(context: &weapon, points: [(-12, -43), (-12, -27), (6, -27), (6, -43)], color: p.metal, width: 1.8)
            if zombie.strikeCharge > 0 && !zombie.charmed {
                glow(context: &weapon, at: CGPoint(x: 0, y: -35), radius: 29, color: p.light, opacity: 0.38)
            }
        case .iceDoctor:
            crystal(context: &context, at: CGPoint(x: -23, y: -83), height: 20, color: p.light)
            if zombie.strikeCharge > 0 && !zombie.charmed {
                glow(context: &context, at: hand, radius: 10 + pose.charge * 18, color: .cyan, opacity: 0.85)
                for i in 0..<3 {
                    let a = zombie.age * 5 + Double(i) * 2.1
                    crystal(context: &context, at: CGPoint(x: hand.x + cos(a) * 13, y: hand.y + sin(a) * 10),
                            height: 7, color: .white)
                }
            }
        case .flameGiant:
            for i in 0..<5 {
                let x = CGFloat(i) * 11 - 24
                flame(context: &context, at: CGPoint(x: x, y: -76 + abs(x) * 0.4),
                      height: 13 + CGFloat(sin(zombie.age * 8 + Double(i))) * 4, time: zombie.age + Double(i))
            }
            if zombie.strikeCharge > 0 && !zombie.charmed {
                glow(context: &context, at: hand, radius: 16 + pose.charge * 17, color: .orange, opacity: 0.65)
            }
        case .dancerSamurai:
            var fan = context
            fan.translateBy(x: hand.x, y: hand.y)
            fan.rotate(by: .degrees(sin(zombie.dancePhase) * 20))
            var silk = Path()
            silk.move(to: .zero)
            silk.addArc(center: .zero, radius: 24, startAngle: .degrees(205), endAngle: .degrees(335), clockwise: false)
            silk.closeSubpath()
            surface(context: &fan, path: silk, color: p.lacquer, metal: false)
            for i in 0..<8 {
                let a = (205 + Double(i) * 130 / 7) * .pi / 180
                stroke(context: &fan, points: [(0, 0), (cos(a) * 24, sin(a) * 24)], color: p.metal, width: 0.8)
            }
            fan.fill(Path(ellipseIn: CGRect(x: -4, y: -19, width: 8, height: 8)), with: .color(p.light.opacity(0.65)))
        case .regular, .bucketHead:
            break
        }
    }

    private static func drawStatus(context: inout GraphicsContext, zombie: Zombie, palette p: Palette) {
        if zombie.charmed || zombie.slowTimer > 0 || zombie.danceBoostTimer > 0 {
            let color: Color = zombie.charmed ? .purple : zombie.slowTimer > 0 ? .cyan : .yellow
            context.stroke(Path(ellipseIn: CGRect(x: -28, y: -7, width: 56, height: 14)),
                           with: .color(color.opacity(0.85)), style: StrokeStyle(lineWidth: 1.8, dash: [4, 3]))
        }
        if zombie.slowTimer > 0 {
            for i in 0..<3 {
                crystal(context: &context, at: CGPoint(x: CGFloat(i) * 12 - 12, y: -4), height: 9, color: .cyan)
            }
        }
        if zombie.burnTimer > 0 {
            flame(context: &context, at: CGPoint(x: 22, y: -55), height: 20, time: zombie.age)
        }
        let health = max(0, min(1, zombie.hp / zombie.kind.maxHP))
        let width: CGFloat = zombie.kind.isBoss ? 76 : 44
        let bar = CGRect(x: -width / 2, y: -145, width: width, height: 4)
        context.fill(Path(roundedRect: bar.insetBy(dx: -1, dy: -1), cornerRadius: 2), with: .color(.black.opacity(0.75)))
        context.fill(Path(roundedRect: CGRect(x: bar.minX, y: bar.minY, width: width * health, height: bar.height), cornerRadius: 1.5),
                     with: .linearGradient(Gradient(colors: [p.light, p.lacquer]), startPoint: bar.origin, endPoint: CGPoint(x: bar.maxX, y: bar.maxY)))
        if zombie.kind.isBoss || zombie.kind == .dancerSamurai {
            context.draw(Text(zombie.kind.title.uppercased()).font(.system(size: 7, weight: .heavy)).foregroundStyle(.white),
                         at: CGPoint(x: 0, y: -153))
        }
        var labels: [String] = []
        if zombie.charmed { labels.append("ALLY") }
        if zombie.slowTimer > 0 { labels.append("SLOWED") }
        if zombie.burnTimer > 0 { labels.append("BURNING") }
        if zombie.danceBoostTimer > 0 { labels.append("DANCE DASH") }
        if zombie.kind.isCharmImmune { labels.append("CHARM IMMUNE") }
        if !labels.isEmpty {
            context.draw(Text(labels.joined(separator: " / ")).font(.system(size: 6.5, weight: .heavy)).foregroundStyle(.white),
                         at: CGPoint(x: 0, y: 15))
        }
        if zombie.strikeCharge > 0 && !zombie.charmed {
            let warning: String = switch zombie.kind {
            case .hammerGiant: "HAMMER STRIKE"
            case .iceDoctor: "ICE ORB"
            case .flameGiant: "FLAME STRIKE"
            case .thunderShogun: "LIGHTNING CHARGING"
            default: "ATTACK"
            }
            context.fill(Path(roundedRect: CGRect(x: -49, y: -137, width: 98, height: 12), cornerRadius: 3),
                         with: .color(.black.opacity(0.82)))
            context.draw(Text(warning).font(.system(size: 7, weight: .black)).foregroundStyle(p.light),
                         at: CGPoint(x: 0, y: -131))
        }
    }

    private static func plate(context: inout GraphicsContext, rect r: CGRect, color: Color, trim: Color, seed: Int) {
        let shape = polygon([(r.minX, r.minY), (r.maxX - 3, r.minY - 1), (r.maxX, r.maxY - 2),
                             (r.midX, r.maxY + 1), (r.minX - 1, r.maxY - 1)])
        surface(context: &context, path: shape, color: color, metal: true)
        stroke(context: &context, points: [(r.minX, r.maxY - 1), (r.midX, r.maxY + 1), (r.maxX, r.maxY - 2)],
               color: trim.opacity(0.8), width: 0.7)
        for x in [r.minX + 3, r.maxX - 4] {
            context.fill(Path(ellipseIn: CGRect(x: x, y: r.minY + 1, width: 1.8, height: 1.3)), with: .color(trim))
            stroke(context: &context, points: [(x, r.minY + 3), (x + 1, r.minY + 5)],
                   color: .black.opacity(0.6), width: 1.2)
        }
        weather(context: &context, path: shape, seed: seed, count: 3, color: trim.opacity(0.5))
    }

    private static func surface(context: inout GraphicsContext, path: Path, color: Color, metal: Bool) {
        let r = path.boundingRect
        let transform = context.transform
        let mirrored = transform.a * transform.d - transform.b * transform.c < 0
        let light = CGPoint(x: mirrored ? r.maxX : r.minX, y: r.minY)
        let shade = CGPoint(x: mirrored ? r.minX : r.maxX, y: r.midY + r.height * 0.3)
        context.fill(path, with: .color(color))
        context.fill(path, with: .linearGradient(Gradient(stops: [
            .init(color: .white.opacity(metal ? 0.36 : 0.18), location: 0),
            .init(color: .white.opacity(metal ? 0.12 : 0.05), location: 0.24),
            .init(color: .clear, location: 0.40),
            .init(color: .black.opacity(0.20), location: 0.68),
            .init(color: .black.opacity(0.61), location: 1)
        ]), startPoint: light, endPoint: shade))
        context.stroke(path, with: .color(.black.opacity(0.5)), lineWidth: 0.65)
    }

    private static func weather(context: inout GraphicsContext, path: Path, seed: Int, count: Int, color: Color) {
        let r = path.boundingRect
        var scratches = Path()
        for i in 0..<count {
            let x = r.minX + CGFloat((i * 37 + seed * 11) % 101) / 101 * r.width
            let y = r.minY + CGFloat((i * 61 + seed * 7) % 97) / 97 * r.height
            scratches.move(to: CGPoint(x: x, y: y))
            scratches.addLine(to: CGPoint(x: x + CGFloat(i % 3) + 0.6, y: y - 0.6))
        }
        var clipped = context
        clipped.clip(to: path)
        clipped.stroke(scratches, with: .color(color), lineWidth: 0.6)
    }

    private static func bone(context: inout GraphicsContext, from a: CGPoint, to b: CGPoint, width: CGFloat, color: Color) {
        let angle = atan2(b.y - a.y, b.x - a.x)
        let length = hypot(b.x - a.x, b.y - a.y)
        var c = context
        c.translateBy(x: a.x, y: a.y)
        c.rotate(by: .radians(angle - .pi / 2))
        surface(context: &c, path: Path(roundedRect: CGRect(x: -width / 2, y: -width * 0.3,
                                                           width: width, height: length + width * 0.6), cornerRadius: width * 0.38),
                color: color, metal: false)
    }

    private static func crystal(context: inout GraphicsContext, at p: CGPoint, height h: CGFloat, color: Color) {
        surface(context: &context, path: polygon([(p.x, p.y - h), (p.x + h * 0.23, p.y - h * 0.3),
                                                  (p.x, p.y + 2), (p.x - h * 0.21, p.y - h * 0.25)]),
                color: color.opacity(0.8), metal: true)
        stroke(context: &context, points: [(p.x, p.y - h), (p.x - 1, p.y)], color: .white.opacity(0.75), width: 0.7)
    }

    private static func flame(context: inout GraphicsContext, at p: CGPoint, height h: CGFloat, time: Double) {
        let sway = CGFloat(sin(time * 9)) * h * 0.18
        var shape = Path()
        shape.move(to: CGPoint(x: p.x - h * 0.25, y: p.y))
        shape.addQuadCurve(to: CGPoint(x: p.x + sway, y: p.y - h), control: CGPoint(x: p.x - h * 0.40, y: p.y - h * 0.5))
        shape.addQuadCurve(to: CGPoint(x: p.x + h * 0.25, y: p.y), control: CGPoint(x: p.x + h * 0.02, y: p.y - h * 0.45))
        shape.closeSubpath()
        context.fill(shape, with: .linearGradient(Gradient(colors: [.red.opacity(0.10), .orange, .yellow.opacity(0.92)]),
                                                  startPoint: CGPoint(x: p.x, y: p.y - h), endPoint: p))
    }

    private static func glow(context: inout GraphicsContext, at point: CGPoint, radius: CGFloat, color: Color, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [.white.opacity(opacity), color.opacity(opacity * 0.7), .clear]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    private static func polygon(_ points: [(CGFloat, CGFloat)]) -> Path {
        GardenTerrain.polygon(points.map { CGPoint(x: $0.0, y: $0.1) })
    }

    private static func stroke(context: inout GraphicsContext, points: [(CGFloat, CGFloat)], color: Color, width: CGFloat) {
        var path = Path()
        for (index, point) in points.enumerated() {
            if index == 0 { path.move(to: CGPoint(x: point.0, y: point.1)) }
            else { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
        }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}
