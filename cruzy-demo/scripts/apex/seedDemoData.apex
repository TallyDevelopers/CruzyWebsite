/**
 * Cruzy Demo Data - Full Seed Script
 * 20 Contacts across all customer types, journey stages, and duplicate scenarios
 * Run: sf apex run --file scripts/apex/seedDemoData.apex --target-org cruzy-demo
 */

// ─── Wipe existing demo data ──────────────────────────────────────────────────
List<Contact> old = [SELECT Id FROM Contact WHERE LastName IN (
    'Marshfield','Henderson','Kowalski','Tran','Delgado','Fontaine','Okafor',
    'Whitmore','Patel','Nguyen','Rivera','Castellano','Drummond','Leake',
    'Sorensen','Yates','Blackwell','Pruitt','Hargrove','Tillman',
    'Prescott','Michaels','Garrett'
)];
if (!old.isEmpty()) delete old;

// ─── 20 Contacts ─────────────────────────────────────────────────────────────

// 1 - Scott Marshfield — Full profile, Cruzy+ member, active booking (B2B Reward → Member)
Contact c01 = new Contact(
    FirstName='Scott', LastName='Marshfield',
    Email='scotty.marshfield@gmail.com', Phone='5712148590',
    Alt_Phone__c='5712148591', Alt_Email__c='s.marshfield@comcast.net',
    MailingStreet='8225 Keeler Street', MailingCity='Alexandria',
    MailingState='VA', MailingPostalCode='22309', MailingCountry='United States',
    Timezone__c='Eastern - Add 1 Hr',
    Primary_DOB__c=Date.newInstance(1978,4,12),
    Spouse_Significant_Other__c='Linda Marshfield',
    Secondary_DOB__c=Date.newInstance(1980,7,22),
    VIFP_Number__c='VIF-882341', VIFP_Level__c='Gold',
    VIFP_Belongs_To__c='Scott Marshfield',
    VIFP_Number_Secondary__c='VIF-882342', VIFP_Level_Secondary__c='Red',
    VIFP_Secondary_Belongs_To__c='Linda Marshfield',
    Customer_Source__c='B2B Reward',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_Pitched__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ001',
    Customer_Notes__c='[MAR-22-26] Booked Bahamas 3PAX. Wife wants OV cabin next time. Good upsell candidate for drink package.'
);

// 2 - DUPLICATE of Scott (same last name + street, different email/phone — wife called in)
Contact c01d = new Contact(
    FirstName='Scott', LastName='Marshfield',
    Email='smarshfield@yahoo.com', Phone='7035551234',
    MailingStreet='8225 Keeler St', MailingCity='Alexandria',
    MailingState='VA', MailingPostalCode='22309',
    Timezone__c='Eastern - Add 1 Hr',
    Customer_Source__c='Cruise Club',
    Customer_Notes__c='[FEB-10-26] Wife called in. Said husband had booked before but she didn\'t have his info.'
);

// 3 - Jennifer Henderson — B2B Reward, active quote, pitched Cruzy+ not enrolled yet
Contact c02 = new Contact(
    FirstName='Jennifer', LastName='Henderson',
    Email='jen.henderson@outlook.com', Phone='8885553201',
    Alt_Phone__c='9185559876',
    MailingStreet='410 Riverside Blvd', MailingCity='Tulsa',
    MailingState='OK', MailingPostalCode='74103',
    Timezone__c='Central',
    Primary_DOB__c=Date.newInstance(1985,11,3),
    Spouse_Significant_Other__c='Mark Henderson',
    VIFP_Number__c='VIF-334892', VIFP_Level__c='Red',
    VIFP_Belongs_To__c='Jennifer Henderson',
    Customer_Source__c='B2B Reward',
    Cruzy_Plus_Pitched__c=true, Cruzy_Plus_Enrolled__c=false,
    Customer_Notes__c='[MAR-01-26] Capital One Rewards. Interested Bahamas JAX 4PAX. Has 2 kids. Pitched Cruzy+ - thinking about it.'
);

// 4 - DUPLICATE of Jennifer (same email, came in through Cruzy.com separately)
Contact c02d = new Contact(
    FirstName='Jen', LastName='Henderson',
    Email='jen.henderson@outlook.com', Phone='9185559876',
    Customer_Source__c='Cruzy.com Direct',
    Customer_Notes__c='[MAR-20-26] Registered online at cruzy.com - self-signup.'
);

// 5 - Marcus Kowalski — Platinum VIFP, 3 cruises, full journey (Reward → Member → Cruzy+)
Contact c03 = new Contact(
    FirstName='Marcus', LastName='Kowalski',
    Email='marcus.kowalski@comcast.net', Phone='3125558823',
    Alt_Phone__c='3125554411', Alt_Email__c='m.kowalski@gmail.com',
    MailingStreet='1701 N Lake Shore Dr Apt 12B', MailingCity='Chicago',
    MailingState='IL', MailingPostalCode='60614',
    Timezone__c='Central',
    Primary_DOB__c=Date.newInstance(1973,2,28),
    Spouse_Significant_Other__c='Rachel Kowalski',
    Secondary_DOB__c=Date.newInstance(1975,9,14),
    VIFP_Number__c='VIF-662910', VIFP_Level__c='Platinum',
    VIFP_Belongs_To__c='Marcus Kowalski',
    VIFP_Number_Secondary__c='VIF-662911', VIFP_Level_Secondary__c='Gold',
    VIFP_Secondary_Belongs_To__c='Rachel Kowalski',
    Customer_Source__c='Cruise Club',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_Pitched__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ002',
    Referral_Reward__c='Referred by: Patricia Wells (CRZ019)',
    Customer_Notes__c='[MAR-15-26] Confirmed June cruise. Wants travel insurance. Anniversary trip - go the extra mile.'
);

// 6 - Linda Tran — B2C Cruzy.com signup, new member, first booking quote
Contact c04 = new Contact(
    FirstName='Linda', LastName='Tran',
    Email='ltran.travels@gmail.com', Phone='4155550091',
    MailingStreet='782 Castro Street', MailingCity='San Francisco',
    MailingState='CA', MailingPostalCode='94114',
    Timezone__c='Pacific - Subtract 2 Hrs',
    Primary_DOB__c=Date.newInstance(1990,6,18),
    Customer_Source__c='Cruzy.com Direct',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_Pitched__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ003',
    Customer_Notes__c='[JAN-12-26] Signed up online. First-time cruiser. Super excited about Caribbean.'
);

// 7 - Robert Delgado — Diamond VIFP, lapsed member, high-value save opportunity
Contact c05 = new Contact(
    FirstName='Robert', LastName='Delgado',
    Email='rdelgado@hotmail.com', Phone='7135552277',
    Alt_Phone__c='7135550012',
    MailingStreet='330 Main Street', MailingCity='Houston',
    MailingState='TX', MailingPostalCode='77002',
    Timezone__c='Central',
    Primary_DOB__c=Date.newInstance(1968,3,7),
    VIFP_Number__c='VIF-114422', VIFP_Level__c='Diamond',
    VIFP_Belongs_To__c='Robert Delgado',
    Customer_Source__c='Cruise Club',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_MBR_Number__c='CRZ004',
    Membership_On_Hold__c=true,
    Customer_Notes__c='[FEB-28-26] Membership lapsed. Left voicemail. 4 past cruises - do NOT lose this customer.',
    Do_Not_Call_Renewal__c=false
);

// 8 - Danielle Fontaine — Social media lead, new member, first quote in progress
Contact c06 = new Contact(
    FirstName='Danielle', LastName='Fontaine',
    Email='dfontaine@gmail.com', Phone='5045551847',
    MailingStreet='2210 Magazine Street', MailingCity='New Orleans',
    MailingState='LA', MailingPostalCode='70130',
    Timezone__c='Central',
    Primary_DOB__c=Date.newInstance(1992,8,25),
    Customer_Source__c='Social Media',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_Pitched__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ005',
    Customer_Notes__c='[MAR-10-26] Found us on Facebook ad. Super engaged. Wants Western Caribbean, 2PAX.'
);

// 9 - Theo Okafor — Referral, new reward, hasn\'t booked yet
Contact c07 = new Contact(
    FirstName='Theo', LastName='Okafor',
    Email='tokafor@yahoo.com', Phone='4045558833',
    MailingStreet='1540 Peachtree St NW', MailingCity='Atlanta',
    MailingState='GA', MailingPostalCode='30309',
    Timezone__c='Eastern - Add 1 Hr',
    Primary_DOB__c=Date.newInstance(1987,1,19),
    Customer_Source__c='Referral',
    Cruzy_Plus_Pitched__c=true, Cruzy_Plus_Enrolled__c=false,
    Customer_Notes__c='[MAR-18-26] Referred by Marcus Kowalski (CRZ002). Has reward from Bass Pro. Wants Bahamas.'
);

// 10 - Patricia Whitmore — Long-time member, Diamond VIFP, biennial plan, 5 cruises
Contact c08 = new Contact(
    FirstName='Patricia', LastName='Whitmore',
    Email='pwhitmore@aol.com', Phone='6155559944',
    Alt_Phone__c='6155551122',
    MailingStreet='4401 Harding Pike', MailingCity='Nashville',
    MailingState='TN', MailingPostalCode='37205',
    Timezone__c='Central',
    Primary_DOB__c=Date.newInstance(1960,5,30),
    Spouse_Significant_Other__c='Gerald Whitmore',
    Secondary_DOB__c=Date.newInstance(1958,11,4),
    VIFP_Number__c='VIF-009821', VIFP_Level__c='Diamond Plus',
    VIFP_Belongs_To__c='Patricia Whitmore',
    VIFP_Number_Secondary__c='VIF-009822', VIFP_Level_Secondary__c='Diamond',
    VIFP_Secondary_Belongs_To__c='Gerald Whitmore',
    Customer_Source__c='Cruise Club',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_Pitched__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ006',
    Customer_Notes__c='[MAR-05-26] Patricia is our most loyal customer. 5 cruises, always books suites. Handle with care.'
);

// 11 - Raj Patel — B2B Reward (Chase Sapphire), first contact, active quote
Contact c09 = new Contact(
    FirstName='Raj', LastName='Patel',
    Email='raj.patel@gmail.com', Phone='6265557712',
    MailingStreet='819 S Lake Ave', MailingCity='Pasadena',
    MailingState='CA', MailingPostalCode='91106',
    Timezone__c='Pacific - Subtract 2 Hrs',
    Primary_DOB__c=Date.newInstance(1983,9,11),
    Spouse_Significant_Other__c='Priya Patel',
    Customer_Source__c='B2B Reward',
    Cruzy_Plus_Pitched__c=true, Cruzy_Plus_Enrolled__c=false,
    Customer_Notes__c='[MAR-12-26] Chase Sapphire reward. Wants Bahamas 4PAX. Pitched Cruzy+ hard - he was interested.'
);

// 12 - Mai Nguyen — Cruzy.com Direct, new member, solo traveler
Contact c10 = new Contact(
    FirstName='Mai', LastName='Nguyen',
    Email='mainguyen88@gmail.com', Phone='7138884421',
    MailingStreet='2700 Post Oak Blvd', MailingCity='Houston',
    MailingState='TX', MailingPostalCode='77056',
    Timezone__c='Central',
    Primary_DOB__c=Date.newInstance(1988,3,22),
    Customer_Source__c='Cruzy.com Direct',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_Pitched__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ007',
    Customer_Notes__c='[FEB-25-26] Signed up direct. Solo cruiser. Interested in Eastern Caribbean 7-night.'
);

// 13 - Carlos Rivera — B2B Reward (Marriott Bonvoy), quote stage
Contact c11 = new Contact(
    FirstName='Carlos', LastName='Rivera',
    Email='crivera@outlook.com', Phone='7875559034',
    MailingStreet='100 Calle Comercio', MailingCity='San Juan',
    MailingState='PR', MailingPostalCode='00901',
    Timezone__c='Eastern - Add 1 Hr',
    Primary_DOB__c=Date.newInstance(1979,6,14),
    Spouse_Significant_Other__c='Ana Rivera',
    Customer_Source__c='B2B Reward',
    Spanish_Speaking__c=true,
    Cruzy_Plus_Pitched__c=false, Cruzy_Plus_Enrolled__c=false,
    Customer_Notes__c='[MAR-08-26] Marriott Bonvoy reward. Spanish preferred. Quote for Bahamas 2PAX.'
);

// 14 - Beth Castellano — Referral from Whitmore, brand new, just pitched
Contact c12 = new Contact(
    FirstName='Beth', LastName='Castellano',
    Email='bcastellano@icloud.com', Phone='3525551029',
    MailingStreet='301 SE 3rd Ave', MailingCity='Gainesville',
    MailingState='FL', MailingPostalCode='32601',
    Timezone__c='Eastern - Add 1 Hr',
    Customer_Source__c='Referral',
    Cruzy_Plus_Pitched__c=true, Cruzy_Plus_Enrolled__c=false,
    Customer_Notes__c='[MAR-19-26] Referred by Patricia Whitmore. First conversation. Very interested in Bahamas short cruise.',
    Referring_Contact__c=c08.Id
);

// 15 - Tony Drummond — B2B Reward, auto-renewal member, Gold VIFP
Contact c13 = new Contact(
    FirstName='Tony', LastName='Drummond',
    Email='tdrummond@comcast.net', Phone='2165553388',
    Alt_Phone__c='2165550011',
    MailingStreet='700 W St Clair Ave', MailingCity='Cleveland',
    MailingState='OH', MailingPostalCode='44113',
    Timezone__c='Eastern - Add 1 Hr',
    Primary_DOB__c=Date.newInstance(1970,12,1),
    Spouse_Significant_Other__c='Karen Drummond',
    VIFP_Number__c='VIF-441287', VIFP_Level__c='Gold',
    VIFP_Belongs_To__c='Tony Drummond',
    Customer_Source__c='Cruise Club',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_Pitched__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ008',
    Customer_Notes__c='[MAR-02-26] Loyal member 3 yrs. Auto-renews every year. Books Western Caribbean every December.'
);

// 16 - Shonda Leake — Social media, new member, first booking
Contact c14 = new Contact(
    FirstName='Shonda', LastName='Leake',
    Email='shonda.leake@gmail.com', Phone='4695557723',
    MailingStreet='5959 Royal Lane', MailingCity='Dallas',
    MailingState='TX', MailingPostalCode='75230',
    Timezone__c='Central',
    Primary_DOB__c=Date.newInstance(1995,2,14),
    Customer_Source__c='Social Media',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_Pitched__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ009',
    Customer_Notes__c='[MAR-14-26] Instagram ad. Excited first-timer. Wants Bahamas, budget-conscious.'
);

// 17 - Greg Sorensen — DUPLICATE of himself (called from work phone, new profile created)
Contact c15 = new Contact(
    FirstName='Greg', LastName='Sorensen',
    Email='gsorensen@northwestelectric.com', Phone='5033338812',
    Alt_Phone__c='5033338813',
    MailingStreet='1400 SW 5th Ave', MailingCity='Portland',
    MailingState='OR', MailingPostalCode='97201',
    Timezone__c='Pacific - Subtract 2 Hrs',
    Primary_DOB__c=Date.newInstance(1975,8,7),
    VIFP_Number__c='VIF-228834', VIFP_Level__c='Platinum',
    VIFP_Belongs_To__c='Greg Sorensen',
    Customer_Source__c='Cruise Club',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_Pitched__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ010',
    Customer_Notes__c='[FEB-15-26] Called from office line. 2 past cruises. Wants Alaska 4-night.'
);

// 18 - DUPLICATE of Greg Sorensen (personal email, different phone — same guy)
Contact c15d = new Contact(
    FirstName='Gregory', LastName='Sorensen',
    Email='gregsorensen@gmail.com', Phone='5039991122',
    MailingStreet='1400 SW Fifth Ave', MailingCity='Portland',
    MailingState='OR', MailingPostalCode='97201',
    Timezone__c='Pacific - Subtract 2 Hrs',
    Customer_Source__c='Cruise Club',
    Customer_Notes__c='[JAN-28-26] Called personal line. Said he\'d booked before but couldn\'t find his record.'
);

// 19 - Melissa Yates — B2B Reward, expired, follow-up needed
Contact c16 = new Contact(
    FirstName='Melissa', LastName='Yates',
    Email='myates@earthlink.net', Phone='5025558841',
    MailingStreet='922 Baxter Ave', MailingCity='Louisville',
    MailingState='KY', MailingPostalCode='40204',
    Timezone__c='Eastern - Add 1 Hr',
    Primary_DOB__c=Date.newInstance(1982,4,29),
    Customer_Source__c='B2B Reward',
    Cruzy_Plus_Pitched__c=true, Cruzy_Plus_Enrolled__c=false,
    Customer_Notes__c='[NOV-15-25] Had Capital One reward - expired before booking. Still interested. Call back spring 26.',
    BOLO__c=false,
    Six_Mo_No_Contact_Followup__c=true
);

// 20 - James Blackwell — Long-time member, upcoming Alaska cruise, full add-ons
Contact c17 = new Contact(
    FirstName='James', LastName='Blackwell',
    Email='jblackwell@gmail.com', Phone='2065551984',
    Alt_Phone__c='2065550092',
    MailingStreet='411 University St', MailingCity='Seattle',
    MailingState='WA', MailingPostalCode='98101',
    Timezone__c='Pacific - Subtract 2 Hrs',
    Primary_DOB__c=Date.newInstance(1966,10,5),
    Spouse_Significant_Other__c='Renee Blackwell',
    Secondary_DOB__c=Date.newInstance(1968,3,17),
    VIFP_Number__c='VIF-771009', VIFP_Level__c='Platinum',
    VIFP_Belongs_To__c='James Blackwell',
    Customer_Source__c='Cruise Club',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_Pitched__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ011',
    Customer_Notes__c='[MAR-20-26] Confirmed Alaska cruise July. Wants transfers from SeaTac + travel insurance.'
);

// 21 - Tamara Pruitt — Cancelled membership, needs win-back
Contact c18 = new Contact(
    FirstName='Tamara', LastName='Pruitt',
    Email='tamara.pruitt@yahoo.com', Phone='9014443322',
    MailingStreet='2100 Union Ave', MailingCity='Memphis',
    MailingState='TN', MailingPostalCode='38104',
    Timezone__c='Central',
    Primary_DOB__c=Date.newInstance(1977,7,21),
    Customer_Source__c='Cruise Club',
    Cruzy_Plus_Enrolled__c=false,
    Membership_On_Hold__c=false,
    Customer_Notes__c='[JAN-05-26] Cancelled membership - said she\'d think about rejoining. Had 2 cruises. Win-back target.'
);

// 22 - Devon Hargrove — B2C Direct, new, hasn\'t booked yet (early pipeline)
Contact c19 = new Contact(
    FirstName='Devon', LastName='Hargrove',
    Email='devon.hargrove@icloud.com', Phone='3124448876',
    MailingStreet='875 N Michigan Ave', MailingCity='Chicago',
    MailingState='IL', MailingPostalCode='60611',
    Timezone__c='Central',
    Customer_Source__c='Cruzy.com Direct',
    Cruzy_Plus_Enrolled__c=true, Cruzy_Plus_Pitched__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ012',
    Customer_Notes__c='[MAR-21-26] Just signed up online. No cruise history. Wants pricing info on Bahamas.'
);

// 23 - Willie Tillman — B2B Reward (Sam\'s Club promo), active + upsell pitched
Contact c20 = new Contact(
    FirstName='Willie', LastName='Tillman',
    Email='wtillman@gmail.com', Phone='2054449922',
    MailingStreet='3200 Cahaba Road', MailingCity='Birmingham',
    MailingState='AL', MailingPostalCode='35223',
    Timezone__c='Central',
    Primary_DOB__c=Date.newInstance(1964,1,30),
    Spouse_Significant_Other__c='Dorothy Tillman',
    VIFP_Number__c='VIF-556612', VIFP_Level__c='Gold',
    VIFP_Belongs_To__c='Willie Tillman',
    Customer_Source__c='B2B Reward',
    Cruzy_Plus_Pitched__c=true, Cruzy_Plus_Enrolled__c=true,
    Cruzy_Plus_MBR_Number__c='CRZ013',
    Customer_Notes__c='[MAR-17-26] Sam\'s Club promo. Retired couple. Wants Western Caribbean. Enrolled in Cruzy+ same call!'
);

insert new List<Contact>{
    c01, c01d, c02, c02d, c03, c04, c05, c06, c07, c08,
    c09, c10, c11, c12, c13, c14, c15, c15d, c16, c17, c18, c19, c20
};

// ─── Rewards ─────────────────────────────────────────────────────────────────

Reward__c r01 = new Reward__c(Name='HOL-OR-102838', Contact__c=c01.Id,
    Reward_Number__c='102838', Reward_Location__c='OR',
    Partner__c='Holiday Inn Rewards',
    Issue_Date__c=Date.newInstance(2025,9,25),
    Book_By_Date__c=Date.newInstance(2026,12,25),
    Expiration_Date__c=Date.newInstance(2027,3,25), Status__c='Active');

Reward__c r02 = new Reward__c(Name='CAP-ONE-449821', Contact__c=c02.Id,
    Reward_Number__c='449821', Reward_Location__c='CAP',
    Partner__c='Capital One Ventures',
    Issue_Date__c=Date.newInstance(2026,1,10),
    Book_By_Date__c=Date.newInstance(2026,10,10),
    Expiration_Date__c=Date.newInstance(2027,1,10), Status__c='Active');

Reward__c r03 = new Reward__c(Name='BAS-PRO-778312', Contact__c=c03.Id,
    Reward_Number__c='778312', Reward_Location__c='BP',
    Partner__c='Bass Pro Shops',
    Issue_Date__c=Date.newInstance(2023,6,1),
    Book_By_Date__c=Date.newInstance(2024,3,1),
    Expiration_Date__c=Date.newInstance(2024,6,1), Status__c='Used');

Reward__c r04 = new Reward__c(Name='CHI-SAP-330012', Contact__c=c09.Id,
    Reward_Number__c='330012', Reward_Location__c='CS',
    Partner__c='Chase Sapphire',
    Issue_Date__c=Date.newInstance(2026,2,1),
    Book_By_Date__c=Date.newInstance(2026,11,1),
    Expiration_Date__c=Date.newInstance(2027,2,1), Status__c='Active');

Reward__c r05 = new Reward__c(Name='MAR-BON-551243', Contact__c=c11.Id,
    Reward_Number__c='551243', Reward_Location__c='MB',
    Partner__c='Marriott Bonvoy',
    Issue_Date__c=Date.newInstance(2026,1,20),
    Book_By_Date__c=Date.newInstance(2026,9,20),
    Expiration_Date__c=Date.newInstance(2027,1,20), Status__c='Active');

Reward__c r06 = new Reward__c(Name='CAP-ONE-332218', Contact__c=c16.Id,
    Reward_Number__c='332218', Reward_Location__c='CAP',
    Partner__c='Capital One Ventures',
    Issue_Date__c=Date.newInstance(2025,3,1),
    Book_By_Date__c=Date.newInstance(2025,12,1),
    Expiration_Date__c=Date.newInstance(2026,3,1), Status__c='Expired',
    Six_Mo_No_Contact_Followup__c=true);

Reward__c r07 = new Reward__c(Name='SAM-PRO-882901', Contact__c=c20.Id,
    Reward_Number__c='882901', Reward_Location__c='SAM',
    Partner__c='Sam\'s Club Promotions',
    Issue_Date__c=Date.newInstance(2026,3,1),
    Book_By_Date__c=Date.newInstance(2026,12,31),
    Expiration_Date__c=Date.newInstance(2027,3,1), Status__c='Active');

Reward__c r08 = new Reward__c(Name='OKA-BAS-441002', Contact__c=c07.Id,
    Reward_Number__c='441002', Reward_Location__c='BP',
    Partner__c='Bass Pro Shops',
    Issue_Date__c=Date.newInstance(2026,2,15),
    Book_By_Date__c=Date.newInstance(2026,11,15),
    Expiration_Date__c=Date.newInstance(2027,2,15), Status__c='Active');

insert new List<Reward__c>{r01,r02,r03,r04,r05,r06,r07,r08};

// ─── Memberships ─────────────────────────────────────────────────────────────

Membership__c m01 = new Membership__c(Name='CRZ001', Contact__c=c01.Id,
    Status__c='Active', Partner__c='Cruzy.com Direct',
    Enroll_Date__c=Date.newInstance(2024,5,10),
    Last_Renewal_Date__c=Date.newInstance(2025,5,10),
    Expiration_Date__c=Date.newInstance(2026,5,10),
    Next_Billing_Date__c=Date.newInstance(2026,5,10),
    Auto_Renewal__c=true, Paid_Through__c=Date.newInstance(2026,5,10));

Membership__c m02 = new Membership__c(Name='CRZ002', Contact__c=c03.Id,
    Status__c='Active', Partner__c='Cruise Club Partner',
    Enroll_Date__c=Date.newInstance(2022,3,15),
    Last_Renewal_Date__c=Date.newInstance(2025,3,15),
    Expiration_Date__c=Date.newInstance(2026,3,15),
    Next_Billing_Date__c=Date.newInstance(2026,3,15),
    Auto_Renewal__c=true, Paid_Through__c=Date.newInstance(2026,3,15));

Membership__c m03 = new Membership__c(Name='CRZ003', Contact__c=c04.Id,
    Status__c='Active', Partner__c='Cruzy.com Direct',
    Enroll_Date__c=Date.newInstance(2026,1,12),
    Expiration_Date__c=Date.newInstance(2027,1,12),
    Next_Billing_Date__c=Date.newInstance(2027,1,12),
    Auto_Renewal__c=false, Paid_Through__c=Date.newInstance(2027,1,12));

Membership__c m04 = new Membership__c(Name='CRZ004', Contact__c=c05.Id,
    Status__c='Inactive - Need Payment', Partner__c='Cruise Club Partner',
    Enroll_Date__c=Date.newInstance(2020,8,1),
    Last_Renewal_Date__c=Date.newInstance(2025,8,1),
    Expiration_Date__c=Date.newInstance(2026,8,1),
    Next_Billing_Date__c=Date.today(),
    Auto_Renewal__c=false, Paid_Through__c=Date.newInstance(2025,8,1));

Membership__c m05 = new Membership__c(Name='CRZ005', Contact__c=c06.Id,
    Status__c='Active', Partner__c='Social Signup',
    Enroll_Date__c=Date.newInstance(2026,3,10),
    Expiration_Date__c=Date.newInstance(2027,3,10),
    Next_Billing_Date__c=Date.newInstance(2027,3,10),
    Auto_Renewal__c=false, Paid_Through__c=Date.newInstance(2027,3,10));

Membership__c m06 = new Membership__c(Name='CRZ006', Contact__c=c08.Id,
    Status__c='Active', Partner__c='Cruise Club Partner',
    Enroll_Date__c=Date.newInstance(2018,11,20),
    Last_Renewal_Date__c=Date.newInstance(2025,11,20),
    Expiration_Date__c=Date.newInstance(2027,11,20),
    Next_Billing_Date__c=Date.newInstance(2027,11,20),
    Auto_Renewal__c=true, Biennial__c=true,
    Paid_Through__c=Date.newInstance(2027,11,20));

Membership__c m07 = new Membership__c(Name='CRZ007', Contact__c=c10.Id,
    Status__c='Active', Partner__c='Cruzy.com Direct',
    Enroll_Date__c=Date.newInstance(2026,2,25),
    Expiration_Date__c=Date.newInstance(2027,2,25),
    Next_Billing_Date__c=Date.newInstance(2027,2,25),
    Auto_Renewal__c=false, Paid_Through__c=Date.newInstance(2027,2,25));

Membership__c m08 = new Membership__c(Name='CRZ008', Contact__c=c13.Id,
    Status__c='Active', Partner__c='Cruise Club Partner',
    Enroll_Date__c=Date.newInstance(2023,1,15),
    Last_Renewal_Date__c=Date.newInstance(2025,1,15),
    Expiration_Date__c=Date.newInstance(2026,1,15),
    Next_Billing_Date__c=Date.newInstance(2026,1,15),
    Auto_Renewal__c=true, Paid_Through__c=Date.newInstance(2026,1,15));

Membership__c m09 = new Membership__c(Name='CRZ009', Contact__c=c14.Id,
    Status__c='Active', Partner__c='Social Signup',
    Enroll_Date__c=Date.newInstance(2026,3,14),
    Expiration_Date__c=Date.newInstance(2027,3,14),
    Next_Billing_Date__c=Date.newInstance(2027,3,14),
    Auto_Renewal__c=false, Paid_Through__c=Date.newInstance(2027,3,14));

Membership__c m10 = new Membership__c(Name='CRZ010', Contact__c=c15.Id,
    Status__c='Active', Partner__c='Cruise Club Partner',
    Enroll_Date__c=Date.newInstance(2021,7,4),
    Last_Renewal_Date__c=Date.newInstance(2025,7,4),
    Expiration_Date__c=Date.newInstance(2026,7,4),
    Next_Billing_Date__c=Date.newInstance(2026,7,4),
    Auto_Renewal__c=true, Paid_Through__c=Date.newInstance(2026,7,4));

Membership__c m11 = new Membership__c(Name='CRZ011', Contact__c=c17.Id,
    Status__c='Active', Partner__c='Cruise Club Partner',
    Enroll_Date__c=Date.newInstance(2019,4,1),
    Last_Renewal_Date__c=Date.newInstance(2025,4,1),
    Expiration_Date__c=Date.newInstance(2026,4,1),
    Next_Billing_Date__c=Date.newInstance(2026,4,1),
    Auto_Renewal__c=true, Paid_Through__c=Date.newInstance(2026,4,1));

Membership__c m12 = new Membership__c(Name='CRZ012', Contact__c=c19.Id,
    Status__c='Active', Partner__c='Cruzy.com Direct',
    Enroll_Date__c=Date.newInstance(2026,3,21),
    Expiration_Date__c=Date.newInstance(2027,3,21),
    Next_Billing_Date__c=Date.newInstance(2027,3,21),
    Auto_Renewal__c=false, Paid_Through__c=Date.newInstance(2027,3,21));

Membership__c m13 = new Membership__c(Name='CRZ013', Contact__c=c20.Id,
    Status__c='Active', Partner__c='Cruzy.com Direct',
    Enroll_Date__c=Date.newInstance(2026,3,17),
    Expiration_Date__c=Date.newInstance(2027,3,17),
    Next_Billing_Date__c=Date.newInstance(2027,3,17),
    Auto_Renewal__c=false, Paid_Through__c=Date.newInstance(2027,3,17));

Membership__c m14 = new Membership__c(Name='CRZ-CXLD-018', Contact__c=c18.Id,
    Status__c='Cancelled', Partner__c='Cruise Club Partner',
    Enroll_Date__c=Date.newInstance(2022,9,1),
    Last_Renewal_Date__c=Date.newInstance(2024,9,1),
    Expiration_Date__c=Date.newInstance(2025,9,1),
    Cancel_Date__c=Date.newInstance(2026,1,5),
    Auto_Renewal__c=false, Paid_Through__c=Date.newInstance(2025,9,1));

insert new List<Membership__c>{m01,m02,m03,m04,m05,m06,m07,m08,m09,m10,m11,m12,m13,m14};

// ─── Bookings ─────────────────────────────────────────────────────────────────

// Marshfield - confirmed booking + alt quote
Booking__c b01 = new Booking__c(Name='TC49N0', Contact__c=c01.Id, Status__c='Booking',
    PAX_Count__c=3, Departure_Date__c=Date.newInstance(2026,11,9),
    Departure_Port__c='Jacksonville, FL', Ship__c='Carnival Elation',
    Cabin_Category__c='4C-Interior', Itinerary__c='Bahamas',
    Quote_Type__c='Reward', Original_Cruise_Total__c=766.00,
    Current_Balance_Due__c=316.00, Reward__c=r01.Id,
    Payment_Date__c=Date.newInstance(2026,3,3));

Booking__c b01q = new Booking__c(Name='Q-TC49N0-ALT', Contact__c=c01.Id, Status__c='Quote',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2026,11,9),
    Departure_Port__c='Port Canaveral, FL', Ship__c='Carnival Glory',
    Cabin_Category__c='4E-Interior', Itinerary__c='Bahamas',
    Quote_Type__c='Reward', Original_Cruise_Total__c=548.64,
    Current_Balance_Due__c=548.64, Reward__c=r01.Id);

// Henderson - active quote
Booking__c b02 = new Booking__c(Name='Q-JH8821', Contact__c=c02.Id, Status__c='Quote',
    PAX_Count__c=4, Departure_Date__c=Date.newInstance(2026,8,15),
    Departure_Port__c='Jacksonville, FL', Ship__c='Carnival Elation',
    Cabin_Category__c='6A-Oceanview', Itinerary__c='Bahamas',
    Quote_Type__c='Reward', Original_Cruise_Total__c=1248.00,
    Current_Balance_Due__c=1248.00, Reward__c=r02.Id);

// Kowalski - 3 bookings (completed history + active)
Booking__c b03a = new Booking__c(Name='MK-HIST-001', Contact__c=c03.Id, Status__c='Completed',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2023,10,7),
    Departure_Port__c='Miami, FL', Ship__c='Carnival Magic',
    Cabin_Category__c='8C-Balcony', Itinerary__c='Caribbean - Eastern',
    Quote_Type__c='Reward', Original_Cruise_Total__c=1890.00,
    Current_Balance_Due__c=0, Reward__c=r03.Id,
    Payment_Date__c=Date.newInstance(2023,8,1));

Booking__c b03b = new Booking__c(Name='MK-HIST-002', Contact__c=c03.Id, Status__c='Completed',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2024,7,14),
    Departure_Port__c='Galveston, TX', Ship__c='Carnival Vista',
    Cabin_Category__c='8D-Balcony', Itinerary__c='Caribbean - Western',
    Quote_Type__c='Member', Original_Cruise_Total__c=2240.00,
    Current_Balance_Due__c=0, Payment_Date__c=Date.newInstance(2024,5,10));

Booking__c b03c = new Booking__c(Name='MK-2026-001', Contact__c=c03.Id, Status__c='Booking',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2026,6,21),
    Departure_Port__c='Miami, FL', Ship__c='Carnival Celebration',
    Cabin_Category__c='JS-Junior Suite', Itinerary__c='Caribbean - Eastern',
    Quote_Type__c='Cruzy+ Member', Original_Cruise_Total__c=3180.00,
    Current_Balance_Due__c=1590.00, Payment_Date__c=Date.newInstance(2026,2,14));

// Tran - new member quote
Booking__c b04 = new Booking__c(Name='Q-LT2026', Contact__c=c04.Id, Status__c='Quote',
    PAX_Count__c=1, Departure_Date__c=Date.newInstance(2026,9,6),
    Departure_Port__c='Port Canaveral, FL', Ship__c='Carnival Horizon',
    Cabin_Category__c='4J-Interior', Itinerary__c='Caribbean - Eastern',
    Quote_Type__c='Cruzy+ Member', Original_Cruise_Total__c=789.00,
    Current_Balance_Due__c=789.00);

// Delgado - 2 past completed + open quote
Booking__c b05a = new Booking__c(Name='RD-HIST-003', Contact__c=c05.Id, Status__c='Completed',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2024,12,7),
    Departure_Port__c='Galveston, TX', Ship__c='Carnival Jubilee',
    Cabin_Category__c='8E-Balcony', Itinerary__c='Caribbean - Western',
    Quote_Type__c='Member', Original_Cruise_Total__c=2890.00,
    Current_Balance_Due__c=0, Payment_Date__c=Date.newInstance(2024,10,1));

Booking__c b05b = new Booking__c(Name='RD-2026-HOLD', Contact__c=c05.Id, Status__c='Quote',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2026,12,12),
    Departure_Port__c='New Orleans, LA', Ship__c='Carnival Horizon',
    Cabin_Category__c='8B-Balcony', Itinerary__c='Caribbean - Western',
    Quote_Type__c='Member', Original_Cruise_Total__c=3100.00,
    Current_Balance_Due__c=3100.00);

// Fontaine - new social media member, first quote
Booking__c b06 = new Booking__c(Name='Q-DF2026', Contact__c=c06.Id, Status__c='Quote',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2026,10,18),
    Departure_Port__c='New Orleans, LA', Ship__c='Carnival Valor',
    Cabin_Category__c='4E-Interior', Itinerary__c='Caribbean - Western',
    Quote_Type__c='Cruzy+ Member', Original_Cruise_Total__c=678.00,
    Current_Balance_Due__c=678.00);

// Whitmore - upcoming confirmed booking (suite)
Booking__c b08a = new Booking__c(Name='PW-HIST-004', Contact__c=c08.Id, Status__c='Completed',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2023,2,12),
    Departure_Port__c='Miami, FL', Ship__c='Carnival Magic',
    Cabin_Category__c='GS-Grand Suite', Itinerary__c='Caribbean - Eastern',
    Quote_Type__c='Member', Original_Cruise_Total__c=4200.00,
    Current_Balance_Due__c=0, Payment_Date__c=Date.newInstance(2022,12,1));

Booking__c b08b = new Booking__c(Name='PW-2026-001', Contact__c=c08.Id, Status__c='Booking',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2026,12,5),
    Departure_Port__c='Miami, FL', Ship__c='Carnival Jubilee',
    Cabin_Category__c='OS-Ocean Suite', Itinerary__c='Caribbean - Southern',
    Quote_Type__c='Cruzy+ Member', Original_Cruise_Total__c=5600.00,
    Current_Balance_Due__c=2800.00, Payment_Date__c=Date.newInstance(2026,3,5));

// Patel - reward quote
Booking__c b09 = new Booking__c(Name='Q-RP2026', Contact__c=c09.Id, Status__c='Quote',
    PAX_Count__c=4, Departure_Date__c=Date.newInstance(2026,7,4),
    Departure_Port__c='Port Canaveral, FL', Ship__c='Carnival Sunshine',
    Cabin_Category__c='4G-Interior', Itinerary__c='Bahamas',
    Quote_Type__c='Reward', Original_Cruise_Total__c=1560.00,
    Current_Balance_Due__c=1560.00, Reward__c=r04.Id);

// Nguyen - new member quote
Booking__c b10 = new Booking__c(Name='Q-MN2026', Contact__c=c10.Id, Status__c='Quote',
    PAX_Count__c=1, Departure_Date__c=Date.newInstance(2026,11,22),
    Departure_Port__c='Miami, FL', Ship__c='Carnival Celebration',
    Cabin_Category__c='8A-Balcony', Itinerary__c='Caribbean - Eastern',
    Quote_Type__c='Cruzy+ Member', Original_Cruise_Total__c=1120.00,
    Current_Balance_Due__c=1120.00);

// Rivera - reward quote
Booking__c b11 = new Booking__c(Name='Q-CR2026', Contact__c=c11.Id, Status__c='Quote',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2026,6,7),
    Departure_Port__c='Jacksonville, FL', Ship__c='Carnival Elation',
    Cabin_Category__c='4C-Interior', Itinerary__c='Bahamas',
    Quote_Type__c='Reward', Original_Cruise_Total__c=698.00,
    Current_Balance_Due__c=698.00, Reward__c=r05.Id);

// Drummond - confirmed upcoming
Booking__c b13a = new Booking__c(Name='TD-HIST-001', Contact__c=c13.Id, Status__c='Completed',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2024,12,14),
    Departure_Port__c='New Orleans, LA', Ship__c='Carnival Valor',
    Cabin_Category__c='8C-Balcony', Itinerary__c='Caribbean - Western',
    Quote_Type__c='Member', Original_Cruise_Total__c=2100.00,
    Current_Balance_Due__c=0, Payment_Date__c=Date.newInstance(2024,10,10));

Booking__c b13b = new Booking__c(Name='TD-2026-001', Contact__c=c13.Id, Status__c='Booking',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2026,12,13),
    Departure_Port__c='New Orleans, LA', Ship__c='Carnival Jubilee',
    Cabin_Category__c='8D-Balcony', Itinerary__c='Caribbean - Western',
    Quote_Type__c='Cruzy+ Member', Original_Cruise_Total__c=2340.00,
    Current_Balance_Due__c=1170.00, Payment_Date__c=Date.newInstance(2026,3,2));

// Leake - budget first-timer quote
Booking__c b14 = new Booking__c(Name='Q-SL2026', Contact__c=c14.Id, Status__c='Quote',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2026,9,20),
    Departure_Port__c='Jacksonville, FL', Ship__c='Carnival Elation',
    Cabin_Category__c='4E-Interior', Itinerary__c='Bahamas',
    Quote_Type__c='Cruzy+ Member', Original_Cruise_Total__c=598.00,
    Current_Balance_Due__c=598.00);

// Sorensen - past + active quote
Booking__c b15a = new Booking__c(Name='GS-HIST-001', Contact__c=c15.Id, Status__c='Completed',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2024,8,11),
    Departure_Port__c='Tampa, FL', Ship__c='Carnival Radiance',
    Cabin_Category__c='8B-Balcony', Itinerary__c='Caribbean - Eastern',
    Quote_Type__c='Member', Original_Cruise_Total__c=2050.00,
    Current_Balance_Due__c=0, Payment_Date__c=Date.newInstance(2024,6,1));

Booking__c b15b = new Booking__c(Name='GS-2026-001', Contact__c=c15.Id, Status__c='Quote',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2026,7,19),
    Departure_Port__c='Galveston, TX', Ship__c='Carnival Valor',
    Cabin_Category__c='4A-Interior', Itinerary__c='Alaska',
    Quote_Type__c='Cruzy+ Member', Original_Cruise_Total__c=1980.00,
    Current_Balance_Due__c=1980.00);

// Blackwell - upcoming Alaska full add-ons
Booking__c b17 = new Booking__c(Name='JB-2026-001', Contact__c=c17.Id, Status__c='Booking',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2026,7,12),
    Departure_Port__c='Norfolk, VA', Ship__c='Carnival Radiance',
    Cabin_Category__c='8C-Balcony', Itinerary__c='Alaska',
    Quote_Type__c='Cruzy+ Member', Original_Cruise_Total__c=3450.00,
    Current_Balance_Due__c=1725.00, Payment_Date__c=Date.newInstance(2026,3,20));

// Pruitt - historical completed before cancel
Booking__c b18a = new Booking__c(Name='TP-HIST-001', Contact__c=c18.Id, Status__c='Completed',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2023,5,21),
    Departure_Port__c='New Orleans, LA', Ship__c='Carnival Glory',
    Cabin_Category__c='4C-Interior', Itinerary__c='Bahamas',
    Quote_Type__c='Member', Original_Cruise_Total__c=980.00,
    Current_Balance_Due__c=0, Payment_Date__c=Date.newInstance(2023,3,10));

// Tillman - reward + confirmed booking
Booking__c b20 = new Booking__c(Name='WT-2026-001', Contact__c=c20.Id, Status__c='Booking',
    PAX_Count__c=2, Departure_Date__c=Date.newInstance(2026,10,4),
    Departure_Port__c='New Orleans, LA', Ship__c='Carnival Valor',
    Cabin_Category__c='8A-Balcony', Itinerary__c='Caribbean - Western',
    Quote_Type__c='Reward', Original_Cruise_Total__c=1840.00,
    Current_Balance_Due__c=920.00, Reward__c=r07.Id,
    Payment_Date__c=Date.newInstance(2026,3,17));

insert new List<Booking__c>{
    b01,b01q,b02,b03a,b03b,b03c,b04,b05a,b05b,b06,
    b08a,b08b,b09,b10,b11,b13a,b13b,b14,b15a,b15b,
    b17,b18a,b20
};

// ─── Booking Payments ─────────────────────────────────────────────────────────

insert new List<Booking_Payment__c>{
    new Booking_Payment__c(Booking__c=b01.Id, Amount__c=450.00,
        Payment_Date__c=Date.newInstance(2026,3,3), Note__c='Initial deposit - Visa ending 4821'),
    new Booking_Payment__c(Booking__c=b03a.Id, Amount__c=1890.00,
        Payment_Date__c=Date.newInstance(2023,8,1), Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b03b.Id, Amount__c=2240.00,
        Payment_Date__c=Date.newInstance(2024,5,10), Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b03c.Id, Amount__c=1590.00,
        Payment_Date__c=Date.newInstance(2026,2,14), Note__c='50% deposit - Anniversary cruise'),
    new Booking_Payment__c(Booking__c=b05a.Id, Amount__c=2890.00,
        Payment_Date__c=Date.newInstance(2024,10,1), Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b08a.Id, Amount__c=4200.00,
        Payment_Date__c=Date.newInstance(2022,12,1), Note__c='Paid in full - suite upgrade'),
    new Booking_Payment__c(Booking__c=b08b.Id, Amount__c=2800.00,
        Payment_Date__c=Date.newInstance(2026,3,5), Note__c='50% deposit - Ocean Suite'),
    new Booking_Payment__c(Booking__c=b13a.Id, Amount__c=2100.00,
        Payment_Date__c=Date.newInstance(2024,10,10), Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b13b.Id, Amount__c=1170.00,
        Payment_Date__c=Date.newInstance(2026,3,2), Note__c='Deposit - auto renewal customer'),
    new Booking_Payment__c(Booking__c=b15a.Id, Amount__c=2050.00,
        Payment_Date__c=Date.newInstance(2024,6,1), Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b17.Id, Amount__c=1725.00,
        Payment_Date__c=Date.newInstance(2026,3,20), Note__c='50% deposit - Alaska cruise'),
    new Booking_Payment__c(Booking__c=b18a.Id, Amount__c=980.00,
        Payment_Date__c=Date.newInstance(2023,3,10), Note__c='Paid in full'),
    new Booking_Payment__c(Booking__c=b20.Id, Amount__c=920.00,
        Payment_Date__c=Date.newInstance(2026,3,17), Note__c='50% deposit - Sam\'s Club reward booking')
};

// ─── Membership Payments ──────────────────────────────────────────────────────

insert new List<Membership_Payment__c>{
    new Membership_Payment__c(Membership__c=m01.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2025,5,10), Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m01.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2024,5,10), Renewal_Year__c=2024),
    new Membership_Payment__c(Membership__c=m02.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2025,3,15), Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m02.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2024,3,15), Renewal_Year__c=2024),
    new Membership_Payment__c(Membership__c=m02.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2023,3,15), Renewal_Year__c=2023),
    new Membership_Payment__c(Membership__c=m03.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2026,1,12), Renewal_Year__c=2026),
    new Membership_Payment__c(Membership__c=m05.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2026,3,10), Renewal_Year__c=2026),
    new Membership_Payment__c(Membership__c=m06.Id, Amount_Paid__c=199.00,
        Date_Paid__c=Date.newInstance(2025,11,20), Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m07.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2026,2,25), Renewal_Year__c=2026),
    new Membership_Payment__c(Membership__c=m08.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2025,1,15), Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m09.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2026,3,14), Renewal_Year__c=2026),
    new Membership_Payment__c(Membership__c=m10.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2025,7,4), Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m11.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2025,4,1), Renewal_Year__c=2025),
    new Membership_Payment__c(Membership__c=m12.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2026,3,21), Renewal_Year__c=2026),
    new Membership_Payment__c(Membership__c=m13.Id, Amount_Paid__c=129.00,
        Date_Paid__c=Date.newInstance(2026,3,17), Renewal_Year__c=2026)
};

// ─── Add-Ons ──────────────────────────────────────────────────────────────────

insert new List<Add_On__c>{
    // Marshfield
    new Add_On__c(Name='Travel Insurance - Marshfield', Booking__c=b01.Id,
        Add_On_Type__c='Travel Insurance', Amount__c=89.00),
    // Kowalski anniversary cruise - stacked
    new Add_On__c(Name='Nassau Shore Excursion - Kowalski', Booking__c=b03c.Id,
        Add_On_Type__c='Shore Excursion', Amount__c=220.00),
    new Add_On__c(Name='Cheers Drink Package - Kowalski', Booking__c=b03c.Id,
        Add_On_Type__c='Drink Package', Amount__c=318.00),
    new Add_On__c(Name='Travel Insurance - Kowalski', Booking__c=b03c.Id,
        Add_On_Type__c='Travel Insurance', Amount__c=99.00),
    new Add_On__c(Name='Specialty Dining - Kowalski', Booking__c=b03c.Id,
        Add_On_Type__c='Specialty Dining', Amount__c=150.00),
    // Whitmore suite upgrade add-ons
    new Add_On__c(Name='Shore Excursion - St Lucia - Whitmore', Booking__c=b08b.Id,
        Add_On_Type__c='Shore Excursion', Amount__c=340.00),
    new Add_On__c(Name='Cheers Package - Whitmore', Booking__c=b08b.Id,
        Add_On_Type__c='Drink Package', Amount__c=490.00),
    new Add_On__c(Name='Travel Insurance - Whitmore', Booking__c=b08b.Id,
        Add_On_Type__c='Travel Insurance', Amount__c=149.00),
    new Add_On__c(Name='Specialty Dining - Whitmore', Booking__c=b08b.Id,
        Add_On_Type__c='Specialty Dining', Amount__c=200.00),
    // Drummond
    new Add_On__c(Name='Travel Insurance - Drummond', Booking__c=b13b.Id,
        Add_On_Type__c='Travel Insurance', Amount__c=89.00),
    new Add_On__c(Name='Cozumel Excursion - Drummond', Booking__c=b13b.Id,
        Add_On_Type__c='Shore Excursion', Amount__c=180.00),
    // Blackwell - Alaska cruise full stack
    new Add_On__c(Name='Glacier Bay Excursion - Blackwell', Booking__c=b17.Id,
        Add_On_Type__c='Shore Excursion', Amount__c=290.00),
    new Add_On__c(Name='Travel Insurance - Blackwell', Booking__c=b17.Id,
        Add_On_Type__c='Travel Insurance', Amount__c=129.00),
    new Add_On__c(Name='SeaTac Airport Transfer - Blackwell', Booking__c=b17.Id,
        Add_On_Type__c='Transfer', Amount__c=120.00),
    // Tillman
    new Add_On__c(Name='Travel Insurance - Tillman', Booking__c=b20.Id,
        Add_On_Type__c='Travel Insurance', Amount__c=89.00),
    new Add_On__c(Name='Cozumel Excursion - Tillman', Booking__c=b20.Id,
        Add_On_Type__c='Shore Excursion', Amount__c=160.00)
};

System.debug('✅ Cruzy demo data seeded!');
System.debug('23 Contacts (3 duplicate pairs), 8 Rewards, 14 Memberships, 23 Bookings, 13 Booking Payments, 15 Membership Payments, 16 Add-Ons');
