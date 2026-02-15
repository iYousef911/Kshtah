//
//  VoiceNoteManager.swift
//  Kashat
//
//  Created by AI Assistant on 15/02/2026.
//

import Foundation
import AVFoundation
import Speech
internal import Combine

class VoiceNoteManager: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    @Published var isRecording = false
    @Published var isPlaying = false
    
    // Path to the temp recording file
    var recordingURL: URL?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording() {
        let fileName = UUID().uuidString + ".m4a"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        recordingURL = path
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: path, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            print("🎙️ Started Recording")
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording(completion: @escaping (URL?, Double) -> Void) {
        let duration = audioRecorder?.currentTime ?? 0
        audioRecorder?.stop()
        isRecording = false
        print("🛑 Stopped Recording, duration: \(duration)")
        
        if let url = recordingURL {
            completion(url, duration)
        } else {
            completion(nil, 0)
        }
        audioRecorder = nil
    }
    
    func playAudio(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            print("▶️ Playing Audio")
        } catch {
            print("Could not play audio: \(error)")
            // Try downloading if it's a remote URL (Not handled here directly, expected local or handled by view)
        }
    }
    
    // Play remote URL
    func playRemoteAudio(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // Simple download and play
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                do {
                    self?.audioPlayer = try AVAudioPlayer(data: data)
                    self?.audioPlayer?.delegate = self
                    self?.audioPlayer?.prepareToPlay()
                    self?.audioPlayer?.play()
                    self?.isPlaying = true
                } catch {
                    print("Remote playback error: \(error)")
                }
            }
        }.resume()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
    
    // MARK: - AI Transcription
    func transcribeAudio(url: URL, completion: @escaping (String?) -> Void) {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA")) // Arabic Saudi
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            print("Speech recognizer not available")
            completion(nil)
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                print("Transcription error: \(error)")
                completion(nil)
                return
            }
            
            if let result = result, result.isFinal {
                print("📝 Transcription: \(result.bestTranscription.formattedString)")
                completion(result.bestTranscription.formattedString)
            }
        }
    }
}
