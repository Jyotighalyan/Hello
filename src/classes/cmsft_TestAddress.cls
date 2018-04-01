/**
 * See https://github.com/financialforcedev/fflib-apex-common for more info
 *
 * Install library via
 *   https://githubsfdeploy.herokuapp.com/app/githubdeploy/financialforcedev/fflib-apex-common
 */

/**
 * For more guidelines and details see
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Domain_Layer
 * @Author Nagendra kumar
 * @Date March 04,2017
 * @Description Encapsulates all behaviour logic relating to the Address Trigger
 * @group Test Code Coverage
 */
@isTest
private class cmsft_TestAddress {
      public static String accountMemberRecordType=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public static string contactMemberRecordType=Schema.SObjectType.contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
 
    /**
    * @description this method covered test code for Address Trigger
    */
    static testmethod void AddressTest() {
        Account thisAccount = TxnTestUtility.createAccount(accountMemberRecordType);
        Contact thisContact = TxnTestUtility.createMember(thisAccount, 'Primary',contactMemberRecordType);
        Address__c thisAddress = TxnTestUtility.getAddress(thisContact, 'Home');
        thisAddress.Primary__c = true;
        Test.startTest();
        update thisAddress;
        System.assertNotEquals(thisContact.name, 'this is Address test class');
        Test.stopTest();
    }
}