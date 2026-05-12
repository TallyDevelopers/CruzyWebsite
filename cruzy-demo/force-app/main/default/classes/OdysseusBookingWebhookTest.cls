@isTest
private class OdysseusBookingWebhookTest {

    private static final String SAMPLE_PAYLOAD = '{"Transaction":{"TimeStamp":"06-06-2024 13:01:21","Action":"RecordBooking","Booking":{"TransactionID":"102040","AgencyConfirmation":"C-USD-RQE856X","Customer":{"ID":"78966","Title":"MR","FirstName":"Monish","LastName":"Luthra","Email":"odysseus_test@example.com","DateOfBirth":"04-04-1988"},"Passengers":{"NoOfAdult":"2","Passenger":[{"ID":"78966","FirstName":"Monish","LastName":"Luthra","Email":"odysseus_test@example.com","Phone":"+11234567890","Prices":{"Type":"Cruise","Price":[{"ID":"17","Amount":"508.29","Name":{"#cdata-section":"Total"}},{"ID":"23","Amount":"508.29","Name":{"#cdata-section":"Total Due"}}]}}]},"Currency":{"ID":"USD"},"CreateDateTime":"2024-06-06T13:00:10","Packages":[{"Package":[{"Type":"Cruise","PackageID":"1412845","CruiseName":"4 Night Western Caribbean Cruise","ConfirmationNumber":"93317","DepartureDate":"02-01-2025 00:00:00","ArrivalDate":"06-01-2025 00:00:00","Duration":"4","Status":{"ID":"6","Name":"Held"},"DepartureCity":{"ID":"GLS","Name":"Galveston"},"Destination":{"ID":"14","Name":"Caribbean Western"},"CruiseLine":{"ID":"8","Name":"Royal Caribbean"},"Ship":{"ID":"79","Name":"Mariner of the Seas"},"Deck":{"Code":"11160","Name":"DECK TEN"},"Category":{"Code":"2V","Type":"1"},"Cabin":{"Code":"1605"},"FareCode":{"ID":"J1226105","RefundableType":"1"},"Prices":{"Type":"Cruise","Price":[{"ID":"17","Amount":"1069.58","Name":{"#cdata-section":"Total"}},{"ID":"63","Amount":"928.58","Code":"3","Name":{"#cdata-section":"Balance Due Check"}},{"ID":"6","Amount":"141.00","Code":"52","Name":{"#cdata-section":"Travel Insurance"}}]},"CustomerPaymentSchedules":{"PaymentSchedule":[{"ID":"494871","Amount":"250.00","DueDate":"10-06-2024","Type":"Deposit"},{"ID":"494872","Amount":"678.58","DueDate":"14-10-2024","Type":"Final"},{"ID":"494873","Amount":"141.00","DueDate":"10-06-2024","Type":"Insurance"}]}}]}]}}}';

    private static final String MODIFIED_PAYLOAD = '{"Transaction":{"TimeStamp":"07-06-2024 10:00:00","Action":"RecordBooking","Booking":{"TransactionID":"102040","AgencyConfirmation":"C-USD-RQE856X-MOD","Customer":{"ID":"78966","FirstName":"Monish","LastName":"Luthra","Email":"odysseus_test@example.com"},"Passengers":{"NoOfAdult":"3"},"Packages":[{"Package":[{"Type":"Cruise","PackageID":"1412845","CruiseName":"4 Night Western Caribbean Cruise","ConfirmationNumber":"93317","DepartureDate":"02-01-2025 00:00:00","Duration":"4","Status":{"ID":"7","Name":"Confirmed"},"DepartureCity":{"ID":"GLS","Name":"Galveston"},"Destination":{"ID":"14","Name":"Caribbean Western"},"CruiseLine":{"ID":"8","Name":"Royal Caribbean"},"Ship":{"ID":"79","Name":"Mariner of the Seas"},"Deck":{"Code":"11160","Name":"DECK TEN"},"Category":{"Code":"2V"},"Cabin":{"Code":"1605"},"FareCode":{"ID":"J1226105"},"Prices":{"Type":"Cruise","Price":[{"ID":"17","Amount":"1069.58","Name":{"#cdata-section":"Total"}},{"ID":"63","Amount":"500.00","Name":{"#cdata-section":"Balance Due Check"}}]},"CustomerPaymentSchedules":{"PaymentSchedule":[{"ID":"494871","Amount":"250.00","DueDate":"10-06-2024","Type":"Deposit"},{"ID":"494872","Amount":"678.58","DueDate":"14-10-2024","Type":"Final"}]}}]}]}}}';

    @isTest
    static void testFullBookingCreation() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/odysseus/booking';
        req.httpMethod = 'POST';
        req.headers.put('X-Webhook-Secret', System.Label.Odysseus_Webhook_Secret);
        req.requestBody = Blob.valueOf(SAMPLE_PAYLOAD);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OdysseusBookingWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Should return 200');
        String respBody = RestContext.response.responseBody.toString();
        System.assert(respBody.contains('"success":"true"'), 'Should succeed: ' + respBody);

        List<Booking__c> bookings = [
            SELECT Id, Odysseus_Transaction_ID__c, Odysseus_Confirmation__c, Name,
                   Ship__c, Cruise_Line__c, Cruise_Name__c, PAX_Count__c,
                   Cabin_Number__c, Deck__c, Status__c, Odysseus_Status__c,
                   Original_Cruise_Total__c, Current_Balance_Due__c, Departure_Date__c,
                   Duration_Nights__c, Contact__c
            FROM Booking__c
            WHERE Odysseus_Transaction_ID__c = '102040'
        ];
        System.assertEquals(1, bookings.size(), 'Should create exactly one booking');

        Booking__c bk = bookings[0];
        System.assertEquals('C-USD-RQE856X', bk.Odysseus_Confirmation__c);
        System.assertEquals('93317', bk.Name);
        System.assertEquals('Mariner of the Seas', bk.Ship__c);
        System.assertEquals('Royal Caribbean', bk.Cruise_Line__c);
        System.assertEquals('4 Night Western Caribbean Cruise', bk.Cruise_Name__c);
        System.assertEquals(2, bk.PAX_Count__c);
        System.assertEquals('1605', bk.Cabin_Number__c);
        System.assertEquals('DECK TEN', bk.Deck__c);
        System.assertEquals('Quote', bk.Status__c);
        System.assertEquals('Held', bk.Odysseus_Status__c);
        System.assertEquals(1069.58, bk.Original_Cruise_Total__c);
        System.assertEquals(928.58, bk.Current_Balance_Due__c);
        System.assertEquals(Date.newInstance(2025, 1, 2), bk.Departure_Date__c);
        System.assertEquals(4, bk.Duration_Nights__c);
        System.assertNotEquals(null, bk.Contact__c, 'Should link to a Contact');

        List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE Email = 'odysseus_test@example.com'];
        System.assertEquals(1, contacts.size(), 'Should create one Contact');

        List<Booking_Payment__c> payments = [
            SELECT Id, Odysseus_Payment_ID__c, Amount__c, Payment_Type__c, Source__c
            FROM Booking_Payment__c WHERE Booking__c = :bk.Id ORDER BY Payment_Type__c
        ];
        System.assertEquals(3, payments.size(), 'Should create 3 payment schedule records');

        List<Add_On__c> addOns = [
            SELECT Id, Name, Amount__c, Add_On_Type__c
            FROM Add_On__c WHERE Booking__c = :bk.Id
        ];
        System.assertEquals(1, addOns.size(), 'Should create Travel Insurance add-on');
        System.assertEquals('Travel Insurance', addOns[0].Add_On_Type__c);
        System.assertEquals(141.00, addOns[0].Amount__c);
    }

    @isTest
    static void testUpsertSameTransactionId() {
        RestRequest req1 = new RestRequest();
        req1.requestURI = '/services/apexrest/odysseus/booking';
        req1.httpMethod = 'POST';
        req1.headers.put('X-Webhook-Secret', System.Label.Odysseus_Webhook_Secret);
        req1.requestBody = Blob.valueOf(SAMPLE_PAYLOAD);
        RestContext.request = req1;
        RestContext.response = new RestResponse();

        Test.startTest();
        OdysseusBookingWebhook.handlePost();

        RestRequest req2 = new RestRequest();
        req2.requestURI = '/services/apexrest/odysseus/booking';
        req2.httpMethod = 'POST';
        req2.headers.put('X-Webhook-Secret', System.Label.Odysseus_Webhook_Secret);
        req2.requestBody = Blob.valueOf(MODIFIED_PAYLOAD);
        RestContext.request = req2;
        RestContext.response = new RestResponse();

        OdysseusBookingWebhook.handlePost();
        Test.stopTest();

        List<Booking__c> bookings = [
            SELECT Id, Odysseus_Confirmation__c, PAX_Count__c, Status__c, Current_Balance_Due__c
            FROM Booking__c WHERE Odysseus_Transaction_ID__c = '102040'
        ];
        System.assertEquals(1, bookings.size(), 'Upsert should not create a duplicate');
        System.assertEquals('C-USD-RQE856X-MOD', bookings[0].Odysseus_Confirmation__c, 'Should update confirmation');
        System.assertEquals(3, bookings[0].PAX_Count__c, 'PAX should be updated');
        System.assertEquals('Booking', bookings[0].Status__c, 'Status should map Confirmed -> Booking');
        System.assertEquals(500.00, bookings[0].Current_Balance_Due__c, 'Balance should be updated');
    }

    @isTest
    static void testUnauthorized() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/odysseus/booking';
        req.httpMethod = 'POST';
        req.headers.put('Authorization', 'Bearer WRONG_TOKEN');
        req.requestBody = Blob.valueOf(SAMPLE_PAYLOAD);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OdysseusBookingWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(401, RestContext.response.statusCode, 'Should reject bad token');
    }

    @isTest
    static void testMissingAuth() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/odysseus/booking';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(SAMPLE_PAYLOAD);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OdysseusBookingWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(401, RestContext.response.statusCode, 'Should reject missing auth');
    }

    @isTest
    static void testExistingPersonAccountMatched() {
        Id rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
        Account pa = new Account(
            RecordTypeId = rtId,
            FirstName = 'Pre-Existing',
            LastName = 'Contact',
            PersonEmail = 'odysseus_test@example.com'
        );
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        Database.insert(pa, dml);

        Account inserted = [SELECT PersonContactId FROM Account WHERE Id = :pa.Id];

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/odysseus/booking';
        req.httpMethod = 'POST';
        req.headers.put('X-Webhook-Secret', System.Label.Odysseus_Webhook_Secret);
        req.requestBody = Blob.valueOf(SAMPLE_PAYLOAD);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OdysseusBookingWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        List<Account> accounts = [SELECT Id, PersonContactId FROM Account WHERE PersonEmail = 'odysseus_test@example.com' AND IsPersonAccount = true];
        System.assertEquals(1, accounts.size(), 'Should not create a duplicate Person Account');
        System.assertEquals(pa.Id, accounts[0].Id, 'Should match existing Person Account');

        Booking__c bk = [SELECT Contact__c FROM Booking__c WHERE Odysseus_Transaction_ID__c = '102040'];
        System.assertEquals(inserted.PersonContactId, bk.Contact__c, 'Booking should link to existing Person Account Contact');
    }

    @isTest
    static void testParserCdata() {
        System.assertEquals('Miami', OdysseusJsonParser.resolveCdata(new Map<String, Object>{ '#cdata-section' => 'Miami' }));
        System.assertEquals('plain', OdysseusJsonParser.resolveCdata('plain'));
        System.assertEquals(null, OdysseusJsonParser.resolveCdata(null));
    }

    @isTest
    static void testParserDates() {
        System.assertEquals(Date.newInstance(2025, 1, 2), OdysseusJsonParser.parseDate('02-01-2025 00:00:00'));
        System.assertEquals(Date.newInstance(2024, 6, 6), OdysseusJsonParser.parseDate('2024-06-06T13:00:10'));
        System.assertEquals(Date.newInstance(2024, 6, 13), OdysseusJsonParser.parseDate('13-06-2024'));
        System.assertEquals(null, OdysseusJsonParser.parseDate(null));
        System.assertEquals(null, OdysseusJsonParser.parseDate(''));
        System.assertEquals(null, OdysseusJsonParser.parseDate('01-01-0001'));
    }

    @isTest
    static void testParserToList() {
        List<Object> fromList = OdysseusJsonParser.toList(new List<Object>{ 'a', 'b' });
        System.assertEquals(2, fromList.size());

        List<Object> fromSingle = OdysseusJsonParser.toList('single');
        System.assertEquals(1, fromSingle.size());

        List<Object> fromNull = OdysseusJsonParser.toList(null);
        System.assertEquals(0, fromNull.size());
    }

    @isTest
    static void testStatusMapping() {
        System.assertEquals('Booking', OdysseusJsonParser.mapBookingStatus('Confirmed'));
        System.assertEquals('Quote', OdysseusJsonParser.mapBookingStatus('Held'));
        System.assertEquals('Quote', OdysseusJsonParser.mapBookingStatus('Pending Confirmation'));
        System.assertEquals('Cancelled', OdysseusJsonParser.mapBookingStatus('Cancelled'));
        System.assertEquals('Quote', OdysseusJsonParser.mapBookingStatus(null));
    }
}
