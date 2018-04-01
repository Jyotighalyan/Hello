@isTest
public class vendorInvoiceTrigger_test {
    public static String AccountMemberId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public static String VendorRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    private testMethod static void runAll() {
        Account account = TxnTestUtility.createAccount(Utility.searchRecordType('Vendor','Account')); 
        Vendor_Invoice__c NewInvoice=TxnTestUtility.createInvoice(100,'123',account.id);
        try{
            NewInvoice=TxnTestUtility.createInvoice(110,'123',account.id);  
        }catch(Exception e){
            //error on duplicate invoice number successfully came.
            Boolean expectedExceptionThrown =  e.getMessage().contains('There is already an Invoice on this Vendor with that number, please update the field and click Save again.') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
    }
}