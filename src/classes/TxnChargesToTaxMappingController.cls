public with sharing class TxnChargesToTaxMappingController{
    
    public List<SelectOption> AllTaxes{get;set;}
    public List<SelectOption> allServiceCharges{get;set;}
    public List<SelectOption> SelectedTaxes{get;set;}
    public List<SelectOption> CopySelectedTaxes{get;set;}
    public List<SelectOption> selectedTaxesforServiceCharge{get;set;}
    public String chargeType{get;set;}
    public boolean isSubTypeEnabled{get;set;}
    public String chargeSubType{get;set;}
  
    public Boolean serviceTaxesApplicable{get;set;}
    public String tax_on_service_charge{get;set;}
    public String serviceChargeName{get;set;}
    public Boolean service_charge_applicable{get;set;}
    public Boolean serviceChargeTaxesVisible{get;set;}
    public Boolean serviceChargesVisible{get;set;}

    public TxnChargeToTaxMapping__c othCharge{get;set;}
    public String saveAction{get;set{saveAction=value;}}
    //Added for Financial JE
    public boolean POS{get;set;}
    public List<SelectOption>totalCopySelectedTaxes{get;set;}
    public boolean taxSizeNotEqual{get;set;}

    public TxnChargesToTaxMappingController()
    {
        othCharge = new  TxnChargeToTaxMapping__c();
        POS=false;
        serviceTaxesApplicable=false;
        taxSizeNotEqual=true;
        totalCopySelectedTaxes=new List<SelectOption>();
        SelectedTaxes=new  List<SelectOption>();
        CopySelectedTaxes = new List<SelectOption>();
        selectedTaxesforServiceCharge = new List<SelectOption>();
        allTaxes();
        allServiceCharge();
        serviceChargeName = null;
        service_charge_applicable = false;
        serviceChargeTaxesVisible = false;
        serviceChargesVisible = false;
        
        if(Apexpages.currentPage().getParameters().get('type') != '' && Apexpages.currentPage().getParameters().get('type') != null)
        {
            String typeFromUrl=Apexpages.currentPage().getParameters().get('type');
            String SubTypeFromUrl=Apexpages.currentPage().getParameters().get('subtype');
            othCharge.Type__c=TypeFromUrl;
            othCharge.SubType__c=SubTypeFromUrl;
            chargeType=TypeFromUrl;
            chargeSubType=SubTypeFromUrl;

            if(SubTypeFromUrl != '' && SubTypeFromUrl != null)
                Get_other_data_based_on_Subtype();
            else 
                Get_other_data_based_on_type();

            get_ServiceChargeData();

            if(service_charge_applicable)
                serviceChargesVisible = true;

            if(serviceTaxesApplicable)
                serviceChargeTaxesVisible = true;
        }
    }

    public void allTaxes()
    {
        AllTaxes=new  List<SelectOption>();
        Map<String,Schema.SObjectField> fieldsMap=Taxes__c.sObjectType.getDescribe().fields.getMap();
        Set<String> customHierarchyFieldNames=new  Set<String>();
        for(String field:fieldsMap.keySet()){         
            Schema.SObjectField F=fieldsMap.get(field);
            Schema.DescribeFieldResult R=F.getDescribe();
            if(R.isCustom()){
                String fName=R.getName();
                String fLabel=R.getLabel();
                Taxes__c allTaxesHSettings=Taxes__c.getInstance();
                
                try{
                    double d=(double)allTaxesHSettings.get(fName);
                    d=d*1;                
                    AllTaxes.add(new  SelectOption(fName,fLabel+'('+String.valueOf(allTaxesHSettings.get(fName))+')')); 
                }            
                catch(Exception e)
                {
                    
                }
            }
        }
    }

    public void allServiceCharge()
    {
        allServiceCharges=new List<SelectOption>();
        allServiceCharges.add(new SelectOption('','Select Service Charge'));
        Map<String,Schema.SObjectField> fieldsMap1=ServiceCharges__c.sObjectType.getDescribe().fields.getMap();
        for(String field:fieldsMap1.keySet())
        {
            Schema.SObjectField F=fieldsMap1.get(field);
            Schema.DescribeFieldResult R=F.getDescribe();
            if(R.isCustom())
            {
                String fName=R.getName();
                String fLabel=R.getLabel();
                ServiceCharges__c allTaxesHSettings=ServiceCharges__c.getInstance();
                
                try
                {
                    if(allTaxesHSettings.get(fName) != null) // only adds to list if there is a value
                        allServiceCharges.add(new SelectOption(fName,fLabel+'('+String.valueOf(allTaxesHSettings.get(fName))+')'));
                }
                catch(Exception e)
                {
                    
                }
            }
        }
    }

    public void autoRun()
    {
        isSubTypeEnabled=false;
    }

    public void get_ServiceChargeData() 
    {
        System.debug('**** In get_ServiceChargeData: '+chargeSubType);

        CopySelectedTaxes=new List<SelectOption>();
        CopySelectedTaxes.addAll(SelectedTaxes);
        selectedTaxesforServiceCharge = new List<SelectOption>();
        serviceTaxesApplicable=false;
        ServiceCharges__c allCharges=ServiceCharges__c.getInstance();
        Boolean foundTaxId = false;

            List<TxnChargeToTaxMapping__c> mappings = (List<TxnChargeToTaxMapping__c>)Data.read(
                'select TaxId__c,Allow_in_POS__c,If_Taxes_Are_Applicable__c,tax_on_service_charge__c,Service_Charge_Name__c,'+
                'Tax_Name_applicable_on_service_charge__c,Service_Charge_applicable__c,Taxes_applicable_on_service_charge__c FROM TxnChargeToTaxMapping__c WHERE '+
                'Type__c=:chargeType AND SubType__c =: chargeSubType',
                new Map<String, Object> {
                    'chargeType' => chargeType,
                    'chargeSubType' => chargeSubType
                }
            );

            if(mappings.size() >0 )
            {
                foundTaxId = true;
                for(TxnChargeToTaxMapping__c mapping : mappings)
                {
                    if(mapping.Service_Charge_applicable__c) // will make screen components appear
                    {
                        service_charge_applicable = true;
                        clickSrvcCharges();
                    }

                    serviceChargeName  = mapping.Service_Charge_Name__c;
                    try
                    {
                        tax_on_service_charge = String.valueOf(allCharges.get(serviceChargeName));
                    }
                    catch(System.NullPointerException npe)
                    {
                        tax_on_service_charge = '0.0';
                    }
                   
                    if(mapping.TaxId__c!=null && mapping.TaxId__c!='' )
                    {
                        String name = Utility.getNameOfTax(mapping.TaxId__c);
                        Decimal value = Utility.getPercentageOfTax(mapping.TaxId__c);

                        Integer ii=0;
                        for(ii=0; ii < CopySelectedTaxes.size(); ii++)
                        {
                            if(CopySelectedTaxes[ii].getValue()==mapping.Tax_Name_applicable_on_service_charge__c)
                            {
                                CopySelectedTaxes.remove(ii);
                                selectedTaxesforServiceCharge.add(new SelectOption(mapping.TaxId__c,name+'('+value+')'));
                            }
                        }

                        if(mapping.Taxes_applicable_on_service_charge__c) 
                        {  
                            serviceTaxesApplicable = true;
                            serviceChargeTaxesVisible = true;
                        }
                    }
                }
            }
        
        if(!foundTaxId)
        {
            mappings = (List<TxnChargeToTaxMapping__c>)Data.read(
                'select TaxId__c,Allow_in_POS__c,If_Taxes_Are_Applicable__c,tax_on_service_charge__c,Service_Charge_Name__c,'+
                'Tax_Name_applicable_on_service_charge__c,Service_Charge_applicable__c,Taxes_applicable_on_service_charge__c FROM TxnChargeToTaxMapping__c WHERE '+
                'Type__c=:chargeType AND SubType__c=\'\'',
                new Map<String, Object> {
                    'chargeType' => chargeType
                }
            );

            for(TxnChargeToTaxMapping__c mapping : mappings)
            {
                if(mapping.TaxId__c!=null)
                {
                    if(mapping.Service_Charge_applicable__c) // will make screen components appear
                    {
                        service_charge_applicable = true;
                        clickSrvcCharges();
                    }
                    serviceChargeName = mapping.Service_Charge_Name__c;

                    try
                    {
                        tax_on_service_charge = String.valueOf(allCharges.get(serviceChargeName));
                    }
                    catch(System.NullPointerException npe)
                    {
                        tax_on_service_charge = '0.0';
                    }

                    String name = Utility.getNameOfTax(mapping.TaxId__c);
                    Decimal value = Utility.getPercentageOfTax(mapping.TaxId__c);

                    Integer ii=0;
                    for(ii=0; ii < CopySelectedTaxes.size(); ii++)
                    {
                        if(CopySelectedTaxes[ii].getValue()==mapping.Tax_Name_applicable_on_service_charge__c)
                        {
                            CopySelectedTaxes.remove(ii);
                            selectedTaxesforServiceCharge.add(new SelectOption(mapping.TaxId__c,name+'('+value+')')); 
                        }
                    }

                    if(mapping.Taxes_applicable_on_service_charge__c == true) 
                    {  
                        serviceTaxesApplicable = true;
                        serviceChargeTaxesVisible = true;
                    } 
                }
            }
        }
    }

    public PageReference Get_other_data_based_on_Subtype()
    {
        SelectedTaxes=new List<SelectOption>();
        allTaxes();
        service_charge_applicable=false;
        POS=false;
        Boolean foundTaxId = false;

        List<TxnChargeToTaxMapping__c> mappings = (List<TxnChargeToTaxMapping__c>)Data.read(
            'select TaxId__c,Allow_in_POS__c,If_Taxes_Are_Applicable__c,tax_on_service_charge__c,Service_Charge_Name__c,'+
            'Tax_Name_applicable_on_service_charge__c,Service_Charge_applicable__c,Taxes_applicable_on_service_charge__c FROM TxnChargeToTaxMapping__c WHERE '+
            'Type__c=:chargeType AND SubType__c =: chargeSubType',
            new Map<String, Object> {
                'chargeType' => chargeType,
                'chargeSubType' => chargeSubType
            }
        );
       
        for(TxnChargeToTaxMapping__c mapping : mappings)
        {
            if(mapping.TaxId__c != null && mapping.TaxId__c != '' )
            {
                foundTaxId = true;
                integer ii=0;
                for(ii=0; ii < AllTaxes.size(); ii++)
                {
                    if(AllTaxes[ii].getValue()==mapping.TaxId__c)
                    {
                        AllTaxes.remove(ii);
                    }
                }

                String name = Utility.getNameOfTax(mapping.TaxId__c);
                Decimal value = Utility.getPercentageOfTax(mapping.TaxId__c);
                SelectedTaxes.add(new SelectOption(mapping.TaxId__c,name+'('+value+')'));

                if(mapping.Allow_in_POS__c==true)
                {
                    POS=true;
                }
               
                if(mapping.Service_Charge_applicable__c == true)
                {
                    service_charge_applicable=true;
                    clickSrvcCharges();
               }
            }
        }
        
        if(!foundTaxId)
        {
            mappings = (List<TxnChargeToTaxMapping__c>)Data.read(
                'select TaxId__c,Allow_in_POS__c,If_Taxes_Are_Applicable__c,tax_on_service_charge__c,Service_Charge_Name__c,'+
                'Tax_Name_applicable_on_service_charge__c,Service_Charge_applicable__c,Taxes_applicable_on_service_charge__c FROM TxnChargeToTaxMapping__c WHERE '+
                'Type__c=:chargeType AND SubType__c=\'\'',
                new Map<String, Object> {
                    'chargeType' => chargeType
                }
            );
            for(TxnChargeToTaxMapping__c mapping : mappings)
            {
                if(mapping.TaxId__c!=null)
                {
                    integer ii=0;
                    for(ii=0;ii<AllTaxes.size();ii++)
                    {
                        if(AllTaxes[ii].getValue()==mapping.TaxId__c)
                        {
                            AllTaxes.remove(ii);
                        }
                    }

                    String name = Utility.getNameOfTax(mapping.TaxId__c);
                    Decimal value = Utility.getPercentageOfTax(mapping.TaxId__c);
                    SelectedTaxes.add(new  SelectOption(mapping.TaxId__c,name+'('+value+')'));

                    if(mapping.Service_Charge_applicable__c == true)
                    {
                        service_charge_applicable=true;
                        clickSrvcCharges();
                    }
                    
                    if(mapping.Allow_in_POS__c==true)
                    {
                        POS=true;
                    }
                }
            }
        }
        get_ServiceChargeData(); // need to populate the service charge fields based on the type
        return null;
    }

    public PageReference Get_other_data_based_on_type()
    {
        allTaxes();
        SelectedTaxes=new  List<SelectOption>();
        service_charge_applicable=false;
        POS=false;

        List<TxnChargeToTaxMapping__c> mappings = (List<TxnChargeToTaxMapping__c>)Data.read(
            'select TaxId__c,Allow_in_POS__c,If_Taxes_Are_Applicable__c,tax_on_service_charge__c,Service_Charge_Name__c,'+
            'Tax_Name_applicable_on_service_charge__c,Service_Charge_applicable__c,Taxes_applicable_on_service_charge__c FROM TxnChargeToTaxMapping__c WHERE '+
            'Type__c=:chargeType AND SubType__c=\'\'',
            new Map<String, Object> {
                'chargeType' => chargeType
            }
        );
        
        for(TxnChargeToTaxMapping__c mapping : mappings)
        {
            if(mapping.TaxId__c!=null)
            {
                integer ii=0;
                for(ii=0;ii<AllTaxes.size();ii++)
                {
                    if(AllTaxes[ii].getValue()==mapping.TaxId__c)
                    {
                        AllTaxes.remove(ii);
                    }
                }
                String name=Utility.getNameOfTax(mapping.TaxId__c);
                Decimal value=Utility.getPercentageOfTax(mapping.TaxId__c);
                SelectedTaxes.add(new  SelectOption(mapping.TaxId__c,name+'('+value+')'));

                if(mapping.Allow_in_POS__c==true)
                {
                    POS=true;
                }
            }
        }
        get_ServiceChargeData(); // need to populate the service charge fields based on the type

        return null;
    }

    public List<SelectOption> getRecordTypeOptions()
    {
        Map<String,Schema.RecordTypeInfo>transactionRecordTypeInfo=TXN__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        List<SelectOption> recordTypesOptions=new  List<SelectOption>();
        recordTypesOptions.add(new  SelectOption('','--None--'));

        for(String s:transactionRecordTypeInfo.keySet())
        {
            if(s=='Charge'||s=='Dues' ||s=='Promotion Discount')
            {
                recordTypesOptions.add(new  SelectOption(transactionRecordTypeInfo.get(s).getRecordTypeId(),s));
            }
        }
        return recordTypesOptions;
    }

    public PageReference save()
    {
        if(chargeType == '' || chargeType==null)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Error No : TxnError00002, Message: Type is Missing.'));
            return null;
        }
        else if(service_charge_applicable == true)
        {
            if(serviceTaxesApplicable && (selectedTaxesforServiceCharge == null || selectedTaxesforServiceCharge.size() == 0))
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Error No : TxnError00003, Message: Service Charge Tax is Missing.'));
                return null;
            }

            if(String.isEmpty(serviceChargeName))
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Error No : TxnError00003, Message: Service Charge is Missing.'));
                return null;
            }
        }
       
        if(chargeSubType!='')
        {
            List<TxnChargeToTaxMapping__c> itemsToDelete = (List<TxnChargeToTaxMapping__c>)Data.read(
                'SELECT Id FROM TxnChargeToTaxMapping__c WHERE Type__c=:chargeType AND SubType__c=:chargeSubType',
                new Map<String, Object> {
                    'chargeType' => chargeType,
                    'chargeSubType' => chargeSubType
                }
            );
            Data.remove(itemsToDelete);
        }
        else 
        {
            List<TxnChargeToTaxMapping__c> itemsToDelete = (List<TxnChargeToTaxMapping__c>)Data.read(
                'SELECT Id FROM TxnChargeToTaxMapping__c WHERE Type__c=:chargeType AND SubType__c=\'\'',
                new Map<String, Object> {
                    'chargeType' => chargeType
                }
            );
            Data.remove(itemsToDelete);
        }

        if(selectedTaxesforServiceCharge.size()==0 && serviceTaxesApplicable==true)
        {
            ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR,'Error No : TxnError00005, Message:They have the "Check if Taxes are applicable" Checked, but there is no tax selected in the pickList.'));
            return null;
        }

        if(!areSelectionsMapped())
        {
            ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR,'Error No : TxnError00006, Message:The Taxes and/or the Service Charge aren\'t mapped'));
            return null;
        }

        // added to save financial account
        SavePoint sp = Database.setSavepoint();
        
        try
        {
            List<TxnChargeToTaxMapping__c> mappings = new List<TxnChargeToTaxMapping__c>();
            if(SelectedTaxes.size() > 0)
            {
                for(SelectOption tax : SelectedTaxes)
                {
                    if(tax.getValue()=='unknown' || tax.getValue()=='Other')
                        continue;

                    TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
                    taxObj.TaxId__c=tax.getValue();
                    taxObj.Type__c=chargeType;
                    taxObj.Allow_in_POS__c=POS;
                    taxObj.Taxes_applicable_on_service_charge__c=serviceTaxesApplicable;
                    taxObj.Service_Charge_applicable__c=service_charge_applicable;
                    if(serviceChargeName != null && serviceChargeName != 'Select Service Charge')
                    {
                        taxObj.Service_Charge_Name__c = serviceChargeName;
                        ServiceCharges__c allTaxesHSettings=ServiceCharges__c.getInstance();
                        taxObj.tax_on_service_charge__c=String.valueOf(allTaxesHSettings.get(serviceChargeName));
                    }
                    else
                    {
                        taxObj.Service_Charge_Name__c = null;
                        taxObj.tax_on_service_charge__c = '0.0';
                    }

                    for(SelectOption srvcTax : selectedTaxesforServiceCharge)
                    {
                        if(tax.getLabel() == srvcTax.getLabel())
                        {
                            taxObj.Tax_Name_applicable_on_service_charge__c = String.valueOf(srvcTax.getValue());
                         }
                     }
                   
                    taxObj.SubType__c=chargeSubType;
                    mappings.add(taxObj);
                }
            }
            else
            {
                TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
                taxObj.Type__c=chargeType;
                taxObj.Allow_in_POS__c=POS;
                taxObj.Taxes_applicable_on_service_charge__c=serviceTaxesApplicable;
                taxObj.Service_Charge_applicable__c=service_charge_applicable;
                if(serviceChargeName != null && serviceChargeName != 'Select Service Charge')
                {
                    taxObj.Service_Charge_Name__c = serviceChargeName;
                    ServiceCharges__c allTaxesHSettings=ServiceCharges__c.getInstance();
                    taxObj.tax_on_service_charge__c=String.valueOf(allTaxesHSettings.get(serviceChargeName));
                }
                else
                {
                    taxObj.Service_Charge_Name__c = null;
                    taxObj.tax_on_service_charge__c = '0.0';
                }

                for(SelectOption srvcTax : selectedTaxesforServiceCharge)
                {
                    taxObj.Taxes_applicable_on_service_charge__c=true; 
                    taxObj.Tax_Name_applicable_on_service_charge__c = String.valueOf(srvcTax.getValue());
                }
               
                taxObj.SubType__c=chargeSubType;
                mappings.add(taxObj);
            }

            Data.create(mappings);

            autoRun();
            service_charge_applicable=false;
            POS=false;
            serviceTaxesApplicable=false;
            othCharge.Type__c='';
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR,'Error No : TxnError00006'+ex.getMessage()));
            Database.rollback(sp);    
            return null;    
        }

        PageReference reRend;
        if(saveAction=='saveAdd')
        {
            reRend=new  PageReference('/apex/TxnChargesToTaxMapping?mp=fb');
            reRend.setRedirect(true);
        }
        else if(saveAction=='save')
        {
            reRend=new  PageReference('/apex/TxnAllTaxes');
            reRend.setRedirect(true);
        }
        return reRend;
    }    

    public PageReference clickSrvcTaxes()
    {   
        if(serviceTaxesApplicable)
        {
            get_ServiceChargeData();
            serviceChargeTaxesVisible = true;
        }
        else
        {
            serviceChargeTaxesVisible = false;
        }
        return null;
    }

    public PageReference clickSrvcCharges()
    {   
        if(service_charge_applicable)
        {
            serviceChargesVisible = true;
        }
        else
        {
            serviceChargesVisible = false;
        }
        return null;
    }

    private Boolean areSelectionsMapped()
    {
        Boolean foundMapping = false;

        //It's ok if the user has not selected any taxes and not selected a Service Charge. All this to pass.
        if((SelectedTaxes == null || SelectedTaxes.size() <=0) &&  serviceChargeName == null)
            return true;
        
        List<Tax_To_Account_Mapping__c> mappings = (List<Tax_To_Account_Mapping__c>)Data.read(
            'select Id, Name, Tax__c, Service_Charge__c, Financial_Accounts__c from Tax_To_Account_Mapping__c',
            new Map<String, Object> {}
        );

        if(mappings.size() > 0) 
        {
            for(Tax_To_Account_Mapping__c tam : mappings)
            {
                for(SelectOption tax : SelectedTaxes)
                {
                    String taxName = Schema.getGlobalDescribe().get('Taxes__c').getDescribe().fields.getMap().get(tax.getValue()).getDescribe().getLabel();
                    
                    if(taxName == tam.Tax__c && tam.Financial_Accounts__c != null)
                    {
                        foundMapping = true;
                    }
                }
            }
        }

        if(!foundMapping && serviceChargeName != null) // tax/SC wasn't found. Just look for service charge mapping
        {
            String scName = Schema.getGlobalDescribe().get('ServiceCharges__c').getDescribe().fields.getMap().get(serviceChargeName).getDescribe().getLabel();
            for(Tax_To_Account_Mapping__c tam : mappings)
            {
                if(scName != null && tam.Service_Charge__c == scName && tam.Financial_Accounts__c != null)
                {
                    foundMapping = true;
                    break;
                }
            }
        }

        return foundMapping;
    }
}