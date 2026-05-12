import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getContactJourney from '@salesforce/apex/CustomerJourneyController.getContactJourney';
import getSavedCards     from '@salesforce/apex/AuthnetPaymentController.getSavedCards';
import chargeCardApex    from '@salesforce/apex/AuthnetPaymentController.chargeCard';
import saveCardApex      from '@salesforce/apex/AuthnetPaymentController.saveCard';

const VIFP_BADGE_MAP = {
    'Red':          'cjt-vifp-badge vifp-red',
    'Gold':         'cjt-vifp-badge vifp-gold',
    'Platinum':     'cjt-vifp-badge vifp-platinum',
    'Diamond':      'cjt-vifp-badge vifp-diamond',
    'Diamond Plus': 'cjt-vifp-badge vifp-diamondplus'
};

const BOOKING_STATUS_BADGE = {
    'Booking':   'cjt-status-pill status-booking',
    'Quote':     'cjt-status-pill status-quote',
    'Completed': 'cjt-status-pill status-completed',
    'Cancelled': 'cjt-status-pill status-cancelled'
};

const MEMBERSHIP_STATUS_BADGE = {
    'Active':                  'cjt-mbr-pill mbr-active',
    'Inactive - Need Payment': 'cjt-mbr-pill mbr-inactive',
    'Cancelled':               'cjt-mbr-pill mbr-cancelled',
    'On Hold':                 'cjt-mbr-pill mbr-hold'
};

const BRAND_MAP = { visa:'VISA', mastercard:'MC', amex:'AMEX', discover:'DISC', default:'CARD' };
const BRAND_CLASS = {
    visa:'sp-brand visa-brand', mastercard:'sp-brand mc-brand',
    amex:'sp-brand amex-brand', discover:'sp-brand disc-brand', default:'sp-brand generic-brand'
};

export default class CustomerJourneyTimeline extends LightningElement {
    @api recordId;

    @track contact      = null;
    @track isLoading    = true;
    @track hasError     = false;

    // ── Charge modal state ─────────────────────────────────────────────────
    @track showChargeModal   = false;
    @track chargeBookingId   = null;
    @track chargeBookingName = '';
    @track chargeBookingBalance = '0.00';
    @track chargeAmount      = '';
    @track selectedCardId    = null;
    @track savedCards        = [];
    @track showNewCardFields = false;
    @track saveNewCard       = true;
    @track newCardName       = '';
    @track newCardNumber     = '';
    @track newCardExpiry     = '';
    @track newCardCvv        = '';
    @track isCharging        = false;
    @track chargeError       = '';
    @track chargeSuccess     = false;
    @track lastChargeId      = '';

    _expandedBookings = new Set();
    _rawData          = null;
    _journeyWire      = null;

    @wire(getContactJourney, { contactId: '$recordId' })
    wiredJourney(result) {
        this._journeyWire = result;
        const { data, error } = result;
        if (data) {
            this._rawData  = data;
            this.contact   = this._processContact(data);
            this.isLoading = false;
        } else if (error) {
            console.error('CustomerJourneyTimeline:', JSON.stringify(error));
            this.hasError  = true;
            this.isLoading = false;
        }
    }

    @wire(getSavedCards, { contactId: '$recordId' })
    wiredCards({ data }) {
        if (data) {
            this.savedCards = data.map(c => this._processCard(c));
            // pre-select default
            const def = this.savedCards.find(c => c.isDefault);
            if (def) this.selectedCardId = def.id;
        }
    }

    // ─── Charge Modal Handlers ────────────────────────────────────────────────

    openChargeModal(e) {
        e.stopPropagation();
        this.chargeBookingId      = e.currentTarget.dataset.bookingId;
        this.chargeBookingName    = e.currentTarget.dataset.bookingName;
        this.chargeBookingBalance = parseFloat(e.currentTarget.dataset.balance || 0).toFixed(2);
        this.chargeAmount         = this.chargeBookingBalance;
        this.chargeError          = '';
        this.chargeSuccess        = false;
        this.showNewCardFields    = false;
        this.newCardName = this.newCardNumber = this.newCardExpiry = this.newCardCvv = '';
        this.saveNewCard = true;
        // re-select default card
        const def = this.savedCards.find(c => c.isDefault);
        this.selectedCardId = def ? def.id : (this.savedCards[0] ? this.savedCards[0].id : null);
        this._refreshCardSelectClasses();
        this.showChargeModal = true;
    }

    closeChargeModal() {
        this.showChargeModal = false;
        if (this.chargeSuccess) {
            refreshApex(this._journeyWire);
        }
    }

    handleChargeAmountChange(e) { this.chargeAmount = e.target.value; }
    setFullAmount()              { this.chargeAmount = this.chargeBookingBalance; }

    selectCard(e) {
        this.selectedCardId  = e.currentTarget.dataset.cardId;
        this.showNewCardFields = false;
        this._refreshCardSelectClasses();
    }

    toggleNewCard() {
        this.showNewCardFields = !this.showNewCardFields;
        if (this.showNewCardFields) this.selectedCardId = null;
        this._refreshCardSelectClasses();
    }

    handleNewCardName(e)   { this.newCardName   = e.target.value; }
    handleNewCardCvv(e)    { this.newCardCvv    = e.target.value; }
    handleSaveNewCard(e)   { this.saveNewCard   = e.target.checked; }

    handleNewCardNumber(e) {
        let v = e.target.value.replace(/\D/g, '').substring(0, 16);
        e.target.value = v.replace(/(.{4})/g, '$1 ').trim();
        this.newCardNumber = v;
    }

    handleNewCardExpiry(e) {
        let v = e.target.value.replace(/\D/g, '').substring(0, 4);
        if (v.length >= 3) v = v.substring(0,2) + ' / ' + v.substring(2);
        e.target.value = v;
        this.newCardExpiry = v;
    }

    async processCharge() {
        this.chargeError   = '';
        const amount       = parseFloat(this.chargeAmount);
        if (!amount || amount <= 0) { this.chargeError = 'Enter a valid charge amount.'; return; }

        let cardId = this.selectedCardId;

        if (this.showNewCardFields) {
            if (!this.newCardName || this.newCardNumber.length < 15) {
                this.chargeError = 'Enter a valid cardholder name and card number.';
                return;
            }
            const expParts = this.newCardExpiry.replace(/\s/g,'').split('/');
            const brand    = this._detectBrand(this.newCardNumber);
            try {
                const saved = await saveCardApex({
                    contactId:      this.recordId,
                    cardBrand:      brand,
                    lastFour:       this.newCardNumber.replace(/\s/g,'').slice(-4),
                    expiryMonth:    parseInt(expParts[0] || '1', 10),
                    expiryYear:     parseInt('20' + (expParts[1] || '25'), 10),
                    cardholderName: this.newCardName,
                    makeDefault:    false
                });
                cardId = saved.Id;
            } catch(err) {
                this.chargeError = 'Could not save card: ' + (err.body?.message || 'Unknown error');
                return;
            }
        }

        if (!cardId) { this.chargeError = 'Select a card or enter a new one.'; return; }

        this.isCharging = true;
        try {
            const result = await chargeCardApex({
                cardId,
                bookingId: this.chargeBookingId,
                amount
            });
            this.chargeSuccess = true;
            this.lastChargeId  = result.chargeId;
            this._toast('Payment Processed', `$${parseFloat(amount).toFixed(2)} charged — Ref: ${result.chargeId}`, 'success');
            // refresh journey so balance updates live
            refreshApex(this._journeyWire);
        } catch(err) {
            this.chargeError = err.body?.message || 'Charge failed. Try again.';
        } finally {
            this.isCharging = false;
        }
    }

    _refreshCardSelectClasses() {
        this.savedCards = this.savedCards.map(c => ({
            ...c,
            selectClass: c.id === this.selectedCardId
                ? 'cjt-cm-card-item cjt-cm-card-item--selected'
                : 'cjt-cm-card-item'
        }));
    }

    _processCard(c) {
        const brand = (c.Card_Brand__c || 'default').toLowerCase();
        return {
            id:          c.Id,
            brandShort:  BRAND_MAP[brand] || 'CARD',
            brandClass:  BRAND_CLASS[brand] || BRAND_CLASS.default,
            lastFour:    c.Last_Four__c || '••••',
            expiry:      `${c.Expiry_Month__c || '?'}/${String(c.Expiry_Year__c || '??').slice(-2)}`,
            isDefault:   c.Is_Default__c,
            selectClass: 'cjt-cm-card-item'
        };
    }

    _detectBrand(num) {
        const n = num.replace(/\s/g,'');
        if (/^4/.test(n))          return 'Visa';
        if (/^5[1-5]/.test(n))     return 'Mastercard';
        if (/^3[47]/.test(n))      return 'Amex';
        if (/^6(?:011|5)/.test(n)) return 'Discover';
        return 'Unknown';
    }

    _toast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }

    // ─── Data Processing ──────────────────────────────────────────────────────

    _processContact(c) {
        const membership = c.membership ? this._processMembership(c.membership) : null;
        const bookings   = (c.bookings || []).map(b => this._processBooking(b));

        const usedRewardIds = new Set(bookings.filter(b => b.rewardId).map(b => b.rewardId));
        const standaloneRewards = (c.rewards || [])
            .filter(r => !usedRewardIds.has(r.rewardId))
            .map(r => this._processReward(r));

        const totalPaid = bookings.reduce((sum, b) => {
            return sum + (b.payments || []).reduce((s, p) => s + parseFloat(p.Amount__c || 0), 0);
        }, 0);

        const totalBalance = bookings.reduce((sum, b) => sum + parseFloat(b.Current_Balance_Due__c || 0), 0);

        return {
            id:              c.contactId,
            name:            c.contactName || '—',
            phone:           c.phone || '—',
            email:           c.email || '—',
            altPhone:        c.altPhone,
            altEmail:        c.altEmail,
            timezone:        c.timezone,
            source:          c.customerSource,
            notes:           c.customerNotes,
            vifpNumber:      c.vifpNumber,
            vifpLevel:       c.vifpLevel,
            vifpBelongsTo:   c.vifpBelongsTo,
            cruzyPlusMbrNum: c.cruzyPlusMbrNum,
            cruzyPlusEnrolled: c.cruzyPlusEnrolled,
            spouse:          c.spouse,
            spanishSpeaking: c.spanishSpeaking,
            initials:        this._initials(c.contactName),
            vifpBadgeClass:  VIFP_BADGE_MAP[c.vifpLevel] || 'cjt-vifp-badge vifp-red',
            hasVifp:         !!c.vifpNumber,
            hasMembership:   !!membership,
            membership,
            bookings,
            bookingCount:    bookings.length,
            rewardCount:     (c.rewards || []).length,
            standaloneRewards,
            hasStandaloneRewards: standaloneRewards.length > 0,
            totalPaid:       totalPaid.toFixed(2),
            totalBalance:    totalBalance.toFixed(2),
            hasBalance:      totalBalance > 0
        };
    }

    _processMembership(m) {
        const today = new Date();
        const expDate = m.expirationDate ? new Date(m.expirationDate) : null;
        const nextBill = m.nextBillingDate ? new Date(m.nextBillingDate) : null;
        const daysLeft = expDate ? Math.ceil((expDate - today) / 86400000) : null;
        const isCancelled = m.status === 'Cancelled';
        const isExpired   = expDate && expDate < today && !isCancelled;

        let countdownClass = 'cjt-countdown';
        let countdownText  = '';
        let showCountdown  = false;

        if (!isCancelled && daysLeft !== null) {
            showCountdown = true;
            if (daysLeft < 0)       { countdownClass += ' cd-expired'; countdownText = 'Expired ' + Math.abs(daysLeft) + ' days ago'; }
            else if (daysLeft === 0){ countdownClass += ' cd-urgent';  countdownText = 'Expires today'; }
            else if (daysLeft <= 7) { countdownClass += ' cd-urgent';  countdownText = daysLeft + ' days left — action needed'; }
            else if (daysLeft <= 30){ countdownClass += ' cd-warn';    countdownText = daysLeft + ' days until renewal'; }
            else                    { countdownClass += ' cd-ok';      countdownText = daysLeft + ' days remaining'; }
        }

        return {
            id:           m.membershipId,
            name:         m.membershipName,
            status:       m.status,
            partner:      m.partner || '—',
            autoRenewal:  m.autoRenewal,
            biennial:     m.biennial,
            plan:         m.biennial ? 'Biennial' : 'Annual',
            enrollDate:   m.enrollDate   ? this._fmtDate(m.enrollDate)        : '—',
            expDate:      m.expirationDate ? this._fmtDate(m.expirationDate)  : '—',
            nextBillDate: m.nextBillingDate ? this._fmtDate(m.nextBillingDate): '—',
            paidThrough:  m.paidThrough  ? this._fmtDate(m.paidThrough)       : '—',
            statusBadgeClass: MEMBERSHIP_STATUS_BADGE[m.status] || 'cjt-mbr-pill mbr-inactive',
            renewIcon:        m.autoRenewal ? 'utility:refresh' : 'utility:ban',
            renewIconClass:   m.autoRenewal ? 'cjt-renew-icon renew-on' : 'cjt-renew-icon renew-off',
            renewToggleClass: m.autoRenewal ? 'cjt-toggle toggle-on' : 'cjt-toggle toggle-off',
            renewLabel:       m.autoRenewal ? 'Auto-Renewal On' : 'Auto-Renewal Off',
            renewDetail:      m.autoRenewal && nextBill
                ? 'Next charge: ' + this._fmtDate(m.nextBillingDate)
                : (!m.autoRenewal && !isCancelled ? 'Will not auto-renew' : ''),
            isCancelled,
            isExpired,
            isActive:       m.status === 'Active',
            showCountdown,
            countdownClass,
            countdownText,
            expiryValueClass: (daysLeft !== null && daysLeft <= 30 && !isCancelled)
                ? 'cjt-val cjt-val-warn' : 'cjt-val'
        };
    }

    _processBooking(b) {
        const addOns = (b.addOns || []).map(a => ({
            id:     a.Id,
            name:   a.addonName,
            type:   a.addonType,
            amount: a.amount ? '$' + parseFloat(a.amount).toFixed(2) : '$0.00'
        }));
        const payments = (b.payments || []).map(p => ({
            id:     p.Id,
            amount: p.amount ? '$' + parseFloat(p.amount).toFixed(2) : '$0.00',
            note:   p.note || '—',
            date:   p.paymentDate ? this._fmtDate(p.paymentDate) : '—'
        }));
        const addOnTotal = (b.addOns || []).reduce((s, a) => s + (a.amount || 0), 0);
        const isExpanded = this._expandedBookings.has(b.bookingId);

        return {
            id:           b.bookingId,
            name:         b.bookingName,
            status:       b.status,
            ship:         b.ship || '—',
            itinerary:    b.itinerary || '—',
            port:         b.departurePort || '—',
            cabin:        b.cabinCategory || '—',
            pax:          b.paxCount || '—',
            quoteType:    b.quoteType || '—',
            total:        b.cruiseTotal ? '$' + parseFloat(b.cruiseTotal).toFixed(2) : '$0.00',
            balance:      b.balanceDue  ? '$' + parseFloat(b.balanceDue).toFixed(2)  : '$0.00',
            balanceRaw:   parseFloat(b.balanceDue || 0).toFixed(2),
            hasBalance:   (b.balanceDue || 0) > 0,
            departDate:   b.departureDate ? this._fmtDate(b.departureDate) : '—',
            statusPillClass: BOOKING_STATUS_BADGE[b.status] || 'cjt-status-pill status-quote',
            rewardId:     b.rewardId,
            rewardName:   b.reward ? b.reward.rewardName  : null,
            rewardPartner:b.reward ? b.reward.partner      : null,
            rewardStatus: b.reward ? b.reward.status       : null,
            hasReward:    !!b.reward,
            addOns,
            addOnCount:   addOns.length,
            addOnTotal:   '$' + addOnTotal.toFixed(2),
            hasAddOns:    addOns.length > 0,
            payments,
            paymentCount: payments.length,
            hasPayments:  payments.length > 0,
            isExpanded,
            expandIcon:    isExpanded ? 'utility:chevrondown' : 'utility:chevronright',
            headerClass:   isExpanded
                ? 'cjt-booking-row cjt-booking-row--expanded'
                : 'cjt-booking-row'
        };
    }

    _processReward(r) {
        return {
            id:       r.rewardId,
            name:     r.rewardName,
            status:   r.status,
            partner:  r.partner || '—',
            number:   r.rewardNumber,
            expDate:  r.expirationDate ? this._fmtDate(r.expirationDate) : '—',
            bookBy:   r.bookByDate     ? this._fmtDate(r.bookByDate)     : '—',
            pillClass: r.status === 'Active'  ? 'cjt-reward-pill reward-active'
                     : r.status === 'Used'    ? 'cjt-reward-pill reward-used'
                     : 'cjt-reward-pill reward-expired'
        };
    }

    // ─── Interactions ─────────────────────────────────────────────────────────

    toggleBooking(e) {
        const id = e.currentTarget.dataset.id;
        if (this._expandedBookings.has(id)) {
            this._expandedBookings.delete(id);
        } else {
            this._expandedBookings.add(id);
        }
        this.contact = this._processContact(this._rawData);
    }

    // ─── Getters ──────────────────────────────────────────────────────────────

    get hasContact()     { return !!this.contact; }
    get hasSavedCards()  { return this.savedCards && this.savedCards.length > 0; }
    get chargeCancelLabel() { return this.chargeSuccess ? 'Done' : 'Cancel'; }

    get bookingsTabLabel() {
        const n = this.contact?.bookingCount ?? 0;
        return `Bookings (${n})`;
    }

    get rewardsTabLabel() {
        const n = this.contact?.standaloneRewards?.length ?? 0;
        return `Rewards (${n})`;
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    _initials(name) {
        if (!name) return '?';
        const parts = name.trim().split(' ');
        return parts.length >= 2
            ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
            : name[0].toUpperCase();
    }

    _fmtDate(d) {
        if (!d) return '—';
        const dt = new Date(d + (d.includes('T') ? '' : 'T00:00:00'));
        return dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    }
}
