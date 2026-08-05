# CougarSwift

> Swift Package for MetricKit performance monitoring with Supabase backend.  
> The iOS companion to [Cougar](../cougar) — a SaaS dashboard for Apple app teams.

## What it does

CougarSwift collects daily MetricKit payloads and sends them to a Supabase PostgreSQL database, where they can be visualised in the Cougar dashboard.

**Captured metrics:**
- 🚀 Launch time (cold, warm, extended) — p50 + p90
- ⏳ Hang time — p50 + p90  
- 💾 CPU, GPU, memory, disk writes
- 📡 Network transfers (Wi-Fi + cellular)
- 📍 Location accuracy tier usage
- 💥 App exit reasons (15 foreground + background fields)
- 🩺 Diagnostics: crashes, hangs, CPU exceptions, disk exceptions (with call stack JSON)

## Requirements

- iOS 18+
- Swift 6.0+
- A [Supabase](https://supabase.com) project with the schema from `supabase/migrations/`

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies** → enter the repo URL.

Or in `Package.swift`:

```swift
.package(url: "https://github.com/your-org/CougarSwift.git", from: "1.0.0")
```

Then add `"CougarSwift"` to your target's dependencies.

## Setup

### 1. Apply the Supabase schema

Run `supabase/migrations/001_initial_schema.sql` in your Supabase SQL Editor.

### 2. Add credentials to Info.plist

Add these two entries to your app target's `Info.plist`:

| Key | Value |
|-----|-------|
| `SupabaseURL` | `https://your-project.supabase.co` |
| `SupabaseAnonKey` | `your-anon-key` |

### 3. Configure and start collecting

```swift
// In your AppDelegate or @main App:
import CougarSwift

@main
struct MyApp: App {
    init() {
        MXMetricsManager.configure()
        MXMetricsManager.shared?.startCollecting()
    }
}
```

### 4. Verify the connection (DEBUG only)

```swift
#if DEBUG
MXMetricsManager.shared?.sendTestRecord()
#endif
```

## Custom Storage Backend

Implement `MetricsStorageService` to send data anywhere:

```swift
struct MyBackend: MetricsStorageService {
    func store(metrics: consuming AppMetrics) async throws { ... }
    func store(diagnostics: consuming AppDiagnostics) async throws { ... }
}

MXMetricsManager.configure(with: MyBackend())
```

## License

MIT
