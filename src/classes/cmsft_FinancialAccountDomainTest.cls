@isTest
private class cmsft_FinancialAccountDomainTest
{
	@isTest
	static void testInsertFinancialAccount()
	{
		Financial_Account__c fa = TestHandler.getFinancialAccount(); // method does the insert
		System.assert(fa.Id != null);
	}

	@isTest
	static void testUpdateEmptyFinancialAccount()
	{
		Location__c loc= TestHandler.getLocation();// method does the insert

		Financial_Account__c faOther = TestHandler.getFinancialAccountWithChecks(loc.Id); // method does the insert
		
		Financial_Account__c fa = TestHandler.getFinancialAccount1();// method does the insert
		fa.Notes__c='Test';
		fa.Active__c = false;
		update fa;

		fa = [select Id, Name, Notes__c from Financial_Account__c where Id =: fa.Id];
		System.assert(fa.Notes__c=='Test');

		try
		{
			delete fa;
		}
		catch(Exception thisShouldFail)
		{
			fa = [select Id, Name, Notes__c from Financial_Account__c where Id =: fa.Id];
			System.assert(fa !=null);
		}
	}

	@isTest
	static void testUpdateFinancialAccountStatus()
	{
		Financial_Account__c fa = TestHandler.getFinancialAccount(); // method does the insert

		TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
        taxObj.Type__c='Breakfast';
        taxObj.Subtype__c = null;
        taxObj.Allow_in_POS__c=true;
        taxObj.Taxes_applicable_on_service_charge__c=false;
        taxObj.Service_Charge_applicable__c=false;
        insert taxObj;

		Charge_Item__c item = TestHandler.getChargeItem();
		item.Financial_Account__c = fa.Id;
		insert item;

		fa.Notes__c='Test';
		fa.Active__c = false;
		
		try
		{
			update fa;
		}
		catch(Exception thisShouldFail)
		{
			fa = [select Id, Name, Notes__c from Financial_Account__c where Id =: fa.Id];
			System.assert(fa.Notes__c==null);
		}

	}

	@isTest
	static void testUpdateFinancialAccountOnDefaultAccount()
	{
		Financial_Account__c fa = TestHandler.getFinancialAccount(); // method does the insert

		Default_Account__c da = TestHandler.getDefaultAccount();
		da.Financial_Account__c = fa.Id;
		insert da;

		fa.Notes__c='Test';
		fa.Active__c = false;
		
		try
		{
			update fa;
		}
		catch(Exception thisShouldFail)
		{
			fa = [select Id, Name, Notes__c from Financial_Account__c where Id =: fa.Id];
			System.assert(fa.Notes__c==null);
		}

	}
}