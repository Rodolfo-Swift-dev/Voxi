//
//  CategoriesView.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//

import SwiftUI

struct CategoriesView: View {
    
    // Accede al `SpeechViewModel` desde el entorno, lo que permite utilizar sus datos y funciones.
    @EnvironmentObject var viewModel: SpeechViewModel
    
    // Estado para almacenar el nombre de una nueva categoría.
    @State private var newCategory: String = ""
    
    // Estado para controlar la presentación de la alerta de nueva categoría.
    @State private var showingAlert = false
    
    // Estado para mostrar una confirmación cuando se agrega una nueva categoría.
    @State private var showingConfirmation = false
    
    @State private var isCreatedCategory = false
    
    // Computed property que genera una lista ordenada de categorías:
    // primero las predeterminadas y luego las personalizadas que no están en las predeterminadas.
    
    var body: some View {
        VStack {
            List {
                // Muestra todas las categorías, incluyendo las predeterminadas y las personalizadas.
                ForEach(viewModel.totalCategories, id: \.self) { category in
                    // Navega a la vista de notas para la categoría seleccionada.
                    NavigationLink(destination: NoteForCategoryView(category: category)) {
                        Text(category)
                        // Las categorías predeterminadas se muestran en color gris, las personalizadas en blanco.
                            .foregroundColor(viewModel.customCategories.contains(category) ? .gray : .white)
                    }
                }
                // Agrega un enlace para "Ver todas las notas", que lleva a una vista que muestra todas las transcripciones.
                NavigationLink(destination: AllNotesView()) {
                    Text("Ver todas las notas")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
        }
        // Establece un fondo negro que ocupa toda el área de la pantalla.
        .background(Color.black.edgesIgnoringSafeArea(.all))
        // Configura la navegación y el título de la vista.
        .navigationTitle("Categorías")
        .navigationBarTitleDisplayMode(.inline)
        // Botón "+" en la barra de navegación para agregar una nueva categoría.
        .navigationBarItems(trailing: Button(action: {
            showingAlert = true // Muestra la alerta para ingresar una nueva categoría.
        }) {
            Image(systemName: "plus")
                .imageScale(.large)
        })
        
        // Alerta para ingresar el nombre de la nueva categoría.
        .alert("Nueva Categoría", isPresented: $showingAlert, actions: {
            // Campo de texto para el nombre de la nueva categoría.
            TextField("Nombre de la categoría", text: $newCategory)
            
            // Botón para confirmar la adición de la nueva categoría.
            Button("Crear", action: addNewCategory)
            
            // Botón para cancelar y cerrar la alerta.
            Button("Cancelar", role: .cancel) {
                newCategory = "" // Limpia el campo de texto.
            }
        }, message: {
            Text("Ingresa el nombre de la nueva categoría.")
        })
        // Alerta de confirmación cuando la categoría se agrega exitosamente.
        .alert(isCreatedCategory ? "Categoría creada" : "Categoria no creada", isPresented: $showingConfirmation, actions: {
            Button("OK", role: .cancel) {
                showingConfirmation = false
                showingAlert = false
                isCreatedCategory = false
            }
        }, message: {
            Text(isCreatedCategory ? "La nueva categoría ha sido creada exitosamente." : "La categoria ya existe")
        })
        
        
    }
    
    
    // Función para agregar una nueva categoría.
    private func addNewCategory() {
        // Verifica que el nombre de la nueva categoría no esté vacío y que no exista en las categorías personalizadas ni predeterminadas.
        if !newCategory.isEmpty && !viewModel.totalCategories.contains(newCategory) {
            // Agrega la nueva categoría al `speechViewModel`.
            
            // Agrega una nueva categoría a la lista de categorías personalizadas si no existe previamente.
            viewModel.addedCategories.append(newCategory)
            viewModel.totalCategories = viewModel.customCategories + viewModel.addedCategories
            newCategory = "" // Limpia el campo de texto.
            isCreatedCategory = true
            showingConfirmation = true // Muestra la alerta de confirmación.
        } else {
            newCategory = "" // Limpia el campo de texto en caso de que la categoría ya exista.
            isCreatedCategory = false
            showingConfirmation = true // muestra la alerta de confirmación.
        }
    }
}
