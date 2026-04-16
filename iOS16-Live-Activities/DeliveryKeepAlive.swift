//
//  DeliveryKeepAlive.swift
//  iOS16-Live-Activities
//
//  Two offline keep-alive strategies for flipping a Live Activity to its
//  "delivered" end-state exactly when the countdown hits 0 — WITHOUT any
//  APNs push. Both share the same shape: keep the app runnable in the
//  background via a side-channel, run a `DispatchSourceTimer` at `endDate`,
//  and call `activity.update(finalContent)` — which is the only mechanism
//  that punches through the Live Activity lock-screen render freeze.
//
//  1. `LocationKeepAlive`
//     Uses significant-location-change monitoring. Language: "we're tracking
//     your driver". Natural fit for delivery / navigation apps.
//
//  2. `AudioKeepAlive`
//     Plays silent audio on a `.playback` session. Language: "timer alarm /
//     ambient sound". Natural fit for timer / meditation / workout apps.
//     Uses `.mixWithOthers` so it doesn't interrupt Apple Music etc.
//

import ActivityKit
import AVFoundation
import CoreLocation
import Foundation

// MARK: - Location keep-alive

/// Keeps the app runnable in background via `CLLocationManager`'s
/// significant-location-changes service. Much lighter than `.startUpdatingLocation`
/// — iOS only wakes the app when the user moves ~500m, but holding the
/// subscription is enough to defeat the ~7s lock-screen render freeze.
final class LocationKeepAlive: NSObject, CLLocationManagerDelegate {
    static let shared = LocationKeepAlive()

    private let manager: CLLocationManager
    private var endTimer: DispatchSourceTimer?
    private var midpointTimer: DispatchSourceTimer?
    private var onFire: (() -> Void)?

    private override init() {
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    /// Ask for Always authorization. Call once, early.
    func requestAuthorizationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            // Upgrade prompt for background.
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    /// Begin keep-alive and schedule:
    ///   - an optional mid-flight timer at `midpoint` → runs `midpointFire`.
    ///     Used to force an `activity.update()` push so the widget re-renders
    ///     and the warehouse → ✓ swap actually takes effect. TimelineView is
    ///     unreliable in Live Activity content views once the phone is locked,
    ///     so we drive it ourselves.
    ///   - a one-shot timer at `endDate` → runs `fire` (final state push).
    func start(
        until endDate: Date,
        midpoint: Date? = nil,
        midpointFire: (() -> Void)? = nil,
        fire: @escaping () -> Void
    ) {
        manager.startMonitoringSignificantLocationChanges()
        onFire = fire

        if let midpoint = midpoint, let midpointFire = midpointFire {
            midpointTimer?.cancel()
            let mid = DispatchSource.makeTimerSource(queue: .main)
            mid.schedule(deadline: .now() + max(0, midpoint.timeIntervalSinceNow))
            mid.setEventHandler { midpointFire() }
            mid.resume()
            midpointTimer = mid
        }

        endTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        let delay = max(0, endDate.timeIntervalSinceNow)
        timer.schedule(deadline: .now() + delay)
        timer.setEventHandler { [weak self] in
            self?.onFire?()
            self?.stop()
        }
        timer.resume()
        endTimer = timer
    }

    func stop() {
        manager.stopMonitoringSignificantLocationChanges()
        midpointTimer?.cancel()
        midpointTimer = nil
        endTimer?.cancel()
        endTimer = nil
        onFire = nil
    }

    // MARK: CLLocationManagerDelegate
    // No-op: we only care about the keep-alive side effect, not the actual
    // location updates. Implementing the delegate is required, though.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

// MARK: - Audio keep-alive

/// Keeps the app runnable in background by holding an active `AVAudioSession`
/// that plays a programmatically-generated silent WAV on loop. Matches the
/// trick Loop / Focuspasta / Launchify are known to use. A `DispatchSourceTimer`
/// then fires at `endDate` and calls `activity.update(finalContent)`.
///
/// Category is `.playback` (required to stay alive while locked) with option
/// `.mixWithOthers` so we don't interrupt music the user is already playing
/// — and so Control Center's Now Playing strip doesn't get hijacked.
final class AudioKeepAlive {
    static let shared = AudioKeepAlive()

    private var player: AVAudioPlayer?
    private var endTimer: DispatchSourceTimer?
    private var midpointTimer: DispatchSourceTimer?
    private var onFire: (() -> Void)?

    private init() {}

    /// Start the silent audio session and schedule:
    ///   - optional midpoint push to force a widget re-render (see
    ///     `LocationKeepAlive.start` for the same rationale).
    ///   - final push at `endDate`.
    func start(
        until endDate: Date,
        midpoint: Date? = nil,
        midpointFire: (() -> Void)? = nil,
        fire: @escaping () -> Void
    ) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            // Synthesize ~1s of silent PCM WAV and load it — avoids shipping
            // an .mp3 asset and keeps the trick self-contained.
            let silent = Self.silentWAV(durationSeconds: 1.0)
            let p = try AVAudioPlayer(data: silent, fileTypeHint: AVFileType.wav.rawValue)
            p.numberOfLoops = -1
            p.volume = 0
            p.prepareToPlay()
            p.play()
            player = p
        } catch {
            print("AudioKeepAlive start failed: \(error)")
        }

        onFire = fire

        if let midpoint = midpoint, let midpointFire = midpointFire {
            midpointTimer?.cancel()
            let mid = DispatchSource.makeTimerSource(queue: .main)
            mid.schedule(deadline: .now() + max(0, midpoint.timeIntervalSinceNow))
            mid.setEventHandler { midpointFire() }
            mid.resume()
            midpointTimer = mid
        }

        endTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        let delay = max(0, endDate.timeIntervalSinceNow)
        timer.schedule(deadline: .now() + delay)
        timer.setEventHandler { [weak self] in
            self?.onFire?()
            self?.stop()
        }
        timer.resume()
        endTimer = timer
    }

    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        midpointTimer?.cancel()
        midpointTimer = nil
        endTimer?.cancel()
        endTimer = nil
        onFire = nil
    }

    /// Build a minimal PCM WAV file in memory at 8kHz/16-bit/mono filled with
    /// zeros. That's the smallest self-contained "valid audio" we can hand
    /// to `AVAudioPlayer` without an asset.
    private static func silentWAV(durationSeconds: Double) -> Data {
        let sampleRate: UInt32 = 8000
        let bitsPerSample: UInt16 = 16
        let channels: UInt16 = 1
        let byteRate = sampleRate * UInt32(channels) * UInt32(bitsPerSample / 8)
        let blockAlign = channels * (bitsPerSample / 8)
        let numSamples = UInt32(Double(sampleRate) * durationSeconds)
        let dataSize = numSamples * UInt32(blockAlign)
        let chunkSize = 36 + dataSize

        var wav = Data()
        wav.append("RIFF".data(using: .ascii)!)
        wav.appendLE(UInt32(chunkSize))
        wav.append("WAVE".data(using: .ascii)!)
        wav.append("fmt ".data(using: .ascii)!)
        wav.appendLE(UInt32(16))            // PCM header size
        wav.appendLE(UInt16(1))             // format: PCM
        wav.appendLE(channels)
        wav.appendLE(sampleRate)
        wav.appendLE(byteRate)
        wav.appendLE(blockAlign)
        wav.appendLE(bitsPerSample)
        wav.append("data".data(using: .ascii)!)
        wav.appendLE(UInt32(dataSize))
        wav.append(Data(count: Int(dataSize))) // actual silence
        return wav
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }
}
