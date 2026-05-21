import Foundation

enum EventBuddyStorageConfiguration {
    static let appGroupIdentifier = "group.com.buildwithharry.EventBuddy"
    static let cloudKitContainerIdentifier = "iCloud.com.buildwithharry.EventBuddy"
    static let databaseFileName = "EventBuddy.sqlite"

    static let storedEventsTableName = "storedEvents"
    static let storedFriendsTableName = "storedFriends"
    static let storedProfilesTableName = "storedProfiles"
    static let storedEventAttendeesTableName = "storedEventAttendees"
    static let storedEventWishesTableName = "storedEventWishes"

    static let createStoredFriendsTableSQL = """
        CREATE TABLE "\(storedFriendsTableName)" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
          "name" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
          "email" TEXT,
          "phone" TEXT,
          "jobTitle" TEXT,
          "company" TEXT,
          "socialMediaHandlesJSON" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '{}',
          "notes" TEXT,
          "createdAt" TEXT NOT NULL ON CONFLICT REPLACE,
          "updatedAt" TEXT NOT NULL ON CONFLICT REPLACE,
          "isFavorite" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
        ) STRICT
        """
}
