//
//  NoteView.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 03-11-24.
//

import SwiftUI

struct NoteView: View {
    
    // Accede al `SpeechViewModel` desde el entorno, lo que permite utilizar sus datos y funciones.
    @EnvironmentObject var speechViewModel: SpeechViewModel
    
    // Propiedad para almacenar la categoría que se está mostrando.
    var category: String
    
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}
