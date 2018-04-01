/**
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Service_Layer
 * @Date: 20th May - 2017
 * @Author: Jyotig@mobifyi.com 
 * @group: Financial Management 
 * @Description: service layer for AccountsPayableController
 */

public with sharing class cmsft_AccountPayableService
{
	/**
    * @Description : method to search vendor invoices that are not posted between startdate and enddate
    */
	public List<Vendor_Invoice__c> getVendorInvoiceListService(Date startDate, Date endDate){
		return cmsft_AccountPayableServiceImpl.getVendorInvoiceListImpl(startDate, endDate);
	}

	/**
    * @Description : method to post selected vendor invoices
    */
	public void postSelectedEnteriesService(List<Vendor_Invoice__c> unpostedVendInv, Date postDate, Date endDate){
		cmsft_AccountPayableServiceImpl.postSelectedEnteries(unpostedVendInv, postDate, endDate);
	}

	/**
    * @Description : method to get invoices that are posted today
    */
	public List<Vendor_Invoice__c> getListOfPostedInvoicesService(Date startDate, Date endDate){
		return cmsft_AccountPayableServiceImpl.getListOfPostedInvoices(startDate, endDate);
	}

	/**
    * @Description : method to get invoices that are selected for posting
    */
	public List<Vendor_Invoice__c> getListOfSelectedInvoicesForPostingService(List<Vendor_Invoice__c> vendInvList){
		return cmsft_AccountPayableServiceImpl.getListOfSelectedInvoicesForPosting(vendInvList);
	}

	/**
	* @Description : method to check amount of vendor invoice is equal to sum of vendor invoice line amount or not
	* @return : true if not equals
	*/
	public List<Vendor_Invoice__c> checkAmountService(List<Vendor_Invoice__c> vendInv, String amountEqualStatus)
	{
		return cmsft_AccountPayableServiceImpl.checkAmount(vendInv, amountEqualStatus);
	}

	/**
	* @Description : mark the passed vendor invoice post status as checked
	*/
	public List<Vendor_Invoice__c> markInvoicePostStatusCheckedService(List<Vendor_Invoice__c> unpostedVendInv, List<Vendor_Invoice__c> InvListToChangePS)
	{
		return cmsft_AccountPayableServiceImpl.markInvoicePostStatusChecked(unpostedVendInv, InvListToChangePS);
	}

	/**
	* @Description : change post date of financial journal entry
	*/
	public void changePostDateOfFJEService(List<Financial_Journal_Entry__c> finJeEntryList)
	{
		cmsft_AccountPayableServiceImpl.changePostDateOfFJE(finJeEntryList);
	}
}