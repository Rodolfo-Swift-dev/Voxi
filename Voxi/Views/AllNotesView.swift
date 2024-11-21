//
//  AllNotesView.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 03-11-24.
//

import SwiftUI

struct AllNotesView: View {
    
    // Accede al `SpeechViewModel` desde el entorno, lo que permite utilizar sus datos y funciones.
    @EnvironmentObject var viewModel: SpeechViewModel
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.transcriptions, id: \.self) { transcription in
                    // Navega a la vista de nota seleccionada.
                    NavigationLink(destination: DetailNoteView(transcription: transcription)) {
                        VStack {
                            Text(transcription.text)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            
                        }
                        .multilineTextAlignment(.leading)
                        
                    }
                }
                // Permite eliminar una transcripción al deslizar una celda.
                .onDelete(perform: viewModel.deleteTranscription)
            }
        }
        .navigationTitle("Todas las notas")
    }
}
