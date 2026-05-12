public with sharing class ContactMergeController {

    @AuraEnabled(cacheable=true)
    public static List<DuplicateResult> findDuplicates(Id contactId) {
        Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
        if (resolvedId == null) return new List<DuplicateResult>();
        Contact current = getContactById(resolvedId);
        if (current == null) return new List<DuplicateResult>();

        Set<Id> candidateIds = new Set<Id>();

        // Match on Email
        if (String.isNotBlank(current.Email)) {
            for (Contact c : [
                SELECT Id FROM Contact
                WHERE (Email = :current.Email OR Alt_Email__c = :current.Email)
                AND Id != :resolvedId LIMIT 10
            ]) {
                candidateIds.add(c.Id);
            }
        }

        // Match on Phone
        if (String.isNotBlank(current.Phone)) {
            for (Contact c : [
                SELECT Id FROM Contact
                WHERE (Phone = :current.Phone OR Alt_Phone__c = :current.Phone OR Phone_3__c = :current.Phone OR Phone_4__c = :current.Phone)
                AND Id != :resolvedId LIMIT 10
            ]) {
                candidateIds.add(c.Id);
            }
        }

        // Match on Alt_Email
        if (String.isNotBlank(current.Alt_Email__c)) {
            for (Contact c : [
                SELECT Id FROM Contact
                WHERE (Email = :current.Alt_Email__c OR Alt_Email__c = :current.Alt_Email__c)
                AND Id != :resolvedId LIMIT 10
            ]) {
                candidateIds.add(c.Id);
            }
        }

        // Fuzzy last name + first name initial match
        if (String.isNotBlank(current.LastName)) {
            String lastNameLower = current.LastName.toLowerCase();
            for (Contact c : [
                SELECT Id, LastName, FirstName FROM Contact
                WHERE LastName = :current.LastName
                AND Id != :resolvedId LIMIT 20
            ]) {
                if (String.isNotBlank(current.FirstName) && String.isNotBlank(c.FirstName)) {
                    // same first letter of first name
                    if (current.FirstName.substring(0,1).equalsIgnoreCase(c.FirstName.substring(0,1))) {
                        candidateIds.add(c.Id);
                    }
                } else {
                    candidateIds.add(c.Id);
                }
            }
        }

        if (candidateIds.isEmpty()) return new List<DuplicateResult>();

        List<Contact> candidates = getContactsByIds(new List<Id>(candidateIds));
        List<DuplicateResult> results = new List<DuplicateResult>();

        Integer currentScore = computeScore(current);

        for (Contact candidate : candidates) {
            DuplicateResult dr = new DuplicateResult();
            dr.duplicateId = candidate.Id;
            dr.duplicateName = candidate.FirstName + ' ' + candidate.LastName;
            dr.currentContactScore = currentScore;
            dr.duplicateContactScore = computeScore(candidate);
            dr.totalFields = SCORED_FIELDS.size();
            dr.matchReasons = buildMatchReasons(current, candidate);
            dr.fieldDiffs = buildFieldDiffs(current, candidate);
            dr.winnerIsCurrentContact = (currentScore >= dr.duplicateContactScore);
            results.add(dr);
        }

        results.sort();
        final Integer maxDupes = 8;
        if (results.size() > maxDupes) {
            List<DuplicateResult> capped = new List<DuplicateResult>();
            for (Integer i = 0; i < maxDupes; i++) {
                capped.add(results[i]);
            }
            return capped;
        }
        return results;
    }

    @AuraEnabled
    public static void dismissDuplicate(Id contactId, Id duplicateId) {
        // No-op for demo — in production use a junction object to track dismissed pairs
    }

    @AuraEnabled
    public static MergeResult mergeContacts(Id masterId, Id duplicateId) {
        MergeResult result = new MergeResult();
        try {
            Database.merge(new Contact(Id = masterId), duplicateId);
            result.success = true;
            result.message = 'Contacts merged successfully. All related records have been transferred.';
            result.survivingId = masterId;
        } catch (Exception e) {
            result.success = false;
            result.message = 'Merge failed: ' + e.getMessage();
        }
        return result;
    }

    // ─── Helpers ────────────────────────────────────────────────────────────────

    private static final List<String> SCORED_FIELDS = new List<String>{
        'FirstName','LastName','Email','Phone','MailingStreet','MailingCity','MailingState','MailingPostalCode',
        'Alt_Email__c','Alt_Phone__c','Phone_3__c','Phone_4__c',
        'Primary_DOB__c','Secondary_DOB__c','VIFP_Number__c','VIFP_Level__c',
        'Spouse_Significant_Other__c','Nickname__c','Timezone__c',
        'Customer_Source__c','Customer_Notes__c','PCC__c',
        'Cruzy_Plus_MBR_Number__c','Cruzy_Plus_Enrolled__c'
    };

    private static Integer computeScore(Contact c) {
        Integer score = 0;
        Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(c));
        for (String field : SCORED_FIELDS) {
            Object val = fieldMap.get(field);
            if (val != null && String.valueOf(val) != '' && String.valueOf(val) != 'false') {
                score++;
            }
        }
        return score;
    }

    private static List<FieldDiff> buildFieldDiffs(Contact current, Contact dupe) {
        List<FieldDiff> diffs = new List<FieldDiff>();
        Map<String, Object> currentMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(current));
        Map<String, Object> dupeMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(dupe));

        List<String> displayFields = new List<String>{
            'FirstName','LastName','Email','Phone','MailingStreet','MailingCity','MailingState','MailingPostalCode',
            'Alt_Email__c','Alt_Phone__c','Timezone__c','Primary_DOB__c',
            'VIFP_Number__c','VIFP_Level__c','Customer_Source__c',
            'Spouse_Significant_Other__c','Nickname__c','PCC__c','Cruzy_Plus_MBR_Number__c'
        };

        Map<String, String> labelMap = new Map<String, String>{
            'FirstName' => 'First Name','LastName' => 'Last Name','Email' => 'Email','Phone' => 'Phone',
            'MailingStreet' => 'Street','MailingCity' => 'City','MailingState' => 'State',
            'MailingPostalCode' => 'Zip','Alt_Email__c' => 'Alt Email','Alt_Phone__c' => 'Alt Phone',
            'Timezone__c' => 'Timezone','Primary_DOB__c' => 'Date of Birth',
            'VIFP_Number__c' => 'VIFP #','VIFP_Level__c' => 'VIFP Level',
            'Customer_Source__c' => 'Customer Source','Spouse_Significant_Other__c' => 'Spouse/S.O.',
            'Nickname__c' => 'Nickname','PCC__c' => 'PCC','Cruzy_Plus_MBR_Number__c' => 'Cruzy+ MBR #'
        };

        for (String field : displayFields) {
            String currentVal = currentMap.containsKey(field) ? String.valueOf(currentMap.get(field)) : '';
            String dupeVal = dupeMap.containsKey(field) ? String.valueOf(dupeMap.get(field)) : '';
            if (currentVal == 'null') currentVal = '';
            if (dupeVal == 'null') dupeVal = '';

            String status = 'same';
            if (currentVal != dupeVal) {
                if (String.isBlank(currentVal) && String.isNotBlank(dupeVal)) {
                    status = 'gain'; // duplicate has data we don't
                } else if (String.isNotBlank(currentVal) && String.isBlank(dupeVal)) {
                    status = 'loss'; // we have data the duplicate doesn't
                } else {
                    status = 'conflict'; // both have data but different
                }
            }

            FieldDiff fd = new FieldDiff();
            fd.fieldLabel = labelMap.containsKey(field) ? labelMap.get(field) : field;
            fd.fieldName = field;
            fd.currentValue = currentVal;
            fd.duplicateValue = dupeVal;
            fd.status = status;
            diffs.add(fd);
        }
        return diffs;
    }

    private static List<String> buildMatchReasons(Contact current, Contact dupe) {
        List<String> reasons = new List<String>();
        if (String.isNotBlank(current.Email) && current.Email == dupe.Email) reasons.add('Same Email');
        if (String.isNotBlank(current.Phone) && current.Phone == dupe.Phone) reasons.add('Same Phone');
        if (String.isNotBlank(current.Email) && current.Email == dupe.Alt_Email__c) reasons.add('Email matches Alt Email');
        if (String.isNotBlank(current.Alt_Email__c) && current.Alt_Email__c == dupe.Email) reasons.add('Alt Email matches Email');
        if (String.isNotBlank(current.LastName) && current.LastName == dupe.LastName) reasons.add('Same Last Name');
        if (String.isNotBlank(current.Phone) && (current.Phone == dupe.Alt_Phone__c || current.Phone == dupe.Phone_3__c)) reasons.add('Phone matches Alt Phone');
        return reasons;
    }

    private static Contact getContactById(Id contactId) {
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Email, Alt_Email__c, Phone, Alt_Phone__c, Phone_3__c, Phone_4__c,
                   MailingStreet, MailingCity, MailingState, MailingPostalCode,
                   Primary_DOB__c, Secondary_DOB__c, VIFP_Number__c, VIFP_Level__c,
                   Spouse_Significant_Other__c, Nickname__c, Timezone__c,
                   Customer_Source__c, Customer_Notes__c, PCC__c,
                   Cruzy_Plus_MBR_Number__c, Cruzy_Plus_Enrolled__c
            FROM Contact WHERE Id = :contactId LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }

    private static List<Contact> getContactsByIds(List<Id> ids) {
        return [
            SELECT Id, FirstName, LastName, Email, Alt_Email__c, Phone, Alt_Phone__c, Phone_3__c, Phone_4__c,
                   MailingStreet, MailingCity, MailingState, MailingPostalCode,
                   Primary_DOB__c, Secondary_DOB__c, VIFP_Number__c, VIFP_Level__c,
                   Spouse_Significant_Other__c, Nickname__c, Timezone__c,
                   Customer_Source__c, Customer_Notes__c, PCC__c,
                   Cruzy_Plus_MBR_Number__c, Cruzy_Plus_Enrolled__c
            FROM Contact WHERE Id IN :ids
        ];
    }

    // ─── Inner Classes ───────────────────────────────────────────────────────────

    public class DuplicateResult implements Comparable {
        @AuraEnabled public Id duplicateId;
        @AuraEnabled public String duplicateName;
        @AuraEnabled public Integer currentContactScore;
        @AuraEnabled public Integer duplicateContactScore;
        @AuraEnabled public Integer totalFields;
        @AuraEnabled public Boolean winnerIsCurrentContact;
        @AuraEnabled public List<String> matchReasons;
        @AuraEnabled public List<FieldDiff> fieldDiffs;

        public Integer compareTo(Object other) {
            DuplicateResult o = (DuplicateResult) other;
            return o.duplicateContactScore - this.duplicateContactScore;
        }
    }

    public class FieldDiff {
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String currentValue;
        @AuraEnabled public String duplicateValue;
        @AuraEnabled public String status; // same | gain | loss | conflict
    }

    public class MergeResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id survivingId;
    }
}
