@isTest
private class CruzyPortalManagerControllerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Cruzy Portal Mgr Test', RecordTypeId = '012al000005f9VtAAI');
        insert acc;

        Contact c = new Contact(
            FirstName = 'Manager',
            LastName  = 'TestUser',
            Email     = 'mgr.test@cruzytest.com',
            AccountId = acc.Id,
            Cruzy_Plus_Enrolled__c   = false,
            Portal_Status__c         = null,
            Portal_Password_Hash__c  = null,
            Portal_Login_Count__c    = 0
        );
        insert c;

        Contact enrolled = new Contact(
            FirstName = 'Already',
            LastName  = 'Enrolled',
            Email     = 'enrolled@cruzytest.com',
            AccountId = acc.Id,
            Cruzy_Plus_Enrolled__c   = true,
            Cruzy_Plus_MBR_Number__c = 'CRZ-EXIST'
        );
        insert enrolled;
    }

    @isTest
    static void testGetPortalStatus() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'mgr.test@cruzytest.com' LIMIT 1];

        Test.startTest();
        Map<String, Object> status = CruzyPortalManagerController.getPortalStatus(c.Id);
        Test.stopTest();

        System.assertEquals(c.Id, status.get('contactId'), 'contactId should match');
        System.assertNotEquals(null, status.get('name'), 'Name should be populated');
        System.assertEquals('mgr.test@cruzytest.com', status.get('email'), 'Email should match');
        System.assertEquals(false, status.get('enrolled'), 'Should not be enrolled yet');
        System.assertEquals(false, status.get('hasPassword'), 'No password hash means hasPassword = false');
    }

    @isTest
    static void testSetPortalStatus() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'mgr.test@cruzytest.com' LIMIT 1];

        Test.startTest();
        String result = CruzyPortalManagerController.setPortalStatus(c.Id, 'Active');
        Test.stopTest();

        System.assertEquals('success', result, 'Should return success');
        Contact updated = [SELECT Portal_Status__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals('Active', updated.Portal_Status__c, 'Status should be updated');
    }

    @isTest
    static void testGenerateResetLink_ResetMode() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'mgr.test@cruzytest.com' LIMIT 1];

        Test.startTest();
        String url = CruzyPortalManagerController.generateResetLink(c.Id, 'reset');
        Test.stopTest();

        System.assertNotEquals(null, url, 'URL should be returned');
        System.assert(url.contains('/reset-password?token='), 'Should contain reset-password path');
    }

    @isTest
    static void testGenerateResetLink_WelcomeMode() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'mgr.test@cruzytest.com' LIMIT 1];

        Test.startTest();
        String url = CruzyPortalManagerController.generateResetLink(c.Id, 'welcome');
        Test.stopTest();

        System.assertNotEquals(null, url, 'URL should be returned');
        System.assert(url.contains('/set-password?token='), 'Should contain set-password path');
    }

    @isTest
    static void testEnrollMember_NewEnrollment() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'mgr.test@cruzytest.com' LIMIT 1];

        Test.startTest();
        String result = CruzyPortalManagerController.enrollMember(c.Id);
        Test.stopTest();

        System.assert(result.startsWith('enrolled:'), 'Result should start with enrolled:');
        System.assert(result.contains('CRZ-'), 'Result should contain membership ID');

        Contact updated = [SELECT Cruzy_Plus_Enrolled__c, Cruzy_Plus_MBR_Number__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(true, updated.Cruzy_Plus_Enrolled__c, 'Should be enrolled');
        System.assertNotEquals(null, updated.Cruzy_Plus_MBR_Number__c, 'Membership number should be set');

        List<Membership__c> memberships = [SELECT Id, Status__c, Partner__c FROM Membership__c WHERE Contact__c = :c.Id];
        System.assertEquals(1, memberships.size(), 'One membership should be created');
        System.assertEquals('Active', memberships[0].Status__c, 'Membership should be Active');
        System.assertEquals('Cruzy+', memberships[0].Partner__c, 'Partner should be Cruzy+');
    }

    @isTest
    static void testEnrollMember_AlreadyEnrolled() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'enrolled@cruzytest.com' LIMIT 1];

        Test.startTest();
        String result = CruzyPortalManagerController.enrollMember(c.Id);
        Test.stopTest();

        System.assert(result.startsWith('already_enrolled:'), 'Result should indicate already enrolled');
        System.assert(result.contains('CRZ-EXIST'), 'Should return existing membership number');
    }
}
