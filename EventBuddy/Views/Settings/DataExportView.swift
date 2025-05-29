import SwiftUI
import SwiftData

struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var exportService: DataExportService?
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("Export Your Data")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Create a backup of all your events, friends, and their relationships")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Export content
                VStack(spacing: 20) {
                    if let exportService = exportService {
                        if exportService.isExporting {
                            exportingView(exportService)
                        } else if exportURL != nil {
                            exportCompleteView
                        } else {
                            exportReadyView
                        }
                    } else {
                        exportReadyView
                    }
                }
                
                Spacer()
                
                // Export info
                exportInfoSection
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if exportService == nil {
                    exportService = DataExportService(modelContext: modelContext)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    DataExportShareSheet(items: [url])
                }
            }
            .alert("Export Error", isPresented: $showingError) {
                Button("OK") { }
                Button("Try Again") {
                    startExport()
                }
            } message: {
                Text(exportService?.exportError ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - View Components
    
    private var exportReadyView: some View {
        VStack(spacing: 16) {
            Button {
                startExport()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export All Data")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text("This will create an archive containing:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                exportItemRow(icon: "doc.text", title: "Complete JSON backup", description: "All data with relationships")
                exportItemRow(icon: "tablecells", title: "Events CSV file", description: "Spreadsheet-friendly format")
                exportItemRow(icon: "person.2", title: "Friends CSV file", description: "Contact information")
                exportItemRow(icon: "info.circle", title: "README file", description: "Export information")
            }
            .padding()
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func exportingView(_ exportService: DataExportService) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: exportService.exportProgress) {
                Text("Exporting your data...")
                    .font(.headline)
            }
            .progressViewStyle(LinearProgressViewStyle())
            
            Text(progressMessage(for: exportService.exportProgress))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var exportCompleteView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)
            
            Text("Export Complete!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your data has been successfully exported and is ready to share.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Export")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button {
                resetExport()
            } label: {
                Text("Export Again")
                    .font(.body)
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
    }
    
    private var exportInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Export Information", systemImage: "info.circle")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• JSON format preserves all data and relationships")
                Text("• CSV files can be opened in Excel or Google Sheets")
                Text("• Export includes timestamps and metadata")
                Text("• No personal data is sent to external servers")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func exportItemRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
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
    
    private func startExport() {
        guard let exportService = exportService else { return }
        
        Task {
            let result = await exportService.exportAllData()
            
            await MainActor.run {
                if let url = result {
                    exportURL = url
                } else {
                    showingError = true
                }
            }
        }
    }
    
    private func resetExport() {
        exportURL = nil
        exportService?.exportError = nil
    }
    
    private func progressMessage(for progress: Double) -> String {
        switch progress {
        case 0.0..<0.2:
            return "Preparing export..."
        case 0.2..<0.5:
            return "Creating JSON backup..."
        case 0.5..<0.7:
            return "Exporting events to CSV..."
        case 0.7..<0.9:
            return "Exporting friends to CSV..."
        case 0.9..<1.0:
            return "Creating archive..."
        default:
            return "Finalizing export..."
        }
    }
}

struct DataExportShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Customize for better UX
        controller.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo,
            .postToWeibo
        ]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DataExportView()
        .modelContainer(for: [Event.self, Friend.self])
} 