public with sharing class CruzyPortalManagerController {

    private static String getPortalUrl() {
        return System.Label.Cruzy_Portal_URL;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPortalStatus(Id contactId) {
        Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
        if (resolvedId == null) return new Map<String, Object>{ 'portalStatus' => 'N/A', 'name' => 'Not a Person Account' };
        Contact c = [
            SELECT Id, FirstName, LastName, Email,
                   Cruzy_Plus_MBR_Number__c, Cruzy_Plus_Enrolled__c,
                   Portal_Status__c, Portal_Last_Login__c, Portal_Login_Count__c,
                   Portal_Reset_Expiry__c
            FROM Contact
            WHERE Id = :resolvedId
            LIMIT 1
        ];

        Map<String, Object> result = new Map<String, Object>();
        result.put('contactId', c.Id);
        result.put('name', c.FirstName + ' ' + c.LastName);
        result.put('email', c.Email);
        result.put('memberId', c.Cruzy_Plus_MBR_Number__c);
        result.put('enrolled', c.Cruzy_Plus_Enrolled__c);
        result.put('portalStatus', c.Portal_Status__c);
        result.put('lastLogin', c.Portal_Last_Login__c);
        result.put('loginCount', c.Portal_Login_Count__c);
        result.put('resetExpiry', c.Portal_Reset_Expiry__c);
        result.put('hasPassword', String.isNotBlank(
            [SELECT Portal_Password_Hash__c FROM Contact WHERE Id = :resolvedId].Portal_Password_Hash__c
        ));
        return result;
    }

    @AuraEnabled
    public static String setPortalStatus(Id contactId, String status) {
        try {
            Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
            Contact c = new Contact(Id = resolvedId, Portal_Status__c = status);
            update c;
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String generateResetLink(Id contactId, String mode) {
        try {
            Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
            Contact c = [SELECT Id, FirstName, LastName, Email, Cruzy_Plus_MBR_Number__c FROM Contact WHERE Id = :resolvedId LIMIT 1];
            String baseUrl = getPortalUrl();
            List<String> urls = CruzyPortalHelper.generateToken(
                new List<CruzyPortalHelper.TokenRequest>{
                    buildRequest(resolvedId, mode, baseUrl)
                }
            );
            String link = urls.isEmpty() ? null : urls[0];

            if (link != null) {
                if (mode == 'reset') {
                    CruzyPortalEmailService.sendPasswordReset(c.Email, c.FirstName, link);
                } else {
                    CruzyPortalEmailService.sendWelcome(c.Email, c.FirstName, link, c.Cruzy_Plus_MBR_Number__c);
                }
            }

            return link;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String enrollMember(Id contactId) {
        try {
            Id resolvedId = CruzyIdResolver.resolveContactId(contactId);
            Contact c = [
                SELECT Id, FirstName, LastName, Cruzy_Plus_Enrolled__c, Cruzy_Plus_MBR_Number__c, Email
                FROM Contact WHERE Id = :resolvedId LIMIT 1
            ];

            if (c.Cruzy_Plus_Enrolled__c) {
                return 'already_enrolled:' + c.Cruzy_Plus_MBR_Number__c;
            }

            String memberId = 'CRZ-'
                + String.valueOf(Date.today().year()).right(2)
                + String.valueOf(Date.today().month()).leftPad(2, '0')
                + '-' + String.valueOf(resolvedId).right(6).toUpperCase();

            Membership__c m = new Membership__c(
                Contact__c = resolvedId,
                Name = memberId,
                Status__c = 'Active',
                Enroll_Date__c = Date.today(),
                Expiration_Date__c = Date.today().addYears(1),
                Next_Billing_Date__c = Date.today().addYears(1),
                Auto_Renewal__c = true,
                Partner__c = 'Cruzy+'
            );
            insert m;

            String baseUrl = getPortalUrl();
            List<String> urls = CruzyPortalHelper.generateToken(
                new List<CruzyPortalHelper.TokenRequest>{
                    buildRequest(resolvedId, 'welcome', baseUrl)
                }
            );

            c.Cruzy_Plus_Enrolled__c = true;
            c.Cruzy_Plus_MBR_Number__c = memberId;
            update c;

            String link = urls.isEmpty() ? '' : urls[0];
            if (String.isNotBlank(link)) {
                CruzyPortalEmailService.sendWelcome(c.Email, c.FirstName, link, memberId);
            }

            return 'enrolled:' + memberId + ':' + link;
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
