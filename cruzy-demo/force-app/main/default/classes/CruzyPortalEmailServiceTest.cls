@isTest
private class CruzyPortalEmailServiceTest {

    @isTest
    static void testSendPasswordReset() {
        Integer before = Limits.getEmailInvocations();
        CruzyPortalEmailService.sendPasswordReset(
            'test@example.com', 'Jane', 'https://example.com/reset-password?token=abc'
        );
        System.assert(Limits.getEmailInvocations() > before, 'Email should have been sent');
    }

    @isTest
    static void testSendWelcome() {
        Integer before = Limits.getEmailInvocations();
        CruzyPortalEmailService.sendWelcome(
            'test@example.com', 'John', 'https://example.com/set-password?token=def', 'CRZ-2604-AB12CD'
        );
        System.assert(Limits.getEmailInvocations() > before, 'Email should have been sent');
    }

    @isTest
    static void testSendTemporaryPassword() {
        Integer before = Limits.getEmailInvocations();
        CruzyPortalEmailService.sendTemporaryPassword(
            'test@example.com', 'Alex', 'TempPwd123!', 'https://example.com/login'
        );
        System.assert(Limits.getEmailInvocations() > before, 'Email should have been sent');
    }
}
