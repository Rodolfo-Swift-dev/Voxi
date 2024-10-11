//
//  ContentView.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var speechViewModel : SpeechViewModel
    @State private var showSaveDeleteOptions = false
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.lightGray))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    
                     //codigo para implementar cuando esten las transcripciones
                     if speechViewModel.currentTranscription.isEmpty && speechViewModel.isAnalyzing {
                         Text("Escuchando")
                             .foregroundColor(.gray)
                             .padding(.horizontal, 16)
                             .padding(.top, 12)
                     }
                            
                     
                     
                   
                    Text(speechViewModel.currentTranscription)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                
                if showSaveDeleteOptions {
                    HStack(spacing: 16) {
                        Button(action: {
                            speechViewModel.saveTranscription()
                            showSaveDeleteOptions = false
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .imageScale(.medium)
                                Text("Guardar")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        Button(action: {
                            speechViewModel.currentTranscription = ""
                            showSaveDeleteOptions = false
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .imageScale(.medium)
                                Text("Cancelar")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                } else {
                    Button(action: toggleAnalysis) {
                        HStack {
                            Image(systemName: speechViewModel.isAnalyzing ? "stop.fill" : "mic.fill")
                                .imageScale(.medium)
                            Text(speechViewModel.isAnalyzing ? "Detener análisis" : "Iniciar análisis")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(speechViewModel.isAnalyzing ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                NavigationLink(destination: CategoriesView()) {
                    Text("Ver categorias")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding()
                }
            }
            .navigationTitle("Transcripción")
            .alert(isPresented: $showAlert) {
                let messageAlert = "Necesitamos tu permiso para usar el reconocimiento de voz. ¿Deseas otorgarlo?"
                
                return Alert(
                    title: Text("Permiso de reconocimiento de voz"),
                    message: Text(messageAlert),
                    primaryButton: .default(Text("Si")) {},
                    secondaryButton: .cancel(Text("No"))
                )
            }
        }
    }
    private func toggleAnalysis() {
        if speechViewModel.isAnalyzing {
            speechViewModel.requestStopAnalysis()
        } else {
            if !speechViewModel.isAuthorized {
                showAlert = true
            } else {
                speechViewModel.requestStartAnalysis()
            }
        }
    }
}

#Preview {
    ContentView()
}
