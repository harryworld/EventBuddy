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

    static let createStoredEventsTableSQL = """
        CREATE TABLE IF NOT EXISTS "\(storedEventsTableName)" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
          "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
          "eventDescription" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
          "location" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
          "address" TEXT,
          "startDate" TEXT NOT NULL ON CONFLICT REPLACE,
          "endDate" TEXT NOT NULL ON CONFLICT REPLACE,
          "eventType" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'Social',
          "notes" TEXT,
          "requiresTicket" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
          "requiresRegistration" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
          "url" TEXT,
          "createdAt" TEXT NOT NULL ON CONFLICT REPLACE,
          "updatedAt" TEXT NOT NULL ON CONFLICT REPLACE,
          "isAttending" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
          "originalTimezoneIdentifier" TEXT,
          "isCustomEvent" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1
        ) STRICT
        """

    static let createStoredFriendsTableSQL = """
        CREATE TABLE IF NOT EXISTS "\(storedFriendsTableName)" (
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

    static let createStoredProfilesTableSQL = """
        CREATE TABLE IF NOT EXISTS "\(storedProfilesTableName)" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
          "name" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
          "bio" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
          "email" TEXT,
          "phone" TEXT,
          "profileImage" BLOB,
          "socialMediaAccountsJSON" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '{}',
          "preferencesJSON" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '{}',
          "createdAt" TEXT NOT NULL ON CONFLICT REPLACE,
          "updatedAt" TEXT NOT NULL ON CONFLICT REPLACE,
          "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
          "company" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
          "avatarSystemName" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'person.crop.circle.fill'
        ) STRICT
        """

    static let createStoredEventAttendeesTableSQL = """
        CREATE TABLE IF NOT EXISTS "\(storedEventAttendeesTableName)" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
          "eventID" TEXT NOT NULL ON CONFLICT REPLACE REFERENCES "\(storedEventsTableName)"("id") ON DELETE CASCADE,
          "friendID" TEXT NOT NULL ON CONFLICT REPLACE REFERENCES "\(storedFriendsTableName)"("id") ON DELETE CASCADE
        ) STRICT
        """

    static let createStoredEventWishesTableSQL = """
        CREATE TABLE IF NOT EXISTS "\(storedEventWishesTableName)" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
          "eventID" TEXT NOT NULL ON CONFLICT REPLACE REFERENCES "\(storedEventsTableName)"("id") ON DELETE CASCADE,
          "friendID" TEXT NOT NULL ON CONFLICT REPLACE REFERENCES "\(storedFriendsTableName)"("id") ON DELETE CASCADE
        ) STRICT
        """
}
