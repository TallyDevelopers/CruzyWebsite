'use client'

import { useEffect, useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Script from 'next/script'
import SiteHeader from '@/components/SiteHeader'
import SiteFooter from '@/components/SiteFooter'

interface Contact {
  Id: string; FirstName: string; LastName: string; Email: string; Phone: string
  MailingCity: string; MailingState: string; Cruzy_Plus_MBR_Number__c: string
  VIFP_Level__c: string; Portal_Last_Login__c: string; Portal_Login_Count__c: number
  Cruzy_Plus_Enrolled__c: boolean
}

interface Membership {
  Id: string; Name: string; Status__c: string; Enroll_Date__c: string
  Expiration_Date__c: string; Next_Billing_Date__c: string; Auto_Renewal__c: boolean; Partner__c: string
}

interface Booking {
  Id: string; Name: string; Status__c: string; Ship__c: string; Itinerary__c: string
  Departure_Date__c: string; Departure_Port__c: string; Cabin_Category__c: string
  PAX_Count__c: number; Original_Cruise_Total__c: number; Current_Balance_Due__c: number
}

interface Reward {
  Id: string; Name: string; Status__c: string; Reward_Number__c: string
  Reward_Location__c: string; Issue_Date__c: string; Book_By_Date__c: string; Expiration_Date__c: string
}

interface SavedCard {
  Id: string; Name: string; Card_Brand__c: string; Last_Four__c: string
  Expiry_Month__c: string; Expiry_Year__c: string; Is_Default__c: boolean
}

type Tab = 'overview' | 'bookings' | 'membership' | 'rewards' | 'cards'

const fmt = (d: string) => d ? new Date(d).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }) : '—'
const fmtMoney = (n: number) => n != null ? `$${n.toLocaleString('en-US', { minimumFractionDigits: 2 })}` : '—'

const statusColor = (s: string) => {
  if (!s) return '#767676'
  const l = s.toLowerCase()
  if (l === 'active' || l === 'booking' || l === 'completed') return '#1a8a4a'
  if (l === 'quote') return '#b36b00'
  if (l === 'cancelled' || l === 'expired' || l === 'inactive') return '#bd1f34'
  if (l === 'used') return '#10559a'
  return '#767676'
}

const statusBg = (s: string) => {
  const c = statusColor(s)
  return { color: c, background: c + '18', borderRadius: '20px', padding: '3px 12px', fontSize: '12px', fontWeight: 600 } as const
}

const vifpColor: Record<string, string> = {
  Red: '#bd1f34', Gold: '#b8860b', Platinum: '#7b7b7b', Diamond: '#1a6ebd', 'Diamond Plus': '#6a0dad',
}

const AUTHNET_ENV = process.env.NEXT_PUBLIC_AUTHNET_ENV || 'sandbox'
const ACCEPT_JS_URL = AUTHNET_ENV === 'production'
  ? 'https://js.authorize.net/v1/Accept.js'
  : 'https://jstest.authorize.net/v1/Accept.js'

const btnPrimary: React.CSSProperties = {
  background: '#10559a', color: '#fff', border: 'none', borderRadius: '8px',
  padding: '10px 20px', fontSize: '14px', fontWeight: 600, cursor: 'pointer',
  fontFamily: 'Poppins, sans-serif',
}
const btnGhost: React.CSSProperties = {
  background: 'transparent', color: '#767676', border: '1px solid #dde3ec', borderRadius: '8px',
  padding: '10px 20px', fontSize: '14px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif',
}
const modalOverlay: React.CSSProperties = {
  position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 1000,
  display: 'flex', alignItems: 'center', justifyContent: 'center',
}
const modalBox: React.CSSProperties = {
  background: '#fff', borderRadius: '16px', width: '100%', maxWidth: '480px',
  maxHeight: '90vh', overflow: 'auto', boxShadow: '0 20px 60px rgba(0,0,0,0.2)',
}
const inputStyle: React.CSSProperties = {
  width: '100%', padding: '10px 14px', border: '1px solid #dde3ec', borderRadius: '8px',
  fontSize: '14px', fontFamily: 'Poppins, sans-serif', outline: 'none', boxSizing: 'border-box',
}
const labelStyle: React.CSSProperties = {
  display: 'block', fontSize: '12px', fontWeight: 600, color: '#767676',
  textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '6px',
}

export default function AccountPage() {
  const router = useRouter()
  const [tab, setTab] = useState<Tab>('overview')
  const [data, setData] = useState<{ contact: Contact; memberships: Membership[]; bookings: Booking[]; rewards: Reward[]; savedCards: SavedCard[] } | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  // Payment modal state
  const [payBooking, setPayBooking] = useState<Booking | null>(null)
  const [payMethod, setPayMethod] = useState<'saved' | 'new'>('saved')
  const [payCardId, setPayCardId] = useState('')
  const [payAmount, setPayAmount] = useState('')
  const [payProcessing, setPayProcessing] = useState(false)
  const [payError, setPayError] = useState('')
  const [paySuccess, setPaySuccess] = useState('')

  // New card fields (for payment modal and add card)
  const [newCardName, setNewCardName] = useState('')
  const [newCardNumber, setNewCardNumber] = useState('')
  const [newCardExpiry, setNewCardExpiry] = useState('')
  const [newCardCvv, setNewCardCvv] = useState('')
  const [saveNewCard, setSaveNewCard] = useState(true)

  // Add card modal
  const [showAddCard, setShowAddCard] = useState(false)
  const [addCardProcessing, setAddCardProcessing] = useState(false)
  const [addCardError, setAddCardError] = useState('')

  // Card action state
  const [cardActionLoading, setCardActionLoading] = useState('')

  // Accept.js ready
  const [, setAcceptReady] = useState(false)

  const loadData = useCallback(() => {
    fetch('/api/account')
      .then(r => r.json())
      .then(d => {
        if (d.success) {
          setData(d)
        } else if (d.error === 'Not authenticated' || d.error === 'Session expired') {
          router.push('/login')
        } else {
          setError(d.error || 'Failed to load account')
        }
      })
      .catch(() => setError('Failed to load account data'))
      .finally(() => setLoading(false))
  }, [router])

  useEffect(() => { loadData() }, [loadData])

  async function handleLogout() {
    await fetch('/api/auth/logout', { method: 'POST' })
    router.push('/login')
  }

  function resetNewCard() {
    setNewCardName(''); setNewCardNumber(''); setNewCardExpiry(''); setNewCardCvv('')
    setSaveNewCard(true)
  }

  function tokenizeCard(): Promise<{ dataDescriptor: string; dataValue: string }> {
    return new Promise((resolve, reject) => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const acceptLib = (window as any).Accept
      if (!acceptLib) { reject(new Error('Accept.js not loaded. Please refresh.')); return }
      const raw = newCardNumber.replace(/\D/g, '')
      const expRaw = newCardExpiry.replace(/\D/g, '')
      if (raw.length < 13) { reject(new Error('Invalid card number')); return }
      if (expRaw.length < 4) { reject(new Error('Invalid expiry')); return }
      if (!newCardCvv || newCardCvv.length < 3) { reject(new Error('Invalid CVV')); return }

      acceptLib.dispatchData(
        {
          authData: {
            clientKey: process.env.NEXT_PUBLIC_AUTHNET_CLIENT_KEY || '',
            apiLoginID: process.env.NEXT_PUBLIC_AUTHNET_API_LOGIN_ID || '',
          },
          cardData: {
            cardNumber: raw,
            month: expRaw.substring(0, 2),
            year: '20' + expRaw.substring(2, 4),
            cardCode: newCardCvv,
          },
        },
        (response: { opaqueData?: { dataDescriptor: string; dataValue: string }; messages?: { resultCode: string; message: Array<{ code: string; text: string }> } }) => {
          if (response.opaqueData) {
            resolve(response.opaqueData)
          } else {
            reject(new Error(response.messages?.message?.[0]?.text || 'Tokenization failed'))
          }
        }
      )
    })
  }

  // ── Pay Booking Balance ────────────────────────────────────────────────────

  function openPayModal(b: Booking) {
    setPayBooking(b)
    setPayMethod(data?.savedCards?.length ? 'saved' : 'new')
    setPayCardId(data?.savedCards?.find(c => c.Is_Default__c)?.Id || data?.savedCards?.[0]?.Id || '')
    setPayAmount(b.Current_Balance_Due__c.toFixed(2))
    setPayError(''); setPaySuccess('')
    resetNewCard()
  }

  async function processPayment() {
    if (!payBooking) return
    setPayProcessing(true); setPayError(''); setPaySuccess('')

    try {
      const amt = parseFloat(payAmount)
      if (!amt || amt <= 0) throw new Error('Enter a valid amount')
      if (amt > payBooking.Current_Balance_Due__c) throw new Error('Amount exceeds balance due')

      let body: Record<string, unknown> = { bookingId: payBooking.Id, amount: amt }

      if (payMethod === 'saved') {
        if (!payCardId) throw new Error('Select a card')
        body.savedCardId = payCardId
      } else {
        const token = await tokenizeCard()
        body = {
          ...body,
          opaqueDataDescriptor: token.dataDescriptor,
          opaqueDataValue: token.dataValue,
          saveCard: saveNewCard,
          firstName: data?.contact?.FirstName,
          lastName: data?.contact?.LastName,
          email: data?.contact?.Email,
          nameOnCard: newCardName,
        }
      }

      const res = await fetch('/api/booking-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      })
      const result = await res.json()

      if (!result.success) throw new Error(result.error || 'Payment failed')

      setPaySuccess(`Payment of ${fmtMoney(amt)} processed successfully! Transaction ID: ${result.transactionId}`)
      loadData()
    } catch (err) {
      setPayError((err as Error).message)
    } finally {
      setPayProcessing(false)
    }
  }

  // ── Card Management ────────────────────────────────────────────────────────

  async function handleDeleteCard(cardId: string) {
    if (!confirm('Remove this card?')) return
    setCardActionLoading(cardId)
    try {
      const res = await fetch('/api/cards', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'delete', cardId }),
      })
      const result = await res.json()
      if (!result.success) throw new Error(result.error)
      loadData()
    } catch (err) {
      alert((err as Error).message)
    } finally {
      setCardActionLoading('')
    }
  }

  async function handleSetDefault(cardId: string) {
    setCardActionLoading(cardId)
    try {
      const res = await fetch('/api/cards', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'setDefault', cardId }),
      })
      const result = await res.json()
      if (!result.success) throw new Error(result.error)
      loadData()
    } catch (err) {
      alert((err as Error).message)
    } finally {
      setCardActionLoading('')
    }
  }

  async function handleAddCard() {
    setAddCardProcessing(true); setAddCardError('')
    try {
      const token = await tokenizeCard()
      const res = await fetch('/api/cards', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'add',
          opaqueDataDescriptor: token.dataDescriptor,
          opaqueDataValue: token.dataValue,
          firstName: data?.contact?.FirstName,
          lastName: data?.contact?.LastName,
          email: data?.contact?.Email,
          nameOnCard: newCardName,
        }),
      })
      const result = await res.json()
      if (!result.success) throw new Error(result.error)
      setShowAddCard(false)
      resetNewCard()
      loadData()
    } catch (err) {
      setAddCardError((err as Error).message)
    } finally {
      setAddCardProcessing(false)
    }
  }

  function handleCardNumberInput(val: string) {
    const raw = val.replace(/\D/g, '').substring(0, 16)
    setNewCardNumber(raw.replace(/(.{4})/g, '$1 ').trim())
  }

  function handleExpiryInput(val: string) {
    const raw = val.replace(/\D/g, '').substring(0, 4)
    setNewCardExpiry(raw.length >= 2 ? raw.substring(0, 2) + ' / ' + raw.substring(2) : raw)
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  if (loading) {
    return (
      <div style={{ background: '#f5f7fa', minHeight: '100vh', fontFamily: 'Poppins, sans-serif' }}>
        <SiteHeader />
        <div className="portal-content">
          <div className="flex items-center justify-center" style={{ minHeight: '60vh' }}>
            <div style={{ textAlign: 'center', color: '#767676' }}>
              <div style={{ width: '48px', height: '48px', border: '4px solid #dde3ec', borderTopColor: '#10559a', borderRadius: '50%', animation: 'spin 0.8s linear infinite', margin: '0 auto 16px' }} />
              <p>Loading your account…</p>
            </div>
          </div>
          <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div style={{ background: '#f5f7fa', minHeight: '100vh', fontFamily: 'Poppins, sans-serif' }}>
        <SiteHeader />
        <div className="portal-content">
          <div className="flex items-center justify-center" style={{ minHeight: '60vh' }}>
            <div style={{ textAlign: 'center', color: '#bd1f34' }}>{error}</div>
          </div>
        </div>
      </div>
    )
  }

  const { contact, memberships, bookings, rewards, savedCards } = data!
  const activeMembership = memberships.find(m => m.Status__c === 'Active')
  const activeRewards = rewards.filter(r => r.Status__c === 'Active')
  const upcomingBookings = bookings.filter(b => b.Departure_Date__c && new Date(b.Departure_Date__c) >= new Date())

  const tabs: { id: Tab; label: string; count?: number }[] = [
    { id: 'overview', label: 'Overview' },
    { id: 'bookings', label: 'My Cruises', count: bookings.length },
    { id: 'membership', label: 'Membership', count: memberships.length },
    { id: 'rewards', label: 'Rewards', count: activeRewards.length },
    { id: 'cards', label: 'Payment', count: savedCards.length },
  ]

  const newCardFields = (
    <>
      <div style={{ marginBottom: '12px' }}>
        <label style={labelStyle}>Name on Card</label>
        <input style={inputStyle} placeholder="Jane Smith" value={newCardName} onChange={e => setNewCardName(e.target.value)} />
      </div>
      <div style={{ marginBottom: '12px' }}>
        <label style={labelStyle}>Card Number</label>
        <input style={inputStyle} placeholder="1234 5678 9012 3456" maxLength={19} value={newCardNumber} onChange={e => handleCardNumberInput(e.target.value)} />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
        <div>
          <label style={labelStyle}>Expiry</label>
          <input style={inputStyle} placeholder="MM / YY" maxLength={7} value={newCardExpiry} onChange={e => handleExpiryInput(e.target.value)} />
        </div>
        <div>
          <label style={labelStyle}>CVV</label>
          <input style={inputStyle} type="password" placeholder="•••" maxLength={4} value={newCardCvv} onChange={e => setNewCardCvv(e.target.value)} />
        </div>
      </div>
    </>
  )

  return (
    <div style={{ background: '#f5f7fa', minHeight: '100vh', fontFamily: 'Poppins, sans-serif' }}>
      <Script src={ACCEPT_JS_URL} onLoad={() => setAcceptReady(true)} />
      <SiteHeader />
      <div className="portal-content">

      {/* Hero banner */}
      <div style={{ background: '#10559a', color: '#fff', padding: '40px 0 0' }}>
        <div className="container mx-auto px-4">
          <div className="flex items-center justify-between flex-wrap gap-4 pb-6">
            <div className="flex items-center gap-4">
              <div style={{ background: 'rgba(255,255,255,0.15)', borderRadius: '50%', width: '64px', height: '64px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '26px', fontWeight: 700 }}>
                {contact.FirstName?.[0]}{contact.LastName?.[0]}
              </div>
              <div>
                <h1 style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '24px', margin: 0 }}>
                  {contact.FirstName} {contact.LastName}
                </h1>
                <p style={{ margin: '4px 0 0', color: '#7bb3e8', fontSize: '14px' }}>{contact.Email}</p>
                {contact.Cruzy_Plus_MBR_Number__c && (
                  <p style={{ margin: '2px 0 0', color: '#a8d0f5', fontSize: '13px', fontFamily: 'monospace' }}>
                    {contact.Cruzy_Plus_MBR_Number__c}
                  </p>
                )}
              </div>
            </div>

            <div className="flex items-center gap-3">
              {contact.VIFP_Level__c && (
                <span style={{ background: vifpColor[contact.VIFP_Level__c] || '#555', color: '#fff', borderRadius: '20px', padding: '6px 16px', fontSize: '13px', fontWeight: 700 }}>
                  VIFP {contact.VIFP_Level__c}
                </span>
              )}
              <button onClick={handleLogout} style={{ background: 'rgba(255,255,255,0.15)', border: '1px solid rgba(255,255,255,0.3)', color: '#fff', borderRadius: '8px', padding: '8px 18px', fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                Sign Out
              </button>
            </div>
          </div>

          {/* Tabs */}
          <div className="flex gap-0 overflow-x-auto">
            {tabs.map(t => (
              <button key={t.id} onClick={() => setTab(t.id)} style={{
                background: tab === t.id ? '#fff' : 'transparent',
                color: tab === t.id ? '#10559a' : 'rgba(255,255,255,0.75)',
                border: 'none', borderRadius: '8px 8px 0 0', padding: '12px 22px',
                fontSize: '14px', fontWeight: tab === t.id ? 700 : 500, cursor: 'pointer',
                fontFamily: 'Poppins, sans-serif', whiteSpace: 'nowrap',
                display: 'flex', alignItems: 'center', gap: '6px',
              }}>
                {t.label}
                {t.count != null && t.count > 0 && (
                  <span style={{ background: tab === t.id ? '#10559a' : 'rgba(255,255,255,0.25)', color: '#fff', borderRadius: '10px', padding: '1px 7px', fontSize: '11px', fontWeight: 700 }}>
                    {t.count}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="container mx-auto px-4 py-8">

        {/* ── OVERVIEW ── */}
        {tab === 'overview' && (
          <div className="grid gap-4" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))' }}>
            <div style={{ background: '#fff', borderRadius: '12px', padding: '24px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
              <p style={{ fontSize: '12px', fontWeight: 600, color: '#767676', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '8px' }}>Membership</p>
              {activeMembership ? (
                <>
                  <div className="flex items-center gap-2 mb-3"><span style={statusBg(activeMembership.Status__c)}>{activeMembership.Status__c}</span></div>
                  <p style={{ fontSize: '14px', color: '#1a2b4a', margin: '4px 0' }}><strong>Expires:</strong> {fmt(activeMembership.Expiration_Date__c)}</p>
                  <p style={{ fontSize: '14px', color: '#1a2b4a', margin: '4px 0' }}><strong>Next Billing:</strong> {fmt(activeMembership.Next_Billing_Date__c)}</p>
                  <p style={{ fontSize: '14px', color: '#1a2b4a', margin: '4px 0' }}><strong>Auto-Renew:</strong> {activeMembership.Auto_Renewal__c ? 'On' : 'Off'}</p>
                </>
              ) : (<p style={{ color: '#767676', fontSize: '14px' }}>No active membership</p>)}
            </div>
            <div style={{ background: '#fff', borderRadius: '12px', padding: '24px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
              <p style={{ fontSize: '12px', fontWeight: 600, color: '#767676', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '8px' }}>Upcoming Cruises</p>
              {upcomingBookings.length === 0 ? (<p style={{ color: '#767676', fontSize: '14px' }}>No upcoming cruises</p>) : (
                upcomingBookings.slice(0, 2).map(b => (
                  <div key={b.Id} style={{ borderBottom: '1px solid #f0f0f0', paddingBottom: '10px', marginBottom: '10px' }}>
                    <p style={{ fontWeight: 600, color: '#1a2b4a', fontSize: '14px', margin: '0 0 2px' }}>{b.Ship__c}</p>
                    <p style={{ color: '#767676', fontSize: '13px', margin: '0' }}>{b.Itinerary__c} · {fmt(b.Departure_Date__c)}</p>
                    {b.Current_Balance_Due__c > 0 && (<p style={{ color: '#bd1f34', fontSize: '12px', margin: '2px 0 0' }}>Balance due: {fmtMoney(b.Current_Balance_Due__c)}</p>)}
                  </div>
                ))
              )}
            </div>
            <div style={{ background: '#fff', borderRadius: '12px', padding: '24px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
              <p style={{ fontSize: '12px', fontWeight: 600, color: '#767676', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '8px' }}>Active Rewards</p>
              {activeRewards.length === 0 ? (<p style={{ color: '#767676', fontSize: '14px' }}>No active rewards</p>) : (
                activeRewards.slice(0, 3).map(r => (
                  <div key={r.Id} style={{ borderBottom: '1px solid #f0f0f0', paddingBottom: '8px', marginBottom: '8px' }}>
                    <p style={{ fontWeight: 600, color: '#1a2b4a', fontSize: '14px', margin: '0 0 2px' }}>{r.Reward_Number__c}</p>
                    <p style={{ color: '#767676', fontSize: '13px', margin: '0' }}>Book by {fmt(r.Book_By_Date__c)}</p>
                  </div>
                ))
              )}
            </div>
            <div style={{ background: '#fff', borderRadius: '12px', padding: '24px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
              <p style={{ fontSize: '12px', fontWeight: 600, color: '#767676', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '12px' }}>Account Info</p>
              <p style={{ fontSize: '14px', color: '#1a2b4a', margin: '4px 0' }}><strong>Phone:</strong> {contact.Phone || '—'}</p>
              <p style={{ fontSize: '14px', color: '#1a2b4a', margin: '4px 0' }}><strong>Location:</strong> {[contact.MailingCity, contact.MailingState].filter(Boolean).join(', ') || '—'}</p>
              <p style={{ fontSize: '14px', color: '#1a2b4a', margin: '4px 0' }}><strong>Last Login:</strong> {contact.Portal_Last_Login__c ? fmt(contact.Portal_Last_Login__c) : 'First time'}</p>
              <p style={{ fontSize: '14px', color: '#1a2b4a', margin: '4px 0' }}><strong>Total Logins:</strong> {contact.Portal_Login_Count__c || 1}</p>
            </div>
          </div>
        )}

        {/* ── BOOKINGS ── */}
        {tab === 'bookings' && (
          <div>
            <h2 style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '22px', color: '#1a2b4a', marginBottom: '20px' }}>My Cruises</h2>
            {bookings.length === 0 ? (
              <div style={{ background: '#fff', borderRadius: '12px', padding: '40px', textAlign: 'center', color: '#767676' }}>No bookings found.</div>
            ) : (
              <div className="flex flex-col gap-4">
                {bookings.map(b => (
                  <div key={b.Id} style={{ background: '#fff', borderRadius: '12px', padding: '24px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)', display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
                    <div>
                      <div className="flex items-center gap-3 mb-2">
                        <span style={{ fontFamily: 'monospace', color: '#767676', fontSize: '13px' }}>{b.Name}</span>
                        <span style={statusBg(b.Status__c)}>{b.Status__c}</span>
                      </div>
                      <h3 style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '18px', color: '#1a2b4a', margin: '0 0 4px' }}>{b.Ship__c}</h3>
                      <p style={{ color: '#767676', fontSize: '14px', margin: '0 0 4px' }}>{b.Itinerary__c}</p>
                      <p style={{ color: '#767676', fontSize: '13px', margin: '0' }}>
                        {fmt(b.Departure_Date__c)} · {b.Departure_Port__c} · {b.Cabin_Category__c} · {b.PAX_Count__c} guest{b.PAX_Count__c !== 1 ? 's' : ''}
                      </p>
                    </div>
                    <div style={{ textAlign: 'right', display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '8px' }}>
                      <p style={{ fontSize: '20px', fontWeight: 700, color: '#1a2b4a', margin: '0' }}>{fmtMoney(b.Original_Cruise_Total__c)}</p>
                      {b.Current_Balance_Due__c > 0 ? (
                        <>
                          <p style={{ color: '#bd1f34', fontSize: '13px', fontWeight: 600, margin: '0' }}>Balance due: {fmtMoney(b.Current_Balance_Due__c)}</p>
                          <button onClick={() => openPayModal(b)} style={{ ...btnPrimary, padding: '8px 16px', fontSize: '13px' }}>
                            Pay Balance
                          </button>
                        </>
                      ) : (
                        <p style={{ color: '#1a8a4a', fontSize: '13px', fontWeight: 600, margin: '0' }}>Paid in full</p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ── MEMBERSHIP ── */}
        {tab === 'membership' && (
          <div>
            <h2 style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '22px', color: '#1a2b4a', marginBottom: '20px' }}>Membership</h2>
            {memberships.length === 0 ? (
              <div style={{ background: '#fff', borderRadius: '12px', padding: '40px', textAlign: 'center', color: '#767676' }}>No memberships found.</div>
            ) : (
              <div className="flex flex-col gap-4">
                {memberships.map(m => (
                  <div key={m.Id} style={{ background: '#fff', borderRadius: '12px', padding: '24px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
                    <div className="flex items-center justify-between flex-wrap gap-3 mb-4">
                      <div>
                        <h3 style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '18px', color: '#1a2b4a', margin: '0 0 4px' }}>{m.Name}</h3>
                        <p style={{ color: '#767676', fontSize: '13px', margin: '0' }}>{m.Partner__c}</p>
                      </div>
                      <span style={statusBg(m.Status__c)}>{m.Status__c}</span>
                    </div>
                    <div className="grid gap-3" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))' }}>
                      {([['Enrolled', fmt(m.Enroll_Date__c)], ['Expires', fmt(m.Expiration_Date__c)], ['Next Billing', fmt(m.Next_Billing_Date__c)], ['Auto-Renew', m.Auto_Renewal__c ? 'On' : 'Off']] as [string, string][]).map(([label, value]) => (
                        <div key={label} style={{ background: '#f8fafc', borderRadius: '8px', padding: '12px 16px' }}>
                          <p style={{ fontSize: '11px', fontWeight: 600, color: '#767676', textTransform: 'uppercase', letterSpacing: '0.5px', margin: '0 0 4px' }}>{label}</p>
                          <p style={{ fontSize: '15px', fontWeight: 600, color: '#1a2b4a', margin: '0' }}>{value}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ── REWARDS ── */}
        {tab === 'rewards' && (
          <div>
            <h2 style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '22px', color: '#1a2b4a', marginBottom: '20px' }}>Rewards</h2>
            {rewards.length === 0 ? (
              <div style={{ background: '#fff', borderRadius: '12px', padding: '40px', textAlign: 'center', color: '#767676' }}>No rewards found.</div>
            ) : (
              <div className="grid gap-4" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))' }}>
                {rewards.map(r => (
                  <div key={r.Id} style={{ background: '#fff', borderRadius: '12px', padding: '20px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)', borderLeft: `4px solid ${statusColor(r.Status__c)}` }}>
                    <div className="flex items-start justify-between gap-2 mb-3">
                      <div>
                        <p style={{ fontFamily: 'monospace', fontSize: '13px', color: '#767676', margin: '0 0 2px' }}>{r.Reward_Number__c}</p>
                        <p style={{ fontWeight: 600, fontSize: '15px', color: '#1a2b4a', margin: '0' }}>{r.Reward_Location__c}</p>
                      </div>
                      <span style={statusBg(r.Status__c)}>{r.Status__c}</span>
                    </div>
                    <p style={{ fontSize: '13px', color: '#767676', margin: '4px 0' }}>Issued: {fmt(r.Issue_Date__c)}</p>
                    <p style={{ fontSize: '13px', color: '#767676', margin: '4px 0' }}>Book by: {fmt(r.Book_By_Date__c)}</p>
                    <p style={{ fontSize: '13px', color: r.Status__c === 'Active' ? '#bd1f34' : '#767676', margin: '4px 0', fontWeight: r.Status__c === 'Active' ? 600 : 400 }}>
                      Expires: {fmt(r.Expiration_Date__c)}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ── PAYMENT ── */}
        {tab === 'cards' && (
          <div>
            <div className="flex items-center justify-between flex-wrap gap-3" style={{ marginBottom: '20px' }}>
              <h2 style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '22px', color: '#1a2b4a', margin: 0 }}>Payment Methods</h2>
              <button onClick={() => { resetNewCard(); setAddCardError(''); setShowAddCard(true) }} style={btnPrimary}>
                + Add Card
              </button>
            </div>
            {savedCards.length === 0 ? (
              <div style={{ background: '#fff', borderRadius: '12px', padding: '40px', textAlign: 'center', color: '#767676' }}>No saved cards.</div>
            ) : (
              <div className="grid gap-4" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))' }}>
                {savedCards.map(c => (
                  <div key={c.Id} style={{ background: 'linear-gradient(135deg, #1a2b4a 0%, #10559a 100%)', borderRadius: '12px', padding: '24px', color: '#fff', position: 'relative', boxShadow: '0 4px 16px rgba(16,85,154,0.3)' }}>
                    {c.Is_Default__c && (
                      <span style={{ position: 'absolute', top: '14px', right: '14px', background: 'rgba(255,255,255,0.2)', borderRadius: '12px', padding: '2px 10px', fontSize: '11px', fontWeight: 600 }}>Default</span>
                    )}
                    <p style={{ fontWeight: 700, fontSize: '16px', margin: '0 0 16px', letterSpacing: '0.5px' }}>{c.Card_Brand__c}</p>
                    <p style={{ fontFamily: 'monospace', fontSize: '18px', letterSpacing: '3px', margin: '0 0 16px', opacity: 0.9 }}>•••• •••• •••• {c.Last_Four__c}</p>
                    <p style={{ fontSize: '13px', opacity: 0.7, margin: '0 0 16px' }}>Expires {c.Expiry_Month__c}/{c.Expiry_Year__c}</p>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      {!c.Is_Default__c && (
                        <button
                          onClick={() => handleSetDefault(c.Id)}
                          disabled={cardActionLoading === c.Id}
                          style={{ background: 'rgba(255,255,255,0.15)', border: '1px solid rgba(255,255,255,0.3)', color: '#fff', borderRadius: '6px', padding: '6px 12px', fontSize: '12px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif', opacity: cardActionLoading === c.Id ? 0.5 : 1 }}
                        >
                          Set Default
                        </button>
                      )}
                      <button
                        onClick={() => handleDeleteCard(c.Id)}
                        disabled={cardActionLoading === c.Id}
                        style={{ background: 'rgba(189,31,52,0.6)', border: 'none', color: '#fff', borderRadius: '6px', padding: '6px 12px', fontSize: '12px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif', opacity: cardActionLoading === c.Id ? 0.5 : 1 }}
                      >
                        Remove
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

      </div>

      </div>
      <SiteFooter />

      {/* ════ PAY BOOKING MODAL ════ */}
      {payBooking && (
        <div style={modalOverlay} onClick={() => !payProcessing && setPayBooking(null)}>
          <div style={modalBox} onClick={e => e.stopPropagation()}>
            <div style={{ padding: '20px 24px', borderBottom: '1px solid #f0f0f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '18px', color: '#1a2b4a', margin: 0 }}>Pay Booking Balance</h3>
              <button onClick={() => !payProcessing && setPayBooking(null)} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer', color: '#767676' }}>✕</button>
            </div>
            <div style={{ padding: '24px' }}>
              {/* Booking summary */}
              <div style={{ background: '#f8fafc', borderRadius: '8px', padding: '14px', marginBottom: '20px' }}>
                <p style={{ fontWeight: 600, color: '#1a2b4a', fontSize: '14px', margin: '0 0 4px' }}>{payBooking.Ship__c}</p>
                <p style={{ color: '#767676', fontSize: '13px', margin: '0 0 4px' }}>{payBooking.Itinerary__c} · {fmt(payBooking.Departure_Date__c)}</p>
                <p style={{ color: '#bd1f34', fontWeight: 600, fontSize: '14px', margin: '0' }}>Balance Due: {fmtMoney(payBooking.Current_Balance_Due__c)}</p>
              </div>

              {paySuccess ? (
                <div style={{ background: '#e8f5e9', borderRadius: '8px', padding: '16px', color: '#1a8a4a', fontSize: '14px', marginBottom: '16px' }}>
                  {paySuccess}
                </div>
              ) : (
                <>
                  {/* Payment method toggle */}
                  {savedCards.length > 0 && (
                    <div style={{ display: 'flex', gap: '0', marginBottom: '16px', background: '#f0f0f0', borderRadius: '8px', padding: '3px' }}>
                      {(['saved', 'new'] as const).map(m => (
                        <button key={m} onClick={() => setPayMethod(m)} style={{
                          flex: 1, padding: '8px 0', border: 'none', borderRadius: '6px', fontSize: '13px', fontWeight: 600, cursor: 'pointer',
                          background: payMethod === m ? '#fff' : 'transparent', color: payMethod === m ? '#10559a' : '#767676',
                          fontFamily: 'Poppins, sans-serif', boxShadow: payMethod === m ? '0 1px 3px rgba(0,0,0,0.1)' : 'none',
                        }}>
                          {m === 'saved' ? 'Saved Card' : 'New Card'}
                        </button>
                      ))}
                    </div>
                  )}

                  {payMethod === 'saved' && savedCards.length > 0 ? (
                    <div style={{ marginBottom: '16px' }}>
                      <label style={labelStyle}>Select Card</label>
                      <select style={{ ...inputStyle, cursor: 'pointer' }} value={payCardId} onChange={e => setPayCardId(e.target.value)}>
                        {savedCards.map(c => (
                          <option key={c.Id} value={c.Id}>
                            {c.Card_Brand__c} •••• {c.Last_Four__c} {c.Is_Default__c ? '(Default)' : ''}
                          </option>
                        ))}
                      </select>
                    </div>
                  ) : (
                    <>
                      {newCardFields}
                      <div style={{ marginBottom: '16px' }}>
                        <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#767676', cursor: 'pointer' }}>
                          <input type="checkbox" checked={saveNewCard} onChange={e => setSaveNewCard(e.target.checked)} />
                          Save card for future payments
                        </label>
                      </div>
                    </>
                  )}

                  {/* Amount */}
                  <div style={{ marginBottom: '16px' }}>
                    <label style={labelStyle}>Payment Amount</label>
                    <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                      <span style={{ fontSize: '18px', fontWeight: 600, color: '#1a2b4a' }}>$</span>
                      <input style={{ ...inputStyle, flex: 1 }} type="number" min="0.01" step="0.01" value={payAmount} onChange={e => setPayAmount(e.target.value)} />
                      <button onClick={() => setPayAmount(payBooking.Current_Balance_Due__c.toFixed(2))} style={{ ...btnGhost, padding: '10px 12px', fontSize: '12px', whiteSpace: 'nowrap' }}>
                        Full Balance
                      </button>
                    </div>
                  </div>

                  {payError && (
                    <div style={{ background: '#fce4e8', borderRadius: '8px', padding: '12px', color: '#bd1f34', fontSize: '13px', marginBottom: '16px' }}>
                      {payError}
                    </div>
                  )}
                </>
              )}
            </div>
            <div style={{ padding: '16px 24px', borderTop: '1px solid #f0f0f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: '11px', color: '#767676', display: 'flex', alignItems: 'center', gap: '4px' }}>
                🔒 Authorize.net · PCI DSS Level 1
              </span>
              <div style={{ display: 'flex', gap: '8px' }}>
                <button onClick={() => setPayBooking(null)} style={btnGhost}>{paySuccess ? 'Done' : 'Cancel'}</button>
                {!paySuccess && (
                  <button onClick={processPayment} disabled={payProcessing} style={{ ...btnPrimary, opacity: payProcessing ? 0.6 : 1 }}>
                    {payProcessing ? 'Processing...' : `Pay $${payAmount}`}
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ════ ADD CARD MODAL ════ */}
      {showAddCard && (
        <div style={modalOverlay} onClick={() => !addCardProcessing && setShowAddCard(false)}>
          <div style={modalBox} onClick={e => e.stopPropagation()}>
            <div style={{ padding: '20px 24px', borderBottom: '1px solid #f0f0f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '18px', color: '#1a2b4a', margin: 0 }}>Add Payment Method</h3>
              <button onClick={() => !addCardProcessing && setShowAddCard(false)} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer', color: '#767676' }}>✕</button>
            </div>
            <div style={{ padding: '24px' }}>
              {newCardFields}
              {addCardError && (
                <div style={{ background: '#fce4e8', borderRadius: '8px', padding: '12px', color: '#bd1f34', fontSize: '13px', marginBottom: '16px' }}>
                  {addCardError}
                </div>
              )}
            </div>
            <div style={{ padding: '16px 24px', borderTop: '1px solid #f0f0f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: '11px', color: '#767676', display: 'flex', alignItems: 'center', gap: '4px' }}>
                🔒 Authorize.net · PCI DSS Level 1
              </span>
              <div style={{ display: 'flex', gap: '8px' }}>
                <button onClick={() => setShowAddCard(false)} style={btnGhost}>Cancel</button>
                <button onClick={handleAddCard} disabled={addCardProcessing} style={{ ...btnPrimary, opacity: addCardProcessing ? 0.6 : 1 }}>
                  {addCardProcessing ? 'Saving...' : 'Save Card'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

    </div>
  )
}
