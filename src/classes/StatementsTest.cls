@isTest
private class StatementsTest
{
	/**
	* @Description : test method for GenerateStatementController And GenerateStatementBatch
	*/

	@testSetup
	static void setup(){
		Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da =TxnTestUtility.getDefaultMapping('Accounts Payable',fa);
        da = TxnTestUtility.getDefaultPaymentMapping('Cash',fa) ;
	}

	@isTest
	static void GenerateStatementsTest1()
	{		
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		member.Customer_Id__c = '3536';
		update member;
		//Member_Dues__c memDue = TxnTestUtility.getDue('Test statement due', 'Annual');
		//List<TXN__c> manualDueAndTaxes = TxnTestUtility.getManualDuesWithTaxes(memDue, member);
		//TXN__c payRec = TxnTestUtility.txnCreatePay(member);
		//TXN__C refRec = TxnTestUtility.getRefundFromPayment(payRec);
		//List<TXN__c> adjustments = TxnTestUtility.getAdjustmentRecordsOnDues(manualDueAndTaxes[0]);
		TXN__C eveCharge = TxnTestUtility.getEventCharges(member);
		Test.startTest();
		GenerateStatementController genStmt = new GenerateStatementController();
		genStmt.monthYear = Date.today().year()+' '+Date.today().addMonths(-1).month();
		genStmt.status = 'Confirm';
		genStmt.statementSummaryRec.Statement_Summary_Name__c = 'test statements';
		genStmt.generate();
		System.assert(genStmt.batchId!=null);
		Test.stopTest();
	}

	/**
	* @Description : test method 2 for GenerateStatementController And GenerateStatementBatch 
	*/
	@isTest
	static void GenerateStatementsTest2(){
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		member.Customer_Id__c = '3536';
		update member;
		Statements__c stmtSumm = TxnTestUtility.getStatementSummary(member);
		Member_Dues__c memDue = TxnTestUtility.getDue('Test statement due', 'Annual');
		TxnTestUtility.getManualDuesWithTaxes(memDue, member);
		Test.startTest();
		GenerateStatementController genStmt = new GenerateStatementController();
		genStmt.statementSummaryRec.Statement_Summary_Name__c = 'test statements';
		try{
			genStmt.generate();
		}
		catch(Exception ex){
			System.assert(ex.getMessage().Contains('mandatory fields'));
		}	
		genStmt.monthYear = Date.today().year()+' '+Date.today().addMonths(-1).month();
		genStmt.status = 'Confirm';
		genStmt.generate();
		System.assert(genStmt.batchId!=null);
		genStmt.cancel();
		System.assertEquals('', genStmt.status);
		Test.StopTest();
	}

	/**
	* @Description : test method for ApproveRejectStatements batch
	*/
	@isTest
	static void ApproveRejectStatementSummary(){
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		member.Customer_Id__c = '3536';
		update member;
		Statements__c stmtSumm = TxnTestUtility.getStatementSummary(member);
		Date todaysDate = Date.today();
		stmtSumm.Date__c = Date.newInstance(todaysDate.year(), todaysDate.month(), 1);
		update stmtSumm;
		Test.startTest();
		GenerateStatementController genStmt = new GenerateStatementController();
		genStmt.statementSummaryRec.Statement_Summary_Name__c = 'test statements';
		genStmt.monthYear = Date.today().year()+' '+Date.today().addMonths(-1).month();
		genStmt.status = 'Confirm';
		genStmt.generate();
		System.assertEquals(true, genStmt.confirmOnDup);
		genStmt.status = 'Generate';
		genStmt.generate();
		System.assert(genStmt.batchId!=null);
		Test.stopTest();
	}

	/**
	* @Description : Test class for approval process of statements - covered ApprovalStatementsController and ApproveRejectStatements
	*/
	@isTest
	static void ApprovalStatementsControllerTest(){
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		member.Customer_Id__c = '3536';
		update member;
		Statements__c stmtSumm = TxnTestUtility.getStatementSummary(member);
		Test.startTest();
		ApproveStatementsController apc = new ApproveStatementsController();
		apc.approveAll = true;
		apc.approveAllStatements();
		apc.renderStatementTable();
		apc.refreshPageSize();
		System.assertEquals(false, apc.hasNext);
		System.assertEquals(false, apc.hasPrevious);
		System.assertEquals(1, apc.getTotalPages());
		System.assertEquals(1, apc.pageNumber);
		apc.approveStatemets();
		System.assert(apc.batchId!=null);
		Test.stopTest();
	}

	/**
	* @Description : test method for UpdateStatementBatch
	*/
	@isTest
	static void UpdateStatementBatchTest(){
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		Statements__c stmtSumm = TxnTestUtility.getStatementSummary(member);
		Date todaysDate = Date.today();
		stmtSumm.Date__c = Date.newInstance(todaysDate.year(), todaysDate.month(), 1);
		stmtSumm.To_Date__c = Date.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.addMonths(1).toStartOfMonth().addDays(-1).day());
		update stmtSumm;
		Statements__c stmtSumm1 = TxnTestUtility.getStatementSummary(member);
		stmtSumm1.Date__c = Date.newInstance(todaysDate.year(), todaysDate.addMonths(1).month(), 1);
		stmtSumm.To_Date__c = Date.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.addMonths(2).toStartOfMonth().addDays(-1).day());
		stmtSumm1.Statement__c = stmtSumm.id;
		update stmtSumm1;
		GenerateStatementController genStmt = new GenerateStatementController();
		genStmt.statementSummaryRec.Statement_Summary_Name__c = 'test statements';
		genStmt.monthYear = Date.today().year()+' '+Date.today().addMonths(-1).month();
		genStmt.status = 'Confirm';
		genStmt.generate();
		System.assertEquals(true, genStmt.callRegenerate);
		Member_Dues__c memDue = TxnTestUtility.getDue('Test statement due', 'Annual');
		List<TXN__c> manualDueAndTaxes = TxnTestUtility.getManualDuesWithTaxes(memDue, member);
		TXN__c payRec = TxnTestUtility.txnCreatePay(member);
		TXN__C refRec = TxnTestUtility.getRefundFromPayment(payRec);
		List<TXN__c> adjustments = TxnTestUtility.getAdjustmentRecordsOnDues(manualDueAndTaxes[0]);
		Test.startTest();
		TXN__C eveCharge = TxnTestUtility.getEventCharges(member);
		genStmt.status = 'Update';
		genStmt.generate();
		System.assert(genStmt.batchId!=null);
		Test.stopTest();
	}

	@isTest
	static void StatementDetailTest(){
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		Statements__c stmtSumm = TxnTestUtility.getStatementSummary(member);
		Statements__c memStmt = [Select Id, RecordType.Name from Statements__c where Statement__c=:stmtSumm.id];
		Statements__c stmtLine = [Select Id, RecordType.Name from Statements__c where Statement__c=:memStmt.id];
		PageReference pageRef = Page.StatementsDetail;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('retURL', 'GenerateStatements');
		pageRef.getParameters().put('delId', memStmt.id);
		Test.startTest();
		StatementsDetailController stdCont1 = new StatementsDetailController(new ApexPages.StandardController(memStmt));
		stdCont1.initializeActivity();
		System.assertEquals(true, stdCont1.isMemStmt);
		pageRef.getParameters().put('delId', stmtSumm.id);
		StatementsDetailController stdCont = new StatementsDetailController(new ApexPages.StandardController(stmtSumm));
		stdCont.initializeActivity();
		System.assert(stdCont.batchId!=null);
		pageRef.getParameters().put('delId', null);
		pageRef.getParameters().put('Id', stmtLine.id);
		StatementsDetailController stdCont2 = new StatementsDetailController(new ApexPages.StandardController(stmtLine));
		stdCont2.initializeActivity();
		System.assertEquals(true,stdCont2.isEdit);
		Test.stopTest();
	}

	/**
	* @Description : test method for statementsDomain
	*/
	@isTest
	static void statementDomainTest(){
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		Contact member1 = TxnTestUtility.createContact('Testing statement', 'addresses', Utility.searchRecordType('Member','Contact'));
		Address__c address = TxnTestUtility.getAddress(member, 'Home');

		List<Address__c> addressesList = new List<Address__c>();
		Address__c address1 = TxnTestUtility.getAddress(member1, 'Home');
		address1.Billing__c = true;
		addressesList.add(address1);
		Address__c address2 = TxnTestUtility.getAddress(member1, 'Home');
		address2.From_Date__c = Date.today();
		address2.To_Date__c = Date.today();
		address2.Billing__c = true;
		addressesList.add(address2);
		update addressesList;
		Statements__c stmtSumm = TxnTestUtility.getStatementSummary(member);
		Statements__c memStmt = [Select Id, RecordType.Name, AddressId__c from Statements__c where Statement__c=:stmtSumm.id];
		System.assertEquals(address.id, memStmt.AddressId__c);
		Statements__c stmtSumm1 = TxnTestUtility.getStatementSummary(member1);
		Statements__c memStmt1 = [Select Id, RecordType.Name, AddressId__c from Statements__c where Statement__c=:stmtSumm1.id];
		System.assertEquals(address2.id, memStmt1.AddressId__c);
		Test.startTest();
		// bulk test
		List<Statements__c> stmtListToUpdate = new List<Statements__c>();
		for(Integer i=0; i<200; i++){
			Statements__c memStmt3 = new Statements__c(RecordTypeId=Utility.searchRecordType('Member Statement','Statements__c'));
			memStmt3.Statement__c = stmtSumm.id;
			memStmt3.Member__c = member.id;
			stmtListToUpdate.add(memStmt3);
		}
		insert stmtListToUpdate;
		Test.stopTest();
	}
}