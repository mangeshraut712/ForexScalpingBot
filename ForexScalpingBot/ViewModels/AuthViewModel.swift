//
//  AuthViewModel.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import Foundation
import LocalAuthentication
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var username = ""
    @Published var userProfile: UserProfile?
    @Published var isBiometricsAvailable = false

    private let authContext = LAContext()

    init() {
        checkBiometricsAvailability()
        // In a real app, check for existing authentication
        // isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
    }

    func checkBiometricsAvailability() {
        var error: NSError?

        // Check for Face ID or Touch ID
        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricsAvailable = true
        }

        // Also check for passcode
        if authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            // Passcode is available
        }
    }

    func authenticateWithBiometrics() async throws {
        let reason = "Please authenticate to access your trading account"
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics

        do {
            try await authContext.evaluatePolicy(policy, localizedReason: reason)
            isAuthenticated = true
            // In real app, load user profile
            await loadUserProfile()
        } catch {
            throw error
        }
    }

    func authenticateWithUsernamePassword(username: String, password: String) async throws {
        // Mock authentication - in real app, call API
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate API call

        guard !username.isEmpty && password.count >= 8 else {
            throw AuthError.invalidCredentials
        }

        isAuthenticated = true
        self.username = username
        await loadUserProfile()
    }

    func performKYC() async throws {
        // Mock KYC process - in real app, integrate with identity verification service
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate verification

        guard let profile = userProfile else { return }

        // Mock KYC approval
        userProfile = UserProfile(
            id: profile.id,
            verified: true,
            riskTolerance: profile.riskTolerance,
            dailyLimits: profile.dailyLimits,
            apiKeys: profile.apiKeys
        )
    }

    private func loadUserProfile() async {
        // Mock profile loading - in real app, fetch from secure storage/database
        self.userProfile = UserProfile(
            id: UUID(),
            verified: false,
            riskTolerance: .moderate,
            dailyLimits: DailyLimits(maxTrades: 50, maxLoss: 1000.0),
            apiKeys: ForexAPIKeys(oandaKey: "", fxcmKey: "")
        )
    }

    func logout() {
        isAuthenticated = false
        userProfile = nil
        username = ""
        // Clear sensitive data
    }

    enum AuthError: LocalizedError {
        case invalidCredentials
        case biometricFailed
        case kycRequired

        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid username or password"
            case .biometricFailed:
                return "Biometric authentication failed"
            case .kycRequired:
                return "KYC verification required"
            }
        }
    }
}

enum RiskTolerance: String, Codable {
    case conservative = "Conservative"
    case moderate = "Moderate"
    case aggressive = "Aggressive"
}

struct UserProfile: Codable {
    let id: UUID
    var verified: Bool
    var riskTolerance: RiskTolerance
    var dailyLimits: DailyLimits
    var apiKeys: ForexAPIKeys
}

struct DailyLimits: Codable {
    var maxTrades: Int
    var maxLoss: Double
}

struct ForexAPIKeys: Codable {
    var oandaKey: String
    var fxcmKey: String
}
