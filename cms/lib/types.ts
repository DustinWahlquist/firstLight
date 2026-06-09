export type SpeciesStatus = 'new' | 'needs_review' | 'draft' | 'published'

export interface ArtByLevel {
  1: string | null
  2: string | null
  3: string | null
  4: string | null
  5: string | null
}

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

export interface Species {
  id: string
  speciesName: string
  scientificName: string
  status: SpeciesStatus
  description: string
  facts: string[]
  migrationSpeed: number
  speedDelta: number
  endurance: number
  enduranceDelta: number
  artByLevel: ArtByLevel
  moves: Move[]
  reports: Report[]
}

export interface StatsData {
  totalUsers: number
  newUsersThisWeek: number
  totalCatches: number
  catchesThisWeek: number
  avgCatchesPerUser: number
  openReports: number
  totalReports: number
  avgResolutionDays: number
  weeklySignups: number[]
  weekLabels: string[]
  mostCaught: { name: string; count: number }[]
  cardLevelDist: { level: string; count: number }[]
  pecksPerWeek: number[]
  scribblesPerWeek: number[]
  reportVolume: number[]
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
