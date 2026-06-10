export type SpeciesStatus = 'new' | 'needs_review' | 'draft' | 'published'

export interface ArtByLevel {
  1: string | null
  2: string | null
  3: string | null
  4: string | null
  5: string | null
}

export const EMPTY_ART: ArtByLevel = { 1: null, 2: null, 3: null, 4: null, 5: null }

export interface Move {
  id?: string
  moveName: string
  category: 'Offense' | 'Defense' | 'Support'
  description: string
  effectType: string
  effectValue: number
  unlockLevel: 1 | 3 | 5
}

export interface Report {
  id: string
  user: string
  message: string
  createdAt: string
  resolved: boolean
}

/** Species content row. speciesName is the primary key shared with the app. */
export interface Species {
  speciesName: string
  scientificName: string
  status: SpeciesStatus
  description: string
  facts: string[]
  migrationSpeed: number
  speedDelta: number
  endurance: number
  enduranceDelta: number
  lineArtUrl: string | null
  artByLevel: ArtByLevel
  moves: Move[]
  reports: Report[]
}

/** Lightweight row for the species table. */
export interface SpeciesSummary {
  speciesName: string
  scientificName: string
  status: SpeciesStatus
  openReports: number
}

export interface SuspiciousUser {
  user: string
  catches: number
  uniqueSpecies: number
  dupes: number
  note: string
}

export interface StatsData {
  speciesTotal: number
  speciesByStatus: Record<SpeciesStatus, number>
  totalUsers: number
  newUsersThisWeek: number
  publicProfiles: number
  notificationsOn: number
  totalCatches: number
  catchesThisWeek: number
  dailyCatches: number[]
  dayLabels: string[]
  mostCaught: { name: string; count: number }[]
  cardLevelDist: { level: string; count: number }[]
  openReports: number
  suspiciousUsers: SuspiciousUser[]
}

export const STATUS_META: Record<SpeciesStatus, {
  label: string; bg: string; text: string; border: string; dot: string
}> = {
  needs_review: { label: 'Needs Review', bg: '#FEF2F2', text: '#991B1B', border: '#FECACA', dot: '#EF4444' },
  new:          { label: 'New',          bg: '#FFFBEB', text: '#92400E', border: '#FDE68A', dot: '#F59E0B' },
  draft:        { label: 'Draft',        bg: '#F8FAFC', text: '#475569', border: '#CBD5E1', dot: '#94A3B8' },
  published:    { label: 'Published',    bg: '#F0FDF4', text: '#166534', border: '#BBF7D0', dot: '#22C55E' },
}

export const STATUS_ORDER: Record<SpeciesStatus, number> = {
  needs_review: 0, new: 1, draft: 2, published: 3,
}
