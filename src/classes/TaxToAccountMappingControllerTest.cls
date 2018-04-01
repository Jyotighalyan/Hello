@isTest
public class TaxToAccountMappingControllerTest {
    private testMethod static void runAll() {
        test.startTest();
        TaxToAccountMappingController TAM = new TaxToAccountMappingController();
        Taxes__c setting = new Taxes__c();
        /**setting.Catering_Bar_Sales_Tax_Percentage__c = 10;
        setting.Catering_Beverage_Sales_Tax_Percentage__c = 10;
        setting.Catering_Fitness_Sales_Tax_Percentage__c = 10;
        setting.Catering_Other_Sales_Tax_Percentage__c = 10;**/
        setting.Sales_Tax__c =10;
        setting.Transit_Improvement_Sales_Tax__c =10;
        insert setting;
        string settingId=setting.Id;
        /**Taxes__c taxes = [select Catering_Fitness_Sales_Tax_Percentage__c from Taxes__c];
        System.assertEquals(10, taxes.Catering_Fitness_Sales_Tax_Percentage__c);**/
        
        ServiceCharges__c sCharge =new ServiceCharges__c();
        sCharge.Banquet_Bar_Service_Charge__c=10;
        sCharge.Banquet_Beverage_Service_Charge__c=10;
        sCharge.Banquet_Fitness_Service_Charge__c=10;
        sCharge.Banquet_Other_Service_Charge__c=10;
        insert sCharge;
        string sChargeId=sCharge.Id;
        ServiceCharges__c sc = [select Banquet_Bar_Service_Charge__c from ServiceCharges__c];
        System.assertEquals(10, sc.Banquet_Bar_Service_Charge__c);
        
        UseTaxes__c useTx =new UseTaxes__c();
        useTx.Use_Tax__c=10;
        insert useTx;
        string useTxId=useTx.Id;
        UseTaxes__c ut = [select Use_Tax__c from UseTaxes__c];
        System.assertEquals(10, ut.Use_Tax__c);
        
        TAM.save();
        TAM = new TaxToAccountMappingController();
        
        setting = new Taxes__c();
        setting.Id=settingId;
        //setting.Catering_Bar_Sales_Tax_Percentage__c = 11;
        update setting;
        
        sCharge =new ServiceCharges__c();
        sCharge.id=sChargeId;
        sCharge.Banquet_Bar_Service_Charge__c=10;
        update sCharge;
        
        useTx =new UseTaxes__c();
        useTx.Id=useTxId;
        useTx.Use_Tax__c=11;
        update useTx;
        
        TAM.save();
        test.stopTest();
        
    }

}