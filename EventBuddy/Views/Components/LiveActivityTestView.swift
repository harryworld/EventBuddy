import SwiftUI
import ActivityKit

@MainActor
struct LiveActivityTestView: View {
    @State private var currentActivity: Activity<EventBuddyWidgetsAttributes>?
    @State private var isActivityRunning = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Live Activity Demo")
                    .font(.largeTitle)
                    .padding()
                
                if isActivityRunning {
                    VStack(spacing: 10) {
                        Text("✅ Live Activity is running!")
                            .foregroundColor(.green)
                            .font(.headline)
                        
                        Text("Check your Lock Screen or Dynamic Island")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                } else {
                    Text("No Live Activity running")
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 15) {
                    Button("Start Demo Event") {
                        startDemoActivity()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isActivityRunning)
                    
                    Button("Update Progress") {
                        updateActivity()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isActivityRunning)
                    
                    Button("End Event") {
                        endActivity()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isActivityRunning)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Demo Event Details:")
                        .font(.headline)
                    Text("• Event: WWDC25 Keynote")
                    Text("• Location: Apple Park")
                    Text("• This simulates a 2-hour event")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
            .navigationTitle("Live Activity Test")
        }
    }
    
    private func startDemoActivity() {
        let attributes = EventBuddyWidgetsAttributes(
            eventName: "WWDC25 Keynote",
            location: "Apple Park"
        )
        
        let contentState = EventBuddyWidgetsAttributes.ContentState(
            eventStatus: "Starting Soon",
            timeRemaining: "2h 00m",
            progress: 0.0
        )
        
        do {
            let activity = try Activity<EventBuddyWidgetsAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            currentActivity = activity
            isActivityRunning = true
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    private func updateActivity() {
        guard let activity = currentActivity else { return }
        
        let updatedState = EventBuddyWidgetsAttributes.ContentState(
            eventStatus: "In Progress",
            timeRemaining: "1h 15m",
            progress: 0.4
        )
        
        Task {
            await activity.update(using: updatedState)
        }
    }
    
    private func endActivity() {
        guard let activity = currentActivity else { return }
        
        let finalState = EventBuddyWidgetsAttributes.ContentState(
            eventStatus: "Ended",
            timeRemaining: "0m",
            progress: 1.0
        )
        
        Task {
            await activity.end(using: finalState, dismissalPolicy: .immediate)
            currentActivity = nil
            isActivityRunning = false
        }
    }
}

#Preview {
    LiveActivityTestView()
} 