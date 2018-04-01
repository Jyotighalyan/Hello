/**
* @author joshi Prakash
* @date 07-07-2017
* @group Financial Management
* @description Update the credit and debit total on financial account whenever the financial journal line is updated deleted or inserted.
 **/
public with sharing class FinancialJournalLineTriggerHandler {
	/**
	* @description Method to handle insert update and delete at same time. 
	* @param List of records which are affected during the trigger action.
 	**/
 	
	public static void AfterInsertUpdateDelete(List<Financial_Journal_Line__c> records) {
		CalculateCreditDebit(records);
	}

	/**
	* @description Calculates the credit and debit sum on the finacial account in credit and debit field.
	* @param List of records.
 	**/

	private static void CalculateCreditDebit(List<Financial_Journal_Line__c> records) {
		Set<id> financialAccountIds = new Set<id>();
		List<Financial_Account__c> financialAccountToUpdate = new List<Financial_Account__c>();

		for (Financial_Journal_Line__c item : records) {
			financialAccountIds.add(item.Financial_Account__c);
		}

		//Query all the finacial journal lines for each finacial account
		List<Financial_Account__c> finacialAccounts = (List<Financial_Account__c>)Data.read(
		            'select Id, Name, Credit_Text__c, Debit_Text__c, (select id, Credit__c, Debit__c, Posted__c, Recurring_Journal_Line__c from Financial_Journal_Lines__r) from Financial_Account__c where Id IN :financialAccountIds',
		new Map<String, Object> {
			'financialAccountIds' => financialAccountIds
		});

		//loop over to the finacial account and update credit and debit.
		for (Financial_Account__c faccount : finacialAccounts) {
			faccount.Credit_Text__c = 0.00;
			faccount.Debit_Text__c = 0.00;
			for (Financial_Journal_Line__c fjl : faccount.Financial_Journal_Lines__r) {
				if (fjl.Posted__c == true && fjl.Recurring_Journal_Line__c != true) {
					if (fjl.Credit__c != null) {
						faccount.Credit_Text__c += fjl.Credit__c;

					}

					if (fjl.Debit__c != null) {
						faccount.Debit_Text__c += fjl.Debit__c;

					}
				}
			}

			financialAccountToUpdate.add(faccount);
		}
		Data.modify(financialAccountToUpdate);
	}
}