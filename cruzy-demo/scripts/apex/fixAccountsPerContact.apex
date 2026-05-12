// Fix: Each contact gets their own Account. Remove the shared "Cruzy" account.

// Pull all our demo contacts
List<Contact> contacts = [
    SELECT Id, FirstName, LastName, Email, Phone, MailingCity, MailingState,
           AccountId
    FROM Contact
    WHERE LastName IN (
        'Marshfield','Henderson','Kowalski','Tran','Delgado','Fontaine','Okafor',
        'Whitmore','Patel','Nguyen','Rivera','Castellano','Drummond','Leake',
        'Sorensen','Yates','Blackwell','Pruitt','Hargrove','Tillman'
    )
];

// Build one Account per contact
List<Account> accountsToInsert = new List<Account>();
for (Contact c : contacts) {
    accountsToInsert.add(new Account(
        Name = c.FirstName + ' ' + c.LastName,
        Phone = c.Phone,
        BillingCity = c.MailingCity,
        BillingState = c.MailingState,
        Type = 'Customer'
    ));
}
insert accountsToInsert;

// Map by name to handle duplicates (same last name) by index
Map<Id, Account> contactToAccount = new Map<Id, Account>();
for (Integer i = 0; i < contacts.size(); i++) {
    contactToAccount.put(contacts[i].Id, accountsToInsert[i]);
}

// Update each contact to their own account
for (Contact c : contacts) {
    c.AccountId = contactToAccount.get(c.Id).Id;
}
update contacts;

// Delete the shared Cruzy account
List<Account> sharedAcct = [SELECT Id FROM Account WHERE Name = 'Cruzy' LIMIT 1];
if (!sharedAcct.isEmpty()) delete sharedAcct;

System.debug('✅ Created ' + accountsToInsert.size() + ' individual accounts');
System.debug('✅ Every contact now has their own account');
