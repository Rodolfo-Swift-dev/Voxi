//
//  NoteView.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 03-11-24.
//

import SwiftUI

struct NoteForCategoryView: View {
    
    // Accede al `SpeechViewModel` desde el entorno, lo que permite utilizar sus datos y funciones.
    @EnvironmentObject var viewModel: SpeechViewModel
    
    // Propiedad para almacenar la categoría que se está mostrando.
    var category: String
    
    
    init(category: String) {
        self.category = category
        
    }
    
    var body: some View {
        VStack {
            List {
                let notesForCategory = viewModel.transcriptions.filter {
                    $0.category == self.category
                }
                ForEach(notesForCategory, id: \.self) { transcription in
                    // Navega a la vista de nota seleccionada.
                    NavigationLink(destination: DetailNoteView(transcription: transcription)) {
                        Text(transcription.text)
                        // Las categorías predeterminadas se muestran en color gris, las personalizadas en blanco.
                            .foregroundColor(.white)
                    }
                }
                // Permite eliminar una transcripción al deslizar una celda.
                .onDelete(perform: viewModel.deleteTranscription)
            }
            
        }
        .navigationTitle(category)
    }
    
}
