import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSavedCards from '@salesforce/apex/AuthnetPaymentController.getSavedCards';
import chargeCard    from '@salesforce/apex/AuthnetPaymentController.chargeCard';

import BOOKING_NAME       from '@salesforce/schema/Booking__c.Name';
import BOOKING_TOTAL      from '@salesforce/schema/Booking__c.Original_Cruise_Total__c';
import BOOKING_BALANCE    from '@salesforce/schema/Booking__c.Current_Balance_Due__c';
import BOOKING_CONTACT    from '@salesforce/schema/Booking__c.Contact__c';

const BRAND_CLASS = {
    'Visa':             { short: 'VISA', cls: 'scm-brand-icon brand-visa' },
    'Mastercard':       { short: 'MC',   cls: 'scm-brand-icon brand-mc' },
    'American Express': { short: 'AMEX', cls: 'scm-brand-icon brand-amex' },
    'Discover':         { short: 'DISC', cls: 'scm-brand-icon brand-disc' }
};

export default class AuthnetChargeModal extends LightningElement {
    @api recordId; // Booking__c Id

    @track showModal = false;
    @track cards = [];
    @track selectedCardId = null;
    @track chargeAmount = '0.00';
    @track chargeNote = '';
    @track isProcessing = false;
    @track chargeError = null;
    @track chargeSuccess = false;
    @track lastChargeAmount = null;
    @track lastCardDisplay = null;
    @track lastChargeId = null;

    _bookingWire;
    _cardsWire;
    _contactId;

    @wire(getRecord, { recordId: '$recordId', fields: [BOOKING_NAME, BOOKING_TOTAL, BOOKING_BALANCE, BOOKING_CONTACT] })
    wiredBooking(result) {
        this._bookingWire = result;
        if (result.data) {
            this._contactId = getFieldValue(result.data, BOOKING_CONTACT);
            const bal = getFieldValue(result.data, BOOKING_BALANCE) || 0;
            this.chargeAmount = parseFloat(bal).toFixed(2);
        }
    }

    @wire(getSavedCards, { contactId: '$_contactId' })
    wiredCards(result) {
        this._cardsWire = result;
        if (result.data) {
            this.cards = result.data.map(c => this._processCard(c, null));
            const def = result.data.find(c => c.Is_Default__c);
            if (def) this.selectedCardId = def.Id;
            this._refreshCardClasses();
        }
    }

    _processCard(c, selectedId) {
        const brand = BRAND_CLASS[c.Card_Brand__c] || { short: '????', cls: 'scm-brand-icon brand-generic' };
        const mo = c.Expiry_Month__c ? String(c.Expiry_Month__c).padStart(2,'0') : '??';
        const yr = c.Expiry_Year__c  ? String(c.Expiry_Year__c).slice(-2)       : '??';
        const sel = selectedId !== null ? selectedId : this.selectedCardId;
        return {
            ...c,
            brandShort:     brand.short,
            brandIconClass: brand.cls,
            expiryDisplay:  `${mo}/${yr}`,
            isSelected:     c.Id === sel,
            selectorClass: c.Id === sel
                ? 'scm-card-option scm-card-option--selected'
                : 'scm-card-option'
        };
    }

    _refreshCardClasses() {
        this.cards = this.cards.map(c => ({
            ...c,
            isSelected: c.Id === this.selectedCardId,
            selectorClass: c.Id === this.selectedCardId
                ? 'scm-card-option scm-card-option--selected'
                : 'scm-card-option'
        }));
    }

    // ─── Getters ──────────────────────────────────────────────────────────────

    get bookingName() {
        return this._bookingWire?.data ? getFieldValue(this._bookingWire.data, BOOKING_NAME) : '';
    }
    get bookingTotal() {
        const v = this._bookingWire?.data ? getFieldValue(this._bookingWire.data, BOOKING_TOTAL) : 0;
        return parseFloat(v || 0).toFixed(2);
    }
    get balanceDue() {
        const v = this._bookingWire?.data ? getFieldValue(this._bookingWire.data, BOOKING_BALANCE) : 0;
        return parseFloat(v || 0).toFixed(2);
    }
    get amountPaid() {
        const total = parseFloat(this.bookingTotal) || 0;
        const bal   = parseFloat(this.balanceDue)   || 0;
        return (total - bal).toFixed(2);
    }
    get isPaidInFull() {
        return parseFloat(this.balanceDue) <= 0;
    }
    get halfAmount() {
        return (parseFloat(this.balanceDue) / 2).toFixed(2);
    }
    get noCards() {
        return !this.cards || this.cards.length === 0;
    }
    get defaultCard() {
        return this.cards.find(c => c.Is_Default__c) || this.cards[0];
    }
    get closeLabel() {
        return this.chargeSuccess ? 'Done' : 'Cancel';
    }

    // ─── Actions ──────────────────────────────────────────────────────────────

    openModal() {
        this.chargeSuccess = false;
        this.chargeError   = null;
        this.showModal     = true;
        const bal = parseFloat(this.balanceDue) || 0;
        this.chargeAmount  = bal.toFixed(2);
    }

    closeModal() {
        if (this.chargeSuccess) {
            refreshApex(this._bookingWire);
        }
        this.showModal     = false;
        this.chargeSuccess = false;
        this.chargeError   = null;
        this.isProcessing  = false;
    }

    selectCard(e) {
        this.selectedCardId = e.currentTarget.dataset.id;
        this._refreshCardClasses();
    }

    handleAmountChange(e) {
        this.chargeAmount = parseFloat(e.target.value || 0).toFixed(2);
    }
    handleNoteChange(e) { this.chargeNote = e.target.value; }

    chargeHalf() {
        this.chargeAmount = this.halfAmount;
    }
    chargeFull() {
        this.chargeAmount = this.balanceDue;
    }

    async processCharge() {
        this.chargeError = null;
        if (!this.selectedCardId) {
            this.chargeError = 'Please select a card.';
            return;
        }
        const amount = parseFloat(this.chargeAmount);
        if (!amount || amount <= 0) {
            this.chargeError = 'Enter a valid charge amount.';
            return;
        }

        this.isProcessing = true;

        // Simulate Authorize.net processing time
        await this._delay(1800);

        try {
            const result = await chargeCard({
                bookingId: this.recordId,
                cardId:    this.selectedCardId,
                amount:    amount,
                note:      this.chargeNote
            });

            this.chargeSuccess    = true;
            this.lastChargeAmount = parseFloat(result.amountCharged).toFixed(2);
            this.lastCardDisplay  = result.cardDisplay;
            this.lastChargeId     = result.chargeId;

            this.dispatchEvent(new ShowToastEvent({
                title:   'Payment Processed',
                message: `$${this.lastChargeAmount} charged to ${this.lastCardDisplay}`,
                variant: 'success'
            }));

            await refreshApex(this._bookingWire);

        } catch (err) {
            this.chargeError = err.body?.message || 'Payment failed. Please try again.';
        } finally {
            this.isProcessing = false;
        }
    }

    _delay(ms) { return new Promise(r => setTimeout(r, ms)); }
}
