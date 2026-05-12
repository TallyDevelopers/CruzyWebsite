public with sharing class AuthnetService {

    private static final String SANDBOX_URL  = 'https://apitest.authorize.net/xml/v1/request.api';
    private static final String PROD_URL     = 'https://api.authorize.net/xml/v1/request.api';

    public class AuthnetException extends Exception {}

    public class ChargeResult {
        public String transactionId;
        public String authCode;
    }

    public class ProfileResult {
        public String customerProfileId;
        public String paymentProfileId;
    }

    // ─── Configuration ──────────────────────────────────────────────────────────

    private static Authnet_Config__mdt configCache;

    private static Authnet_Config__mdt getConfig() {
        if (configCache != null) return configCache;
        List<Authnet_Config__mdt> configs = [
            SELECT API_Login_ID__c, Transaction_Key__c, Environment__c
            FROM Authnet_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        if (configs.isEmpty()) {
            throw new AuthnetException(
                'Authorize.net configuration not found. Create an Authnet_Config__mdt record named "Default" in Setup > Custom Metadata Types.'
            );
        }
        configCache = configs[0];
        return configCache;
    }

    private static String getEndpoint() {
        return getConfig().Environment__c == 'production' ? PROD_URL : SANDBOX_URL;
    }

    private static String getValidationMode() {
        return getConfig().Environment__c == 'production' ? 'liveMode' : 'testMode';
    }

    // Writes the merchantAuthentication object fields in guaranteed order
    private static void writeMerchantAuth(JSONGenerator gen) {
        Authnet_Config__mdt cfg = getConfig();
        gen.writeFieldName('merchantAuthentication');
        gen.writeStartObject();
        gen.writeStringField('name', cfg.API_Login_ID__c);
        gen.writeStringField('transactionKey', cfg.Transaction_Key__c);
        gen.writeEndObject();
    }

    // ─── HTTP Helper ────────────────────────────────────────────────────────────

    private static Map<String, Object> post(String jsonBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(getEndpoint());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        req.setTimeout(30000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        String body = res.getBody();
        if (body.startsWith('\uFEFF')) {
            body = body.substring(1);
        }

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(body);
        return result;
    }

    private static void checkMessages(Map<String, Object> result, String context) {
        Map<String, Object> messages = (Map<String, Object>) result.get('messages');
        if (messages == null || (String) messages.get('resultCode') != 'Ok') {
            String errText = context + ' failed';
            if (messages != null) {
                List<Object> msgList = (List<Object>) messages.get('message');
                if (msgList != null && !msgList.isEmpty()) {
                    Map<String, Object> first = (Map<String, Object>) msgList[0];
                    errText = context + ': ' + (String) first.get('text');
                }
            }
            throw new AuthnetException(errText);
        }
    }

    // ─── Create Customer Profile (new card via raw PAN) ─────────────────────────

    public static ProfileResult createCustomerProfile(
        String email, String firstName, String lastName,
        String cardNumber, String expDate, String cvv
    ) {
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('createCustomerProfileRequest');
        gen.writeStartObject();

        writeMerchantAuth(gen);

        gen.writeFieldName('profile');
        gen.writeStartObject();
        gen.writeStringField('merchantCustomerId', 'CRUZY-' + String.valueOf(Datetime.now().getTime()));
        gen.writeStringField('email', email);
        gen.writeFieldName('paymentProfiles');
        gen.writeStartObject();
        gen.writeStringField('customerType', 'individual');
        gen.writeFieldName('billTo');
        gen.writeStartObject();
        gen.writeStringField('firstName', firstName);
        gen.writeStringField('lastName', lastName);
        gen.writeEndObject();
        gen.writeFieldName('payment');
        gen.writeStartObject();
        gen.writeFieldName('creditCard');
        gen.writeStartObject();
        gen.writeStringField('cardNumber', cardNumber);
        gen.writeStringField('expirationDate', expDate);
        gen.writeStringField('cardCode', cvv);
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();

        gen.writeStringField('validationMode', getValidationMode());

        gen.writeEndObject();
        gen.writeEndObject();

        Map<String, Object> result = post(gen.getAsString());
        checkMessages(result, 'Create customer profile');

        ProfileResult pr = new ProfileResult();
        pr.customerProfileId = (String) result.get('customerProfileId');

        List<Object> ppIds = (List<Object>) result.get('customerPaymentProfileIdList');
        if (ppIds != null && !ppIds.isEmpty()) {
            pr.paymentProfileId = (String) ppIds[0];
        }

        return pr;
    }

    // ─── Add Payment Profile to existing Customer Profile ───────────────────────

    public static String createPaymentProfile(
        String customerProfileId,
        String cardNumber, String expDate, String cvv,
        String firstName, String lastName
    ) {
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('createCustomerPaymentProfileRequest');
        gen.writeStartObject();

        writeMerchantAuth(gen);

        gen.writeStringField('customerProfileId', customerProfileId);

        gen.writeFieldName('paymentProfile');
        gen.writeStartObject();
        gen.writeFieldName('billTo');
        gen.writeStartObject();
        gen.writeStringField('firstName', firstName);
        gen.writeStringField('lastName', lastName);
        gen.writeEndObject();
        gen.writeFieldName('payment');
        gen.writeStartObject();
        gen.writeFieldName('creditCard');
        gen.writeStartObject();
        gen.writeStringField('cardNumber', cardNumber);
        gen.writeStringField('expirationDate', expDate);
        gen.writeStringField('cardCode', cvv);
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();

        gen.writeStringField('validationMode', getValidationMode());

        gen.writeEndObject();
        gen.writeEndObject();

        Map<String, Object> result = post(gen.getAsString());
        checkMessages(result, 'Create payment profile');

        return (String) result.get('customerPaymentProfileId');
    }

    // ─── Charge a Customer Profile (saved card — no PAN needed) ─────────────────

    public static ChargeResult chargeCustomerProfile(
        String customerProfileId, String paymentProfileId,
        Decimal amount, String description
    ) {
        String orderDesc = description != null
            ? description.abbreviate(255)
            : 'Cruzy Cruise Club Payment';

        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('createTransactionRequest');
        gen.writeStartObject();

        writeMerchantAuth(gen);

        gen.writeFieldName('transactionRequest');
        gen.writeStartObject();
        gen.writeStringField('transactionType', 'authCaptureTransaction');
        gen.writeStringField('amount', amount.setScale(2).toPlainString());
        gen.writeFieldName('profile');
        gen.writeStartObject();
        gen.writeStringField('customerProfileId', customerProfileId);
        gen.writeFieldName('paymentProfile');
        gen.writeStartObject();
        gen.writeStringField('paymentProfileId', paymentProfileId);
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeFieldName('order');
        gen.writeStartObject();
        gen.writeStringField('description', orderDesc);
        gen.writeEndObject();
        gen.writeEndObject();

        gen.writeEndObject();
        gen.writeEndObject();

        Map<String, Object> result = post(gen.getAsString());
        checkMessages(result, 'Charge card');

        Map<String, Object> txnResponse = (Map<String, Object>) result.get('transactionResponse');
        if (txnResponse == null) {
            throw new AuthnetException('No transaction response returned from Authorize.net');
        }

        String responseCode = String.valueOf(txnResponse.get('responseCode'));
        if (responseCode != '1') {
            String errMsg = 'Transaction declined';
            List<Object> errors = (List<Object>) txnResponse.get('errors');
            if (errors != null && !errors.isEmpty()) {
                Map<String, Object> firstErr = (Map<String, Object>) errors[0];
                errMsg = (String) firstErr.get('errorText');
            }
            throw new AuthnetException(errMsg);
        }

        ChargeResult cr = new ChargeResult();
        cr.transactionId = (String) txnResponse.get('transId');
        cr.authCode      = (String) txnResponse.get('authCode');
        return cr;
    }

    // ─── Delete a Customer Payment Profile ──────────────────────────────────────

    public static void deletePaymentProfile(String customerProfileId, String paymentProfileId) {
        if (String.isBlank(customerProfileId) || String.isBlank(paymentProfileId)) return;

        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('deleteCustomerPaymentProfileRequest');
        gen.writeStartObject();

        writeMerchantAuth(gen);

        gen.writeStringField('customerProfileId', customerProfileId);
        gen.writeStringField('customerPaymentProfileId', paymentProfileId);

        gen.writeEndObject();
        gen.writeEndObject();

        Map<String, Object> result = post(gen.getAsString());
        checkMessages(result, 'Delete payment profile');
    }
}
