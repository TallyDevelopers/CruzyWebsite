// Uses SF CLI session token when SF_ACCESS_TOKEN + SF_INSTANCE_URL are set,
// or falls back to OAuth username-password flow for production.

interface SalesforceTokenResponse {
  access_token: string
  instance_url: string
}

export interface ContactPayload {
  firstName: string
  lastName: string
  email: string
  phone: string
  street1: string
  street2?: string
  city: string
  state?: string
  postalCode: string
  country: string
  spouseFirstName?: string
  spouseLastName?: string
  authorizedUsers?: Array<{
    firstName?: string
    lastName?: string
    email?: string
    phone?: string
  }>
  nameOnCard: string
  // Authorize.net IDs
  authnetCustomerProfileId: string
  authnetPaymentProfileId: string
  authnetTransactionId: string
  // Card details
  cardBrand?: string
  cardLast4?: string
  cardExpMonth?: number
  cardExpYear?: number
}

export interface SalesforceResult {
  contactId: string
  membershipId: string
  savedCardId: string
  cruzyMemberId: string
}

async function getToken(): Promise<SalesforceTokenResponse> {
  // Direct token — available when running locally with SF CLI session
  if (process.env.SF_ACCESS_TOKEN && process.env.SF_INSTANCE_URL) {
    return {
      access_token: process.env.SF_ACCESS_TOKEN,
      instance_url: process.env.SF_INSTANCE_URL,
    }
  }

  // OAuth username-password flow for production
  const loginUrl = process.env.SF_LOGIN_URL || 'https://login.salesforce.com'
  const params = new URLSearchParams({
    grant_type: 'password',
    client_id: process.env.SF_CLIENT_ID!,
    client_secret: process.env.SF_CLIENT_SECRET!,
    username: process.env.SF_USERNAME!,
    password: process.env.SF_PASSWORD!,
  })

  const res = await fetch(`${loginUrl}/services/oauth2/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString(),
  })

  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Salesforce OAuth failed: ${err}`)
  }

  return res.json()
}

async function sfPost(
  accessToken: string,
  instanceUrl: string,
  sobject: string,
  body: Record<string, unknown>
): Promise<{ id: string }> {
  const res = await fetch(`${instanceUrl}/services/data/v66.0/sobjects/${sobject}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  })

  if (!res.ok) {
    const err = await res.text()
    throw new Error(`SF ${sobject} create failed: ${err}`)
  }

  return res.json()
}

export async function pushToSalesforce(payload: ContactPayload): Promise<SalesforceResult> {
  const { access_token, instance_url } = await getToken()

  const mailingStreet = [payload.street1, payload.street2].filter(Boolean).join('\n')
  const spouseName = [payload.spouseFirstName, payload.spouseLastName].filter(Boolean).join(' ')
  const today = new Date().toISOString().split('T')[0]

  // ── 1. Create Contact ──────────────────────────────────────────────────────
  const contactBody: Record<string, unknown> = {
    FirstName: payload.firstName,
    LastName: payload.lastName,
    Email: payload.email,
    Phone: payload.phone,
    MailingStreet: mailingStreet,
    MailingCity: payload.city,
    MailingState: payload.state || '',
    MailingPostalCode: payload.postalCode,
    MailingCountry: payload.country,
    Spouse_Significant_Other__c: spouseName || '',
    Cruzy_Plus_Enrolled__c: true,
    Stripe_Customer_ID__c: payload.authnetCustomerProfileId,
    Stripe_Payment_Intent_ID__c: payload.authnetTransactionId,
    Stripe_Payment_Method_ID__c: payload.authnetPaymentProfileId,
    Customer_Source__c: 'Website',
  }

  const contactResult = await sfPost(access_token, instance_url, 'Contact', contactBody)
  const contactId = contactResult.id

  // ── 2. Generate Cruzy Member ID & Create Membership__c ─────────────────────
  // Format: CRUZY-YYYYMMDD-XXXX (date + last 4 of Stripe customer ID)
  const datePart = today.replace(/-/g, '')
  const idSuffix = payload.authnetCustomerProfileId.slice(-6).toUpperCase()
  const cruzyMemberId = `CRUZY-${datePart}-${idSuffix}`

  // Expiration = 1 year from today
  const expDate = new Date()
  expDate.setFullYear(expDate.getFullYear() + 1)
  const expirationDate = expDate.toISOString().split('T')[0]

  // Next billing = 1 year from today
  const nextBilling = expirationDate

  const membershipBody: Record<string, unknown> = {
    Name: cruzyMemberId,
    Contact__c: contactId,
    Status__c: 'Active',
    Enroll_Date__c: today,
    Expiration_Date__c: expirationDate,
    Next_Billing_Date__c: nextBilling,
    Auto_Renewal__c: true,
    Partner__c: 'Cruzy+',
    Authorized_User__c: payload.authorizedUsers?.length
      ? payload.authorizedUsers
          .map((u) => [u.firstName, u.lastName].filter(Boolean).join(' '))
          .filter(Boolean)
          .join(', ')
      : '',
  }

  const membershipResult = await sfPost(access_token, instance_url, 'Membership__c', membershipBody)

  // Update Contact with the generated member number
  await fetch(`${instance_url}/services/data/v66.0/sobjects/Contact/${contactId}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ Cruzy_Plus_MBR_Number__c: cruzyMemberId }),
  })

  // ── 3. Create Saved_Card__c ────────────────────────────────────────────────
  const cardBrand = payload.cardBrand || 'Unknown'
  const last4 = payload.cardLast4 || '????'

  const savedCardBody: Record<string, unknown> = {
    Name: `${cardBrand} •••• ${last4}`,
    Contact__c: contactId,
    Card_Brand__c: cardBrand,
    Last_Four__c: last4,
    Expiry_Month__c: payload.cardExpMonth || null,
    Expiry_Year__c: payload.cardExpYear || null,
    Cardholder_Name__c: payload.nameOnCard,
    Is_Default__c: true,
    Stripe_Payment_Method_Id__c: payload.authnetPaymentProfileId,
  }

  const savedCardResult = await sfPost(access_token, instance_url, 'Saved_Card__c', savedCardBody)

  return {
    contactId,
    membershipId: membershipResult.id,
    savedCardId: savedCardResult.id,
    cruzyMemberId,
  }
}
