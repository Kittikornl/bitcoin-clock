import AppKit

/// Menu bar icon for the "⛏" mark.
///
/// Putting the character straight into the status item's title lets macOS choose the font. On
/// newer SDKs it picks the color emoji font, whose metrics push the digits off the menu bar's
/// baseline and clip them, and the glyph turns grey. So the glyph is drawn from STIX Two Math
/// (the thin, tintable pickaxe) into an image instead. If that font is missing, a hand-drawn
/// pickaxe is used so the icon never falls back to the emoji font.
enum PickaxeIcon {
    static func image(color: NSColor) -> NSImage {
        if let font = NSFont(name: "STIXTwoMath-Regular", size: 13) {
            return glyphImage(font: font, color: color)
        }
        return drawnImage(color: color, size: 14)
    }

    private static func glyphImage(font: NSFont, color: NSColor) -> NSImage {
        let ctFont = font as CTFont
        var character: UniChar = 0x26CF
        var glyph = CGGlyph()
        guard CTFontGetGlyphsForCharacters(ctFont, &character, &glyph, 1) else {
            return drawnImage(color: color, size: 14)
        }
        // Exact ink bounds, relative to the baseline origin (y up), so the glyph can be centered.
        let ink = CTFontGetBoundingRectsForGlyphs(ctFont, .horizontal, &glyph, nil, 1)
        let pad: CGFloat = 1
        let size = NSSize(width: ceil(ink.width) + pad * 2, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.setFillColor(color.cgColor)
            var position = CGPoint(
                x: pad - ink.minX,
                y: (rect.height - ink.height) / 2 - ink.minY
            )
            CTFontDrawGlyphs(ctFont, &glyph, &position, 1, context)
            return true
        }
        image.isTemplate = false
        return image
    }

    private static func drawnImage(color: NSColor, size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let s = rect.width / 16
            color.setStroke()

            let handle = NSBezierPath()
            handle.move(to: NSPoint(x: 2.5 * s, y: 2.5 * s))
            handle.line(to: NSPoint(x: 11.5 * s, y: 10 * s))
            handle.lineWidth = 1.8 * s
            handle.lineCapStyle = .round
            handle.stroke()

            let head = NSBezierPath()
            head.move(to: NSPoint(x: 3.5 * s, y: 12.5 * s))
            head.curve(
                to: NSPoint(x: 13.5 * s, y: 2.5 * s),
                controlPoint1: NSPoint(x: 11 * s, y: 14 * s),
                controlPoint2: NSPoint(x: 14.5 * s, y: 6 * s)
            )
            head.lineWidth = 2.2 * s
            head.lineCapStyle = .round
            head.stroke()
            return true
        }
        image.isTemplate = false
        return image
    }
}
