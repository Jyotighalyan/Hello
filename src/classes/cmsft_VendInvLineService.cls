/**
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Service_Layer
 * @Date: 20th May - 2017
 * @Author: Jyotig@mobifyi.com 
 * @group: Financial Management 
 * @Description: service class for VendInvLine controller class
 */

public with sharing class cmsft_VendInvLineService
{
	
	/**
    * @Description : get vendor invoice line complete record service with passed id
    * @return : returns vendor Invoice Line object after querying
    */
	public Vendor_Invoice_Line__c getVendorInvoiceLineFullRecordService(string vilId){
		return cmsft_VendInvLineServiceImpl.getVendorInvoiceLineFullRecord(vilId);
	}

	/**
    * @Description : get vendor invoice complete record service with passed id
    * @return : returns vendor Invoice object after querying
    */
	public Vendor_Invoice__c getVendorInvoiceFullRecordService(string vilId){
		return cmsft_VendInvLineServiceImpl.getVendorInvoiceFullRecord(vilId);
	}

	/**
    * @Description : get vendor invoice with passed endor invoice line record
    * @return : returns vendor Invoice Line object after querying
    */
	public Vendor_Invoice__c getVendorInvoiceForNewNEditVILService(Vendor_Invoice_Line__c vil){
		return cmsft_VendInvLineServiceImpl.getVendorInvoiceForNewNEditVIL(vil);
	}

	/**
    * @Description : method to return error if the passed invoice is already posted
    * @return : returns boolean if true then error
    */
	public boolean returnErrorIfInvoiceAlreadyPostedService(Vendor_Invoice__c vendInv){
		return cmsft_VendInvLineServiceImpl.returnErrorIfInvoiceAlreadyPosted(vendInv);
	}

	/**
    * @Description : method for saving invoice lines
    * @return : returns page to be refreshed
    */
	public pageReference saveNewService(List<Vendor_Invoice__c> vin,List<Vendor_Invoice_Line__c> vilRec, List<string> saveOrSaveNew){
		return cmsft_VendInvLineServiceImpl.saveNew(vin, vilRec, saveOrSaveNew);
	}

	/**
	* @Description : method to get default account of vendor to fill on vendor invoice line
	*/
	public List<Vendor_Invoice_Line__c> fillDefaultAccountService(List<Vendor_Invoice_Line__c> vendInvLineList, String vendId)
	{
		return cmsft_VendInvLineServiceImpl.fillDefaultAccount(vendInvLineList, vendId);
	}
}