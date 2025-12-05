import SwiftUI

struct HistoryView: View {
    let email: String
    @StateObject private var supabase = SupabaseManager.shared
    @State private var selectedItem: Translation?
    @State private var isLoading = true
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.indigo.opacity(0.9),
                                                           Color.purple.opacity(0.9)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else if supabase.translations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 70))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Text("No History Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        
                        Text("Your translations will appear here")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(supabase.translations) { item in
                                TranslationCard(item: item)
                                    .onTapGesture {
                                        selectedItem = item
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        await supabase.fetchTranslations()
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("History")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                if !supabase.translations.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
            }
            .sheet(item: $selectedItem) { item in
                TranslationDetailSheet(item: item)
            }
            .alert("Delete All Translations", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    Task {
                        do {
                            try await supabase.deleteAllTranslations()
                        } catch {
                            print("Error deleting translations: \(error)")
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete all your translation history? This action cannot be undone.")
            }
            .task {
                await supabase.fetchTranslations()
                isLoading = false
            }
        }
    }
}

struct TranslationCard: View {
    let item: Translation
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail image if available
            if let imageUrl = item.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 60)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure:
                        placeholderIcon
                    @unknown default:
                        placeholderIcon
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            } else {
                placeholderIcon
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Text(item.sourceLanguage)
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                        Text(item.targetLanguage)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(item.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Text(item.originalText)
                    .font(.body)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                Text(item.translatedText)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var placeholderIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
                .frame(width: 60, height: 60)
            
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

struct TranslationDetailSheet: View {
    let item: Translation
    @StateObject private var supabase = SupabaseManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showFullScreenImage = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.9),
                                                           Color.indigo.opacity(0.9)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Translation")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                Text(item.createdAt, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Text(item.sourceLanguage)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                Text(item.targetLanguage)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                        }
                        
                        // Image Section
                        if let imageUrl = item.imageUrl {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Captured Image")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                Button {
                                    showFullScreenImage = true
                                } label: {
                                    AsyncImage(url: URL(string: imageUrl)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 200)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: .infinity)
                                                .frame(maxHeight: 200)
                                        case .failure:
                                            Text("Failed to load image")
                                                .foregroundStyle(.white.opacity(0.6))
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 200)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                    .font(.caption)
                                                    .foregroundStyle(.white)
                                                    .padding(8)
                                                    .background(Color.black.opacity(0.5))
                                                    .clipShape(Circle())
                                                    .padding(8)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Original (\(item.sourceLanguage))")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                Spacer()
                                
                                Button {
                                    UIPasteboard.general.string = item.originalText
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            
                            Text(item.originalText)
                                .font(.body)
                                .foregroundStyle(.white)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(16)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Translation (\(item.targetLanguage))")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                Spacer()
                                
                                Button {
                                    UIPasteboard.general.string = item.translatedText
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            
                            Text(item.translatedText)
                                .font(.body)
                                .foregroundStyle(.white)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(16)
                        }
                        
                        // Delete Button
                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Translation")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Translation Details")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .fullScreenCover(isPresented: $showFullScreenImage) {
                if let imageUrl = item.imageUrl {
                    FullScreenImageView(imageUrl: imageUrl)
                }
            }
            .alert("Delete Translation", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await supabase.deleteTranslation(id: item.id)
                            dismiss()
                        } catch {
                            print("Error deleting translation: \(error)")
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this translation?")
            }
        }
    }
}

struct FullScreenImageView: View {
    let imageUrl: String
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { value in
                                    lastScale = scale
                                    if scale < 1.0 {
                                        withAnimation {
                                            scale = 1.0
                                            lastScale = 1.0
                                        }
                                    }
                                    if scale > 4.0 {
                                        withAnimation {
                                            scale = 4.0
                                            lastScale = 4.0
                                        }
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                } else {
                                    scale = 2.0
                                    lastScale = 2.0
                                }
                            }
                        }
                case .failure:
                    Text("Failed to load image")
                        .foregroundStyle(.white)
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}
