@isTest
private class AuthnetPaymentControllerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Cruzy Authorize.net Test', RecordTypeId = '012al000005f9VtAAI');
        insert acc;

        Contact c = new Contact(
            FirstName = 'Authnet',
            LastName  = 'Payer',
            Email     = 'authnet.payer@cruzytest.com',
            AccountId = acc.Id,
            Authnet_Customer_Profile_ID__c = '100200300'
        );
        insert c;

        Membership__c mbr = new Membership__c(
            Contact__c         = c.Id,
            Name               = 'CRZ-PAY01',
            Status__c          = 'Active',
            Partner__c         = 'Cruzy+',
            Enroll_Date__c     = Date.today().addYears(-1),
            Expiration_Date__c = Date.today().addMonths(6),
            Next_Billing_Date__c = Date.today().addMonths(6),
            Auto_Renewal__c    = true,
            Last_Renewal_Date__c = Date.today().addMonths(-6)
        );
        insert mbr;

        Membership_Payment__c mPmt = new Membership_Payment__c(
            Membership__c = mbr.Id,
            Amount_Paid__c = 199.00,
            Date_Paid__c   = Date.today().addMonths(-6),
            Renewal_Year__c = Date.today().year()
        );
        insert mPmt;

        Booking__c bk = new Booking__c(
            Contact__c              = c.Id,
            Status__c               = 'Confirmed',
            Ship__c                 = 'Cruzy Explorer',
            Departure_Date__c       = Date.today().addMonths(3),
            Original_Cruise_Total__c = 5000.00,
            Current_Balance_Due__c  = 3000.00
        );
        insert bk;

        Booking_Payment__c bPmt = new Booking_Payment__c(
            Booking__c      = bk.Id,
            Amount__c       = 2000.00,
            Payment_Date__c = Date.today().addDays(-14),
            Note__c         = 'Deposit payment'
        );
        insert bPmt;

        Saved_Card__c card = new Saved_Card__c(
            Contact__c       = c.Id,
            Card_Brand__c    = 'Visa',
            Last_Four__c     = '4242',
            Expiry_Month__c  = 12,
            Expiry_Year__c   = Date.today().year() + 2,
            Cardholder_Name__c = 'Authnet Payer',
            Is_Default__c    = true,
            Authnet_Payment_Profile_Id__c = '200300400'
        );
        insert card;

        Saved_Card__c card2 = new Saved_Card__c(
            Contact__c       = c.Id,
            Card_Brand__c    = 'Mastercard',
            Last_Four__c     = '5555',
            Expiry_Month__c  = 6,
            Expiry_Year__c   = Date.today().year() + 1,
            Cardholder_Name__c = 'Authnet Payer',
            Is_Default__c    = false,
            Authnet_Payment_Profile_Id__c = '200300401'
        );
        insert card2;
    }

    // ─── getContactBookings ────────────────────────────────────────────────────

    @isTest
    static void testGetContactBookings() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];

        Test.startTest();
        List<Booking__c> bookings = AuthnetPaymentController.getContactBookings(c.Id);
        Test.stopTest();

        System.assertEquals(1, bookings.size(), 'Should return 1 booking');
        System.assertEquals('Cruzy Explorer', bookings[0].Ship__c, 'Ship name should match');
    }

    // ─── getSavedCards ─────────────────────────────────────────────────────────

    @isTest
    static void testGetSavedCards() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];

        Test.startTest();
        List<Saved_Card__c> cards = AuthnetPaymentController.getSavedCards(c.Id);
        Test.stopTest();

        System.assertEquals(2, cards.size(), 'Should return 2 saved cards');
        System.assertEquals(true, cards[0].Is_Default__c, 'First card should be the default (sorted DESC)');
    }

    // ─── getBillingHubData ─────────────────────────────────────────────────────

    @isTest
    static void testGetBillingHubData() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];

        Test.startTest();
        AuthnetPaymentController.BillingHubData hub = AuthnetPaymentController.getBillingHubData(c.Id);
        Test.stopTest();

        System.assertEquals(2, hub.cards.size(), 'Should have 2 cards');
        System.assertEquals(1, hub.memberships.size(), 'Should have 1 membership');
        System.assertEquals(1, hub.recentPayments.size(), 'Should have 1 booking payment');
        System.assertEquals(1, hub.membershipPayments.size(), 'Should have 1 membership payment');
        System.assert(hub.lifetimeSpend > 0, 'Lifetime spend should be > 0');
        System.assertEquals(2199.00, hub.lifetimeSpend, 'Lifetime spend = 2000 + 199');
    }

    // ─── saveCard (with existing customer profile — adds payment profile) ─────

    @isTest
    static void testSaveCard_AsDefault() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        Saved_Card__c newCard = AuthnetPaymentController.saveCard(
            c.Id, 'Amex', '3782', 9, Date.today().year() + 3, 'Test Holder', true,
            '378282246310005', '1234'
        );
        Test.stopTest();

        System.assertNotEquals(null, newCard.Id, 'New card should be inserted');
        System.assertEquals(true, newCard.Is_Default__c, 'New card should be default');
        System.assertEquals('200300401', newCard.Authnet_Payment_Profile_Id__c,
            'Should have real Authorize.net payment profile ID from mock');

        List<Saved_Card__c> oldDefaults = [
            SELECT Id FROM Saved_Card__c
            WHERE Contact__c = :c.Id AND Is_Default__c = true AND Id != :newCard.Id
        ];
        System.assertEquals(0, oldDefaults.size(), 'Previous defaults should be cleared');
    }

    @isTest
    static void testSaveCard_NotDefault() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        Saved_Card__c newCard = AuthnetPaymentController.saveCard(
            c.Id, 'Discover', '6011', 3, Date.today().year() + 2, 'Another Holder', false,
            '6011111111111117', '123'
        );
        Test.stopTest();

        System.assertNotEquals(null, newCard.Id, 'New card should be inserted');
        System.assertEquals(false, newCard.Is_Default__c, 'Card should not be default');
    }

    @isTest
    static void testSaveCard_FirstCardAutoDefault_NewProfile() {
        Account acc = new Account(Name = 'New Authorize.net Acc', RecordTypeId = '012al000005f9VtAAI');
        insert acc;
        Contact fresh = new Contact(
            FirstName = 'Fresh',
            LastName  = 'Cardholder',
            Email     = 'fresh@cruzytest.com',
            AccountId = acc.Id
        );
        insert fresh;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        Saved_Card__c firstCard = AuthnetPaymentController.saveCard(
            fresh.Id, 'Visa', '1111', 1, Date.today().year() + 1, 'Fresh Holder', false,
            '4111111111111111', '123'
        );
        Test.stopTest();

        System.assertEquals(true, firstCard.Is_Default__c, 'First card should auto-default even when makeDefault=false');
        System.assertEquals('200300400', firstCard.Authnet_Payment_Profile_Id__c,
            'Should have profile ID from createCustomerProfile mock');

        Contact updatedCon = [SELECT Authnet_Customer_Profile_ID__c FROM Contact WHERE Id = :fresh.Id];
        System.assertEquals('100200300', updatedCon.Authnet_Customer_Profile_ID__c,
            'Contact should have the new customer profile ID');
    }

    // ─── deleteCard ────────────────────────────────────────────────────────────

    @isTest
    static void testDeleteCard_NonDefault() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];
        Saved_Card__c nonDefault = [
            SELECT Id FROM Saved_Card__c
            WHERE Contact__c = :c.Id AND Is_Default__c = false LIMIT 1
        ];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        AuthnetPaymentController.deleteCard(nonDefault.Id);
        Test.stopTest();

        List<Saved_Card__c> remaining = [SELECT Id FROM Saved_Card__c WHERE Id = :nonDefault.Id];
        System.assert(remaining.isEmpty(), 'Card should be deleted');
    }

    @isTest
    static void testDeleteCard_DefaultPromotesNext() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];
        Saved_Card__c defaultCard = [
            SELECT Id FROM Saved_Card__c
            WHERE Contact__c = :c.Id AND Is_Default__c = true LIMIT 1
        ];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        AuthnetPaymentController.deleteCard(defaultCard.Id);
        Test.stopTest();

        List<Saved_Card__c> remaining = [
            SELECT Id, Is_Default__c FROM Saved_Card__c WHERE Contact__c = :c.Id
        ];
        System.assertEquals(1, remaining.size(), 'One card should remain');
        System.assertEquals(true, remaining[0].Is_Default__c, 'Remaining card should be promoted to default');
    }

    // ─── setDefaultCard ────────────────────────────────────────────────────────

    @isTest
    static void testSetDefaultCard() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];
        Saved_Card__c nonDefault = [
            SELECT Id FROM Saved_Card__c
            WHERE Contact__c = :c.Id AND Is_Default__c = false LIMIT 1
        ];

        Test.startTest();
        AuthnetPaymentController.setDefaultCard(nonDefault.Id, c.Id);
        Test.stopTest();

        Saved_Card__c updated = [SELECT Is_Default__c FROM Saved_Card__c WHERE Id = :nonDefault.Id];
        System.assertEquals(true, updated.Is_Default__c, 'Card should now be default');

        List<Saved_Card__c> others = [
            SELECT Id FROM Saved_Card__c
            WHERE Contact__c = :c.Id AND Is_Default__c = true AND Id != :nonDefault.Id
        ];
        System.assertEquals(0, others.size(), 'All other cards should lose default status');
    }

    // ─── chargeCard ────────────────────────────────────────────────────────────

    @isTest
    static void testChargeCard_Success() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];
        Saved_Card__c card = [SELECT Id FROM Saved_Card__c WHERE Contact__c = :c.Id AND Is_Default__c = true LIMIT 1];
        Booking__c bk = [SELECT Id, Current_Balance_Due__c FROM Booking__c WHERE Contact__c = :c.Id LIMIT 1];

        Decimal chargeAmount = 500.00;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        AuthnetPaymentController.ChargeResult result =
            AuthnetPaymentController.chargeCard(bk.Id, card.Id, chargeAmount, 'Test charge');
        Test.stopTest();

        System.assertEquals(true, result.success, 'Charge should succeed');
        System.assertEquals(chargeAmount, result.amountCharged, 'Amount charged should match');
        System.assertEquals(2500.00, result.newBalanceDue, 'Balance should be 3000 - 500 = 2500');
        System.assertEquals('60123456789', result.transactionId, 'Transaction ID should match mock');
        System.assertEquals('ABC123', result.chargeId, 'Auth code should match mock');
        System.assertNotEquals(null, result.paymentId, 'Payment record should be created');
        System.assertEquals('Visa •••• 4242', result.cardDisplay, 'Card display should match');

        Booking_Payment__c pmt = [
            SELECT Authnet_Transaction_ID__c FROM Booking_Payment__c WHERE Id = :result.paymentId
        ];
        System.assertEquals('60123456789', pmt.Authnet_Transaction_ID__c,
            'Payment record should store real transaction ID');
    }

    @isTest
    static void testChargeCard_WithNote() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];
        Saved_Card__c card = [SELECT Id FROM Saved_Card__c WHERE Contact__c = :c.Id AND Is_Default__c = true LIMIT 1];
        Booking__c bk = [SELECT Id FROM Booking__c WHERE Contact__c = :c.Id LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        AuthnetPaymentController.ChargeResult result =
            AuthnetPaymentController.chargeCard(bk.Id, card.Id, 100.00, 'Custom payment note');
        Test.stopTest();

        Booking_Payment__c pmt = [SELECT Note__c FROM Booking_Payment__c WHERE Id = :result.paymentId];
        System.assertEquals('Custom payment note', pmt.Note__c, 'Custom note should be stored');
    }

    @isTest
    static void testChargeCard_BlankNote_UsesDefault() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];
        Saved_Card__c card = [SELECT Id FROM Saved_Card__c WHERE Contact__c = :c.Id AND Is_Default__c = true LIMIT 1];
        Booking__c bk = [SELECT Id FROM Booking__c WHERE Contact__c = :c.Id LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        AuthnetPaymentController.ChargeResult result =
            AuthnetPaymentController.chargeCard(bk.Id, card.Id, 100.00, '');
        Test.stopTest();

        Booking_Payment__c pmt = [SELECT Note__c FROM Booking_Payment__c WHERE Id = :result.paymentId];
        System.assert(pmt.Note__c.contains('Visa'), 'Default note should contain card brand');
        System.assert(pmt.Note__c.contains('4242'), 'Default note should contain last four');
        System.assert(pmt.Note__c.contains('Authorize.net'), 'Default note should contain Authorize.net reference');
    }

    @isTest
    static void testChargeCard_AmountExceedsBalance() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];
        Saved_Card__c card = [SELECT Id FROM Saved_Card__c WHERE Contact__c = :c.Id AND Is_Default__c = true LIMIT 1];
        Booking__c bk = [SELECT Id FROM Booking__c WHERE Contact__c = :c.Id LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        Boolean didThrow = false;
        try {
            AuthnetPaymentController.chargeCard(bk.Id, card.Id, 99999.00, 'Over limit');
        } catch (Exception e) {
            didThrow = true;
        }
        Test.stopTest();
        System.assert(didThrow, 'Should have thrown an exception for amount exceeding balance');
    }

    @isTest
    static void testChargeCard_ZeroAmount() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];
        Saved_Card__c card = [SELECT Id FROM Saved_Card__c WHERE Contact__c = :c.Id AND Is_Default__c = true LIMIT 1];
        Booking__c bk = [SELECT Id FROM Booking__c WHERE Contact__c = :c.Id LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        Boolean didThrow = false;
        try {
            AuthnetPaymentController.chargeCard(bk.Id, card.Id, 0, 'Zero charge');
        } catch (Exception e) {
            didThrow = true;
        }
        Test.stopTest();
        System.assert(didThrow, 'Should have thrown an exception for zero amount');
    }

    @isTest
    static void testChargeCard_NegativeAmount() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];
        Saved_Card__c card = [SELECT Id FROM Saved_Card__c WHERE Contact__c = :c.Id AND Is_Default__c = true LIMIT 1];
        Booking__c bk = [SELECT Id FROM Booking__c WHERE Contact__c = :c.Id LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        Boolean didThrow = false;
        try {
            AuthnetPaymentController.chargeCard(bk.Id, card.Id, -50.00, 'Negative');
        } catch (Exception e) {
            didThrow = true;
        }
        Test.stopTest();
        System.assert(didThrow, 'Should have thrown an exception for negative amount');
    }

    @isTest
    static void testChargeCard_ExactBalance() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'authnet.payer@cruzytest.com' LIMIT 1];
        Saved_Card__c card = [SELECT Id FROM Saved_Card__c WHERE Contact__c = :c.Id AND Is_Default__c = true LIMIT 1];
        Booking__c bk = [SELECT Id, Current_Balance_Due__c FROM Booking__c WHERE Contact__c = :c.Id LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        AuthnetPaymentController.ChargeResult result =
            AuthnetPaymentController.chargeCard(bk.Id, card.Id, bk.Current_Balance_Due__c, 'Pay in full');
        Test.stopTest();

        System.assertEquals(true, result.success, 'Charge should succeed for exact balance');
        System.assertEquals(0.00, result.newBalanceDue, 'Balance should be zero after full payment');
    }

    // ─── AuthnetService direct tests ───────────────────────────────────────────

    @isTest
    static void testAuthnetService_ChargeDeclined() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock('charge_declined'));
        Boolean didThrow = false;
        try {
            AuthnetService.chargeCustomerProfile('100200300', '200300400', 50.00, 'Test');
        } catch (AuthnetService.AuthnetException e) {
            didThrow = true;
            System.assert(e.getMessage().contains('declined'), 'Should mention declined');
        }
        Test.stopTest();
        System.assert(didThrow, 'Should throw on declined transaction');
    }

    @isTest
    static void testAuthnetService_CreateProfileError() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock('profile_error'));
        Boolean didThrow = false;
        try {
            AuthnetService.createCustomerProfile(
                'test@test.com', 'Test', 'User',
                '4111111111111111', '2028-01', '123'
            );
        } catch (AuthnetService.AuthnetException e) {
            didThrow = true;
            System.assert(e.getMessage().contains('duplicate'), 'Should mention duplicate');
        }
        Test.stopTest();
        System.assert(didThrow, 'Should throw on profile creation error');
    }

    @isTest
    static void testAuthnetService_DeletePaymentProfile() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthnetCalloutMock());
        AuthnetService.deletePaymentProfile('100200300', '200300400');
        Test.stopTest();
    }
}
