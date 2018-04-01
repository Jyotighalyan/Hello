/**
* @Description : controller for the batch run page
* @Author : Jyotig@mobifyi.com
* @Date : 5th June 2017
*/
public with sharing class APAgingBatchRunnerController {

	// get status of the current batch
	public boolean runningBatchStatus {get; set;}
	// variable to store effective date from custom setting
	public Account EffecDate {get; set;}
	// service class instance
	public cmsft_BatchRunnerService service;
	public Id batchId {get; set;}
	private String name;
	private AP_Aging__c agCuSetting;

	/**
	* @Description : Controller of the class
	*/
	public APAgingBatchRunnerController() {
		name = ApexPages.currentPage().getParameters().get('Name');
		service = new cmsft_BatchRunnerService();
		if(name=='APAging'){
			runningBatchStatus = service.getStatusOfBatchService('APAgingBatch');
			EffecDate = service.getAgingEffectiveDateService();
		}
		else if(name=='MemberAging'){
			runningBatchStatus = false;
			agCuSetting = service.getInProgressAgingEffectiveDateService();
			batchId = GenerateDuesController.getStatusOfBatch('MemberAgingBatch');
			if(batchId!=null){
				runningBatchStatus = true;
			}
			if(agCuSetting.id!=null && agCuSetting.Last_Run_Of_Member_Aging__c!=null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, 'ARAgingBatch with Effective Date of ' + String.valueOf(agCuSetting.Last_Run_Of_Member_Aging__c).split(' ')[0] + ' was successful.'));
			}
			else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, 'Run the batch to check a Report on Member aging.'));
			}
			EffecDate = new Account(Aging_Effective_Date__c=Date.today());
		}
	}

	/**
	* @Description : responsible for running the batch to update Aging fields on Account for vendor
	*/
	public void runBatch(){
		if(name=='APAging'){
			AP_Aging__c agCuSetting = service.getInProgressAgingEffectiveDateService();
			agCuSetting.Effective_Date__c = EffecDate.Aging_Effective_Date__c;

			// Update in progress AP batch effective date in custom setting called AP_Aging__c
			Data.upsurt(new List<SObject> {agCuSetting}, Schema.AP_Aging__c.Id, new Set<String>());
			batchId = service.runBatchService();
		}
		else if(name=='MemberAging'){
			ARAgingBatch memAgingBatch = new ARAgingBatch(EffecDate.Aging_Effective_Date__c);
			batchId = Database.executeBatch(memAgingBatch, 9000);
		}
		runningBatchStatus = true;
	}
}