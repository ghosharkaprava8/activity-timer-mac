import Foundation
import IOKit

// Seconds since the last user input (keyboard/mouse), system-wide.
func systemIdleSeconds() -> Double {
    var iterator: io_iterator_t = 0
    guard IOServiceGetMatchingServices(kIOMainPortDefault,
                                       IOServiceMatching("IOHIDSystem"),
                                       &iterator) == KERN_SUCCESS else { return 0 }
    defer { IOObjectRelease(iterator) }

    let entry = IOIteratorNext(iterator)
    guard entry != 0 else { return 0 }
    defer { IOObjectRelease(entry) }

    var dict: Unmanaged<CFMutableDictionary>?
    guard IORegistryEntryCreateCFProperties(entry, &dict, kCFAllocatorDefault, 0) == KERN_SUCCESS,
          let props = dict?.takeRetainedValue() as? [String: Any],
          let idleNs = props["HIDIdleTime"] as? UInt64 else { return 0 }
    return Double(idleNs) / 1_000_000_000.0
}
