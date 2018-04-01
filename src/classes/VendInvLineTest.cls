/**
 * @Description : test class for VendInvLine controller class
 */
@isTest
private class VendInvLineTest
{
    /**
     *  @Description : test method to check save and saveNew functionality
     */
	@isTest
	static void testNew()
 	{
 		Account vendor= TxnTestUtility.createAccount(Utility.searchRecordType('Vendor','Account'));
  		Vendor_Invoice__c vendInv = TxnTestUtility.createInvoice(Double.valueOf(500), '26598765', vendor.id);
  		Vendor_Invoice_Line__c vendInvLine = new Vendor_Invoice_Line__c(Vendor_Invoice__c=vendInv.id);
  		ApexPages.StandardController std = new ApexPages.StandardController(vendInvLine);
  		Financial_Account__c finAccount = TxnTestUtility.createFinancialAccount('Test Account');
  		VendInvLine venInvLineCon = new VendInvLine(std);
  		venInvLineCon.venInvLine.Amount__c = 100;
  		venInvLineCon.venInvLine.Financial_Account__c = finAccount.id;
        Test.startTest();
  		venInvLineCon.savenew();
        System.assert(venInvLineCon.venInvLine!=null);
  		PageReference pRef = Page.CreateVendInvLine;
  		pRef.getParameters().put('vid', vendInv.Id);
  		Test.setCurrentPage(pRef);
  		VendInvLine venInvLineCon1 = new VendInvLine(std);
  		venInvLineCon1.save();
  		System.assert(vendInvLine.id!=null);
        Test.stopTest();
 	}
	
    /**
     *  @Description : test method to check save on click of edit functionality
     */
	@isTest
	static void testEdit()
	{		
		Account vendor= TxnTestUtility.createAccount(Utility.searchRecordType('Vendor','Account')); 
		Vendor_Invoice__c vendInv = TxnTestUtility.createInvoice(Double.valueOf(500), '26598765', vendor.id);
		Vendor_Invoice_Line__c vendInvLine = TxnTestUtility.createInvoiceLines(Double.valueOf(500), vendInv.id);
		ApexPages.StandardController std = new ApexPages.StandardController(vendInvLine);
		PageReference pRef = Page.CreateVendInvLine;
		pRef.getParameters().put('id', vendInvLine.Id);
		Test.setCurrentPage(pRef);
		VendInvLine venInvLineCon = new VendInvLine(std);
        Test.startTest();
		venInvLineCon.save();
        System.assertEquals(vendInv.Amount__c, Double.valueOf(500));
        Test.stopTest();
	}
}