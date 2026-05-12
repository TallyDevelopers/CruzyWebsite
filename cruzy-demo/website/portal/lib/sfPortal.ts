// Salesforce helpers for the customer portal

let cachedToken: { access_token: string; instance_url: string; expiresAt: number } | null = null
let pendingRefresh: Promise<{ access_token: string; instance_url: string }> | null = null

async function refreshToken(): Promise<{ access_token: string; instance_url: string }> {
  const params = new URLSearchParams({
    grant_type: 'client_credentials',
    client_id: process.env.SF_CLIENT_ID!,
    client_secret: process.env.SF_CLIENT_SECRET!,
  })
  const res = await fetch(`${process.env.SF_INSTANCE_URL}/services/oauth2/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString(),
  })
  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Salesforce client_credentials auth failed: ${err}`)
  }
  const data = await res.json()
  cachedToken = {
    access_token: data.access_token,
    instance_url: data.instance_url || process.env.SF_INSTANCE_URL!,
    expiresAt: Date.now() + 90 * 60 * 1000,
  }
  return { access_token: cachedToken.access_token, instance_url: cachedToken.instance_url }
}

export async function getToken() {
  if (process.env.SF_CLIENT_ID && process.env.SF_CLIENT_SECRET && process.env.SF_INSTANCE_URL) {
    if (cachedToken && Date.now() < cachedToken.expiresAt) {
      return { access_token: cachedToken.access_token, instance_url: cachedToken.instance_url }
    }
    // Deduplicate concurrent refresh requests
    if (!pendingRefresh) {
      pendingRefresh = refreshToken().finally(() => { pendingRefresh = null })
    }
    return pendingRefresh
  }

  if (process.env.SF_ACCESS_TOKEN && process.env.SF_INSTANCE_URL) {
    return { access_token: process.env.SF_ACCESS_TOKEN, instance_url: process.env.SF_INSTANCE_URL }
  }

  throw new Error('No Salesforce credentials configured. Set SF_CLIENT_ID + SF_CLIENT_SECRET, or SF_ACCESS_TOKEN for dev.')
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
    `SELECT Id, Name, Card_Brand__c, Last_Four__c, Expiry_Month__c, Expiry_Year__c, Is_Default__c, Authnet_Payment_Profile_Id__c FROM Saved_Card__c WHERE Contact__c = '${contactId}' ORDER BY Is_Default__c DESC`
  )
  const data = await sfFetch(`/query/?q=${q}`)
  return data?.records ?? []
}

export async function getSavedCardById(cardId: string) {
  const q = encodeURIComponent(
    `SELECT Id, Name, Card_Brand__c, Last_Four__c, Expiry_Month__c, Expiry_Year__c, Is_Default__c, Authnet_Payment_Profile_Id__c, Contact__c FROM Saved_Card__c WHERE Id = '${cardId}' LIMIT 1`
  )
  const data = await sfFetch(`/query/?q=${q}`)
  return data?.records?.[0] ?? null
}

export async function getContactAuthnetProfile(contactId: string) {
  const q = encodeURIComponent(
    `SELECT Id, Authnet_Customer_Profile_ID__c FROM Contact WHERE Id = '${contactId}' LIMIT 1`
  )
  const data = await sfFetch(`/query/?q=${q}`)
  return data?.records?.[0]?.Authnet_Customer_Profile_ID__c ?? null
}

export async function getBookingById(bookingId: string) {
  const q = encodeURIComponent(
    `SELECT Id, Name, Contact__c, Current_Balance_Due__c, Original_Cruise_Total__c, Ship__c, Status__c FROM Booking__c WHERE Id = '${bookingId}' LIMIT 1`
  )
  const data = await sfFetch(`/query/?q=${q}`)
  return data?.records?.[0] ?? null
}

export async function createBookingPayment(
  bookingId: string, amount: number, note: string, transactionId: string
) {
  const today = new Date().toISOString().split('T')[0]
  return sfFetch('/sobjects/Booking_Payment__c', 'POST', {
    Booking__c: bookingId,
    Amount__c: amount,
    Payment_Date__c: today,
    Note__c: note,
    Authnet_Transaction_ID__c: transactionId,
  })
}

export async function updateBookingBalance(bookingId: string, newBalance: number) {
  return sfFetch(`/sobjects/Booking__c/${bookingId}`, 'PATCH', {
    Current_Balance_Due__c: Math.max(0, newBalance),
  })
}

export async function createSavedCard(contactId: string, fields: {
  cardBrand: string; lastFour: string; expiryMonth: number; expiryYear: number;
  cardholderName: string; isDefault: boolean; paymentProfileId: string;
}) {
  return sfFetch('/sobjects/Saved_Card__c', 'POST', {
    Name: `${fields.cardBrand} •••• ${fields.lastFour}`,
    Contact__c: contactId,
    Card_Brand__c: fields.cardBrand,
    Last_Four__c: fields.lastFour,
    Expiry_Month__c: fields.expiryMonth,
    Expiry_Year__c: fields.expiryYear,
    Cardholder_Name__c: fields.cardholderName,
    Is_Default__c: fields.isDefault,
    Authnet_Payment_Profile_Id__c: fields.paymentProfileId,
  })
}

export async function deleteSavedCard(cardId: string) {
  return sfFetch(`/sobjects/Saved_Card__c/${cardId}`, 'DELETE')
}

export async function setDefaultCard(cardId: string, contactId: string) {
  const cards = await getContactSavedCards(contactId)
  for (const card of cards) {
    const shouldBeDefault = card.Id === cardId
    if (card.Is_Default__c !== shouldBeDefault) {
      await sfFetch(`/sobjects/Saved_Card__c/${card.Id}`, 'PATCH', {
        Is_Default__c: shouldBeDefault,
      })
    }
  }
}

export async function updateContactAuthnetProfile(contactId: string, profileId: string) {
  return sfFetch(`/sobjects/Contact/${contactId}`, 'PATCH', {
    Authnet_Customer_Profile_ID__c: profileId,
  })
}
