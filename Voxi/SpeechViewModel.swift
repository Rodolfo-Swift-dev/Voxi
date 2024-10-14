//
//  SpeechViewModel.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//

import Foundation
import Combine

class SpeechViewModel: ObservableObject {
    @Published var currentTranscription = ""
    @Published var isAnalyzing = false
    @Published var isAuthorized = false
    
    private let speechRecognizer = SpeechRecognizer()
    private let startAnalysisSubject = PassthroughSubject<Void, Never>()
    private let stopAnalysisSubject = PassthroughSubject<Void, Never>()
    private let startAuthorizationSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        //forma rapida de vincular authorizationStatus con isAuthorized y poder reaccionar a sus cambios
        //speechRecognizer.authorizationStatus.assign(to: &$isAuthorized)
        
        //forma amplia de suscribir authorizationStatus con isAuthorized y poder reaccionar a sus cambios, ademas podemos agregar codigo lo que lo hace mas flexible
        speechRecognizer.authorizationStatusPublisher.sink { [weak self] authorized in
            DispatchQueue.main.async {
                DispatchQueue.main.async {
                    self?.isAuthorized = authorized
                }
                
            }
        }
        .store(in: &cancellables)
        
        speechRecognizer.speechResultPublisher.sink { [weak self] transcription in
            DispatchQueue.main.async {
                self?.currentTranscription = transcription
            }
            
        }
        .store(in: &cancellables)
        
        speechRecognizer.speechErrorPublisher.sink {
            print("Error")
        }
        .store(in: &cancellables)
        
        startAuthorizationSubject.sink { [weak self] in
            self?.startAuthorization()
        }
        .store(in: &cancellables)
        
        startAnalysisSubject.sink { [weak self] in
            self?.startAnalysis()
        }
        .store(in: &cancellables)
        
        stopAnalysisSubject.sink { [weak self] in
            self?.stopAnalysis()
        }
        .store(in: &cancellables)
        
    }
    
    private func startAuthorization() {
        speechRecognizer.requestAuthorization()
    }
    private func startAnalysis() {
        
        guard isAuthorized else { return }
        speechRecognizer.requestStartRecognition()
        DispatchQueue.main.async {
            self.isAnalyzing = true
        }
    }
    private func stopAnalysis() {
        DispatchQueue.main.async {
            self.isAnalyzing = false
        }
        speechRecognizer.requestStopRecognition()
    }
    
    func requestStartAuthorization() {
        startAuthorizationSubject.send(())
    }
    func requestStartAnalysis() {
        startAnalysisSubject.send(())
    }
    func requestStopAnalysis() {
        stopAnalysisSubject.send(())
    }
    func saveTranscription() {
        
    }
}
