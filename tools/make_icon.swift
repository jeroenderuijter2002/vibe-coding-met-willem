import AppKit
import CoreGraphics

let size: CGFloat = 1024
let out = CommandLine.arguments[1]
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(srgbRed: r, green: g, blue: b, alpha: a) }

// Achtergrond: middernachtblauw verloop (zelfde als de app, zie Shared/Theme.swift)
let bg = CGGradient(colorsSpace: cs, colors: [rgb(0.09, 0.13, 0.27), rgb(0.03, 0.04, 0.10)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
// Zachte koraal gloed achter de munten
let glow = CGGradient(colorsSpace: cs, colors: [rgb(0.94, 0.54, 0.42, 0.35), rgb(0.94, 0.54, 0.42, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 512, y: 470), startRadius: 0, endCenter: CGPoint(x: 512, y: 470), endRadius: 480, options: [])

let goldLight = rgb(1.0, 0.79, 0.69), gold = rgb(0.94, 0.54, 0.42), goldDark = rgb(0.72, 0.33, 0.23), edge = rgb(0.50, 0.21, 0.14)  // perzik, koraal, koper
let coinGrad = CGGradient(colorsSpace: cs, colors: [goldLight, gold, goldDark] as CFArray, locations: [0, 0.45, 1])!

func coin(cx: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, thickness: CGFloat) {
    // zijkant (dikte)
    let side = CGRect(x: cx - w/2, y: y - thickness, width: w, height: h)
    ctx.setFillColor(edge); ctx.fillEllipse(in: side)
    ctx.setFillColor(goldDark)
    ctx.fill(CGRect(x: cx - w/2, y: y - thickness + h/2, width: w, height: thickness))
    // bovenkant
    let top = CGRect(x: cx - w/2, y: y, width: w, height: h)
    ctx.saveGState(); ctx.addEllipse(in: top); ctx.clip()
    ctx.drawLinearGradient(coinGrad, start: CGPoint(x: cx - w/2, y: y + h), end: CGPoint(x: cx + w/2, y: y), options: [])
    ctx.restoreGState()
    ctx.setStrokeColor(edge); ctx.setLineWidth(5); ctx.strokeEllipse(in: top.insetBy(dx: 2.5, dy: 2.5))
    // glimlicht
    ctx.setFillColor(rgb(1, 1, 1, 0.45))
    ctx.fillEllipse(in: CGRect(x: cx - w*0.28, y: y + h*0.52, width: w*0.32, height: h*0.18))
}

// Drie stapels: laag, hoog, middel (van achter naar voor tekenen = van onder naar boven)
let w: CGFloat = 250, h: CGFloat = 78, thick: CGFloat = 30, step: CGFloat = 40
let baseY: CGFloat = 200
let stacks: [(cx: CGFloat, count: Int)] = [(250, 5), (512, 9), (774, 7)]
for s in stacks {
    for i in 0..<s.count { coin(cx: s.cx, y: baseY + CGFloat(i) * step, w: w, h: h, thickness: thick) }
}

// Euroteken bovenop de middelste stapel, in een munt die "valt"
let bigW: CGFloat = 300
let bigRect = CGRect(x: 512 - bigW/2, y: 640, width: bigW, height: bigW)
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: rgb(0, 0, 0, 0.45))
ctx.setFillColor(edge); ctx.fillEllipse(in: bigRect.offsetBy(dx: 0, dy: -14))
ctx.setShadow(offset: .zero, blur: 0, color: nil)
ctx.saveGState(); ctx.addEllipse(in: bigRect); ctx.clip()
ctx.drawLinearGradient(coinGrad, start: CGPoint(x: bigRect.minX, y: bigRect.maxY), end: CGPoint(x: bigRect.maxX, y: bigRect.minY), options: [])
ctx.restoreGState()
ctx.setStrokeColor(edge); ctx.setLineWidth(10); ctx.strokeEllipse(in: bigRect.insetBy(dx: 26, dy: 26))

let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
NSGraphicsContext.current = ns
let font = NSFont.systemFont(ofSize: 190, weight: .black)
let euro = NSAttributedString(string: "€", attributes: [.font: font, .foregroundColor: NSColor(cgColor: edge)!])
let es = euro.size()
euro.draw(at: CGPoint(x: 512 - es.width/2, y: bigRect.midY - es.height/2 + 6))

// Sterretjes
func sparkle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
    ctx.setFillColor(rgb(1, 0.88, 0.80, 0.95))
    let p = CGMutablePath()
    p.move(to: CGPoint(x: x, y: y + r)); p.addQuadCurve(to: CGPoint(x: x + r, y: y), control: CGPoint(x: x, y: y))
    p.addQuadCurve(to: CGPoint(x: x, y: y - r), control: CGPoint(x: x, y: y)); p.addQuadCurve(to: CGPoint(x: x - r, y: y), control: CGPoint(x: x, y: y))
    p.addQuadCurve(to: CGPoint(x: x, y: y + r), control: CGPoint(x: x, y: y)); ctx.addPath(p); ctx.fillPath()
}
sparkle(250, 760, 46); sparkle(800, 850, 34); sparkle(860, 640, 22)

let img = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: img)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("ok")
