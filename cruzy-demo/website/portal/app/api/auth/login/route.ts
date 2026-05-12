import { NextRequest, NextResponse } from 'next/server'
import { findContactByEmail, updateContact } from '@/lib/sfPortal'
import { verifyPassword, generateToken } from '@/lib/auth'

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
  const headers = corsHeaders(origin)

  try {
    const { email, password } = await req.json()

    if (!email || !password) {
      return NextResponse.json({ success: false, error: 'Email and password are required' }, { status: 400, headers })
    }

    const contact = await findContactByEmail(email.toLowerCase().trim())

    if (!contact) {
      return NextResponse.json({ success: false, error: 'Invalid email or password' }, { status: 401, headers })
    }

    if (contact.Portal_Status__c === 'Inactive') {
      return NextResponse.json({ success: false, error: 'Your account has been deactivated. Please contact support.' }, { status: 403, headers })
    }

    if (contact.Portal_Status__c === 'Locked') {
      return NextResponse.json({ success: false, error: 'Your account is locked. Please reset your password or contact support.' }, { status: 403, headers })
    }

    if (contact.Portal_Status__c === 'Pending' || !contact.Portal_Password_Hash__c) {
      return NextResponse.json({ success: false, error: 'Please check your email to set your password before logging in.' }, { status: 403, headers })
    }

    const { valid, needsUpgrade } = await verifyPassword(password, contact.Portal_Password_Hash__c)
    if (!valid) {
      return NextResponse.json({ success: false, error: 'Invalid email or password' }, { status: 401, headers })
    }

    const updates: Record<string, unknown> = {
      Portal_Last_Login__c: new Date().toISOString(),
      Portal_Login_Count__c: (contact.Portal_Login_Count__c || 0) + 1,
    }

    if (needsUpgrade) {
      const { hashPassword: rehash } = await import('@/lib/auth')
      updates.Portal_Password_Hash__c = await rehash(password)
    }

    await updateContact(contact.Id, updates)

    const token = generateToken(contact.Id, contact.Email)

    const response = NextResponse.json({
      success: true,
      contactId: contact.Id,
      name: `${contact.FirstName} ${contact.LastName}`,
      email: contact.Email,
      memberId: contact.Cruzy_Plus_MBR_Number__c,
    }, { headers })

    response.cookies.set('cruzy_session', token, {
      httpOnly: true,
      secure: true,
      sameSite: 'none',
      maxAge: 60 * 60 * 24 * 7,
      path: '/',
    })

    return response
  } catch (err) {
    console.error('Login error:', err)
    return NextResponse.json({ success: false, error: 'An unexpected error occurred' }, { status: 500, headers })
  }
}
