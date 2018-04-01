public class MappingAndTaxUtilityTest {
  public static Integer financialAccountNumber = 1;
  
  //Create Financial Account
  public static Financial_Account__c createFinancialAccount(Integer financialAccountNumberL) {
    Financial_Account__c financialAccountForTest = new Financial_Account__c();
    financialAccountForTest.Name = 'Test finance' + financialAccountNumberL;
    financialAccountForTest.Account_Number__c = string.valueOf(financialAccountNumberL);
    financialAccountForTest.Category__c = 'Assets';
    insert financialAccountForTest;
    return financialAccountForTest;
  }

  //Create tax in customSetting for test coverage
  public static void CreateTax_And_ServiceCharge() {
    Taxes__c tax = new Taxes__c();
    tax.Sales_Tax__c = 6.65;
    tax.Transit_Improvement_Sales_Tax__c = 6.65;
    //insert tax;
    Data.create(tax);
    /*
    ServiceCharges__c sr = new ServiceCharges__c();
    sr.Service_Charge_for_food__c = 6.65;
    insert sr;
    */
  }

  //Create Tax Mapping
  public static TxnChargeToTaxMapping__c createTaxMapping(string type, string subtype) {
    TxnChargeToTaxMapping__c newTaxMapping = new TxnChargeToTaxMapping__c();
    // commenting this because of new type subtype structure without recordtype - jyoti - not changing the signature of this method currenctly.
    //newTaxMapping.Charge__c = Utility.searchRecordType(recordType, 'TXN__c');
    newTaxMapping.Type__c = type;
    newTaxMapping.SubType__c = subtype;
    Map<string, Schema.SObjectField> fieldsMap = Taxes__c.sObjectType.getDescribe().fields.getMap();
    string taxId;
    string taxANme;
    Double taxVal;
    for (string field : fieldsMap.keySet()) {
      Schema.SObjectField F = fieldsMap.get(field);
      Schema.DescribeFieldResult R = F.getDescribe();
      if (R.isCustom()) {
        taxId = R.getName();
        taxANme = R.getLabel();
        Taxes__c allTaxesHSettings = Taxes__c.getInstance();

        try {
          taxVal = double.valueOf(allTaxesHSettings.get(taxId));
        } catch (System.TypeException ex) {
          continue;
        }
        if (taxVal != null) {
          break;
        }
      }
    }

    financialAccountNumber++;
    newTaxMapping.Service_Charge_applicable__c = true;
    newTaxMapping.TaxId__c = taxId;
    newTaxMapping.If_Taxes_Are_Applicable__c = true;
    newTaxMapping.Taxes_applicable_on_service_charge__c = true;
/*
    Tax_To_Account_Mapping__c taxFinMapping = new Tax_To_Account_Mapping__c();
    taxFinMapping.Tax__c = taxANme;
    taxFinMapping.Tax_Value__c = '6.65';
    taxFinMapping.Financial_Accounts__c = createFinancialAccount(financialAccountNumber).id;
    insert taxFinMapping;
*/
    Map<string, Schema.SObjectField> fieldsMap1 = ServiceCharges__c.sObjectType.getDescribe().fields.getMap();
    string servCharge;
    string servName;
    Double serVal;

    for (string field : fieldsMap1.keySet()) {
      Schema.SObjectField F = fieldsMap1.get(field);
      Schema.DescribeFieldResult R = F.getDescribe();
      if (R.isCustom()) {
        servCharge = R.getName();
        servName = R.getLabel();
        //c62ServiceCharges__c allServiceChargeSettings = c62ServiceCharges__c.getInstance();
        try {
          //serVal = double.valueOf(allServiceChargeSettings.get(servCharge));
        } catch (System.TypeException ex) {
          continue;
        }
        if (serVal != null) {
          break;
        }
      }
    }
/*
    newTaxMapping.tax_on_service_charge__c = servCharge;
    financialAccountNumber++;
    Tax_To_Account_Mapping__c taxFinMappingse = new Tax_To_Account_Mapping__c();
    taxFinMappingse.Service_Charge__c = servName;
    taxFinMappingse.Service_Charge_Value__c = '6.65';
    taxFinMappingse.Financial_Accounts__c = createFinancialAccount(financialAccountNumber).id;
    insert taxFinMappingse;
    */
    insert newTaxMapping; 
    return newTaxMapping;
  }
}