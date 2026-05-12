@isTest
public class AuthnetCalloutMock implements HttpCalloutMock {

    private String scenario;

    public AuthnetCalloutMock() {
        this.scenario = 'success';
    }

    public AuthnetCalloutMock(String scenario) {
        this.scenario = scenario;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);

        String body = req.getBody();

        if (body.contains('createCustomerPaymentProfileRequest')) {
            if (scenario == 'profile_error') {
                res.setBody(errorResponse('E00039', 'A duplicate record already exists.'));
            } else {
                res.setBody(
                    '{"messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]},' +
                    '"customerPaymentProfileId":"200300401"}'
                );
            }
        } else if (body.contains('createCustomerProfileRequest')) {
            if (scenario == 'profile_error') {
                res.setBody(errorResponse('E00039', 'A duplicate record already exists.'));
            } else {
                res.setBody(
                    '{"messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]},' +
                    '"customerProfileId":"100200300",' +
                    '"customerPaymentProfileIdList":["200300400"]}'
                );
            }
        } else if (body.contains('createTransactionRequest')) {
            if (scenario == 'charge_declined') {
                res.setBody(
                    '{"messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]},' +
                    '"transactionResponse":{"responseCode":"2","transId":"0",' +
                    '"errors":[{"errorCode":"2","errorText":"This transaction has been declined."}]}}'
                );
            } else {
                res.setBody(
                    '{"messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]},' +
                    '"transactionResponse":{"responseCode":"1","transId":"60123456789","authCode":"ABC123",' +
                    '"messages":[{"code":"1","description":"This transaction has been approved."}]}}'
                );
            }
        } else if (body.contains('deleteCustomerPaymentProfileRequest')) {
            res.setBody(
                '{"messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}'
            );
        } else {
            res.setBody(
                '{"messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}'
            );
        }

        return res;
    }

    private String errorResponse(String code, String text) {
        return '{"messages":{"resultCode":"Error","message":[{"code":"' + code + '","text":"' + text + '"}]}}';
    }
}
