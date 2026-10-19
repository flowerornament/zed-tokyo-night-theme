// Print the id of the largest normal window owned by a process.
//
//   swift window-id.swift <pid>
//
// Matching on the process rather than the app name keeps the capture away
// from any other Zed windows on the machine.

import CoreGraphics

let pid = Int(CommandLine.arguments[1])!
let windows = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] ?? []

let area = { (w: [String: Any]) -> Double in
  let b = w[kCGWindowBounds as String] as? [String: Double] ?? [:]
  return (b["Width"] ?? 0) * (b["Height"] ?? 0)
}

let best = windows
  .filter { ($0[kCGWindowOwnerPID as String] as? Int) == pid && ($0[kCGWindowLayer as String] as? Int) == 0 }
  .max { area($0) < area($1) }

if let id = best?[kCGWindowNumber as String] as? Int, area(best!) > 200_000 {
  print(id)
}
