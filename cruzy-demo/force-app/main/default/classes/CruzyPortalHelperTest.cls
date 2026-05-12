@isTest
private class CruzyPortalHelperTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Cruzy Test Household', RecordTypeId = '012al000005f9VtAAI');
        insert acc;

        Contact c = new Contact(
            FirstName = 'Portal',
            LastName  = 'Tester',
            Email     = 'portal.tester@cruzytest.com',
            AccountId = acc.Id
        );
        insert c;
    }

    @isTest
    static void testGenerateToken_WelcomeMode() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'portal.tester@cruzytest.com' LIMIT 1];

        CruzyPortalHelper.TokenRequest req = new CruzyPortalHelper.TokenRequest();
        req.contactId = c.Id;
        req.mode      = 'welcome';
        req.baseUrl   = 'https://members.cruzy.com';

        Test.startTest();
        List<String> urls = CruzyPortalHelper.generateToken(new List<CruzyPortalHelper.TokenRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, urls.size(), 'Should return one URL');
        System.assert(urls[0].contains('/set-password?token='), 'Welcome URL should contain set-password path');
        System.assert(urls[0].startsWith('https://members.cruzy.com/'), 'URL should start with base URL');

        Contact updated = [SELECT Portal_Reset_Token__c, Portal_Reset_Expiry__c, Portal_Status__c, Cruzy_Plus_Enrolled__c
                           FROM Contact WHERE Id = :c.Id];
        System.assertNotEquals(null, updated.Portal_Reset_Token__c, 'Token should be stamped on Contact');
        System.assertNotEquals(null, updated.Portal_Reset_Expiry__c, 'Expiry should be stamped on Contact');
        System.assertEquals('Pending', updated.Portal_Status__c, 'Welcome mode sets status to Pending');
        System.assertEquals(true, updated.Cruzy_Plus_Enrolled__c, 'Welcome mode sets Cruzy Plus Enrolled');
    }

    @isTest
    static void testGenerateToken_ResetMode() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'portal.tester@cruzytest.com' LIMIT 1];

        CruzyPortalHelper.TokenRequest req = new CruzyPortalHelper.TokenRequest();
        req.contactId = c.Id;
        req.mode      = 'reset';
        req.baseUrl   = 'https://members.cruzy.com';

        Test.startTest();
        List<String> urls = CruzyPortalHelper.generateToken(new List<CruzyPortalHelper.TokenRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, urls.size(), 'Should return one URL');
        System.assert(urls[0].contains('/reset-password?token='), 'Reset URL should contain reset-password path');

        Contact updated = [SELECT Portal_Reset_Token__c, Portal_Reset_Expiry__c
                           FROM Contact WHERE Id = :c.Id];
        System.assertNotEquals(null, updated.Portal_Reset_Token__c, 'Token should be stamped');
        System.assertNotEquals(null, updated.Portal_Reset_Expiry__c, 'Expiry should be stamped');
    }

    @isTest
    static void testGenerateToken_MultipleRequests() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'portal.tester@cruzytest.com' LIMIT 1];

        CruzyPortalHelper.TokenRequest req1 = new CruzyPortalHelper.TokenRequest();
        req1.contactId = c.Id;
        req1.mode      = 'welcome';
        req1.baseUrl   = 'https://members.cruzy.com';

        CruzyPortalHelper.TokenRequest req2 = new CruzyPortalHelper.TokenRequest();
        req2.contactId = c.Id;
        req2.mode      = 'reset';
        req2.baseUrl   = 'https://members.cruzy.com';

        Test.startTest();
        List<String> urls = CruzyPortalHelper.generateToken(
            new List<CruzyPortalHelper.TokenRequest>{ req1, req2 }
        );
        Test.stopTest();

        System.assertEquals(2, urls.size(), 'Should return two URLs');
        System.assert(urls[0].contains('/set-password?token='), 'First URL should be set-password');
        System.assert(urls[1].contains('/reset-password?token='), 'Second URL should be reset-password');
    }
}
