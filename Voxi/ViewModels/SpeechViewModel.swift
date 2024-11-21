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
    @Published var navigationLinkDisable: Bool = false
    
    @Published var sentimenText: String = ""
    
    @Published var addedCategories: [String] = []
    // Lista de categorías personalizadas para clasificar las transcripciones.
    let customCategories: [String] = ["Trabajo", "Personal", "Salud", "Finanzas", "Educación", "Sin categoría"]
    @Published var totalCategories: [String] = []

    // Array que almacena las transcripciones con su texto, análisis de sentimiento y categorías asociadas.
    @Published var transcriptions: [TranscriptionEntity] = []
    
    
    private var speechRecognizer = SpeechRecognizer()
    private var textAnalizer = TextAnalyzer()
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
        totalCategories = customCategories + addedCategories
        print(totalCategories)
    }
        
    
    
    func buttonTapped() {
        stateButton = stateButton ? false : true
    }
    
    func saveTranscription() {
        
        if !recognizedText.isEmpty {
            textAnalizer.text = recognizedText
            
            
            // Analiza el sentimiento del texto de la transcripción.
            textAnalizer.analyzeSentimentPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] sentiment in
                    guard let self = self else {
                        return
                    }
                    
                        print(sentiment)
                        if sentiment != "0.0" {
                            self.sentimenText = sentiment
                        } else {
                            self.sentimenText = "Sin determinar"
                        }
                    categorizeText(recognizedText, categories: totalCategories, completion: { category in
                        print(category)
                        print(self.recognizedText)
                        print("sentiment \(self.sentimenText)")
                        // Almacena la transcripción con su sentimiento y categorías.
                        self.transcriptions.append(TranscriptionEntity(text: self.recognizedText, sentiment: self.sentimenText, category: category))
                        // Limpia la transcripción actual después de guardarla.
                        self.recognizedText = ""
                        self.sentimenText = ""
                    })
                    
                }
                .store(in: &cancellables)
            
            
            
            
            
            
            
            
        }
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
                            
                            // Devuelve el estado de autorización del speech para continuar la cadena de publishers
                            return Just(isSpeechStatus).eraseToAnyPublisher()
                        } else {
                            
                            return Just(isSpeechStatus).eraseToAnyPublisher() // Devuelve directamente el estado de autorización del speech
                        }
                    }
                    .flatMap { [weak self] speechStatus -> AnyPublisher<AVAudioSession.RecordPermission, Never> in
                        guard let self = self else {
                            return Just(.undetermined).eraseToAnyPublisher()
                        }
                        
                        // Si speech está autorizado, solicitamos el permiso del micrófono
                        if speechStatus == .authorized {
                            
                            return self.speechRecognizer.authorizationMicroState
                                .eraseToAnyPublisher()
                        } else {
                            
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
                                navigationLinkDisable = true
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
                navigationLinkDisable = true
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
            navigationLinkDisable = false
            placeholderText = ""
            if !recognizedText.isEmpty {
                buttonViewState = .isButtonsSaveDeleteAppear
            } else {
                buttonViewState = .isButtonsSaveDeleteDisappier
            }
        }
    }
    
    private func categorizeText(_ text: String, categories: [String], completion: @escaping (String) -> Void)  {
            var textCategory = ""
            // Recorre cada categoría personalizada.
        DispatchQueue.main.async {
            for category in categories {
                // Si el texto contiene la categoría (ignorando mayúsculas y minúsculas), la añade a las categorías coincidentes.
                if text.lowercased().contains(category.lowercased()) {
                    
                        textCategory = category
                        
                        print("ok")
                   
                   
                }
            }
                    
        if textCategory != "" {
            completion(textCategory)
        }else {
            completion("Sin categoría")
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
    
    func deleteTranscription(at offsets: IndexSet) {
        
        // Recorre los índices proporcionados para eliminar las transcripciones correspondientes.
        offsets.forEach { index in
            // Busca la posición de la transcripción en la lista general de `transcriptions` usando su texto.
            if let transcriptionIndex = transcriptions.firstIndex(where: { $0.text == transcriptions[index].text }) {
                // Elimina la transcripción de `speechViewModel.transcriptions`.
                transcriptions.remove(at: transcriptionIndex)
            }
        }
    }
}
