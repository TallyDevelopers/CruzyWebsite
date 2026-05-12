import { LightningElement, api, wire, track } from 'lwc';
import getCustomerIntelligence from '@salesforce/apex/CustomerJourneyController.getCustomerIntelligence';

const VIFP_PILL = {
    'Red':          'cib-flag-pill flag-vifp-red',
    'Gold':         'cib-flag-pill flag-vifp-gold',
    'Platinum':     'cib-flag-pill flag-vifp-plat',
    'Diamond':      'cib-flag-pill flag-vifp-diamond',
    'Diamond Plus': 'cib-flag-pill flag-vifp-diamondplus'
};

const ADDON_HEAVY_THRESHOLD = 3; // 3+ add-ons = "Heavy User"

export default class CustomerIntelligenceBanner extends LightningElement {
    @api recordId;

    @track data    = null;
    @track isLoading = true;

    @wire(getCustomerIntelligence, { contactId: '$recordId' })
    wired({ data, error }) {
        if (data) {
            this.data     = data;
            this.isLoading = false;
        } else if (error) {
            console.error('CustomerIntelligenceBanner:', JSON.stringify(error));
            this.isLoading = false;
        }
    }

    // ── Computed ──────────────────────────────────────────────────────────────

    get hasData() { return !!this.data; }

    // Membership
    get membershipDisplay() {
        if (!this.data.hasMembership) return 'No Membership';
        return this.data.membershipStatus || 'Active';
    }
    get membershipSub() {
        if (!this.data.hasMembership) return 'Not enrolled';
        if (this.data.membershipExpDate) {
            const d = new Date(this.data.membershipExpDate);
            const today = new Date();
            const days = Math.ceil((d - today) / 86400000);
            if (days < 0)      return 'Expired';
            if (days <= 30)    return 'Expires in ' + days + 'd';
            return 'Exp ' + d.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
        }
        return this.data.membershipAutoRenew ? 'Auto-renews' : 'No auto-renew';
    }
    get membershipTileClass() {
        if (!this.data.hasMembership) return 'cib-tile cib-tile-mbr mbr-none';
        const s = this.data.membershipStatus;
        if (s === 'Active')                  return 'cib-tile cib-tile-mbr mbr-active';
        if (s === 'Cancelled')               return 'cib-tile cib-tile-mbr mbr-cancelled';
        if (s === 'Inactive - Need Payment') return 'cib-tile cib-tile-mbr mbr-inactive';
        return 'cib-tile cib-tile-mbr mbr-hold';
    }
    get membershipDotClass() {
        if (!this.data.hasMembership) return 'cib-status-dot dot-none';
        const s = this.data.membershipStatus;
        if (s === 'Active')                  return 'cib-status-dot dot-active';
        if (s === 'Cancelled')               return 'cib-status-dot dot-cancelled';
        if (s === 'Inactive - Need Payment') return 'cib-status-dot dot-inactive';
        return 'cib-status-dot dot-hold';
    }

    // Bookings
    get bookingSubLabel() {
        const n = this.data.bookingCount;
        if (n === 0) return 'No bookings yet';
        if (n === 1) return '1 trip booked';
        return n + ' trips total';
    }

    // Spend
    get totalSpendDisplay() {
        return this._fmt(this.data.totalSpend || 0);
    }
    get cruiseValueDisplay() {
        return this._fmt(this.data.totalCruiseValue || 0);
    }

    // Balance
    get hasOverdueBalance() {
        return (this.data.totalBalanceDue || 0) > 0;
    }
    get balanceTileClass() {
        return this.hasOverdueBalance ? 'cib-tile cib-tile-balance balance-due' : 'cib-tile cib-tile-balance balance-clear';
    }
    get balanceIconWrapClass() {
        return this.hasOverdueBalance ? 'cib-tile-icon-wrap cib-icon-balance-due' : 'cib-tile-icon-wrap cib-icon-balance-ok';
    }
    get balanceIcon() {
        return this.hasOverdueBalance ? 'utility:error' : 'utility:check';
    }
    get balanceValueClass() {
        return this.hasOverdueBalance ? 'cib-tile-value cib-val-overdue' : 'cib-tile-value cib-val-clear';
    }
    get balanceDueDisplay() {
        return this._fmt(this.data.totalBalanceDue || 0);
    }
    get balanceSubLabel() {
        return this.hasOverdueBalance ? 'Requires collection' : 'All paid up';
    }

    // Add-Ons
    get isAddOnHeavy() {
        return (this.data.addOnCount || 0) >= ADDON_HEAVY_THRESHOLD;
    }
    get addonTileClass() {
        return this.isAddOnHeavy ? 'cib-tile cib-tile-addon addon-heavy' : 'cib-tile cib-tile-addon';
    }
    get addonIconWrapClass() {
        return this.isAddOnHeavy ? 'cib-tile-icon-wrap cib-icon-addon-heavy' : 'cib-tile-icon-wrap cib-icon-addon';
    }
    get addOnSpendDisplay() {
        return this._fmt(this.data.addOnSpend || 0);
    }

    // Rewards
    get rewardSubLabel() {
        const n = this.data.rewardCount || 0;
        if (n === 0) return 'No rewards';
        return n === 1 ? '1 reward on file' : n + ' rewards on file';
    }

    // Flags
    get hasVifp()  { return !!this.data.vifpLevel; }
    get vifpPillClass() { return VIFP_PILL[this.data.vifpLevel] || 'cib-flag-pill flag-vifp-red'; }
    get hasAnyFlag() {
        return this.data.spanishSpeaking || this.data.cruzyPlusEnrolled
            || this.hasVifp || this.data.customerSource;
    }

    // Alerts strip
    get hasAlerts() {
        return this.data.isBolo || this.data.hasAccountAlert
            || this.data.membershipOnHold || this.hasOverdueBalance;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    _fmt(n) {
        return parseFloat(n).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }
}
