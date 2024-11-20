//
//  TextAnalizer.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 31-10-24.
//

// Importa el framework NaturalLanguage, que permite realizar análisis de texto y procesamiento del lenguaje natural.
import NaturalLanguage

// Importa Combine, un framework para manejar flujos de datos asíncronos y eventos reactivos en Swift.
import Combine

// Define una clase llamada TextAnalyzer que contiene métodos para analizar el sentimiento y categorizar el texto.
class TextAnalyzer {
    
    // Variable que almacena el texto a analizar.
    var text: String = ""
    
    // Publisher para el análisis de sentimiento. Emite un String representando el sentimiento del texto.
    var analyzeSentimentPublisher: some Publisher<String, Never> {
        // Llama a la función `analyzeSentiment(for:)` para realizar el análisis de sentimiento del texto.
        analyzeSentiment(for: text).eraseToAnyPublisher()
    }
   
    
    // Función privada para analizar el sentimiento de un texto dado.
    private func analyzeSentiment(for text: String) -> AnyPublisher<String, Never> {
        
        // Devuelve un Future Publisher que emitirá un resultado en el futuro.
        return Future { [weak self] promise in
            // Crea un etiquetador configurado para el esquema de análisis de sentimiento.
            let tagger = NLTagger(tagSchemes: [.sentimentScore])
            
            // Asigna el texto a analizar al etiquetador.
            tagger.string = text
            
            // Ejecuta el análisis en el hilo principal.
            DispatchQueue.main.async {
                
                // Obtiene la puntuación de sentimiento del texto en una escala de -1.0 a 1.0.
                // Usa `tag(at:unit:scheme)` para obtener el sentimiento en el nivel de párrafo.
                // Si no se encuentra un valor, devuelve "0.0" como valor por defecto.
                let sentiment = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0?.rawValue ?? "0.0"
                
                // Retorna la puntuación de sentimiento como una cadena de texto mediante `promise`.
                promise(.success(sentiment))
            }
        }
        .eraseToAnyPublisher() // Convierte el Publisher a `AnyPublisher` para ocultar los detalles de implementación.
    }
    
}
