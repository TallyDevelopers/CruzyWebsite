import { NextRequest, NextResponse } from 'next/server'
import { verifyToken } from '@/lib/auth'
import {
  getContactSavedCards,
  getSavedCardById,
  deleteSavedCard,
  setDefaultCard,
  createSavedCard,
  getContactAuthnetProfile,
  updateContactAuthnetProfile,
} from '@/lib/sfPortal'

const API_LOGIN_ID = process.env.AUTHNET_API_LOGIN_ID!
const TRANSACTION_KEY = process.env.AUTHNET_TRANSACTION_KEY!
const AUTHNET_ENV = process.env.NEXT_PUBLIC_AUTHNET_ENV || 'sandbox'
const AUTHNET_URL =
  AUTHNET_ENV === 'production'
    ? 'https://api.authorize.net/xml/v1/request.api'
    : 'https://apitest.authorize.net/xml/v1/request.api'

async function authnetPost(payload: object): Promise<Record<string, unknown>> {
  const res = await fetch(AUTHNET_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  })
  const text = await res.text()
  return JSON.parse(text.replace(/^\uFEFF/, ''))
}

async function authenticate(req: NextRequest) {
  const sessionCookie = req.cookies.get('cruzy_session')?.value
  if (!sessionCookie) {
    return { contactId: '', error: NextResponse.json({ success: false, error: 'Not authenticated' }, { status: 401 }) }
  }
  const payload = verifyToken(sessionCookie)
  if (!payload) {
    return { contactId: '', error: NextResponse.json({ success: false, error: 'Session expired' }, { status: 401 }) }
  }
  return { contactId: payload.contactId as string, error: null }
}

export async function GET(req: NextRequest) {
  const { contactId, error } = await authenticate(req)
  if (error) return error

  try {
    const cards = await getContactSavedCards(contactId)
    return NextResponse.json({ success: true, cards })
  } catch (err) {
    console.error('Cards fetch error:', err)
    return NextResponse.json({ success: false, error: 'Failed to load cards' }, { status: 500 })
  }
}

export async function POST(req: NextRequest) {
  const { contactId, error } = await authenticate(req)
  if (error) return error

  try {
    const body = await req.json()
    const { action } = body

    if (action === 'delete') {
      const card = await getSavedCardById(body.cardId)
      if (!card || card.Contact__c !== contactId) {
        return NextResponse.json({ success: false, error: 'Card not found' }, { status: 404 })
      }

      // Try to delete from Authorize.net
      if (card.Authnet_Payment_Profile_Id__c) {
        try {
          const customerProfileId = await getContactAuthnetProfile(contactId)
          if (customerProfileId) {
            await authnetPost({
              deleteCustomerPaymentProfileRequest: {
                merchantAuthentication: { name: API_LOGIN_ID, transactionKey: TRANSACTION_KEY },
                customerProfileId,
                customerPaymentProfileId: card.Authnet_Payment_Profile_Id__c,
              },
            })
          }
        } catch (e) {
          console.warn('Authnet profile delete failed (non-blocking):', e)
        }
      }

      await deleteSavedCard(body.cardId)
      return NextResponse.json({ success: true })

    } else if (action === 'setDefault') {
      await setDefaultCard(body.cardId, contactId)
      return NextResponse.json({ success: true })

    } else if (action === 'add') {
      const { opaqueDataDescriptor, opaqueDataValue, firstName, lastName, email, nameOnCard } = body

      if (!opaqueDataDescriptor || !opaqueDataValue) {
        return NextResponse.json({ success: false, error: 'Payment token required' }, { status: 400 })
      }

      let customerProfileId = await getContactAuthnetProfile(contactId)
      let paymentProfileId: string

      if (customerProfileId) {
        const addResult = await authnetPost({
          createCustomerPaymentProfileRequest: {
            merchantAuthentication: { name: API_LOGIN_ID, transactionKey: TRANSACTION_KEY },
            customerProfileId,
            paymentProfile: {
              billTo: { firstName: firstName || 'Member', lastName: lastName || '' },
              payment: {
                opaqueData: { dataDescriptor: opaqueDataDescriptor, dataValue: opaqueDataValue },
              },
            },
            validationMode: AUTHNET_ENV === 'production' ? 'liveMode' : 'testMode',
          },
        }) as { messages: { resultCode: string; message: Array<{ text: string }> }; customerPaymentProfileId: string }

        if (addResult.messages.resultCode !== 'Ok') {
          throw new Error(addResult.messages.message[0]?.text || 'Failed to add card')
        }
        paymentProfileId = addResult.customerPaymentProfileId
      } else {
        const createResult = await authnetPost({
          createCustomerProfileRequest: {
            merchantAuthentication: { name: API_LOGIN_ID, transactionKey: TRANSACTION_KEY },
            profile: {
              merchantCustomerId: `CRUZY-${Date.now()}`,
              email: email || '',
              paymentProfiles: {
                customerType: 'individual',
                billTo: { firstName: firstName || 'Member', lastName: lastName || '' },
                payment: {
                  opaqueData: { dataDescriptor: opaqueDataDescriptor, dataValue: opaqueDataValue },
                },
              },
            },
            validationMode: AUTHNET_ENV === 'production' ? 'liveMode' : 'testMode',
          },
        }) as {
          messages: { resultCode: string; message: Array<{ text: string }> }
          customerProfileId: string
          customerPaymentProfileIdList: string[]
        }

        if (createResult.messages.resultCode !== 'Ok') {
          throw new Error(createResult.messages.message[0]?.text || 'Failed to create profile')
        }
        customerProfileId = createResult.customerProfileId
        paymentProfileId = createResult.customerPaymentProfileIdList[0]
        await updateContactAuthnetProfile(contactId, customerProfileId)
      }

      // Get card details from Authorize.net
      const detailsResult = await authnetPost({
        getCustomerPaymentProfileRequest: {
          merchantAuthentication: { name: API_LOGIN_ID, transactionKey: TRANSACTION_KEY },
          customerProfileId,
          customerPaymentProfileId: paymentProfileId,
        },
      }) as {
        paymentProfile?: { payment?: { creditCard?: { cardNumber: string; expirationDate: string; cardType: string } } }
      }

      const cc = detailsResult.paymentProfile?.payment?.creditCard
      const last4 = (cc?.cardNumber || 'XXXX').slice(-4)
      const [expYear, expMonth] = (cc?.expirationDate || '').includes('-')
        ? (cc?.expirationDate || '').split('-')
        : [(cc?.expirationDate || '').slice(0, 4), (cc?.expirationDate || '').slice(4, 6)]

      const existingCards = await getContactSavedCards(contactId)
      const isFirst = existingCards.length === 0

      await createSavedCard(contactId, {
        cardBrand: cc?.cardType || 'Card',
        lastFour: last4,
        expiryMonth: parseInt(expMonth || '0'),
        expiryYear: parseInt(expYear || '0'),
        cardholderName: nameOnCard || `${firstName || ''} ${lastName || ''}`.trim(),
        isDefault: isFirst,
        paymentProfileId,
      })

      return NextResponse.json({ success: true, cardBrand: cc?.cardType, lastFour: last4 })

    } else {
      return NextResponse.json({ success: false, error: 'Invalid action' }, { status: 400 })
    }
  } catch (err) {
    const error = err as { message?: string }
    console.error('Cards action error:', error)
    return NextResponse.json(
      { success: false, error: error.message || 'Card operation failed' },
      { status: 500 }
    )
  }
}
