@isTest
private class allPaymentsControllerTest
{
    public  Static String  AccountMemberId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public  Static String ContactMemberId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
    public  Static String refundId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();

	@isTest
	static void allPaymentsControllerTest()
	{
        Test.startTest();
        Financial_Account__c fa = TxnTestUtility.createFinancialAccount('test');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da = TxnTestUtility.getDefaultPaymentMapping('Cash',fa) ;
        da = TxnTestUtility.getDefaultRefundMapping('Cash',fa) ;
    
        Account Acc=TxnTestUtility.createAccount(AccountMemberId);
        Contact mem=TxnTestUtility.createMember(Acc,'Primary',ContactMemberId);
        TXN__c payment=TxnTestUtility.txnCreatePay(mem);
        
        TXN__c newRefund = new TXN__c();
        newRefund.Amount__c = 50.00;
        newRefund.Related_To__c = payment.id;
        newRefund.RecordTypeId = refundId;
        newRefund.Payment_Type__c='Cash';
        insert newRefund;
        Apexpages.currentPage().getParameters().put('MemberId', mem.id);
		allPaymentsController payments=new allPaymentsController();

		Test.stopTest();
	}
}