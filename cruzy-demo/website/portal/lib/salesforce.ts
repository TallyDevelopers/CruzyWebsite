import { getToken } from './sfPortal'

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

  // ── 1. Create Person Account ──────────────────────────────────────────────
  const accountBody: Record<string, unknown> = {
    RecordTypeId: '012al000005f9XVAAY',
    FirstName: payload.firstName,
    LastName: payload.lastName,
    PersonEmail: payload.email,
    PersonMobilePhone: payload.phone,
    PersonMailingStreet: mailingStreet,
    PersonMailingCity: payload.city,
    PersonMailingState: payload.state || '',
    PersonMailingPostalCode: payload.postalCode,
    PersonMailingCountry: payload.country,
    Spouse_Significant_Other__pc: spouseName || '',
    Cruzy_Plus_Enrolled__pc: true,
    Authnet_Customer_Profile_ID__pc: payload.authnetCustomerProfileId,
    Authnet_Transaction_ID__pc: payload.authnetTransactionId,
    Authnet_Payment_Profile_ID__pc: payload.authnetPaymentProfileId,
    Customer_Source__pc: 'Website',
  }

  const accountResult = await sfPost(access_token, instance_url, 'Account', accountBody)
  const accountId = accountResult.id

  // Retrieve the PersonContactId for child object lookups
  const acctRes = await fetch(`${instance_url}/services/data/v66.0/sobjects/Account/${accountId}?fields=PersonContactId`, {
    headers: { Authorization: `Bearer ${access_token}` },
  })
  const acctData = await acctRes.json() as { PersonContactId: string }
  const contactId = acctData.PersonContactId

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

  // Update Person Account with the generated member number (via Contact)
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
    Authnet_Payment_Profile_Id__c: payload.authnetPaymentProfileId,
  }

  const savedCardResult = await sfPost(access_token, instance_url, 'Saved_Card__c', savedCardBody)

  return {
    contactId,
    membershipId: membershipResult.id,
    savedCardId: savedCardResult.id,
    cruzyMemberId,
  }
}
