@isTest
private class ManualDueSetupControllerTest
{
	@isTest
	static void ManualDueTest1()
	{
		// create a member with the selected membership type
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
		Contact con = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
		Member_Dues__c dueObj = TxnTestUtility.getDue('Apply Due Test', 'Installment');
		Financial_Account__c finaAcc = TxnTestUtility.createFinancialAccount('Manual Dues Test');
		Default_Account__c defAcc = TxnTestUtility.getDefaultMapping('Accounts Receivable', finaAcc);
		Test.setCurrentPage(Page.ManualDueSetup);
		ApexPages.currentPage().getParameters().put('id',con.id);
		Test.startTest();
		ManualDueSetupController dueSetup = new ManualDueSetupController();
		dueSetup.dueRec.Member_Dues__c = dueObj.id;
		dueSetup.changeDueSelected();
		TxnChargeToTaxMapping__c taxMap = TxnTestUtility.getTaxMapping(dueSetup.memDues.Type__c, dueSetup.memDues.Subtype__c);
		List<Tax_To_Account_Mapping__c> taxToAccMap = TxnTestUtility.mapFinancialAccountOnPassedTaxes(taxMap);
		dueSetup.changeDueSelected();
		dueSetup.save();
		System.assert(dueSetup.dueRec.id!=null);
		Test.stopTest();
	}

	@isTest
	static void ManualDueTest2()
	{
		// create a member with the selected membership type
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
		Contact con = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
		con.Tax_Exempt__c = true;
		con.Tax_Exempt_Number__c = '123456';
		update con;
		Member_Dues__c dueObj = TxnTestUtility.getDue('Apply Due Test', 'Installment');
		Test.setCurrentPage(Page.ManualDueSetup);
		ApexPages.currentPage().getParameters().put('id',con.id);
		Test.startTest();
		ManualDueSetupController dueSetup = new ManualDueSetupController();

		try{
			dueSetup.save();
		}
		catch(Exception ex)
		{
			System.assert(ex.getMessage().contains('Due selection'));
		}
		dueSetup.dueRec.Member_Dues__c = dueObj.id;
		dueSetup.dueRec.Date__c = null;
		dueSetup.changeDueSelected();
		TxnChargeToTaxMapping__c taxMap = TxnTestUtility.getTaxMapping(dueSetup.memDues.Type__c, dueSetup.memDues.Subtype__c);
		List<Tax_To_Account_Mapping__c> taxToAccMap = TxnTestUtility.mapFinancialAccountOnPassedTaxes(taxMap);
		dueSetup.updateTaxesAndSCList(dueSetup.memDues.Type__c, dueSetup.memDues.Subtype__c, dueSetup.dueRec.Amount__c);
		try{
			dueSetup.save();
		}
		catch(Exception ex)
		{
			System.assert(ex.getMessage().contains('Post date'));
		}
		dueSetup.taxesAndSC.taxesList[0].taxExemption = true;
		try{
			dueSetup.save();
		}
		catch(Exception ex)
		{
			System.assert(ex.getMessage().contains('set Tax Exempt'));
		}
		Test.stopTest();
	}
}