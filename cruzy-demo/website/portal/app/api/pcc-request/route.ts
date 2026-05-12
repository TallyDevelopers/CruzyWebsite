import { NextRequest, NextResponse } from 'next/server'
import { getToken } from '@/lib/sfPortal'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
}

export async function OPTIONS() {
  return NextResponse.json(null, { headers: CORS_HEADERS })
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { firstName, lastName, phone, email, preferredShip, notes } = body

    if (!firstName || !lastName || !email) {
      return NextResponse.json(
        { success: false, error: 'First name, last name, and email are required.' },
        { status: 400, headers: CORS_HEADERS }
      )
    }

    const { access_token, instance_url } = await getToken()

    const leadBody: Record<string, unknown> = {
      FirstName: firstName,
      LastName: lastName,
      Email: email,
      Phone: phone || null,
      Company: 'Cruzy+ PCC Request',
      LeadSource: 'Web',
      Preferred_Ship__c: preferredShip || null,
      Description: notes || null,
    }

    const res = await fetch(
      `${instance_url}/services/data/v66.0/sobjects/Lead`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(leadBody),
      }
    )

    if (!res.ok) {
      const err = await res.text()
      console.error('Salesforce Lead creation failed:', err)
      return NextResponse.json(
        { success: false, error: 'Failed to create lead. Please try again.' },
        { status: 500, headers: CORS_HEADERS }
      )
    }

    const result = (await res.json()) as { id: string }
    console.log(`✅ Salesforce Lead created: ${result.id}`)

    return NextResponse.json(
      { success: true, leadId: result.id },
      { headers: CORS_HEADERS }
    )
  } catch (err) {
    const error = err as { message?: string }
    console.error('PCC request error:', error)
    return NextResponse.json(
      { success: false, error: error.message || 'An unexpected error occurred.' },
      { status: 500, headers: CORS_HEADERS }
    )
  }
}
