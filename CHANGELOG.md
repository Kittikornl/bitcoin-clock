# Changelog

## Unreleased

- On first launch from outside Applications (dmg, Downloads), offer to move the app into /Applications and relaunch from there
- Menu bar: draw the pickaxe from STIX Two Math as an image instead of putting "⛏" in the title, so newer macOS no longer swaps in the emoji font (grey glyph, digits pushed down and clipped)
- build-dmg.sh: build the universal binary with one `swift build` and find it via `--show-bin-path`, then check both architectures are present (it was lipo-ing stale binaries with newer toolchains)

## 1.0.1

- App icon: bitcoin sign on brand-orange circle

## 1.0.0

- Menu bar shows live block height
- Popover: BTC price, block height, halving countdown
- Launches at login (SMAppService)
- Release `.dmg` via `scripts/build-dmg.sh`
