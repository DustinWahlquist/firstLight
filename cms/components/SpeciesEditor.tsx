'use client'
import { useState, useEffect, use, useRef } from 'react'
import { useRouter } from 'next/navigation'
import {
  createSpecies, fetchSpecies, resolveReport, updateSpecies, uploadArt,
} from '@/lib/api'
import { ArtByLevel, EMPTY_ART, Move, Species, SpeciesStatus, STATUS_META } from '@/lib/types'

const STAT_LEVELS = [1, 2, 3, 4, 5] as const

function StatusBadge({ status, onChange }: { status: SpeciesStatus; onChange: (s: SpeciesStatus) => void }) {
  const [open, setOpen] = useState(false)
  const meta = STATUS_META[status]
  const options: SpeciesStatus[] = ['new', 'needs_review', 'draft', 'published']
  return (
    <div style={{ position: 'relative' }}>
      <button onClick={() => setOpen(o => !o)} style={{
        display: 'inline-flex', alignItems: 'center', gap: 6,
        padding: '5px 10px', borderRadius: 20, fontSize: 12, fontWeight: 600,
        background: meta.bg, color: meta.text, border: `1px solid ${meta.border}`, cursor: 'pointer',
      }}>
        <span style={{ width: 7, height: 7, borderRadius: '50%', background: meta.dot }} />
        {meta.label}
        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
          <path d="M6 9l6 6 6-6"/>
        </svg>
      </button>
      {open && (
        <div style={{
          position: 'absolute', top: '110%', left: 0, zIndex: 50,
          background: 'white', border: '1px solid #E8E5DE', borderRadius: 10,
          boxShadow: '0 4px 16px rgba(0,0,0,0.10)', padding: 4, minWidth: 140,
        }}>
          {options.map(s => {
            const m = STATUS_META[s]
            return (
              <button key={s} onClick={() => { onChange(s); setOpen(false) }} style={{
                width: '100%', display: 'flex', alignItems: 'center', gap: 8,
                padding: '7px 10px', borderRadius: 7, fontSize: 12.5, fontWeight: s === status ? 700 : 500,
                background: s === status ? m.bg : 'transparent',
                color: s === status ? m.text : '#1C1916',
                border: 'none', cursor: 'pointer', textAlign: 'left',
              }}>
                <span style={{ width: 7, height: 7, borderRadius: '50%', background: m.dot, flexShrink: 0 }} />
                {m.label}
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}

function StatStepper({ label, value, max, onChange }: {
  label: string; value: number; max: number; onChange: (v: number) => void
}) {
  return (
    <div style={{ marginBottom: 16 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
        <span style={{ fontSize: 12.5, fontWeight: 600, color: '#1C1916' }}>{label}</span>
        <span style={{ fontSize: 12, color: '#9B968F', fontFamily: "'IBM Plex Mono', monospace" }}>
          {value}/{max}
        </span>
      </div>
      <div style={{ display: 'flex', gap: 5 }}>
        {Array.from({ length: max }, (_, i) => i + 1).map(n => (
          <button key={n} onClick={() => onChange(n)} style={{
            flex: 1, height: 28, borderRadius: 6,
            border: n <= value ? 'none' : '1px solid #E8E5DE',
            background: n <= value ? '#2596BE' : '#F7F6F3',
            cursor: 'pointer', transition: 'all 0.1s',
          }} />
        ))}
      </div>
    </div>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div style={{
      background: 'white', border: '1px solid #E8E5DE', borderRadius: 12,
      padding: 20, marginBottom: 16,
    }}>
      <div style={{ fontSize: 13, fontWeight: 700, color: '#1C1916', marginBottom: 16 }}>{title}</div>
      {children}
    </div>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ marginBottom: 14 }}>
      <label style={{ display: 'block', fontSize: 11.5, fontWeight: 700, color: '#9B968F',
        letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 5 }}>
        {label}
      </label>
      {children}
    </div>
  )
}

const inputStyle: React.CSSProperties = {
  width: '100%', padding: '8px 11px', borderRadius: 8,
  border: '1px solid #E8E5DE', background: 'white',
  fontSize: 13.5, color: '#1C1916', outline: 'none',
  boxSizing: 'border-box',
}

const BLANK_SPECIES: Species = {
  speciesName: '', scientificName: '', status: 'draft',
  description: '', facts: [],
  migrationSpeed: 5, speedDelta: 0, endurance: 3, enduranceDelta: 0,
  lineArtUrl: null,
  artByLevel: { ...EMPTY_ART },
  moves: [], reports: [],
}

export default function SpeciesEditor({ paramsPromise }: { paramsPromise: Promise<{ id: string }> }) {
  const params = use(paramsPromise)
  const isNew = params.id === 'new'
  const speciesName = isNew ? '' : decodeURIComponent(params.id)

  const router = useRouter()

  const [species, setSpecies] = useState<Species>(BLANK_SPECIES)
  const [loading, setLoading] = useState(!isNew)
  const [notFound, setNotFound] = useState(false)
  const [saving, setSaving] = useState(false)
  const [dirty, setDirty] = useState(false)
  const [error, setError] = useState('')
  const [activeTab, setActiveTab] = useState<'content' | 'art' | 'moves' | 'reports'>('content')

  useEffect(() => {
    if (isNew) return
    ;(async () => {
      try {
        const loaded = await fetchSpecies(speciesName)
        if (loaded) setSpecies(loaded)
        else setNotFound(true)
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed to load species')
      }
      setLoading(false)
    })()
  }, [isNew, speciesName])

  const set = (patch: Partial<Species>) => {
    setSpecies(s => ({ ...s, ...patch }))
    setDirty(true)
  }

  const save = async () => {
    if (!species.speciesName.trim()) {
      setError('Species name is required')
      return
    }
    setSaving(true)
    setError('')
    try {
      if (isNew) {
        await createSpecies(species)
        router.replace(`/species/${encodeURIComponent(species.speciesName)}`)
      } else {
        await updateSpecies(species)
      }
      setDirty(false)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Save failed')
    }
    setSaving(false)
  }

  const markResolved = async (reportId: string) => {
    setSpecies(s => ({
      ...s,
      reports: s.reports.map(r => r.id === reportId ? { ...r, resolved: true } : r),
    }))
    try {
      await resolveReport(reportId)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to resolve report')
    }
  }

  if (loading) return (
    <div style={{ padding: 48, textAlign: 'center', color: '#9B968F', fontSize: 13 }}>Loading…</div>
  )
  if (notFound) return (
    <div style={{ padding: 48, textAlign: 'center', color: '#9B968F', fontSize: 13 }}>
      Species “{speciesName}” not found.
    </div>
  )

  const openReports = species.reports.filter(r => !r.resolved).length
  const tabs: { key: typeof activeTab; label: string }[] = [
    { key: 'content', label: 'Content' },
    { key: 'art', label: 'Art' },
    { key: 'moves', label: 'Moves' },
    { key: 'reports', label: `Reports${openReports > 0 ? ` (${openReports})` : ''}` },
  ]

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Top bar */}
      <div style={{
        padding: '14px 24px', borderBottom: '1px solid #E8E5DE', background: 'white',
        display: 'flex', alignItems: 'center', gap: 12, flexShrink: 0,
      }}>
        <button onClick={() => router.push('/species')} style={{
          display: 'flex', alignItems: 'center', gap: 5,
          background: 'none', border: 'none', cursor: 'pointer',
          color: '#6B6560', fontSize: 12.5, padding: 0,
        }}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <path d="M15 18l-6-6 6-6"/>
          </svg>
          Species
        </button>
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#D4CFC9" strokeWidth="2" strokeLinecap="round">
          <path d="M9 18l6-6-6-6"/>
        </svg>
        <span style={{ fontSize: 13.5, fontWeight: 700, color: '#1C1916', flex: 1 }}>
          {isNew ? 'New species' : (species.speciesName || 'Unnamed')}
        </span>
        {error && (
          <span style={{ fontSize: 12, color: '#991B1B', maxWidth: 320, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {error}
          </span>
        )}
        <StatusBadge status={species.status} onChange={s => set({ status: s })} />
        <button onClick={save} disabled={!dirty || saving} style={{
          height: 34, padding: '0 16px', borderRadius: 8,
          background: dirty ? '#2596BE' : '#E8E5DE',
          color: dirty ? 'white' : '#9B968F',
          border: 'none', cursor: dirty ? 'pointer' : 'default',
          fontSize: 13, fontWeight: 600, transition: 'all 0.15s',
        }}>
          {saving ? 'Saving…' : 'Save'}
        </button>
      </div>

      {/* Tabs */}
      <div style={{
        display: 'flex', gap: 0, padding: '0 24px',
        borderBottom: '1px solid #E8E5DE', background: 'white', flexShrink: 0,
      }}>
        {tabs.map(t => (
          <button key={t.key} onClick={() => setActiveTab(t.key)} style={{
            padding: '10px 14px', fontSize: 13, fontWeight: t.key === activeTab ? 700 : 500,
            color: t.key === activeTab ? '#2596BE' : '#6B6560',
            background: 'none', border: 'none', borderBottom: t.key === activeTab ? '2px solid #2596BE' : '2px solid transparent',
            cursor: 'pointer', transition: 'color 0.1s',
          }}>
            {t.label}
          </button>
        ))}
      </div>

      {/* Content area */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '20px 24px' }}>
        {activeTab === 'content' && (
          <>
            <Section title="Identity">
              <Field label="Common Name">
                <input value={species.speciesName}
                  onChange={e => set({ speciesName: e.target.value })}
                  disabled={!isNew}
                  title={isNew ? undefined : 'Species name is the shared key with the app and cannot be renamed'}
                  style={{ ...inputStyle, ...(isNew ? {} : { background: '#F7F6F3', color: '#6B6560' }) }} />
              </Field>
              <Field label="Scientific Name">
                <input value={species.scientificName} onChange={e => set({ scientificName: e.target.value })}
                  style={{ ...inputStyle, fontStyle: 'italic' }} />
              </Field>
              <Field label="Description">
                <textarea value={species.description} onChange={e => set({ description: e.target.value })}
                  rows={4} style={{ ...inputStyle, resize: 'vertical', lineHeight: 1.6 }} />
              </Field>
              <Field label="Fun Facts">
                {species.facts.map((fact, i) => (
                  <div key={i} style={{ display: 'flex', gap: 6, marginBottom: 6 }}>
                    <input value={fact}
                      onChange={e => {
                        const facts = [...species.facts]
                        facts[i] = e.target.value
                        set({ facts })
                      }}
                      style={{ ...inputStyle, flex: 1 }} />
                    <button onClick={() => set({ facts: species.facts.filter((_, j) => j !== i) })} style={{
                      width: 32, height: 36, borderRadius: 8, border: '1px solid #FECACA',
                      background: '#FEF2F2', color: '#991B1B', cursor: 'pointer', fontSize: 16,
                    }}>×</button>
                  </div>
                ))}
                <button onClick={() => set({ facts: [...species.facts, ''] })} style={{
                  marginTop: 2, fontSize: 12.5, fontWeight: 600, color: '#2596BE',
                  background: 'none', border: 'none', cursor: 'pointer', padding: 0,
                }}>
                  + Add fact
                </button>
              </Field>
            </Section>

            <Section title="Stats">
              <StatStepper label="Migration Speed" value={species.migrationSpeed} max={10}
                onChange={v => set({ migrationSpeed: v })} />
              <Field label="Speed Delta (per level)">
                <input type="number" value={species.speedDelta}
                  onChange={e => set({ speedDelta: Number(e.target.value) })}
                  style={{ ...inputStyle, width: 100 }} />
              </Field>
              <StatStepper label="Endurance" value={species.endurance} max={5}
                onChange={v => set({ endurance: v })} />
              <Field label="Endurance Delta (per level)">
                <input type="number" value={species.enduranceDelta}
                  onChange={e => set({ enduranceDelta: Number(e.target.value) })}
                  style={{ ...inputStyle, width: 100 }} />
              </Field>
            </Section>
          </>
        )}

        {activeTab === 'art' && (
          <>
            {species.lineArtUrl && (
              <Section title="Current App Art">
                <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={species.lineArtUrl} alt="Line art"
                    style={{ width: 80, height: 80, borderRadius: 10, border: '1px solid #E8E5DE', background: '#F7F6F3', objectFit: 'contain' }} />
                  <div style={{ fontSize: 12.5, color: '#6B6560', lineHeight: 1.6 }}>
                    AI-generated line art currently shown on cards in the app.
                    Per-level art below will replace it once leveled card art ships.
                  </div>
                </div>
              </Section>
            )}
            <Section title="Art by Level">
              <div style={{ fontSize: 12.5, color: '#6B6560', marginBottom: 16, lineHeight: 1.6 }}>
                Upload one illustration per level (SVG preferred; PNG/WebP accepted), or paste a URL.
                Level 1 is the base form; Level 5 is the final form.
              </div>
              {STAT_LEVELS.map(level => (
                <ArtSlot key={level} level={level} species={species}
                  onArtChange={(url) => set({ artByLevel: { ...species.artByLevel, [level]: url } })}
                  onError={setError} />
              ))}
            </Section>
          </>
        )}

        {activeTab === 'moves' && (
          <Section title="Moves">
            {species.moves.length === 0 && (
              <div style={{ color: '#9B968F', fontSize: 13, marginBottom: 12 }}>No moves yet.</div>
            )}
            {species.moves.map((move, i) => (
              <div key={i} style={{
                border: '1px solid #E8E5DE', borderRadius: 10, padding: 14, marginBottom: 12,
              }}>
                <div style={{ display: 'flex', gap: 10, marginBottom: 10 }}>
                  <div style={{ flex: 2 }}>
                    <label style={{ fontSize: 11, fontWeight: 700, color: '#9B968F', textTransform: 'uppercase', letterSpacing: 0.5, display: 'block', marginBottom: 4 }}>Name</label>
                    <input value={move.moveName} onChange={e => {
                      const moves = [...species.moves]
                      moves[i] = { ...moves[i], moveName: e.target.value }
                      set({ moves })
                    }} style={inputStyle} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <label style={{ fontSize: 11, fontWeight: 700, color: '#9B968F', textTransform: 'uppercase', letterSpacing: 0.5, display: 'block', marginBottom: 4 }}>Category</label>
                    <select value={move.category} onChange={e => {
                      const moves = [...species.moves]
                      moves[i] = { ...moves[i], category: e.target.value as Move['category'] }
                      set({ moves })
                    }} style={{ ...inputStyle }}>
                      {(['Offense', 'Defense', 'Support'] as const).map(c => (
                        <option key={c} value={c}>{c}</option>
                      ))}
                    </select>
                  </div>
                  <div style={{ flex: 1 }}>
                    <label style={{ fontSize: 11, fontWeight: 700, color: '#9B968F', textTransform: 'uppercase', letterSpacing: 0.5, display: 'block', marginBottom: 4 }}>Unlock Level</label>
                    <select value={move.unlockLevel} onChange={e => {
                      const moves = [...species.moves]
                      moves[i] = { ...moves[i], unlockLevel: Number(e.target.value) as Move['unlockLevel'] }
                      set({ moves })
                    }} style={{ ...inputStyle }}>
                      {[1, 3, 5].map(l => <option key={l} value={l}>Level {l}</option>)}
                    </select>
                  </div>
                </div>
                <div style={{ marginBottom: 10 }}>
                  <label style={{ fontSize: 11, fontWeight: 700, color: '#9B968F', textTransform: 'uppercase', letterSpacing: 0.5, display: 'block', marginBottom: 4 }}>Description</label>
                  <textarea value={move.description} rows={2} onChange={e => {
                    const moves = [...species.moves]
                    moves[i] = { ...moves[i], description: e.target.value }
                    set({ moves })
                  }} style={{ ...inputStyle, resize: 'vertical' }} />
                </div>
                <div style={{ display: 'flex', gap: 10, alignItems: 'flex-end' }}>
                  <div style={{ flex: 1 }}>
                    <label style={{ fontSize: 11, fontWeight: 700, color: '#9B968F', textTransform: 'uppercase', letterSpacing: 0.5, display: 'block', marginBottom: 4 }}>Effect Type</label>
                    <input value={move.effectType} onChange={e => {
                      const moves = [...species.moves]
                      moves[i] = { ...moves[i], effectType: e.target.value }
                      set({ moves })
                    }} placeholder="e.g. damage, heal, buff" style={inputStyle} />
                  </div>
                  <div style={{ width: 100 }}>
                    <label style={{ fontSize: 11, fontWeight: 700, color: '#9B968F', textTransform: 'uppercase', letterSpacing: 0.5, display: 'block', marginBottom: 4 }}>Value</label>
                    <input type="number" value={move.effectValue} onChange={e => {
                      const moves = [...species.moves]
                      moves[i] = { ...moves[i], effectValue: Number(e.target.value) }
                      set({ moves })
                    }} style={inputStyle} />
                  </div>
                  <button onClick={() => set({ moves: species.moves.filter((_, j) => j !== i) })}
                    style={{
                      height: 36, padding: '0 12px', borderRadius: 8,
                      border: '1px solid #FECACA', background: '#FEF2F2',
                      color: '#991B1B', cursor: 'pointer', fontSize: 13, fontWeight: 600,
                    }}>
                    Remove
                  </button>
                </div>
              </div>
            ))}
            {species.moves.length < 3 && (
              <button onClick={() => set({
                moves: [...species.moves, {
                  moveName: '', category: 'Offense', description: '',
                  effectType: '', effectValue: 0,
                  unlockLevel: ([1, 3, 5] as const)[species.moves.length],
                }]
              })} style={{
                padding: '8px 14px', borderRadius: 8, fontSize: 13, fontWeight: 600,
                border: '1px solid #E8E5DE', background: 'white', color: '#2596BE', cursor: 'pointer',
              }}>
                + Add move
              </button>
            )}
          </Section>
        )}

        {activeTab === 'reports' && (
          <Section title="User Reports">
            {species.reports.length === 0 ? (
              <div style={{ color: '#9B968F', fontSize: 13 }}>No reports for this species.</div>
            ) : (
              species.reports.map(report => (
                <div key={report.id} style={{
                  border: `1px solid ${report.resolved ? '#E8E5DE' : '#FECACA'}`,
                  borderRadius: 10, padding: 14, marginBottom: 10,
                  background: report.resolved ? '#FAFAF8' : '#FEF2F2',
                  opacity: report.resolved ? 0.7 : 1,
                }}>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                        <span style={{ fontSize: 12.5, fontWeight: 700, color: '#1C1916' }}>{report.user}</span>
                        <span style={{ fontSize: 11, color: '#9B968F',
                          fontFamily: "'IBM Plex Mono', monospace" }}>
                          {new Date(report.createdAt).toLocaleDateString()}
                        </span>
                        {report.resolved && (
                          <span style={{ fontSize: 11, fontWeight: 600, color: '#166534',
                            background: '#F0FDF4', border: '1px solid #BBF7D0',
                            padding: '1px 6px', borderRadius: 20 }}>Resolved</span>
                        )}
                      </div>
                      <div style={{ fontSize: 13, color: '#3D3934', lineHeight: 1.5 }}>{report.message}</div>
                    </div>
                    {!report.resolved && (
                      <button onClick={() => markResolved(report.id)} style={{
                        padding: '5px 10px', borderRadius: 7, fontSize: 12, fontWeight: 600,
                        border: '1px solid #BBF7D0', background: '#F0FDF4',
                        color: '#166534', cursor: 'pointer', whiteSpace: 'nowrap',
                      }}>
                        Resolve
                      </button>
                    )}
                  </div>
                </div>
              ))
            )}
          </Section>
        )}
      </div>
    </div>
  )
}

function ArtSlot({ level, species, onArtChange, onError }: {
  level: 1 | 2 | 3 | 4 | 5
  species: Species
  onArtChange: (url: string | null) => void
  onError: (msg: string) => void
}) {
  const fileInput = useRef<HTMLInputElement>(null)
  const [uploading, setUploading] = useState(false)
  const url = species.artByLevel[level]

  const upload = async (file: File) => {
    if (!species.speciesName.trim()) {
      onError('Set the species name before uploading art')
      return
    }
    setUploading(true)
    try {
      onArtChange(await uploadArt(species.speciesName, level, file))
    } catch (e) {
      onError(e instanceof Error ? e.message : 'Upload failed')
    }
    setUploading(false)
  }

  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 14,
      padding: '12px 0', borderBottom: '1px solid #F0EDE6',
    }}>
      <div style={{
        width: 80, height: 80, borderRadius: 10, border: '1px solid #E8E5DE',
        background: '#F7F6F3', display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0, overflow: 'hidden',
      }}>
        {url
          // eslint-disable-next-line @next/next/no-img-element
          ? <img src={url} alt={`Level ${level}`} style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
          : <span style={{ fontSize: 11, color: '#C4BEB7' }}>Lv {level}</span>
        }
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: '#1C1916' }}>Level {level}</div>
          <button onClick={() => fileInput.current?.click()} disabled={uploading} style={{
            padding: '3px 10px', borderRadius: 7, fontSize: 12, fontWeight: 600,
            border: '1px solid #E8E5DE', background: 'white', color: '#2596BE',
            cursor: uploading ? 'default' : 'pointer',
          }}>
            {uploading ? 'Uploading…' : 'Upload'}
          </button>
          {url && (
            <button onClick={() => onArtChange(null)} style={{
              padding: '3px 10px', borderRadius: 7, fontSize: 12, fontWeight: 600,
              border: '1px solid #FECACA', background: '#FEF2F2', color: '#991B1B', cursor: 'pointer',
            }}>
              Remove
            </button>
          )}
          <input ref={fileInput} type="file" accept=".svg,.png,.webp,image/svg+xml,image/png,image/webp"
            style={{ display: 'none' }}
            onChange={e => {
              const file = e.target.files?.[0]
              if (file) upload(file)
              e.target.value = ''
            }} />
        </div>
        <input type="text" placeholder="…or paste an image URL"
          value={url ?? ''}
          onChange={e => onArtChange(e.target.value || null)}
          style={{ ...inputStyle }} />
      </div>
    </div>
  )
}
