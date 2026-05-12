import { NextRequest, NextResponse } from 'next/server'
import { findContactByEmail, updateContact } from '@/lib/sfPortal'
import { generateResetToken, getResetExpiry } from '@/lib/auth'
import { passwordResetEmail, sendEmail } from '@/lib/email'

export async function POST(req: NextRequest) {
  try {
    const { email } = await req.json()

    if (!email) {
      return NextResponse.json({ success: false, error: 'Email is required' }, { status: 400 })
    }

    const contact = await findContactByEmail(email.toLowerCase().trim())

    if (!contact || contact.Portal_Status__c === 'Inactive') {
      return NextResponse.json({ success: true, message: 'If that email is on file, a reset link is on its way.' })
    }

    const token = generateResetToken()
    const expiry = getResetExpiry()

    await updateContact(contact.Id, {
      Portal_Reset_Token__c: token,
      Portal_Reset_Expiry__c: expiry,
    })

    const resetUrl = `${process.env.NEXT_PUBLIC_PORTAL_URL || 'http://localhost:3000'}/reset-password?token=${token}`

    const { subject, html } = passwordResetEmail(contact.FirstName, resetUrl)
    await sendEmail(contact.Email, subject, html)

    return NextResponse.json({
      success: true,
      message: 'If that email is on file, a reset link is on its way.',
      ...(process.env.NODE_ENV !== 'production' && { devResetUrl: resetUrl }),
    })
  } catch (err) {
    console.error('Forgot password error:', err)
    return NextResponse.json({ success: false, error: 'An unexpected error occurred' }, { status: 500 })
  }
}
