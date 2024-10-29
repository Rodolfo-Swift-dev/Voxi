//
//  ContentView.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//

import SwiftUI

/*
 struct ContentView: View {
 @EnvironmentObject private var speechViewModel : SpeechViewModel
 @State private var showSaveDeleteOptions = false
 
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
 withAnimation {
 showSaveDeleteOptions = false
 }
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
 DispatchQueue.main.async {
 speechViewModel.currentTranscription = ""
 }
 
 withAnimation {
 showSaveDeleteOptions = false
 }
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
 .padding(.top)
 }
 NavigationLink(destination: CategoriesView()) {
 Text("Ver categorias")
 .font(.headline)
 .foregroundColor(.primary)
 .padding()
 
 }
 .onReceive(speechViewModel.$isAuthorized) { isAuthorized in
 if isAuthorized {
 DispatchQueue.main.async {
 toggleAnalysis()
 }
 
 }
 }
 }
 .navigationTitle("Transcripción")
 }
 }
 private func toggleAnalysis() {
 if speechViewModel.isAnalyzing {
 showSaveDeleteOptions = !speechViewModel.currentTranscription.isEmpty
 speechViewModel.requestStopAnalysis()
 
 
 } else {
 if !speechViewModel.isAuthorized {
 speechViewModel.requestStartAuthorization()
 } else {
 speechViewModel.requestStartAnalysis()
 }
 }
 }
 }
 */





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
                    if viewModel.recognizedText.isEmpty && viewModel.buttonValue {
                        Text("Escuchando")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }
                    Text(viewModel.recognizedText)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                if showSaveDeleteOptions {
                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.saveTranscription()
                            showSaveDeleteOptions = false
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
                            showSaveDeleteOptions = false
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
                } else {
                    
                    Button(action: {
                        withAnimation {
                            toggleAnalysis()
                        }
                    }) {
                        HStack {
                            Image(systemName: (viewModel.buttonValue == true) && (viewModel.isSpeechAuthorized == .authorized) && (viewModel.isMicrophoneAuthorized == true) ? "stop.fill" : "mic.fill")
                                .imageScale(.medium)
                            Text((viewModel.buttonValue == true) && (viewModel.isSpeechAuthorized == .authorized) && (viewModel.isMicrophoneAuthorized == true) ? "Detener análisis" : "Iniciar análisis")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background((viewModel.buttonValue == true) && (viewModel.isSpeechAuthorized == .authorized) && (viewModel.isMicrophoneAuthorized == true) ? Color.red : Color.green)
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
                            .opacity(!viewModel.buttonValue ? 1 : 0)
                    }
                }
            }
            
            .navigationTitle("Transcripción")
        }
    }
    private func toggleAnalysis() {
        $viewModel.buttonValue.wrappedValue.toggle()
        print("speech \(viewModel.isSpeechAuthorized)")
        print("micro \(viewModel.isMicrophoneAuthorized)")
    }
}
#Preview {
    ContentView(viewModel: SpeechViewModel())
}
