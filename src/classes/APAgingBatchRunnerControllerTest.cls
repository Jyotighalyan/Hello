/**
* @Description : Test class for APAgingBatchRunnerController
* @Author : Jyotig@mobifyi.com
* @Date : 9th June - 2017
*/
@isTest
private class APAgingBatchRunnerControllerTest
{
	@isTest
	static void runBatchTest()
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
		vendorInvoice1 = [select Posted__c, Amount__c, Vendor__c from Vendor_Invoice__c where id=:vendorInvoice1.id];

		System.assert(vendorInvoice1.Posted__c);

		// create payment for vendorInvoice
		Vendor_Invoice_Payment__c vendPay1 = TxnTestUtility.createPaymentOnPassedInvoice(vendorInvoice1, vendorInvoiceLine2);
		Test.startTest();
		PageReference pg = Page.APAgingBatchRunner;
		pg.getParameters().put('Name','APAging');
		Test.setCurrentPage(pg);
		APAgingBatchRunnerController agRunConObj = new APAgingBatchRunnerController();
		agRunConObj.EffecDate.Aging_Effective_Date__c = Date.today();
		agRunConObj.runBatch();
		System.assert(vendor.X0_30__c!=vendorInvoice.Amount__c);
		pg.getParameters().put('Name','APAging');
		Test.stopTest();
	}

	/**
	* @Description : coverage for MemberAgingBatch
	*/
	@isTest
	static void runMemberAgingBatchTest(){
		// Creating vendor, vendor invoice and invoice lines
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
		Contact member = TxnTestUtility.createMember(acc,'Dependent');
		TXN__c pay = TxnTestUtility.txnCreatePay(member);
		Member_Dues__c memDues = TxnTestUtility.getDue('MemberAging', 'Monthly');
		List<TXN__c> dues = TxnTestUtility.getManualDuesWithTaxes(memDues, member);
		for(TXN__c txn : dues){
			txn.Date__c = Date.today().addMonths(-2);
		}
		Update dues;
		PageReference pg = Page.APAgingBatchRunner;
		pg.getParameters().put('Name','MemberAging');
		Test.setCurrentPage(pg);
		APAgingBatchRunnerController agRunConObj = new APAgingBatchRunnerController();
		agRunConObj.EffecDate.Aging_Effective_Date__c = Date.today();
		agRunConObj.runBatch();
	}
}