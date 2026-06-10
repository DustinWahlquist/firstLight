'use client'
import { useEffect, useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { usePathname } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

const NAV = [
  {
    key: 'needs_review', label: 'Needs Review', href: '/species?status=needs_review',
    active: (p: string, s: string) => s === 'needs_review',
    icon: (
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
        <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
      </svg>
    ),
  },
  {
    key: 'new', label: 'New', href: '/species?status=new',
    active: (p: string, s: string) => s === 'new',
    icon: (
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/>
      </svg>
    ),
  },
  {
    key: 'species', label: 'Species', href: '/species',
    active: (p: string, s: string) => p === '/species' && !s,
    icon: (
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
        <path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>
      </svg>
    ),
  },
]

const NAV_BOTTOM = [
  {
    key: 'stats', label: 'Stats', href: '/stats',
    active: (p: string) => p.startsWith('/stats'),
    icon: (
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/>
        <line x1="6" y1="20" x2="6" y2="14"/>
      </svg>
    ),
  },
  {
    key: 'settings', label: 'Settings', href: '/settings',
    active: (p: string) => p.startsWith('/settings'),
    icon: (
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <circle cx="12" cy="12" r="3"/>
        <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>
      </svg>
    ),
  },
]

export default function Sidebar() {
  const [collapsed, setCollapsed] = useState(false)
  const [userName, setUserName] = useState('')
  const [userEmail, setUserEmail] = useState('')
  const pathname = usePathname()
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      setUserEmail(user?.email ?? '')
      setUserName((user?.user_metadata?.display_name as string) ?? '')
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const displayName = userName || userEmail || '…'
  const initials = displayName
    .split(/[\s@.]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map(p => p[0]?.toUpperCase() ?? '')
    .join('')

  const searchParams = typeof window !== 'undefined'
    ? new URLSearchParams(window.location.search).get('status') ?? ''
    : ''

  const w = collapsed ? 56 : 220

  const signOut = async () => {
    await supabase.auth.signOut()
    router.push('/login')
  }

  const navItem = (item: typeof NAV[0], isActive: boolean) => (
    <Link
      key={item.key}
      href={item.href}
      style={{
        display: 'flex', alignItems: 'center', gap: collapsed ? 0 : 9,
        justifyContent: collapsed ? 'center' : 'flex-start',
        height: 36, padding: collapsed ? '0 8px' : '0 10px',
        borderRadius: 8, textDecoration: 'none',
        background: isActive ? '#EBF6FA' : 'transparent',
        color: isActive ? '#1A7FA8' : '#6B6560',
        fontWeight: isActive ? 600 : 400,
        fontSize: 13.5, transition: 'background 0.1s',
        flexShrink: 0,
        whiteSpace: 'nowrap', overflow: 'hidden',
      }}
      onMouseEnter={e => { if (!isActive) (e.currentTarget as HTMLElement).style.background = '#F7F6F3' }}
      onMouseLeave={e => { if (!isActive) (e.currentTarget as HTMLElement).style.background = 'transparent' }}
      title={collapsed ? item.label : undefined}
    >
      <span style={{ flexShrink: 0 }}>{item.icon}</span>
      {!collapsed && <span>{item.label}</span>}
    </Link>
  )

  return (
    <div style={{
      width: w, flexShrink: 0,
      background: 'white', borderRight: '1px solid #E8E5DE',
      display: 'flex', flexDirection: 'column',
      height: '100%', transition: 'width 0.2s ease',
      overflow: 'hidden',
    }}>
      {/* Logo */}
      <div style={{
        height: 56, display: 'flex', alignItems: 'center',
        gap: collapsed ? 0 : 10, justifyContent: collapsed ? 'center' : 'flex-start',
        padding: collapsed ? '0 14px' : '0 16px',
        borderBottom: '1px solid #E8E5DE', flexShrink: 0,
      }}>
        <Image src="/app-icon.png" alt="First Light" width={28} height={28} style={{ borderRadius: 6, flexShrink: 0 }} />
        {!collapsed && (
          <div>
            <div style={{ fontSize: 14, fontWeight: 800, color: '#1C1916', lineHeight: 1.2 }}>First Light</div>
            <div style={{ fontSize: 9, fontWeight: 700, letterSpacing: 1, color: '#9B968F', fontFamily: "'IBM Plex Mono', monospace", textTransform: 'uppercase' }}>CMS</div>
          </div>
        )}
      </div>

      {/* Nav */}
      <div style={{ flex: 1, padding: '10px 8px', display: 'flex', flexDirection: 'column', gap: 2, overflowY: 'auto' }}>
        {NAV.map(item => {
          const isActive = 'active' in item && typeof item.active === 'function'
            ? (item.active as Function)(pathname, searchParams)
            : pathname.startsWith(item.href)
          return navItem(item as any, isActive)
        })}

        <div style={{ height: 1, background: '#F0EDE6', margin: '6px 2px' }} />

        {NAV_BOTTOM.map(item => {
          const isActive = item.active(pathname)
          return navItem(item as any, isActive)
        })}
      </div>

      {/* User + collapse */}
      <div style={{ borderTop: '1px solid #E8E5DE', padding: '10px 8px', flexShrink: 0 }}>
        {!collapsed && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 6px', borderRadius: 8, marginBottom: 6 }}>
            <div style={{ width: 34, height: 34, borderRadius: '50%', background: 'linear-gradient(135deg, #2596BE, #1B6B3D)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, fontWeight: 700, flexShrink: 0 }}>
              {initials || '?'}
            </div>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: '#1C1916', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{displayName}</div>
              <div style={{ fontSize: 11, color: '#9B968F' }}>Content Admin</div>
            </div>
          </div>
        )}
        <button
          onClick={() => setCollapsed(c => !c)}
          style={{
            width: '100%', height: 32, borderRadius: 7,
            border: '1px solid #E8E5DE', background: 'white',
            cursor: 'pointer', color: '#9B968F',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}
          title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            {collapsed
              ? <><path d="M13 17l5-5-5-5"/><path d="M6 17l5-5-5-5"/></>
              : <><path d="M11 17l-5-5 5-5"/><path d="M18 17l-5-5 5-5"/></>
            }
          </svg>
        </button>
      </div>
    </div>
  )
}
