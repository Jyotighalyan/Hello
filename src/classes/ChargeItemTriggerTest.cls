@isTest
private class ChargeItemTriggerTest
{
	@isTest
	static void testHappyPath()
	{
		TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
        taxObj.Type__c='Breakfast';
        taxObj.Subtype__c = 'Buffet';
        taxObj.Allow_in_POS__c=true;
        taxObj.Taxes_applicable_on_service_charge__c=false;
        taxObj.Service_Charge_applicable__c=false;
        insert taxObj;

        Id recId = Utility.searchRecordType('Misc Charges','Charge_Item__c');

		Charge_Item__c ci = new Charge_Item__c();
		ci.Type__c = 'Breakfast';
		ci.SubType__c = 'Buffet';
		ci.RecordTypeId = recId;
		ci.Price__c = 10;
		insert ci;

		System.assert(ci.Id != null);

		ci.Price__c = 100;
		update ci;

		Charge_Item__c ci2 = [select Id, Price__c from Charge_Item__c where Id =: ci.Id];
		System.assert(ci2.Price__c == 100);
	}

	@isTest
	static void testHappyPathLarge()
	{
		TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
        taxObj.Type__c='Breakfast';
        taxObj.Subtype__c = 'Buffet';
        taxObj.Allow_in_POS__c=true;
        taxObj.Taxes_applicable_on_service_charge__c=false;
        taxObj.Service_Charge_applicable__c=false;
        insert taxObj;

        Id recId = Utility.searchRecordType('Misc Charges','Charge_Item__c');

        List<Charge_Item__c> items = new List<Charge_Item__c>();
        for(Integer i=0;i<200;i++)
        {
			Charge_Item__c ci = new Charge_Item__c();
			ci.Type__c = 'Breakfast';
			ci.SubType__c = 'Buffet';
			ci.RecordTypeId = recId;
			ci.Price__c = 10;
			items.add(ci);
		}
		insert items;
	}

	@isTest
	static void testErrorPathInsert()
	{
        Id recId = Utility.searchRecordType('Misc Charges','Charge_Item__c');

		Charge_Item__c ci = new Charge_Item__c();
		ci.Type__c = 'Breakfast';
		ci.SubType__c = 'Buffet';
		ci.RecordTypeId = recId;
		ci.Price__c = 10;
		
		try
		{
			insert ci;
		}
		catch(Exception weShouldBeHere)
		{ }
		System.assert(ci.Id == null);
	}

	@isTest
	static void testErrorPathUpdate()
	{
		TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
        taxObj.Type__c='Breakfast';
        taxObj.Subtype__c = 'Buffet';
        taxObj.Allow_in_POS__c=true;
        taxObj.Taxes_applicable_on_service_charge__c=false;
        taxObj.Service_Charge_applicable__c=false;
        insert taxObj;

        Id recId = Utility.searchRecordType('Misc Charges','Charge_Item__c');

		Charge_Item__c ci = new Charge_Item__c();
		ci.Type__c = 'Breakfast';
		ci.SubType__c = 'Buffet';
		ci.RecordTypeId = recId;
		ci.Price__c = 10;
		insert ci;

		System.assert(ci.Id != null);

		ci.SubType__c = 'Bad Sub';
		try
		{
			update ci;
		}
		catch(Exception weShouldBeHere)
		{ }
	}
}