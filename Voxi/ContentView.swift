//
//  ContentView.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//

import SwiftUI

struct ContentView: View {
    @State private var showSaveDeleteOptions = false
    @StateObject var viewModel = SpeechViewModel()
    
    /*
     @StateObject var viewModel: SpeechViewModel
     init(viewModel: SpeechViewModel) {
     _viewModel = StateObject(wrappedValue: SpeechViewModel(speechRecognizer: SpeechRecognizer()))
     }
     */
    
    
    var body: some View {
        NavigationView {
            VStack {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.lightGray))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    //codigo para implementar cuando esten las transcripciones
                    
                    Text(viewModel.placeholderText)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    
                    Text(viewModel.recognizedText)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                switch viewModel.buttonViewState {
                    
                case .isButtonsSaveDeleteAppear:
                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.saveTranscription()
                            viewModel.buttonViewState = .isButtonsSaveDeleteDisappier
                        }) {
                            HStack{
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
                            viewModel.recognizedText = ""
                            viewModel.buttonViewState = .isButtonsSaveDeleteDisappier
                        }) {
                            HStack{
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
                    
                case .isButtonsSaveDeleteDisappier:
                    Button(action: {
                        self.viewModel.buttonTapped()
                    }) {
                        HStack {
                            Image(systemName: viewModel.buttonImageName)
                                .imageScale(.medium)
                            Text(viewModel.buttonText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(viewModel.buttonColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    NavigationLink(destination: CategoriesView()) {
                        Text("Ver categorias")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding()
                            .opacity(viewModel.navigationLinkOpacity)
                    }
                }
            }
            
            .navigationTitle("Transcripción")
        }
    }
}
#Preview {
    ContentView(viewModel: SpeechViewModel())
}
