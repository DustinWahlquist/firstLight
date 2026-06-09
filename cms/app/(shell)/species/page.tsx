import { Suspense } from 'react'
import SpeciesList from '@/components/SpeciesList'

export default function SpeciesPage() {
  return (
    <Suspense fallback={<div style={{ padding: 48, textAlign: 'center', color: '#9B968F', fontSize: 13 }}>Loading…</div>}>
      <SpeciesList />
    </Suspense>
  )
}
