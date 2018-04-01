/**
* @Description : controller for the BatchStatus component 
* @Author : Jyotig@mobifyi.com
* @Date : 12th June - 2017
*/
public with sharing class BatchStatusController {

	public Id batchId {get;set;}
	public Integer errornum {get;set;}
	public String redirectToPage {get; set;}

	public BatchJobs currentJob {
		get
		{
			List<AsyncApexJob> apexJobs = [Select TotalJobItems, Status, NumberOfErrors, ExtendedStatus, JobItemsProcessed, Id, JobType, ApexClassId, CreatedDate From AsyncApexJob Where Id =: batchId];
			if(apexJobs.size()>0)
			for(AsyncApexJob asyncJobObj :apexJobs){
				if(asyncJobObj.id!=batchId)
					continue;
				BatchJobs bj = new BatchJobs();
				bj.isCompleted = false;
				bj.aj = asyncJobObj;

				if(asyncJobObj.jobItemsProcessed==0){
					bj.Percent= 0;
					return bj;
				}

				Decimal d = asyncJobObj.jobItemsProcessed;
				d = d.divide(asyncJobObj.TotalJobItems, 2)*100;
				bj.Percent = d.intValue();

				if(bj.Percent!=100){
					return bj;
				}
				else{
					errornum += asyncJobObj.NumberOfErrors;
					bj.isCompleted = true;
					currentJob = bj;
				}
			}
			return currentJob;
		}
		set;
	}
	
	public BatchStatusController() {
		redirectToPage = '/apex/'+redirectToPage;
		errornum =0;
	}

	public void updateProgress() {
    }

    /**
    * @Description : job structure to represent the batch job
    */
	public class BatchJobs
	{
		public AsyncApexJob aj {get;set;}
		public Integer Percent {get;set;}
		public Boolean isCompleted {get;set;}
	}
}