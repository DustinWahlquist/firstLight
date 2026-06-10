import { createClient } from './supabase'
import {
  ArtByLevel, EMPTY_ART, Move, Report, Species, SpeciesStatus,
  SpeciesSummary, StatsData, SuspiciousUser,
} from './types'

// Single boundary between the UI (camelCase domain types) and the
// database (snake_case rows). All Supabase queries live here.

const supabase = () => createClient()

// ── Row mappers ─────────────────────────────────────────────────────

function artFromRow(json: Record<string, string> | null): ArtByLevel {
  const art = { ...EMPTY_ART }
  for (const level of [1, 2, 3, 4, 5] as const) {
    art[level] = json?.[String(level)] ?? null
  }
  return art
}

function artToRow(art: ArtByLevel): Record<string, string> {
  const json: Record<string, string> = {}
  for (const level of [1, 2, 3, 4, 5] as const) {
    if (art[level]) json[String(level)] = art[level]!
  }
  return json
}

function moveFromRow(r: Record<string, unknown>): Move {
  return {
    id: r.id as string,
    moveName: (r.move_name as string) ?? '',
    category: (r.category as Move['category']) ?? 'Offense',
    description: (r.description as string) ?? '',
    effectType: (r.effect_type as string) ?? '',
    effectValue: (r.effect_value as number) ?? 0,
    unlockLevel: (r.unlock_level as Move['unlockLevel']) ?? 1,
  }
}

function speciesFromRow(
  r: Record<string, unknown>,
  reporterNames: Map<string, string> = new Map(),
): Species {
  const reports = ((r.species_reports as Record<string, unknown>[]) ?? [])
    .map((rep): Report => ({
      id: rep.id as string,
      user: reporterNames.get(rep.user_id as string) ?? 'Unknown user',
      message: (rep.message as string) ?? '',
      createdAt: rep.created_at as string,
      resolved: (rep.resolved as boolean) ?? false,
    }))
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt))

  return {
    speciesName: r.species_name as string,
    scientificName: (r.scientific_name as string) ?? '',
    status: (r.status as SpeciesStatus) ?? 'new',
    description: (r.description as string) ?? '',
    facts: (r.facts as string[]) ?? [],
    migrationSpeed: (r.migration_speed as number) ?? 5,
    speedDelta: (r.speed_delta as number) ?? 0,
    endurance: (r.endurance as number) ?? 3,
    enduranceDelta: (r.endurance_delta as number) ?? 0,
    lineArtUrl: (r.line_art_url as string) ?? null,
    artByLevel: artFromRow(r.art_by_level as Record<string, string> | null),
    moves: ((r.species_moves as Record<string, unknown>[]) ?? [])
      .map(moveFromRow)
      .sort((a, b) => a.unlockLevel - b.unlockLevel),
    reports,
  }
}

function speciesToRow(s: Species): Record<string, unknown> {
  return {
    species_name: s.speciesName,
    scientific_name: s.scientificName,
    status: s.status,
    description: s.description,
    facts: s.facts,
    migration_speed: s.migrationSpeed,
    speed_delta: s.speedDelta,
    endurance: s.endurance,
    endurance_delta: s.enduranceDelta,
    art_by_level: artToRow(s.artByLevel),
  }
}

// ── Species ─────────────────────────────────────────────────────────

export async function listSpecies(opts: {
  status?: SpeciesStatus | ''
  search?: string
}): Promise<SpeciesSummary[]> {
  let q = supabase()
    .from('bird_species')
    .select('species_name, scientific_name, status, species_reports(resolved)')
    .order('species_name', { ascending: true })
  if (opts.status) q = q.eq('status', opts.status)
  if (opts.search) q = q.ilike('species_name', `%${opts.search}%`)

  const { data, error } = await q
  if (error) throw error
  return (data ?? []).map(r => ({
    speciesName: r.species_name,
    scientificName: r.scientific_name ?? '',
    status: (r.status as SpeciesStatus) ?? 'new',
    openReports: (r.species_reports ?? []).filter((rep: { resolved: boolean }) => !rep.resolved).length,
  }))
}

export async function fetchSpecies(speciesName: string): Promise<Species | null> {
  const { data, error } = await supabase()
    .from('bird_species')
    .select('*, species_moves(*), species_reports(*)')
    .eq('species_name', speciesName)
    .maybeSingle()
  if (error) throw error
  if (!data) return null

  const reporterIds = [...new Set(
    ((data.species_reports as { user_id: string | null }[]) ?? [])
      .map(r => r.user_id)
      .filter((id): id is string => id != null),
  )]
  const reporterNames = new Map<string, string>()
  if (reporterIds.length > 0) {
    const { data: profiles } = await supabase()
      .from('profiles')
      .select('id, display_name, username')
      .in('id', reporterIds)
    for (const p of profiles ?? []) {
      reporterNames.set(p.id, p.display_name ?? p.username ?? 'Unknown user')
    }
  }
  return speciesFromRow(data, reporterNames)
}

export async function createSpecies(s: Species): Promise<void> {
  const { error } = await supabase().from('bird_species').insert(speciesToRow(s))
  if (error) throw error
  await syncMoves(s.speciesName, s.moves)
}

export async function updateSpecies(s: Species): Promise<void> {
  const { error } = await supabase()
    .from('bird_species')
    .update(speciesToRow(s))
    .eq('species_name', s.speciesName)
  if (error) throw error
  await syncMoves(s.speciesName, s.moves)
}

/** Replace the species' moves with the given set. */
async function syncMoves(speciesName: string, moves: Move[]): Promise<void> {
  const client = supabase()
  const { error: deleteError } = await client
    .from('species_moves')
    .delete()
    .eq('species_name', speciesName)
  if (deleteError) throw deleteError
  if (moves.length === 0) return
  const { error } = await client.from('species_moves').insert(
    moves.map(m => ({
      species_name: speciesName,
      move_name: m.moveName,
      category: m.category,
      description: m.description,
      effect_type: m.effectType,
      effect_value: m.effectValue,
      unlock_level: m.unlockLevel,
    })),
  )
  if (error) throw error
}

export async function bulkUpdateStatus(
  speciesNames: string[],
  status: SpeciesStatus,
): Promise<void> {
  const { error } = await supabase()
    .from('bird_species')
    .update({ status })
    .in('species_name', speciesNames)
  if (error) throw error
}

export async function resolveReport(reportId: string): Promise<void> {
  const { error } = await supabase()
    .from('species_reports')
    .update({ resolved: true })
    .eq('id', reportId)
  if (error) throw error
}

// ── Art uploads ─────────────────────────────────────────────────────

const slugify = (name: string) =>
  name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '')

export async function uploadArt(
  speciesName: string,
  level: number,
  file: File,
): Promise<string> {
  const ext = file.name.split('.').pop()?.toLowerCase() ?? 'svg'
  const path = `${slugify(speciesName)}/level_${level}.${ext}`
  const client = supabase()
  const { error } = await client.storage
    .from('species-art')
    .upload(path, file, { upsert: true, contentType: file.type || undefined })
  if (error) throw error
  // Cache-bust: the path is stable across re-uploads
  return `${client.storage.from('species-art').getPublicUrl(path).data.publicUrl}?v=${Date.now()}`
}

// ── Stats ───────────────────────────────────────────────────────────

const DAY_MS = 24 * 60 * 60 * 1000

export async function fetchStats(): Promise<StatsData> {
  const client = supabase()
  const [speciesRes, profilesRes, cardsRes, logsRes, reportsRes] = await Promise.all([
    client.from('bird_species').select('species_name, status'),
    client.from('profiles').select('id, created_at'),
    client.from('bird_cards').select('id, user_id, species_name, xp, level, catch_count'),
    client.from('catch_logs').select('user_id, bird_card_id, caught_at, xp_awarded'),
    client.from('species_reports').select('id, resolved'),
  ])
  for (const res of [speciesRes, profilesRes, cardsRes, logsRes, reportsRes]) {
    if (res.error) throw res.error
  }
  const species = speciesRes.data ?? []
  const profiles = profilesRes.data ?? []
  const cards = cardsRes.data ?? []
  const logs = logsRes.data ?? []
  const reports = reportsRes.data ?? []

  const speciesByStatus: StatsData['speciesByStatus'] =
    { new: 0, needs_review: 0, draft: 0, published: 0 }
  for (const s of species) {
    speciesByStatus[(s.status as SpeciesStatus) ?? 'new']++
  }

  const now = Date.now()
  const weekAgo = now - 7 * DAY_MS
  const newUsersThisWeek = profiles
    .filter(p => new Date(p.created_at).getTime() > weekAgo).length

  const dailyCatches = Array(7).fill(0) as number[]
  const dayLabels: string[] = []
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  for (let i = 6; i >= 0; i--) {
    const day = new Date(today.getTime() - i * DAY_MS)
    dayLabels.push(['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'][day.getDay()])
  }
  let catchesThisWeek = 0
  for (const log of logs) {
    const t = new Date(log.caught_at).getTime()
    if (t <= weekAgo) continue
    catchesThisWeek++
    const daysAgo = Math.floor((today.getTime() + DAY_MS - t) / DAY_MS)
    if (daysAgo >= 0 && daysAgo < 7) dailyCatches[6 - daysAgo]++
  }

  const catchesBySpecies = new Map<string, number>()
  for (const c of cards) {
    catchesBySpecies.set(
      c.species_name,
      (catchesBySpecies.get(c.species_name) ?? 0) + c.catch_count,
    )
  }
  const mostCaught = [...catchesBySpecies.entries()]
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 5)

  const cardLevelDist = [1, 2, 3, 4, 5].map(level => ({
    level: `Lv ${level}`,
    count: cards.filter(c => c.level === level).length,
  }))

  return {
    speciesTotal: species.length,
    speciesByStatus,
    totalUsers: profiles.length,
    newUsersThisWeek,
    totalCatches: logs.length,
    catchesThisWeek,
    dailyCatches,
    dayLabels,
    mostCaught,
    cardLevelDist,
    openReports: reports.filter(r => !r.resolved).length,
    suspiciousUsers: findSuspiciousUsers(cards, logs),
  }
}

/** Flags same-day duplicate catches and card XP that doesn't match the
 *  catch log — both signals of the client-side rules being bypassed. */
function findSuspiciousUsers(
  cards: { id: string; user_id: string; xp: number; catch_count: number; species_name: string }[],
  logs: { user_id: string; bird_card_id: string; caught_at: string; xp_awarded: number }[],
): SuspiciousUser[] {
  const dupesByUser = new Map<string, number>()
  const seen = new Set<string>()
  for (const log of logs) {
    const key = `${log.bird_card_id}|${log.caught_at.slice(0, 10)}`
    if (seen.has(key)) {
      dupesByUser.set(log.user_id, (dupesByUser.get(log.user_id) ?? 0) + 1)
    }
    seen.add(key)
  }

  const xpByCard = new Map<string, number>()
  for (const log of logs) {
    xpByCard.set(log.bird_card_id, (xpByCard.get(log.bird_card_id) ?? 0) + log.xp_awarded)
  }
  const xpMismatchUsers = new Set<string>()
  for (const card of cards) {
    if (card.xp !== (xpByCard.get(card.id) ?? 0)) xpMismatchUsers.add(card.user_id)
  }

  const flagged = new Set([...dupesByUser.keys(), ...xpMismatchUsers])
  return [...flagged].map(userId => {
    const userCards = cards.filter(c => c.user_id === userId)
    const dupes = dupesByUser.get(userId) ?? 0
    const notes: string[] = []
    if (dupes > 0) notes.push('Same-day duplicate catches')
    if (xpMismatchUsers.has(userId)) notes.push('Card XP inconsistent with catch log')
    return {
      user: userId,
      catches: logs.filter(l => l.user_id === userId).length,
      uniqueSpecies: userCards.length,
      dupes,
      note: notes.join(' · '),
    }
  })
}
