@isTest
public class vendorInvoiceLinesTrigger_test {
    public static String AccountMemberId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public static String VendorRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    private testMethod static void runAll() {
        Account account = TxnTestUtility.createAccount(Utility.searchRecordType('Vendor','Account'));   
        Vendor_Invoice__c NewInvoice=TxnTestUtility.createInvoice(100,'123',account.id);
        //on insert check
        Vendor_Invoice_Line__c invoiceLine_test1=TxnTestUtility.createInvoiceLines(100,NewInvoice.id);
        try{
        Vendor_Invoice_Line__c invoiceLine_test2=TxnTestUtility.createInvoiceLines(110,NewInvoice.id);  
        }catch(Exception e){
            //error on duplicate invoice number successfully came.
            Boolean expectedExceptionThrown =  e.getMessage().contains('Invoice lines total amount should not be more then invoice total amount') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        //on updatecheck
        Vendor_Invoice_Line__c invoiceLine_updateTest1=TxnTestUtility.updateInvoiceLines(invoiceLine_test1.id,10);
        try{
            Vendor_Invoice_Line__c invoiceLine_updateTest2=TxnTestUtility.updateInvoiceLines(invoiceLine_test1.id,110);  
        }catch(Exception e){
            //error on duplicate invoice number successfully came.
            Boolean expectedExceptionThrown =  e.getMessage().contains('Invoice lines total amount should not be more then invoice total amount') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
    }
}