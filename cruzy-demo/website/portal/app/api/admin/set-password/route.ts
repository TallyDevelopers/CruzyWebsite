import { NextRequest, NextResponse } from 'next/server'
import { updateContact } from '@/lib/sfPortal'
import { hashPassword } from '@/lib/auth'

const ADMIN_SECRET = process.env.ADMIN_API_SECRET || ''

export async function POST(req: NextRequest) {
  try {
    const authHeader = req.headers.get('authorization')
    if (!ADMIN_SECRET || authHeader !== `Bearer ${ADMIN_SECRET}`) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { contactId, password } = await req.json()

    if (!contactId || !password || password.length < 8) {
      return NextResponse.json({ error: 'contactId and password (8+ chars) required' }, { status: 400 })
    }

    const hash = await hashPassword(password)

    await updateContact(contactId, {
      Portal_Password_Hash__c: hash,
      Portal_Status__c: 'Active',
      Portal_Reset_Token__c: '',
      Portal_Reset_Expiry__c: null,
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    const error = err as { message?: string }
    console.error('Admin set-password error:', error)
    return NextResponse.json({ error: error.message || 'Failed' }, { status: 500 })
  }
}
