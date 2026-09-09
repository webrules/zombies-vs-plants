// Run on macOS: swift Tools/GenerateAppIcon.swift
// Original code-drawn artwork, with no external fonts or image dependencies.
import AppKit
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let c = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                  bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
c.setFillColor(NSColor(calibratedRed: 0.12, green: 0.28, blue: 0.25, alpha: 1).cgColor)
c.fill(CGRect(x: 0, y: 0, width: size, height: size))
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
    NSColor(calibratedRed: 0.99, green: 0.89, blue: 0.60, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.45, green: 0.76, blue: 0.59, alpha: 1).cgColor
] as CFArray, locations: [0, 1])!
c.drawLinearGradient(gradient, start: CGPoint(x: 200, y: 1000), end: CGPoint(x: 800, y: 0), options: [])
c.setFillColor(NSColor(calibratedRed: 1, green: 0.92, blue: 0.66, alpha: 1).cgColor)
c.fillEllipse(in: CGRect(x: 340, y: 570, width: 360, height: 360))
c.setStrokeColor(NSColor(calibratedRed: 0.18, green: 0.48, blue: 0.43, alpha: 1).cgColor)
c.setLineWidth(65)
c.move(to: CGPoint(x: 0, y: 90))
c.addCurve(to: CGPoint(x: 1100, y: 190), control1: CGPoint(x: 370, y: 400), control2: CGPoint(x: 660, y: -40))
c.strokePath()
// Vermilion gateway, softly curved lintel, and two warm stone feet.
c.setFillColor(NSColor(calibratedRed: 0.71, green: 0.17, blue: 0.18, alpha: 1).cgColor)
for x in [260, 680] { c.fill(CGRect(x: x, y: 230, width: 84, height: 455)) }
c.fill(CGRect(x: 224, y: 574, width: 576, height: 66))
c.setLineWidth(92)
c.setLineCap(.round)
c.setStrokeColor(NSColor(calibratedRed: 0.80, green: 0.23, blue: 0.21, alpha: 1).cgColor)
c.move(to: CGPoint(x: 170, y: 750))
c.addQuadCurve(to: CGPoint(x: 854, y: 750), control: CGPoint(x: 512, y: 650))
c.strokePath()
c.setLineWidth(27)
c.setStrokeColor(NSColor(calibratedRed: 0.22, green: 0.21, blue: 0.19, alpha: 1).cgColor)
c.move(to: CGPoint(x: 160, y: 793))
c.addQuadCurve(to: CGPoint(x: 864, y: 793), control: CGPoint(x: 512, y: 688))
c.strokePath()
c.setFillColor(NSColor(calibratedRed: 0.89, green: 0.80, blue: 0.60, alpha: 1).cgColor)
for x in [240, 660] { c.fill(CGRect(x: x, y: 206, width: 124, height: 45)) }
// Guardian sprout at the heart of the garden.
c.setStrokeColor(NSColor(calibratedRed: 0.15, green: 0.36, blue: 0.17, alpha: 1).cgColor)
c.setLineWidth(30)
c.move(to: CGPoint(x: 512, y: 240)); c.addLine(to: CGPoint(x: 512, y: 410)); c.strokePath()
c.setFillColor(NSColor(calibratedRed: 0.27, green: 0.60, blue: 0.25, alpha: 1).cgColor)
c.fillEllipse(in: CGRect(x: 386, y: 335, width: 136, height: 68))
c.fillEllipse(in: CGRect(x: 510, y: 370, width: 144, height: 72))
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let destination = root.appendingPathComponent("MoonbridgeGarden/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
let writer = CGImageDestinationCreateWithURL(destination as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(writer, c.makeImage()!, nil)
precondition(CGImageDestinationFinalize(writer))
print(destination.path)
