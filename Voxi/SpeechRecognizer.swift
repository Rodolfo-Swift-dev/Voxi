//
//  SpeechRecognizer.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//

import Speech
import Combine

class SpeechRecognizer {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    let authorizationStatus = PassthroughSubject<Bool, Never>()
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.authorizationStatus.send(true)
                case .denied, .restricted, .notDetermined:
                    self.authorizationStatus.send(false)
                @unknown default:
                    fatalError("Unknown authorization status")
                }
            }
        }
    }
}
