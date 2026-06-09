import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'First Light CMS',
  description: 'Content management for First Light',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" style={{ height: '100%' }}>
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:ital,wght@0,400;0,600;0,700;1,400&family=IBM+Plex+Sans:ital,wght@0,400;0,500;0,600;0,700;0,800;1,400&display=swap"
          rel="stylesheet"
        />
      </head>
      <body style={{ height: '100%' }}>{children}</body>
    </html>
  )
}
