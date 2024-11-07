//
//  SpeechRecognizer.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//


import SwiftUI
import Combine
import Speech

class SpeechRecognizer {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var accumulatedText = ""
    private var lastTranscription = ""
    
    private let recognitionTextSubject = PassthroughSubject<String, Never>()
    private let errorSubject = PassthroughSubject<String?, Never>()
    
    private var authorizationSpeechPublisher: AnyPublisher<SFSpeechRecognizerAuthorizationStatus, Never> {
        return Future { [weak self] promise in
                SFSpeechRecognizer.requestAuthorization { status in
                    DispatchQueue.main.async {
                        SFSpeechRecognizer.authorizationStatus()
                        switch status {
                        case .authorized:
                            promise(.success(.authorized))  // Permiso concedido
                            
                        case .denied:
                            promise(.success(.denied))  // Permiso denegado
                            self?.errorSubject.send("Acceso o restringido.")
                            
                        case .restricted, .notDetermined:
                            promise(.success(.restricted))  // Permiso denegado
                            self?.errorSubject.send("Acceso o restringido.")
                            
                        @unknown default:
                            promise(.success(.notDetermined))
                            self?.errorSubject.send("Estado de autorización desconocido.")
                            
                        }
                    }
                }
            }
        
        .eraseToAnyPublisher()  // Convertimos a AnyPublisher
    }
    
    private var authorizationMicrophonePublisher: AnyPublisher<AVAudioSession.RecordPermission, Never> {
        return Future { [weak self] promise in
            let audioSession = AVAudioSession.sharedInstance()
            
            DispatchQueue.main.async {
                switch audioSession.recordPermission {
                case .undetermined:
                    // Solicitar el permiso si no ha sido determinado aún
                    audioSession.requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                promise(.success(.granted))
                            } else {
                                promise(.success(.undetermined))
                                self?.errorSubject.send("Estado de autorización desconocido.")
                                
                            }
                        }
                    }
                case .denied:
                    // El permiso ha sido denegado previamente
                    promise(.success(.denied))
                    self?.errorSubject.send("Estado de autorización desconocido.")
                    
                case .granted:
                    // El permiso ya ha sido concedido
                    promise(.success(.granted))
                    
                    
                }
            }
            
            
        }
        .eraseToAnyPublisher()  // Convertimos a AnyPublisher
    }
    
    var recognitionTextPublisher: some Publisher<String, Never> {
        recognitionTextSubject.eraseToAnyPublisher()
    }
    var errorPublisher: some Publisher<String?, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    var authorizationSpeechState: some Publisher<SFSpeechRecognizerAuthorizationStatus, Never> {
        authorizationSpeechPublisher.eraseToAnyPublisher()
    }
    var authorizationMicroState: some Publisher<AVAudioSession.RecordPermission, Never> {
        authorizationMicrophonePublisher.eraseToAnyPublisher()
    }
    
    
    func startRecognition() {
        
        guard audioEngine.isRunning == false else {return}
        // Cancelamos cualquier tarea de reconocimiento en progreso
        recognitionTask?.cancel()
        recognitionTask = nil
        
        //clase responsable de gestionar la configuración y el comportamiento de la sesión de audio de tu aplicación
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Configuramos la sesión de audio para grabación, modo de medición y con la opción de reducir el volumen de otros sonidos
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            // Activamos la sesión de audio
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // Si ocurre un error al activar la sesión de audio, lo capturamos y publicamos a través del errorSubject
            errorSubject.send("No se pudo activar la sesión de audio.")
            return
        }
        
        // Creamos la solicitud de reconocimiento de audio en búfer
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            // Si ocurre un error al crear la solicitud de reconocimiento de audio en búfer, lo capturamos y publicamos a través del errorSubject
            errorSubject.send("No se pudo crear la solicitud de reconocimiento.")
            return
        }
        
        // Obtenemos el nodo de entrada de audio del motor de audio
        let inputNode = audioEngine.inputNode
        // Configuramos la solicitud para que informe los resultados parciales
        recognitionRequest.shouldReportPartialResults = true
        
        
        
        // Creamos la tarea de reconocimiento, pasando la solicitud y un manejador de resultados
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] result, error in
            
            guard let self = self else { return }
            
            
                    if let result = result {
                    

                       
                        let actualTranscription = result.bestTranscription.formattedString.lowercased()
                         
                            print("lastTranscription: \(lastTranscription).")
                            print("actualTranscription: \(actualTranscription).")
                            
                        if lastTranscription.split(separator: " ").count != actualTranscription.split(separator: " ").count {
                                
                                    self.accumulatedText += getNewText(fullText: actualTranscription, previousText: lastTranscription) + " "
                                    self.lastTranscription = actualTranscription
                                    self.recognitionTextSubject.send(self.accumulatedText)
                                
                        } else if (lastTranscription.split(separator: " ").count == actualTranscription.split(separator: " ").count) && (lastTranscription != actualTranscription) {
                            
                            if let lastWordTranscription = actualTranscription.split(separator: " ").last,
                               let lastWordAccumulated = accumulatedText.split(separator: " ").last {
                                
                                accumulatedText = self.accumulatedText.replacingOccurrences(of: lastWordAccumulated.description, with: lastWordTranscription.description)
                                self.lastTranscription = actualTranscription
                                self.recognitionTextSubject.send(self.accumulatedText)
                            }
                        } else if lastTranscription == actualTranscription {
                                
                                    self.lastTranscription = ""
                        }
                        
                        
                        
                    }
            
            
            
            
            
            
            if let error = error {
                self.errorSubject.send("Error durante el reconocimiento: \(error.localizedDescription)")
            }
        })
        
        // Configuramos el formato de grabación de audio para el nodo de entrada
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        // Instalamos un tap (escucha) en el bus 0 para capturar el audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        
        // Preparamos el motor de audio para la grabación
        audioEngine.prepare()
        do {
            // Iniciamos el motor de audio para empezar a capturar el audio
            try audioEngine.start()
        } catch {
            // Si ocurre un error al iniciar el motor de audio, lo publicamos a través del publisher
            self.errorSubject.send("No se pudo iniciar el motor de audio.")
        }
    }
    
    func stopRecognition() {
        lastTranscription = ""
        accumulatedText = ""
        // Detenemos el motor de audio
        audioEngine.stop()
        // Finalizamos el flujo de audio de la solicitud de reconocimiento
        recognitionRequest?.endAudio()
        // Cancelamos la tarea de reconocimiento activa
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        // Desactivamos la sesión de audio
        //clase responsable de gestionar la configuración y el comportamiento de la sesión de audio de tu aplicación
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Desactivamos la sesión de audio
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            errorSubject.send("No se pudo desactivar la sesión de audio.")
        }
    }
    // Helper function to find new text
    func getNewText(fullText: String, previousText: String) -> String {
        // Split both strings into words
        let fullWords = fullText.split(separator: " ")
        let previousWords = previousText.split(separator: " ")
        
        // Verificar que el índice esté dentro de los límites
        let startIndex = min(previousWords.count, fullWords.count)
        let newWords = fullWords.suffix(from: startIndex)
        print("execute ")
        // Join new words into a single string with spaces
        return newWords.joined(separator: " ").lowercased()
    }
    
}