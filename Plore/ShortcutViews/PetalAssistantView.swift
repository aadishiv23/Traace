//
//  PetalAssistantView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation
import SwiftUI

struct PetalAssistantView: View {
    @State private var isEssayExpanded = false
    @State private var selectedAction: String?
    @State private var animateGradient = false
    @State private var selectedTab = 0
    
    let sampleEssay = """
    The Impact of Artificial Intelligence on Modern Education
    
    In recent years, artificial intelligence has transformed the educational landscape, 
    offering new possibilities for personalized learning and automated assessment. 
    However, this technological revolution also raises important questions about the 
    role of human teachers and the nature of education itself...
    """
    
    let aiAnalysis = """
    • Strong opening thesis, but could be more specific
    • Good flow between paragraphs
    • Consider adding more concrete examples
    • Citation needed for AI statistics
    • Conclusion could be strengthened
    """
    
    let suggestedActions = [
        ("✍️ Enhance Thesis", "Strengthen your opening argument"),
        ("📚 Add Citations", "Include academic sources"),
        ("🎯 Expand Examples", "Add real-world cases"),
        ("✨ Check Grammar", "Polish your writing"),
        ("🎭 Strengthen Conclusion", "End with impact")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Petal AI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Your Writing Assistant")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 40))
                        .foregroundStyle(.linearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                .padding()
                
                // Essay Canvas
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Your Essay")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { withAnimation { isEssayExpanded.toggle() }}) {
                            Label(isEssayExpanded ? "Collapse" : "Expand",
                                  systemImage: isEssayExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Writing progress indicators
                        HStack(spacing: 20) {
                            ProgressRing(progress: 0.8, title: "Clarity", color: .blue)
                            ProgressRing(progress: 0.6, title: "Structure", color: .purple)
                            ProgressRing(progress: 0.9, title: "Grammar", color: .green)
                        }
                        
                        Text(sampleEssay)
                            .lineLimit(isEssayExpanded ? nil : 3)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                }
                .padding(.horizontal)
                
                // AI Analysis Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI Analysis")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    TabView(selection: $selectedTab) {
                        // Overview Tab
                        AnalysisCard(title: "Overview", icon: "doc.text.magnifyingglass") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(aiAnalysis.components(separatedBy: "\n"), id: \.self) { point in
                                    HStack(alignment: .top) {
                                        Text(point)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .tag(0)
                        
                        // Style Tab
                        AnalysisCard(title: "Style", icon: "paintbrush.pointed") {
                            StyleAnalysisView()
                        }
                        .tag(1)
                        
                        // Structure Tab
                        AnalysisCard(title: "Structure", icon: "square.stack.3d.up") {
                            StructureAnalysisView()
                        }
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 250)
                }
                .padding(.horizontal)
                
                // Suggested Actions
                VStack(alignment: .leading, spacing: 20) {
                    Text("Recommended Actions")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ForEach(suggestedActions, id: \.0) { action, description in
                        ActionButton(
                            title: action,
                            description: description,
                            isSelected: selectedAction == action,
                            action: { selectedAction = action }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemGray6), Color(.systemBackground)],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
        )
    }
}

struct ProgressRing: View {
    let progress: Double
    let title: String
    let color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(width: 50, height: 50)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ActionButton: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.blue)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1),
                           radius: isSelected ? 10 : 5,
                           x: 0,
                           y: isSelected ? 5 : 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AnalysisCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            content
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
        .padding(.horizontal)
    }
}

struct StyleAnalysisView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Writing Style Metrics")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Tone")
                    ProgressView(value: 0.7)
                        .tint(.blue)
                }
                VStack(alignment: .leading) {
                    Text("Clarity")
                    ProgressView(value: 0.8)
                        .tint(.green)
                }
            }
            
            Text("Your writing style is academic and professional, but could be more engaging.")
                .font(.subheadline)
        }
    }
}

struct StructureAnalysisView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Paragraph Analysis")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(["Introduction", "Body", "Conclusion"], id: \.self) { section in
                HStack {
                    Text(section)
                    Spacer()
                    Image(systemName: section == "Body" ? "exclamationmark.circle" : "checkmark.circle")
                        .foregroundColor(section == "Body" ? .orange : .green)
                }
            }
        }
    }
}

#Preview {
    PetalAssistantView()
}
