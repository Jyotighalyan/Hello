@isTest
private class UtilityTest {

    @isTest static void testSearchRecordType() {

        String recordTypeId = Utility.searchRecordType('Credit', 'TXN__c');
        Id recTypeId = Schema.getGlobalDescribe().get('TXN__c').getDescribe().getRecordTypeInfosByName().get('Credit').getRecordTypeId();

        System.assertEquals(recordTypeId, recTypeId);
    }

    @isTest
    static void testRound2()
    {
        Double result = Utility.Round2(Double.valueOf(2.534));
        System.assert(result == 2.53);
    }

    @isTest
    static void testGetNameOfTax()
    {
        Taxes__c settings = Taxes__c.getOrgDefaults();
        /**settings.Adjust_Taxes__c = true;
        settings.Catering_Bar_Sales_Tax_Percentage__c = .1;
        settings.Catering_Beverage_Sales_Tax_Percentage__c = .1;
        settings.Catering_Fitness_Sales_Tax_Percentage__c = .1;
        settings.Catering_Food_Sales_Tax_Percentage__c = .1;
        settings.Catering_Other_Sales_Tax_Percentage__c  = .1; **/
        settings.Liquor_Sales_Tax__c = .1;
        settings.Sales_Tax__c = .1;
        settings.Tax_Exempt__c = .1;
        settings.Tax_ID__c ='1234';
        settings.Transit_Improvement_Sales_Tax__c = .1;
        upsert settings;

        String result = Utility.getNameOfTax('Sales_Tax__c');
        System.assert(result != null);

        Decimal percent = Utility.getPercentageOfTax('Sales_Tax__c');
        System.assert(percent == .1);
    }

    @isTest
    static void testGetNameOfServiceCharge()
    {
        ServiceCharges__c settings = ServiceCharges__c.getOrgDefaults();
        settings.Banquet_Bar_Service_Charge__c = .1;
        settings.Banquet_Beverage_Service_Charge__c = .1;
        settings.Banquet_Fitness_Service_Charge__c = .1;
        settings.Banquet_Food_Service_Charge__c = .1;
        settings.Banquet_Other_Service_Charge__c = .1;
        settings.Service_Charge_for_food__c  = .1;
        settings.Service_Charge_general__c = .1;
        settings.Service_Charge_Guest__c = .1;
        settings.Service_Charge_Member__c = .1;
        upsert settings;

        String result = Utility.getNameOfServiceCharge('Service_Charge_Member__c');
        System.assert(result != null);

        Decimal percent = Utility.getPercentageOfServiceCharge('Service_Charge_Member__c');
        System.assert(percent == .1);
    }

    @isTest
    static void testGetFinancialAccountForTax()
    {
        Financial_Account__c fa = TestHandler.getFinancialAccount(); // method does the insert

        Tax_To_Account_Mapping__c tam = new Tax_To_Account_Mapping__c();
        tam.Financial_Accounts__c = fa.Id;
        tam.Service_Charge__c = 'Service Charge';
        tam.Tax__c = 'Tax';
        tam.Service_Charge_Value__c = 'Value';
        tam.Tax_Value__c = 'Value';
        insert tam;

        String fin = Utility.getFinancialAccountForTax('Service Charge', true);
        System.assert(fin == fa.Id);

        fin = Utility.getFinancialAccountForTax('Tax', false);
        System.assert(fin == fa.Id);
    }

    @isTest
    static void testGetFinancialAccountForTxnRecTypes()
    {
        Financial_Account__c fa = TestHandler.getFinancialAccount(); // method does the insert
        String defRecTypeId = Utility.searchRecordType('Default', 'Default_Account__c');
        Default_Account__c tfm2 = new Default_Account__c();
        tfm2.Financial_Account__c = fa.Id;
        tfm2.Default_Type_Name__c = 'Lunch';
        tfm2.Financial_Account_Name_And_Number__c = 'Test 2';
        tfm2.RecordTypeId = defRecTypeId;
        insert tfm2;

        String fin = Utility.getFinancialAccountForTxnRecTypes('Default', 'Lunch', 'Other');
        System.assert(fin == fa.Id);
    }

    @isTest
    static void testGetCredDebitStatus()
    {
        Financial_Account__c fa = TestHandler.getFinancialAccount(); // method does the insert

        String result = Utility.getCredDebitStatus(fa.id);
        System.assert(result == null);

        fa.Category__c = 'Asset';
        fa.A_P_Trade__c = false;
        update fa;

        result = Utility.getCredDebitStatus(fa.id);
        System.assert(result != null);

    }

    @isTest
    static void testGetFields()
    {
        String result = Utility.getFields('Contact');
        System.assert(result != null);

        result = Utility.getFields('Reservation_Registration__c');
    }
}