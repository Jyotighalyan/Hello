/**
* @Description : test class for PostInvoiceController and AccountPayableController
* @Date : 2017
*/

@isTest
private class AccountPayableControllerTest {
	
	/**
	* @Description : test method for AccountPayableController
	*/
	@isTest 
	static void AccountPayableControllerTestMethodOne() 
	{
        Financial_Account__c finAccount = TxnTestUtility.createFinancialAccount('TestAccPay');
        Default_Account__c defaultMapping = TxnTestUtility.getDefaultMapping('Accounts Payable', finAccount); 
        Account vendRec= TxnTestUtility.createAccount(Utility.searchRecordType('Vendor','Account'));
        
        Vendor_Invoice__c vendorInvoice = TxnTestUtility.createInvoice(500, '569874254', vendRec.id);
		Vendor_Invoice_Line__c vendorInvoiceLine = TxnTestUtility.createInvoiceLines(200, vendorInvoice.id);
		Vendor_Invoice_Line__c vendorInvoiceLine1 = TxnTestUtility.createInvoiceLines(300, vendorInvoice.id);
		Vendor_Invoice__c vendorInvoice1 = TxnTestUtility.createInvoice(500, '569874257', vendRec.id);
		Vendor_Invoice_Line__c vendorInvoiceLine2 = TxnTestUtility.createInvoiceLines(500, vendorInvoice1.id);

        Vendor_Invoice__c vInv = TxnTestUtility.createInvoice(Double.valueOf(500), '564625416484', vendRec.id);
		AccountsPayableController accPayObj = new AccountsPayableController();
        Test.startTest();
		accPayObj.SearchAPEnteries();
        
        // check unpostedVenInvList size must be greater than 0
        System.assert(accPayObj.unpostedVenInvList.size()>0);

        // mark them to be posted
        for(Vendor_Invoice__c vendInv :accPayObj.unpostedVenInvList){
        	vendInv.Post_Status__c = true;
        }
        accPayObj.takeConfirm = 'confirm';
		accPayObj.postEnteries();

		// check numberOfFailedPosting size must be 1
		System.assertEquals(1, accPayObj.numberOfFailedPosting);
		accPayObj.takeConfirm = 'post';
		accPayObj.postEnteries();
		vendorInvoice = [select Posted__c, Amount__c, Vendor__c from Vendor_Invoice__c where id=:vendorInvoice.id];

		// check posted checkbox should be true now
		System.assertEquals(true, vendorInvoice.Posted__c);
        Test.stopTest();
	}

	/**
	* @Description : test method to cover code selected from detail page
	*/
	@isTest
	static void testMethod2()
	{
		Financial_Account__c finAccount = TxnTestUtility.createFinancialAccount('TestAccPay');
        Default_Account__c defaultMapping = TxnTestUtility.getDefaultMapping('Accounts Payable', finAccount);
        Account vendRec= TxnTestUtility.createAccount(Utility.searchRecordType('Vendor','Account'));
		Vendor_Invoice__c vendorInvoice = TxnTestUtility.createInvoice(500, '569874254', vendRec.id);
		Vendor_Invoice_Line__c vendorInvoiceLine = TxnTestUtility.createInvoiceLines(200, vendorInvoice.id);
		Test.setCurrentPage(new PageReference('Page.AccountsPayable'));
		System.currentPageReference().getParameters().put('Vid', vendorInvoice.id);
		Test.startTest();
		AccountsPayableController accPayObj = new AccountsPayableController();
		// check unpostedVenInvList size should be greater than 0 now
		System.assert(accPayObj.unpostedVenInvList.size()>0);
		System.assertEquals(true, accPayObj.unpostedVenInvList[0].Post_Status__c);
		Test.stopTest();
	}

	/**
	* @Description : test method to cover change post date of a posted financial journal entry 
	*/
	@isTest
	static void testChangeFJEPostDate()
	{
		Financial_Account__c finAccount = TxnTestUtility.createFinancialAccount('TestChangeFJEPSD');
		Financial_Journal_Entry__c finEntry = new Financial_Journal_Entry__c(Posted__c=true, Post_Date__c=Date.today(), Entry_Date__c=Date.today());
		insert finEntry;
		Financial_Journal_Line__c finJeLine = new Financial_Journal_Line__c(Financial_Journal_Entry__c=finEntry.id, Financial_Account__c=finAccount.id, Posted__c=true, Post_Date__c=Date.today(), Amount__c= -200);
		Financial_Journal_Line__c finJeLine1 = new Financial_Journal_Line__c(Financial_Journal_Entry__c=finEntry.id, Financial_Account__c=finAccount.id, Posted__c=true, Post_Date__c=Date.today(), Amount__c=200);
		insert finJeLine;
		insert finJeLine1;
		Test.setCurrentPage(Page.changeInvoicePostDate);
		System.currentPageReference().getParameters().put('FjeId', finEntry.id);
		Test.startTest();
		AccountsPayableController apc = new AccountsPayableController();
		apc.finJeEntry.Post_Date__c = Date.today().addMonths(-1);
		apc.UpdateFinJEPostDate();
		Financial_Journal_Entry__c fjeEntrySaved = [Select id, Post_Date__c from Financial_Journal_Entry__c where id=:apc.finJeEntry.id];
		System.assertEquals(Date.today().addMonths(-1).month(), apc.finJeEntry.Post_Date__c.month());
		Test.stopTest();
	}
}