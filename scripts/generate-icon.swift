import AppKit

let orange = NSColor(red: 0xF7/255, green: 0x93/255, blue: 0x1A/255, alpha: 1)
let sizes: [(Int, String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x"),
]

let outDir = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

for (size, name) in sizes {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    let circleRect = NSRect(x: 0, y: 0, width: s, height: s)
    let circle = NSBezierPath(ovalIn: circleRect)
    orange.setFill()
    circle.fill()

    let symbolConfig = NSImage.SymbolConfiguration(pointSize: s * 0.62, weight: .bold)
    if let symbol = NSImage(systemSymbolName: "bitcoinsign", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig) {
        let tinted = NSImage(size: symbol.size)
        tinted.lockFocus()
        NSColor.white.set()
        let rect = NSRect(origin: .zero, size: symbol.size)
        symbol.draw(in: rect)
        rect.fill(using: .sourceAtop)
        tinted.unlockFocus()

        let drawSize = tinted.size
        let origin = NSPoint(x: (s - drawSize.width) / 2, y: (s - drawSize.height) / 2)
        tinted.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
    }

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to render \(name)")
    }
    try! png.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
}
print("Generated \(sizes.count) icon sizes in \(outDir)")
