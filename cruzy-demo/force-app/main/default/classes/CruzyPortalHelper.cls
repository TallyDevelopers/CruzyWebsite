public with sharing class CruzyPortalHelper {

    /**
     * Generates a secure random token, stamps it on the Contact with an expiry,
     * sets Portal_Status__c, and returns the full set-password / reset URL.
     *
     * @param contactId  The Contact Id
     * @param mode       'welcome' (24-hour expiry, sets status to Pending)
     *                   'reset'   (1-hour expiry, keeps existing status)
     * @param baseUrl    The website base URL (e.g. https://members.cruzy.com)
     */
    @InvocableMethod(label='Generate Portal Token' description='Creates a portal token for set-password or reset-password links')
    public static List<String> generateToken(List<TokenRequest> requests) {
        List<String> urls = new List<String>();

        for (TokenRequest req : requests) {
            String token = generateSecureToken();
            DateTime expiry = req.mode == 'welcome'
                ? DateTime.now().addHours(24)
                : DateTime.now().addHours(1);

            String page = req.mode == 'welcome' ? 'set-password' : 'reset-password';
            String url = req.baseUrl + '/' + page + '?token=' + token;

            Contact c = new Contact(Id = req.contactId);
            c.Portal_Reset_Token__c = token;
            c.Portal_Reset_Expiry__c = expiry;

            if (req.mode == 'welcome') {
                c.Portal_Status__c = 'Pending';
                c.Cruzy_Plus_Enrolled__c = true;
            }

            update c;
            urls.add(url);
        }

        return urls;
    }

    private static String generateSecureToken() {
        Blob b = Crypto.generateAESKey(128);
        return EncodingUtil.convertToHex(b);
    }

    public class TokenRequest {
        @InvocableVariable(label='Contact Id' required=true)
        public String contactId;

        @InvocableVariable(label='Mode (welcome or reset)' required=true)
        public String mode;

        @InvocableVariable(label='Base URL' required=true)
        public String baseUrl;
    }
}
