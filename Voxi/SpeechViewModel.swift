//
//  SpeechViewModel.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//

import Foundation
import Combine
import SwiftUI
import Speech

final class SpeechViewModel: ObservableObject  {
    //publishers
    @Published var isSpeechAuthorized: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var isMicrophoneAuthorized: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasError: Bool = false
    
    //UI
    @Published var recognizedText: String = ""
    @Published var buttonText: String = "Iniciar análisis"
    @Published var buttonColor: Color = .green
    @Published var buttonImageName: String = "mic.fill"
    @Published var navigationLinkOpacity: Double = 1
    @Published var buttonValue: Bool = false
    
    
private var speechRecognizer = SpeechRecognizer()
    private var cancellables = Set<AnyCancellable>()
    
    private var stateButton: Bool = false {
        didSet {
            switch stateButton {
                
            case true:
                updateRunningState()
            case false:
                updateToNotRunningState()
            }
        }
    }
    
    init() {
        
        bindToSpeechRecognizer()
    }
        
    
    private func bindToSpeechRecognizer() {
        
        speechRecognizer.recognitionTextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.recognizedText = text
            }
            .store(in: &cancellables)
        
        speechRecognizer.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.errorMessage = error
                    self?.hasError = true
                } else {
                    self?.hasError = false
                }
            }
            .store(in: &cancellables)
        
        
        
    }
    
    func saveTranscription() {
        
    }
    func buttonTapped() {
        stateButton = stateButton ? false : true
    }
    
    private func updateRunningState() {
        
        switch isSpeechAuthorized {
            
        case .notDetermined:
            print("1")
            if !isMicrophoneAuthorized {
                
                speechRecognizer.authorizationState
                    .receive(on: DispatchQueue.main)
                    .flatMap { [weak self] isSpeechAuthorized -> AnyPublisher<SFSpeechRecognizerAuthorizationStatus, Never> in
                        guard let self = self else {
                            print("aqui")
                            return Just(.notDetermined).eraseToAnyPublisher() // Si no existe el self, devuelves un valor por defecto
                           
                        }

                        // Asignamos el valor de la autorización de Speech
                        self.isSpeechAuthorized = isSpeechAuthorized
                        
                        print("Speech authorization: \(isSpeechAuthorized)")

                        if isSpeechAuthorized == .authorized {
                            // Devuelve el estado de autorización del speech para continuar la cadena de publishers
                            return Just(isSpeechAuthorized).eraseToAnyPublisher()
                        } else {
                            print("aqui siiiiii")
                            return Just(isSpeechAuthorized).eraseToAnyPublisher() // Devuelve directamente el estado de autorización del speech
                        }
                    }
                    .flatMap { [weak self] speechStatus -> AnyPublisher<Bool, Never> in
                        guard let self = self else {
                            return Just(false).eraseToAnyPublisher()
                        }
                        
                        // Si speech está autorizado, solicitamos el permiso del micrófono
                        if speechStatus == .authorized {
                            return self.speechRecognizer.authorizationMicrophonePublisher
                                .eraseToAnyPublisher()
                        } else {
                            return Just(false).eraseToAnyPublisher()
                        }
                    }
                    .sink { [weak self] isMicrophoneAuthorized in
                        guard let self = self else { return }
                        // Guardamos el valor del micrófono como booleano
                        self.isMicrophoneAuthorized = isMicrophoneAuthorized
                        print("Microphone authorization: \(isMicrophoneAuthorized)")
                        if self.isSpeechAuthorized == .authorized && self.isMicrophoneAuthorized {
                            
                            speechRecognizer.startRecognition()
                            buttonText = "Detener analisis"
                            buttonColor = .red
                            buttonImageName = "stop.fill"
                            navigationLinkOpacity = 0
                            
                        } else {
                            self.buttonValue = false
                            showMicrophonePermissionAlert()
                            print("is anañizing \(buttonValue)")
                        }
                    }
                    .store(in: &cancellables)
            }
            
        case .denied:
            print("2")
            showSpeechPermissionAlert()
            
        case .restricted:
            print("3")
            
        case .authorized:
            if isMicrophoneAuthorized {
                print("4")
                speechRecognizer.startRecognition()
                buttonText = "Detener analisis"
                buttonColor = .red
                buttonImageName = "stop.fill"
                navigationLinkOpacity = 0
            } else {
                showMicrophonePermissionAlert()
            }
            
        @unknown default:
            print("4")
        }
    }
    private func updateToNotRunningState() {
        if isSpeechAuthorized == .authorized && isMicrophoneAuthorized == true {
            speechRecognizer.stopRecognition()
            buttonText = "Iniciar análisis"
            buttonColor = .green
            buttonImageName = "mic.fill"
            navigationLinkOpacity = 1
        }
    }
    
    
    
    func showSpeechPermissionAlert() {
        // Mostrar una alerta para que el usuario vaya a Ajustes
        let alert = UIAlertController(title: "Permiso de reconocimiento de voz requerido",
                                      message: "Por favor, habilita el permiso en Ajustes para usar reconocimiento de voz.",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: { _ in
            self.buttonValue = false
        }))
        
        alert.addAction(UIAlertAction(title: "Ajustes", style: .default, handler: { _ in
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings)
                }
            }
        }))
        
        // Presenta la alerta al usuario
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    func showMicrophonePermissionAlert() {
        // Mostrar una alerta para que el usuario vaya a Ajustes
        let alert = UIAlertController(title: "Permiso de micrófono requerido",
                                      message: "Por favor, habilita el permiso en Ajustes para usar el micrófono.",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: {_ in
            self.buttonValue = false
        }))
        
        alert.addAction(UIAlertAction(title: "Ajustes", style: .default, handler: { _ in
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings)
                }
            }
        }))
        
        // Presenta la alerta al usuario
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}
