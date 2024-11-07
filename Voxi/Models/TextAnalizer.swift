//
//  TextAnalizer.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 31-10-24.
//

import NaturalLanguage // Importa el framework NaturalLanguage para el análisis de texto.
import Combine

class TextAnalyzer {
    
    var text: String = ""
    var categories: [String] = []
    
    var analyzeSentimentPublisher: some Publisher<String, Never> {
        analyzeSentiment(for: text).eraseToAnyPublisher()
    }
    var categorizeTextPublisher: some Publisher<[String], Never> {
        categorizeText(text, customCategories: categories)
    }
    
    // Función para analizar el sentimiento de un texto dado.
    private func analyzeSentiment(for text: String) -> AnyPublisher<String, Never> {
        
        return Future { [weak self] promise in
            // Crea un etiquetador de lenguaje configurado para el esquema de análisis de sentimiento.
            let tagger = NLTagger(tagSchemes: [.sentimentScore])
            
            // Asigna el texto a analizar al etiquetador.
            tagger.string = text
            
            DispatchQueue.main.async {
                
                // Obtiene la puntuación del sentimiento del texto en una escala de -1.0 a 1.0.
                // `tag(at:unit:scheme)` devuelve un resultado opcional, por lo que se utiliza `?? "0.0"` para proporcionar un valor por defecto.
                let sentiment = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0?.rawValue ?? "0.0"
                
                // Retorna la puntuación del sentimiento como una cadena.
                promise(.success(sentiment))
            }
            }
        .eraseToAnyPublisher()
        }
        
  
    // Función para categorizar un texto en función de una lista de categorías personalizadas.
    private func categorizeText(_ text: String, customCategories: [String]) -> AnyPublisher<[String], Never> {
        
        return Future { [weak self] promise in
            // Array para almacenar las categorías que coinciden con el texto.
            var matchedCategories: [String] = []
            
            // Recorre cada categoría personalizada.
            for category in customCategories {
                // Si el texto contiene la categoría (ignorando mayúsculas y minúsculas), la añade a las categorías coincidentes.
                if text.lowercased().contains(category.lowercased()) {
                    matchedCategories.append(category)
                }
            }
            DispatchQueue.main.async {
                // Si no se encontraron coincidencias, se retorna una categoría predeterminada "Sin categoría".
                promise(.success(matchedCategories.isEmpty ? ["Sin categoría"] : matchedCategories))
            }
            
            
        }
        .eraseToAnyPublisher()
    }
}

