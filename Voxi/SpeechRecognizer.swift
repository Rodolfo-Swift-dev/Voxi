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
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let startAuthorizationSubject = PassthroughSubject<Void, Never>()
    let authorizationStatusPublisher = PassthroughSubject<Bool, Never>()
    
    private let startRecognitionSubject = PassthroughSubject<Void, Never>()
    let speechResultPublisher = PassthroughSubject<String, Never>()
    let speechErrorPublisher = PassthroughSubject<Void, Never>()
    
    private let stoptRecognitionSubject = PassthroughSubject<Void, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        startAuthorizationSubject.sink { [weak self] in
            self?.startRequestAuthorization()
        }
        .store(in: &cancellables)
        
        startRecognitionSubject.sink { [weak self] in
            self?.startRecognition()
        }
        .store(in: &cancellables)
        
        stoptRecognitionSubject.sink { [weak self] in
            self?.stoptRecognition()
        }
        .store(in: &cancellables)
    }
    
    private func startRequestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.authorizationStatusPublisher.send(true)
                case .denied, .restricted, .notDetermined:
                    self.authorizationStatusPublisher.send(false)
                @unknown default:
                    fatalError("Unknown authorization status")
                }
            }
        }
    }
    private func startRecognition() {
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
            // Si ocurre un error al activar la sesión de audio, lo publicamos a través del speechErrorPublisher
            speechErrorPublisher.send(())
            return
        }
        
        // Creamos la solicitud de reconocimiento de audio en búfer
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            // Si no se puede crear la solicitud, terminamos el proceso con un fatalError
            fatalError("No se pudo crear la solicitud de reconocimiento.")
        }
        
        // Obtenemos el nodo de entrada de audio del motor de audio
        let inputNode = audioEngine.inputNode
        // Configuramos la solicitud para que informe los resultados parciales
        recognitionRequest.shouldReportPartialResults
        // Creamos la tarea de reconocimiento, pasando la solicitud y un manejador de resultados
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { result, error in
            // Si obtenemos un resultado, publicamos la transcripción parcial o completa a través del speechResultPublisher
            if let result = result {
                DispatchQueue.main.async {
                    // Publicamos la mejor transcripción obtenida (formattedString) al subscriber del publisher speechResultPublisher
                    // Esto asegura que cualquier suscriptor reciba el texto reconocido
                    self.speechResultPublisher.send(result.bestTranscription.formattedString)
                }
            }
            // Si hay un error o el resultado es final, detenemos el motor de audio y limpiamos las solicitudes y tareas
            if error != nil || result?.isFinal == true {
                // Detenemos el motor de audio, lo cual también detiene la captación del micrófono
                self.audioEngine.stop()
                // Eliminamos el tap instalado en el inputNode del motor de audio para dejar de recibir audio
                inputNode.removeTap(onBus: 0)
                // Limpiamos la solicitud de reconocimiento, ya que no es necesaria después de detenerse
                self.recognitionRequest = nil
                // Cancelamos la tarea de reconocimiento y la dejamos en nil para evitar posibles fugas de memoria
                self.recognitionTask = nil
            }
        })
        
        // Configuramos el formato de grabación de audio para el nodo de entrada
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        // Instalamos un tap (escucha) en el bus 0 para capturar el audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            // Agregamos los datos del buffer de audio a la solicitud de reconocimiento
            self.recognitionRequest?.append(buffer)
        }
        
        // Preparamos el motor de audio para la grabación
        audioEngine.prepare()
        
        do {
            // Iniciamos el motor de audio para empezar a capturar el audio
            try audioEngine.start()
        } catch {
            // Si ocurre un error al iniciar el motor de audio, lo publicamos a través del speechErrorPublisher
            self.speechErrorPublisher.send(())
        }
    }
    
    private func stoptRecognition() {
        print("stop")
    }
    
    func requestAuthorization() {
        startAuthorizationSubject.send(())
    }
    func requestStartRecognition() {
        startRecognitionSubject.send(())
    }
    func requestStopRecognition() {
        stoptRecognitionSubject.send(())
    }
}
