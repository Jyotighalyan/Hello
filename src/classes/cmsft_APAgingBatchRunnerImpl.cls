/**
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Service_Layer
 * @Description : Bussiness class for APAgingBatchRunnerController - contains bussiness logic for APAgingBatchRunnerController
 * @Date : 5th June - 2017
 * @Author : Jyotig@mobifyi.com
 * @Group : Financial Management
 */
public with sharing class cmsft_APAgingBatchRunnerImpl {

	/**
	* @Description : method implementation of getting status of the passed batch
	* @return : returns true of the passed batch name is active
	*/
	public static boolean getStatusOfBatch(String batchName) {
		List<SObject> asyncJ = Data.read('select TotalJobItems, Status, NumberOfErrors From AsyncApexJob where JobType = \'BatchApex\' and ApexClass.Name = :batchName and Status in :listOfExpStatus', new Map<String, Object> {'batchName' => batchName, 'listOfExpStatus' => new List<String> {'Queued', 'Pending', 'Active', 'Preparing', 'Processing'}});
		System.debug(asyncJ);
		if (asyncJ.size() > 0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, 'The APAgingBatch is in progress for Effective Date : ' + String.valueOf(getInProgressAgingEffectiveDate().Effective_Date__c).split(' ')[0] + '.<br/> You will get an email of status once processing will complete.'));
			return true;
		} else {
			if (getAgingEffectiveDate().id != null)
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, 'AP Aging Batch with Effective Date of ' + String.valueOf(getAgingEffectiveDate().Aging_Effective_Date__c).split(' ')[0] + ' was successful.'));
			else
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, 'Run the batch to check a Report on AP aging.'));
			return false;
		}
	}

	/**
	* @Description : method to get the AP_Aging__c list custom setting Effective Date Record data
	*/
	public static Account getAgingEffectiveDate() {
		List<Account> toGetLastEffectiveDate = new cmsft_AccountSelector().getAccountsWithPassedCondition('Aging_Effective_Date__c != null');
		Account AccObj;
		if (toGetLastEffectiveDate.size() > 0)
			AccObj =  toGetLastEffectiveDate[0];
		else {
			AccObj = new Account(Aging_Effective_Date__c = Date.today());
		}
		return AccObj;
	}

	/**
	* @Description : method to get the AP_Aging__c list custom setting Effective Date Record data
	*/
	public static AP_Aging__c getInProgressAgingEffectiveDate() {
		String effecDateRec = 'Effective Date Record';
		//List<AP_Aging__c> ApAging = [select Effective_Date__c from AP_Aging__c where name =:String.escapeSingleQuotes(effecDateRec)];
		List<AP_Aging__c> ApAging = (List<AP_Aging__c>)Data.read('select Effective_Date__c, Last_Run_Of_Member_Aging__c from AP_Aging__c where name =: agingName',
		                            new Map<String, Object> {'agingName' => String.escapeSingleQuotes(effecDateRec)});

		AP_Aging__c ApAgingObj;
		if (ApAging.size() > 0)
			ApAgingObj =  ApAging[0];
		else {
			ApAgingObj = new AP_Aging__c(Name = 'Effective Date Record');
		}
		return ApAgingObj;
	}

	/**
	* @Description : method to call APAgingBatch batch to update aging related fields on vendor
	*/
	public static Id runBatch() {
		APAgingBatch batch = new APAgingBatch();
		return Database.executeBatch(batch);
	}
}