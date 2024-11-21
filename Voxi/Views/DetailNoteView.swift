//
//  DetailNoteView.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 20-11-24.
//

import SwiftUI

struct DetailNoteView: View {
    // Accede al `SpeechViewModel` desde el entorno, lo que permite utilizar sus datos y funciones.
    @EnvironmentObject var viewModel: SpeechViewModel
    
    var transcription: TranscriptionEntity
    
    init(transcription: TranscriptionEntity) {
        self.transcription = transcription
        
    }
    
    var body: some View {
        VStack {
            Text("Contenido: \(transcription.text)")
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            Text("Sentimiento: \(transcription.sentiment)")
            // Las categorías predeterminadas se muestran en color gris, las personalizadas en blanco.
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            Text("Categoria: \(transcription.category)")
            // Las categorías predeterminadas se muestran en color gris, las personalizadas en blanco.
                .foregroundColor(Color.gray.opacity(0.7))
                .multilineTextAlignment(.leading)
        }
        .navigationTitle("Detalle de nota")
    }
}
