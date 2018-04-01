/*
@Name               : TaxToAccountMappingController
@Author             : kiran patel
@Date               : june, 2017
@Description        : Mapping of Taxes and Service Charges
to respective Financial Accounts.
*/
public with sharing class TaxToAccountMappingContService {
    public TaxToAccountMappingContService(){
        
    }
    /* Getting all the Taxes */  
    public Map<String,String> allTaxes(){
        Map<String,String> AllTax = new Map<String,String>();
        Map<string,Schema.SObjectField> fieldsMap=Taxes__c.sObjectType.getDescribe().fields.getMap();
        Set<string> customHierarchyFieldNames=new  Set<string>();
        for(string field:fieldsMap.keySet()){
            
            Schema.SObjectField F=fieldsMap.get(field);
            Schema.DescribeFieldResult R=F.getDescribe();
            if(R.isCustom()){
                string fName=R.getName();
                string fLabel=R.getLabel();
                Taxes__c allTaxesHSettings=Taxes__c.getInstance();
                try{
                    if(string.valueOf(allTaxesHSettings.get(fName))!=null && string.valueOf(allTaxesHSettings.get(fName))!='true' && string.valueOf(allTaxesHSettings.get(fName))!='false'
                       && integer.valueOf(allTaxesHSettings.get(fName)) > 0){
                           AllTax.put(fLabel,string.valueOf(allTaxesHSettings.get(fName)));
                       }
                }catch(Exception e){
                    system.debug('this value is in string, so ingnore this value');
                }
                
            }
        }
        
        return AllTax;
    }
    /*Getting all the Service Charges*/
    public Map<String,String> allServiceCharges(){
        
        Map<String,String> AllServiceCharge = new Map<String,String>();
        Map<string,Schema.SObjectField> fieldsMap=ServiceCharges__c.sObjectType.getDescribe().fields.getMap();
        Set<string> customHierarchyFieldNames=new  Set<string>();
        for(string field:fieldsMap.keySet()){
            Schema.SObjectField F=fieldsMap.get(field);
            Schema.DescribeFieldResult R=F.getDescribe();
            if(R.isCustom()){
                string fName=R.getName();
                string fLabel=R.getLabel();
                ServiceCharges__c allTaxesHSettings=ServiceCharges__c.getInstance();
                try{
                    if(string.valueOf(allTaxesHSettings.get(fName))!=null && string.valueOf(allTaxesHSettings.get(fName))!='true' && string.valueOf(allTaxesHSettings.get(fName))!='false'
                       && integer.valueOf(allTaxesHSettings.get(fName)) > 0){
                           AllServiceCharge.put(fLabel,string.valueOf(allTaxesHSettings.get(fName)));
                       }
                }catch(Exception e){
                    system.debug('this value is in string, so ingnore this value');
                }
            }
        } 
        return AllServiceCharge;
    }
    /*Getting all the Use Taxes*/
    public Map<String,String> allUseTaxes(){
        
        Map<String,String> AllServiceCharge = new Map<String,String>();
        Map<string,Schema.SObjectField> fieldsMap=UseTaxes__c.sObjectType.getDescribe().fields.getMap();
        Set<string> customHierarchyFieldNames=new  Set<string>();
        for(string field:fieldsMap.keySet()){
            Schema.SObjectField F=fieldsMap.get(field);
            Schema.DescribeFieldResult R=F.getDescribe();
            if(R.isCustom()){
                string fName=R.getName();
                string fLabel=R.getLabel();
                UseTaxes__c  allTaxesHSettings=UseTaxes__c.getInstance();
                try{
                    if(string.valueOf(allTaxesHSettings.get(fName))!=null && string.valueOf(allTaxesHSettings.get(fName))!='true' && string.valueOf(allTaxesHSettings.get(fName))!='false'
                       && integer.valueOf(allTaxesHSettings.get(fName)) > 0){
                           AllServiceCharge.put(fLabel,string.valueOf(allTaxesHSettings.get(fName)));
                       }
                }catch(Exception e){
                    system.debug('this value is in string, so ingnore this value');
                }
            }
        } 
        return AllServiceCharge;
    }
    public void deleteRecord(List<Tax_To_Account_Mapping__c> accts, map<string,string> AllTax,List<Tax_To_Account_Mapping__c> servChar, map<string,string> AllServiceCharge,List<Tax_To_Account_Mapping__c> UseTaxes, map<string,string> AllUseTaxes){
        set<string> deleteSCMapping = new set<string>();
        set<string> deleteTAXMapping = new set<string>();
        set<string> deleteUTMapping = new set<string>();

        for(Tax_To_Account_Mapping__c d : accts)
        {
            if(!AllTax.containsKey(String.valueOf(d.Tax__c))) {
                deleteTAXMapping.add(String.valueOf(d.Tax__c));
            }
        }
        for(Tax_To_Account_Mapping__c d : servChar)
        {
            if(!AllServiceCharge.containsKey(String.valueOf(d.Service_Charge__c))) {
                deleteSCMapping.add(String.valueOf(d.Service_Charge__c));
            }
        }
        for(Tax_To_Account_Mapping__c d : UseTaxes)
        {
            if(!AllUseTaxes.containsKey(String.valueOf(d.UseTax_Name__c))) {
                deleteUTMapping.add(String.valueOf(d.UseTax_Name__c));
            }
        }
        List<Tax_To_Account_Mapping__c> acMapp= (List<Tax_To_Account_Mapping__c>)Data.read('Select Id From Tax_To_Account_Mapping__c Where UseTax_Name__c in :UTIds OR Service_Charge__c in :ScIds Or Tax__c in :TaxIds',
                                                                                                  new Map<String,Object> {
                                                                                                      'TaxIds'=> deleteTAXMapping,
                                                                                                       'ScIds'=>deleteSCMapping,
                                                                                                      'UTIds'=>deleteUTMapping
                                                                                                          }
                                                                                                 );
         data.remove(acMapp);
    }
    public List<Tax_To_Account_Mapping__c> getTaxesFromObj(){
        List<Tax_To_Account_Mapping__c> accts = (List<Tax_To_Account_Mapping__c>)Data.read(
            'select id,Name,Financial_Accounts__c,Tax__c,Tax_Value__c from Tax_To_Account_Mapping__c '+
            'where Tax__c NOT IN( null,\'\')',
            new Map<String,Object> {
            }
        );
        return accts;
    }
    public List<Tax_To_Account_Mapping__c> getServiceChargesFromObj(){
        List<Tax_To_Account_Mapping__c> servChar = (List<Tax_To_Account_Mapping__c>)Data.read(
            'select id,Name,Financial_Accounts__c,Service_Charge__c,Service_Charge_Value__c from Tax_To_Account_Mapping__c '+
            'where Service_Charge__c Not IN( null,\'\')',
            new Map<String,Object> {
            }
        );
        return servChar;
    }
    public List<Tax_To_Account_Mapping__c> getUseTaxesFromObj(){
        List<Tax_To_Account_Mapping__c> UseTaxes = (List<Tax_To_Account_Mapping__c>)Data.read(
            'select id,Name,Financial_Accounts__c,UseTax_Name__c,UseTax_Value__c  from Tax_To_Account_Mapping__c '+
            'where UseTax_Name__c Not IN( null,\'\')',
            new Map<String,Object> {
            }
        );
        return UseTaxes;
    }
    public List<Tax_To_Account_Mapping__c> checkDeletedTaxes(List<Tax_To_Account_Mapping__c> objData, map<string,string> customSettingData){
        List<Tax_To_Account_Mapping__c> latestData= new List<Tax_To_Account_Mapping__c>();
        for(String csData :customSettingData.keySet()){
            integer check=0;
            for(Tax_To_Account_Mapping__c objD:objData){
                if(objD.Tax__c == csData){
                    check=1;
                    latestData.add(objD);
                }
            } 
            if(check==0){
                Tax_To_Account_Mapping__c newTax=new Tax_To_Account_Mapping__c();
                newTax.Tax__c = csData;
                newTax.Tax_Value__c=customSettingData.get(csData);
                latestData.add(newTax);
            }
        }
        return latestData;
    }
    public List<Tax_To_Account_Mapping__c> checkDeletedServiceCharges(List<Tax_To_Account_Mapping__c> objData, map<string,string> customSettingData){
        List<Tax_To_Account_Mapping__c> latestData= new List<Tax_To_Account_Mapping__c>();
        for(String csData :customSettingData.keySet()){
            integer check=0;
            for(Tax_To_Account_Mapping__c objD:objData){
                if(objD.Service_Charge__c == csData){
                    check=1;
                    latestData.add(objD);
                }
            } 
            if(check==0){
                Tax_To_Account_Mapping__c newTax=new Tax_To_Account_Mapping__c();
                newTax.Service_Charge__c = csData;
                newTax.Service_Charge_Value__c=customSettingData.get(csData);
                latestData.add(newTax);
            }
        }
        return latestData;
    }
    public List<Tax_To_Account_Mapping__c> checkDeletedUseTaxes(List<Tax_To_Account_Mapping__c> objData, map<string,string> customSettingData){
        List<Tax_To_Account_Mapping__c> latestData= new List<Tax_To_Account_Mapping__c>();
        for(String csData :customSettingData.keySet()){
            integer check=0;
            for(Tax_To_Account_Mapping__c objD:objData){
                if(objD.UseTax_Name__c == csData){
                    check=1;
                    latestData.add(objD);
                }
            } 
            if(check==0){
                Tax_To_Account_Mapping__c newTax=new Tax_To_Account_Mapping__c();
                newTax.UseTax_Name__c = csData;
                newTax.UseTax_Value__c=customSettingData.get(csData);
                latestData.add(newTax);
            }
        }
        return latestData;
    }
    public pagereference save(List<Tax_To_Account_Mapping__c> accts, map<string,string> AllTax,List<Tax_To_Account_Mapping__c> servChar, map<string,string> AllServiceCharge,List<Tax_To_Account_Mapping__c> UseTaxes, map<string,string> AllUseTaxes){
        set<string> allServiceChargesMappings = new set<string>();
        set<string> allTaxesMappings = new set<string>();
        set<string> allUseTaxesMappings = new set<string>();
        List<Tax_To_Account_Mapping__c> allMappings = (List<Tax_To_Account_Mapping__c>)Data.read(
            'select id,Service_Charge__c,Tax__c,UseTax_Name__c '+
            'from Tax_To_Account_Mapping__c ',
            new Map<String,Object> {
            }
        ); 
        for(Tax_To_Account_Mapping__c mappings : allMappings){
            allServiceChargesMappings.add(mappings.Service_Charge__c);
            allTaxesMappings.add(mappings.Tax__c);
            allUseTaxesMappings.add(mappings.UseTax_Name__c);
        }
        
        
        for(String Key :AllTax.keySet())
        {
            Tax_To_Account_Mapping__c t = new Tax_To_Account_Mapping__c();
            if(!accts.isEmpty()){
                if(allTaxesMappings.contains(Key))
                {
                    string TaxValue = AllTax.get(Key);
                    for(Tax_To_Account_Mapping__c d:accts)
                    {
                        if(d.Tax__c == Key)
                        {
                            d.Tax_Value__c =TaxValue;
                            data.modify(d);
                        }
                    }
                }
            } 
        }
        Data.upsurt(accts, Tax_To_Account_Mapping__c.Id.getDescribe().getSObjectField(), new Set<String>());
        //Service Charges
        for(String Key :AllServiceCharge.keySet())
        {
            Tax_To_Account_Mapping__c t = new Tax_To_Account_Mapping__c();
            if(!AllServiceCharge.isEmpty()){
                if(allServiceChargesMappings.contains(Key))
                {
                    string TaxValue = AllServiceCharge.get(Key);
                    for(Tax_To_Account_Mapping__c d:servChar)
                    {
                        if(d.Service_Charge__c == Key)
                        {
                            d.Service_Charge_Value__c = TaxValue;
                            data.modify(d);
                        }
                    }
                }
            } 
        }
        Data.upsurt(servChar, Tax_To_Account_Mapping__c.Id.getDescribe().getSObjectField(), new Set<String>());
        //Use Taxes
        for(String Key :AllUseTaxes.keySet())
        {
            Tax_To_Account_Mapping__c t = new Tax_To_Account_Mapping__c();
            if(!AllUseTaxes.isEmpty()){
                if(allUseTaxesMappings.contains(Key)) 
                {
                    string TaxValue = AllUseTaxes.get(Key);
                    for(Tax_To_Account_Mapping__c d:UseTaxes)
                    {
                        if(d.UseTax_Name__c == Key)
                        {
                            d.UseTax_Value__c = TaxValue;
                            data.modify(d);
                        }
                    }
                }
            }
        }
        system.debug('check this data here ' + UseTaxes);
        Data.upsurt(UseTaxes, Tax_To_Account_Mapping__c.Id.getDescribe().getSObjectField(), new Set<String>());
        
        //page reference
        PageReference pg;
        pg=page.TaxToAccountMapping;
        pg.getParameters().put('message','Saved Successfully');
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Saved Successfully'));
        pg.setRedirect(true);
        return pg;
    }
}