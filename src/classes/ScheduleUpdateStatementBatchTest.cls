@isTest
private class ScheduleUpdateStatementBatchTest
{
	@isTest
	static void ScheduleUpdateStatementBatchTestMethod1()
	{
		Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da =TxnTestUtility.getDefaultMapping('Accounts Payable',fa);
        da = TxnTestUtility.getDefaultPaymentMapping('Cash',fa) ;
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		Statements__c stmtSumm = TxnTestUtility.getStatementSummary(member);
		Date todaysDate = Date.today();
		stmtSumm.Date__c = Date.newInstance(todaysDate.year(), todaysDate.month(), 1);
		stmtSumm.To_Date__c = Date.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.addMonths(1).toStartOfMonth().addDays(-1).day());
		update stmtSumm;
		Test.startTest();
		Member_Dues__c memDue = TxnTestUtility.getDue('Test statement due', 'Annual');
		List<TXN__c> manualDueAndTaxes = TxnTestUtility.getManualDuesWithTaxes(memDue, member);
		TXN__c payRec = TxnTestUtility.txnCreatePay(member);
		TXN__C refRec = TxnTestUtility.getRefundFromPayment(payRec);
		List<TXN__c> adjustments = TxnTestUtility.getAdjustmentRecordsOnDues(manualDueAndTaxes[0]);
		TXN__C eveCharge = TxnTestUtility.getEventCharges(member);
		ScheduleUpdateStatementBatch sh1 = new ScheduleUpdateStatementBatch();
		String sch = '0 0 0 * * ?'; 
		system.schedule('Test Schedule USB', sch, sh1); 
		Test.stopTest(); 
	}

	/**
	* @Description : test method for dues in DataTableHelper
	*/
	@isTest
	static void DataTableHelperTest1(){
		Member_Dues__c memDue = TxnTestUtility.getDue('Test statement due', 'Annual');
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		List<Dues_Summary__c> dues = TxnTestUtility.getDueSummAndRelatedDues(memDue, member);
		PageReference pg = Page.DataTableHelper;
		pg.getParameters().put('FromPage', '\'Dues\'');
		pg.getParameters().put('dueId', memDue.id);
		pg.getParameters().put('billingMonth', dues[0].Billing_Period__c);
		pg.getParameters().put('dueDate', String.valueOf(dues[0].Post_Date__c));
		pg.getParameters().put('search[value]', member.Name);
		pg.getParameters().put('start', String.valueOf(0));
		pg.getParameters().put('length', String.valueOf(10));
		pg.getParameters().put('order[0][column]', '0');
		pg.getParameters().put('order[0][dir]', 'asc');
		pg.getParameters().put('columns[0][data]', 'Contact__r.Name');
		Test.setCurrentPage(pg);
		Test.startTest();
		DataTableHelper dtable = new DataTableHelper();
		dtable.processData();
		System.assert(dtable.dataTableJson!=null);
		Test.stopTest();
	}

	/**
	* @Description : test method for statements in DataTableHelper
	*/
	@isTest
	static void DataTableHelperTest2(){
		Member_Dues__c memDue = TxnTestUtility.getDue('Test statement due', 'Annual');
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		Statements__c stmtSumm = TxnTestUtility.getStatementSummary(member);
		PageReference pg = Page.DataTableHelper;
		pg.getParameters().put('FromPage', '\'Statements\'');
		pg.getParameters().put('stmtId', stmtSumm.id);
		pg.getParameters().put('memTypes', member.Membership_Type__c);
		pg.getParameters().put('fromMemId', member.Customer_Id__c);
		pg.getParameters().put('toMemId', member.Customer_Id__c);
		pg.getParameters().put('start', String.valueOf(0));
		pg.getParameters().put('length', String.valueOf(10));
		pg.getParameters().put('order[0][column]', '0');
		pg.getParameters().put('order[0][dir]', 'asc');
		pg.getParameters().put('columns[0][data]', 'Member__r.Name');
		Test.setCurrentPage(pg);
		Test.startTest();
		DataTableHelper dtable = new DataTableHelper();
		dtable.processData();
		System.assert(dtable.dataTableJson!=null);
		Test.stopTest();
	}
}