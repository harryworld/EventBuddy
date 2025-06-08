import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var importService: DataImportService?
    @State private var showingFilePicker = false
    @State private var showingImportSummary = false
    @State private var showingError = false
    @State private var importResult: ImportResult?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    Text("Import Your Data")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Restore your events, friends, and relationships from a backup file")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Import content
                VStack(spacing: 20) {
                    if let importService = importService {
                        if importService.isImporting {
                            importingView(importService)
                        } else if let result = importResult {
                            importCompleteView(result)
                        } else {
                            importReadyView
                        }
                    } else {
                        importReadyView
                    }
                }
                
                Spacer()
                
                // Import info
                importInfoSection
            }
            .padding()
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if importService == nil {
                    importService = DataImportService(modelContext: modelContext)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [
                    .json,
                    .folder,
                    UTType(filenameExtension: "json") ?? .json,
                    .plainText
                ],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Import Error", isPresented: $showingError) {
                Button("OK") {
                    resetImport()
                }
            } message: {
                Text(importService?.importError ?? "An unknown error occurred")
            }
            .sheet(isPresented: $showingImportSummary) {
                if let result = importResult {
                    ImportSummaryView(result: result) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var importReadyView: some View {
        VStack(spacing: 16) {
            Button {
                showingFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Select Backup File")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text("Select a backup file to import:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                importItemRow(icon: "doc.text", title: "JSON backup file", description: "eventbuddy_backup.json")
                importItemRow(icon: "folder", title: "Export folder", description: "Complete export directory")
            }
            .padding()
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func importingView(_ importService: DataImportService) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: importService.importProgress) {
                Text("Importing your data...")
                    .font(.headline)
            }
            .progressViewStyle(LinearProgressViewStyle())
            
            Text(progressMessage(for: importService.importProgress))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func importCompleteView(_ result: ImportResult) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)
            
            Text("Import Complete!")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                if result.summary.totalChanges > 0 {
                    Text("Successfully imported \(result.summary.totalChanges) items")
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No new data to import")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                Text("• \(result.summary.eventsCreated) events created")
                Text("• \(result.summary.friendsCreated) friends created")
                Text("• \(result.summary.relationshipsCreated) relationships created")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                Button {
                    showingImportSummary = true
                } label: {
                    Text("View Details")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    private var importInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Import Information", systemImage: "info.circle")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Supports JSON backup files from EventBuddy exports")
                Text("• Existing data will be updated if newer versions are found")
                Text("• Duplicate data will be automatically detected and skipped")
                Text("• All relationships between events and friends are preserved")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func importItemRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            startImport(from: url)
        case .failure(let error):
            importService?.importError = error.localizedDescription
            showingError = true
        }
    }
    
    private func startImport(from url: URL) {
        guard let importService = importService else { return }
        
        Task {
            let result = await importService.importData(from: url)
            
            await MainActor.run {
                if let result = result {
                    importResult = result
                } else {
                    showingError = true
                }
            }
        }
    }
    
    private func resetImport() {
        importResult = nil
        importService?.importError = nil
    }
    
    private func progressMessage(for progress: Double) -> String {
        switch progress {
        case 0.0..<0.2:
            return "Reading backup file..."
        case 0.2..<0.4:
            return "Validating data integrity..."
        case 0.4..<0.6:
            return "Importing friends..."
        case 0.6..<0.8:
            return "Importing events..."
        case 0.8..<1.0:
            return "Creating relationships..."
        default:
            return "Finalizing import..."
        }
    }
}

// MARK: - Import Summary View

struct ImportSummaryView: View {
    let result: ImportResult
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.green)
                        
                        Text("Import Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Imported on \(result.importDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Summary sections
                    if result.summary.totalEvents > 0 {
                        summarySection(
                            title: "Events",
                            icon: "calendar",
                            created: result.summary.eventsCreated,
                            updated: result.summary.eventsUpdated,
                            skipped: result.summary.eventsSkipped
                        )
                    }
                    
                    if result.summary.totalFriends > 0 {
                        summarySection(
                            title: "Friends",
                            icon: "person.2",
                            created: result.summary.friendsCreated,
                            updated: result.summary.friendsUpdated,
                            skipped: result.summary.friendsSkipped
                        )
                    }
                    
                    if result.summary.relationshipsCreated > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Relationships", systemImage: "link")
                                .font(.headline)
                            
                            HStack {
                                Text("Created:")
                                Spacer()
                                Text("\(result.summary.relationshipsCreated)")
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Total summary
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Total Changes", systemImage: "sum")
                            .font(.headline)
                        
                        Text("\(result.summary.totalChanges) items imported successfully")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Import Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func summarySection(
        title: String,
        icon: String,
        created: Int,
        updated: Int,
        skipped: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Created:")
                    Spacer()
                    Text("\(created)")
                        .fontWeight(.medium)
                        .foregroundStyle(created > 0 ? .green : .secondary)
                }
                
                HStack {
                    Text("Updated:")
                    Spacer()
                    Text("\(updated)")
                        .fontWeight(.medium)
                        .foregroundStyle(updated > 0 ? .blue : .secondary)
                }
                
                HStack {
                    Text("Skipped:")
                    Spacer()
                    Text("\(skipped)")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DataImportView()
        .modelContainer(for: [Event.self, Friend.self])
} 