@RestResource(urlMapping='/odysseus/booking')
global without sharing class OdysseusBookingWebhook {

    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        String body = req.requestBody.toString();
        Map<String, Object> payload = null;
        String transactionId = null;
        String action = null;

        try {
            if (!authenticateRequest(req)) {
                logEvent(null, null, 'Error', body, '{"error":"Unauthorized"}', 'Unauthorized');
                res.statusCode = 401;
                res.responseBody = Blob.valueOf('{"success":"false","error":"Unauthorized"}');
                return;
            }

            payload = (Map<String, Object>) JSON.deserializeUntyped(body);

            Map<String, Object> txn = (Map<String, Object>) payload.get('Transaction');
            if (txn != null) {
                transactionId = String.valueOf(txn.get('TransactionID'));
                action = String.valueOf(txn.get('Action'));
            }

            Map<String, Object> booking = resolveBookingNode(payload);
            if (booking == null) {
                logEvent(transactionId, action, 'Error', body, '{"error":"No Booking node found"}', 'No Booking node found');
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"success":"false","error":"No Booking node found"}');
                return;
            }

            processBooking(booking);

            logEvent(transactionId, action, 'Success', body, '{"success":"true"}', null);
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"success":"true"}');

        } catch (Exception e) {
            String errorMsg = e.getMessage() + '\n' + e.getStackTraceString();
            logEvent(transactionId, action, 'Error', body, '{"error":"' + e.getMessage().escapeJava() + '"}', errorMsg);
            System.debug(LoggingLevel.ERROR, 'Odysseus webhook error: ' + errorMsg);
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"success":"false","error":"' + e.getMessage().escapeJava() + '"}');
        }
    }

    private static void logEvent(String transactionId, String action, String status, String requestPayload, String responsePayload, String errorMessage) {
        try {
            Odysseus_Log__c log = new Odysseus_Log__c(
                Transaction_ID__c = transactionId,
                Action__c = action,
                Status__c = status,
                Request_Payload__c = requestPayload != null && requestPayload.length() > 131072 ? requestPayload.substring(0, 131072) : requestPayload,
                Response_Payload__c = responsePayload != null && responsePayload.length() > 131072 ? responsePayload.substring(0, 131072) : responsePayload,
                Error_Message__c = errorMessage != null && errorMessage.length() > 32768 ? errorMessage.substring(0, 32768) : errorMessage,
                Timestamp__c = System.now()
            );
            insert log;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log Odysseus event: ' + e.getMessage());
        }
    }

    // ── Auth ────────────────────────────────────────────────────────────────

    private static Boolean authenticateRequest(RestRequest req) {
        String secret;
        try { secret = System.Label.Odysseus_Webhook_Secret; } catch (Exception e) { return false; }
        if (String.isBlank(secret)) return false;

        String token = req.params.get('token');

        if (String.isBlank(token)) {
            token = req.headers.get('X-Webhook-Secret');
        }

        if (String.isBlank(token)) {
            String authHeader = req.headers.get('Authorization');
            if (String.isNotBlank(authHeader) && authHeader.startsWithIgnoreCase('Bearer ')) {
                token = authHeader.substring(7).trim();
            }
        }

        return String.isNotBlank(token) && token == secret;
    }

    // ── Booking node resolution ─────────────────────────────────────────────

    private static Map<String, Object> resolveBookingNode(Map<String, Object> payload) {
        Object txn = payload.get('Transaction');
        if (txn instanceof Map<String, Object>) {
            Object bk = ((Map<String, Object>) txn).get('Booking');
            if (bk instanceof Map<String, Object>) return (Map<String, Object>) bk;
        }
        Object bk = payload.get('Booking');
        if (bk instanceof Map<String, Object>) return (Map<String, Object>) bk;
        return null;
    }

    // ── Main processing ─────────────────────────────────────────────────────

    @TestVisible
    private static void processBooking(Map<String, Object> booking) {
        String transactionId = String.valueOf(booking.get('TransactionID'));
        if (String.isBlank(transactionId)) {
            throw new OdysseusException('TransactionID is required');
        }

        Id contactId = resolveContact(booking);

        Id accountId = null;
        if (contactId != null) {
            List<Contact> ctx = [SELECT AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
            if (!ctx.isEmpty()) accountId = ctx[0].AccountId;
        }

        Map<String, Object> cruisePkg = OdysseusJsonParser.findCruisePackage(booking.get('Packages'));

        Booking__c bk = buildBookingRecord(booking, cruisePkg, contactId, transactionId);
        if (accountId != null) bk.Account__c = accountId;

        List<Booking__c> existingBookings = [
            SELECT Id FROM Booking__c
            WHERE Odysseus_Transaction_ID__c = :transactionId LIMIT 1
        ];
        if (!existingBookings.isEmpty()) {
            bk.Id = existingBookings[0].Id;
            update bk;
        } else {
            insert bk;
        }

        if (cruisePkg != null) {
            processPaymentSchedules(cruisePkg, bk.Id, transactionId);
        }

        List<Map<String, Object>> addOnPkgs = OdysseusJsonParser.findNonCruisePackages(booking.get('Packages'));
        processAddOns(addOnPkgs, bk.Id, cruisePkg);

        processInsuranceAddOn(cruisePkg, bk.Id);
    }

    // ── Contact resolution (Person Account) ────────────────────────────────

    private static Id personAccountRtId {
        get {
            if (personAccountRtId == null) {
                Map<String, Schema.RecordTypeInfo> rtMap =
                    Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
                Schema.RecordTypeInfo rti = rtMap.get('PersonAccount');
                if (rti != null) {
                    personAccountRtId = rti.getRecordTypeId();
                }
            }
            return personAccountRtId;
        }
        set;
    }

    private static Id resolveContact(Map<String, Object> booking) {
        Map<String, Object> customer = (Map<String, Object>) booking.get('Customer');
        if (customer == null) return null;

        String email = OdysseusJsonParser.resolveCdata(customer.get('Email'));
        if (String.isBlank(email)) {
            Map<String, Object> passengers = (Map<String, Object>) booking.get('Passengers');
            if (passengers != null) {
                List<Object> paxList = OdysseusJsonParser.toList(passengers.get('Passenger'));
                if (!paxList.isEmpty()) {
                    Map<String, Object> firstPax = (Map<String, Object>) paxList[0];
                    email = String.valueOf(firstPax.get('Email'));
                }
            }
        }
        if (String.isBlank(email)) return null;
        email = email.toLowerCase().trim();

        List<Account> existing = [
            SELECT Id, PersonContactId FROM Account
            WHERE PersonEmail = :email AND IsPersonAccount = true
            LIMIT 1
        ];

        if (!existing.isEmpty()) {
            return existing[0].PersonContactId;
        }

        String firstName = OdysseusJsonParser.resolveCdata(customer.get('FirstName'));
        String lastName = OdysseusJsonParser.resolveCdata(customer.get('LastName'));
        if (String.isBlank(lastName)) lastName = 'Unknown';

        Account pa = new Account(
            RecordTypeId = personAccountRtId,
            FirstName = firstName,
            LastName = lastName,
            PersonEmail = email
        );

        String phone = findCustomerPhone(booking);
        if (String.isNotBlank(phone)) pa.Phone = phone;

        Date dob = OdysseusJsonParser.parseDate(String.valueOf(customer.get('DateOfBirth')));
        if (dob != null) pa.Primary_DOB__pc = dob;

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        Database.SaveResult sr = Database.insert(pa, dml);
        if (!sr.isSuccess()) {
            throw new OdysseusException('Person Account insert failed: ' + sr.getErrors()[0].getMessage());
        }

        List<Contact> personContact = [
            SELECT Id FROM Contact WHERE AccountId = :pa.Id LIMIT 1
        ];
        if (!personContact.isEmpty()) {
            return personContact[0].Id;
        }
        return null;
    }

    private static String findCustomerPhone(Map<String, Object> booking) {
        Map<String, Object> passengers = (Map<String, Object>) booking.get('Passengers');
        if (passengers == null) return null;
        List<Object> paxList = OdysseusJsonParser.toList(passengers.get('Passenger'));
        if (paxList.isEmpty()) return null;

        Map<String, Object> firstPax = (Map<String, Object>) paxList[0];
        Object phoneObj = firstPax.get('Phone');
        if (phoneObj instanceof String) return (String) phoneObj;
        if (phoneObj instanceof Map<String, Object>) {
            Map<String, Object> pm = (Map<String, Object>) phoneObj;
            String cc = String.valueOf(pm.get('CountryCode'));
            String num = String.valueOf(pm.get('Number'));
            if (String.isNotBlank(num)) return '+' + (String.isNotBlank(cc) ? cc : '') + num;
        }
        return null;
    }

    // ── Booking record builder ──────────────────────────────────────────────

    private static Booking__c buildBookingRecord(
        Map<String, Object> booking,
        Map<String, Object> cruisePkg,
        Id contactId,
        String transactionId
    ) {
        Booking__c bk = new Booking__c();
        bk.Odysseus_Transaction_ID__c = transactionId;
        bk.Odysseus_Confirmation__c = String.valueOf(booking.get('AgencyConfirmation'));

        if (contactId != null) bk.Contact__c = contactId;

        Map<String, Object> passengers = (Map<String, Object>) booking.get('Passengers');
        if (passengers != null) {
            bk.PAX_Count__c = OdysseusJsonParser.getNestedInteger(passengers, 'NoOfAdult');
        }

        if (cruisePkg == null) {
            bk.Status__c = 'Quote';
            return bk;
        }

        bk.Name = String.valueOf(cruisePkg.get('ConfirmationNumber'));
        bk.Odysseus_Package_ID__c = String.valueOf(cruisePkg.get('PackageID'));
        bk.Cruise_Name__c = OdysseusJsonParser.resolveCdata(cruisePkg.get('CruiseName'));
        bk.Cruise_Line__c = OdysseusJsonParser.getNestedString(cruisePkg, 'CruiseLine.Name');
        bk.Cabin_Category__c = OdysseusJsonParser.getNestedString(cruisePkg, 'Category.Code');
        bk.Cabin_Number__c = OdysseusJsonParser.getNestedString(cruisePkg, 'Cabin.Code');
        bk.Deck__c = OdysseusJsonParser.getNestedString(cruisePkg, 'Deck.Name');
        bk.Fare_Code__c = OdysseusJsonParser.getNestedString(cruisePkg, 'FareCode.ID');

        bk.Ship__c = OdysseusJsonParser.getNestedString(cruisePkg, 'Ship.Name');
        bk.Itinerary__c = mapItinerary(OdysseusJsonParser.getNestedString(cruisePkg, 'Destination.Name'));
        bk.Departure_Port__c = mapDeparturePort(
            OdysseusJsonParser.getNestedString(cruisePkg, 'DepartureCity.Name')
        );

        bk.Departure_Date__c = OdysseusJsonParser.parseDate(
            String.valueOf(cruisePkg.get('DepartureDate'))
        );

        Integer duration = OdysseusJsonParser.getNestedInteger(
            new Map<String, Object>{ 'v' => cruisePkg.get('Duration') }, 'v'
        );
        if (duration != null) bk.Duration_Nights__c = duration;

        String odyStatus = OdysseusJsonParser.getNestedString(cruisePkg, 'Status.Name');
        bk.Odysseus_Status__c = odyStatus;
        bk.Status__c = OdysseusJsonParser.mapBookingStatus(odyStatus);

        Object cruisePrices = cruisePkg.get('Prices');
        Decimal total = OdysseusJsonParser.getPriceById(cruisePrices, '17');
        if (total != null) bk.Original_Cruise_Total__c = total;

        Decimal balanceDue = OdysseusJsonParser.getPriceById(cruisePrices, '63');
        if (balanceDue == null) balanceDue = OdysseusJsonParser.getPriceById(cruisePrices, '62');
        if (balanceDue != null) bk.Current_Balance_Due__c = balanceDue;

        return bk;
    }

    // ── Payment schedules ───────────────────────────────────────────────────

    private static void processPaymentSchedules(
        Map<String, Object> cruisePkg, Id bookingId, String transactionId
    ) {
        Object custSchedules = OdysseusJsonParser.getNestedValue(
            cruisePkg, 'CustomerPaymentSchedules'
        );
        if (custSchedules == null || !(custSchedules instanceof Map<String, Object>)) return;

        Object scheduleObj = ((Map<String, Object>) custSchedules).get('PaymentSchedule');
        List<Object> schedules = OdysseusJsonParser.toList(scheduleObj);

        List<Booking_Payment__c> payments = new List<Booking_Payment__c>();
        for (Object sObj : schedules) {
            if (!(sObj instanceof Map<String, Object>)) continue;
            Map<String, Object> s = (Map<String, Object>) sObj;

            String payId = String.valueOf(s.get('ID'));
            if (String.isBlank(payId)) continue;

            Booking_Payment__c bp = new Booking_Payment__c();
            bp.Odysseus_Payment_ID__c = payId;
            bp.Booking__c = bookingId;
            bp.Source__c = 'Odysseus';
            bp.Payment_Type__c = String.valueOf(s.get('Type'));

            String amt = String.valueOf(s.get('Amount'));
            if (String.isNotBlank(amt)) {
                try { bp.Amount__c = Decimal.valueOf(amt.trim()); } catch (Exception e) { /* skip */ }
            }

            bp.Payment_Date__c = OdysseusJsonParser.parseDate(String.valueOf(s.get('DueDate')));

            payments.add(bp);
        }

        if (!payments.isEmpty()) {
            Set<String> payIds = new Set<String>();
            for (Booking_Payment__c bp : payments) {
                payIds.add(bp.Odysseus_Payment_ID__c);
            }

            Map<String, Id> existingMap = new Map<String, Id>();
            for (Booking_Payment__c ep : [
                SELECT Id, Odysseus_Payment_ID__c FROM Booking_Payment__c
                WHERE Odysseus_Payment_ID__c IN :payIds
            ]) {
                existingMap.put(ep.Odysseus_Payment_ID__c, ep.Id);
            }

            List<Booking_Payment__c> toInsert = new List<Booking_Payment__c>();
            List<Booking_Payment__c> toUpdate = new List<Booking_Payment__c>();
            for (Booking_Payment__c bp : payments) {
                Id existingId = existingMap.get(bp.Odysseus_Payment_ID__c);
                if (existingId != null) {
                    bp.Id = existingId;
                    toUpdate.add(bp);
                } else {
                    toInsert.add(bp);
                }
            }
            if (!toInsert.isEmpty()) insert toInsert;
            if (!toUpdate.isEmpty()) update toUpdate;
        }
    }

    // ── Add-ons from non-cruise packages ────────────────────────────────────

    private static void processAddOns(
        List<Map<String, Object>> addOnPkgs, Id bookingId, Map<String, Object> cruisePkg
    ) {
        if (addOnPkgs == null || addOnPkgs.isEmpty()) return;

        List<Add_On__c> addOns = new List<Add_On__c>();
        for (Map<String, Object> pkg : addOnPkgs) {
            String pkgType = String.valueOf(pkg.get('Type'));
            String name = OdysseusJsonParser.resolveCdata(pkg.get('Name'));
            if (String.isBlank(name)) name = pkgType;

            Decimal amount = null;
            Object prices = pkg.get('Prices');
            if (prices != null) {
                amount = OdysseusJsonParser.getPriceById(prices, '23');
                if (amount == null) amount = OdysseusJsonParser.getPriceById(prices, '17');
            }

            Add_On__c ao = new Add_On__c();
            ao.Booking__c = bookingId;
            ao.Name = name.left(80);
            ao.Add_On_Type__c = OdysseusJsonParser.mapAddOnType(pkgType);
            if (amount != null) ao.Amount__c = amount;
            addOns.add(ao);
        }

        if (!addOns.isEmpty()) insert addOns;
    }

    /**
     * Extracts travel insurance from cruise package price lines (ID=6, Code=52)
     * and creates an Add_On__c if present.
     */
    private static void processInsuranceAddOn(Map<String, Object> cruisePkg, Id bookingId) {
        if (cruisePkg == null) return;
        Object pricesObj = cruisePkg.get('Prices');
        Decimal insuranceAmount = OdysseusJsonParser.getPriceById(pricesObj, '6');
        if (insuranceAmount != null && insuranceAmount > 0) {
            Add_On__c ins = new Add_On__c();
            ins.Booking__c = bookingId;
            ins.Name = 'Travel Insurance';
            ins.Add_On_Type__c = 'Travel Insurance';
            ins.Amount__c = insuranceAmount;
            insert ins;
        }
    }

    // ── Picklist mapping helpers ─────────────────────────────────────────────

    private static String mapItinerary(String destination) {
        if (String.isBlank(destination)) return null;
        String d = destination.toLowerCase();

        if (d.contains('bahamas')) return 'Bahamas';
        if (d.contains('eastern')) return 'Caribbean - Eastern';
        if (d.contains('western')) return 'Caribbean - Western';
        if (d.contains('southern')) return 'Caribbean - Southern';
        if (d.contains('caribbean')) return 'Caribbean - Eastern';
        if (d.contains('mexico')) return 'Mexico';
        if (d.contains('bermuda')) return 'Bermuda';
        if (d.contains('canada') || d.contains('england') || d.contains('new england')) return 'Canada/New England';
        if (d.contains('pacific')) return 'Pacific Coast';
        if (d.contains('alaska')) return 'Alaska';
        if (d.contains('europe') || d.contains('mediterranean')) return 'Europe';
        return null;
    }

    private static String mapDeparturePort(String cityName) {
        if (String.isBlank(cityName)) return null;
        String c = cityName.toLowerCase();

        if (c.contains('canaveral')) return 'Port Canaveral, FL';
        if (c.contains('jacksonville')) return 'Jacksonville, FL';
        if (c.contains('miami')) return 'Miami, FL';
        if (c.contains('tampa')) return 'Tampa, FL';
        if (c.contains('galveston')) return 'Galveston, TX';
        if (c.contains('new orleans')) return 'New Orleans, LA';
        if (c.contains('baltimore')) return 'Baltimore, MD';
        if (c.contains('charleston')) return 'Charleston, SC';
        if (c.contains('norfolk')) return 'Norfolk, VA';
        return null;
    }

    public class OdysseusException extends Exception {}
}
