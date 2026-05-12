import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPartnerStatus from '@salesforce/apex/CruzyPartnerManagerController.getPartnerStatus';
import enrollPartner from '@salesforce/apex/CruzyPartnerManagerController.enrollPartner';
import generateResetLink from '@salesforce/apex/CruzyPartnerManagerController.generateResetLink';
import setPortalStatus from '@salesforce/apex/CruzyPartnerManagerController.setPortalStatus';
import setTemporaryPassword from '@salesforce/apex/CruzyPartnerManagerController.setTemporaryPassword';

export default class CruzyPartnerManager extends LightningElement {
    @api recordId;

    @track portalData = null;
    @track isLoading = true;
    @track isBusy = false;
    @track errorMsg = null;
    @track successMsg = null;
    @track generatedLink = null;
    @track showTempPasswordModal = false;
    @track tempPassword = '';
    @track tempPasswordError = '';
    @track showTempPassword = false;

    _wiredResult;

    @wire(getPartnerStatus, { contactId: '$recordId' })
    wiredStatus(result) {
        this._wiredResult = result;
        if (result.data) {
            this.portalData = result.data;
            this.isLoading = false;
            this.errorMsg = null;
        } else if (result.error) {
            this.errorMsg = 'Failed to load partner status. ' + (result.error.body?.message || '');
            this.isLoading = false;
        }
    }

    get portalTypeDisplay() {
        return this.portalData?.portalType || 'Not Set';
    }

    get lastLoginDisplay() {
        if (!this.portalData?.lastLogin) return 'Never';
        return new Date(this.portalData.lastLogin).toLocaleString('en-US', {
            month: 'short', day: 'numeric', year: 'numeric',
            hour: 'numeric', minute: '2-digit'
        });
    }

    get loginCountDisplay() {
        return this.portalData?.loginCount || '0';
    }

    get resetExpiryDisplay() {
        if (!this.portalData?.resetExpiry) return '—';
        const exp = new Date(this.portalData.resetExpiry);
        return exp < new Date() ? 'Expired' : exp.toLocaleString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' });
    }

    get passwordSetLabel() {
        return this.portalData?.hasPassword ? '✓ Yes' : '✗ Not set';
    }

    get passwordSetClass() {
        return 'info-value ' + (this.portalData?.hasPassword ? 'text-success' : 'text-warning');
    }

    get statusBadgeClass() {
        const s = this.portalData?.portalStatus;
        const base = 'status-badge ';
        if (s === 'Active') return base + 'status-active';
        if (s === 'Inactive') return base + 'status-inactive';
        if (s === 'Pending') return base + 'status-pending';
        if (s === 'Locked') return base + 'status-locked';
        return base + 'status-pending';
    }

    get isActive() { return this.portalData?.portalStatus === 'Active'; }
    get statusToggleTitle() { return this.isActive ? 'Deactivate Portal Access' : 'Activate Portal Access'; }
    get statusToggleDesc() { return this.isActive ? 'Immediately blocks this partner from logging in' : 'Restores this partner\'s ability to log in'; }
    get statusToggleLabel() { return this.isActive ? 'Deactivate' : 'Activate'; }
    get statusToggleVariant() { return this.isActive ? 'destructive' : 'success'; }
    get statusToggleIcon() { return this.isActive ? 'utility:ban' : 'utility:check'; }
    get tempPasswordInputType() { return this.showTempPassword ? 'text' : 'password'; }
    get tempPasswordToggleIcon() { return this.showTempPassword ? 'utility:hide' : 'utility:preview'; }
    get tempPasswordToggleLabel() { return this.showTempPassword ? 'Hide' : 'Show'; }
    get isSetPasswordDisabled() { return this.isBusy || !this.tempPassword || this.tempPassword.length < 8; }

    clearMessages() {
        this.errorMsg = null;
        this.successMsg = null;
        this.generatedLink = null;
    }

    async handleEnroll() {
        this.clearMessages();
        this.isBusy = true;
        try {
            const result = await enrollPartner({ contactId: this.recordId });
            if (result === 'already_enrolled') {
                this.errorMsg = 'This contact is already enrolled as a Partner user.';
            } else {
                const link = result.split(':').slice(1).join(':');
                this.successMsg = '✓ Partner enrolled! Welcome email sent.';
                if (link) this.generatedLink = link;
                this.dispatchEvent(new ShowToastEvent({ title: 'Partner Enrolled', message: 'Partner portal access created and welcome email sent.', variant: 'success' }));
            }
            await refreshApex(this._wiredResult);
        } catch (e) {
            this.errorMsg = e.body?.message || 'Enrollment failed.';
        } finally {
            this.isBusy = false;
        }
    }

    async handleSendReset() {
        this.clearMessages();
        this.isBusy = true;
        try {
            const link = await generateResetLink({ contactId: this.recordId, mode: 'reset' });
            this.successMsg = `✓ Password reset email sent to ${this.portalData.email}. Link expires in 1 hour.`;
            this.generatedLink = link;
            this.dispatchEvent(new ShowToastEvent({ title: 'Reset Link Sent', message: 'Password reset email sent successfully.', variant: 'success' }));
            await refreshApex(this._wiredResult);
        } catch (e) {
            this.errorMsg = e.body?.message || 'Failed to send reset link.';
        } finally {
            this.isBusy = false;
        }
    }

    async handleSendWelcome() {
        this.clearMessages();
        this.isBusy = true;
        try {
            const link = await generateResetLink({ contactId: this.recordId, mode: 'welcome' });
            this.successMsg = `✓ Welcome / set-password email sent to ${this.portalData.email}. Link expires in 24 hours.`;
            this.generatedLink = link;
            this.dispatchEvent(new ShowToastEvent({ title: 'Welcome Email Sent', message: 'Set-password link sent successfully.', variant: 'success' }));
            await refreshApex(this._wiredResult);
        } catch (e) {
            this.errorMsg = e.body?.message || 'Failed to send welcome email.';
        } finally {
            this.isBusy = false;
        }
    }

    async handleStatusToggle() {
        this.clearMessages();
        this.isBusy = true;
        const newStatus = this.isActive ? 'Inactive' : 'Active';
        try {
            await setPortalStatus({ contactId: this.recordId, status: newStatus });
            this.successMsg = `✓ Portal access set to ${newStatus}.`;
            this.dispatchEvent(new ShowToastEvent({ title: 'Status Updated', message: `Portal access is now ${newStatus}.`, variant: newStatus === 'Active' ? 'success' : 'warning' }));
            await refreshApex(this._wiredResult);
        } catch (e) {
            this.errorMsg = e.body?.message || 'Failed to update status.';
        } finally {
            this.isBusy = false;
        }
    }

    openTempPasswordModal() {
        this.tempPassword = '';
        this.tempPasswordError = '';
        this.showTempPassword = false;
        this.showTempPasswordModal = true;
    }

    closeTempPasswordModal() {
        this.showTempPasswordModal = false;
        this.tempPassword = '';
        this.tempPasswordError = '';
    }

    handleTempPasswordChange(event) {
        this.tempPassword = event.target.value;
        this.tempPasswordError = (this.tempPassword.length > 0 && this.tempPassword.length < 8) ? 'Must be at least 8 characters' : '';
    }

    toggleTempPasswordVisibility() { this.showTempPassword = !this.showTempPassword; }

    generateRandomPassword() {
        const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$%';
        let pw = '';
        for (let i = 0; i < 12; i++) pw += chars.charAt(Math.floor(Math.random() * chars.length));
        this.tempPassword = pw;
        this.showTempPassword = true;
        this.tempPasswordError = '';
    }

    async handleSetTempPassword() {
        if (!this.tempPassword || this.tempPassword.length < 8) {
            this.tempPasswordError = 'Must be at least 8 characters';
            return;
        }
        this.clearMessages();
        this.isBusy = true;
        try {
            await setTemporaryPassword({ contactId: this.recordId, tempPassword: this.tempPassword });
            this.closeTempPasswordModal();
            this.successMsg = `✓ Temporary password set and emailed to ${this.portalData.email}.`;
            this.dispatchEvent(new ShowToastEvent({ title: 'Password Set', message: 'Temporary password set and notification email sent.', variant: 'success' }));
            await refreshApex(this._wiredResult);
        } catch (e) {
            this.tempPasswordError = e.body?.message || 'Failed to set password.';
        } finally {
            this.isBusy = false;
        }
    }

    copyLink() {
        if (!this.generatedLink) return;
        navigator.clipboard.writeText(this.generatedLink).then(() => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Copied', message: 'Link copied to clipboard.', variant: 'success', mode: 'dismissable' }));
        });
    }
}
