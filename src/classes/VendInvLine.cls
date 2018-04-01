/**
 * @Date: 20th May - 2017
 * @Author: Jyotig@mobifyi.com 
 * @group: Financial Management 
 * @Description: controller class for CreateVendInvLine page
 */

public with sharing class VendInvLine {
    public Vendor_Invoice__c vendInv {get; set;}
    public Vendor_Invoice_Line__c venInvLine {get; set;}

    // if invoice already posted then make isPosted true and request coming for edit make isEditBoolean true
    public boolean isEditBoolean {get; set;}
    public boolean isPosted {get; set;} 

    // service class variable
    public cmsft_VendInvLineService service;

    /**
    * @Description : fill vendor invoice variable vendInv with the coming record id or create new and assign to it in case of save&New
    */
    public VendInvLine(ApexPages.StandardController std) {
        service = new cmsft_VendInvLineService();
        venInvLine = (Vendor_Invoice_Line__c)std.getRecord();
        isEditBoolean = false;
        isPosted = false;
        if(ApexPages.currentPage().getParameters().get('id')!=null){
            isEditBoolean = true;
            venInvLine = service.getVendorInvoiceLineFullRecordService(ApexPages.currentPage().getParameters().get('id'));
            vendInv = service.getVendorInvoiceFullRecordService(venInvLine.Vendor_Invoice__c);
        }
        else if(std.getRecord()!=null && venInvLine.Vendor_Invoice__c!=null){
            vendInv = service.getVendorInvoiceForNewNEditVILService(venInvLine);
        }
        else if(ApexPages.currentPage().getParameters().get('vid')!=null){
            venInvLine = new Vendor_Invoice_Line__c(Vendor_Invoice__c = ApexPages.currentPage().getParameters().get('vid'));
            vendInv = service.getVendorInvoiceFullRecordService(ApexPages.currentPage().getParameters().get('vid'));
        }

        // fill the new financial account on records with default financial account on vendor
        if(venInvLine.Financial_Account__c==null)
        venInvLine = service.fillDefaultAccountService(new List<Vendor_Invoice_Line__c> {venInvLine}, vendInv.Vendor__c).get(0);
        isPosted = service.returnErrorIfInvoiceAlreadyPostedService(vendInv);
        if(isPosted) return;
    }

    /**
    * @Description : overriding default save method so that after save&New the record can be saved 
    * @return : redirect on vendor invoice detail page after save
    */
    public PageReference save(){
        return service.saveNewService(new List<Vendor_Invoice__c> {vendInv}, new List<Vendor_Invoice_Line__c> {venInvLine},  new List<String> {'save'});
    }

     /**
    * @Description : method to handle save&New action
    * @return : redirect to create new vendor invoice line after save
    */
    public pageReference savenew(){
        try{
        return service.saveNewService(new List<Vendor_Invoice__c>{vendInv}, new List<Vendor_Invoice_Line__c> {venInvLine}, new List<String> {'saveNew'});
        }
        catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,ex.getMessage()));
            return null;
        }
    }
    /**
    * @Description : cancel method overriding
    */
    public PageReference cancel()
    {
        PageReference pg = new PageReference(URL.getSalesforceBaseUrl().toExternalForm() + '/'+vendInv.id);
        pg.setRedirect(true);
        return pg;
    }
}