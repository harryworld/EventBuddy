export interface EventRow {
  id: string;
  title: string;
  eventDescription: string;
  location: string;
  address: string | null;
  startDate: string;
  endDate: string;
  eventType: string;
  notes: string | null;
  requiresTicket: boolean;
  requiresRegistration: boolean;
  url: string | null;
  createdAt: string;
  updatedAt: string;
  isAttending: boolean;
  originalTimezoneIdentifier: string | null;
  isCustomEvent: boolean;
}

export interface FriendRow {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  jobTitle: string | null;
  company: string | null;
  socialMediaHandles: Record<string, string>;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
  isFavorite: boolean;
}

export type RelationshipKind = "attending" | "wish";

export interface RelationRow {
  id: string;
  kind: RelationshipKind;
  eventId: string;
  eventTitle: string | null;
  friendId: string;
  friendName: string | null;
}

export interface CommandResponse {
  status?: string;
  message?: string;
  payload?: unknown;
}
