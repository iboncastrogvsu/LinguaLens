import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                Text(isRegistering ? "Create Account" : "Welcome Back")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 10)

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
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

                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(14)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }

                Button {
                    withAnimation {
                        isLoggedIn = true
                    }
                } label: {
                    Text(isRegistering ? "Register" : "Login")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.indigo)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }

                Button(isRegistering ? "Already have an account? Login" : "Don’t have an account? Register") {
                    withAnimation(.easeInOut) {
                        isRegistering.toggle()
                    }
                }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 8)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        
        .navigationDestination(isPresented: $isLoggedIn) {
            HomeView(email: email)
                .navigationBarBackButtonHidden(true)
        }
        
        .transition(.opacity)
    }
}

