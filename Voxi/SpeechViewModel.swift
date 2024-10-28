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

/*
 class SpeechViewModel: ObservableObject {
     @Published var currentTranscription = ""
     @Published var isAnalyzing = false
     @Published var isAuthorized = false
     
     private let speechRecognizer = SpeechRecognizer()
     private let startAnalysisSubject = PassthroughSubject<Void, Never>()
     private let stopAnalysisSubject = PassthroughSubject<Void, Never>()
     private let startAuthorizationSubject = PassthroughSubject<Void, Never>()
     private var cancellables = Set<AnyCancellable>()
     
     init() {
         //forma rapida de vincular authorizationStatus con isAuthorized y poder reaccionar a sus cambios
         //speechRecognizer.authorizationStatusPublisher.assign(to: &$isAuthorized)
         
         //forma amplia de suscribir authorizationStatus con isAuthorized y poder reaccionar a sus cambios, ademas podemos agregar codigo lo que lo hace mas flexible
         speechRecognizer.authorizationStatusPublisher.sink { [weak self] authorized in
             DispatchQueue.main.async {
                 DispatchQueue.main.async {
                     self?.isAuthorized = authorized
                 }
                 
             }
         }
         .store(in: &cancellables)
         
         speechRecognizer.speechResultPublisher.sink { [weak self] transcription in
             DispatchQueue.main.async {
                 self?.currentTranscription = transcription
             }
             
         }
         .store(in: &cancellables)
         
         speechRecognizer.speechErrorPublisher.sink {
             print("Error")
         }
         .store(in: &cancellables)
         
         startAuthorizationSubject.sink { [weak self] in
             self?.startAuthorization()
         }
         .store(in: &cancellables)
         
         startAnalysisSubject.sink { [weak self] in
             self?.startAnalysis()
         }
         .store(in: &cancellables)
         
         stopAnalysisSubject.sink { [weak self] in
             self?.stopAnalysis()
         }
         .store(in: &cancellables)
         
     }
     
     private func startAuthorization() {
         speechRecognizer.requestAuthorization()
     }
     private func startAnalysis() {
         
         guard isAuthorized else { return }
         speechRecognizer.requestStartRecognition()
         DispatchQueue.main.async {
             self.isAnalyzing = true
         }
     }
     private func stopAnalysis() {
         DispatchQueue.main.async {
             self.isAnalyzing = false
         }
         speechRecognizer.requestStopRecognition()
     }
     
     func requestStartAuthorization() {
         startAuthorizationSubject.send(())
     }
     func requestStartAnalysis() {
         startAnalysisSubject.send(())
     }
     func requestStopAnalysis() {
         stopAnalysisSubject.send(())
     }
     func saveTranscription() {
         
     }
 }

 */

final class SpeechViewModel: ObservableObject  {
    @Published var isSpeechAuthorized: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var isMicrophoneAuthorized: Bool = false
    @Published var recognizedText: String = ""
    @Published var buttonValue: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasError: Bool = false
   
    private var isAnalizing: Bool = false
    
    private var speechRecognizer = SpeechRecognizer()
    private var cancellables = Set<AnyCancellable>()
    
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
        
        $buttonValue
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                print("Event: \(value)")
                print("Llamado al boton")
                if value {
                    self?.startRecognition()
                    print("Event advance if: \(value)")
                } else {
                    if self?.isSpeechAuthorized == .authorized && self?.isMicrophoneAuthorized == true {
                        self?.stopRecognition()
                        print("Event advance else if: \(value)")
                        print("stop")
                    }
                }
            }
            .store(in: &cancellables)
        
        
    }
    
   
    func startRecognition() {
        
        switch isSpeechAuthorized {
            
        case .notDetermined:
            print("1")
            if !isMicrophoneAuthorized {
                
                speechRecognizer.authorizationSpeechPublisher
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
            } else {
                showMicrophonePermissionAlert()
            }
            
        @unknown default:
            print("4")
        }
        
        /*
         if isSpeechAuthorized == .authorized && isMicrophoneAuthorized {
                 print("1")
                 speechRecognizer.startRecognition()
                 
         } else if isSpeechAuthorized == .authorized && !isMicrophoneAuthorized {
                 print("2")
                 
                 
         } else if isSpeechAuthorized == .notDetermined && isMicrophoneAuthorized {
                 print("3")
                 
                 
             } else if isSpeechAuthorized && !isMicrophoneAuthorized {
                 print("4")
                 speechRecognizer.authorizationSpeechPublisher
                     .receive(on: DispatchQueue.main)
                     .flatMap { [weak self] isSpeechAuthorized -> AnyPublisher<SFSpeechRecognizerAuthorizationStatus, Never> in
                         guard let self = self else {
                             return Just(SFSpeechRecognizerAuthorizationStatus.notDetermined).eraseToAnyPublisher()
                         }
                         
                         
                         print("Speech authorization: \(isSpeechAuthorized)")
                         
                         if isSpeechAuthorized == .authorized {
                             self.isSpeechAuthorized = true
                             // Usamos Deferred para que el Future del micrófono espere hasta que sea necesario
                             return Deferred {
                                 self.speechRecognizer.authorizationMicrophonePublisher
                             }
                             .eraseToAnyPublisher()
                         } else {
                             return Just(false).eraseToAnyPublisher()
                         }
                     }
                     .receive(on: DispatchQueue.main)
                     .sink { [weak self] isMicrophoneAuthorized in
                         guard let self = self else {
                             return
                         }
                         self.isMicrophoneAuthorized = isMicrophoneAuthorized
                         print("Microphone authorization: \(isMicrophoneAuthorized)")
                         
                         if self.isSpeechAuthorized && self.isMicrophoneAuthorized {
                             
                             speechRecognizer.startRecognition()
                             
                         } else {
                             self.buttonValue = false
                             print("is anañizing \(buttonValue)")
                         }
                     }
                     .store(in: &cancellables)
             }

         */
        
    }
    

    func stopRecognition() {
        speechRecognizer.stopRecognition()
    }
    func saveTranscription() {
        
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
