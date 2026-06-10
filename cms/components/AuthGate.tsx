'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'

/** Blocks shell pages until a session exists; otherwise sends to /login. */
export default function AuthGate({ children }: { children: React.ReactNode }) {
  const router = useRouter()
  const [ready, setReady] = useState(false)

  useEffect(() => {
    const supabase = createClient()
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) setReady(true)
      else router.replace('/login')
    })
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!session) router.replace('/login')
    })
    return () => subscription.unsubscribe()
  }, [router])

  if (!ready) {
    return (
      <div style={{ padding: 48, textAlign: 'center', color: '#9B968F', fontSize: 13 }}>
        Loading…
      </div>
    )
  }
  return <>{children}</>
}
