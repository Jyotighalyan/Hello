/**
* @Description : test class to cover ApplyDuesController and BillingTableSetupDetailController
* @Date : 2017
* @group : Financial Management
*/

@isTest
private class ApplyDuesNBillingTableSetupDetailTest
{
	/**
	* @Description : test method to cover ApplyDuesController class - for membership types
	*/
	@isTest
	static void ApplyDuesControllerTest1()
	{
	// create a member with the selected membership type
	Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
	Contact con = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
	Member_Dues__c dueObj = TxnTestUtility.getDue('Apply Due Test', 'Installment');
	Test.setCurrentPage(Page.InstallmentBilling);
	ApexPages.currentPage().getParameters().put('dueId',dueObj.id);
	ApplyDuesController apc = new ApplyDuesController(new ApexPages.StandardController(dueObj));
	apc.selectedCategories.add(apc.allCategories[0]);
	con.Membership_Type__c = apc.allCategories[0].getValue();
	update con;
	Test.startTest();
	apc.allCategories.remove(0);
	apc.actionToPerform = 'confirm';
	apc.saveSetup();
	System.assertEquals(apc.delList.size(), 0);
	apc.actionToPerform = 'save';
	apc.saveSetup();
	List<Apply_due_on_members__c> apDOnMem = [select Id from Apply_due_on_members__c where Member_Dues__c=:apc.currentBillingObj.id];
	System.assertEquals(apDOnMem.size(), 1);

	// Test 2
	apc = new ApplyDuesController(new ApexPages.StandardController(dueObj));
	apc.allCategories.add(apc.selectedCategories[0]);
	apc.selectedCategories.remove(0);
	apc.actionToPerform = 'confirm';
	apc.saveSetup();
	System.assert(apc.delList.size()>0);
	apc.actionToPerform = '';
	apc.saveSetup();
	System.assertEquals(apc.selectedCategories.size(), 1);
	Test.stopTest(); 
	}

	/**
	* @Description : test method to cover ApplyDuesController, GenerateDuesController and GenerateDuesBatch class - for annual amount distribution
	*/
	@isTest
	static void ApplyDuesControllerTest2()
	{
		// create a member with the selected membership type
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
		Contact con = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
		Member_Dues__c dueObj = TxnTestUtility.getDue('Apply Due Test', 'Installment');
		Test.setCurrentPage(Page.InstallmentBilling);
		ApexPages.currentPage().getParameters().put('dueId',dueObj.id);
		Test.startTest();
		ApplyDuesController apc = new ApplyDuesController(new ApexPages.StandardController(dueObj));
		apc.distrubtionMap.values().get(0).setPrimaryAmount(1000);
		apc.distrubtionMap.values().get(0).setSpouseAmount(1000);
		apc.distrubtionMap.values().get(0).setDependentAmount(1000);
		apc.SaveFull();
		System.assert(apc.existingInstallment[0].id!=null);

		// test code for GenerateDuesController and GenerateDuesBatch
		String Type = TxnChargeToTaxMapping__c.Type__c.getDescribe().getPicklistValues().get(0).getLabel();
		String Subtype = TxnChargeToTaxMapping__c.Subtype__c.getDescribe().getPicklistValues().get(0).getLabel();
		TxnChargeToTaxMapping__c tax = TxnTestUtility.getTaxMapping(Type, Subtype);
		TxnTestUtility.mapFinancialAccountOnPassedTaxes(tax);
		dueObj.Type__c = Type;
		dueObj.Subtype__c = Subtype;
		update dueObj;
		TxnTestUtility.applyDueOnMembers(dueObj, con);
		GenerateDuesController genObj = new GenerateDuesController();
		genObj.selectedBillingPeriod = apc.distrubtionMap.values().get(0).monthName;
		genObj.dueList.add(genObj.unSelectedDues[0]);
		genObj.unSelectedDues.remove(0);
		genObj.txnObjRec.Post_Date__c = Date.today();
		genObj.status = 'confirm';
		genObj.generateDues();
		genObj.status = 'generate';
		genObj.generateDues();
		Test.stopTest(); 
	}

	/**
	* @Description : test method to cover BillingTableSetupDetailController
	*/
	@isTest
	static void BillingTableSetupDetailControllerTest1()
	{
		Member_Dues__c dueObj = TxnTestUtility.getDue('Apply Due Test', 'Installment');
		BillingTableSetupDetailController btsdc = new BillingTableSetupDetailController(new ApexPages.StandardController(dueObj));
		btsdc.setupPage();
		System.assertEquals(btsdc.isInstalSele, true);
		Test.setCurrentPage(Page.InstallmentBilling);
		ApexPages.currentPage().getParameters().put('dueId',dueObj.id);
		ApplyDuesController apc = new ApplyDuesController(new ApexPages.StandardController(dueObj));
		apc.distrubtionMap.values().get(0).setPrimaryAmount(1000);
		apc.distrubtionMap.values().get(0).setSpouseAmount(1000);
		apc.distrubtionMap.values().get(0).setDependentAmount(1000);
		apc.SaveFull();
		btsdc = new BillingTableSetupDetailController(new ApexPages.StandardController(dueObj));
		btsdc.setupPage();
		System.assertEquals(btsdc.isInstalSele, false);
	}

	/**
	* @Description : test method to cover PostDuesController and PostDuesBatch for posting
	*/
	@isTest
	static void testPostDues()
	{
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
		Contact con = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
		Member_Dues__c dueObj = TxnTestUtility.getDue('Post Dues Test', 'Installment');
		List<Dues_Summary__c> dueSummList = TxnTestUtility.getDueSummAndRelatedDues(dueObj, con);
		Financial_Account__c finAcc = TxnTestUtility.createFinancialAccount('Post Test Financial Account');
		Default_Account__c defAcc = TxnTestUtility.getDefaultMapping('Accounts Receivable', finAcc);
		Tax_To_Account_Mapping__c settingFinancialAccount = new Tax_To_Account_Mapping__c(Financial_Accounts__c=finAcc.id, Tax__c=Utility.getNameOfTax(new List<String>(Taxes__c.sObjectType.getDescribe().fields.getMap().keySet())[0]));
		Insert settingFinancialAccount;
		Test.startTest();
		PostDuesController pdc = new PostDuesController();
		pdc.renderDues();
		System.assertEquals('April', pdc.selectedBillingMonth);
		pdc.renderViewTable();
		pdc.selectedDuesListToBePosted.add(pdc.unSelectedDues[0]);
		pdc.unSelectedDues.remove(0);
		pdc.postReject = 'post';
		pdc.status = 'confirm';
		pdc.PostRejectDues();
		System.assertEquals('', pdc.confirmDuePostings);
		pdc.postReject = 'post';
		pdc.status = 'post';
		pdc.PostRejectDues();
		System.assert(pdc.dueIdsListToBePosted.size()>0);
		Test.stopTest();
	}

	/**
	* @Description : test method to cover PostDuesController and PostDuesBatch for rejecting
	*/
	@isTest
	static void testRejectDues()
	{
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
		Contact con = TxnTestUtility.createMember(acc, 'Primary', Utility.searchRecordType('Member', 'Contact'));
		Member_Dues__c dueObj = TxnTestUtility.getDue('Post Dues Test', 'Installment');
		List<Dues_Summary__c> dueSummList = TxnTestUtility.getDueSummAndRelatedDues(dueObj, con);
		Financial_Account__c finAcc = TxnTestUtility.createFinancialAccount('Post Test Financial Account');
		Default_Account__c defAcc = TxnTestUtility.getDefaultMapping('Accounts Receivable', finAcc);
		Tax_To_Account_Mapping__c settingFinancialAccount = new Tax_To_Account_Mapping__c(Financial_Accounts__c=finAcc.id, Tax__c=Utility.getNameOfTax(new List<String>(Taxes__c.sObjectType.getDescribe().fields.getMap().keySet())[0]));
		Insert settingFinancialAccount;
		Test.startTest();
		PostDuesController pdc = new PostDuesController();
		pdc.selectedDuesListToBePosted.add(pdc.unSelectedDues[0]);
		pdc.unSelectedDues.remove(0);
		pdc.postReject = 'Reject';
		pdc.status = 'Reject';
		pdc.PostRejectDues();
		System.assert(pdc.dueIdsListToBePosted.size()>0);
		Test.stopTest();
	}
}