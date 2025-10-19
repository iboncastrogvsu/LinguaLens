import SwiftUI

struct TranslationItem: Identifiable {
    let id = UUID()
    let originalText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let date: Date
    let imageName: String?
}

struct HistoryView: View {
    let email: String
    @State private var translations: [TranslationItem] = [
        TranslationItem(originalText: "What's the point of legal injuctions AFTER a Data Breach?\n\nAre legal injuctions just symbolic gestures, or do they serve a genuine purpose in the aftermath of data breaches?\n\nIn my video, I investigate the intentions behind these court orders and explore the perspectives of different stakeholders.\n\nFind out why organisations are adding this tool to their incident response strategy.\n\nClick to watch and share your thoughts!", translatedText: "¿Cuál es el propósito de las medidas judiciales después de una filtración de datos?\n\n¿Son las medidas judiciales solo gestos simbólicos, o realmente cumplen una función genuina tras una violación de datos?\n\nEn mi video, analizo las intenciones detrás de estas órdenes judiciales y exploro las perspectivas de los diferentes actores involucrados.\n\nDescubre por qué las organizaciones están incorporando esta herramienta en su estrategia de respuesta a incidentes.\n\n¡Haz clic para ver el video y comparte tus opiniones!", sourceLanguage: "English", targetLanguage: "Spanish", date: Date().addingTimeInterval(-86400), imageName: "example1"),
        TranslationItem(originalText: "\"Episodio 38 - Cómo saber si tu idea es una mierda antes de perder dinero\"\n\nCrees que la gente te dice la verdad cuando le cuentas tu idea.\n\nPues no.\n\nTe mienten.\n\nTu madre, tus colegas, tus futuros clientes... todos.\n\nNo por maldad. Por educación.\n\nY por eso hay tanta gente quemando dinero, tiempo y neuronas en proyectos que nadie quiere.\n\nEn este episodio te doy 5 técnicas para hacer que los clientes te digan la verdad, aunque no quieran.\n\n\nEste domingo 19 estará disponible\n\n24 minutos y 28 segundos", translatedText: "\"Episode 38 - How to Know if Your Idea is Crap Before You Lose Money\"\n\nDo you think people tell you the truth when you share your idea with them?\n\nWell, no.\n\nThey lie to you.\n\nYour mom, your colleagues, your future clients… everyone.\n\nNot out of malice. Out of politeness.\n\nAnd that's why so many people are burning money, time, and brainpower on projects nobody wants.\n\nIn this episode, I give you 5 techniques to make clients tell you the truth—even when they don't want to.\n\n\nThis Sunday the 19th it will be available\n\n24 minutes and 28 seconds", sourceLanguage: "Spanish", targetLanguage: "English", date: Date().addingTimeInterval(-172800), imageName: "example2")
    ]
    @State private var selectedItem: TranslationItem?
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.indigo.opacity(0.9),
                                                           Color.purple.opacity(0.9)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                if translations.isEmpty {
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
                            ForEach(translations) { item in
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
                
                if !translations.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            translations.removeAll()
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
        }
    }
}

struct TranslationCard: View {
    let item: TranslationItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail image if available
            if let imageName = item.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            } else {
                // Placeholder icon when no image
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "doc.text")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.6))
                }
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
                    
                    Text(item.date, style: .relative)
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
}

struct TranslationDetailSheet: View {
    let item: TranslationItem
    @Environment(\.dismiss) var dismiss
    @State private var showFullScreenImage = false
    
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
                                Text(item.date, style: .date)
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
                        if let imageName = item.imageName {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Captured Image")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                Button {
                                    showFullScreenImage = true
                                } label: {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .frame(maxHeight: 200)
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
                FullScreenImageView(imageName: item.imageName ?? "")
            }
        }
    }
}

struct FullScreenImageView: View {
    let imageName: String
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(imageName)
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
                            // Reset if zoomed out too much
                            if scale < 1.0 {
                                withAnimation {
                                    scale = 1.0
                                    lastScale = 1.0
                                }
                            }
                            // Limit maximum zoom
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
