/**
* @author Salesforce.com Foundation
* @date 2014
*
* @group Financial Management
*
* @description financial account trigger domain class
*/

public class cmsft_FinancialAccountDomain extends fflib_SObjectDomain {
	public cmsft_FinancialAccountDomain(List<Financial_Account__c> records) {
		super(records);
	}

	public override void onValidate() {
		for (Financial_Account__c record : (List<Financial_Account__c>) Records) {
		}
	}

	public override void onValidate(Map<Id, SObject> existingRecords) {
		for (Financial_Account__c record : (List<Financial_Account__c>) Records) {
		}
	}
	/*******************************************************************************************************
	* @description before insert function to check if financial account with same name is exist or not
	*/
	public override void onBeforeInsert() {

		checkFinancialAccount(Records, null, 'insert');

	}
	/*******************************************************************************************************
	* @description function to check various conditions matches before saving new or edit existing financia account
	*/
	public void checkFinancialAccount(List<Financial_Account__c> Records, Map<Id, SObject> existingRecords, string frunction_from) {
		List<Financial_Account__c> currentAccountsPayableListOC = new cmsft_FinancialAccountSelector().get_finAccountValues('Operating_Checks__c');
		List<Financial_Account__c> currentAccountsPayableListRE = new cmsft_FinancialAccountSelector().get_finAccountValues('Retained_Earnings__c');
		List<Financial_Account__c> currentAccountsPayableListAPTrade = new cmsft_FinancialAccountSelector().get_finAccountValues('A_P_Trade__c');
		List<Financial_Account__c> currentAccountsPayableListUT = new cmsft_FinancialAccountSelector().get_finAccountValues('Use_Tax__c');

		Map<Id, Set<Id>> currentAccountsPayableListIds = new Map<Id, Set<Id>>();
		Map<Id, Set<Id>> currentAccountsPayableListIdsRE = new Map<Id, Set<Id>>();
		Map<Id, Set<Id>> currentAccountsPayableTradeListIds = new Map<Id, Set<Id>>();
		Map<Id, Set<Id>> currentAccountsPayableListUTIds = new Map<Id, Set<Id>>();
		Map<Id, Integer> countOCMap = new Map<Id, Integer>();
		Map<Id, Integer> countREMap = new Map<Id, Integer>();
		Map<Id, Integer> countAPMap = new Map<Id, Integer>();
		Map<Id, Integer> countUTMap = new Map<Id, Integer>();

		if (currentAccountsPayableListOC != null) {
			for (Financial_Account__c thisFinancialAccount : currentAccountsPayableListOC) {
				if (!countOCMap.containsKey(thisFinancialAccount.location__c)) {
					countOCMap.put(thisFinancialAccount.Location__c, 1);
				} else {
					countOCMap.put(thisFinancialAccount.Location__c, (countOCMap.get(thisFinancialAccount.Location__c)) + 1);
				}
				if (!currentAccountsPayableListIds.containsKey(thisFinancialAccount.Location__c)) {
					currentAccountsPayableListIds.put(thisFinancialAccount.Location__c, new Set<Id>());
				}
				currentAccountsPayableListIds.get(thisFinancialAccount.Location__c).add(thisFinancialAccount.id);
			}
		}
		if (currentAccountsPayableListRE != null) {
			for (Financial_Account__c thisFinancialAccount : currentAccountsPayableListRE) {
				if (!countREMap.containsKey(thisFinancialAccount.location__c)) {
					countREMap.put(thisFinancialAccount.Location__c, 1);
				} else {
					countREMap.put(thisFinancialAccount.Location__c, countREMap.get(thisFinancialAccount.Location__c) + 1);
				}
				if (!currentAccountsPayableListIdsRE.containsKey(thisFinancialAccount.Location__c)) {
					currentAccountsPayableListIdsRE.put(thisFinancialAccount.Location__c, new Set<Id>());
				}
				currentAccountsPayableListIdsRE.get(thisFinancialAccount.Location__c).add(thisFinancialAccount.id);
			}
		}
		if (currentAccountsPayableListAPTrade != null) {
			for (Financial_Account__c thisFinancialAccount : currentAccountsPayableListAPTrade) {
				if (!countAPMap.containsKey(thisFinancialAccount.location__c)) {
					countAPMap.put(thisFinancialAccount.Location__c, 1);
				} else {
					countAPMap.put(thisFinancialAccount.Location__c, countAPMap.get(thisFinancialAccount.Location__c) + 1);
				}
				if (!currentAccountsPayableTradeListIds.containsKey(thisFinancialAccount.Location__c)) {
					currentAccountsPayableTradeListIds.put(thisFinancialAccount.Location__c, new Set<Id>());
				}
				currentAccountsPayableTradeListIds.get(thisFinancialAccount.Location__c).add(thisFinancialAccount.id);
			}
		}
		if (currentAccountsPayableListUT != null) {
			for (Financial_Account__c thisFinancialAccount : currentAccountsPayableListUT) {
				if (!countUTMap.containsKey(thisFinancialAccount.location__c)) {
					countUTMap.put(thisFinancialAccount.Location__c, 1);
				} else {
					countUTMap.put(thisFinancialAccount.Location__c, countUTMap.get(thisFinancialAccount.Location__c) + 1);
				}
				if (!currentAccountsPayableListUTIds.containsKey(thisFinancialAccount.Location__c)) {
					currentAccountsPayableListUTIds.put(thisFinancialAccount.Location__c, new Set<Id>());
				}
				currentAccountsPayableListUTIds.get(thisFinancialAccount.Location__c).add(thisFinancialAccount.id);
			}
		}
		for (Financial_Account__c thisFinancialAccount : Records) {
			if (!countOCMap.containsKey(thisFinancialAccount.Location__c)) {
				countOCMap.put(thisFinancialAccount.Location__c, 0);
			}
			if (!countREMap.containsKey(thisFinancialAccount.Location__c)) {
				countREMap.put(thisFinancialAccount.Location__c, 0);
			}
			if (!countAPMap.containsKey(thisFinancialAccount.Location__c)) {
				countAPMap.put(thisFinancialAccount.Location__c, 0);
			}
			if (!countUTMap.containsKey(thisFinancialAccount.Location__c)) {
				countUTMap.put(thisFinancialAccount.Location__c, 0);
			}
			if (frunction_from == 'update') {
				Financial_Account__c oldRecord = (Financial_Account__c) existingRecords.get(thisFinancialAccount.id);
				if (oldRecord.Operating_Checks__c == true && thisFinancialAccount.Operating_Checks__c == false && currentAccountsPayableListIds.containsKey(thisFinancialAccount.Location__c) && currentAccountsPayableListIds.get(thisFinancialAccount.Location__c).contains(thisFinancialAccount.id)) {
					countOCMap.put(thisFinancialAccount.Location__c, countOCMap.get(thisFinancialAccount.Location__c) - 1);
				}
				if (oldRecord.Operating_Checks__c == false && thisFinancialAccount.Operating_Checks__c == true) {
					countOCMap.put(thisFinancialAccount.Location__c, countOCMap.get(thisFinancialAccount.Location__c) + 1);
				}
				if (oldRecord.Retained_Earnings__c == true && thisFinancialAccount.Retained_Earnings__c == false && currentAccountsPayableListIdsRE.containsKey(thisFinancialAccount.Location__c) && currentAccountsPayableListIdsRE.get(thisFinancialAccount.Location__c).contains(thisFinancialAccount.id)) {
					countREMap.put(thisFinancialAccount.Location__c, countREMap.get(thisFinancialAccount.Location__c) - 1);
				}
				if (oldRecord.Retained_Earnings__c == false && thisFinancialAccount.Retained_Earnings__c == true) {
					countREMap.put(thisFinancialAccount.Location__c, countREMap.get(thisFinancialAccount.Location__c) + 1);
				}
				if (oldRecord.A_P_Trade__c == true && thisFinancialAccount.A_P_Trade__c == false && currentAccountsPayableTradeListIds.containsKey(thisFinancialAccount.Location__c) && currentAccountsPayableTradeListIds.get(thisFinancialAccount.Location__c).contains(thisFinancialAccount.id)) {
					countAPMap.put(thisFinancialAccount.Location__c, countAPMap.get(thisFinancialAccount.Location__c) - 1);
				}
				if (oldRecord.A_P_Trade__c == false && thisFinancialAccount.A_P_Trade__c == true) {
					countAPMap.put(thisFinancialAccount.Location__c, countAPMap.get(thisFinancialAccount.Location__c) + 1);
				}
				if (oldRecord.Use_Tax__c == true && thisFinancialAccount.Use_Tax__c == false && currentAccountsPayableListUTIds.containsKey(thisFinancialAccount.Location__c) && currentAccountsPayableListUTIds.get(thisFinancialAccount.Location__c).contains(thisFinancialAccount.id)) {
					countUTMap.put(thisFinancialAccount.Location__c, countUTMap.get(thisFinancialAccount.Location__c) - 1);
				}
				if (oldRecord.Use_Tax__c == false && thisFinancialAccount.Use_Tax__c == true) {
					countUTMap.put(thisFinancialAccount.Location__c, countUTMap.get(thisFinancialAccount.Location__c) + 1);
				}
			}
			if (frunction_from == 'insert') {
				if (thisFinancialAccount.Operating_Checks__c == true) {
					countOCMap.put(thisFinancialAccount.Location__c, countOCMap.get(thisFinancialAccount.Location__c) + 1);
				}
				if (thisFinancialAccount.Retained_Earnings__c == true) {
					countREMap.put(thisFinancialAccount.Location__c, countREMap.get(thisFinancialAccount.Location__c) + 1);
				}
				if (thisFinancialAccount.A_P_Trade__c == true) {
					countAPMap.put(thisFinancialAccount.Location__c, countAPMap.get(thisFinancialAccount.Location__c) + 1);
				}
				if (thisFinancialAccount.Use_Tax__c == true) {
					countUTMap.put(thisFinancialAccount.Location__c, countUTMap.get(thisFinancialAccount.Location__c) + 1);
				}
			}

		}
		//restrict to insert/update the finacial account for same location which is already exist.
		for (Financial_Account__c thisFinancialAccount : Records) {
			if (countOCMap.get(thisFinancialAccount.Location__c) > 1) {
				if (thisFinancialAccount.Operating_Checks__c == true) {
					thisFinancialAccount.addError('There can only be one Financial Account with Operating Checks Checked');
				}
			}
			if (countREMap.get(thisFinancialAccount.Location__c) > 1) {
				if (thisFinancialAccount.Retained_Earnings__c == true) {
					thisFinancialAccount.addError('There can only be one Financial Account with Retained Earnings Checked');
				}
			}
			if (countAPMap.get(thisFinancialAccount.Location__c) > 1) {
				if (thisFinancialAccount.A_P_Trade__c == true) {
					thisFinancialAccount.addError('There can only be one Financial Account with A/P Trade Checked');
				}
			}
			if (countUTMap.get(thisFinancialAccount.Location__c) > 1) {
				if (thisFinancialAccount.Use_Tax__c == true) {
					thisFinancialAccount.addError('There can only be one Financial Account with Use Tax Checked');
				}
			}
		}
	}

	public class Constructor implements fflib_SObjectDomain.IConstructable2 {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new cmsft_FinancialAccountDomain(sObjectList);
		}

		public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
			return new cmsft_FinancialAccountDomain(sObjectList);
		}
	}
	/*******************************************************************************************************
	* @description function to check if financial account marching all condition before updating.
	*/
	public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {

		checkCharges(Records, existingRecords);
		checkDefaultAccounts(Records, existingRecords);
		checkFinancialAccount(Records, existingRecords, 'insert');

	}
	/*******************************************************************************************************
	* @description function to check if financial account is deletable or not.
	*/
	public override void onBeforeDelete() {

		//get data migration custom setting.
		Data_Migration_Settings__c dataMigrationSetting = Data_Migration_Settings__c.getOrgDefaults();
		Boolean preventDelete = true;
		if (dataMigrationSetting != null) {
			//check financial account can be deleted or not.
			if (dataMigrationSetting.Allow_Deletion_of_Financial_Accounts__c == true) {
				preventDelete = false;
			}
		}
		for (Financial_Account__c thisFinancialAccount : (List<Financial_Account__c>) Records) {
			//display error message
			if (preventDelete == true) {
				thisFinancialAccount.addError('You are not allowed to delete this record.');
			}
		}
	}

	public void checkCharges(List<Financial_Account__c> newAccts, Map<Id, SObject> oldAccts)
	{
		List<Id> acctIds = new List<Id>();
		for(Financial_Account__c fa : newAccts)
		{
			Financial_Account__c oldFa = (Financial_Account__c)oldAccts.get(fa.Id);
			if(oldFa.Active__c==true && fa.Active__c==false)
			{
				acctIds.add(fa.Id);
			}
		}

		List<Charge_Item__c> items = (List<Charge_Item__c>)Data.read(
                'select Id, Name, isActive__c, Financial_Account__c from Charge_Item__c where isActive__c=true and Financial_Account__c in: acctIds',
                new Map<String, Object> {
                    'acctIds' => acctIds
                }
            );

		if(items!=null && items.size()>0)
		{
			for(Financial_Account__c fa : newAccts)
			{
				Boolean foundActiveChargeItem = false;
				for(Charge_Item__c item : items)
				{
					if(item.Financial_Account__c == fa.Id)
					{
						foundActiveChargeItem = true;
					}
				}

				if(foundActiveChargeItem)
				{
					fa.addError('This account cannot be deactivated because it is tied to an active Charge Item.',false);
				}
			}
		}
	}

	public void checkDefaultAccounts(List<Financial_Account__c> newAccts, Map<Id, SObject> oldAccts)
	{
		List<Id> acctIds = new List<Id>();
		for(Financial_Account__c fa : newAccts)
		{
			Financial_Account__c oldFa = (Financial_Account__c)oldAccts.get(fa.Id);
			if(oldFa.Active__c==true && fa.Active__c==false)
			{
				acctIds.add(fa.Id);
			}
		}

		List<Default_Account__c> items = (List<Default_Account__c>)Data.read(
                'select Id, Name from Default_Account__c where Financial_Account__c in: acctIds',
                new Map<String, Object> {
                    'acctIds' => acctIds
                }
            );

		if(items!=null && items.size()>0)
		{
			for(Financial_Account__c fa : newAccts)
			{
				fa.addError('This account cannot be deactivated because it is referenced on a default account');
			}
		}
	}

}