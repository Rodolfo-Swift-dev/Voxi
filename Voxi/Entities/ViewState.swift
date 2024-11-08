//
//  ViewState.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 31-10-24.
//

// Importa el módulo Foundation, que contiene funcionalidades básicas de Swift.
// Aunque este código en particular no lo requiere estrictamente, es común importarlo en archivos Swift.
import Foundation

// Define un enumerado (enum) llamado ViewState, que representa diferentes estados de visibilidad de los botones.
enum ViewState {
    
    // Estado que indica que los botones "Guardar" y "Eliminar" están visibles en la interfaz.
    case isButtonsSaveDeleteAppear
    
    // Estado que indica que los botones "Guardar" y "Eliminar" están ocultos en la interfaz.
    case isButtonsSaveDeleteDisappier
}
