//
//  AuthView.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var username = ""
    @State private var password = ""
    @State private var isKYCInProgress = false
    @State private var showKYCSuccess = false
    @State private var showKYCRequired = false
    @State private var authError: AuthViewModel.AuthError?

    var body: some View {
        NavigationView {
            ZStack {
                Color.blue.opacity(0.1)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 30) {
                    Spacer()

                    // Logo/Branding
                    VStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Forex Scalping Bot")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Advanced AI-Powered Trading")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Authentication Options
                    VStack(spacing: 20) {

                        // Biometric Authentication Button
                        if authViewModel.isBiometricsAvailable {
                            Button(action: authenticateWithBiometrics) {
                                HStack {
                                    Image(systemName: "faceid")
                                        .font(.title2)
                                    Text("Sign in with Face ID")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }

                        Text("OR")
                            .foregroundColor(.secondary)
                            .font(.caption)

                        // Username/Password Fields
                        VStack(spacing: 15) {
                            TextField("Username", text: $username)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 5)

                            SecureField("Password", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 5)
                        }

                        // Sign In Button
                        Button(action: authenticateWithCredentials) {
                            if isKYCInProgress {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(username.isEmpty || password.isEmpty || isKYCInProgress)

                        // KYC Button for new users
                        Button(action: { showKYCRequired = true }) {
                            Text("New User? Complete KYC")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .alert(item: $authError) { error in
            Alert(title: Text("Authentication Error"),
                  message: Text(error.localizedDescription),
                  dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showKYCRequired) {
            KYCView()
        }
        .sheet(isPresented: $showKYCSuccess) {
            KYCSuccessView()
        }
    }

    private func authenticateWithBiometrics() {
        Task {
            do {
                try await authViewModel.authenticateWithBiometrics()
            } catch {
                if let authError = error as? AuthViewModel.AuthError {
                    self.authError = authError
                } else {
                    // Handle generic biometric error
                    authError = .biometricFailed
                }
            }
        }
    }

    private func authenticateWithCredentials() {
        Task {
            do {
                try await authViewModel.authenticateWithUsernamePassword(username: username, password: password)

                // Check if KYC is required
                if let profile = authViewModel.userProfile, !profile.verified {
                    showKYCSuccess = true
                }
            } catch {
                if let authError = error as? AuthViewModel.AuthError {
                    self.authError = authError
                }
            }
        }
    }
}

// KYC View for Know Your Customer verification
struct KYCView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var dateOfBirth = Date()
    @State private var address = ""
    @State private var idType = "Passport"
    @State private var idNumber = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false

    let idTypes = ["Passport", "Driver's License", "National ID"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    TextField("Address", text: $address)
                }

                Section(header: Text("Identification")) {
                    Picker("ID Type", selection: $idType) {
                        ForEach(idTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    TextField("ID Number", text: $idNumber)
                }

                Section {
                    Button(action: submitKYC) {
                        if isSubmitting {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Submitting...")
                                Spacer()
                            }
                        } else {
                            Text("Complete KYC Verification")
                        }
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .navigationTitle("KYC Verification")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert(isPresented: $showSuccess) {
            Alert(title: Text("Success"),
                  message: Text("KYC verification submitted successfully. You will be notified once approved."),
                  dismissButton: .default(Text("OK")) {
                presentationMode.wrappedValue.dismiss()
                Task {
                    await authViewModel.performKYC()
                }
            })
        }
    }

    private var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty && !phone.isEmpty &&
        !address.isEmpty && !idNumber.isEmpty &&
        email.contains("@") && phone.count >= 10
    }

    private func submitKYC() {
        isSubmitting = true

        // In a real app, call API to submit KYC information
        // Here we simulate the submission
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate API call
            isSubmitting = false
            showSuccess = true
        }
    }
}

// KYC Success View
struct KYCSuccessView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("KYC Verification Complete!")
                .font(.title)
                .fontWeight(.bold)

            Text("You can now access all trading features. Welcome to Forex Scalping Bot!")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Get Started") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding()
    }
}

// Extension to make AuthError conform to Identifiable for Alert
extension AuthViewModel.AuthError: Identifiable {
    var id: String {
        localizedDescription
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
