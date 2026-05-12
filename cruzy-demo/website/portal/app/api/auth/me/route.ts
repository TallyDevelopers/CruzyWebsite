import { NextRequest, NextResponse } from 'next/server'
import { verifyToken } from '@/lib/auth'
import { findContactById } from '@/lib/sfPortal'

const SITE_URL = process.env.SITE_URL || process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:8080'
const PORTAL_URL = process.env.NEXT_PUBLIC_PORTAL_URL || 'http://localhost:3000'
const ALLOWED_ORIGINS = [SITE_URL, PORTAL_URL]

function corsHeaders(origin: string | null) {
  const allowed = origin && ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0]
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Credentials': 'true',
  }
}

export async function OPTIONS(req: NextRequest) {
  const origin = req.headers.get('origin')
  return NextResponse.json(null, { headers: corsHeaders(origin) })
}

export async function GET(req: NextRequest) {
  const origin = req.headers.get('origin')
  const headers = corsHeaders(origin)

  try {
    const sessionCookie = req.cookies.get('cruzy_session')?.value

    if (!sessionCookie) {
      return NextResponse.json({ loggedIn: false }, { headers })
    }

    const payload = verifyToken(sessionCookie)
    if (!payload) {
      return NextResponse.json({ loggedIn: false }, { headers })
    }

    const contact = await findContactById(payload.contactId)
    if (!contact) {
      return NextResponse.json({ loggedIn: false }, { headers })
    }

    return NextResponse.json({
      loggedIn: true,
      name: `${contact.FirstName} ${contact.LastName}`,
      firstName: contact.FirstName,
      email: contact.Email,
    }, { headers })
  } catch {
    return NextResponse.json({ loggedIn: false }, { headers })
  }
}
