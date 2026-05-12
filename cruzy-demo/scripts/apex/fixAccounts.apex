// Create the Cruzy Account and wire all contacts + related records to it

// Upsert the main Cruzy account
Account cruzy = new Account(
    Name = 'Cruzy',
    Website = 'https://www.cruzy.com',
    Phone = '8005559990',
    BillingStreet = '1 Cruise Club Blvd',
    BillingCity = 'Fort Lauderdale',
    BillingState = 'FL',
    BillingPostalCode = '33316',
    BillingCountry = 'United States',
    Industry = 'Travel',
    Description = 'Cruzy - Cruise Club & Concierge Travel. B2B Rewards, Cruise Club Memberships, and Cruzy.com Direct.'
);
insert cruzy;

// Assign all existing contacts to this account
List<Contact> contacts = [
    SELECT Id, AccountId FROM Contact
    WHERE LastName IN (
        'Marshfield','Henderson','Kowalski','Tran','Delgado','Fontaine','Okafor',
        'Whitmore','Patel','Nguyen','Rivera','Castellano','Drummond','Leake',
        'Sorensen','Yates','Blackwell','Pruitt','Hargrove','Tillman'
    )
];

for (Contact c : contacts) {
    c.AccountId = cruzy.Id;
}
update contacts;

System.debug('✅ Account created: ' + cruzy.Id);
System.debug('✅ Contacts linked to Cruzy: ' + contacts.size());
