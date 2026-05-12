// PART 2: Bookings + Payments + Add-Ons
// Requires Part 1 to be run first

// Re-query contacts and rewards by unique identifiers
Contact c01=[SELECT Id FROM Contact WHERE Email='scotty.marshfield@gmail.com' LIMIT 1];
Contact c02=[SELECT Id FROM Contact WHERE Email='jen.henderson@outlook.com' AND FirstName='Jennifer' LIMIT 1];
Contact c03=[SELECT Id FROM Contact WHERE Email='marcus.kowalski@comcast.net' LIMIT 1];
Contact c04=[SELECT Id FROM Contact WHERE Email='ltran.travels@gmail.com' LIMIT 1];
Contact c05=[SELECT Id FROM Contact WHERE Email='rdelgado@hotmail.com' LIMIT 1];
Contact c06=[SELECT Id FROM Contact WHERE Email='dfontaine@gmail.com' LIMIT 1];
Contact c08=[SELECT Id FROM Contact WHERE Email='pwhitmore@aol.com' LIMIT 1];
Contact c09=[SELECT Id FROM Contact WHERE Email='raj.patel@gmail.com' LIMIT 1];
Contact c10=[SELECT Id FROM Contact WHERE Email='mainguyen88@gmail.com' LIMIT 1];
Contact c11=[SELECT Id FROM Contact WHERE Email='crivera@outlook.com' LIMIT 1];
Contact c13=[SELECT Id FROM Contact WHERE Email='tdrummond@comcast.net' LIMIT 1];
Contact c14=[SELECT Id FROM Contact WHERE Email='shonda.leake@gmail.com' LIMIT 1];
Contact c15=[SELECT Id FROM Contact WHERE Email='gsorensen@northwestelectric.com' LIMIT 1];
Contact c17=[SELECT Id FROM Contact WHERE Email='jblackwell@gmail.com' LIMIT 1];
Contact c18=[SELECT Id FROM Contact WHERE Email='tamara.pruitt@yahoo.com' LIMIT 1];
Contact c20=[SELECT Id FROM Contact WHERE Email='wtillman@gmail.com' LIMIT 1];

Reward__c r01=[SELECT Id FROM Reward__c WHERE Name='HOL-OR-102838' LIMIT 1];
Reward__c r02=[SELECT Id FROM Reward__c WHERE Name='CAP-ONE-449821' LIMIT 1];
Reward__c r04=[SELECT Id FROM Reward__c WHERE Name='CHI-SAP-330012' LIMIT 1];
Reward__c r05=[SELECT Id FROM Reward__c WHERE Name='MAR-BON-551243' LIMIT 1];
Reward__c r07=[SELECT Id FROM Reward__c WHERE Name='SAM-PRO-882901' LIMIT 1];

// Bookings
Booking__c b01=new Booking__c(Name='TC49N0',Contact__c=c01.Id,Status__c='Booking',PAX_Count__c=3,Departure_Date__c=Date.newInstance(2026,11,9),Departure_Port__c='Jacksonville, FL',Ship__c='Carnival Elation',Cabin_Category__c='4C-Interior',Itinerary__c='Bahamas',Quote_Type__c='Reward',Original_Cruise_Total__c=766.00,Current_Balance_Due__c=316.00,Reward__c=r01.Id,Payment_Date__c=Date.newInstance(2026,3,3));
Booking__c b01q=new Booking__c(Name='Q-TC49N0-ALT',Contact__c=c01.Id,Status__c='Quote',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2026,11,9),Departure_Port__c='Port Canaveral, FL',Ship__c='Carnival Glory',Cabin_Category__c='4E-Interior',Itinerary__c='Bahamas',Quote_Type__c='Reward',Original_Cruise_Total__c=548.64,Current_Balance_Due__c=548.64,Reward__c=r01.Id);
Booking__c b02=new Booking__c(Name='Q-JH8821',Contact__c=c02.Id,Status__c='Quote',PAX_Count__c=4,Departure_Date__c=Date.newInstance(2026,8,15),Departure_Port__c='Jacksonville, FL',Ship__c='Carnival Elation',Cabin_Category__c='6A-Oceanview',Itinerary__c='Bahamas',Quote_Type__c='Reward',Original_Cruise_Total__c=1248.00,Current_Balance_Due__c=1248.00,Reward__c=r02.Id);
Booking__c b03a=new Booking__c(Name='MK-HIST-001',Contact__c=c03.Id,Status__c='Completed',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2023,10,7),Departure_Port__c='Miami, FL',Ship__c='Carnival Magic',Cabin_Category__c='8C-Balcony',Itinerary__c='Caribbean - Eastern',Quote_Type__c='Reward',Original_Cruise_Total__c=1890.00,Current_Balance_Due__c=0,Payment_Date__c=Date.newInstance(2023,8,1));
Booking__c b03b=new Booking__c(Name='MK-HIST-002',Contact__c=c03.Id,Status__c='Completed',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2024,7,14),Departure_Port__c='Galveston, TX',Ship__c='Carnival Vista',Cabin_Category__c='8D-Balcony',Itinerary__c='Caribbean - Western',Quote_Type__c='Member',Original_Cruise_Total__c=2240.00,Current_Balance_Due__c=0,Payment_Date__c=Date.newInstance(2024,5,10));
Booking__c b03c=new Booking__c(Name='MK-2026-001',Contact__c=c03.Id,Status__c='Booking',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2026,6,21),Departure_Port__c='Miami, FL',Ship__c='Carnival Celebration',Cabin_Category__c='JS-Junior Suite',Itinerary__c='Caribbean - Eastern',Quote_Type__c='Cruzy+ Member',Original_Cruise_Total__c=3180.00,Current_Balance_Due__c=1590.00,Payment_Date__c=Date.newInstance(2026,2,14));
Booking__c b04=new Booking__c(Name='Q-LT2026',Contact__c=c04.Id,Status__c='Quote',PAX_Count__c=1,Departure_Date__c=Date.newInstance(2026,9,6),Departure_Port__c='Port Canaveral, FL',Ship__c='Carnival Horizon',Cabin_Category__c='4J-Interior',Itinerary__c='Caribbean - Eastern',Quote_Type__c='Cruzy+ Member',Original_Cruise_Total__c=789.00,Current_Balance_Due__c=789.00);
Booking__c b05a=new Booking__c(Name='RD-HIST-003',Contact__c=c05.Id,Status__c='Completed',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2024,12,7),Departure_Port__c='Galveston, TX',Ship__c='Carnival Jubilee',Cabin_Category__c='8E-Balcony',Itinerary__c='Caribbean - Western',Quote_Type__c='Member',Original_Cruise_Total__c=2890.00,Current_Balance_Due__c=0,Payment_Date__c=Date.newInstance(2024,10,1));
Booking__c b05b=new Booking__c(Name='RD-2026-HOLD',Contact__c=c05.Id,Status__c='Quote',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2026,12,12),Departure_Port__c='New Orleans, LA',Ship__c='Carnival Horizon',Cabin_Category__c='8B-Balcony',Itinerary__c='Caribbean - Western',Quote_Type__c='Member',Original_Cruise_Total__c=3100.00,Current_Balance_Due__c=3100.00);
Booking__c b06=new Booking__c(Name='Q-DF2026',Contact__c=c06.Id,Status__c='Quote',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2026,10,18),Departure_Port__c='New Orleans, LA',Ship__c='Carnival Valor',Cabin_Category__c='4E-Interior',Itinerary__c='Caribbean - Western',Quote_Type__c='Cruzy+ Member',Original_Cruise_Total__c=678.00,Current_Balance_Due__c=678.00);
Booking__c b08a=new Booking__c(Name='PW-HIST-004',Contact__c=c08.Id,Status__c='Completed',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2023,2,12),Departure_Port__c='Miami, FL',Ship__c='Carnival Magic',Cabin_Category__c='GS-Grand Suite',Itinerary__c='Caribbean - Eastern',Quote_Type__c='Member',Original_Cruise_Total__c=4200.00,Current_Balance_Due__c=0,Payment_Date__c=Date.newInstance(2022,12,1));
Booking__c b08b=new Booking__c(Name='PW-2026-001',Contact__c=c08.Id,Status__c='Booking',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2026,12,5),Departure_Port__c='Miami, FL',Ship__c='Carnival Jubilee',Cabin_Category__c='OS-Ocean Suite',Itinerary__c='Caribbean - Southern',Quote_Type__c='Cruzy+ Member',Original_Cruise_Total__c=5600.00,Current_Balance_Due__c=2800.00,Payment_Date__c=Date.newInstance(2026,3,5));
Booking__c b09=new Booking__c(Name='Q-RP2026',Contact__c=c09.Id,Status__c='Quote',PAX_Count__c=4,Departure_Date__c=Date.newInstance(2026,7,4),Departure_Port__c='Port Canaveral, FL',Ship__c='Carnival Sunshine',Cabin_Category__c='4G-Interior',Itinerary__c='Bahamas',Quote_Type__c='Reward',Original_Cruise_Total__c=1560.00,Current_Balance_Due__c=1560.00,Reward__c=r04.Id);
Booking__c b10=new Booking__c(Name='Q-MN2026',Contact__c=c10.Id,Status__c='Quote',PAX_Count__c=1,Departure_Date__c=Date.newInstance(2026,11,22),Departure_Port__c='Miami, FL',Ship__c='Carnival Celebration',Cabin_Category__c='8A-Balcony',Itinerary__c='Caribbean - Eastern',Quote_Type__c='Cruzy+ Member',Original_Cruise_Total__c=1120.00,Current_Balance_Due__c=1120.00);
Booking__c b11=new Booking__c(Name='Q-CR2026',Contact__c=c11.Id,Status__c='Quote',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2026,6,7),Departure_Port__c='Jacksonville, FL',Ship__c='Carnival Elation',Cabin_Category__c='4C-Interior',Itinerary__c='Bahamas',Quote_Type__c='Reward',Original_Cruise_Total__c=698.00,Current_Balance_Due__c=698.00,Reward__c=r05.Id);
Booking__c b13a=new Booking__c(Name='TD-HIST-001',Contact__c=c13.Id,Status__c='Completed',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2024,12,14),Departure_Port__c='New Orleans, LA',Ship__c='Carnival Valor',Cabin_Category__c='8C-Balcony',Itinerary__c='Caribbean - Western',Quote_Type__c='Member',Original_Cruise_Total__c=2100.00,Current_Balance_Due__c=0,Payment_Date__c=Date.newInstance(2024,10,10));
Booking__c b13b=new Booking__c(Name='TD-2026-001',Contact__c=c13.Id,Status__c='Booking',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2026,12,13),Departure_Port__c='New Orleans, LA',Ship__c='Carnival Jubilee',Cabin_Category__c='8D-Balcony',Itinerary__c='Caribbean - Western',Quote_Type__c='Cruzy+ Member',Original_Cruise_Total__c=2340.00,Current_Balance_Due__c=1170.00,Payment_Date__c=Date.newInstance(2026,3,2));
Booking__c b14=new Booking__c(Name='Q-SL2026',Contact__c=c14.Id,Status__c='Quote',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2026,9,20),Departure_Port__c='Jacksonville, FL',Ship__c='Carnival Elation',Cabin_Category__c='4E-Interior',Itinerary__c='Bahamas',Quote_Type__c='Cruzy+ Member',Original_Cruise_Total__c=598.00,Current_Balance_Due__c=598.00);
Booking__c b15a=new Booking__c(Name='GS-HIST-001',Contact__c=c15.Id,Status__c='Completed',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2024,8,11),Departure_Port__c='Tampa, FL',Ship__c='Carnival Radiance',Cabin_Category__c='8B-Balcony',Itinerary__c='Caribbean - Eastern',Quote_Type__c='Member',Original_Cruise_Total__c=2050.00,Current_Balance_Due__c=0,Payment_Date__c=Date.newInstance(2024,6,1));
Booking__c b15b=new Booking__c(Name='GS-2026-001',Contact__c=c15.Id,Status__c='Quote',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2026,7,19),Departure_Port__c='Galveston, TX',Ship__c='Carnival Valor',Cabin_Category__c='4A-Interior',Itinerary__c='Alaska',Quote_Type__c='Cruzy+ Member',Original_Cruise_Total__c=1980.00,Current_Balance_Due__c=1980.00);
Booking__c b17=new Booking__c(Name='JB-2026-001',Contact__c=c17.Id,Status__c='Booking',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2026,7,12),Departure_Port__c='Norfolk, VA',Ship__c='Carnival Radiance',Cabin_Category__c='8C-Balcony',Itinerary__c='Alaska',Quote_Type__c='Cruzy+ Member',Original_Cruise_Total__c=3450.00,Current_Balance_Due__c=1725.00,Payment_Date__c=Date.newInstance(2026,3,20));
Booking__c b18a=new Booking__c(Name='TP-HIST-001',Contact__c=c18.Id,Status__c='Completed',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2023,5,21),Departure_Port__c='New Orleans, LA',Ship__c='Carnival Glory',Cabin_Category__c='4C-Interior',Itinerary__c='Bahamas',Quote_Type__c='Member',Original_Cruise_Total__c=980.00,Current_Balance_Due__c=0,Payment_Date__c=Date.newInstance(2023,3,10));
Booking__c b20=new Booking__c(Name='WT-2026-001',Contact__c=c20.Id,Status__c='Booking',PAX_Count__c=2,Departure_Date__c=Date.newInstance(2026,10,4),Departure_Port__c='New Orleans, LA',Ship__c='Carnival Valor',Cabin_Category__c='8A-Balcony',Itinerary__c='Caribbean - Western',Quote_Type__c='Reward',Original_Cruise_Total__c=1840.00,Current_Balance_Due__c=920.00,Reward__c=r07.Id,Payment_Date__c=Date.newInstance(2026,3,17));
insert new List<Booking__c>{b01,b01q,b02,b03a,b03b,b03c,b04,b05a,b05b,b06,b08a,b08b,b09,b10,b11,b13a,b13b,b14,b15a,b15b,b17,b18a,b20};

// Booking Payments
insert new List<Booking_Payment__c>{
    new Booking_Payment__c(Booking__c=b01.Id,Amount__c=450.00,Payment_Date__c=Date.newInstance(2026,3,3),Note__c='Initial deposit - Visa ending 4821'),
    new Booking_Payment__c(Booking__c=b03a.Id,Amount__c=1890.00,Payment_Date__c=Date.newInstance(2023,8,1),Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b03b.Id,Amount__c=2240.00,Payment_Date__c=Date.newInstance(2024,5,10),Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b03c.Id,Amount__c=1590.00,Payment_Date__c=Date.newInstance(2026,2,14),Note__c='50% deposit - Anniversary cruise'),
    new Booking_Payment__c(Booking__c=b05a.Id,Amount__c=2890.00,Payment_Date__c=Date.newInstance(2024,10,1),Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b08a.Id,Amount__c=4200.00,Payment_Date__c=Date.newInstance(2022,12,1),Note__c='Paid in full - suite upgrade'),
    new Booking_Payment__c(Booking__c=b08b.Id,Amount__c=2800.00,Payment_Date__c=Date.newInstance(2026,3,5),Note__c='50% deposit - Ocean Suite'),
    new Booking_Payment__c(Booking__c=b13a.Id,Amount__c=2100.00,Payment_Date__c=Date.newInstance(2024,10,10),Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b13b.Id,Amount__c=1170.00,Payment_Date__c=Date.newInstance(2026,3,2),Note__c='Deposit - auto renewal customer'),
    new Booking_Payment__c(Booking__c=b15a.Id,Amount__c=2050.00,Payment_Date__c=Date.newInstance(2024,6,1),Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b17.Id,Amount__c=1725.00,Payment_Date__c=Date.newInstance(2026,3,20),Note__c='50% deposit - Alaska cruise'),
    new Booking_Payment__c(Booking__c=b18a.Id,Amount__c=980.00,Payment_Date__c=Date.newInstance(2023,3,10),Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b20.Id,Amount__c=920.00,Payment_Date__c=Date.newInstance(2026,3,17),Note__c='50% deposit - Sam\'s Club reward')
};

// Membership Payments
Membership__c m01=[SELECT Id FROM Membership__c WHERE Name='CRZ001' LIMIT 1];
Membership__c m02=[SELECT Id FROM Membership__c WHERE Name='CRZ002' LIMIT 1];
Membership__c m03=[SELECT Id FROM Membership__c WHERE Name='CRZ003' LIMIT 1];
Membership__c m05=[SELECT Id FROM Membership__c WHERE Name='CRZ005' LIMIT 1];
Membership__c m06=[SELECT Id FROM Membership__c WHERE Name='CRZ006' LIMIT 1];
Membership__c m07=[SELECT Id FROM Membership__c WHERE Name='CRZ007' LIMIT 1];
Membership__c m08=[SELECT Id FROM Membership__c WHERE Name='CRZ008' LIMIT 1];
Membership__c m09=[SELECT Id FROM Membership__c WHERE Name='CRZ009' LIMIT 1];
Membership__c m10=[SELECT Id FROM Membership__c WHERE Name='CRZ010' LIMIT 1];
Membership__c m11=[SELECT Id FROM Membership__c WHERE Name='CRZ011' LIMIT 1];
Membership__c m12=[SELECT Id FROM Membership__c WHERE Name='CRZ012' LIMIT 1];
Membership__c m13=[SELECT Id FROM Membership__c WHERE Name='CRZ013' LIMIT 1];
insert new List<Membership_Payment__c>{
    new Membership_Payment__c(Membership__c=m01.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2025,5,10),Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m01.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2024,5,10),Renewal_Year__c=2024),
    new Membership_Payment__c(Membership__c=m02.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2025,3,15),Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m02.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2024,3,15),Renewal_Year__c=2024),
    new Membership_Payment__c(Membership__c=m02.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2023,3,15),Renewal_Year__c=2023),
    new Membership_Payment__c(Membership__c=m03.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2026,1,12),Renewal_Year__c=2026),
    new Membership_Payment__c(Membership__c=m05.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2026,3,10),Renewal_Year__c=2026),
    new Membership_Payment__c(Membership__c=m06.Id,Amount_Paid__c=199.00,Date_Paid__c=Date.newInstance(2025,11,20),Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m07.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2026,2,25),Renewal_Year__c=2026),
    new Membership_Payment__c(Membership__c=m08.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2025,1,15),Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m09.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2026,3,14),Renewal_Year__c=2026),
    new Membership_Payment__c(Membership__c=m10.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2025,7,4),Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m11.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2025,4,1),Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m12.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2026,3,21),Renewal_Year__c=2026),
    new Membership_Payment__c(Membership__c=m13.Id,Amount_Paid__c=129.00,Date_Paid__c=Date.newInstance(2026,3,17),Renewal_Year__c=2026)
};

// Add-Ons
insert new List<Add_On__c>{
    new Add_On__c(Name='Travel Insurance - Marshfield',Booking__c=b01.Id,Add_On_Type__c='Travel Insurance',Amount__c=89.00),
    new Add_On__c(Name='Nassau Shore Excursion - Kowalski',Booking__c=b03c.Id,Add_On_Type__c='Shore Excursion',Amount__c=220.00),
    new Add_On__c(Name='Cheers Drink Package - Kowalski',Booking__c=b03c.Id,Add_On_Type__c='Drink Package',Amount__c=318.00),
    new Add_On__c(Name='Travel Insurance - Kowalski',Booking__c=b03c.Id,Add_On_Type__c='Travel Insurance',Amount__c=99.00),
    new Add_On__c(Name='Specialty Dining - Kowalski',Booking__c=b03c.Id,Add_On_Type__c='Specialty Dining',Amount__c=150.00),
    new Add_On__c(Name='Shore Excursion St Lucia - Whitmore',Booking__c=b08b.Id,Add_On_Type__c='Shore Excursion',Amount__c=340.00),
    new Add_On__c(Name='Cheers Package - Whitmore',Booking__c=b08b.Id,Add_On_Type__c='Drink Package',Amount__c=490.00),
    new Add_On__c(Name='Travel Insurance - Whitmore',Booking__c=b08b.Id,Add_On_Type__c='Travel Insurance',Amount__c=149.00),
    new Add_On__c(Name='Specialty Dining - Whitmore',Booking__c=b08b.Id,Add_On_Type__c='Specialty Dining',Amount__c=200.00),
    new Add_On__c(Name='Travel Insurance - Drummond',Booking__c=b13b.Id,Add_On_Type__c='Travel Insurance',Amount__c=89.00),
    new Add_On__c(Name='Cozumel Excursion - Drummond',Booking__c=b13b.Id,Add_On_Type__c='Shore Excursion',Amount__c=180.00),
    new Add_On__c(Name='Glacier Bay Excursion - Blackwell',Booking__c=b17.Id,Add_On_Type__c='Shore Excursion',Amount__c=290.00),
    new Add_On__c(Name='Travel Insurance - Blackwell',Booking__c=b17.Id,Add_On_Type__c='Travel Insurance',Amount__c=129.00),
    new Add_On__c(Name='SeaTac Airport Transfer - Blackwell',Booking__c=b17.Id,Add_On_Type__c='Transfer',Amount__c=120.00),
    new Add_On__c(Name='Travel Insurance - Tillman',Booking__c=b20.Id,Add_On_Type__c='Travel Insurance',Amount__c=89.00),
    new Add_On__c(Name='Cozumel Excursion - Tillman',Booking__c=b20.Id,Add_On_Type__c='Shore Excursion',Amount__c=160.00)
};
System.debug('Part 2 done: 23 Bookings, 13 Booking Payments, 15 Membership Payments, 16 Add-Ons');
