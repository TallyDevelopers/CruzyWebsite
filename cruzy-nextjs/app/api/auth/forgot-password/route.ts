import { NextRequest, NextResponse } from 'next/server'
import { findContactByEmail, updateContact } from '@/lib/sfPortal'
import { generateResetToken, getResetExpiry } from '@/lib/auth'

export async function POST(req: NextRequest) {
  try {
    const { email } = await req.json()

    if (!email) {
      return NextResponse.json({ success: false, error: 'Email is required' }, { status: 400 })
    }

    const contact = await findContactByEmail(email.toLowerCase().trim())

    // Always return success to prevent email enumeration
    if (!contact || contact.Portal_Status__c === 'Inactive') {
      return NextResponse.json({ success: true, message: 'If that email is on file, a reset link is on its way.' })
    }

    const token = generateResetToken()
    const expiry = getResetExpiry()

    await updateContact(contact.Id, {
      Portal_Reset_Token__c: token,
      Portal_Reset_Expiry__c: expiry,
    })

    const resetUrl = `${process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3000'}/reset-password?token=${token}`

    console.log(`🔑 Password reset link for ${contact.Email}: ${resetUrl}`)

    // In production: send via nodemailer / SendGrid / Resend
    // For demo: the link is logged to the console above

    return NextResponse.json({
      success: true,
      message: 'If that email is on file, a reset link is on its way.',
      // Only expose the link in dev mode for easy demo testing
      ...(process.env.NODE_ENV !== 'production' && { devResetUrl: resetUrl }),
    })
  } catch (err) {
    console.error('Forgot password error:', err)
    return NextResponse.json({ success: false, error: 'An unexpected error occurred' }, { status: 500 })
  }
}
