'use client'
import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

const inputStyle: React.CSSProperties = {
  width: '100%', padding: '8px 11px', borderRadius: 8,
  border: '1px solid #E8E5DE', background: 'white',
  fontSize: 13.5, color: '#1C1916', outline: 'none', boxSizing: 'border-box',
}

const readOnlyStyle: React.CSSProperties = {
  ...inputStyle, background: '#F7F6F3', color: '#9B968F',
}

function Section({ title, sub, children }: { title: string; sub?: string; children: React.ReactNode }) {
  return (
    <div style={{
      background: 'white', border: '1px solid #E8E5DE', borderRadius: 12,
      padding: 20, marginBottom: 16,
    }}>
      <div style={{ marginBottom: sub ? 4 : 16 }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: '#1C1916' }}>{title}</div>
        {sub && <div style={{ fontSize: 12, color: '#9B968F', marginTop: 2, marginBottom: 14 }}>{sub}</div>}
      </div>
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

function Feedback({ kind, text }: { kind: 'ok' | 'error'; text: string }) {
  const ok = kind === 'ok'
  return (
    <div style={{
      padding: '7px 11px', borderRadius: 8, fontSize: 12.5, marginBottom: 12,
      background: ok ? '#F0FDF4' : '#FEF2F2',
      border: `1px solid ${ok ? '#BBF7D0' : '#FECACA'}`,
      color: ok ? '#166534' : '#991B1B',
    }}>
      {text}
    </div>
  )
}

const ctaStyle: React.CSSProperties = {
  padding: '7px 14px', borderRadius: 8, fontSize: 13, fontWeight: 600,
  background: '#2596BE', color: 'white', border: 'none', cursor: 'pointer',
}

export default function SettingsPage() {
  const router = useRouter()
  const supabase = createClient()

  const [email, setEmail] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [accountMsg, setAccountMsg] = useState<{ kind: 'ok' | 'error'; text: string } | null>(null)
  const [savingAccount, setSavingAccount] = useState(false)

  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [passwordMsg, setPasswordMsg] = useState<{ kind: 'ok' | 'error'; text: string } | null>(null)
  const [savingPassword, setSavingPassword] = useState(false)

  const [signingOut, setSigningOut] = useState(false)

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      setEmail(user?.email ?? '')
      setDisplayName((user?.user_metadata?.display_name as string) ?? '')
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const saveAccount = async () => {
    setSavingAccount(true)
    setAccountMsg(null)
    const { error } = await supabase.auth.updateUser({
      data: { display_name: displayName.trim() },
    })
    setAccountMsg(error
      ? { kind: 'error', text: error.message }
      : { kind: 'ok', text: 'Saved.' })
    setSavingAccount(false)
  }

  const updatePassword = async () => {
    setPasswordMsg(null)
    if (newPassword.length < 8) {
      setPasswordMsg({ kind: 'error', text: 'Password must be at least 8 characters.' })
      return
    }
    if (newPassword !== confirmPassword) {
      setPasswordMsg({ kind: 'error', text: 'Passwords do not match.' })
      return
    }
    setSavingPassword(true)
    const { error } = await supabase.auth.updateUser({ password: newPassword })
    if (error) {
      setPasswordMsg({ kind: 'error', text: error.message })
    } else {
      setPasswordMsg({ kind: 'ok', text: 'Password updated.' })
      setNewPassword('')
      setConfirmPassword('')
    }
    setSavingPassword(false)
  }

  const signOut = async () => {
    setSigningOut(true)
    await supabase.auth.signOut()
    router.push('/login')
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{
        padding: '20px 24px 16px', borderBottom: '1px solid #E8E5DE',
        background: 'white', flexShrink: 0,
      }}>
        <div style={{ fontSize: 18, fontWeight: 800, color: '#1C1916' }}>Settings</div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '20px 24px', maxWidth: 560 }}>
        <Section title="Account" sub="Your First Light CMS account">
          {accountMsg && <Feedback kind={accountMsg.kind} text={accountMsg.text} />}
          <Field label="Display Name">
            <input value={displayName} onChange={e => setDisplayName(e.target.value)} style={inputStyle} />
          </Field>
          <Field label="Email">
            <input value={email} type="email" readOnly style={readOnlyStyle} />
          </Field>
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 4 }}>
            <button onClick={saveAccount} disabled={savingAccount} style={ctaStyle}>
              {savingAccount ? 'Saving…' : 'Save changes'}
            </button>
          </div>
        </Section>

        <Section title="Change Password">
          {passwordMsg && <Feedback kind={passwordMsg.kind} text={passwordMsg.text} />}
          <Field label="New Password">
            <input type="password" value={newPassword}
              onChange={e => setNewPassword(e.target.value)} style={inputStyle} />
          </Field>
          <Field label="Confirm New Password">
            <input type="password" value={confirmPassword}
              onChange={e => setConfirmPassword(e.target.value)} style={inputStyle} />
          </Field>
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 4 }}>
            <button onClick={updatePassword} disabled={savingPassword} style={ctaStyle}>
              {savingPassword ? 'Updating…' : 'Update password'}
            </button>
          </div>
        </Section>

        <Section title="Supabase" sub="Read-only — set via environment variables">
          <Field label="Project URL">
            <input value={process.env.NEXT_PUBLIC_SUPABASE_URL ?? '(not set)'} readOnly
              style={{ ...readOnlyStyle, fontFamily: "'IBM Plex Mono', monospace", fontSize: 12 }} />
          </Field>
          <Field label="Anon Key">
            <input value="••••••••••••••••••••" readOnly
              style={{ ...readOnlyStyle, fontFamily: "'IBM Plex Mono', monospace", fontSize: 12 }} />
          </Field>
        </Section>

        <Section title="Session">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <div style={{ fontSize: 13, fontWeight: 600, color: '#1C1916' }}>Sign out</div>
              <div style={{ fontSize: 12, color: '#9B968F', marginTop: 2 }}>End your current session</div>
            </div>
            <button onClick={signOut} disabled={signingOut} style={{
              padding: '7px 14px', borderRadius: 8, fontSize: 13, fontWeight: 600,
              border: '1px solid #FECACA', background: '#FEF2F2',
              color: '#991B1B', cursor: 'pointer',
            }}>
              {signingOut ? 'Signing out…' : 'Sign out'}
            </button>
          </div>
        </Section>
      </div>
    </div>
  )
}
