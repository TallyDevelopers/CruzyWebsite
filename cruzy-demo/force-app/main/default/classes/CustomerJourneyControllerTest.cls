@isTest
private class CustomerJourneyControllerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Cruzy Journey Household', RecordTypeId = '012al000005f9VtAAI');
        insert acc;

        Contact c = new Contact(
            FirstName = 'Journey',
            LastName  = 'Traveler',
            Email     = 'journey@cruzytest.com',
            Phone     = '5551112222',
            AccountId = acc.Id,
            Spanish_Speaking__c      = true,
            VIFP_Level__c            = 'Platinum',
            VIFP_Number__c           = 'VIP999',
            VIFP_Belongs_To__c       = 'Primary',
            VIFP_Number_Secondary__c = 'VIP888',
            VIFP_Level_Secondary__c  = 'Gold',
            VIFP_Secondary_Belongs_To__c = 'Spouse',
            Cruzy_Plus_Enrolled__c   = true,
            Cruzy_Plus_MBR_Number__c = 'CRZ-JRN01',
            Cruzy_Plus_Pitched__c    = true,
            Customer_Source__c       = 'Website',
            Customer_Notes__c        = 'VIP client',
            Account_Alert__c         = 'Special handling required',
            BOLO__c                  = true,
            Membership_On_Hold__c    = false,
            Alt_Phone__c             = '5553334444',
            Alt_Email__c             = 'alt.journey@cruzytest.com',
            Timezone__c              = 'Pacific',
            Spouse_Significant_Other__c = 'Jane Traveler',
            Primary_DOB__c           = Date.newInstance(1980, 6, 15),
            Secondary_DOB__c         = Date.newInstance(1982, 3, 20)
        );
        insert c;

        Membership__c mbr = new Membership__c(
            Contact__c         = c.Id,
            Name               = 'CRZ-JRN01',
            Status__c          = 'Active',
            Partner__c         = 'Cruzy+',
            Enroll_Date__c     = Date.today().addYears(-1),
            Expiration_Date__c = Date.today().addMonths(6),
            Next_Billing_Date__c = Date.today().addMonths(6),
            Auto_Renewal__c    = true,
            Biennial__c        = false,
            Paid_Through__c    = Date.today().addMonths(6),
            Last_Renewal_Date__c = Date.today().addMonths(-6)
        );
        insert mbr;

        Membership_Payment__c mPmt = new Membership_Payment__c(
            Membership__c = mbr.Id,
            Amount_Paid__c = 299.00,
            Date_Paid__c   = Date.today().addMonths(-6),
            Renewal_Year__c = Date.today().year()
        );
        insert mPmt;

        Reward__c rwd = new Reward__c(
            Contact__c       = c.Id,
            Status__c        = 'Active',
            Partner__c       = 'Carnival',
            Reward_Number__c = 'RWD-001',
            Reward_Location__c = 'Miami',
            Issue_Date__c    = Date.today().addMonths(-3),
            Book_By_Date__c  = Date.today().addMonths(3),
            Expiration_Date__c = Date.today().addMonths(6)
        );
        insert rwd;

        Booking__c bk = new Booking__c(
            Contact__c              = c.Id,
            Status__c               = 'Confirmed',
            Ship__c                 = 'Cruzy Horizon',
            Itinerary__c            = '7-Day Caribbean',
            Departure_Date__c       = Date.today().addMonths(2),
            Departure_Port__c       = 'Miami',
            Cabin_Category__c       = 'Balcony',
            PAX_Count__c            = 2,
            Quote_Type__c           = 'Firm',
            Original_Cruise_Total__c = 3500.00,
            Current_Balance_Due__c  = 1500.00,
            Payment_Date__c         = Date.today().addMonths(1),
            Reward__c               = rwd.Id
        );
        insert bk;

        Add_On__c addon = new Add_On__c(
            Booking__c     = bk.Id,
            Add_On_Type__c = 'Excursion',
            Amount__c      = 150.00
        );
        insert addon;

        Booking_Payment__c bPmt = new Booking_Payment__c(
            Booking__c      = bk.Id,
            Amount__c       = 2000.00,
            Payment_Date__c = Date.today().addMonths(-1),
            Note__c         = 'Initial deposit'
        );
        insert bPmt;

        Contact emptyContact = new Contact(
            FirstName = 'Empty',
            LastName  = 'Journey',
            Email     = 'empty.journey@cruzytest.com',
            AccountId = acc.Id
        );
        insert emptyContact;
    }

    @isTest
    static void testGetCustomerIntelligence_WithData() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'journey@cruzytest.com' LIMIT 1];

        Test.startTest();
        CustomerJourneyController.CustomerIntelligence intel =
            CustomerJourneyController.getCustomerIntelligence(c.Id);
        Test.stopTest();

        System.assertEquals(true, intel.spanishSpeaking, 'Should be Spanish speaking');
        System.assertEquals('Platinum', intel.vifpLevel, 'VIFP level should be Platinum');
        System.assertEquals(true, intel.cruzyPlusEnrolled, 'Should be Cruzy+ enrolled');
        System.assertEquals('Website', intel.customerSource, 'Customer source should match');
        System.assertEquals(true, intel.hasAccountAlert, 'Should have account alert');
        System.assertEquals(true, intel.isBolo, 'Should be BOLO');
        System.assertEquals(true, intel.hasMembership, 'Should have membership');
        System.assertEquals('Active', intel.membershipStatus, 'Membership should be Active');
        System.assertEquals(true, intel.membershipAutoRenew, 'Auto-renew should be true');
        System.assertEquals(1, intel.bookingCount, 'Should have 1 booking');
        System.assert(intel.totalCruiseValue > 0, 'Total cruise value should be > 0');
        System.assert(intel.totalSpend > 0, 'Total spend should be > 0');
        System.assertEquals(1, intel.addOnCount, 'Should have 1 add-on');
        System.assert(intel.addOnSpend > 0, 'Add-on spend should be > 0');
        System.assertEquals(1, intel.rewardCount, 'Should have 1 reward');
    }

    @isTest
    static void testGetCustomerIntelligence_NoData() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'empty.journey@cruzytest.com' LIMIT 1];

        Test.startTest();
        CustomerJourneyController.CustomerIntelligence intel =
            CustomerJourneyController.getCustomerIntelligence(c.Id);
        Test.stopTest();

        System.assertEquals(false, intel.hasMembership, 'Should not have membership');
        System.assertEquals(0, intel.bookingCount, 'Should have 0 bookings');
        System.assertEquals(0, intel.totalSpend, 'Total spend should be 0');
        System.assertEquals(0, intel.rewardCount, 'Reward count should be 0');
    }

    @isTest
    static void testGetContactJourney_WithFullData() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'journey@cruzytest.com' LIMIT 1];

        Test.startTest();
        CustomerJourneyController.ContactJourney journey =
            CustomerJourneyController.getContactJourney(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, journey, 'Journey should not be null');
        System.assertEquals(c.Id, journey.contactId, 'Contact ID should match');
        System.assertEquals('journey@cruzytest.com', journey.email, 'Email should match');
        System.assertEquals('Pacific', journey.timezone, 'Timezone should match');
        System.assertEquals(true, journey.cruzyPlusEnrolled, 'Cruzy+ enrolled should be true');
        System.assertNotEquals(null, journey.membership, 'Membership should be populated');
        System.assertEquals('Active', journey.membership.status, 'Membership status should be Active');
        System.assertEquals(true, journey.membership.autoRenewal, 'Auto renewal should be true');
        System.assert(!journey.rewards.isEmpty(), 'Should have rewards');
        System.assert(!journey.bookings.isEmpty(), 'Should have bookings');

        CustomerJourneyController.BookingWrapper bw = journey.bookings[0];
        System.assertNotEquals(null, bw.reward, 'Booking reward wrapper should be populated');
        System.assert(!bw.addOns.isEmpty(), 'Booking should have add-ons');
        System.assert(!bw.payments.isEmpty(), 'Booking should have payments');
    }

    @isTest
    static void testGetContactJourney_NoData() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'empty.journey@cruzytest.com' LIMIT 1];

        Test.startTest();
        CustomerJourneyController.ContactJourney journey =
            CustomerJourneyController.getContactJourney(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, journey, 'Journey should not be null even with no child records');
        System.assertEquals(null, journey.membership, 'Membership should be null');
        System.assert(journey.rewards.isEmpty(), 'Rewards should be empty');
        System.assert(journey.bookings.isEmpty(), 'Bookings should be empty');
    }

    @isTest
    static void testGetAccountJourney() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Cruzy Journey Household' LIMIT 1];

        Test.startTest();
        List<CustomerJourneyController.ContactJourney> journeys =
            CustomerJourneyController.getAccountJourney(acc.Id);
        Test.stopTest();

        System.assert(journeys.size() >= 2, 'Should return journeys for all contacts on the account');
    }

    @isTest
    static void testGetAccountJourney_EmptyAccount() {
        Account emptyAcc = new Account(Name = 'Empty Account', RecordTypeId = '012al000005f9VtAAI');
        insert emptyAcc;

        Test.startTest();
        List<CustomerJourneyController.ContactJourney> journeys =
            CustomerJourneyController.getAccountJourney(emptyAcc.Id);
        Test.stopTest();

        System.assert(journeys.isEmpty(), 'Should return empty list for account with no contacts');
    }

    @isTest
    static void testGetCustomerIntelligence_InvalidContact() {
        Test.startTest();
        CustomerJourneyController.CustomerIntelligence intel =
            CustomerJourneyController.getCustomerIntelligence(
                [SELECT Id FROM Contact WHERE Email = 'empty.journey@cruzytest.com' LIMIT 1].Id
            );
        Test.stopTest();

        System.assertNotEquals(null, intel, 'Should return default intelligence object');
    }
}
