//
//  OpenAppView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/10/25.
//

import Foundation
import SwiftUI

// MARK: - Models

struct AssistantTask: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let timeframe: String
    let isScheduled: Bool
    let type: TaskType
    
    let suggestedCommands: [String] = [
        "Analyze this task",
        "Generate outline",
        "Create study materials",
        "Set reminders",
        "Share with study group"
    ]
    
    enum TaskType: String {
        case research, math, literature, science, writing, study
    }
}

// MARK: - OpenAppView

struct OpenAppView: View {
    @State private var tasks = [
        AssistantTask(title: "Research Paper Analysis",
             description: "AI will analyze research papers on renewable energy",
             timeframe: "Scheduled for 3 PM",
             isScheduled: true,
             type: .research),
        AssistantTask(title: "Math Problem Solutions",
             description: "Step-by-step calculus problem solving",
             timeframe: "Tomorrow",
             isScheduled: true,
             type: .math),
        AssistantTask(title: "Literature Review",
             description: "Analysis of Shakespeare's Macbeth",
             timeframe: "Unplanned",
             isScheduled: false,
             type: .literature),
        AssistantTask(title: "Chemistry Lab Report",
             description: "Help structure and review lab findings",
             timeframe: "Scheduled for 5 PM",
             isScheduled: true,
             type: .science),
        AssistantTask(title: "Essay Outline",
             description: "Create detailed outline for history essay",
             timeframe: "Unplanned",
             isScheduled: false,
             type: .writing),
        AssistantTask(title: "Study Guide Creation",
             description: "Generate comprehensive biology study guide",
             timeframe: "Next Week",
             isScheduled: true,
             type: .study)
    ]
    
    @State private var selectedTask: AssistantTask?
    @State private var showingTaskDetail = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerView
                tasksView
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGray6))
        .sheet(isPresented: $showingTaskDetail, content: {
            if let task = selectedTask {
                TaskDetailView(task: task)
            }
        })
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Petal Tasks")
                .font(.system(size: 34, weight: .bold))
            Text("View and edit Petal's tasks")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.bottom, 10)
    }
    
    private var tasksView: some View {
        VStack(spacing: 16) {
            ForEach(tasks) { task in
                TaskCardView(task: task)
                    .onTapGesture {
                        selectedTask = task
                        showingTaskDetail = true
                    }
            }
        }
    }
}

// MARK: - TaskCardView

struct TaskCardView: View {
    let task: AssistantTask
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Column
            Circle()
                .fill(task.isScheduled ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: iconName)
                        .foregroundColor(task.isScheduled ? .blue : .gray)
                        .font(.system(size: 24))
                )
            
            // Content Column
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(1)
                
                Text(task.description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    // Time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(task.timeframe)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.gray)
                    
                    // Status Badge
                    if task.isScheduled {
                        Text("Scheduled")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    private var iconName: String {
        switch task.type {
        case .research: return "book.fill"
        case .math: return "function"
        case .literature: return "text.book.closed.fill"
        case .science: return "atom"
        case .writing: return "pencil"
        case .study: return "calendar"
        }
    }
}

// MARK: - TaskDetailView

struct TaskDetailView: View {
    let task: AssistantTask
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section with Icon
                    HStack(spacing: 16) {
                        Circle()
                            .fill(task.isScheduled ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: iconName)
                                    .foregroundColor(task.isScheduled ? .blue : .gray)
                                    .font(.system(size: 30))
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.system(size: 24, weight: .bold))
                            
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                Text(task.isScheduled ? "Scheduled" : "Unplanned")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(task.isScheduled ? .blue : .gray)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Description
                    Text(task.description)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    // Timeframe Card
                    HStack {
                        Image(systemName: "clock.fill")
                        Text(task.timeframe)
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                    
                    // Commands Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Available Commands")
                            .font(.system(size: 20, weight: .bold))
                        
                        ForEach(task.suggestedCommands, id: \.self) { command in
                            Button(action: {}) {
                                HStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Image(systemName: "terminal")
                                                .foregroundColor(.blue)
                                        )
                                    
                                    Text(command)
                                        .font(.system(size: 16))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.system(size: 20, weight: .bold))
                        
                        HStack(spacing: 12) {
                            PetalActionButton(title: "Share", icon: "square.and.arrow.up")
                            PetalActionButton(title: "Calendar", icon: "calendar")
                            PetalActionButton(title: "Reminder", icon: "bell")
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGray6))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
    }
    
    private var iconName: String {
        switch task.type {
        case .research: return "book.fill"
        case .math: return "function"
        case .literature: return "text.book.closed.fill"
        case .science: return "atom"
        case .writing: return "pencil"
        case .study: return "calendar"
        }
    }
}

// MARK: - Supporting Views

struct PetalActionButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                    )
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Preview Provider

struct OpenAppView_Previews: PreviewProvider {
    static var previews: some View {
        OpenAppView()
    }
}
