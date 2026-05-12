import { NextRequest, NextResponse } from 'next/server'
import { verifyToken } from '@/lib/auth'
import {
  findContactById,
  getContactMemberships,
  getContactBookings,
  getContactRewards,
  getContactSavedCards,
} from '@/lib/sfPortal'

export async function GET(req: NextRequest) {
  try {
    const sessionCookie = req.cookies.get('cruzy_session')?.value

    if (!sessionCookie) {
      return NextResponse.json({ success: false, error: 'Not authenticated' }, { status: 401 })
    }

    const payload = verifyToken(sessionCookie)
    if (!payload) {
      return NextResponse.json({ success: false, error: 'Session expired' }, { status: 401 })
    }

    const [contact, memberships, bookings, rewards, savedCards] = await Promise.all([
      findContactById(payload.contactId),
      getContactMemberships(payload.contactId),
      getContactBookings(payload.contactId),
      getContactRewards(payload.contactId),
      getContactSavedCards(payload.contactId),
    ])

    if (!contact) {
      return NextResponse.json({ success: false, error: 'Account not found' }, { status: 404 })
    }

    return NextResponse.json({
      success: true,
      contact,
      memberships,
      bookings,
      rewards,
      savedCards,
    })
  } catch (err) {
    console.error('Account fetch error:', err)
    return NextResponse.json({ success: false, error: 'Failed to load account data' }, { status: 500 })
  }
}
