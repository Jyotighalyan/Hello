@isTest
private class AdjustmentTest
{
	@isTest
	static void duesAdjustment()
	{
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
		Contact con = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
		Member_Dues__c dueObj = TxnTestUtility.getDue('Post Dues Test', 'Installment');
		List<TXN__c> dueTxnRec = TxnTestUtility.getManualDuesWithTaxes(dueObj, con);
		Test.startTest();
		Test.setCurrentPage(Page.TxnChargesAdjustment);
		ApexPages.currentPage().getParameters().put('Id', dueTxnRec[0].id);
		TxnChargesAdjustmentController txnChargeAdjus = new TxnChargesAdjustmentController();
		txnChargeAdjus.adjustmentTxnRecord.Statement_Description__c = 'testing statement description dues adjust';
		txnChargeAdjus.adjustmentTxnRecord.Adjustment_Reason__c = 'test adjust reason dues adjust';
		txnChargeAdjus.saveDueAdjust();
		System.assert(txnChargeAdjus.adjustmentTxnRecord.id!=null);
		Test.stopTest();
	}
}