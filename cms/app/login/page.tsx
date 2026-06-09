'use client'
import { useState } from 'react'
import Image from 'next/image'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

type Mode = 'password' | 'forgot' | 'magic'

export default function LoginPage() {
  const router = useRouter()
  const supabase = createClient()
  const [mode, setMode] = useState<Mode>('password')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [magicEmail, setMagicEmail] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [resetSent, setResetSent] = useState(false)
  const [magicSent, setMagicSent] = useState(false)

  const signIn = async () => {
    setLoading(true)
    setError('')
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) setError(error.message)
    else router.push('/species')
    setLoading(false)
  }

  const sendReset = async () => {
    setLoading(true)
    await supabase.auth.resetPasswordForEmail(email)
    setResetSent(true)
    setLoading(false)
  }

  const sendMagic = async () => {
    setLoading(true)
    await supabase.auth.signInWithOtp({ email: magicEmail })
    setMagicSent(true)
    setLoading(false)
  }

  return (
    <div style={{
      minHeight: '100vh', background: '#F7F6F3',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 24,
    }}>
      <div style={{
        width: 380, background: 'white',
        borderRadius: 16, padding: 32,
        border: '1px solid #E8E5DE',
        boxShadow: '0 4px 24px rgba(0,0,0,0.06)',
      }}>
        {/* Logo */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 28 }}>
          <Image src="/app-icon.png" alt="First Light" width={44} height={44} style={{ borderRadius: 10 }} />
          <div>
            <div style={{ fontSize: 18, fontWeight: 800, color: '#1C1916', lineHeight: 1.2 }}>First Light</div>
            <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: 1.2, color: '#9B968F', fontFamily: "'IBM Plex Mono', monospace", textTransform: 'uppercase' }}>Content Management</div>
          </div>
        </div>

        {mode === 'password' && (
          <>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1C1916', marginBottom: 20 }}>Sign in</div>
            {error && (
              <div style={{ padding: '8px 12px', borderRadius: 8, background: '#FEF2F2', border: '1px solid #FECACA', color: '#991B1B', fontSize: 13, marginBottom: 14 }}>
                {error}
              </div>
            )}
            <div style={{ marginBottom: 12 }}>
              <label style={labelStyle}>Email</label>
              <input
                type="email" value={email} onChange={e => setEmail(e.target.value)}
                placeholder="you@firstlight.app"
                style={inputStyle}
                onKeyDown={e => e.key === 'Enter' && signIn()}
              />
            </div>
            <div style={{ marginBottom: 6 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 5 }}>
                <label style={labelStyle}>Password</label>
                <button onClick={() => setMode('forgot')} style={linkStyle}>Forgot password?</button>
              </div>
              <input
                type="password" value={password} onChange={e => setPassword(e.target.value)}
                style={inputStyle}
                onKeyDown={e => e.key === 'Enter' && signIn()}
              />
            </div>
            <button onClick={signIn} disabled={loading} style={ctaStyle}>
              {loading ? 'Signing in…' : 'Sign in'}
            </button>

            <div style={{ display: 'flex', alignItems: 'center', gap: 10, margin: '20px 0 16px' }}>
              <div style={{ flex: 1, height: 1, background: '#E8E5DE' }} />
              <span style={{ fontSize: 11.5, color: '#9B968F' }}>or</span>
              <div style={{ flex: 1, height: 1, background: '#E8E5DE' }} />
            </div>

            <div style={{ fontSize: 12.5, color: '#6B6560', marginBottom: 8 }}>Sign in with magic link</div>
            {magicSent ? (
              <div style={{ padding: '8px 12px', borderRadius: 8, background: '#F0FDF4', border: '1px solid #BBF7D0', color: '#166534', fontSize: 13 }}>
                Check your email for a magic link.
              </div>
            ) : (
              <div style={{ display: 'flex', gap: 8 }}>
                <input
                  type="email" value={magicEmail} onChange={e => setMagicEmail(e.target.value)}
                  placeholder="you@firstlight.app"
                  style={{ ...inputStyle, flex: 1, marginBottom: 0 }}
                />
                <button onClick={sendMagic} style={{ padding: '7px 14px', borderRadius: 9, background: '#F7F6F3', border: '1px solid #E8E5DE', color: '#6B6560', fontSize: 13, fontWeight: 600, cursor: 'pointer', whiteSpace: 'nowrap' }}>
                  Send link
                </button>
              </div>
            )}
          </>
        )}

        {mode === 'forgot' && (
          <>
            <button onClick={() => setMode('password')} style={{ ...linkStyle, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 4 }}>
              ← Back
            </button>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1C1916', marginBottom: 6 }}>Reset password</div>
            <div style={{ fontSize: 13, color: '#6B6560', marginBottom: 20 }}>Enter your email and we'll send a reset link.</div>
            {resetSent ? (
              <div style={{ padding: '10px 14px', borderRadius: 8, background: '#F0FDF4', border: '1px solid #BBF7D0', color: '#166534', fontSize: 13 }}>
                Reset link sent — check your inbox.
              </div>
            ) : (
              <>
                <div style={{ marginBottom: 14 }}>
                  <label style={labelStyle}>Email</label>
                  <input type="email" value={email} onChange={e => setEmail(e.target.value)} style={inputStyle} />
                </div>
                <button onClick={sendReset} disabled={loading} style={ctaStyle}>
                  {loading ? 'Sending…' : 'Send reset link'}
                </button>
              </>
            )}
          </>
        )}
      </div>
    </div>
  )
}

const labelStyle: React.CSSProperties = {
  display: 'block', fontSize: 12.5, fontWeight: 600, color: '#1C1916', marginBottom: 5,
}

const inputStyle: React.CSSProperties = {
  width: '100%', padding: '9px 11px', borderRadius: 9,
  border: '1px solid #E8E5DE', background: 'white',
  fontSize: 13.5, color: '#1C1916', outline: 'none',
  boxSizing: 'border-box', marginBottom: 0,
}

const ctaStyle: React.CSSProperties = {
  width: '100%', height: 44, borderRadius: 9,
  background: '#2596BE', color: 'white',
  border: 'none', cursor: 'pointer',
  fontSize: 14, fontWeight: 700, marginTop: 16,
}

const linkStyle: React.CSSProperties = {
  background: 'none', border: 'none', cursor: 'pointer',
  color: '#2596BE', fontSize: 12.5, padding: 0,
}
