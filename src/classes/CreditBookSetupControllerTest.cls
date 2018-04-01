@isTest
private class CreditBookSetupControllerTest
{
	@isTest
	static void CreditBookSetupTestMethod1()
	{
		Financial_Account__c finAcc = TxnTestUtility.createFinancialAccount('CreditBookFinancials');
		PageReference pg = Page.CreditBookSetup;
		pg.getParameters().put('from','profilePage');
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		pg.getParameters().put('Id',member.id);
		Credit_Book__c credit = TxnTestUtility.getCredits(member);
		Test.setCurrentPage(pg);
		Test.startTest();
		CreditBookSetupController cbcont = new CreditBookSetupController();
		System.assertEquals('profilePage', cbcont.fromPage);
		cbcont.creditRecord.Credit_Amount__c = 200;
		cbcont.creditRecord.CreditBookType__c = Credit_Book__c.CreditBookType__c.getDescribe().getPicklistValues()[0].getValue();
		cbcont.creditRecord.Description__c = 'Test credits';
		cbcont.creditRecord.Date__c = Date.today();
		pg.getParameters().put('type','memberPage');
		cbcont.save();
		TxnTestUtility.getDefaultMapping('Credit Book - Credit Account', finAcc);
		TxnTestUtility.getDefaultMapping('Credit Book - Debit Account', finAcc);
		cbcont.save();
		System.assert(cbcont.creditRecord.id!=null);
		Test.stopTest();
	}

	@isTest
	static void CreditBookSetupTestMethod2(){
		Financial_Account__c finAcc = TxnTestUtility.createFinancialAccount('CreditBookFinancials');
		TxnTestUtility.getDefaultMapping('Credit Book - Credit Account', finAcc);
		TxnTestUtility.getDefaultMapping('Credit Book - Debit Account', finAcc);
		PageReference pg = Page.CreditBookSetup;
		pg.getParameters().put('from','financialLandingPage');
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household','Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member','Contact'));
		Test.setCurrentPage(pg);
		Test.startTest();
		CreditBookSetupController cbcont = new CreditBookSetupController();
		System.assertEquals('financialLandingPage', cbcont.fromPage);
		cbcont.creditRecord.Credit_Amount__c = 200;
		cbcont.creditRecord.CreditBookType__c = Credit_Book__c.CreditBookType__c.getDescribe().getPicklistValues()[0].getValue();
		cbcont.creditRecord.Description__c = 'Test credits';
		cbcont.creditRecord.Date__c = Date.today();
		pg.getParameters().put('type','saveFinancial');
		cbcont.membersToAdd[0].Member_ID__c = member.id;
		cbcont.save();
		cbcont.addMembers();
		System.assertEquals(2, cbcont.membersToAdd.size());
		pg.getParameters().put('type','saveNewFinancial');
		cbcont.save();
		Test.stopTest();
	}
}