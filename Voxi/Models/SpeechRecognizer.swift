//
//  SpeechRecognizer.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//


// Importa el framework SwiftUI, que puede ser útil si se desea integrar este reconocimiento en una interfaz de usuario.
import SwiftUI

// Importa Combine para trabajar con flujos de datos y suscripciones de eventos reactivos en Swift.
import Combine

// Importa Speech para acceder a las funcionalidades de reconocimiento de voz.
import Speech

// Define una clase llamada SpeechRecognizer para gestionar el reconocimiento de voz.
class SpeechRecognizer {
    
    // Inicializa un objeto SFSpeechRecognizer configurado para el idioma español (es-ES).
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    
    // Crea un motor de audio (AVAudioEngine) para capturar el audio del micrófono en tiempo real.
    private let audioEngine = AVAudioEngine()
    
    // Declara una solicitud de reconocimiento de audio en búfer (SFSpeechAudioBufferRecognitionRequest) para manejar el audio que se analizará.
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    // Declara una tarea de reconocimiento (SFSpeechRecognitionTask) que realiza la transcripción del audio.
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Variable que acumula el texto transcrito hasta el momento.
    private var accumulatedText = ""
    
    // Variable que guarda la última transcripción parcial recibida.
    private var lastTranscription = ""
    
    // Declara un Publisher que emite el texto transcrito y permite actualizar la interfaz en tiempo real.
    private let recognitionTextSubject = PassthroughSubject<String, Never>()
    
    // Declara un Publisher que emite mensajes de error.
    private let errorSubject = PassthroughSubject<String?, Never>()
    
    // Publisher que maneja la autorización para el reconocimiento de voz.
    private var authorizationSpeechPublisher: AnyPublisher<SFSpeechRecognizerAuthorizationStatus, Never> {
        // Devuelve un Future Publisher que emite el estado de autorización.
        return Future { [weak self] promise in
            // Solicita autorización para el reconocimiento de voz al usuario.
            SFSpeechRecognizer.requestAuthorization { status in
                // Ejecuta el manejo de la respuesta en el hilo principal.
                DispatchQueue.main.async {
                    // Revisa el estado de autorización recibido.
                    switch status {
                    case .authorized:
                        // Permiso concedido para el reconocimiento de voz.
                        promise(.success(.authorized))
                    case .denied:
                        // Permiso denegado, se emite un mensaje de error.
                        promise(.success(.denied))
                        self?.errorSubject.send("Acceso denegado.")
                    case .restricted, .notDetermined:
                        // Acceso restringido o no determinado, se emite un mensaje de error.
                        promise(.success(.restricted))
                        self?.errorSubject.send("Acceso restringido o no determinado.")
                    @unknown default:
                        // Estado desconocido de autorización.
                        promise(.success(.notDetermined))
                        self?.errorSubject.send("Estado de autorización desconocido.")
                    }
                }
            }
        }
        .eraseToAnyPublisher() // Convierte el Publisher a AnyPublisher.
    }
    
    // Publisher que maneja la autorización para el micrófono.
    private var authorizationMicrophonePublisher: AnyPublisher<AVAudioSession.RecordPermission, Never> {
        // Devuelve un Future Publisher que emite el estado de permiso del micrófono.
        return Future { [weak self] promise in
            // Obtiene la instancia de la sesión de audio.
            let audioSession = AVAudioSession.sharedInstance()
            
            // Ejecuta el manejo de permiso en el hilo principal.
            DispatchQueue.main.async {
                switch audioSession.recordPermission {
                case .undetermined:
                    // Solicita el permiso si aún no ha sido determinado.
                    audioSession.requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                // Permiso concedido.
                                promise(.success(.granted))
                            } else {
                                // Permiso no determinado, se emite un mensaje de error.
                                promise(.success(.undetermined))
                                self?.errorSubject.send("Permiso no determinado.")
                            }
                        }
                    }
                case .denied:
                    // El permiso ha sido denegado, se emite un mensaje de error.
                    promise(.success(.denied))
                    self?.errorSubject.send("Permiso denegado.")
                case .granted:
                    // El permiso ya ha sido concedido previamente.
                    promise(.success(.granted))
                }
            }
        }
        .eraseToAnyPublisher() // Convierte el Publisher a AnyPublisher.
    }
    
    // Publisher que expone el texto transcrito.
    var recognitionTextPublisher: some Publisher<String, Never> {
        recognitionTextSubject.eraseToAnyPublisher()
    }
    
    // Publisher que expone los mensajes de error.
    var errorPublisher: some Publisher<String?, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // Publisher que expone el estado de autorización para el reconocimiento de voz.
    var authorizationSpeechState: some Publisher<SFSpeechRecognizerAuthorizationStatus, Never> {
        authorizationSpeechPublisher.eraseToAnyPublisher()
    }
    
    // Publisher que expone el estado de autorización para el micrófono.
    var authorizationMicroState: some Publisher<AVAudioSession.RecordPermission, Never> {
        authorizationMicrophonePublisher.eraseToAnyPublisher()
    }
    
    // Función para comenzar el reconocimiento de voz.
    func startRecognition() {
        
        // Verifica que el motor de audio no esté en ejecución para evitar duplicados.
        guard audioEngine.isRunning == false else { return }
        
        // Cancela cualquier tarea de reconocimiento en progreso.
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Obtiene la instancia de la sesión de audio.
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Configura la sesión de audio para grabación, medición y con opción de reducir otros sonidos.
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            // Activa la sesión de audio.
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // En caso de error, envía un mensaje a través del Publisher de error.
            errorSubject.send("No se pudo activar la sesión de audio.")
            return
        }
        
        // Crea una solicitud de reconocimiento de audio en búfer.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Verifica que la solicitud de reconocimiento se haya creado correctamente.
        guard let recognitionRequest = recognitionRequest else {
            errorSubject.send("No se pudo crear la solicitud de reconocimiento.")
            return
        }
        
        // Obtiene el nodo de entrada de audio del motor de audio.
        let inputNode = audioEngine.inputNode
        
        // Configura la solicitud para que informe resultados parciales.
        recognitionRequest.shouldReportPartialResults = true
        
        // Crea la tarea de reconocimiento y define cómo manejar los resultados.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                // Obtiene la transcripción actual en minúsculas.
                let actualTranscription = result.bestTranscription.formattedString.lowercased()
                
                // Verifica si el número de palabras ha cambiado para evitar duplicados.
                if self.lastTranscription.split(separator: " ").count != actualTranscription.split(separator: " ").count {
                    self.accumulatedText += self.getNewText(fullText: actualTranscription, previousText: self.lastTranscription) + " "
                    self.lastTranscription = actualTranscription
                    self.recognitionTextSubject.send(self.accumulatedText)
                } else if (self.lastTranscription.split(separator: " ").count == actualTranscription.split(separator: " ").count) && (self.lastTranscription != actualTranscription) {
                    // Reemplaza la última palabra si se detecta un cambio.
                    if let lastWordTranscription = actualTranscription.split(separator: " ").last,
                       let lastWordAccumulated = self.accumulatedText.split(separator: " ").last {
                        self.accumulatedText = self.accumulatedText.replacingOccurrences(of: lastWordAccumulated.description, with: lastWordTranscription.description)
                        self.lastTranscription = actualTranscription
                        self.recognitionTextSubject.send(self.accumulatedText)
                    }
                } else if self.lastTranscription == actualTranscription {
                    // Resetea la última transcripción si no hay cambios.
                    self.lastTranscription = ""
                }
            }
            
            // Si ocurre un error, envía un mensaje al Publisher de error.
            if let error = error {
                self.errorSubject.send("Error durante el reconocimiento: \(error.localizedDescription)")
            }
        })
        
        // Configura el formato de grabación de audio para el nodo de entrada.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Instala un tap en el bus 0 para capturar el audio en el formato especificado.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Prepara el motor de audio para grabación.
        audioEngine.prepare()
        
        do {
            // Inicia el motor de audio para comenzar a capturar el audio.
            try audioEngine.start()
        } catch {
            // En caso de error, envía un mensaje al Publisher de error.
            self.errorSubject.send("No se pudo iniciar el motor de audio.")
        }
    }
    
    // Función para detener el reconocimiento de voz y limpiar las configuraciones.
    func stopRecognition() {
        // Resetea la última transcripción y el texto acumulado.
        lastTranscription = ""
        accumulatedText = ""
        
        // Detiene el motor de audio.
        audioEngine.stop()
        
        // Finaliza el flujo de audio de la solicitud de reconocimiento.
        recognitionRequest?.endAudio()
        
        // Cancela cualquier tarea de reconocimiento activa.
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Elimina el tap del nodo de entrada de audio.
        audioEngine.inputNode.removeTap(onBus: 0)
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Desactiva la sesión de audio.
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // En caso de error, envía un mensaje al Publisher de error.
            errorSubject.send("No se pudo desactivar la sesión de audio.")
        }
    }
    
    // Función auxiliar para encontrar el texto nuevo comparando con el texto previo.
    func getNewText(fullText: String, previousText: String) -> String {
        // Divide ambos textos en palabras.
        let fullWords = fullText.split(separator: " ")
        let previousWords = previousText.split(separator: " ")
        
        // Obtiene el índice de inicio basado en el menor tamaño entre ambos.
        let startIndex = min(previousWords.count, fullWords.count)
        
        // Obtiene solo las palabras nuevas desde el índice calculado.
        let newWords = fullWords.suffix(from: startIndex)
        
        // Combina las palabras nuevas en un solo string con espacios y en minúsculas.
        return newWords.joined(separator: " ").lowercased()
    }
}
