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
        speechRecognizer.authorizationStatus.sink { [weak self] authorized in
            self?.isAuthorized = authorized
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
        isAnalyzing = true
        guard isAuthorized else { return }
        
    }
    private func stopAnalysis() {
        isAnalyzing = false
    }
    func saveTranscription() {
        
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
}
