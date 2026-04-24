import AppKit
import Foundation

// Generates short sine-wave tones at runtime, packs them into in-memory WAV
// data, and plays them via NSSound(data:). This avoids AVAudioEngine (which
// failed silently during earlier Clear-style experiments) and gives us the
// ascending per-position chime we want for task completions.
//
// For delete/add we stick with macOS system sounds — they're short, cached,
// and sound distinct from the musical chime.
final class AudioController {
    static let shared = AudioController()

    var volume: Float = 0.6

    // Pentatonic scale (C major): C5, D5, E5, G5, A5, C6, D6, E6.
    private let frequencies: [Double] = [
        523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51,
    ]

    private var chimeCache: [Int: Data] = [:]

    private init() {}

    // Task complete — ascending pentatonic note per row position.
    func playComplete(position: Int) {
        let idx = min(max(position, 0), frequencies.count - 1)
        let data: Data
        if let cached = chimeCache[idx] {
            data = cached
        } else {
            data = Self.wavSineTone(frequency: frequencies[idx], duration: 0.28)
            chimeCache[idx] = data
        }
        play(data: data)
    }

    func playDelete() { systemSound("Basso") }
    func playAdd()    { systemSound("Pop") }

    // MARK: - Playback helpers

    private func play(data: Data) {
        guard let sound = NSSound(data: data) else { return }
        sound.volume = volume
        sound.play()
    }

    private func systemSound(_ name: String) {
        guard let template = NSSound(named: NSSound.Name(name)),
              let copy = template.copy() as? NSSound else {
            NSSound.beep(); return
        }
        copy.volume = volume
        copy.play()
    }

    // MARK: - WAV generation

    // Produces a tiny WAV (16-bit mono PCM @ 44.1kHz) with an ADSR-ish
    // amplitude envelope so the tone sounds like a ping, not a buzz.
    private static func wavSineTone(frequency: Double, duration: Double) -> Data {
        let sampleRate: Double = 44100
        let totalSamples = Int(duration * sampleRate)
        let peak: Double = 0.35 // leaves headroom

        var samples = [Int16]()
        samples.reserveCapacity(totalSamples)
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let sample = sin(2 * .pi * frequency * t) * envelope(t: t, total: duration) * peak
            let clamped = max(-1.0, min(1.0, sample))
            samples.append(Int16(clamped * Double(Int16.max)))
        }
        return wavContainer(samples: samples, sampleRate: UInt32(sampleRate))
    }

    // Fast attack, long-ish decay: ping character.
    private static func envelope(t: Double, total: Double) -> Double {
        let attack = 0.015
        let release = total * 0.85
        if t < attack { return t / attack }
        if t > total - release {
            let remaining = total - t
            return max(0, remaining / release)
        }
        return 1
    }

    private static func wavContainer(samples: [Int16], sampleRate: UInt32) -> Data {
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate = sampleRate * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        let blockAlign = numChannels * bitsPerSample / 8
        let subchunk2Size = UInt32(samples.count * MemoryLayout<Int16>.size)
        let chunkSize = 36 + subchunk2Size

        var data = Data()
        data.append("RIFF".data(using: .ascii)!)
        data.append(chunkSize.leData)
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        data.append(UInt32(16).leData)        // PCM header size
        data.append(UInt16(1).leData)         // audioFormat = PCM
        data.append(numChannels.leData)
        data.append(sampleRate.leData)
        data.append(byteRate.leData)
        data.append(blockAlign.leData)
        data.append(bitsPerSample.leData)
        data.append("data".data(using: .ascii)!)
        data.append(subchunk2Size.leData)
        for s in samples {
            data.append(UInt16(bitPattern: s).leData)
        }
        return data
    }
}

private extension FixedWidthInteger {
    // Little-endian byte representation for WAV fields.
    var leData: Data {
        var le = self.littleEndian
        return Data(bytes: &le, count: MemoryLayout<Self>.size)
    }
}
