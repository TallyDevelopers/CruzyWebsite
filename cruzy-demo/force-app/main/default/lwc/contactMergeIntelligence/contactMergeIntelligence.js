import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import findDuplicates from '@salesforce/apex/ContactMergeController.findDuplicates';
import mergeContacts from '@salesforce/apex/ContactMergeController.mergeContacts';
import dismissDuplicate from '@salesforce/apex/ContactMergeController.dismissDuplicate';

export default class ContactMergeIntelligence extends NavigationMixin(LightningElement) {
    @api recordId;

    @track duplicates = [];
    @track isLoading = true;
    @track showMergeModal = false;
    @track isMerging = false;
    @track pendingMasterId;
    @track pendingDuplicateId;
    @track pendingMergeMasterName = '';
    @track pendingMergeDuplicateName = '';
    @track dismissedIds = new Set();

    _wiredResult;

    @wire(findDuplicates, { contactId: '$recordId' })
    wiredDuplicates(result) {
        this._wiredResult = result;
        this.isLoading = false;
        if (result.data) {
            this.duplicates = result.data
                .filter(d => !this.dismissedIds.has(d.duplicateId))
                .map(d => this._enrichDuplicate(d));
        } else if (result.error) {
            console.error('Error loading duplicates', result.error);
            this.showToast('Error', 'Failed to load duplicate data.', 'error');
        }
    }

    _enrichDuplicate(d) {
        const currentPct = Math.round((d.currentContactScore / d.totalFields) * 100);
        const duplicatePct = Math.round((d.duplicateContactScore / d.totalFields) * 100);

        return {
            ...d,
            currentPct,
            duplicatePct,
            currentBarStyle: `width: ${currentPct}%`,
            duplicateBarStyle: `width: ${duplicatePct}%`,
            showDiff: false,
            diffToggleLabel: 'Show Field Comparison',
            fieldDiffs: (d.fieldDiffs || []).map(f => this._enrichFieldDiff(f))
        };
    }

    _enrichFieldDiff(f) {
        const statusMap = {
            same: { icon: '=', cls: 'status-same', title: 'Same value', rowClass: 'row-same' },
            gain: { icon: '+', cls: 'status-gain', title: 'Duplicate has data this record is missing', rowClass: 'row-gain' },
            loss: { icon: '→', cls: 'status-loss', title: 'This record has data the duplicate is missing', rowClass: 'row-loss' },
            conflict: { icon: '≠', cls: 'status-conflict', title: 'Both records have different values', rowClass: 'row-conflict' }
        };
        const s = statusMap[f.status] || statusMap['same'];

        return {
            ...f,
            statusIcon: s.icon,
            statusIconClass: `status-icon ${s.cls}`,
            statusTitle: s.title,
            rowClass: `diff-row ${s.rowClass}`,
            currentValueDisplay: f.currentValue || '—',
            duplicateValueDisplay: f.duplicateValue || '—',
            currentClass: f.currentValue ? 'cell-filled' : 'cell-empty',
            duplicateClass: f.duplicateValue ? 'cell-filled' : 'cell-empty'
        };
    }

    get hasDuplicates() {
        return this.duplicates && this.duplicates.length > 0;
    }

    get duplicateCount() {
        return this.duplicates ? this.duplicates.length : 0;
    }

    get duplicatePlural() {
        return this.duplicateCount === 1 ? '' : 's';
    }

    handleToggleDiff(event) {
        const dupId = event.currentTarget.dataset.id;
        this.duplicates = this.duplicates.map(d => {
            if (d.duplicateId === dupId) {
                const newShow = !d.showDiff;
                return {
                    ...d,
                    showDiff: newShow,
                    diffToggleLabel: newShow ? 'Hide Field Comparison' : 'Show Field Comparison'
                };
            }
            return d;
        });
    }

    handleDismiss(event) {
        const dupId = event.currentTarget.dataset.id;
        this.dismissedIds.add(dupId);
        this.duplicates = this.duplicates.filter(d => d.duplicateId !== dupId);
        dismissDuplicate({ contactId: this.recordId, duplicateId: dupId }).catch(e => console.warn('Dismiss error', e));
        this.showToast('Dismissed', 'Duplicate flag removed for this session.', 'info');
    }

    handleMerge(event) {
        this.pendingMasterId = event.currentTarget.dataset.master;
        this.pendingDuplicateId = event.currentTarget.dataset.duplicate;

        const masterDup = this.duplicates.find(d =>
            d.duplicateId === this.pendingMasterId || this.recordId === this.pendingMasterId
        );

        if (this.pendingMasterId === this.recordId) {
            this.pendingMergeMasterName = 'This Record (Current)';
        } else {
            const dup = this.duplicates.find(d => d.duplicateId === this.pendingMasterId);
            this.pendingMergeMasterName = dup ? dup.duplicateName : 'Selected Record';
        }

        if (this.pendingDuplicateId === this.recordId) {
            this.pendingMergeDuplicateName = 'This Record (Current)';
        } else {
            const dup = this.duplicates.find(d => d.duplicateId === this.pendingDuplicateId);
            this.pendingMergeDuplicateName = dup ? dup.duplicateName : 'Selected Record';
        }

        this.showMergeModal = true;
    }

    handleCancelMerge() {
        this.showMergeModal = false;
        this.pendingMasterId = null;
        this.pendingDuplicateId = null;
    }

    async handleConfirmMerge() {
        this.isMerging = true;
        try {
            const result = await mergeContacts({
                masterId: this.pendingMasterId,
                duplicateId: this.pendingDuplicateId
            });

            this.isMerging = false;
            this.showMergeModal = false;

            if (result.success) {
                this.showToast('Merge Successful', result.message, 'success');

                if (result.survivingId === this.recordId) {
                    // Current record survived - refresh
                    this.duplicates = [];
                    this.isLoading = true;
                    await refreshApex(this._wiredResult);
                    this.isLoading = false;
                } else {
                    // Navigate to the surviving record
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result.survivingId,
                            objectApiName: 'Contact',
                            actionName: 'view'
                        }
                    });
                }
            } else {
                this.showToast('Merge Failed', result.message, 'error');
            }
        } catch (e) {
            this.isMerging = false;
            this.showToast('Error', e.body ? e.body.message : e.message, 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
