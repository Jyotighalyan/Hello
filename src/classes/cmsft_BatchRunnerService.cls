/**
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Service_Layer
 * @Description : Encapsulates all service layer logic for the Batch Runner Controller classes in the application 
 * @Date : 5th June - 2017
 * @Group : Financial Management
 */

public class cmsft_BatchRunnerService
{

	/**
	* @Description : method to get status of the passed batch, currently running or not
	*/
	public boolean getStatusOfBatchService(String batchName)
	{
		return cmsft_APAgingBatchRunnerImpl.getStatusOfBatch(batchName);
	}

	/**
	* @Description : get AP_Aging__c custom setting record
	*/
	public Account getAgingEffectiveDateService()
	{
		return cmsft_APAgingBatchRunnerImpl.getAgingEffectiveDate();
	}

	/**
	* @Description : get AP_Aging__c custom setting record
	*/
	public AP_Aging__c getInProgressAgingEffectiveDateService()
	{
		return cmsft_APAgingBatchRunnerImpl.getInProgressAgingEffectiveDate();
	}

	/**
	* @Description : returns the effective date for AP aging calculation
	*/
	public Id runBatchService()
	{
		return cmsft_APAgingBatchRunnerImpl.runBatch();
	}
}