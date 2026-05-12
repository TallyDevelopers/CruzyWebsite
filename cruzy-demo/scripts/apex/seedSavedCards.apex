// Seed realistic Stripe-style saved cards for demo contacts

List<String> lastNames = new List<String>{
    'Marshfield','Henderson','Kowalski','Tran','Delgado',
    'Fontaine','Okafor','Whitmore','Patel','Nguyen',
    'Rivera','Castellano','Drummond','Leake','Sorensen',
    'Yates','Blackwell','Pruitt','Hargrove','Tillman'
};

List<Contact> contacts = [
    SELECT Id, FirstName, LastName
    FROM Contact
    WHERE LastName IN :lastNames
    ORDER BY LastName
];

List<Saved_Card__c> cards = new List<Saved_Card__c>();

// Card data pool — realistic variety
List<Map<String,Object>> cardPool = new List<Map<String,Object>>{
    new Map<String,Object>{'brand'=>'Visa','last4'=>'4821','mo'=>8,'yr'=>2027},
    new Map<String,Object>{'brand'=>'Mastercard','last4'=>'3356','mo'=>11,'yr'=>2026},
    new Map<String,Object>{'brand'=>'American Express','last4'=>'0091','mo'=>3,'yr'=>2028},
    new Map<String,Object>{'brand'=>'Visa','last4'=>'7734','mo'=>6,'yr'=>2027},
    new Map<String,Object>{'brand'=>'Discover','last4'=>'5512','mo'=>1,'yr'=>2029},
    new Map<String,Object>{'brand'=>'Mastercard','last4'=>'2290','mo'=>9,'yr'=>2026},
    new Map<String,Object>{'brand'=>'Visa','last4'=>'9043','mo'=>4,'yr'=>2028},
    new Map<String,Object>{'brand'=>'American Express','last4'=>'1177','mo'=>7,'yr'=>2027},
    new Map<String,Object>{'brand'=>'Mastercard','last4'=>'6618','mo'=>12,'yr'=>2026},
    new Map<String,Object>{'brand'=>'Visa','last4'=>'3302','mo'=>2,'yr'=>2029}
};

Integer idx = 0;
for (Contact c : contacts) {
    Map<String,Object> card = cardPool[Math.mod(idx, cardPool.size())];
    String pmId = 'pm_demo' + String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0,8);

    cards.add(new Saved_Card__c(
        Name                     = (String)card.get('brand') + ' •••• ' + (String)card.get('last4'),
        Contact__c               = c.Id,
        Card_Brand__c            = (String)card.get('brand'),
        Last_Four__c             = (String)card.get('last4'),
        Expiry_Month__c          = (Integer)card.get('mo'),
        Expiry_Year__c           = (Integer)card.get('yr'),
        Cardholder_Name__c       = c.FirstName + ' ' + c.LastName,
        Is_Default__c            = true,
        Stripe_Payment_Method_Id__c = pmId
    ));

    // ~30% of contacts get a second card
    if (Math.mod(idx, 3) == 0) {
        Integer nextIdx = Math.mod(idx + 5, cardPool.size());
        Map<String,Object> card2 = cardPool[nextIdx];
        String pmId2 = 'pm_demo' + String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0,8);
        cards.add(new Saved_Card__c(
            Name                     = (String)card2.get('brand') + ' •••• ' + (String)card2.get('last4'),
            Contact__c               = c.Id,
            Card_Brand__c            = (String)card2.get('brand'),
            Last_Four__c             = (String)card2.get('last4'),
            Expiry_Month__c          = (Integer)card2.get('mo'),
            Expiry_Year__c           = (Integer)card2.get('yr'),
            Cardholder_Name__c       = c.FirstName + ' ' + c.LastName,
            Is_Default__c            = false,
            Stripe_Payment_Method_Id__c = pmId2
        ));
    }
    idx++;
}

insert cards;
System.debug('✅ Seeded ' + cards.size() + ' saved cards across ' + contacts.size() + ' contacts');
