/*
@Name               : TaxToAccountMappingController
@Author             : kiran patel
@Date               : june, 2017
@Description        : Mapping of Taxes and Service Charges
to respective Financial Accounts.
*/
public with sharing class TaxToAccountMappingController 
{
    public TaxToAccountMappingContService serviceImpObj;
    public Map<String,String> AllTax{get;set;}
    public Map<String,String> AllServiceCharge{get;set;}
    public Map<String,String> AllUseTaxes{get;set;}
    public List<Tax_To_Account_Mapping__c> accts{get;set;}
    public List<Tax_To_Account_Mapping__c> servChar{get;set;}
    public List<Tax_To_Account_Mapping__c> UseTaxes{get;set;}
    public string tabname {get; set;}
    
    public TaxToAccountMappingController()
    {
        tabname = 'Taxes';
        serviceImpObj =new TaxToAccountMappingContService();
        AllTax = serviceImpObj.allTaxes();
        AllServiceCharge = serviceImpObj.allServiceCharges();
        AllUseTaxes = serviceImpObj.allUseTaxes();
        
        string message=''+ApexPages.CurrentPage().GetParameters().Get('message');
        if(message!=''&&message!='null'){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.CONFIRM,message));
        }
        accts = serviceImpObj.checkDeletedTaxes(serviceImpObj.getTaxesFromObj(),AllTax);
        servChar = serviceImpObj.checkDeletedServiceCharges(serviceImpObj.getServiceChargesFromObj(),AllServiceCharge);
        UseTaxes = serviceImpObj.checkDeletedUseTaxes(serviceImpObj.getUseTaxesFromObj(),AllUseTaxes);
    }

    /*Saving all the Records*/
    public PageReference save(){
        AllTax = serviceImpObj.allTaxes();
        AllServiceCharge = serviceImpObj.allServiceCharges();
        AllUseTaxes = serviceImpObj.allUseTaxes();
        serviceImpObj =new TaxToAccountMappingContService();
        PageReference pg;
        boolean isValidationsPassed = false;
        if(tabName=='Taxes')
        {
            for(Tax_To_Account_Mapping__c txnToFinMapp :accts){
                if(txnToFinMapp.Financial_Accounts__c==null){
                    isValidationsPassed = true;
                }
            }
        }
        else if(tabName=='Service Charge')
        {
            for(Tax_To_Account_Mapping__c txnToFinMapp :servChar){
                if(txnToFinMapp.Financial_Accounts__c==null){
                    isValidationsPassed = true;
                }
            }
        }
        else if (tabName=='Use Taxes')
        {
            for(Tax_To_Account_Mapping__c txnToFinMapp :UseTaxes){
                if(txnToFinMapp.Financial_Accounts__c==null){
                    isValidationsPassed = true;
                }
            }
        }
        if(isValidationsPassed){
            ApexPages.AddMessage(new ApexPages.message(ApexPages.Severity.Error, 'Please fill the value in required fields.'));
            return null;
        }
        else
        pg = serviceImpObj.save(accts,AllTax,servChar,AllServiceCharge,UseTaxes,AllUseTaxes);
        accts = serviceImpObj.getTaxesFromObj();
        servChar = serviceImpObj.getServiceChargesFromObj();
        UseTaxes = serviceImpObj.getUseTaxesFromObj();
        serviceImpObj.deleteRecord(accts,AllTax,servChar,AllServiceCharge,UseTaxes,AllUseTaxes);
        return pg;
        
    }
}