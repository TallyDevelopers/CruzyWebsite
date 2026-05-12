@isTest
private class CruzyPortalPasswordUtilTest {

    @isTest
    static void testHashPassword() {
        String hash = CruzyPortalPasswordUtil.hashPassword('TestPassword1');
        System.assert(hash.startsWith('sha256:'), 'Hash should be prefixed with sha256:');
        System.assertEquals(hash, CruzyPortalPasswordUtil.hashPassword('TestPassword1'), 'Same input should produce same hash');
        System.assertNotEquals(hash, CruzyPortalPasswordUtil.hashPassword('DifferentPassword'), 'Different input should produce different hash');
    }
}
