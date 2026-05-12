public with sharing class BookingOverviewController {
    @AuraEnabled(cacheable=true)
    public static BookingDetails getBookingDetails(Id bookingId) {
        BookingDetails details = new BookingDetails();
        
        Booking__c booking = [
            SELECT Id, Name, Status__c, Contact__c, Account__c,
                   Cruise_Name__c, Ship__c, Cruise_Line__c, Departure_Date__c,
                   Departure_Port__c, Duration_Nights__c, Itinerary__c,
                   Cabin_Category__c, Cabin_Number__c, Deck__c, PAX_Count__c,
                   Original_Cruise_Total__c, Current_Balance_Due__c, Payment_Date__c,
                   Odysseus_Transaction_ID__c, Odysseus_Confirmation__c, Odysseus_Status__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];
        
        if (booking != null) {
            details.id = booking.Id;
            details.name = booking.Name;
            details.status = booking.Status__c;
            details.contactId = booking.Contact__c;
            details.accountId = booking.Account__c;
            details.cruiseName = booking.Cruise_Name__c;
            details.ship = booking.Ship__c;
            details.cruiseLine = booking.Cruise_Line__c;
            details.departureDate = formatDate(booking.Departure_Date__c);
            details.departurePort = booking.Departure_Port__c;
            details.duration = String.valueOf(booking.Duration_Nights__c);
            details.itinerary = booking.Itinerary__c;
            details.cabinCategory = booking.Cabin_Category__c;
            details.cabinNumber = booking.Cabin_Number__c;
            details.deck = booking.Deck__c;
            details.paxCount = String.valueOf(booking.PAX_Count__c);
            details.originalTotal = formatCurrency(booking.Original_Cruise_Total__c);
            details.currentBalance = formatCurrency(booking.Current_Balance_Due__c);
            details.paymentDate = formatDate(booking.Payment_Date__c);
            details.odysseusTransactionId = booking.Odysseus_Transaction_ID__c;
            details.odysseusConfirmation = booking.Odysseus_Confirmation__c;
            details.odysseusStatus = booking.Odysseus_Status__c;
            details.fromOdysseus = booking.Odysseus_Transaction_ID__c != null;
        }
        
        return details;
    }
    
    private static String formatDate(Date dateValue) {
        if (dateValue == null) return '';
        return dateValue.format();
    }
    
    private static String formatCurrency(Decimal value) {
        if (value == null) return '$0.00';
        return '$' + value.setScale(2).format();
    }
    
    public class BookingDetails {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public Id contactId;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String cruiseName;
        @AuraEnabled public String ship;
        @AuraEnabled public String cruiseLine;
        @AuraEnabled public String departureDate;
        @AuraEnabled public String departurePort;
        @AuraEnabled public String duration;
        @AuraEnabled public String itinerary;
        @AuraEnabled public String cabinCategory;
        @AuraEnabled public String cabinNumber;
        @AuraEnabled public String deck;
        @AuraEnabled public String paxCount;
        @AuraEnabled public String originalTotal;
        @AuraEnabled public String currentBalance;
        @AuraEnabled public String paymentDate;
        @AuraEnabled public String odysseusTransactionId;
        @AuraEnabled public String odysseusConfirmation;
        @AuraEnabled public String odysseusStatus;
        @AuraEnabled public Boolean fromOdysseus;
    }
}
