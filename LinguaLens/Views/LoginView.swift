import SwiftUI

struct LoginView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var emailOrUsername = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isRegistering = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                Text(isRegistering ? "Create Account" : "Welcome Back")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 10)

                VStack(spacing: 16) {
                    // Username field (only for registration)
                    if isRegistering {
                        TextField("Username", text: $username)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(14)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Email field (changes to Email or Username for login)
                    TextField(isRegistering ? "Email" : "Email or Username", text: isRegistering ? $email : $emailOrUsername)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(14)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(isRegistering ? .emailAddress : .default)

                    // Password field with toggle
                    ZStack(alignment: .trailing) {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textFieldStyle(.plain)
                        .padding()
                        .padding(.trailing, 40)
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(14)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.trailing, 12)
                        }
                    }
                    
                    // Confirm Password field (only for registration)
                    if isRegistering {
                        ZStack(alignment: .trailing) {
                            Group {
                                if showConfirmPassword {
                                    TextField("Confirm Password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                }
                            }
                            .textFieldStyle(.plain)
                            .padding()
                            .padding(.trailing, 40)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(14)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            
                            Button {
                                showConfirmPassword.toggle()
                            } label: {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.trailing, 12)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Button {
                    handleAuthentication()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.indigo)
                        } else {
                            Text(isRegistering ? "Register" : "Login")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.indigo)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .disabled(isLoading || (isRegistering ? (username.isEmpty || email.isEmpty || password.isEmpty) : (emailOrUsername.isEmpty || password.isEmpty)))
                .opacity((isLoading || (isRegistering ? (username.isEmpty || email.isEmpty || password.isEmpty) : (emailOrUsername.isEmpty || password.isEmpty))) ? 0.6 : 1.0)

                Button(isRegistering ? "Already have an account? Login" : "Don't have an account? Register") {
                    withAnimation(.easeInOut) {
                        isRegistering.toggle()
                        errorMessage = ""
                        username = ""
                        email = ""
                        emailOrUsername = ""
                        confirmPassword = ""
                        showPassword = false
                        showConfirmPassword = false
                    }
                }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 8)
                .disabled(isLoading)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .navigationDestination(isPresented: $supabase.isAuthenticated) {
            HomeView(email: supabase.userEmail)
                .navigationBarBackButtonHidden(true)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .transition(.opacity)
    }
    
    private func handleAuthentication() {
        // Validation for registration
        if isRegistering {
            guard !username.isEmpty else {
                errorMessage = "Please enter a username"
                showError = true
                return
            }
            
            guard username.count >= 3 else {
                errorMessage = "Username must be at least 3 characters"
                showError = true
                return
            }
            
            // Username can only contain letters, numbers, underscores
            let usernameRegex = "^[a-zA-Z0-9_]+$"
            let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
            guard usernamePredicate.evaluate(with: username) else {
                errorMessage = "Username can only contain letters, numbers, and underscores"
                showError = true
                return
            }
            
            guard isValidEmail(email) else {
                errorMessage = "Please enter a valid email address"
                showError = true
                return
            }
            
            guard password.count >= 6 else {
                errorMessage = "Password must be at least 6 characters"
                showError = true
                return
            }
            
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match"
                showError = true
                return
            }
        } else {
            // Validation for login
            guard !emailOrUsername.isEmpty else {
                errorMessage = "Please enter your email or username"
                showError = true
                return
            }
            
            guard password.count >= 6 else {
                errorMessage = "Password must be at least 6 characters"
                showError = true
                return
            }
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if isRegistering {
                    _ = try await supabase.signUp(email: email, password: password, username: username)
                } else {
                    _ = try await supabase.signIn(emailOrUsername: emailOrUsername, password: password)
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
