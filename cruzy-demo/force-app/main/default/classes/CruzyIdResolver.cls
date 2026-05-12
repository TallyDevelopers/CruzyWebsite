public with sharing class CruzyIdResolver {

    private static final Schema.SObjectType ACCOUNT_TYPE = Account.SObjectType;
    private static final Schema.SObjectType CONTACT_TYPE = Contact.SObjectType;

    /**
     * Accepts either an Account Id (Person Account) or a Contact Id.
     * Returns the underlying Contact Id in both cases.
     * Throws AuraHandledException if the record can't be resolved.
     */
    public static Id resolveContactId(Id recordId) {
        if (recordId == null) {
            return null;
        }

        Schema.SObjectType sot = recordId.getSobjectType();

        if (sot == CONTACT_TYPE) {
            return recordId;
        }

        if (sot == ACCOUNT_TYPE) {
            List<Account> accts = [
                SELECT PersonContactId FROM Account
                WHERE Id = :recordId AND IsPersonAccount = true
                LIMIT 1
            ];
            if (!accts.isEmpty() && accts[0].PersonContactId != null) {
                return accts[0].PersonContactId;
            }
            return null;
        }

        return null;
    }
}
