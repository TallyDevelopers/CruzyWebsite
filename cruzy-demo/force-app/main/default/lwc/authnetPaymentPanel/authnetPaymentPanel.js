import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSavedCards    from '@salesforce/apex/AuthnetPaymentController.getSavedCards';
import getBookings      from '@salesforce/apex/AuthnetPaymentController.getContactBookings';
import getBillingHub    from '@salesforce/apex/AuthnetPaymentController.getBillingHubData';
import saveCardApex     from '@salesforce/apex/AuthnetPaymentController.saveCard';
import deleteCardApex   from '@salesforce/apex/AuthnetPaymentController.deleteCard';
import chargeCardApex   from '@salesforce/apex/AuthnetPaymentController.chargeCard';

const BRAND_MAP = {
    '4': { brand: 'Visa',             short: 'VISA', cls: 'sp-brand brand-visa' },
    '5': { brand: 'Mastercard',       short: 'MC',   cls: 'sp-brand brand-mc' },
    '3': { brand: 'American Express', short: 'AMEX', cls: 'sp-brand brand-amex' },
    '6': { brand: 'Discover',         short: 'DISC', cls: 'sp-brand brand-disc' }
};
const BRAND_BY_NAME = {
    'Visa':             { short: 'VISA', cls: 'sp-brand brand-visa' },
    'Mastercard':       { short: 'MC',   cls: 'sp-brand brand-mc' },
    'American Express': { short: 'AMEX', cls: 'sp-brand brand-amex' },
    'Discover':         { short: 'DISC', cls: 'sp-brand brand-disc' }
};

export default class AuthnetPaymentPanel extends LightningElement {
    @api recordId;
    @api contactId;

    @track isLoading  = true;
    @track cards      = [];
    @track bookings   = [];
    @track charges    = [];
    @track totalBalance = 0;

    // modal states
    @track showChargeModal  = false;
    @track showChargeNew    = false;
    @track showAddModal     = false;
    @track showDeleteConfirm = false;

    // charge state
    @track chargeCard          = null;
    @track chargeAmount        = '0.00';
    @track selectedBookingId   = null;
    @track selectedBookingBalance = null;
    @track isProcessing        = false;
    @track chargeError         = null;
    @track chargeSuccess       = false;
    @track lastChargeAmount    = null;
    @track lastChargeId        = null;

    // new card state
    @track newCard    = this._emptyCard();
    @track addError   = null;
    @track isSaving   = false;

    // delete state
    @track cardToDelete = {};

    _cardsWire;
    _hubWire;

    get resolvedContactId() { return this.contactId || this.recordId; }

    @wire(getSavedCards, { contactId: '$resolvedContactId' })
    wiredCards(result) {
        this._cardsWire = result;
        if (result.data) {
            this.cards = result.data.map(c => this._processCard(c));
            this.isLoading = false;
        } else if (result.error) {
            this.isLoading = false;
        }
    }

    @wire(getBookings, { contactId: '$resolvedContactId' })
    wiredBookings({ data }) {
        if (data) {
            this.bookings = data.map(b => ({
                id:      b.Id,
                label:   b.Name + (b.Current_Balance_Due__c > 0 ? ' — $' + parseFloat(b.Current_Balance_Due__c).toFixed(2) + ' due' : ' — paid'),
                balance: b.Current_Balance_Due__c || 0
            }));
            this.totalBalance = data.reduce((s, b) => s + (b.Current_Balance_Due__c || 0), 0);
        }
    }

    @wire(getBillingHub, { contactId: '$resolvedContactId' })
    wiredHub(result) {
        this._hubWire = result;
        if (result.data) {
            const d = result.data;
            const bp = (d.recentPayments || []).map(p => ({
                id:            p.Id,
                label:         'Booking Payment',
                bookingRef:    p.Booking__r ? p.Booking__r.Name : null,
                note:          p.Note__c || (p.Booking__r && p.Booking__r.Ship__c ? p.Booking__r.Ship__c : ''),
                amount:        parseFloat(p.Amount__c || 0).toFixed(2),
                date:          this._fmtDate(p.Payment_Date__c),
                typeIcon:      'utility:anchor',
                typeIconClass: 'sp-charge-icon sp-icon-booking'
            }));
            const mp = (d.membershipPayments || []).map(p => ({
                id:            p.Id + '_m',
                label:         'Membership Payment',
                bookingRef:    p.Membership__r ? p.Membership__r.Name : null,
                note:          p.Renewal_Year__c ? 'Renewal Year ' + p.Renewal_Year__c : 'Membership',
                amount:        parseFloat(p.Amount_Paid__c || 0).toFixed(2),
                date:          this._fmtDate(p.Date_Paid__c),
                typeIcon:      'utility:shield',
                typeIconClass: 'sp-charge-icon sp-icon-mbr'
            }));
            this.charges = [...bp, ...mp].sort((a, b) => new Date(b.date) - new Date(a.date));
        }
    }

    _processCard(c) {
        const b = BRAND_BY_NAME[c.Card_Brand__c] || { short: '????', cls: 'sp-brand brand-generic' };
        const mo = c.Expiry_Month__c ? String(c.Expiry_Month__c).padStart(2,'0') : '??';
        const yr = c.Expiry_Year__c  ? String(c.Expiry_Year__c).slice(-2)        : '??';
        return {
            ...c,
            brandShort:   b.short,
            brandClass:   b.cls,
            expiryDisplay: mo + '/' + yr,
            rowClass: c.Is_Default__c ? 'sp-card-row sp-card-default' : 'sp-card-row'
        };
    }

    // ── Getters ───────────────────────────────────────────────────────────────
    get hasCards()    { return this.cards && this.cards.length > 0; }
    get hasBalance()  { return this.totalBalance > 0; }
    get totalBalanceDisplay() { return parseFloat(this.totalBalance).toFixed(2); }
    get closeBtnLabel() { return this.chargeSuccess ? 'Done' : 'Cancel'; }
    get hasCharges()  { return this.charges && this.charges.length > 0; }
    get chargeCount() { return this.charges ? this.charges.length + ' records' : '0 records'; }

    // ── Open Modals ───────────────────────────────────────────────────────────
    openChargeModal(e) {
        this._resetCharge();
        const cardId = e.currentTarget.dataset.id;
        this.chargeCard = this.cards.find(c => c.Id === cardId);
        this.showChargeModal = true;
    }
    openChargeNew() { this._resetCharge(); this.newCard = this._emptyCard(); this.showChargeNew = true; }
    openNewCard()   { this.newCard = this._emptyCard(); this.addError = null; this.showAddModal = true; }

    closeModals() {
        if (this.chargeSuccess) refreshApex(this._cardsWire);
        this.showChargeModal = false;
        this.showChargeNew   = false;
        this.showAddModal    = false;
        this._resetCharge();
        this.newCard = this._emptyCard();
    }

    // ── Booking Select ────────────────────────────────────────────────────────
    handleBookingSelect(e) {
        this.selectedBookingId = e.target.value || null;
        if (this.selectedBookingId) {
            const bk = this.bookings.find(b => b.id === this.selectedBookingId);
            this.selectedBookingBalance = bk ? parseFloat(bk.balance).toFixed(2) : null;
            if (bk && bk.balance > 0) this.chargeAmount = parseFloat(bk.balance).toFixed(2);
        } else {
            this.selectedBookingBalance = null;
        }
    }
    handleAmountChange(e) { this.chargeAmount = parseFloat(e.target.value || 0).toFixed(2); }
    chargeFullBalance()   { if (this.selectedBookingBalance) this.chargeAmount = this.selectedBookingBalance; }

    // ── Charge Saved Card ─────────────────────────────────────────────────────
    async processCharge() {
        this.chargeError = null;
        if (!this.selectedBookingId) { this.chargeError = 'Select a booking first.'; return; }
        const amount = parseFloat(this.chargeAmount);
        if (!amount || amount <= 0) { this.chargeError = 'Enter a valid amount.'; return; }

        this.isProcessing = true;
        await this._delay(1600);
        try {
            const result = await chargeCardApex({
                bookingId: this.selectedBookingId,
                cardId:    this.chargeCard.Id,
                amount,
                note:      ''
            });
            this.chargeSuccess    = true;
            this.lastChargeAmount = parseFloat(result.amountCharged).toFixed(2);
            this.lastChargeId     = result.chargeId;
            this.totalBalance     = Math.max(0, this.totalBalance - amount);
            this._toast('Payment Processed', `$${this.lastChargeAmount} charged successfully`, 'success');
            refreshApex(this._hubWire);
        } catch (err) {
            this.chargeError = err.body?.message || 'Charge failed. Try again.';
        } finally {
            this.isProcessing = false;
        }
    }

    // ── Charge New Card ───────────────────────────────────────────────────────
    async processChargeNew() {
        this.chargeError = null;
        const c = this.newCard;
        if (!c.cardholderName)                   { this.chargeError = 'Enter cardholder name.'; return; }
        if (!c.rawNumber || c.rawNumber.length < 13) { this.chargeError = 'Enter a valid card number.'; return; }
        if (!c.detectedBrand)                    { this.chargeError = 'Unrecognized card type.'; return; }
        if (!c.expiryMonth || !c.expiryYear)     { this.chargeError = 'Enter expiry date.'; return; }
        if (!c.cvv)                              { this.chargeError = 'Enter CVV.'; return; }
        if (!this.selectedBookingId)             { this.chargeError = 'Select a booking.'; return; }
        const amount = parseFloat(this.chargeAmount);
        if (!amount || amount <= 0)              { this.chargeError = 'Enter a valid amount.'; return; }

        this.isProcessing = true;
        await this._delay(1600);

        try {
            let savedCardId;
            if (c.saveForLater) {
                const saved = await saveCardApex({
                    contactId: this.resolvedContactId, cardBrand: c.detectedBrand,
                    lastFour: c.lastFour, expiryMonth: c.expiryMonth, expiryYear: c.expiryYear,
                    cardholderName: c.cardholderName, makeDefault: false,
                    cardNumber: c.rawNumber, cvv: c.cvv
                });
                savedCardId = saved.Id;
            } else {
                const temp = await saveCardApex({
                    contactId: this.resolvedContactId, cardBrand: c.detectedBrand,
                    lastFour: c.lastFour, expiryMonth: c.expiryMonth, expiryYear: c.expiryYear,
                    cardholderName: c.cardholderName, makeDefault: false,
                    cardNumber: c.rawNumber, cvv: c.cvv
                });
                savedCardId = temp.Id;
            }

            const result = await chargeCardApex({
                bookingId: this.selectedBookingId,
                cardId:    savedCardId,
                amount,
                note:      ''
            });

            if (!c.saveForLater) {
                await deleteCardApex({ cardId: savedCardId });
            }

            this.chargeSuccess    = true;
            this.lastChargeAmount = parseFloat(result.amountCharged).toFixed(2);
            this.lastChargeId     = result.chargeId;
            this.totalBalance     = Math.max(0, this.totalBalance - amount);
            this._toast('Payment Processed', `$${this.lastChargeAmount} charged`, 'success');
            await refreshApex(this._cardsWire);
            refreshApex(this._hubWire);
        } catch (err) {
            this.chargeError = err.body?.message || 'Charge failed. Try again.';
        } finally {
            this.isProcessing = false;
        }
    }

    // ── Save Card (add only) ──────────────────────────────────────────────────
    async saveCard() {
        this.addError = null;
        const c = this.newCard;
        if (!c.cardholderName)                   { this.addError = 'Cardholder name required.'; return; }
        if (!c.rawNumber || c.rawNumber.length < 13) { this.addError = 'Enter a valid card number.'; return; }
        if (!c.detectedBrand)                    { this.addError = 'Unrecognized card type.'; return; }
        if (!c.expiryMonth || !c.expiryYear)     { this.addError = 'Enter expiry date.'; return; }
        if (!c.cvv)                              { this.addError = 'CVV required.'; return; }

        this.isSaving = true;
        await this._delay(1200);
        try {
            await saveCardApex({
                contactId: this.resolvedContactId, cardBrand: c.detectedBrand,
                lastFour: c.lastFour, expiryMonth: c.expiryMonth, expiryYear: c.expiryYear,
                cardholderName: c.cardholderName, makeDefault: !this.hasCards,
                cardNumber: c.rawNumber, cvv: c.cvv
            });
            this._toast('Card Saved', `${c.detectedBrand} •••• ${c.lastFour} added`, 'success');
            this.showAddModal = false;
            await refreshApex(this._cardsWire);
        } catch (err) {
            this.addError = err.body?.message || 'Failed to save card.';
        } finally {
            this.isSaving = false;
        }
    }

    // ── Delete ────────────────────────────────────────────────────────────────
    confirmDelete(e) {
        this.cardToDelete = { id: e.currentTarget.dataset.id, name: e.currentTarget.dataset.name };
        this.showDeleteConfirm = true;
    }
    cancelDelete() { this.showDeleteConfirm = false; }
    async deleteCard() {
        try {
            await deleteCardApex({ cardId: this.cardToDelete.id });
            this._toast('Card Removed', this.cardToDelete.name + ' removed', 'success');
            this.showDeleteConfirm = false;
            await refreshApex(this._cardsWire);
        } catch (err) {
            this._toast('Error', err.body?.message || 'Could not remove.', 'error');
        }
    }

    // ── Card Input ────────────────────────────────────────────────────────────
    handleCardholderName(e) { this.newCard = { ...this.newCard, cardholderName: e.target.value }; }
    handleCvv(e)            { this.newCard = { ...this.newCard, cvv: e.target.value }; }
    handleSaveToggle(e)     { this.newCard = { ...this.newCard, saveForLater: e.target.checked }; }

    handleCardNumber(e) {
        let raw = e.target.value.replace(/\D/g, '').substring(0, 16);
        const fmt = raw.replace(/(.{4})/g, '$1 ').trim();
        e.target.value = fmt;
        const bd = BRAND_MAP[raw[0] || ''];
        this.newCard = {
            ...this.newCard,
            rawNumber: raw,
            cardNumberDisplay: fmt,
            lastFour: raw.length >= 4 ? raw.slice(-4) : '',
            detectedBrand: bd ? bd.brand : null,
            brandShort: bd ? bd.short : '',
            detectedBrandClass: bd ? bd.cls + ' sp-inline-brand' : ''
        };
    }

    handleExpiry(e) {
        let raw = e.target.value.replace(/\D/g, '').substring(0, 4);
        let fmt = raw.length >= 2 ? raw.substring(0, 2) + ' / ' + raw.substring(2) : raw;
        e.target.value = fmt;
        this.newCard = {
            ...this.newCard,
            expiryMonth: raw.length >= 2 ? parseInt(raw.substring(0, 2), 10) : null,
            expiryYear:  raw.length === 4 ? parseInt('20' + raw.substring(2), 10) : null,
            expiryDisplay: fmt
        };
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    _emptyCard() {
        return {
            cardholderName: '', rawNumber: '', cardNumberDisplay: '',
            lastFour: '', detectedBrand: null, brandShort: '',
            expiryMonth: null, expiryYear: null, expiryDisplay: '',
            cvv: '', saveForLater: true
        };
    }
    _resetCharge() {
        this.chargeError = null; this.chargeSuccess = false;
        this.isProcessing = false; this.chargeAmount = '0.00';
        this.selectedBookingId = null; this.selectedBookingBalance = null;
    }
    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    _fmtDate(d) {
        if (!d) return '—';
        const dt = new Date(d + (String(d).includes('T') ? '' : 'T00:00:00'));
        return dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    }
    _delay(ms) { return new Promise(r => setTimeout(r, ms)); }
}
