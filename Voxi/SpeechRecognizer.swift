//
//  SpeechRecognizer.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//

import Speech
import SwiftUI
import Combine

class SpeechRecognizer {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    private let startAuthorizationSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    let authorizationStatus = PassthroughSubject<Bool, Never>()
    
    init() {
        startAuthorizationSubject.sink { [weak self] in
            self?.startRequestAuthorization()
        }
        .store(in: &cancellables)
    }
    
    private func startRequestAuthorization() {
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
    func requestAuthorization() {
        startAuthorizationSubject.send(())
    }
}
