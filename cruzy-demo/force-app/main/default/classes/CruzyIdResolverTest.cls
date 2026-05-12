@isTest
private class CruzyIdResolverTest {

    @TestSetup
    static void setup() {
        Id rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
        Account pa = new Account(
            FirstName = 'Test',
            LastName = 'Resolver',
            PersonEmail = 'resolver@test.cruzy.com',
            RecordTypeId = rtId
        );
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        Database.insert(pa, dml);
    }

    @isTest
    static void testResolveWithContactId() {
        Account pa = [SELECT PersonContactId FROM Account WHERE PersonEmail = 'resolver@test.cruzy.com' LIMIT 1];
        Id contactId = pa.PersonContactId;

        Test.startTest();
        Id result = CruzyIdResolver.resolveContactId(contactId);
        Test.stopTest();

        System.assertEquals(contactId, result, 'Passing a Contact ID should return it unchanged');
    }

    @isTest
    static void testResolveWithAccountId() {
        Account pa = [SELECT Id, PersonContactId FROM Account WHERE PersonEmail = 'resolver@test.cruzy.com' LIMIT 1];

        Test.startTest();
        Id result = CruzyIdResolver.resolveContactId(pa.Id);
        Test.stopTest();

        System.assertEquals(pa.PersonContactId, result, 'Passing an Account ID should return the PersonContactId');
    }

    @isTest
    static void testResolveNullReturnsNull() {
        Test.startTest();
        Id result = CruzyIdResolver.resolveContactId(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Null ID should return null');
    }
}
