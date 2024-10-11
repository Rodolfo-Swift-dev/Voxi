//
//  SpeechViewModel.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//

import SwiftUI
import Combine

class SpeechViewModel: ObservableObject {
    @Published var currentTranscription = ""
    @Published var isAnalyzing = false
    @Published var isAuthorized = false
    
    private var speechRecognizer = SpeechRecognizer()
    private var cancellables = Set<AnyCancellable>()
    private let startAnalysisSubject = PassthroughSubject<Void, Never>()
    private let stopAnalysisSubject = PassthroughSubject<Void, Never>()
    
    init() {
        speechRecognizer.authorizationStatus.assign(to: &$isAuthorized)
        
        startAnalysisSubject.sink { [weak self] in
            self?.startAnalysis()
        }
        .store(in: &cancellables)
        
        stopAnalysisSubject.sink { [weak self] in
            self?.stopAnalysis()
        }
        .store(in: &cancellables)
    }
    
    private func startAnalysis() {
        guard isAuthorized else { return }
        isAnalyzing = true
    }
    private func stopAnalysis() {
        isAnalyzing = false
    }
    func saveTranscription() {
        
    }
    func requestStartAnalysis() {
        startAnalysisSubject.send(())
    }
    func requestStopAnalysis() {
        stopAnalysisSubject.send(())
    }
}
