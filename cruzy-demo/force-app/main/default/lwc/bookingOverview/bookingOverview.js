import getBookingDetails from '@salesforce/apex/BookingOverviewController.getBookingDetails';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';

export default class BookingOverview extends NavigationMixin(LightningElement) {
    @api recordId;
    booking;
    loading = true;
    error;
    _addOnsOpen = false;
    _paymentsOpen = false;

    @wire(getBookingDetails, { bookingId: '$recordId' })
    wiredBooking({ error, data }) {
        this.loading = false;
        if (data) {
            this.booking = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.booking = undefined;
        }
    }

    get hasBooking()   { return !!this.booking; }
    get hasAddOns()    { return this.booking?.addOns?.length > 0; }
    get hasPayments()  { return this.booking?.payments?.length > 0; }
    get hasReward()    { return !!this.booking?.rewardId; }
    get fromOdysseus() { return !!this.booking?.fromOdysseus; }
    get addOnsOpen()   { return this._addOnsOpen; }
    get paymentsOpen() { return this._paymentsOpen; }

    get statusClass() {
        const s = this.booking?.status?.toLowerCase() || '';
        if (s === 'booking' || s === 'confirmed') return 'pill-confirmed';
        if (s === 'quote')     return 'pill-quote';
        if (s === 'cancelled') return 'pill-cancelled';
        if (s === 'completed') return 'pill-completed';
        return 'pill-default';
    }

    get initials() {
        const n = this.booking?.contactName || '';
        return n.split(' ').map(w => w[0]).join('').toUpperCase().substring(0, 2);
    }

    get departureFormatted() {
        return this._fmtDate(this.booking?.departureDate);
    }
    get returnFormatted() {
        return this._fmtDate(this.booking?.returnDate);
    }
    get paymentDateFormatted() {
        return this._fmtDate(this.booking?.paymentDate);
    }

    get durationLabel() {
        const n = this.booking?.durationNights;
        return n ? `${n} Night${n !== 1 ? 's' : ''}` : '—';
    }

    get originalTotalFmt()    { return this._fmtCur(this.booking?.originalTotal); }
    get currentBalanceFmt()   { return this._fmtCur(this.booking?.currentBalance); }
    get cruiseTotalFmt()      { return this._fmtCur(this.booking?.cruiseTotal); }
    get cruiseLineFareFmt()   { return this._fmtCur(this.booking?.cruiseLineTotalFare); }
    get savingsFmt()          { return this._fmtCur(this.booking?.savings); }
    get markUpFmt()           { return this._fmtCur(this.booking?.markUp); }
    get pricePerPersonDayFmt(){ return this._fmtCur(this.booking?.pricePerPersonDay); }

    get markUpPercentFmt() {
        const v = this.booking?.markUpPercent;
        return v != null ? `${(v * 100).toFixed(1)}%` : '—';
    }

    get hasBalance() {
        return this.booking?.currentBalance > 0;
    }

    get balanceCellClass() {
        return this.hasBalance ? 'bko-cell-val bko-val-red' : 'bko-cell-val';
    }

    get addOnList() {
        return (this.booking?.addOns || []).map((a, i) => ({
            ...a,
            key: a.id || `ao-${i}`,
            amountFmt: this._fmtCur(a.amount)
        }));
    }

    get addOnTotal() {
        const t = (this.booking?.addOns || []).reduce((s, a) => s + (a.amount || 0), 0);
        return this._fmtCur(t);
    }

    get addOnCount() {
        return this.booking?.addOns?.length || 0;
    }

    get paymentList() {
        return (this.booking?.payments || []).map((p, i) => ({
            ...p,
            key: p.id || `pm-${i}`,
            amountFmt: this._fmtCur(p.amount),
            dateFmt: this._fmtDate(p.paymentDate)
        }));
    }

    get paymentTotal() {
        const t = (this.booking?.payments || []).reduce((s, p) => s + (p.amount || 0), 0);
        return this._fmtCur(t);
    }

    get paymentCount() {
        return this.booking?.payments?.length || 0;
    }

    get addOnsChevron() { return this._addOnsOpen ? '▾' : '▸'; }
    get paymentsChevron() { return this._paymentsOpen ? '▾' : '▸'; }

    toggleAddOns()   { this._addOnsOpen = !this._addOnsOpen; }
    togglePayments() { this._paymentsOpen = !this._paymentsOpen; }

    navigateToContact() {
        if (!this.booking?.contactId) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: this.booking.contactId, objectApiName: 'Contact', actionName: 'view' }
        });
    }

    navigateToAccount() {
        if (!this.booking?.accountId) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: this.booking.accountId, objectApiName: 'Account', actionName: 'view' }
        });
    }

    navigateToReward() {
        if (!this.booking?.rewardId) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: this.booking.rewardId, objectApiName: 'Reward__c', actionName: 'view' }
        });
    }

    _fmtCur(v) {
        if (v == null) return '—';
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(v);
    }

    _fmtDate(v) {
        if (!v) return '—';
        const d = new Date(v + 'T00:00:00');
        return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    }
}
