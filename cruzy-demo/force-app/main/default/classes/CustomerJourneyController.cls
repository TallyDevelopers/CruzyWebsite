public with sharing class CustomerJourneyController {

    // ─── Customer Intelligence Banner ────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static CustomerIntelligence getCustomerIntelligence(Id contactId) {
        Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
        CustomerIntelligence intel = new CustomerIntelligence();
        if (resolvedId == null) return intel;

        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Spanish_Speaking__c,
                   VIFP_Level__c, VIFP_Number__c,
                   Cruzy_Plus_Enrolled__c, Customer_Source__c,
                   Membership_On_Hold__c, Account_Alert__c, BOLO__c
            FROM Contact WHERE Id = :resolvedId LIMIT 1
        ];
        if (contacts.isEmpty()) return intel;
        Contact c = contacts[0];
        intel.spanishSpeaking   = c.Spanish_Speaking__c;
        intel.vifpLevel         = c.VIFP_Level__c;
        intel.cruzyPlusEnrolled = c.Cruzy_Plus_Enrolled__c;
        intel.customerSource    = c.Customer_Source__c;
        intel.hasAccountAlert   = String.isNotBlank(c.Account_Alert__c);
        intel.accountAlertText  = c.Account_Alert__c;
        intel.isBolo            = c.BOLO__c;
        intel.membershipOnHold  = c.Membership_On_Hold__c;

        // Membership
        List<Membership__c> mbrs = [
            SELECT Id, Status__c, Auto_Renewal__c, Expiration_Date__c,
                   Next_Billing_Date__c, Partner__c
            FROM Membership__c
            WHERE Contact__c = :resolvedId
            ORDER BY Enroll_Date__c DESC LIMIT 1
        ];
        if (!mbrs.isEmpty()) {
            intel.hasMembership     = true;
            intel.membershipStatus  = mbrs[0].Status__c;
            intel.membershipAutoRenew = mbrs[0].Auto_Renewal__c;
            intel.membershipExpDate = mbrs[0].Expiration_Date__c;
        }

        // Bookings aggregate
        AggregateResult[] bookAgg = [
            SELECT COUNT(Id) cnt,
                   SUM(Original_Cruise_Total__c) totalCruise,
                   SUM(Current_Balance_Due__c) totalBalance
            FROM Booking__c
            WHERE Contact__c = :resolvedId
        ];
        intel.bookingCount    = (Integer)(bookAgg[0].get('cnt') != null ? bookAgg[0].get('cnt') : 0);
        intel.totalCruiseValue= (Decimal)(bookAgg[0].get('totalCruise') != null ? bookAgg[0].get('totalCruise') : 0);
        intel.totalBalanceDue = (Decimal)(bookAgg[0].get('totalBalance') != null ? bookAgg[0].get('totalBalance') : 0);

        // Payments total (actual collected)
        AggregateResult[] pmtAgg = [
            SELECT SUM(Amount__c) paid
            FROM Booking_Payment__c
            WHERE Booking__r.Contact__c = :resolvedId
        ];
        Decimal bpPaid = (pmtAgg[0].get('paid') != null) ? (Decimal)pmtAgg[0].get('paid') : 0;

        AggregateResult[] mpmtAgg = [
            SELECT SUM(Amount_Paid__c) paid
            FROM Membership_Payment__c
            WHERE Membership__r.Contact__c = :resolvedId
        ];
        Decimal mpPaid = (mpmtAgg[0].get('paid') != null) ? (Decimal)mpmtAgg[0].get('paid') : 0;
        intel.totalSpend = bpPaid + mpPaid;

        // Add-ons count
        AggregateResult[] addonAgg = [
            SELECT COUNT(Id) cnt, SUM(Amount__c) total
            FROM Add_On__c
            WHERE Booking__r.Contact__c = :resolvedId
        ];
        intel.addOnCount      = (Integer)(addonAgg[0].get('cnt')   != null ? addonAgg[0].get('cnt')   : 0);
        intel.addOnSpend      = (Decimal)(addonAgg[0].get('total') != null ? addonAgg[0].get('total') : 0);

        // Rewards
        AggregateResult[] rwAgg = [
            SELECT COUNT(Id) cnt
            FROM Reward__c WHERE Contact__c = :resolvedId
        ];
        intel.rewardCount = (Integer)(rwAgg[0].get('cnt') != null ? rwAgg[0].get('cnt') : 0);

        return intel;
    }

    public class CustomerIntelligence {
        @AuraEnabled public Boolean spanishSpeaking    = false;
        @AuraEnabled public Boolean cruzyPlusEnrolled  = false;
        @AuraEnabled public Boolean hasMembership      = false;
        @AuraEnabled public Boolean membershipAutoRenew= false;
        @AuraEnabled public Boolean hasAccountAlert    = false;
        @AuraEnabled public String  accountAlertText;
        @AuraEnabled public Boolean isBolo             = false;
        @AuraEnabled public Boolean membershipOnHold   = false;
        @AuraEnabled public String  membershipStatus;
        @AuraEnabled public Date    membershipExpDate;
        @AuraEnabled public String  vifpLevel;
        @AuraEnabled public String  customerSource;
        @AuraEnabled public Integer bookingCount       = 0;
        @AuraEnabled public Integer rewardCount        = 0;
        @AuraEnabled public Integer addOnCount         = 0;
        @AuraEnabled public Decimal totalCruiseValue   = 0;
        @AuraEnabled public Decimal totalBalanceDue    = 0;
        @AuraEnabled public Decimal totalSpend         = 0;
        @AuraEnabled public Decimal addOnSpend         = 0;
    }

    // ─── Single Contact Journey (Contact record page) ─────────────────────────

    @AuraEnabled(cacheable=true)
    public static ContactJourney getContactJourney(Id contactId) {
        Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
        if (resolvedId == null) return null;
        List<Contact> contacts = [
            SELECT Id, Name, FirstName, LastName,
                   Phone, Email, Alt_Phone__c, Alt_Email__c,
                   Timezone__c, Customer_Source__c, Customer_Notes__c,
                   VIFP_Number__c, VIFP_Level__c, VIFP_Belongs_To__c,
                   VIFP_Number_Secondary__c, VIFP_Level_Secondary__c,
                   VIFP_Secondary_Belongs_To__c,
                   Cruzy_Plus_Enrolled__c, Cruzy_Plus_MBR_Number__c, Cruzy_Plus_Pitched__c,
                   Spouse_Significant_Other__c, Primary_DOB__c, Secondary_DOB__c,
                   Spanish_Speaking__c, Membership_On_Hold__c
            FROM Contact
            WHERE Id = :resolvedId
            LIMIT 1
        ];
        if (contacts.isEmpty()) return null;

        Set<Id> contactIds = new Set<Id>{ resolvedId };
        List<ContactJourney> results = buildJourneys(contacts, contactIds);
        return results.isEmpty() ? null : results[0];
    }

    // ─── Multi-Contact Journey (Account record page — duplicate view) ─────────

    @AuraEnabled(cacheable=true)
    public static List<ContactJourney> getAccountJourney(Id accountId) {
        List<ContactJourney> journeys = new List<ContactJourney>();

        List<Contact> contacts = [
            SELECT Id, Name, FirstName, LastName,
                   Phone, Email, Alt_Phone__c, Alt_Email__c,
                   Timezone__c, Customer_Source__c, Customer_Notes__c,
                   VIFP_Number__c, VIFP_Level__c, VIFP_Belongs_To__c,
                   VIFP_Number_Secondary__c, VIFP_Level_Secondary__c,
                   VIFP_Secondary_Belongs_To__c,
                   Cruzy_Plus_Enrolled__c, Cruzy_Plus_MBR_Number__c, Cruzy_Plus_Pitched__c,
                   Spouse_Significant_Other__c, Primary_DOB__c, Secondary_DOB__c,
                   Spanish_Speaking__c, Membership_On_Hold__c
            FROM Contact
            WHERE AccountId = :accountId
            ORDER BY LastModifiedDate DESC
        ];

        if (contacts.isEmpty()) return journeys;

        Set<Id> contactIds = new Map<Id, Contact>(contacts).keySet();
        return buildJourneys(contacts, contactIds);
    }

    // ─── Shared query + assembly logic ───────────────────────────────────────

    private static List<ContactJourney> buildJourneys(List<Contact> contacts, Set<Id> contactIds) {
        List<ContactJourney> journeys = new List<ContactJourney>();

        // Memberships — keep most recent per contact
        Map<Id, Membership__c> membershipByContact = new Map<Id, Membership__c>();
        for (Membership__c m : [
            SELECT Id, Name, Status__c, Partner__c, Enroll_Date__c,
                   Last_Renewal_Date__c, Expiration_Date__c, Next_Billing_Date__c,
                   Auto_Renewal__c, Biennial__c, Paid_Through__c, Cancel_Date__c, Contact__c
            FROM Membership__c
            WHERE Contact__c IN :contactIds
            ORDER BY Enroll_Date__c DESC
        ]) {
            if (!membershipByContact.containsKey(m.Contact__c)) {
                membershipByContact.put(m.Contact__c, m);
            }
        }

        // Rewards
        Map<Id, List<Reward__c>> rewardsByContact = new Map<Id, List<Reward__c>>();
        Map<Id, Reward__c> rewardById = new Map<Id, Reward__c>();
        for (Reward__c r : [
            SELECT Id, Name, Status__c, Partner__c, Reward_Number__c,
                   Reward_Location__c, Issue_Date__c, Book_By_Date__c,
                   Expiration_Date__c, Contact__c
            FROM Reward__c
            WHERE Contact__c IN :contactIds
            ORDER BY Issue_Date__c DESC
        ]) {
            if (!rewardsByContact.containsKey(r.Contact__c)) {
                rewardsByContact.put(r.Contact__c, new List<Reward__c>());
            }
            rewardsByContact.get(r.Contact__c).add(r);
            rewardById.put(r.Id, r);
        }

        // Bookings
        Map<Id, List<Booking__c>> bookingsByContact = new Map<Id, List<Booking__c>>();
        for (Booking__c b : [
            SELECT Id, Name, Status__c, Ship__c, Itinerary__c,
                   Departure_Date__c, Departure_Port__c, Cabin_Category__c,
                   PAX_Count__c, Quote_Type__c, Original_Cruise_Total__c,
                   Current_Balance_Due__c, Payment_Date__c,
                   Reward__c, Contact__c
            FROM Booking__c
            WHERE Contact__c IN :contactIds
            ORDER BY Departure_Date__c DESC
        ]) {
            if (!bookingsByContact.containsKey(b.Contact__c)) {
                bookingsByContact.put(b.Contact__c, new List<Booking__c>());
            }
            bookingsByContact.get(b.Contact__c).add(b);
        }

        Set<Id> allBookingIds = new Set<Id>();
        for (List<Booking__c> bl : bookingsByContact.values()) {
            for (Booking__c b : bl) allBookingIds.add(b.Id);
        }

        // Add-Ons
        Map<Id, List<AddOnWrapper>> addOnsByBooking = new Map<Id, List<AddOnWrapper>>();
        for (Add_On__c a : [
            SELECT Id, Name, Add_On_Type__c, Amount__c, Booking__c
            FROM Add_On__c
            WHERE Booking__c IN :allBookingIds
            ORDER BY Add_On_Type__c
        ]) {
            if (!addOnsByBooking.containsKey(a.Booking__c)) {
                addOnsByBooking.put(a.Booking__c, new List<AddOnWrapper>());
            }
            AddOnWrapper aw = new AddOnWrapper();
            aw.Id        = a.Id;
            aw.addonName = a.Name;
            aw.addonType = a.Add_On_Type__c;
            aw.amount    = a.Amount__c;
            addOnsByBooking.get(a.Booking__c).add(aw);
        }

        // Booking Payments
        Map<Id, List<PaymentWrapper>> paymentsByBooking = new Map<Id, List<PaymentWrapper>>();
        for (Booking_Payment__c p : [
            SELECT Id, Amount__c, Payment_Date__c, Note__c, Booking__c
            FROM Booking_Payment__c
            WHERE Booking__c IN :allBookingIds
            ORDER BY Payment_Date__c DESC
        ]) {
            if (!paymentsByBooking.containsKey(p.Booking__c)) {
                paymentsByBooking.put(p.Booking__c, new List<PaymentWrapper>());
            }
            PaymentWrapper pw = new PaymentWrapper();
            pw.Id          = p.Id;
            pw.amount      = p.Amount__c;
            pw.paymentDate = p.Payment_Date__c;
            pw.note        = p.Note__c;
            paymentsByBooking.get(p.Booking__c).add(pw);
        }

        // Assemble contact journeys
        for (Contact c : contacts) {
            ContactJourney cj = new ContactJourney();
            cj.contactId          = c.Id;
            cj.contactName        = c.Name;
            cj.phone              = c.Phone;
            cj.email              = c.Email;
            cj.altPhone           = c.Alt_Phone__c;
            cj.altEmail           = c.Alt_Email__c;
            cj.timezone           = c.Timezone__c;
            cj.customerSource     = c.Customer_Source__c;
            cj.customerNotes      = c.Customer_Notes__c;
            cj.vifpNumber         = c.VIFP_Number__c;
            cj.vifpLevel          = c.VIFP_Level__c;
            cj.vifpBelongsTo      = c.VIFP_Belongs_To__c;
            cj.cruzyPlusEnrolled  = c.Cruzy_Plus_Enrolled__c;
            cj.cruzyPlusMbrNum    = c.Cruzy_Plus_MBR_Number__c;
            cj.cruzyPlusPitched   = c.Cruzy_Plus_Pitched__c;
            cj.spouse             = c.Spouse_Significant_Other__c;
            cj.spanishSpeaking    = c.Spanish_Speaking__c;
            cj.membershipOnHold   = c.Membership_On_Hold__c;

            // Membership wrapper
            if (membershipByContact.containsKey(c.Id)) {
                Membership__c m = membershipByContact.get(c.Id);
                MembershipWrapper mw = new MembershipWrapper();
                mw.membershipId   = m.Id;
                mw.membershipName = m.Name;
                mw.status         = m.Status__c;
                mw.partner        = m.Partner__c;
                mw.enrollDate     = m.Enroll_Date__c;
                mw.expirationDate = m.Expiration_Date__c;
                mw.nextBillingDate= m.Next_Billing_Date__c;
                mw.autoRenewal    = m.Auto_Renewal__c;
                mw.biennial       = m.Biennial__c;
                mw.paidThrough    = m.Paid_Through__c;
                cj.membership     = mw;
            }

            // Rewards
            List<RewardWrapper> rws = new List<RewardWrapper>();
            if (rewardsByContact.containsKey(c.Id)) {
                for (Reward__c r : rewardsByContact.get(c.Id)) {
                    RewardWrapper rw = new RewardWrapper();
                    rw.rewardId      = r.Id;
                    rw.rewardName    = r.Name;
                    rw.status        = r.Status__c;
                    rw.partner       = r.Partner__c;
                    rw.rewardNumber  = r.Reward_Number__c;
                    rw.expirationDate= r.Expiration_Date__c;
                    rw.bookByDate    = r.Book_By_Date__c;
                    rws.add(rw);
                }
            }
            cj.rewards = rws;

            // Bookings
            List<BookingWrapper> bws = new List<BookingWrapper>();
            if (bookingsByContact.containsKey(c.Id)) {
                for (Booking__c b : bookingsByContact.get(c.Id)) {
                    BookingWrapper bw = new BookingWrapper();
                    bw.bookingId       = b.Id;
                    bw.bookingName     = b.Name;
                    bw.status          = b.Status__c;
                    bw.ship            = b.Ship__c;
                    bw.itinerary       = b.Itinerary__c;
                    bw.departureDate   = b.Departure_Date__c;
                    bw.departurePort   = b.Departure_Port__c;
                    bw.cabinCategory   = b.Cabin_Category__c;
                    bw.paxCount        = b.PAX_Count__c;
                    bw.quoteType       = b.Quote_Type__c;
                    bw.cruiseTotal     = b.Original_Cruise_Total__c;
                    bw.balanceDue      = b.Current_Balance_Due__c;
                    bw.rewardId        = b.Reward__c;

                    if (b.Reward__c != null && rewardById.containsKey(b.Reward__c)) {
                        Reward__c r = rewardById.get(b.Reward__c);
                        RewardWrapper rw = new RewardWrapper();
                        rw.rewardId    = r.Id;
                        rw.rewardName  = r.Name;
                        rw.status      = r.Status__c;
                        rw.partner     = r.Partner__c;
                        rw.rewardNumber= r.Reward_Number__c;
                        rw.expirationDate = r.Expiration_Date__c;
                        bw.reward      = rw;
                    }

                    bw.addOns   = addOnsByBooking.containsKey(b.Id) ? addOnsByBooking.get(b.Id) : new List<AddOnWrapper>();
                    bw.payments = paymentsByBooking.containsKey(b.Id) ? paymentsByBooking.get(b.Id) : new List<PaymentWrapper>();
                    bws.add(bw);
                }
            }
            cj.bookings = bws;
            journeys.add(cj);
        }

        return journeys;
    } // end buildJourneys

    public class ContactJourney {
        @AuraEnabled public Id     contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
        @AuraEnabled public String altPhone;
        @AuraEnabled public String altEmail;
        @AuraEnabled public String timezone;
        @AuraEnabled public String customerSource;
        @AuraEnabled public String customerNotes;
        @AuraEnabled public String vifpNumber;
        @AuraEnabled public String vifpLevel;
        @AuraEnabled public String vifpBelongsTo;
        @AuraEnabled public Boolean cruzyPlusEnrolled;
        @AuraEnabled public String  cruzyPlusMbrNum;
        @AuraEnabled public Boolean cruzyPlusPitched;
        @AuraEnabled public String  spouse;
        @AuraEnabled public Boolean spanishSpeaking;
        @AuraEnabled public Boolean membershipOnHold;
        @AuraEnabled public MembershipWrapper     membership;
        @AuraEnabled public List<RewardWrapper>   rewards;
        @AuraEnabled public List<BookingWrapper>  bookings;
    }

    public class MembershipWrapper {
        @AuraEnabled public Id      membershipId;
        @AuraEnabled public String  membershipName;
        @AuraEnabled public String  status;
        @AuraEnabled public String  partner;
        @AuraEnabled public Date    enrollDate;
        @AuraEnabled public Date    expirationDate;
        @AuraEnabled public Date    nextBillingDate;
        @AuraEnabled public Boolean autoRenewal;
        @AuraEnabled public Boolean biennial;
        @AuraEnabled public Date    paidThrough;
    }

    public class RewardWrapper {
        @AuraEnabled public Id     rewardId;
        @AuraEnabled public String rewardName;
        @AuraEnabled public String status;
        @AuraEnabled public String partner;
        @AuraEnabled public String rewardNumber;
        @AuraEnabled public Date   expirationDate;
        @AuraEnabled public Date   bookByDate;
    }

    public class BookingWrapper {
        @AuraEnabled public Id      bookingId;
        @AuraEnabled public String  bookingName;
        @AuraEnabled public String  status;
        @AuraEnabled public String  ship;
        @AuraEnabled public String  itinerary;
        @AuraEnabled public Date    departureDate;
        @AuraEnabled public String  departurePort;
        @AuraEnabled public String  cabinCategory;
        @AuraEnabled public Decimal paxCount;
        @AuraEnabled public String  quoteType;
        @AuraEnabled public Decimal cruiseTotal;
        @AuraEnabled public Decimal balanceDue;
        @AuraEnabled public Id      rewardId;
        @AuraEnabled public RewardWrapper        reward;
        @AuraEnabled public List<AddOnWrapper>   addOns;
        @AuraEnabled public List<PaymentWrapper> payments;
    }

    public class AddOnWrapper {
        @AuraEnabled public Id      Id;
        @AuraEnabled public String  addonName;
        @AuraEnabled public String  addonType;
        @AuraEnabled public Decimal amount;
    }

    public class PaymentWrapper {
        @AuraEnabled public Id      Id;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Date    paymentDate;
        @AuraEnabled public String  note;
    }
}
