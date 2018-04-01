/**
* @Description : test class for DefaultAccountDomain class
* @group : Financial Management
*/
@isTest
private class DefaultAccountDomainTest
{
	@isTest
	static void TestMethod1()
	{
		List<Default_Account__c> defAccList = new List<Default_Account__c>();
		Financial_Account__c finAcc = TxnTestUtility.createFinancialAccount('DefaultFinancialAccount');

		// bulk insert test
		for(Integer i=0; i<199; i++){
			Default_Account__c defAcc = new Default_Account__c(Default_Type_Name__c='Accounts Payable', Financial_Account__c = finAcc.id);
			defAccList.add(defAcc);
		}
		try{
			Test.startTest();
			Database.insert(defAccList, false);
			Test.stopTest();
		}
		catch(Exception ex)
		{
			System.assert(ex.getMessage().contains('already exist'));
		}
		List<Default_Account__c> defAccsWithAcccPay = [select id from Default_Account__c where Default_Type_Name__c='Accounts Payable'];
		System.assertEquals(1,defAccsWithAcccPay.size());

		// test single record if some records already exist
		defAccList.clear();
		defAccList.add(new Default_Account__c(Default_Type_Name__c='Accounts Payable', Financial_Account__c = finAcc.id));
		try{
			insert defAccList;
		}
		catch(Exception ex)
		{
			System.assert(ex.getMessage().contains('already exist'));
		}
	}

	/**
	* @Description : method to check DefaultAccountDomain on update
	*/
	@isTest
	static void TestMethod2()
	{
		List<Default_Account__c> defAccList = new List<Default_Account__c>();
		Financial_Account__c finAcc = TxnTestUtility.createFinancialAccount('DefaultFinancialAccount');
		Default_Account__c defAcc = new Default_Account__c(Default_Type_Name__c='Bank Account', Financial_Account__c = finAcc.id);
		insert defAcc;
		Default_Account__c defAcc1 = new Default_Account__c(Default_Type_Name__c='Accounts Payable', Financial_Account__c = finAcc.id);
		insert defAcc1;
		defAcc.Default_Type_Name__c = 'Accounts Payable';
		try{
			Test.startTest();
			update defAcc;
			Test.stopTest();
		}
		catch(Exception ex){
			System.assert(ex.getMessage().contains('already exist'));
		}
	}
}