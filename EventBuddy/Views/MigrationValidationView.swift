import SwiftUI

struct MigrationValidationView: View {
    @Environment(AppStore.self) private var appStore

    let mode: MigrationValidationMode

    @State private var phase: Phase = .loading

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .loading:
                    ProgressView("Preparing \(mode.title)...")
                        .controlSize(.large)
                case .legacy(let snapshot):
                    validationContent(
                        title: "SwiftData Baseline",
                        subtitle: "Sample data written into the legacy SwiftData store before migration.",
                        snapshot: snapshot,
                        comparison: nil
                    )
                case .sqlite(let comparison):
                    validationContent(
                        title: "SQLite Migration Result",
                        subtitle: comparison.matchesExactly
                            ? "SQLiteData matches the seeded SwiftData snapshot."
                            : "Mismatch detected between SwiftData and SQLiteData.",
                        snapshot: comparison.sqlite,
                        comparison: comparison
                    )
                case .failure(let message):
                    ContentUnavailableView("Migration Validation Failed", systemImage: "exclamationmark.triangle", description: Text(message))
                }
            }
            .padding()
            .navigationTitle(mode.title)
            .task {
                await runScenario()
            }
        }
    }

    @ViewBuilder
    private func validationContent(
        title: String,
        subtitle: String,
        snapshot: MigrationSnapshot,
        comparison: MigrationComparison?
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.largeTitle.bold())
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let comparison {
                    HStack(spacing: 12) {
                        metricCard(
                            title: "Match",
                            value: comparison.matchesExactly ? "PASS" : "FAIL",
                            tint: comparison.matchesExactly ? .green : .red
                        )
                        metricCard(title: "SwiftData", value: comparison.legacy.digest, tint: .blue)
                        metricCard(title: "SQLite", value: comparison.sqlite.digest, tint: .indigo)
                    }
                } else {
                    HStack(spacing: 12) {
                        metricCard(title: "Digest", value: snapshot.digest, tint: .blue)
                        metricCard(title: "Events", value: "\(snapshot.events.count)", tint: .orange)
                        metricCard(title: "Friends", value: "\(snapshot.friends.count)", tint: .green)
                    }
                }

                HStack(spacing: 12) {
                    metricCard(title: "Profile", value: "\(snapshot.profileCount)", tint: .purple)
                    metricCard(title: "Attendee Links", value: "\(snapshot.attendeeLinkCount)", tint: .teal)
                    metricCard(title: "Wish Links", value: "\(snapshot.wishLinkCount)", tint: .pink)
                }

                if let profile = snapshot.profile {
                    sectionCard("Profile") {
                        LabeledContent("Name", value: profile.name)
                        LabeledContent("Role", value: "\(profile.title) @ \(profile.company)")
                        LabeledContent("Email", value: profile.email ?? "None")
                    }
                }

                sectionCard("Friends") {
                    ForEach(snapshot.friends) { friend in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(friend.name)
                                    .font(.headline)
                                if friend.isFavorite {
                                    Text("Favorite")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.yellow.opacity(0.2), in: Capsule())
                                }
                            }
                            Text("\(friend.jobTitle ?? "Unknown role") • \(friend.company ?? "Unknown company")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if friend.id != snapshot.friends.last?.id {
                            Divider()
                        }
                    }
                }

                sectionCard("Events") {
                    ForEach(snapshot.events) { event in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(event.title)
                                    .font(.headline)
                                Spacer()
                                Text(event.isAttending ? "Attending" : "Not Attending")
                                    .font(.caption.bold())
                                    .foregroundStyle(event.isAttending ? .green : .secondary)
                            }
                            Text(event.location)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            relationLine("People Met", ids: event.attendeeIDs, snapshot: snapshot)
                            relationLine("Friend Wishes", ids: event.wishIDs, snapshot: snapshot)
                        }
                        if event.id != snapshot.events.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metricCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospaced())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sectionCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func relationLine(_ label: String, ids: [UUID], snapshot: MigrationSnapshot) -> some View {
        let names = ids.compactMap { id in
            snapshot.friends.first(where: { $0.id == id })?.name
        }
        return LabeledContent(label, value: names.isEmpty ? "None" : names.joined(separator: ", "))
            .font(.footnote)
    }

    @MainActor
    private func runScenario() async {
        do {
            switch mode {
            case .legacyBaseline:
                let snapshot = try LegacySwiftDataStore.seedFixture()
                phase = .legacy(snapshot)
            case .sqliteMigrated:
                let comparison = try SQLiteMigrationValidator.migrateLegacyStoreToSQLite(appStore: appStore)
                phase = .sqlite(comparison)
            }
        } catch {
            phase = .failure(error.localizedDescription)
        }
    }
}

private extension MigrationValidationView {
    enum Phase {
        case loading
        case legacy(MigrationSnapshot)
        case sqlite(MigrationComparison)
        case failure(String)
    }
}
