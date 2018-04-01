@isTest
public class TxnChargesToTaxMappingControllerTest 
{
    @testSetup static void setup(){
        Financial_Account__c financialAccount = new Financial_Account__c(Name = 'TEST_FIN_ACCOUNT', Account_Number__c = '123456789', Category__c = 'Expense');
        insert financialAccount;

        Taxes__c taxesCustomSettings = new Taxes__c();
        taxesCustomSettings.Sales_Tax__c = 10.00;
        taxesCustomSettings.Transit_Improvement_Sales_Tax__c = 1.00;
        insert taxesCustomSettings;

        ServiceCharges__c servicesCustomSettings = new ServiceCharges__c();
        servicesCustomSettings.Service_Charge_Member__c = 5.00;
        insert servicesCustomSettings;
        List<Tax_To_Account_Mapping__c> taxToAccounts = new List<Tax_To_Account_Mapping__c>();

        Tax_To_Account_Mapping__c taxToAccount1 = new Tax_To_Account_Mapping__c(Account_Name__c = 'TEST_TAX_TO_ACCOUNT1', Financial_Accounts__c = financialAccount.Id, Tax__c = Utility.getNameOfTax('Sales_Tax__c'));
        Tax_To_Account_Mapping__c taxToAccount2 = new Tax_To_Account_Mapping__c(Account_Name__c = 'TEST_TAX_TO_ACCOUNT2', Financial_Accounts__c = financialAccount.Id, Service_Charge__c = Utility.getNameOfServiceCharge('Service_Charge_Member__c'));
        taxToAccounts.add(taxToAccount1);
        taxToAccounts.add(taxToAccount2);
        insert taxToAccounts;

        List<TxnChargeToTaxMapping__c> mappings = new List<TxnChargeToTaxMapping__c>();
        TxnChargeToTaxMapping__c taxObj1= new TxnChargeToTaxMapping__c();
        taxObj1.Type__c='Dinner';
        taxObj1.Subtype__c = null;
        taxObj1.Allow_in_POS__c=true;
        taxObj1.Taxes_applicable_on_service_charge__c=false;
        taxObj1.Service_Charge_applicable__c=true;
        taxObj1.Service_Charge_Name__c = 'Service_Charge_Member__c';
        taxObj1.TaxId__c = 'Sales_Tax__c';
        mappings.add(taxObj1);
        insert mappings;
    }
    static testMethod void testMethod1() 
    { 
        PageReference pageRef = Page.TxnChargesToTaxMapping;
        Test.setCurrentPage(pageRef);
        
        

        String type = 'Dinner';
        String subtype = null;
        Schema.DescribeFieldResult fieldResult = TXN__c.GlobalType__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        // for( Schema.PicklistEntry pick : picklistValues)
        // {
        //     type = pick.getValue();
        //     break;
        // }
        
        // Schema.DescribeFieldResult fieldResult1 = TXN__c.GlobalSubType__c.getDescribe();
        // List<Schema.PicklistEntry> picklistValues1 = fieldResult1.getPicklistValues();
        // for( Schema.PicklistEntry pick : picklistValues1)
        // {
        //     subtype = pick.getValue();
        //     break;
        // }
        TxnChargeToTaxMapping__c taxMappingOnThisType = MappingAndTaxUtilityTest.createTaxMapping(type, subtype);
        // Integer accNumber = ++MappingAndTaxUtilityTest.financialAccountNumber;
        //Financial_Account__c financialAccount = MappingAndTaxUtilityTest.createFinancialAccount(accNumber);

        //Tax_To_Account_Mapping__c tam = new Tax_To_Account_Mapping__c();
        // tam.Tax__c = Schema.getGlobalDescribe().get('Taxes__c').getDescribe().fields.getMap().get(taxMappingOnThisType.TaxId__c).getDescribe().getLabel();
        // if(taxMappingOnThisType.Service_Charge_Name__c != null)
        // {
        //     tam.Service_Charge__c = Schema.getGlobalDescribe().get('ServiceCharges__c').getDescribe().fields.getMap().get(taxMappingOnThisType.Service_Charge_Name__c).getDescribe().getLabel();
        // }
        // tam.Financial_Accounts__c = financialAccount.Id;
        // insert tam;
        
        TxnChargesToTaxMappingController testController = new TxnChargesToTaxMappingController();              
        testController.autoRun();
        testController.getRecordTypeOptions();
        testController.othCharge.Type__c = type;
        testController.Get_other_data_based_on_type();
        testController.othCharge.SubType__c = subtype;
        testController.Get_other_data_based_on_Subtype();
        
        testController.save();
        testController.ChargeType = type;
        testController.ChargeSubType = subtype;
        testController.save();
        System.debug('++ TaxMappingOnThisType.TaxId__c ' + TaxMappingOnThisType.TaxId__c);

        string name = Utility.getNameOfTax(TaxMappingOnThisType.TaxId__c);
        Decimal value = Utility.getPercentageOfTax(TaxMappingOnThisType.TaxId__c);
        
        testController.SelectedTaxes.add(new SelectOption(TaxMappingOnThisType.TaxId__c, name+'('+value+')'));
        testController.saveAction = 'saveAdd';
        testController.save();
        testController.saveAction = 'save';
        testController.save();
    }
    
    static testMethod void editPage()
    {
        
        PageReference pageRef = Page.TxnChargesToTaxMapping;
        Test.setCurrentPage(pageRef);
        
        String type;
        String subtype;
        Schema.DescribeFieldResult fieldResult = TXN__c.GlobalType__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pick : picklistValues)
        {
            type = pick.getValue();
            break;
        }
        Schema.DescribeFieldResult fieldResult1 = TXN__c.GlobalSubType__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues1 = fieldResult1.getPicklistValues();
        for(Schema.PicklistEntry pick : picklistValues1)
        {
            subtype = pick.getValue();
            break;
        }
        TxnChargeToTaxMapping__c taxMapping = MappingAndTaxUtilityTest.createTaxMapping(type, subtype);
        
        Financial_Account__c financialAccountForTest=new Financial_Account__c();
        financialAccountForTest.Name='Test finance1';
        financialAccountForTest.Account_Number__c='1234567';
        financialAccountForTest.Category__c='Asset';
        insert financialAccountForTest;
        Default_Account__c financialMapping =new Default_Account__c();
        financialMapping.RecordtypeId=Utility.searchRecordType('Default','Default_Account__c');
        insert financialMapping;
        
        TxnChargeToTaxMapping__c chargeToTaxMapping = new TxnChargeToTaxMapping__c();
        chargeToTaxMapping.Type__c = type;
        chargeToTaxMapping.SubType__c = '';
        chargeToTaxMapping.TaxId__c = taxMapping.id;
        insert chargeToTaxMapping;
        
        System.currentPageReference().getParameters().put('charge', [select id from recordType where name=:'Charge' and SobjectType=:'TXN__c'].id);
        System.currentPageReference().getParameters().put('type', type);
        System.currentPageReference().getParameters().put('subtype', subtype);
        
        string servCharge;
        Map<String,Schema.SObjectField> fieldsMap1=ServiceCharges__c.sObjectType.getDescribe().fields.getMap();
        for(String field:fieldsMap1.keySet())
        {
            Schema.SObjectField F=fieldsMap1.get(field);
            Schema.DescribeFieldResult R=F.getDescribe();
            servCharge = R.getLabel();
        }
        
        TxnChargesToTaxMappingController testController = new TxnChargesToTaxMappingController(); 
        testController.Get_other_data_based_on_type();
        testController.Get_other_data_based_on_Subtype();
        testController.get_ServiceChargeData();
    }

    static testMethod void editPageNoSubType()
    {
        PageReference pageRef = Page.TxnChargesToTaxMapping;
        Test.setCurrentPage(pageRef);
        
        String type = null;
        String subtype = null;
        Schema.DescribeFieldResult fieldResult = TXN__c.GlobalType__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry pick : picklistValues)
        {
            type = pick.getValue();
            break;
        }

        TxnChargeToTaxMapping__c taxMapping = MappingAndTaxUtilityTest.createTaxMapping(type, subtype);
        
        Financial_Account__c financialAccountForTest=new Financial_Account__c();
        financialAccountForTest.Name='Test finance1';
        financialAccountForTest.Account_Number__c='1234567';
        financialAccountForTest.Category__c='Asset';
        insert financialAccountForTest;

        Default_Account__c financialMapping =new Default_Account__c();
        financialMapping.RecordtypeId=Utility.searchRecordType('Default','Default_Account__c');
        insert financialMapping;
        
        TxnChargeToTaxMapping__c chargeToTaxMapping = new TxnChargeToTaxMapping__c();
        chargeToTaxMapping.Type__c = type;
        chargeToTaxMapping.SubType__c = '';
        chargeToTaxMapping.TaxId__c = taxMapping.id;
        insert chargeToTaxMapping;
        
        System.currentPageReference().getParameters().put('charge', [select id from recordType where name=:'Charge' and SobjectType=:'TXN__c'].id);
        System.currentPageReference().getParameters().put('type', type);
        System.currentPageReference().getParameters().put('subtype', subtype);
        
        string servCharge;
        Map<String,Schema.SObjectField> fieldsMap1=ServiceCharges__c.sObjectType.getDescribe().fields.getMap();
        for(String field:fieldsMap1.keySet())
        {
            Schema.SObjectField F=fieldsMap1.get(field);
            Schema.DescribeFieldResult R=F.getDescribe();
            servCharge = R.getLabel();
        }
        
        TxnChargesToTaxMappingController testController = new TxnChargesToTaxMappingController(); 
        testController.Get_other_data_based_on_type();
        testController.Get_other_data_based_on_Subtype();
        testController.get_ServiceChargeData();
    }

    static testMethod void saveEdit()
    {
        PageReference pageRef = Page.TxnChargesToTaxMapping;
        Test.setCurrentPage(pageRef);
        
        String type;
        String subtype;
        Schema.DescribeFieldResult fieldResult = TXN__c.GlobalType__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pick : picklistValues)
        {
            type = pick.getValue();
            break;
        }
        Schema.DescribeFieldResult fieldResult1 = TXN__c.GlobalSubType__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues1 = fieldResult1.getPicklistValues();
        for(Schema.PicklistEntry pick : picklistValues1)
        {
            subtype = pick.getValue();
            break;
        }
        TxnChargeToTaxMapping__c taxMapping = MappingAndTaxUtilityTest.createTaxMapping(type, subtype);
        Financial_Account__c financialAccountForTest=new Financial_Account__c();
        financialAccountForTest.Name='Test finance1';
        financialAccountForTest.Account_Number__c='1234567';
        financialAccountForTest.Category__c='Asset';
        insert financialAccountForTest;
        Default_Account__c financialMapping =new Default_Account__c();
        financialMapping.RecordtypeId=Utility.searchRecordType('Default','Default_Account__c');
        insert financialMapping;
        
        TxnChargeToTaxMapping__c chargeToTaxMapping = new TxnChargeToTaxMapping__c();
        chargeToTaxMapping.Type__c = type;
        chargeToTaxMapping.SubType__c = subtype;
        chargeToTaxMapping.TaxId__c = taxMapping.id;
        chargeToTaxMapping.tax_on_service_charge__c = '0.00';
        insert chargeToTaxMapping;
        
        System.currentPageReference().getParameters().put('charge', [select id from recordType where name=:'Charge' and SobjectType=:'TXN__c'].id);
        System.currentPageReference().getParameters().put('type', type);
        System.currentPageReference().getParameters().put('subtype', subtype);
        
        string servCharge;
        Map<String,Schema.SObjectField> fieldsMap1=ServiceCharges__c.sObjectType.getDescribe().fields.getMap();
        for(String field:fieldsMap1.keySet())
        {
            Schema.SObjectField F=fieldsMap1.get(field);
            Schema.DescribeFieldResult R=F.getDescribe();
            servCharge = R.getLabel();
        }
        
        TxnChargesToTaxMappingController testController = new TxnChargesToTaxMappingController(); 
        testController.serviceTaxesApplicable=true;
        testController.service_charge_applicable=true;
        testController.clickSrvcCharges();
        testController.clickSrvcTaxes();
        testController.save();
    }
}