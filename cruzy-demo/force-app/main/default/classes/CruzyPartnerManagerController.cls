public with sharing class CruzyPartnerManagerController {

    private static String getPortalUrl() {
        return System.Label.Cruzy_Portal_URL;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPartnerStatus(Id contactId) {
        Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
        if (resolvedId == null) return new Map<String, Object>{ 'portalStatus' => 'N/A', 'name' => 'Not a Person Account' };
        Contact c = [
            SELECT Id, FirstName, LastName, Email,
                   Portal_Status__c, Portal_Last_Login__c, Portal_Login_Count__c,
                   Portal_Reset_Expiry__c, Portal_Type__c, Cruzy_Plus_Enrolled__c
            FROM Contact
            WHERE Id = :resolvedId
            LIMIT 1
        ];

        Map<String, Object> result = new Map<String, Object>();
        result.put('contactId', c.Id);
        result.put('name', c.FirstName + ' ' + c.LastName);
        result.put('email', c.Email);
        result.put('portalStatus', c.Portal_Status__c);
        result.put('portalType', c.Portal_Type__c);
        result.put('enrolled', c.Portal_Type__c == 'Partner');
        result.put('lastLogin', c.Portal_Last_Login__c);
        result.put('loginCount', c.Portal_Login_Count__c);
        result.put('resetExpiry', c.Portal_Reset_Expiry__c);
        result.put('hasPassword', String.isNotBlank(
            [SELECT Portal_Password_Hash__c FROM Contact WHERE Id = :resolvedId].Portal_Password_Hash__c
        ));
        return result;
    }

    @AuraEnabled
    public static String enrollPartner(Id contactId) {
        try {
            Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
            Contact c = [
                SELECT Id, FirstName, LastName, Email, Portal_Type__c, Cruzy_Plus_Enrolled__c
                FROM Contact WHERE Id = :resolvedId LIMIT 1
            ];

            if (c.Portal_Type__c == 'Partner') {
                return 'already_enrolled';
            }

            String baseUrl = getPortalUrl();
            List<String> urls = CruzyPortalHelper.generateToken(
                new List<CruzyPortalHelper.TokenRequest>{ buildRequest(resolvedId, 'welcome', baseUrl) }
            );

            c.Portal_Type__c = 'Partner';
            update c;

            String link = urls.isEmpty() ? '' : urls[0];
            if (String.isNotBlank(link)) {
                CruzyPortalEmailService.sendPartnerWelcome(c.Email, c.FirstName, link);
            }

            return 'enrolled:' + link;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String generateResetLink(Id contactId, String mode) {
        try {
            Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
            Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id = :resolvedId LIMIT 1];
            String baseUrl = getPortalUrl();
            List<String> urls = CruzyPortalHelper.generateToken(
                new List<CruzyPortalHelper.TokenRequest>{ buildRequest(resolvedId, mode, baseUrl) }
            );
            String link = urls.isEmpty() ? null : urls[0];

            if (link != null) {
                if (mode == 'reset') {
                    CruzyPortalEmailService.sendPasswordReset(c.Email, c.FirstName, link);
                } else {
                    CruzyPortalEmailService.sendPartnerWelcome(c.Email, c.FirstName, link);
                }
            }
            return link;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String setPortalStatus(Id contactId, String status) {
        try {
            Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
            update new Contact(Id = resolvedId, Portal_Status__c = status);
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String setTemporaryPassword(Id contactId, String tempPassword) {
        try {
            if (String.isBlank(tempPassword) || tempPassword.length() < 8) {
                throw new AuraHandledException('Password must be at least 8 characters.');
            }
            Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
            Contact c = [SELECT Id, Email, FirstName FROM Contact WHERE Id = :resolvedId LIMIT 1];
            String hash = CruzyPortalPasswordUtil.hashPassword(tempPassword);
            update new Contact(
                Id = resolvedId,
                Portal_Password_Hash__c = hash,
                Portal_Status__c = 'Active',
                Portal_Reset_Token__c = null,
                Portal_Reset_Expiry__c = null
            );
            CruzyPortalPasswordUtil.setPasswordViaPortal(resolvedId, tempPassword);
            CruzyPortalEmailService.sendTemporaryPassword(c.Email, c.FirstName, tempPassword, getPortalUrl() + '/login');
            return 'success';
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static CruzyPortalHelper.TokenRequest buildRequest(Id contactId, String mode, String baseUrl) {
        CruzyPortalHelper.TokenRequest req = new CruzyPortalHelper.TokenRequest();
        req.contactId = contactId;
        req.mode = mode;
        req.baseUrl = baseUrl;
        return req;
    }
}
