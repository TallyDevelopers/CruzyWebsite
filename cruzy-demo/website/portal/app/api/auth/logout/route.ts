import { NextRequest, NextResponse } from 'next/server'

const SITE_URL = process.env.SITE_URL || process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:8080'
const PORTAL_URL = process.env.NEXT_PUBLIC_PORTAL_URL || 'http://localhost:3000'
const ALLOWED_ORIGINS = [SITE_URL, PORTAL_URL]

function corsHeaders(origin: string | null) {
  const allowed = origin && ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0]
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Credentials': 'true',
  }
}

export async function OPTIONS(req: NextRequest) {
  const origin = req.headers.get('origin')
  return NextResponse.json(null, { headers: corsHeaders(origin) })
}

export async function POST(req: NextRequest) {
  const origin = req.headers.get('origin')
  const response = NextResponse.json({ success: true }, { headers: corsHeaders(origin) })
  response.cookies.set('cruzy_session', '', {
    maxAge: 0,
    path: '/',
    sameSite: 'none',
    secure: true,
  })
  return response
}
