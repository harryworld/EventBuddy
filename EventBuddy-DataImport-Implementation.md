# EventBuddy Data Import Implementation

## Overview

The data import functionality provides users with the ability to restore their EventBuddy data from previously exported backup files. This feature complements the existing export functionality and enables data migration, backup restoration, and data sharing between devices.

## Features Implemented

### 1. **JSON Backup Import**
- **Supported Files**: `eventbuddy_backup.json` files created by the export feature
- **Content**: Complete restoration of:
  - All events with full metadata and timestamps
  - All friends with contact information and social media handles
  - Event-Friend relationships (attendees and wishes)
  - Proper conflict resolution for existing data
- **Format**: ISO8601 date parsing with timezone preservation
- **Use Cases**: Data restoration, device migration, backup recovery

### 2. **Flexible File Selection**
- **Direct JSON Import**: Select `eventbuddy_backup.json` files directly
- **Folder Import**: Select entire export folders (automatically finds the JSON backup)
- **File Picker Integration**: Native iOS file picker with support for Files app, iCloud, and other storage providers

### 3. **Smart Conflict Resolution**
- **Timestamp-Based Updates**: Existing data is only updated if imported data is newer
- **Duplicate Detection**: Automatically detects and skips duplicate entries
- **Relationship Preservation**: Maintains all event-friend relationships without duplication
- **Data Integrity**: Validates all references before import

### 4. **Progress Tracking & User Feedback**
- **Real-time Progress**: Visual progress bar with descriptive status messages
- **Import Summary**: Detailed breakdown of what was imported, updated, or skipped
- **Error Handling**: Comprehensive error messages with recovery options

## Technical Implementation

### Core Components

#### 1. **DataImportService** (`EventBuddy/Services/DataImportService.swift`)
- `@Observable` class for SwiftUI integration
- Async import operations with progress tracking
- Comprehensive error handling and validation
- SwiftData integration for data persistence

#### 2. **DataImportView** (`EventBuddy/Views/Settings/DataImportView.swift`)
- Modern SwiftUI interface matching export design
- File picker integration with multiple content type support
- Progress indicators and status messages
- Import summary display with detailed statistics

#### 3. **ImportSummaryView**
- Detailed breakdown of import results
- Visual indicators for created, updated, and skipped items
- Categorized statistics for events, friends, and relationships

### Data Validation & Integrity

#### Version Compatibility
```swift
// Validates backup version compatibility
guard backup.version == "1.0" else {
    throw ImportError.incompatibleVersion(backup.version)
}
```

#### Reference Validation
- Validates all event and friend ID references in relationships
- Ensures data integrity before import begins
- Prevents orphaned relationships and data corruption

#### Conflict Resolution Strategy
```swift
// Update existing data only if imported data is newer
if dto.updatedAt > existingItem.updatedAt {
    updateItem(existingItem, from: dto)
    summary.itemsUpdated += 1
} else {
    summary.itemsSkipped += 1
}
```

### Import Process Flow

1. **File Selection**: User selects backup file or folder via native file picker
2. **File Validation**: Verify file exists and contains valid JSON backup
3. **Data Parsing**: Parse JSON with ISO8601 date decoding
4. **Backup Validation**: Validate version compatibility and data integrity
5. **Conflict Analysis**: Compare with existing data using timestamps
6. **Data Import**: Create new items and update existing ones as needed
7. **Relationship Import**: Restore all event-friend relationships
8. **Summary Generation**: Provide detailed import statistics

## Data Structure Compatibility

### Supported Import Format
The import feature supports the exact same JSON structure as the export feature:

```json
{
  "exportDate": "2025-01-29T20:00:00Z",
  "version": "1.0",
  "events": [...],
  "friends": [...],
  "relationships": {
    "eventAttendees": [...],
    "eventWishes": [...]
  }
}
```

### Timestamp Preservation
- Original `createdAt` and `updatedAt` timestamps are preserved
- Enables accurate conflict resolution
- Maintains data history and audit trail

## User Interface

### Import Flow
1. **Settings → Import Data** - Access import functionality
2. **File Selection** - Choose backup file or export folder
3. **Progress Tracking** - Real-time import progress with status
4. **Import Summary** - Detailed results with statistics
5. **Completion** - Success confirmation with option to view details

### Import States
- **Ready**: Initial state with file selection button
- **Importing**: Progress bar with descriptive status messages
- **Complete**: Success state with summary and action buttons
- **Error**: Error handling with clear messages and retry options

## Error Handling

### Comprehensive Error Types
```swift
enum ImportError: LocalizedError {
    case fileNotFound
    case invalidFormat(String)
    case incompatibleVersion(String)
    case dataCorruption
    case permissionDenied
}
```

### User-Friendly Error Messages
- Clear descriptions of what went wrong
- Actionable guidance for resolution
- Graceful degradation for partial failures

## Import Statistics

### Detailed Tracking
```swift
struct ImportSummary {
    var eventsCreated = 0
    var eventsUpdated = 0
    var eventsSkipped = 0
    var friendsCreated = 0
    var friendsUpdated = 0
    var friendsSkipped = 0
    var relationshipsCreated = 0
}
```

### Visual Summary
- Color-coded statistics (green for created, blue for updated, gray for skipped)
- Total change count for quick overview
- Detailed breakdown by category

## Privacy & Security

- **Local Processing**: All import operations happen locally on device
- **No External Servers**: No data sent to external services during import
- **File Access**: Uses iOS secure file access APIs
- **Data Validation**: Comprehensive validation prevents malicious data injection

## Usage Instructions

### For Users
1. Navigate to **Settings** tab
2. Tap **Import Data**
3. Tap **Select Backup File**
4. Choose your backup file or export folder from Files app
5. Wait for import completion
6. Review import summary
7. Tap **Done** to finish

### Supported File Sources
- **Files App**: Local device storage
- **iCloud Drive**: Cloud-stored backups
- **Third-party Storage**: Dropbox, Google Drive, etc. (via Files app)
- **AirDrop**: Received backup files
- **Email Attachments**: Backup files from email

## Integration with Settings

### Settings Menu Addition
The import feature is seamlessly integrated into the existing Settings data section:

```swift
NavigationLink {
    DataImportView()
} label: {
    Label("Import Data", systemImage: "square.and.arrow.down")
}
```

## Testing & Validation

### Test Scenarios
1. **Fresh Import**: Import into empty app
2. **Partial Overlap**: Import with some existing data
3. **Complete Overlap**: Import identical data (should skip all)
4. **Mixed Updates**: Import with newer and older data
5. **Corrupted Files**: Test error handling with invalid files
6. **Large Datasets**: Performance testing with substantial data

### Validation Checks
- Data integrity after import
- Relationship consistency
- Timestamp preservation
- Duplicate prevention
- Error recovery

## Performance Considerations

### Async Operations
- All import operations are asynchronous to prevent UI blocking
- Progress tracking provides user feedback during long operations
- Memory-efficient processing for large datasets

### Batch Processing
- Friends imported before events (dependency order)
- Relationships processed after all entities exist
- Single save operation at the end for optimal performance

## Future Enhancements

### Planned Features
- **Selective Import**: Choose specific events or friends to import
- **Merge Strategies**: Different conflict resolution options
- **Import History**: Track previous imports and their results
- **Backup Validation**: Pre-import validation with detailed reports

### Advanced Options
- **Date Range Filtering**: Import only events within specific date ranges
- **Category Filtering**: Import only specific event types
- **Friend Filtering**: Import only favorite friends or specific groups

## Technical Notes

### Dependencies
- SwiftData for data persistence
- SwiftUI for user interface
- UniformTypeIdentifiers for file type handling
- Foundation for file operations and JSON parsing

### Error Recovery
- Transactional imports (all-or-nothing for data integrity)
- Rollback capability for failed imports
- Detailed error logging for debugging

### Memory Management
- Streaming JSON parsing for large files
- Efficient data structures for import processing
- Automatic cleanup of temporary data

## Conclusion

The data import feature provides a robust, user-friendly solution for restoring EventBuddy data from backups. It maintains data integrity, provides excellent user feedback, and integrates seamlessly with the existing app architecture. The implementation follows iOS best practices and provides a solid foundation for future enhancements while ensuring reliability and ease of use.

## File Structure

```
EventBuddy/
├── Services/
│   ├── DataExportService.swift (existing)
│   └── DataImportService.swift (new)
├── Views/Settings/
│   ├── SettingsView.swift (updated)
│   ├── DataExportView.swift (existing)
│   └── DataImportView.swift (new)
└── Documentation/
    ├── EventBuddy-DataExport-Implementation.md (existing)
    └── EventBuddy-DataImport-Implementation.md (new)
``` 