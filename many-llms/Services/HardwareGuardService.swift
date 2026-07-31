//
//  HardwareGuardService.swift
//  many-llms
//  v1.2 Feature - Device Hardware & Thermal Guardian
//

import Foundation
import Combine

public enum ThermalRiskLevel: String {
    case nominal = "Nominal"
    case fair = "Moderado"
    case serious = "Alto"
    case critical = "Crítico"
    
    public var icon: String {
        switch self {
        case .nominal: return "checkmark.shield.fill"
        case .fair: return "thermometer.medium"
        case .serious: return "thermometer.high"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}

public final class HardwareGuardService: ObservableObject {
    public static let shared = HardwareGuardService()
    
    @Published public private(set) var physicalRAMBytes: UInt64
    @Published public private(set) var safeModelRAMLimitBytes: UInt64
    @Published public private(set) var currentThermalState: ProcessInfo.ThermalState
    @Published public private(set) var deviceModelName: String
    
    private var observer: NSObjectProtocol?
    
    private init() {
        let totalRam = ProcessInfo.processInfo.physicalMemory
        self.physicalRAMBytes = totalRam
        
        // On iOS/iPadOS, apps are typically allocated 60% - 70% of total RAM before encountering Jetsam memory pressure
        self.safeModelRAMLimitBytes = UInt64(Double(totalRam) * 0.65)
        self.currentThermalState = ProcessInfo.processInfo.thermalState
        
        #if os(iOS)
        self.deviceModelName = "Apple Device (\(ByteCountFormatter.string(fromByteCount: Int64(totalRam), countStyle: .memory)) Unified RAM)"
        #else
        self.deviceModelName = "Mac Apple Silicon (\(ByteCountFormatter.string(fromByteCount: Int64(totalRam), countStyle: .memory)) Unified RAM)"
        #endif
        
        setupThermalObserver()
    }
    
    deinit {
        if let obs = observer {
            NotificationCenter.default.removeObserver(obs)
        }
    }
    
    private func setupThermalObserver() {
        observer = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.currentThermalState = ProcessInfo.processInfo.thermalState
        }
    }
    
    public var thermalRiskLevel: ThermalRiskLevel {
        switch currentThermalState {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .nominal
        }
    }
    
    public var formattedRAMLimit: String {
        ByteCountFormatter.string(fromByteCount: Int64(safeModelRAMLimitBytes), countStyle: .memory)
    }
    
    public var formattedTotalRAM: String {
        ByteCountFormatter.string(fromByteCount: Int64(physicalRAMBytes), countStyle: .memory)
    }
    
    /// Evaluates if a model can run safely on this device given its estimated RAM requirements
    public func canRunModelSafely(_ model: LocalModelInfo) -> (canRun: Bool, warningMessage: String?) {
        if model.estimatedRAMBytes > Int64(safeModelRAMLimitBytes) {
            let msg = "⚠️ Requiere ~\(model.formattedRAMRequired) RAM. Tu límite seguro de app es \(formattedRAMLimit) (\(formattedTotalRAM) totales). Podría causar cierre por falta de memoria (Jetsam)."
            return (false, msg)
        }
        
        if currentThermalState == .critical || currentThermalState == .serious {
            let msg = "🔥 La temperatura del dispositivo es alta. Se recomienda dejar enfriar antes de iniciar inferencia pesada."
            return (true, msg)
        }
        
        return (true, nil)
    }
}
