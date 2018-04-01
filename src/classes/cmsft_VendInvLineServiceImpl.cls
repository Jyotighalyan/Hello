/**
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Service_Layer
 * @Date: 20th May - 2017
 * @Author: Jyotig@mobifyi.com 
 * @group: Financial Management 
 * @Description: service class for VendInvLine class
 */

public with sharing class cmsft_VendInvLineServiceImpl {

    /**
    * @Description : bussiness logic behing getting vendor invoice line complete record service with passed id
    * @return : returns vendor Invoice Line object after querying
    */
    public static Vendor_Invoice_Line__c getVendorInvoiceLineFullRecord(string vilId){
        Set<Id> vidSet = new Set<Id>();
        vidSet.add(vilId);
        return new cmsft_vendorInvoiceLineTriggerSelector().selectById(vidSet).get(0);
    }

    /**
    * @Description : bussiness logic behind getting vendor invoice complete record service with passed id
    * @return : returns vendor Invoice object after querying
    */
    public static vendor_invoice__c getVendorInvoiceForNewNEditVIL(Vendor_Invoice_Line__c vil){
        Set<Id> vidSet = new Set<Id>();
        vidSet.add(vil.Vendor_Invoice__c);
        return new cmsft_vendorInvoiceTriggerSelector().selectById(vidSet).get(0);
    }

   /**
    * @Description : bussiness logic behind getting vendor invoice with passed endor invoice line record
    * @return : returns vendor Invoice Line object after querying
    */
    public static vendor_invoice__c getVendorInvoiceFullRecord(String viId){
        Set<Id> vidSet = new Set<Id>();
        vidSet.add(viId);
        return new cmsft_vendorInvoiceTriggerSelector().selectById(vidSet).get(0);
    }
    
    /**
    * @Description : bussiness logic behind return error if the passed invoice is already posted
    * @return : returns boolean if true then error
    */
    public static boolean returnErrorIfInvoiceAlreadyPosted(Vendor_Invoice__c vendInv){
        if(vendInv.Posted__c){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Invoice Lines can not be added/updated to posted invoice.'));
        return true;
        }
        return false;
    }

    /**
    * @Description : bussiness logic behind saving invoice lines , throw exception if no rights to the user to modify the Vendor_Invoice_Line__c object
    * @return : returns page to be refreshed
    */
    public static pageReference saveNew(List<Vendor_Invoice__c> vin, List<Vendor_Invoice_Line__c> vilRec, List<string> saveOrSaveNew){
        try{
        	Data.upsurt(vilRec, Vendor_Invoice_Line__c.Id.getDescribe().getSObjectField(), new Set<String>());    
        }catch (Exception e){
            return null;
        }
        
        if(saveOrSaveNew.get(0)=='save')
        {
            return new PageReference('/'+vin.get(0).id);
        }
        else {
            PageReference pg = new PageReference('/apex/CreateVendInvLine?vid='+vin.get(0).id);
            pg.setRedirect(true);
            return pg;
        }
    }

    /**
    * @Description : get vendor default account and fill this in vendor invoice line
    */
    public static List<Vendor_Invoice_Line__c> fillDefaultAccount(List<Vendor_Invoice_Line__c> vendInvLineList, String vendId)
    {
        String finAccId = new cmsft_AccountSelector().getAccountsWithPassedCondition('Id=\''+vendId+'\'').get(0).Default_Account__c;
        for(Vendor_Invoice_Line__c vendInvObj :vendInvLineList)
        {
            vendInvObj.Financial_Account__c = finAccId;
        }
        return vendInvLineList;
    }
}