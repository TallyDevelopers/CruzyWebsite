import type { Metadata } from 'next'
import Script from 'next/script'
import './globals.css'

export const metadata: Metadata = {
  title: 'Join Cruzy+ | Cruise Membership Discounts & Benefits',
  description: 'Join Cruzy+ and save an average of 25% on cruise bookings. Priority boarding, concierge line, personal cruise counselor, and more.',
  icons: { icon: `${process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:8080'}/files/images/favicon.png` },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        {/* Fonts */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,100..900;1,100..900&family=Poppins:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&display=swap" />
        <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fjalla+One&display=swap" />
        <link rel="stylesheet" href="https://use.typekit.net/ruf1vnr.css" />

        {/* Bootstrap CSS */}
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" />

        {/* Font Awesome */}
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" />

        {/* Hover.css */}
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/hover.css/2.3.1/css/hover-min.css" />

        {/* Slick */}
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/slick-carousel/1.9.0/slick-theme.css" />
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/slick-carousel/1.9.0/slick.min.css" />

        {/* Site custom styles - MUST come after Bootstrap, before page content */}
        <link rel="stylesheet" href={`${process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:8080'}/css/styles.css`} />
      </head>
      <body>
        {children}

        {/* Bootstrap JS for navbar toggle, dropdowns */}
        <Script
          src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"
          strategy="afterInteractive"
        />

        {/* Google Maps / Places Autocomplete */}
        <Script
          src={`https://maps.googleapis.com/maps/api/js?key=${process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY}&libraries=places`}
          strategy="afterInteractive"
        />
      </body>
    </html>
  )
}
