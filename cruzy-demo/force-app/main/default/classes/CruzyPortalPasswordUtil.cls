public with sharing class CruzyPortalPasswordUtil {

    /**
     * Calls the portal API to bcrypt-hash a temporary password and store it on the Contact.
     * This keeps the hashing algorithm consistent with the portal's auth system.
     */
    @future(callout=true)
    public static void setPasswordViaPortal(Id contactId, String tempPassword) {
        String portalUrl = System.Label.Cruzy_Portal_URL;
        String adminSecret = System.Label.Cruzy_Admin_API_Secret;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(portalUrl + '/api/admin/set-password');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + adminSecret);
        req.setBody(JSON.serialize(new Map<String, String>{
            'contactId' => contactId,
            'password' => tempPassword
        }));
        req.setTimeout(30000);

        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200) {
            System.debug(LoggingLevel.ERROR, 'Portal set-password failed: ' + res.getBody());
        }
    }

    /**
     * SHA-256 hash (not bcrypt) — used only as a fallback placeholder.
     * The portal will re-hash with bcrypt on first login if this format is detected.
     */
    public static String hashPassword(String password) {
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(password));
        return 'sha256:' + EncodingUtil.convertToHex(digest);
    }
}
