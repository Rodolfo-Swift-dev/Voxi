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
    @Published var isMicrophoneAuthorized: AVAudioSession.RecordPermission = .undetermined
    @Published var errorMessage: String? = nil
    @Published var hasError: Bool = false
    
    @Published var recognizedText: String = ""
    @Published var buttonViewState: ViewState = .isButtonsSaveDeleteDisappier
    
    //UI
    @Published var placeholderText: String = ""
    @Published var buttonText: String = "Iniciar análisis"
    @Published var buttonColor: Color = .green
    @Published var buttonImageName: String = "mic.fill"
    @Published var navigationLinkOpacity: Double = 1
    
    @Published var sentimenText: String = ""
    
    @Published var categories: [String] = []
    // Lista de categorías personalizadas para clasificar las transcripciones.
    let customCategories: [String] = ["Trabajo", "Personal", "Salud", "Finanzas", "Educación"]
    @Published var totalCategories: [String] = []

    // Array que almacena las transcripciones con su texto, análisis de sentimiento y categorías asociadas.
    @Published var transcriptions: [(text: String, sentiment: String, categories: [String])] = []
    
    
    
    
    private var speechRecognizer = SpeechRecognizer()
    private var textAnalizer = TextAnalyzer()
    private var cancellables = Set<AnyCancellable>()
    
    private var stateButton: Bool = false {
        didSet {
            print(stateButton.description)
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
        totalCategories = customCategories + categories
    }
        
    func saveTranscription() {
        
        if !recognizedText.isEmpty {
            textAnalizer.text = recognizedText
            textAnalizer.categories = totalCategories
            
            // Analiza el sentimiento del texto de la transcripción.
            textAnalizer.analyzeSentimentPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] sentiment in
                    guard let self = self else {
                        return
                    }
                    self.sentimenText = sentiment
                    
                }
                .store(in: &cancellables)
            
            // Categoriza el texto utilizando las categorías personalizadas.
            textAnalizer.categorizeTextPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] categorie in
                    guard let self = self else {
                        return
                    }
                   
                    
                }
                .store(in: &cancellables)
            
            // Almacena la transcripción con su sentimiento y categorías.
            transcriptions.append((text: recognizedText, sentiment: sentimenText, categories: categories))
            // Limpia la transcripción actual después de guardarla.
            recognizedText = ""
        }
    }
    
    func buttonTapped() {
        stateButton = stateButton ? false : true
    }
    
    private func bindToSpeechRecognizer() {
        
        
        
        speechRecognizer.recognitionTextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                
                guard let self = self else {
                    return
                }
                placeholderText = ""
                recognizedText = text
                
                
                
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
    
    private func updateRunningState() {
        
        switch isSpeechAuthorized {
            
        case .notDetermined:
            
            if isMicrophoneAuthorized != .granted {
                
                speechRecognizer.authorizationSpeechState
                    .receive(on: DispatchQueue.main)
                    .flatMap { [weak self] isSpeechStatus -> AnyPublisher<SFSpeechRecognizerAuthorizationStatus, Never> in
                        guard let self = self else {
                            
                            return Just(.notDetermined).eraseToAnyPublisher() // Si no existe el self, devuelves un valor por defecto
                           
                        }

                        // Asignamos el valor de la autorización de Speech
                        self.isSpeechAuthorized = isSpeechStatus
                        
                        if isSpeechStatus == .authorized {
                            print("authorized")
                            // Devuelve el estado de autorización del speech para continuar la cadena de publishers
                            return Just(isSpeechStatus).eraseToAnyPublisher()
                        } else {
                            print("Not authorized")
                            return Just(isSpeechStatus).eraseToAnyPublisher() // Devuelve directamente el estado de autorización del speech
                        }
                    }
                    .flatMap { [weak self] speechStatus -> AnyPublisher<AVAudioSession.RecordPermission, Never> in
                        guard let self = self else {
                            return Just(.undetermined).eraseToAnyPublisher()
                        }
                        
                        // Si speech está autorizado, solicitamos el permiso del micrófono
                        if speechStatus == .authorized {
                            print("debe estar autorizado")
                            return self.speechRecognizer.authorizationMicroState
                                .eraseToAnyPublisher()
                        } else {
                            print("no debe estar autorizado")
                            return Just(AVAudioSession.RecordPermission.undetermined).eraseToAnyPublisher()
                        }
                    }
                    .sink { [weak self] isMicrophoneStatus in
                        guard let self = self else { return }
                        if isSpeechAuthorized == .authorized {
                            // Guardamos el valor del micrófono como booleano
                            self.isMicrophoneAuthorized = isMicrophoneStatus
                            if self.isMicrophoneAuthorized == .granted {
                                
                                speechRecognizer.startRecognition()
                                buttonText = "Detener analisis"
                                buttonColor = .red
                                buttonImageName = "stop.fill"
                                navigationLinkOpacity = 0
                                placeholderText = "Escuchando"
                                buttonViewState = .isButtonsSaveDeleteDisappier
                                
                            } else {
                                
                                showPermissionAlert(title: "Permiso de micrófono requerido", message: "Por favor, habilita el permiso en Ajustes para usar el micrófono.")
                                
                            }
                        } else {
                            
                            showPermissionAlert(title: "Permiso de reconocimiento de voz requerido", message: "Por favor, habilita el permiso en Ajustes para usar reconocimiento de voz.")
                        }
                    }
                    .store(in: &cancellables)
            }
            
        case .denied:
            
            
            showPermissionAlert(title: "Permiso de reconocimiento de voz requerido", message: "Por favor, habilita el permiso en Ajustes para usar reconocimiento de voz.")
            
        case .restricted:
            print("restricted")
            
        case .authorized:
            if isMicrophoneAuthorized == .granted {
                
                speechRecognizer.startRecognition()
                buttonText = "Detener analisis"
                buttonColor = .red
                buttonImageName = "stop.fill"
                navigationLinkOpacity = 0
                placeholderText = "Escuchando"
                buttonViewState = .isButtonsSaveDeleteDisappier
                
            } else {
                showPermissionAlert(title: "Permiso de micrófono requerido", message: "Por favor, habilita el permiso en Ajustes para usar el micrófono.")
            }
            
        @unknown default:
            print("unknown")
        }
    }
    private func updateToNotRunningState() {
        if isSpeechAuthorized == .authorized && isMicrophoneAuthorized == .granted {
            speechRecognizer.stopRecognition()
            
            buttonText = "Iniciar análisis"
            buttonColor = .green
            buttonImageName = "mic.fill"
            navigationLinkOpacity = 1
            placeholderText = ""
            if !recognizedText.isEmpty {
                buttonViewState = .isButtonsSaveDeleteAppear
            } else {
                buttonViewState = .isButtonsSaveDeleteDisappier
            }
        }
    }
    
    
    private func showPermissionAlert(title: String, message: String) {
        // Mostrar una alerta para que el usuario vaya a Ajustes
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: { _ in
            self.stateButton = false
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
