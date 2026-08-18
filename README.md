# Bitcoin Clock

A tiny macOS menu bar app showing live Bitcoin block height, price, and time until the next halving.

![Bitcoin Clock screenshot](docs/screenshot.png)

## Features

- Menu bar shows current block height (⛏ prefix, Bitcoin-orange text)
- Popover with:
  - BTC price (USD)
  - Block height
  - Next halving block + ETA (based on 10-min average block time)
- Data from [mempool.space](https://mempool.space) public API
  - Price refreshes every 15s
  - Block height refreshes every 30s

## Requirements

- macOS 13+
- Swift 5.9+ (Xcode or Swift toolchain)

## Build & Run

```bash
swift run
```

This launches the app as a menu bar accessory (no Dock icon). Click the menu bar item to open the popover; click the `×` in the popover to quit.

## Project structure

```
Sources/BitcoinClock/
  main.swift            entry point
  AppDelegate.swift      status item + popover wiring
  BitcoinService.swift   polls mempool.space for price/block height
  ContentView.swift      popover UI
  BitcoinPalette.swift   shared Bitcoin-orange color
```
