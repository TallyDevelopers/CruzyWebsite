public with sharing class BookingOverviewController {

    @AuraEnabled(cacheable=true)
    public static BookingDetail getBookingDetails(Id bookingId) {
        if (bookingId == null) return null;

        List<Booking__c> bookings = [
            SELECT Id, Name, Status__c, Ship__c, Cruise_Name__c, Cruise_Line__c,
                   Itinerary__c, Departure_Date__c, Departure_Port__c,
                   Duration_Nights__c, Return_Date__c,
                   Cabin_Category__c, Cabin_Number__c, Deck__c,
                   PAX_Count__c, Quote_Type__c, Fare_Code__c,
                   Dining_Time__c, Special_Considerations__c, Booking_Tag__c,
                   Original_Cruise_Total__c, Current_Balance_Due__c,
                   Cruise_Total__c, Cruise_Line_Total_Fare__c,
                   Cruzy_Cruise_Rate__c, Cruzy_Total_Fare__c,
                   Cruise_Line_Cruise_Rate__c, Cruise_Line_Rate_Code__c,
                   Cruzy_Rate_Code__c,
                   Savings__c, Mark_Up__c, Mark_Up_Percent__c,
                   Price_per_Person_per_Day__c, Payment_Date__c,
                   Odysseus_Transaction_ID__c, Odysseus_Confirmation__c,
                   Odysseus_Status__c, Odysseus_Package_ID__c,
                   Contact__c, Contact__r.Name,
                   Account__c, Account__r.Name,
                   Reward__c, Reward__r.Name, Reward__r.Status__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];
        if (bookings.isEmpty()) return null;
        Booking__c b = bookings[0];

        BookingDetail d = new BookingDetail();
        d.bookingId        = b.Id;
        d.name             = b.Name;
        d.status           = b.Status__c;
        d.ship             = b.Ship__c;
        d.cruiseName       = b.Cruise_Name__c;
        d.cruiseLine       = b.Cruise_Line__c;
        d.itinerary        = b.Itinerary__c;
        d.departureDate    = b.Departure_Date__c;
        d.departurePort    = b.Departure_Port__c;
        d.durationNights   = b.Duration_Nights__c != null ? Integer.valueOf(b.Duration_Nights__c) : null;
        d.returnDate       = b.Return_Date__c;
        d.cabinCategory    = b.Cabin_Category__c;
        d.cabinNumber      = b.Cabin_Number__c;
        d.deck             = b.Deck__c;
        d.paxCount         = b.PAX_Count__c != null ? Integer.valueOf(b.PAX_Count__c) : null;
        d.quoteType        = b.Quote_Type__c;
        d.fareCode         = b.Fare_Code__c;
        d.diningTime       = b.Dining_Time__c;
        d.specialConsiderations = b.Special_Considerations__c;
        d.bookingTag       = b.Booking_Tag__c;
        d.originalTotal    = b.Original_Cruise_Total__c;
        d.currentBalance   = b.Current_Balance_Due__c;
        d.cruiseTotal      = b.Cruise_Total__c;
        d.cruiseLineTotalFare = b.Cruise_Line_Total_Fare__c;
        d.cruzyCruiseRate  = b.Cruzy_Cruise_Rate__c;
        d.cruzyTotalFare   = b.Cruzy_Total_Fare__c;
        d.cruiseLineCruiseRate = b.Cruise_Line_Cruise_Rate__c;
        d.savings          = b.Savings__c;
        d.markUp           = b.Mark_Up__c;
        d.markUpPercent    = b.Mark_Up_Percent__c;
        d.pricePerPersonDay = b.Price_per_Person_per_Day__c;
        d.paymentDate      = b.Payment_Date__c;
        d.contactId        = b.Contact__c;
        d.contactName      = b.Contact__r?.Name;
        d.accountId        = b.Account__c;
        d.accountName      = b.Account__r?.Name;
        d.rewardId         = b.Reward__c;
        d.rewardName       = b.Reward__r?.Name;
        d.rewardStatus     = b.Reward__r?.Status__c;

        d.odysseusTransactionId = b.Odysseus_Transaction_ID__c;
        d.odysseusConfirmation  = b.Odysseus_Confirmation__c;
        d.odysseusStatus        = b.Odysseus_Status__c;
        d.odysseusPackageId     = b.Odysseus_Package_ID__c;
        d.fromOdysseus          = String.isNotBlank(b.Odysseus_Transaction_ID__c);

        // Add-Ons
        List<AddOnItem> addOnItems = new List<AddOnItem>();
        for (Add_On__c a : [
            SELECT Id, Name, Add_On_Type__c, Amount__c
            FROM Add_On__c WHERE Booking__c = :bookingId ORDER BY Add_On_Type__c
        ]) {
            AddOnItem ai = new AddOnItem();
            ai.id        = a.Id;
            ai.name      = a.Name;
            ai.addonType = a.Add_On_Type__c;
            ai.amount    = a.Amount__c;
            addOnItems.add(ai);
        }
        d.addOns = addOnItems;

        // Payments
        List<PaymentItem> paymentItems = new List<PaymentItem>();
        for (Booking_Payment__c p : [
            SELECT Id, Amount__c, Payment_Date__c, Note__c, Payment_Type__c, Source__c
            FROM Booking_Payment__c WHERE Booking__c = :bookingId ORDER BY Payment_Date__c DESC
        ]) {
            PaymentItem pi = new PaymentItem();
            pi.id          = p.Id;
            pi.amount      = p.Amount__c;
            pi.paymentDate = p.Payment_Date__c;
            pi.note        = p.Note__c;
            pi.paymentType = p.Payment_Type__c;
            pi.source      = p.Source__c;
            paymentItems.add(pi);
        }
        d.payments = paymentItems;

        return d;
    }

    public class BookingDetail {
        @AuraEnabled public Id      bookingId;
        @AuraEnabled public String  name;
        @AuraEnabled public String  status;
        @AuraEnabled public String  ship;
        @AuraEnabled public String  cruiseName;
        @AuraEnabled public String  cruiseLine;
        @AuraEnabled public String  itinerary;
        @AuraEnabled public Date    departureDate;
        @AuraEnabled public String  departurePort;
        @AuraEnabled public Integer durationNights;
        @AuraEnabled public Date    returnDate;
        @AuraEnabled public String  cabinCategory;
        @AuraEnabled public String  cabinNumber;
        @AuraEnabled public String  deck;
        @AuraEnabled public Integer paxCount;
        @AuraEnabled public String  quoteType;
        @AuraEnabled public String  fareCode;
        @AuraEnabled public String  diningTime;
        @AuraEnabled public String  specialConsiderations;
        @AuraEnabled public String  bookingTag;
        @AuraEnabled public Decimal originalTotal;
        @AuraEnabled public Decimal currentBalance;
        @AuraEnabled public Decimal cruiseTotal;
        @AuraEnabled public Decimal cruiseLineTotalFare;
        @AuraEnabled public Decimal cruzyCruiseRate;
        @AuraEnabled public Decimal cruzyTotalFare;
        @AuraEnabled public Decimal cruiseLineCruiseRate;
        @AuraEnabled public Decimal savings;
        @AuraEnabled public Decimal markUp;
        @AuraEnabled public Decimal markUpPercent;
        @AuraEnabled public Decimal pricePerPersonDay;
        @AuraEnabled public Date    paymentDate;
        @AuraEnabled public Id      contactId;
        @AuraEnabled public String  contactName;
        @AuraEnabled public Id      accountId;
        @AuraEnabled public String  accountName;
        @AuraEnabled public Id      rewardId;
        @AuraEnabled public String  rewardName;
        @AuraEnabled public String  rewardStatus;
        @AuraEnabled public String  odysseusTransactionId;
        @AuraEnabled public String  odysseusConfirmation;
        @AuraEnabled public String  odysseusStatus;
        @AuraEnabled public String  odysseusPackageId;
        @AuraEnabled public Boolean fromOdysseus;
        @AuraEnabled public List<AddOnItem>   addOns;
        @AuraEnabled public List<PaymentItem> payments;
    }

    public class AddOnItem {
        @AuraEnabled public Id      id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  addonType;
        @AuraEnabled public Decimal amount;
    }

    public class PaymentItem {
        @AuraEnabled public Id      id;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Date    paymentDate;
        @AuraEnabled public String  note;
        @AuraEnabled public String  paymentType;
        @AuraEnabled public String  source;
    }
}
