public with sharing class AuthnetPaymentController {

    // ─── Contact Bookings (for payment panel dropdown) ────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<Booking__c> getContactBookings(Id contactId) {
        Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
        if (resolvedId == null) return new List<Booking__c>();
        return [
            SELECT Id, Name, Current_Balance_Due__c, Original_Cruise_Total__c,
                   Ship__c, Departure_Date__c, Status__c
            FROM Booking__c
            WHERE Contact__c = :resolvedId
            ORDER BY Departure_Date__c DESC
        ];
    }

    // ─── Card Vault ───────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<Saved_Card__c> getSavedCards(Id contactId) {
        Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
        if (resolvedId == null) return new List<Saved_Card__c>();
        return [
            SELECT Id, Name, Card_Brand__c, Last_Four__c,
                   Expiry_Month__c, Expiry_Year__c,
                   Cardholder_Name__c, Is_Default__c,
                   Authnet_Payment_Profile_Id__c
            FROM Saved_Card__c
            WHERE Contact__c = :resolvedId
            ORDER BY Is_Default__c DESC, CreatedDate DESC
        ];
    }

    // ─── Billing Hub Data ─────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static BillingHubData getBillingHubData(Id contactId) {
        Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
        BillingHubData hub = new BillingHubData();
        if (resolvedId == null) return hub;

        hub.cards = [
            SELECT Id, Name, Card_Brand__c, Last_Four__c,
                   Expiry_Month__c, Expiry_Year__c,
                   Cardholder_Name__c, Is_Default__c,
                   Authnet_Payment_Profile_Id__c
            FROM Saved_Card__c
            WHERE Contact__c = :resolvedId
            ORDER BY Is_Default__c DESC, CreatedDate DESC
        ];

        hub.memberships = [
            SELECT Id, Name, Status__c, Enroll_Date__c, Expiration_Date__c,
                   Next_Billing_Date__c, Last_Renewal_Date__c,
                   Auto_Renewal__c, Biennial__c, Partner__c, Paid_Through__c,
                   Cancel_Date__c
            FROM Membership__c
            WHERE Contact__c = :resolvedId
            ORDER BY Enroll_Date__c DESC
        ];

        hub.recentPayments = [
            SELECT Id, Name, Amount__c, Payment_Date__c, Note__c,
                   Authnet_Transaction_ID__c,
                   Booking__r.Name, Booking__r.Ship__c, Booking__r.Departure_Date__c,
                   Booking__r.Current_Balance_Due__c
            FROM Booking_Payment__c
            WHERE Booking__r.Contact__c = :resolvedId
            ORDER BY Payment_Date__c DESC
        ];

        hub.membershipPayments = [
            SELECT Id, Name, Amount_Paid__c, Date_Paid__c, Renewal_Year__c,
                   Membership__r.Name
            FROM Membership_Payment__c
            WHERE Membership__r.Contact__c = :resolvedId
            ORDER BY Date_Paid__c DESC
        ];

        AggregateResult[] bpAgg = [
            SELECT SUM(Amount__c) total
            FROM Booking_Payment__c
            WHERE Booking__r.Contact__c = :resolvedId
        ];
        AggregateResult[] mpAgg = [
            SELECT SUM(Amount_Paid__c) total
            FROM Membership_Payment__c
            WHERE Membership__r.Contact__c = :resolvedId
        ];
        Decimal bpTotal = (bpAgg[0].get('total') != null) ? (Decimal)bpAgg[0].get('total') : 0;
        Decimal mpTotal = (mpAgg[0].get('total') != null) ? (Decimal)mpAgg[0].get('total') : 0;
        hub.lifetimeSpend = bpTotal + mpTotal;

        return hub;
    }

    public class BillingHubData {
        @AuraEnabled public List<Saved_Card__c>        cards;
        @AuraEnabled public List<Membership__c>        memberships;
        @AuraEnabled public List<Booking_Payment__c>   recentPayments;
        @AuraEnabled public List<Membership_Payment__c> membershipPayments;
        @AuraEnabled public Decimal                    lifetimeSpend;
    }

    // ─── Save Card (creates real Authorize.net CIM profile) ─────────────────

    @AuraEnabled
    public static Saved_Card__c saveCard(Id contactId, String cardBrand, String lastFour,
                                          Integer expiryMonth, Integer expiryYear,
                                          String cardholderName, Boolean makeDefault,
                                          String cardNumber, String cvv) {
        Id resolvedId = CruzyIdResolver.resolveContactId(contactId);

        Contact con = [
            SELECT Id, FirstName, LastName, Email,
                   Authnet_Customer_Profile_ID__c
            FROM Contact WHERE Id = :resolvedId LIMIT 1
        ];

        String expDate = String.valueOf(expiryYear) + '-' +
                         String.valueOf(expiryMonth).leftPad(2, '0');

        String paymentProfileId;
        String customerProfileId = con.Authnet_Customer_Profile_ID__c;

        if (String.isNotBlank(customerProfileId)) {
            paymentProfileId = AuthnetService.createPaymentProfile(
                customerProfileId,
                cardNumber, expDate, cvv,
                con.FirstName, con.LastName
            );
        } else {
            AuthnetService.ProfileResult profile = AuthnetService.createCustomerProfile(
                con.Email, con.FirstName, con.LastName,
                cardNumber, expDate, cvv
            );
            customerProfileId = profile.customerProfileId;
            paymentProfileId  = profile.paymentProfileId;

            con.Authnet_Customer_Profile_ID__c = customerProfileId;
            update con;
        }

        if (makeDefault) {
            List<Saved_Card__c> existing = [
                SELECT Id FROM Saved_Card__c
                WHERE Contact__c = :resolvedId AND Is_Default__c = true
            ];
            for (Saved_Card__c c : existing) c.Is_Default__c = false;
            if (!existing.isEmpty()) update existing;
        }

        Integer cardCount = [SELECT COUNT() FROM Saved_Card__c WHERE Contact__c = :resolvedId];
        Boolean isDefault = makeDefault || cardCount == 0;

        Saved_Card__c card = new Saved_Card__c(
            Name             = cardBrand + ' •••• ' + lastFour,
            Contact__c       = resolvedId,
            Card_Brand__c    = cardBrand,
            Last_Four__c     = lastFour,
            Expiry_Month__c  = expiryMonth,
            Expiry_Year__c   = expiryYear,
            Cardholder_Name__c = cardholderName,
            Is_Default__c    = isDefault,
            Authnet_Payment_Profile_Id__c = paymentProfileId
        );
        insert card;
        return card;
    }

    @AuraEnabled
    public static void deleteCard(Id cardId) {
        Saved_Card__c card = [
            SELECT Id, Contact__c, Is_Default__c,
                   Authnet_Payment_Profile_Id__c
            FROM Saved_Card__c WHERE Id = :cardId
        ];

        // Attempt to delete the payment profile from Authorize.net
        if (String.isNotBlank(card.Authnet_Payment_Profile_Id__c)) {
            try {
                Contact con = [
                    SELECT Authnet_Customer_Profile_ID__c
                    FROM Contact WHERE Id = :card.Contact__c LIMIT 1
                ];
                if (String.isNotBlank(con.Authnet_Customer_Profile_ID__c)) {
                    AuthnetService.deletePaymentProfile(
                        con.Authnet_Customer_Profile_ID__c,
                        card.Authnet_Payment_Profile_Id__c
                    );
                }
            } catch (Exception e) {
                System.debug('Authnet profile delete failed (non-blocking): ' + e.getMessage());
            }
        }

        delete card;

        if (card.Is_Default__c) {
            List<Saved_Card__c> remaining = [
                SELECT Id FROM Saved_Card__c
                WHERE Contact__c = :card.Contact__c
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!remaining.isEmpty()) {
                remaining[0].Is_Default__c = true;
                update remaining[0];
            }
        }
    }

    @AuraEnabled
    public static void setDefaultCard(Id cardId, Id contactId) {
        Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
        List<Saved_Card__c> all = [
            SELECT Id, Is_Default__c FROM Saved_Card__c WHERE Contact__c = :resolvedId
        ];
        for (Saved_Card__c c : all) {
            c.Is_Default__c = (c.Id == cardId);
        }
        update all;
    }

    // ─── Charge (real Authorize.net transaction) ────────────────────────────

    @AuraEnabled
    public static ChargeResult chargeCard(Id bookingId, Id cardId, Decimal amount, String note) {
        Saved_Card__c card = [
            SELECT Id, Name, Card_Brand__c, Last_Four__c,
                   Authnet_Payment_Profile_Id__c, Contact__c
            FROM Saved_Card__c WHERE Id = :cardId
        ];

        Booking__c booking = [
            SELECT Id, Name, Current_Balance_Due__c, Original_Cruise_Total__c, Contact__c
            FROM Booking__c WHERE Id = :bookingId
        ];

        if (amount <= 0) {
            throw new AuraHandledException('Charge amount must be greater than $0.00');
        }
        if (amount > booking.Current_Balance_Due__c) {
            throw new AuraHandledException(
                'Charge amount ($' + amount + ') exceeds balance due ($' + booking.Current_Balance_Due__c + ')'
            );
        }

        Contact con = [
            SELECT Authnet_Customer_Profile_ID__c
            FROM Contact WHERE Id = :card.Contact__c LIMIT 1
        ];

        if (String.isBlank(con.Authnet_Customer_Profile_ID__c) ||
            String.isBlank(card.Authnet_Payment_Profile_Id__c)) {
            throw new AuraHandledException(
                'This card has no Authorize.net payment profile. Please add a new card first.'
            );
        }

        AuthnetService.ChargeResult authResult = AuthnetService.chargeCustomerProfile(
            con.Authnet_Customer_Profile_ID__c,
            card.Authnet_Payment_Profile_Id__c,
            amount,
            booking.Name + ' — ' + card.Card_Brand__c + ' •••• ' + card.Last_Four__c
        );

        String paymentNote = String.isNotBlank(note) ? note :
            card.Card_Brand__c + ' •••• ' + card.Last_Four__c +
            ' · Authorize.net txn ' + authResult.transactionId;

        Booking_Payment__c payment = new Booking_Payment__c(
            Booking__c              = bookingId,
            Amount__c               = amount,
            Payment_Date__c         = Date.today(),
            Note__c                 = paymentNote,
            Authnet_Transaction_ID__c = authResult.transactionId
        );
        insert payment;

        booking.Current_Balance_Due__c = (booking.Current_Balance_Due__c - amount).setScale(2);
        update booking;

        ChargeResult result = new ChargeResult();
        result.success        = true;
        result.chargeId       = authResult.authCode;
        result.transactionId  = authResult.transactionId;
        result.amountCharged  = amount;
        result.newBalanceDue  = booking.Current_Balance_Due__c;
        result.cardDisplay    = card.Card_Brand__c + ' •••• ' + card.Last_Four__c;
        result.paymentId      = payment.Id;
        return result;
    }

    public class ChargeResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  chargeId;
        @AuraEnabled public String  transactionId;
        @AuraEnabled public Decimal amountCharged;
        @AuraEnabled public Decimal newBalanceDue;
        @AuraEnabled public String  cardDisplay;
        @AuraEnabled public Id      paymentId;
    }
}
