/*
@Name               : TxnAllTaxesController
@Author             : kiran@3embed.com
@Date               : January , 2016
@Description        : The above combination of VF and APEX used to display the 
                      list of charges which are currently mapped with the taxes.
*/
public with sharing class TxnAllTaxesController{
    
    public List<string> allTxnTypes;
    public List<string> allTxnSubtypes;
    public Map<String, double> mapOfTaxesAndItsVal = new Map<String, double>();

    public TxnAllTaxesController(){
     allTxnTypes = new List<string>();
     allTxnSubtypes = new List<string>();

     string name='';
        double value=0;
        Map<string,Schema.SObjectField> fieldsMap=Taxes__c.sObjectType.getDescribe().fields.getMap();
        Set<string> customHierarchyFieldNames=new  Set<string>();
        for(string field:fieldsMap.keySet()){
            Schema.SObjectField F=fieldsMap.get(field);
            Schema.DescribeFieldResult R=F.getDescribe();
            if(R.isCustom()){
                string fName=R.getName();
                    Taxes__c allTaxesHSettings=Taxes__c.getInstance();
                try
                {
                    value=double.valueOf(allTaxesHSettings.get(fName));
                    mapOfTaxesAndItsVal.put(fName, value);
                }
                catch(Exception e)
                { 
                    // there are fields that aren't doubles in the Custom Setting.
                }
            }
        }

        
     Schema.DescribeFieldResult fieldResult = TXN__c.GlobalType__c.getDescribe(); 
     List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
     for( Schema.PicklistEntry f : ple)
      allTxnTypes.add(f.getLabel());
        
     Schema.DescribeFieldResult fieldResultsub = TXN__c.GlobalSubType__c.getDescribe(); 
     List<Schema.PicklistEntry> plesub = fieldResultsub.getPicklistValues();
     for( Schema.PicklistEntry f : plesub)
      allTxnSubtypes.add(f.getLabel());    
    }
    
    public class aTableRow{
        public string Name{get;set;}
        public string Charge{get;set;}
        public string ChargeId{get;set;}
        public string Type{get;set;}
        public string SubType{get;set;}
        public Boolean SCApplicable{get;set;}
        public string SC{get;set;}
        public List<SelectOption> Taxes{get;set;}
        public Boolean TaxOnSErviceCharge{get;set;}
        public string financialAccount {get; set;}
        public string defaultFinancialAccount {get; set;}
        
        public aTableRow(string txnId,string txnCharge,string txnChargeId,string txnType,string txnSubType,List<SelectOption> txnTaxes,boolean txnSCApplicable,string txnSC,Boolean txnTaxOnSErviceCharge, string finAc, string defFinAc){
            Name=txnId;
            Charge=txnCharge;
            Type=txnType;
            SubType=txnSubType;
            ChargeId=txnChargeId;
            SCApplicable=txnSCApplicable;
            SC=txnSC;
            Taxes=txnTaxes;
            TaxOnSErviceCharge=txnTaxOnSErviceCharge;
            financialAccount=finAc;
            defaultFinancialAccount=defFinAc;
        }
    }
/*club62_FT_TXN
auther:joshi
date:22/3/2016
description:Get all the charges on the member for displaying in the charges table
*/
    public List<aTableRow> allCharges{
        get{
            List<aTableRow> dataRows=new  List<aTableRow>();
            string ChargeId='';
            string chargeName='';
            string name='';
            boolean serviceChargeApply=false;
            boolean TaxSErviceCharge=false;
            string scVal='';
            boolean TaxesOnS=false;

            List<TxnChargeToTaxMapping__c> datData=[SELECT Id,Name, If_Taxes_Are_Applicable__c,SubType__c,Type__c,Service_Charge_applicable__c,tax_on_service_charge__c,Taxes_applicable_on_service_charge__c,TaxId__c FROM TxnChargeToTaxMapping__c limit 50000];
            //for(AggregateResult getData:getChargeData){
                //ChargeId=string.valueOf(getData.get('Charge__c'));
                for(TxnChargeToTaxMapping__c SubTypes:datData){
                    string finAccount = '';
                    string defFinAccount = '';
                    boolean typeExistInTxn = false;
                    boolean subtypeExistInTxn = false;
                    
                   // if(ChargeId==string.valueOf(SubTypes.Charge__c)){
                       // if(ChargeId==string.valueOf(SubTypes.Charge__c)&&string.valueOf(SubTypes.Type__c)==string.valueOf(SubTypes.Type__c)){
                           // check for type existence
                            for(string txnType : allTxnTypes){
                              if(txnType==string.valueOf(SubTypes.Type__c))
                                 typeExistInTxn = true; 
                            }
                            //check for subtype existence
                            for(string txnSubType: allTxnSubtypes){
                                if(SubTypes.SubType__c!=null && SubTypes.SubType__c!=''){
                                if(txnSubType==string.valueOf(SubTypes.SubType__c))
                                 subtypeExistInTxn = true;
                                }
                                else
                                 subtypeExistInTxn = true;   
                            }
                            
                            chargeName='';
                           // for(RecordType rt:tranRecTypeLst)if(rt.ID==ChargeId)chargeName=rt.Name;
                            name='';
                            serviceChargeApply=false;
                            TaxSErviceCharge=false;
                            scVal='';
                            List<SelectOption> taxes=new List<SelectOption>();
                            TaxesOnS=false;
                            for(TxnChargeToTaxMapping__c dat : datData)
                            {
                                if(String.valueOf(dat.Type__c) == String.valueOf(SubTypes.Type__c) && String.valueOf(dat.SubType__c) == String.valueOf(SubTypes.SubType__c))
                                {
                                    if(dat.TaxId__c != null)
                                    {
                                        String val=String.valueOf(mapOfTaxesAndItsVal.get(dat.TaxId__c));
                                        taxes.add(new SelectOption('',dat.TaxId__c+'('+val+'%)'));
                                    }

                                    scVal=dat.tax_on_service_charge__c;
                                    name=dat.Name;
                                    serviceChargeApply=dat.Service_Charge_applicable__c;
                                    TaxesOnS=dat.Taxes_applicable_on_service_charge__c;
                                    TaxSErviceCharge=dat.Taxes_applicable_on_service_charge__c;
                                }
                            }

                            if(taxes.size() == 0)
                            {
                                taxes.add(new SelectOption('No taxes','No Taxes'));
                            }
                            integer iii=0;
                            for(aTableRow d:dataRows)
                            {
                                if(string.valueOf(SubTypes.Type__c)==d.Type&&string.valueOf(SubTypes.SubType__c)==d.SubType)
                                {
                                    iii=1;
                                }
                            }
                            if(iii==0){
                                if(typeExistInTxn==true && subtypeExistInTxn==true)
                                dataRows.add(new  aTableRow(name,'','',string.valueOf(SubTypes.Type__c),string.valueOf(SubTypes.SubType__c),taxes,serviceChargeApply,scVal,TaxSErviceCharge,finAccount,defFinAccount));
                            }
                          // }
                   // }
                }
           // }
            return dataRows;
        }
        private set;
    }
    public string getNameOfServiceCharge(string Id,string val){
        string name='';
        double value=0;
        ServiceCharges__c setting=ServiceCharges__c.getInstance();
        if(Id=='Service_Charge_for_food__c'){
            name='Service Charge for food';
            value=setting.Service_Charge_for_food__c;
        }
        else if(Id=='Service_Charge_general__c'){
            name='Service Charge for General';
            value=setting.Service_Charge_general__c;
        }
        if(val!='')return string.valueOf(value);
        return name;
    }
    
    public PageReference redirectUser(){
        PageReference ref=new  PageReference('/apex/TxnChargesToTaxMapping');
        return ref;
    }
//funtion to get tax name or value
    public string getNameOfTax(string Id,string val){
        string name='';
        double value=0;
        Map<string,Schema.SObjectField> fieldsMap=Taxes__c.sObjectType.getDescribe().fields.getMap();
        Set<string> customHierarchyFieldNames=new  Set<string>();
        for(string field:fieldsMap.keySet()){
            Schema.SObjectField F=fieldsMap.get(field);
            Schema.DescribeFieldResult R=F.getDescribe();
            if(R.isCustom()){
                string fName=R.getName();
                string fLabel=R.getLabel();
                if(Id==fName){
                    name=fLabel;
                    Taxes__c allTaxesHSettings=Taxes__c.getInstance();
                    value=double.valueOf(allTaxesHSettings.get(fName));
                }
            }
        }
        if(val!='')return string.valueOf(value);
        return name;
    }
}