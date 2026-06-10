import AuthGate from '@/components/AuthGate'
import Sidebar from '@/components/Sidebar'

export default function ShellLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGate>
      <div style={{ display: 'flex', height: '100vh', overflow: 'hidden', background: '#F7F6F3' }}>
        <Sidebar />
        <main style={{ flex: 1, overflow: 'auto', display: 'flex', flexDirection: 'column' }}>
          {children}
        </main>
      </div>
    </AuthGate>
  )
}
