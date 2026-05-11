// Salesforce helpers for the customer portal

async function getToken() {
  if (process.env.SF_ACCESS_TOKEN && process.env.SF_INSTANCE_URL) {
    return { access_token: process.env.SF_ACCESS_TOKEN, instance_url: process.env.SF_INSTANCE_URL }
  }
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
  if (!res.ok) throw new Error(`SF OAuth failed: ${await res.text()}`)
  return res.json()
}

async function sfFetch(path: string, method = 'GET', body?: Record<string, unknown>) {
  const { access_token, instance_url } = await getToken()
  const res = await fetch(`${instance_url}/services/data/v62.0${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${access_token}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  })
  if (!res.ok && res.status !== 204) {
    const err = await res.text()
    throw new Error(`SF ${method} ${path} failed (${res.status}): ${err}`)
  }
  if (res.status === 204) return null
  return res.json()
}

export async function findContactByEmail(email: string) {
  const q = encodeURIComponent(
    `SELECT Id, FirstName, LastName, Email, Phone, Cruzy_Plus_MBR_Number__c, VIFP_Level__c, Portal_Status__c, Portal_Password_Hash__c, Portal_Last_Login__c, Portal_Login_Count__c FROM Contact WHERE Email = '${email}' LIMIT 1`
  )
  const data = await sfFetch(`/query/?q=${q}`)
  return data?.records?.[0] ?? null
}

export async function findContactById(id: string) {
  const q = encodeURIComponent(
    `SELECT Id, FirstName, LastName, Email, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Cruzy_Plus_MBR_Number__c, VIFP_Level__c, Portal_Status__c, Portal_Last_Login__c, Portal_Login_Count__c, Cruzy_Plus_Enrolled__c FROM Contact WHERE Id = '${id}' LIMIT 1`
  )
  const data = await sfFetch(`/query/?q=${q}`)
  return data?.records?.[0] ?? null
}

export async function findContactByResetToken(token: string) {
  const q = encodeURIComponent(
    `SELECT Id, Email, FirstName, Portal_Reset_Expiry__c FROM Contact WHERE Portal_Reset_Token__c = '${token}' LIMIT 1`
  )
  const data = await sfFetch(`/query/?q=${q}`)
  return data?.records?.[0] ?? null
}

export async function updateContact(id: string, fields: Record<string, unknown>) {
  return sfFetch(`/sobjects/Contact/${id}`, 'PATCH', fields)
}

export async function getContactMemberships(contactId: string) {
  const q = encodeURIComponent(
    `SELECT Id, Name, Status__c, Enroll_Date__c, Expiration_Date__c, Next_Billing_Date__c, Auto_Renewal__c, Partner__c, Biennial__c FROM Membership__c WHERE Contact__c = '${contactId}' ORDER BY Enroll_Date__c DESC`
  )
  const data = await sfFetch(`/query/?q=${q}`)
  return data?.records ?? []
}

export async function getContactBookings(contactId: string) {
  const q = encodeURIComponent(
    `SELECT Id, Name, Status__c, Ship__c, Itinerary__c, Departure_Date__c, Departure_Port__c, Cabin_Category__c, PAX_Count__c, Original_Cruise_Total__c, Current_Balance_Due__c FROM Booking__c WHERE Contact__c = '${contactId}' ORDER BY Departure_Date__c DESC LIMIT 20`
  )
  const data = await sfFetch(`/query/?q=${q}`)
  return data?.records ?? []
}

export async function getContactRewards(contactId: string) {
  const q = encodeURIComponent(
    `SELECT Id, Name, Status__c, Reward_Number__c, Reward_Location__c, Issue_Date__c, Book_By_Date__c, Expiration_Date__c, Partner__c FROM Reward__c WHERE Contact__c = '${contactId}' ORDER BY Expiration_Date__c ASC`
  )
  const data = await sfFetch(`/query/?q=${q}`)
  return data?.records ?? []
}

export async function getContactSavedCards(contactId: string) {
  const q = encodeURIComponent(
    `SELECT Id, Name, Card_Brand__c, Last_Four__c, Expiry_Month__c, Expiry_Year__c, Is_Default__c FROM Saved_Card__c WHERE Contact__c = '${contactId}' ORDER BY Is_Default__c DESC`
  )
  const data = await sfFetch(`/query/?q=${q}`)
  return data?.records ?? []
}
