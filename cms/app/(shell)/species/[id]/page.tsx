import SpeciesEditor from '@/components/SpeciesEditor'

export default function SpeciesDetailPage({ params }: { params: Promise<{ id: string }> }) {
  return <SpeciesEditor paramsPromise={params} />
}
