'use client'
import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase'

type Tab = 'birds' | 'product' | 'suspicious'

function StatCard({ label, value, sub }: { label: string; value: string | number; sub?: string }) {
  return (
    <div style={{
      background: 'white', border: '1px solid #E8E5DE', borderRadius: 12,
      padding: '16px 20px',
    }}>
      <div style={{ fontSize: 11.5, fontWeight: 700, color: '#9B968F', textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 6 }}>{label}</div>
      <div style={{ fontSize: 26, fontWeight: 800, color: '#1C1916', fontFamily: "'IBM Plex Mono', monospace", lineHeight: 1 }}>{value}</div>
      {sub && <div style={{ fontSize: 11.5, color: '#9B968F', marginTop: 4 }}>{sub}</div>}
    </div>
  )
}

function MiniBar({ data, labels }: { data: number[]; labels?: string[] }) {
  const max = Math.max(...data, 1)
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 4, height: 48 }}>
      {data.map((v, i) => (
        <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
          <div style={{
            width: '100%', background: '#2596BE', borderRadius: '3px 3px 0 0',
            height: `${Math.max((v / max) * 44, 2)}px`,
            opacity: 0.8,
          }} />
          {labels && <div style={{ fontSize: 9, color: '#C4BEB7', fontFamily: "'IBM Plex Mono', monospace" }}>{labels[i]}</div>}
        </div>
      ))}
    </div>
  )
}

const MOCK = {
  totalSpecies: 142,
  publishedSpecies: 89,
  newSpecies: 31,
  needsReview: 7,
  totalUsers: 2841,
  newUsersThisWeek: 184,
  totalCatches: 18_342,
  catchesThisWeek: 1_203,
  openReports: 14,
  weeklyCatches: [820, 940, 1103, 988, 1201, 1340, 1203],
  weekLabels: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'],
  mostCaught: [
    { name: 'American Robin', count: 842 },
    { name: 'Dark-eyed Junco', count: 714 },
    { name: 'House Sparrow', count: 698 },
    { name: 'Black-capped Chickadee', count: 601 },
    { name: 'Northern Cardinal', count: 583 },
  ],
  suspiciousUsers: [
    { user: 'user_7821', catches: 47, uniqueSpecies: 41, dupes: 3, note: 'Duplicate screenshot hashes detected' },
    { user: 'user_2244', catches: 102, uniqueSpecies: 12, dupes: 0, note: 'XP inconsistency — possible client tampering' },
    { user: 'user_9913', catches: 38, uniqueSpecies: 38, dupes: 7, note: 'Same-day duplicate catches across multiple species' },
  ],
}

export default function StatsDashboard() {
  const [tab, setTab] = useState<Tab>('birds')

  const tabs: { key: Tab; label: string }[] = [
    { key: 'birds', label: 'Birds' },
    { key: 'product', label: 'Product' },
    { key: 'suspicious', label: `Suspicious Activity${MOCK.suspiciousUsers.length > 0 ? ` (${MOCK.suspiciousUsers.length})` : ''}` },
  ]

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Header */}
      <div style={{
        padding: '20px 24px 0', background: 'white',
        borderBottom: '1px solid #E8E5DE', flexShrink: 0,
      }}>
        <div style={{ fontSize: 18, fontWeight: 800, color: '#1C1916', marginBottom: 16 }}>Stats</div>
        <div style={{ display: 'flex', gap: 0 }}>
          {tabs.map(t => (
            <button key={t.key} onClick={() => setTab(t.key)} style={{
              padding: '10px 14px', fontSize: 13, fontWeight: t.key === tab ? 700 : 500,
              color: t.key === tab ? '#2596BE' : '#6B6560',
              borderBottom: t.key === tab ? '2px solid #2596BE' : '2px solid transparent',
              background: 'none', border: 'none', cursor: 'pointer',
            }}>
              {t.label}
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '20px 24px' }}>
        {tab === 'birds' && (
          <>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
              <StatCard label="Total Species" value={MOCK.totalSpecies} />
              <StatCard label="Published" value={MOCK.publishedSpecies} sub={`${Math.round(MOCK.publishedSpecies / MOCK.totalSpecies * 100)}% of total`} />
              <StatCard label="New (AI)" value={MOCK.newSpecies} sub="awaiting review" />
              <StatCard label="Needs Review" value={MOCK.needsReview} sub="flagged" />
            </div>
            <div style={{ background: 'white', border: '1px solid #E8E5DE', borderRadius: 12, padding: 20, marginBottom: 16 }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: '#1C1916', marginBottom: 16 }}>Most Caught Species</div>
              {MOCK.mostCaught.map((s, i) => {
                const pct = Math.round(s.count / MOCK.mostCaught[0].count * 100)
                return (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                    <div style={{ fontSize: 11, fontFamily: "'IBM Plex Mono', monospace", color: '#9B968F', width: 16, textAlign: 'right' }}>{i + 1}</div>
                    <div style={{ flex: 1, fontSize: 13, color: '#1C1916' }}>{s.name}</div>
                    <div style={{ width: 120, height: 6, background: '#F0EDE6', borderRadius: 3, overflow: 'hidden' }}>
                      <div style={{ height: '100%', background: '#2596BE', borderRadius: 3, width: `${pct}%` }} />
                    </div>
                    <div style={{ fontSize: 12, fontFamily: "'IBM Plex Mono', monospace", color: '#6B6560', width: 40, textAlign: 'right' }}>{s.count}</div>
                  </div>
                )
              })}
            </div>
          </>
        )}

        {tab === 'product' && (
          <>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
              <StatCard label="Total Users" value={MOCK.totalUsers.toLocaleString()} />
              <StatCard label="New This Week" value={MOCK.newUsersThisWeek} />
              <StatCard label="Total Catches" value={MOCK.totalCatches.toLocaleString()} />
              <StatCard label="Catches This Week" value={MOCK.catchesThisWeek.toLocaleString()} />
            </div>
            <div style={{ background: 'white', border: '1px solid #E8E5DE', borderRadius: 12, padding: 20, marginBottom: 16 }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: '#1C1916', marginBottom: 4 }}>Catches This Week</div>
              <div style={{ fontSize: 12, color: '#9B968F', marginBottom: 16 }}>Daily breakdown</div>
              <MiniBar data={MOCK.weeklyCatches} labels={MOCK.weekLabels} />
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <StatCard label="Open Reports" value={MOCK.openReports} sub="across all species" />
              <StatCard label="Avg Catches/User" value={(MOCK.totalCatches / MOCK.totalUsers).toFixed(1)} />
            </div>
          </>
        )}

        {tab === 'suspicious' && (
          <>
            <div style={{ fontSize: 13, color: '#6B6560', marginBottom: 16, lineHeight: 1.6 }}>
              Users flagged for patterns that may indicate cheating: same-day duplicate catches or XP inconsistencies.
            </div>
            {MOCK.suspiciousUsers.length === 0 ? (
              <div style={{
                background: 'white', border: '1px solid #E8E5DE', borderRadius: 12, padding: 32,
                textAlign: 'center', color: '#9B968F', fontSize: 13,
              }}>
                No suspicious activity detected.
              </div>
            ) : (
              MOCK.suspiciousUsers.map((u, i) => (
                <div key={i} style={{
                  background: 'white', border: '1px solid #FECACA', borderRadius: 12,
                  padding: '14px 18px', marginBottom: 10,
                }}>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                    <div style={{
                      width: 34, height: 34, borderRadius: '50%', flexShrink: 0,
                      background: '#FEF2F2', border: '1px solid #FECACA',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#EF4444" strokeWidth="2" strokeLinecap="round">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                        <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
                      </svg>
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
                        <span style={{ fontSize: 13.5, fontWeight: 700, color: '#1C1916',
                          fontFamily: "'IBM Plex Mono', monospace" }}>{u.user}</span>
                      </div>
                      <div style={{ fontSize: 12.5, color: '#991B1B', marginBottom: 8 }}>{u.note}</div>
                      <div style={{ display: 'flex', gap: 16 }}>
                        {[
                          { l: 'Total Catches', v: u.catches },
                          { l: 'Unique Species', v: u.uniqueSpecies },
                          { l: 'Duplicates', v: u.dupes },
                        ].map(({ l, v }) => (
                          <div key={l}>
                            <div style={{ fontSize: 10, fontWeight: 700, color: '#9B968F', textTransform: 'uppercase', letterSpacing: 0.5 }}>{l}</div>
                            <div style={{ fontSize: 16, fontWeight: 800, color: '#1C1916', fontFamily: "'IBM Plex Mono', monospace" }}>{v}</div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              ))
            )}
          </>
        )}
      </div>
    </div>
  )
}
