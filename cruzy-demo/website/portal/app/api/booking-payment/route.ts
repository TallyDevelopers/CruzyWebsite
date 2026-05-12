import { NextRequest, NextResponse } from 'next/server'
import { verifyToken } from '@/lib/auth'
import {
  getSavedCardById,
  getContactAuthnetProfile,
  getBookingById,
  createBookingPayment,
  updateBookingBalance,
  createSavedCard,
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
  const clean = text.replace(/^\uFEFF/, '')
  return JSON.parse(clean)
}

interface AuthnetMessages {
  resultCode: string
  message: Array<{ code: string; text: string }>
}

function checkResult(result: Record<string, unknown>, context: string) {
  const messages = result.messages as AuthnetMessages | undefined
  if (!messages || messages.resultCode !== 'Ok') {
    const errText = messages?.message?.[0]?.text || `${context} failed`
    throw new Error(errText)
  }
}

async function chargeCustomerProfile(data: {
  customerProfileId: string
  customerPaymentProfileId: string
  amount: number
  description: string
}): Promise<{ transactionId: string }> {
  const payload = {
    createTransactionRequest: {
      merchantAuthentication: { name: API_LOGIN_ID, transactionKey: TRANSACTION_KEY },
      transactionRequest: {
        transactionType: 'authCaptureTransaction',
        amount: data.amount.toFixed(2),
        profile: {
          customerProfileId: data.customerProfileId,
          paymentProfile: { paymentProfileId: data.customerPaymentProfileId },
        },
        order: { description: data.description.substring(0, 255) },
      },
    },
  }

  const result = await authnetPost(payload)
  checkResult(result, 'Charge card')

  const txnResponse = result.transactionResponse as {
    responseCode: string
    transId: string
    errors?: Array<{ errorCode: string; errorText: string }>
  } | undefined

  if (!txnResponse || txnResponse.responseCode !== '1') {
    const errText = txnResponse?.errors?.[0]?.errorText || 'Transaction declined'
    throw new Error(errText)
  }

  return { transactionId: txnResponse.transId }
}

async function createCustomerProfileFromOpaque(data: {
  email: string
  firstName: string
  lastName: string
  opaqueDataDescriptor: string
  opaqueDataValue: string
}): Promise<{ customerProfileId: string; customerPaymentProfileId: string }> {
  const payload = {
    createCustomerProfileRequest: {
      merchantAuthentication: { name: API_LOGIN_ID, transactionKey: TRANSACTION_KEY },
      profile: {
        merchantCustomerId: `CRUZY-${Date.now()}`,
        email: data.email,
        paymentProfiles: {
          customerType: 'individual',
          billTo: { firstName: data.firstName, lastName: data.lastName },
          payment: {
            opaqueData: {
              dataDescriptor: data.opaqueDataDescriptor,
              dataValue: data.opaqueDataValue,
            },
          },
        },
      },
      validationMode: AUTHNET_ENV === 'production' ? 'liveMode' : 'testMode',
    },
  }

  const result = await authnetPost(payload) as {
    messages: AuthnetMessages
    customerProfileId: string
    customerPaymentProfileIdList: string[]
  }

  checkResult(result as unknown as Record<string, unknown>, 'Create customer profile')

  return {
    customerProfileId: result.customerProfileId,
    customerPaymentProfileId: result.customerPaymentProfileIdList[0],
  }
}

async function addPaymentProfileFromOpaque(data: {
  customerProfileId: string
  opaqueDataDescriptor: string
  opaqueDataValue: string
  firstName: string
  lastName: string
}): Promise<string> {
  const payload = {
    createCustomerPaymentProfileRequest: {
      merchantAuthentication: { name: API_LOGIN_ID, transactionKey: TRANSACTION_KEY },
      customerProfileId: data.customerProfileId,
      paymentProfile: {
        billTo: { firstName: data.firstName, lastName: data.lastName },
        payment: {
          opaqueData: {
            dataDescriptor: data.opaqueDataDescriptor,
            dataValue: data.opaqueDataValue,
          },
        },
      },
      validationMode: AUTHNET_ENV === 'production' ? 'liveMode' : 'testMode',
    },
  }

  const result = await authnetPost(payload) as {
    messages: AuthnetMessages
    customerPaymentProfileId: string
  }
  checkResult(result as unknown as Record<string, unknown>, 'Add payment profile')
  return result.customerPaymentProfileId
}

async function getCardDetails(data: {
  customerProfileId: string
  customerPaymentProfileId: string
}): Promise<{ cardType: string; cardNumber: string; expirationDate: string }> {
  const payload = {
    getCustomerPaymentProfileRequest: {
      merchantAuthentication: { name: API_LOGIN_ID, transactionKey: TRANSACTION_KEY },
      customerProfileId: data.customerProfileId,
      customerPaymentProfileId: data.customerPaymentProfileId,
    },
  }

  const result = await authnetPost(payload) as {
    paymentProfile?: {
      payment?: {
        creditCard?: { cardNumber: string; expirationDate: string; cardType: string }
      }
    }
  }

  const card = result.paymentProfile?.payment?.creditCard
  return {
    cardType: card?.cardType || 'Card',
    cardNumber: card?.cardNumber || 'XXXX',
    expirationDate: card?.expirationDate || '',
  }
}

export async function POST(req: NextRequest) {
  try {
    const sessionCookie = req.cookies.get('cruzy_session')?.value
    if (!sessionCookie) {
      return NextResponse.json({ success: false, error: 'Not authenticated' }, { status: 401 })
    }
    const payload = verifyToken(sessionCookie)
    if (!payload) {
      return NextResponse.json({ success: false, error: 'Session expired' }, { status: 401 })
    }

    const body = await req.json()
    const { bookingId, amount, note } = body

    if (!bookingId || !amount || amount <= 0) {
      return NextResponse.json({ success: false, error: 'Booking and valid amount required' }, { status: 400 })
    }

    const booking = await getBookingById(bookingId)
    if (!booking) {
      return NextResponse.json({ success: false, error: 'Booking not found' }, { status: 404 })
    }

    if (booking.Contact__c !== payload.contactId) {
      return NextResponse.json({ success: false, error: 'Unauthorized' }, { status: 403 })
    }

    if (amount > (booking.Current_Balance_Due__c || 0)) {
      return NextResponse.json({
        success: false,
        error: `Amount ($${amount}) exceeds balance due ($${booking.Current_Balance_Due__c})`,
      }, { status: 400 })
    }

    let transactionId: string
    let customerProfileId = await getContactAuthnetProfile(payload.contactId)

    if (body.savedCardId) {
      // ── Charge a saved card ────────────────────────────────────────────────
      const card = await getSavedCardById(body.savedCardId)
      if (!card || card.Contact__c !== payload.contactId) {
        return NextResponse.json({ success: false, error: 'Card not found' }, { status: 404 })
      }

      if (!customerProfileId || !card.Authnet_Payment_Profile_Id__c) {
        return NextResponse.json({
          success: false,
          error: 'Card has no Authorize.net profile. Please add a new card.',
        }, { status: 400 })
      }

      const chargeResult = await chargeCustomerProfile({
        customerProfileId,
        customerPaymentProfileId: card.Authnet_Payment_Profile_Id__c,
        amount,
        description: `${booking.Name} — ${card.Card_Brand__c} •••• ${card.Last_Four__c}`,
      })
      transactionId = chargeResult.transactionId

    } else if (body.opaqueDataDescriptor && body.opaqueDataValue) {
      // ── Charge a new card (via Accept.js token) ────────────────────────────
      let paymentProfileId: string

      if (customerProfileId) {
        paymentProfileId = await addPaymentProfileFromOpaque({
          customerProfileId,
          opaqueDataDescriptor: body.opaqueDataDescriptor,
          opaqueDataValue: body.opaqueDataValue,
          firstName: body.firstName || 'Member',
          lastName: body.lastName || '',
        })
      } else {
        const profile = await createCustomerProfileFromOpaque({
          email: body.email || '',
          firstName: body.firstName || 'Member',
          lastName: body.lastName || '',
          opaqueDataDescriptor: body.opaqueDataDescriptor,
          opaqueDataValue: body.opaqueDataValue,
        })
        customerProfileId = profile.customerProfileId
        paymentProfileId = profile.customerPaymentProfileId

        await updateContactAuthnetProfile(payload.contactId, customerProfileId)
      }

      const chargeResult = await chargeCustomerProfile({
        customerProfileId,
        customerPaymentProfileId: paymentProfileId,
        amount,
        description: `${booking.Name} — New card payment`,
      })
      transactionId = chargeResult.transactionId

      if (body.saveCard) {
        const cardDetails = await getCardDetails({ customerProfileId, customerPaymentProfileId: paymentProfileId })
        const last4 = cardDetails.cardNumber.slice(-4)
        const [expYear, expMonth] = cardDetails.expirationDate.includes('-')
          ? cardDetails.expirationDate.split('-')
          : [cardDetails.expirationDate.slice(0, 4), cardDetails.expirationDate.slice(4, 6)]

        await createSavedCard(payload.contactId, {
          cardBrand: cardDetails.cardType,
          lastFour: last4,
          expiryMonth: parseInt(expMonth || '0'),
          expiryYear: parseInt(expYear || '0'),
          cardholderName: body.nameOnCard || `${body.firstName || ''} ${body.lastName || ''}`.trim(),
          isDefault: false,
          paymentProfileId,
        })
      }
    } else {
      return NextResponse.json({ success: false, error: 'Provide savedCardId or payment token' }, { status: 400 })
    }

    const paymentNote = note || `Online payment · txn ${transactionId}`
    await createBookingPayment(bookingId, amount, paymentNote, transactionId)

    const newBalance = Math.max(0, (booking.Current_Balance_Due__c || 0) - amount)
    await updateBookingBalance(bookingId, newBalance)

    return NextResponse.json({
      success: true,
      transactionId,
      amountCharged: amount,
      newBalance,
    })
  } catch (err) {
    const error = err as { message?: string }
    console.error('Booking payment error:', error)
    return NextResponse.json(
      { success: false, error: error.message || 'Payment failed' },
      { status: 500 }
    )
  }
}
