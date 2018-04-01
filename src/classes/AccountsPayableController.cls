/**
 * @Description: controller class for AccountPayable page
 * @Author: Jyotig@mobifyi.com
 * @Date: 16th May - 2017
 * @group: Financial Management
 */

public with sharing class AccountsPayableController {
	public Vendor_Invoice__c vendInvForDate {get;set;}
	public List<Vendor_Invoice__c> unpostedVenInvList {get; set;}
	public cmsft_AccountPayableService service;
	public List<Vendor_Invoice__c> postedVenInvList {get; set;}
	public Integer numberOfFailedPosting {get; set;}
	public Integer numberOfPostedInv {get; set;}
	public Integer numberOfSelectedInvoices {get; set;}
	public String takeConfirm {get; set;}
	public boolean isAlreadyPosted {get; set;}
	public Vendor_Invoice__c currentVendInv {get; set;}
	public Financial_Journal_Entry__c finJeEntry {get; set;}
	public boolean erInFinJeSetup {get; set;}

	public AccountsPayableController(){
		erInFinJeSetup = false;
		service = new cmsft_AccountPayableService();
		Date searchDate1=Date.today();
		Date searchDate2 = Date.today();

		// get id of vendor invoice from which post invoice is clicked - param from url
		List<Vendor_Invoice__c> vendInvcsList;
		if(ApexPages.currentPage().getParameters().get('Vid')!=null){
		    vendInvcsList = new cmsft_vendorInvoiceTriggerSelector().selectById(new Set<Id> {ApexPages.currentPage().getParameters().get('Vid')});
		    if(vendInvcsList.size()<1){
		    	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info,'Unexpected Id received while setting up the page!!!'));
		    	return;
		    }
		    else{
		    	currentVendInv = vendInvcsList[0];
		    	if(searchDate1<currentVendInv.Invoice_Date__c)
		    		searchDate2 = currentVendInv.Invoice_Date__c;
		    	else	
		    		searchDate1 = currentVendInv.Invoice_Date__c;
		    	isAlreadyPosted = currentVendInv.Posted__c;		
		    }
		}
		vendInvForDate = new Vendor_Invoice__c(Invoice_Date__c=searchDate1, Post_Date__c=Date.today(), Due_Date__c= searchDate2);
		unpostedVenInvList = service.getVendorInvoiceListService(vendInvForDate.Invoice_Date__c, vendInvForDate.Due_Date__c);
		postedVenInvList = service.getListOfPostedInvoicesService(vendInvForDate.Invoice_Date__c, vendInvForDate.Due_Date__c);

		// make the poted checkbox true for the passed invoice
		if(ApexPages.currentPage().getParameters().get('Vid')!=null){
			if(vendInvcsList.size()>0)
			service.markInvoicePostStatusCheckedService(unpostedVenInvList, vendInvcsList);
		}
		numberOfPostedInv=0;
		numberOfFailedPosting=0;

		// check if coming from financial journal entry detail page
		if(ApexPages.currentPage().getParameters().get('FjeId')!=null){
			List<Financial_Journal_Entry__c> finJeList = Data.read('Select Id, Post_Date__c, Posted__c from Financial_Journal_Entry__c where Id=:finJeId', new Map<String, Object> {'finJeId' => ApexPages.currentPage().getParameters().get('FjeId')});
			if(finJeList==null || finJeList.size()<1){
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Financial Journal Entry Id is incorrect.'));
				erInFinJeSetup = true;
				return;
			}
			else 
				finJeEntry = finJeList[0];
		}
	}

	/**
    * @Description : method to search vendor invoices that are not posted between startdate and enddate
    */
	public void SearchAPEnteries(){
		if(vendInvForDate.Invoice_Date__c>vendInvForDate.Due_Date__c)
		{
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Start date should be less than End date.'));
			return;
		}
		unpostedVenInvList = service.getVendorInvoiceListService(vendInvForDate.Invoice_Date__c, vendInvForDate.Due_Date__c);
		postedVenInvList = service.getListOfPostedInvoicesService(vendInvForDate.Invoice_Date__c, vendInvForDate.Due_Date__c);
	}

	/**
    * @Description : Cancel editing post date and go back to the vendor invoice details page.
    */
	public pageReference cancelEdit()
	{
		return new ApexPages.StandardController(finJeEntry).view();	
	}

	/**
    * @Description : controller method to post the enteries
    * @return : to refresh the page after post enteries
    */
	public void postEnteries(){
		if(vendInvForDate.Post_Date__c==null){
			 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Post Date is required.'));
			 takeConfirm='';
			 return;
		}
		if(takeConfirm=='confirm'){
			unpostedVenInvList = service.getListOfSelectedInvoicesForPostingService(unpostedVenInvList);
			numberOfSelectedInvoices = unpostedVenInvList.size();
			List<Vendor_Invoice__c> toBeFailedInvoices = service.checkAmountService(unpostedVenInvList, 'Amount Not Equal');
			if(toBeFailedInvoices!=null && toBeFailedInvoices.size()>0)
			   numberOfFailedPosting = toBeFailedInvoices.size();
		}
		else if(takeConfirm=='post'){
			unpostedVenInvList = service.checkAmountService(unpostedVenInvList, 'Amount Equal');
		    service.postSelectedEnteriesService(unpostedVenInvList, vendInvForDate.Post_Date__c, vendInvForDate.Due_Date__c);
		    numberOfPostedInv = unpostedVenInvList.size();
            unpostedVenInvList = service.getVendorInvoiceListService(vendInvForDate.Invoice_Date__c, vendInvForDate.Due_Date__c);
            postedVenInvList = service.getListOfPostedInvoicesService(vendInvForDate.Invoice_Date__c, vendInvForDate.Due_Date__c);
		}
	}

	/**
	* @Description : method to change the post date of the financial journal entry
	*/
	public PageReference UpdateFinJEPostDate()
	{
		service.changePostDateOfFJEService(new List<Financial_Journal_Entry__c> {finJeEntry});
		return new ApexPages.StandardController(finJeEntry).view();
	}
}