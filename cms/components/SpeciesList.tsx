'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Species, SpeciesStatus, STATUS_META, STATUS_ORDER } from '@/lib/types'

const PAGE_SIZE = 40

export default function SpeciesList() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const statusFilter = (searchParams.get('status') ?? '') as SpeciesStatus | ''

  const [species, setSpecies] = useState<Species[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [selected, setSelected] = useState<Set<string>>(new Set())

  const supabase = createClient()

  const fetchSpecies = useCallback(async () => {
    setLoading(true)
    let q = supabase
      .from('species')
      .select('*')
      .order('status', { ascending: true })
      .order('species_name', { ascending: true })
      .limit(PAGE_SIZE)

    if (statusFilter) q = q.eq('status', statusFilter)
    if (search) q = q.ilike('species_name', `%${search}%`)

    const { data } = await q
    if (data) setSpecies(data as unknown as Species[])
    setLoading(false)
  }, [statusFilter, search])

  useEffect(() => { fetchSpecies() }, [fetchSpecies])

  const toggleSelect = (id: string) => {
    setSelected(s => {
      const n = new Set(s)
      n.has(id) ? n.delete(id) : n.add(id)
      return n
    })
  }

  const toggleAll = () => {
    if (selected.size === species.length) setSelected(new Set())
    else setSelected(new Set(species.map(s => s.id)))
  }

  const bulkUpdateStatus = async (status: SpeciesStatus) => {
    await supabase.from('species').update({ status }).in('id', [...selected])
    setSelected(new Set())
    fetchSpecies()
  }

  const sorted = [...species].sort((a, b) =>
    (STATUS_ORDER[a.status] - STATUS_ORDER[b.status]) ||
    a.speciesName?.localeCompare(b.speciesName ?? '') || 0
  )

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Header */}
      <div style={{
        padding: '20px 24px 16px',
        borderBottom: '1px solid #E8E5DE',
        background: 'white',
        display: 'flex', alignItems: 'center', gap: 12, flexShrink: 0,
      }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 18, fontWeight: 800, color: '#1C1916' }}>Species</div>
          <div style={{ fontSize: 12, color: '#9B968F', marginTop: 1 }}>
            {statusFilter ? STATUS_META[statusFilter]?.label : 'All species'}
          </div>
        </div>
        {/* Search */}
        <div style={{ position: 'relative' }}>
          <svg style={{ position: 'absolute', left: 9, top: '50%', transform: 'translateY(-50%)', color: '#9B968F' }}
            width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
          </svg>
          <input
            type="text" placeholder="Search species…" value={search}
            onChange={e => setSearch(e.target.value)}
            style={{
              paddingLeft: 28, paddingRight: 10, height: 34, borderRadius: 8,
              border: '1px solid #E8E5DE', background: '#F7F6F3',
              fontSize: 13, color: '#1C1916', outline: 'none', width: 200,
            }}
          />
        </div>
        <button
          onClick={() => router.push('/species/new')}
          style={{
            height: 34, padding: '0 14px', borderRadius: 8,
            background: '#2596BE', color: 'white',
            border: 'none', cursor: 'pointer', fontSize: 13, fontWeight: 600,
            display: 'flex', alignItems: 'center', gap: 6,
          }}
        >
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          Add species
        </button>
      </div>

      {/* Bulk actions */}
      {selected.size > 0 && (
        <div style={{
          padding: '8px 24px', background: '#EBF6FA', borderBottom: '1px solid #C8E8F4',
          display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0,
        }}>
          <span style={{ fontSize: 13, fontWeight: 600, color: '#1A7FA8' }}>{selected.size} selected</span>
          <div style={{ flex: 1 }} />
          {(['new', 'draft', 'needs_review', 'published'] as SpeciesStatus[]).map(s => (
            <button key={s} onClick={() => bulkUpdateStatus(s)} style={{
              height: 28, padding: '0 10px', borderRadius: 6, fontSize: 12, fontWeight: 600,
              border: `1px solid ${STATUS_META[s].border}`,
              background: STATUS_META[s].bg, color: STATUS_META[s].text,
              cursor: 'pointer',
            }}>
              → {STATUS_META[s].label}
            </button>
          ))}
          <button onClick={() => setSelected(new Set())} style={{
            height: 28, padding: '0 10px', borderRadius: 6, fontSize: 12,
            border: '1px solid #E8E5DE', background: 'white', color: '#6B6560', cursor: 'pointer',
          }}>
            Cancel
          </button>
        </div>
      )}

      {/* Table */}
      <div style={{ flex: 1, overflowY: 'auto' }}>
        {loading ? (
          <div style={{ padding: 48, textAlign: 'center', color: '#9B968F', fontSize: 13 }}>Loading…</div>
        ) : sorted.length === 0 ? (
          <div style={{ padding: 48, textAlign: 'center', color: '#9B968F', fontSize: 13 }}>No species found.</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #E8E5DE', background: 'white', position: 'sticky', top: 0 }}>
                <th style={{ width: 40, padding: '10px 8px 10px 20px', textAlign: 'center' }}>
                  <input type="checkbox" checked={selected.size === species.length && species.length > 0}
                    onChange={toggleAll} style={{ cursor: 'pointer' }} />
                </th>
                {['Species', 'Scientific Name', 'Status', 'Reports', ''].map((h, i) => (
                  <th key={i} style={{
                    padding: '10px 12px', textAlign: 'left', fontSize: 11.5,
                    fontWeight: 700, color: '#9B968F', letterSpacing: 0.3,
                    textTransform: 'uppercase', whiteSpace: 'nowrap',
                  }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {sorted.map((sp, i) => {
                const meta = STATUS_META[sp.status]
                const openReports = sp.reports?.filter(r => !r.resolved).length ?? 0
                return (
                  <tr
                    key={sp.id}
                    style={{
                      borderBottom: '1px solid #F0EDE6',
                      background: selected.has(sp.id) ? '#F0F9FF' : i % 2 === 0 ? 'white' : '#FAFAF8',
                      cursor: 'pointer',
                    }}
                    onClick={() => router.push(`/species/${sp.id}`)}
                  >
                    <td style={{ padding: '10px 8px 10px 20px', textAlign: 'center' }}
                      onClick={e => { e.stopPropagation(); toggleSelect(sp.id) }}>
                      <input type="checkbox" checked={selected.has(sp.id)} onChange={() => toggleSelect(sp.id)}
                        style={{ cursor: 'pointer' }} />
                    </td>
                    <td style={{ padding: '10px 12px' }}>
                      <div style={{ fontSize: 13.5, fontWeight: 600, color: '#1C1916' }}>{sp.speciesName}</div>
                    </td>
                    <td style={{ padding: '10px 12px' }}>
                      <div style={{ fontSize: 12.5, color: '#6B6560', fontStyle: 'italic',
                        fontFamily: "'IBM Plex Mono', monospace" }}>{sp.scientificName}</div>
                    </td>
                    <td style={{ padding: '10px 12px' }}>
                      <span style={{
                        display: 'inline-flex', alignItems: 'center', gap: 5,
                        padding: '3px 8px', borderRadius: 20, fontSize: 11.5, fontWeight: 600,
                        background: meta?.bg, color: meta?.text, border: `1px solid ${meta?.border}`,
                      }}>
                        <span style={{ width: 6, height: 6, borderRadius: '50%', background: meta?.dot, flexShrink: 0 }} />
                        {meta?.label}
                      </span>
                    </td>
                    <td style={{ padding: '10px 12px' }}>
                      {openReports > 0 && (
                        <span style={{
                          display: 'inline-flex', alignItems: 'center', gap: 4,
                          padding: '2px 7px', borderRadius: 20, fontSize: 11, fontWeight: 700,
                          background: '#FEF2F2', color: '#991B1B', border: '1px solid #FECACA',
                        }}>
                          {openReports} open
                        </span>
                      )}
                    </td>
                    <td style={{ padding: '10px 16px 10px 12px', textAlign: 'right' }}>
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#C4BEB7" strokeWidth="2" strokeLinecap="round">
                        <path d="M9 18l6-6-6-6"/>
                      </svg>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
