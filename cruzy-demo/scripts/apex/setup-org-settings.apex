// Query current org settings
Organization org = [
    SELECT Id, LanguageLocaleKey, DefaultLocaleSidKey, TimeZoneSidKey, DefaultCurrencyIsoCode
    FROM Organization
    LIMIT 1
];

System.debug('=== Current Org Settings ===');
System.debug('Language:  ' + org.LanguageLocaleKey);
System.debug('Locale:    ' + org.DefaultLocaleSidKey);
System.debug('Timezone:  ' + org.TimeZoneSidKey);
System.debug('Currency:  ' + org.DefaultCurrencyIsoCode);
System.debug('');
System.debug('NOTE: Language, Timezone, and Currency must be set via Metadata API.');
System.debug('See scripts/shell/setup-org-settings.sh to apply all settings automatically.');
