/**
* @Description : Test class for the BatchstatusController
*/
@isTest
private class BatchStatusControllerTest
{
	/**
	* @Description : Test method 1
	*/
	@isTest
	static void BatchstatusMeth1()
	{
		// Creating vendor, vendor invoice and invoice lines
		Account vendor = TxnTestUtility.createAccount(Utility.searchRecordType('Vendor', 'Account'));
		Vendor_Invoice__c vendorInvoice = TxnTestUtility.createInvoice(500, '569874254', vendor.id);
		Vendor_Invoice_Line__c vendorInvoiceLine = TxnTestUtility.createInvoiceLines(200, vendorInvoice.id);
		Vendor_Invoice_Line__c vendorInvoiceLine1 = TxnTestUtility.createInvoiceLines(300, vendorInvoice.id);
		Vendor_Invoice__c vendorInvoice1 = TxnTestUtility.createInvoice(500, '569874257', vendor.id);
		vendorInvoice1.Invoice_Date__c = Date.today().addDays(-60);
		update vendorInvoice1;
		Vendor_Invoice_Line__c vendorInvoiceLine2 = TxnTestUtility.createInvoiceLines(500, vendorInvoice1.id);

		// set default financial account
		Financial_Account__c finAcc = TxnTestUtility.createFinancialAccount('TestBatch123');
		TxnTestUtility.getDefaultMapping('Accounts Payable', finAcc);
		
		//posting invoices so that the batch can take it
		cmsft_AccountPayableServiceImpl.postInvoice(new List<Vendor_Invoice__c> {vendorInvoice, vendorInvoice1}, Date.today(), Date.today());
		vendorInvoice = [select Posted__c, Amount__c, Vendor__c from Vendor_Invoice__c where id=:vendorInvoice.id];
		vendorInvoice1 = [select Posted__c, Amount__c, Vendor__c from Vendor_Invoice__c where id=:vendorInvoice1.id];
		System.assert(vendorInvoice.Posted__c);

		AP_Aging__c apcus = new AP_Aging__c(name='Effective Date Record', Effective_Date__c=Date.today());
		insert apcus;
		Test.startTest();
		APAgingBatch ap =new APAgingBatch();
		Id batchId = Database.executeBatch(ap);
		BatchStatusController bsc = new BatchStatusController();
		bsc.redirectToPage = 'APAgingBatchRunner';
		bsc.batchId = batchId;
		BatchStatusController.BatchJobs bj = bsc.currentJob;
		bsc.updateProgress();
		System.assert(bj.isCompleted==false);
		bj = bsc.currentJob;
		Test.stopTest();
	}
}