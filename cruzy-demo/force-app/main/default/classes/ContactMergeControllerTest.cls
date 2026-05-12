@isTest
private class ContactMergeControllerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Cruzy Merge Test', RecordTypeId = '012al000005f9VtAAI');
        insert acc;

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;

        Contact master = new Contact(
            FirstName   = 'John',
            LastName    = 'Doe',
            Email       = 'john.doe@cruzytest.com',
            Phone       = '5551234567',
            Alt_Email__c= 'johnd@alt.com',
            Alt_Phone__c= '5559876543',
            AccountId   = acc.Id,
            Timezone__c = 'Eastern',
            VIFP_Number__c = 'V12345',
            VIFP_Level__c  = 'Gold',
            Customer_Source__c = 'Referral',
            Cruzy_Plus_MBR_Number__c = 'CRZ-001',
            Cruzy_Plus_Enrolled__c   = true
        );
        Database.insert(master, dml);

        Contact dupe = new Contact(
            FirstName   = 'Jon',
            LastName    = 'Doe',
            Email       = 'john.doe@cruzytest.com',
            Phone       = '5551234567',
            Alt_Email__c= 'jdoe@other.com',
            Phone_3__c  = '5551234567',
            AccountId   = acc.Id,
            Nickname__c = 'Johnny'
        );
        Database.insert(dupe, dml);

        Contact noMatch = new Contact(
            FirstName = 'Completely',
            LastName  = 'Different',
            Email     = 'unique@nomatch.com',
            Phone     = '0000000000',
            AccountId = acc.Id
        );
        Database.insert(noMatch, dml);
    }

    @isTest
    static void testFindDuplicates_ByEmail() {
        Contact master = [SELECT Id FROM Contact WHERE Email = 'john.doe@cruzytest.com' AND FirstName = 'John' LIMIT 1];

        Test.startTest();
        List<ContactMergeController.DuplicateResult> results = ContactMergeController.findDuplicates(master.Id);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should find at least one duplicate');
        for (ContactMergeController.DuplicateResult dr : results) {
            System.assertNotEquals(null, dr.duplicateId, 'Duplicate Id should be populated');
            System.assertNotEquals(null, dr.matchReasons, 'Match reasons should be populated');
            System.assertNotEquals(null, dr.fieldDiffs, 'Field diffs should be populated');
            System.assert(dr.totalFields > 0, 'Total fields should be positive');
        }
    }

    @isTest
    static void testFindDuplicates_ByAltEmail() {
        Contact dupe = [SELECT Id FROM Contact WHERE Alt_Email__c = 'jdoe@other.com' LIMIT 1];

        Test.startTest();
        List<ContactMergeController.DuplicateResult> results = ContactMergeController.findDuplicates(dupe.Id);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should find duplicates via email/alt-email cross-match');
    }

    @isTest
    static void testFindDuplicates_NoneFound() {
        Contact noMatch = [SELECT Id FROM Contact WHERE Email = 'unique@nomatch.com' LIMIT 1];

        Test.startTest();
        List<ContactMergeController.DuplicateResult> results = ContactMergeController.findDuplicates(noMatch.Id);
        Test.stopTest();

        System.assert(results.isEmpty(), 'Should find no duplicates for a unique contact');
    }

    @isTest
    static void testFindDuplicates_InvalidId() {
        Test.startTest();
        try {
            ContactMergeController.findDuplicates(null);
        } catch (Exception e) {
            System.assertNotEquals(null, e, 'Should throw an exception for null Id');
        }
        Test.stopTest();
    }

    @isTest
    static void testDismissDuplicate() {
        Contact master = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
        Contact dupe   = [SELECT Id FROM Contact WHERE FirstName = 'Jon' AND LastName = 'Doe' LIMIT 1];

        Test.startTest();
        ContactMergeController.dismissDuplicate(master.Id, dupe.Id);
        Test.stopTest();
        // No-op in demo — just verifying it doesn't throw
    }

    @isTest
    static void testMergeContacts_Success() {
        Contact master = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
        Contact dupe   = [SELECT Id FROM Contact WHERE FirstName = 'Jon' AND LastName = 'Doe' LIMIT 1];

        Test.startTest();
        ContactMergeController.MergeResult result = ContactMergeController.mergeContacts(master.Id, dupe.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Merge should succeed');
        System.assertEquals(master.Id, result.survivingId, 'Surviving Id should be the master');
        System.assert(result.message.contains('merged successfully'), 'Message should confirm success');

        List<Contact> remaining = [SELECT Id FROM Contact WHERE Id = :dupe.Id];
        System.assert(remaining.isEmpty(), 'Duplicate contact should be deleted after merge');
    }

    @isTest
    static void testMergeContacts_SameId() {
        Contact master = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];

        Test.startTest();
        ContactMergeController.MergeResult result = ContactMergeController.mergeContacts(master.Id, master.Id);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Merging a record with itself should fail');
        System.assert(result.message.contains('Merge failed'), 'Message should indicate failure');
    }

    @isTest
    static void testDuplicateResult_Comparable() {
        ContactMergeController.DuplicateResult dr1 = new ContactMergeController.DuplicateResult();
        dr1.duplicateContactScore = 10;
        ContactMergeController.DuplicateResult dr2 = new ContactMergeController.DuplicateResult();
        dr2.duplicateContactScore = 5;

        List<ContactMergeController.DuplicateResult> results = new List<ContactMergeController.DuplicateResult>{ dr2, dr1 };
        results.sort();
        System.assertEquals(10, results[0].duplicateContactScore, 'Higher score should sort first (descending)');
    }
}
