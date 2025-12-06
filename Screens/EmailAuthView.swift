//
//  EmailAuthView.swift
//  AI Voice Copilot
//

import SwiftUI
import AuthenticationServices

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isRegistering = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showPasswordReset = false

    var onAuthenticated: ((String) -> Void)?

    private var isFormValid: Bool {
        let emailValid = !email.isEmpty && email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 8
        if isRegistering {
            return emailValid && passwordValid && password == confirmPassword
        }
        return emailValid && passwordValid
    }

    private var passwordValidationMessage: String? {
        if password.isEmpty { return nil }
        if password.count < 8 { return "Password must be at least 8 characters" }
        if !password.contains(where: { $0.isUppercase }) { return "Must contain an uppercase letter" }
        if !password.contains(where: { $0.isLowercase }) { return "Must contain a lowercase letter" }
        if !password.contains(where: { $0.isNumber }) { return "Must contain a number" }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: isRegistering ? "person.badge.plus" : "person.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text(isRegistering ? "Create Account" : "Sign In")
                            .font(.title.bold())

                        Text(isRegistering ? "Sign up with your email address" : "Welcome back")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Form
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextField("your@email.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            SecureField("Password", text: $password)
                                .textContentType(isRegistering ? .newPassword : .password)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)

                            if let validationMsg = passwordValidationMessage {
                                Text(validationMsg)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }

                        // Confirm password (registration only)
                        if isRegistering {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirm Password")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                SecureField("Confirm password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)

                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Action button
                    Button {
                        Task {
                            await performAuth()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isRegistering ? "Create Account" : "Sign In")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal)

                    // Toggle mode
                    Button {
                        withAnimation {
                            isRegistering.toggle()
                            errorMessage = nil
                            confirmPassword = ""
                        }
                    } label: {
                        Text(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                    }
                    .disabled(isLoading)

                    // Forgot Password (login mode only)
                    if !isRegistering {
                        Button {
                            showPasswordReset = true
                        } label: {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .disabled(isLoading)
                    }

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result: result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .sheet(isPresented: $showPasswordReset) {
                PasswordResetView()
            }
        }
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return
            }

            do {
                try AuthService.shared.handleAppleSignIn(credential: credential)
                onAuthenticated?("apple_\(credential.user)")
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func performAuth() async {
        isLoading = true
        errorMessage = nil

        do {
            let token: String
            if isRegistering {
                token = try await AuthService.shared.register(email: email, password: password)
            } else {
                token = try await AuthService.shared.login(email: email, password: password)
            }

            await MainActor.run {
                HapticFeedbackService.shared.success()
                isLoading = false
                onAuthenticated?(token)
                dismiss()
            }
        } catch {
            await MainActor.run {
                HapticFeedbackService.shared.error()
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    EmailAuthView()
}
