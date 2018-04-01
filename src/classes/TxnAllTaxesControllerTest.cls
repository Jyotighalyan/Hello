/*
@Name            : TxnAllTaxesControllerTest
@Author          : kiran@3embed.com
@Date            : May 20, 2015
@Description     : Test Class for TxnAllTaxesControllerTest
*/

@ISTest
public class TxnAllTaxesControllerTest {
      static testmethod void TxnAllTaxesController(){
            PageReference appController=Page.TxnAllTaxes;
            Test.setCurrentPage(appController);         
    
            TxnAllTaxesController AllTaxCont = new TxnAllTaxesController();
            string type;
            string subtype;
            Schema.DescribeFieldResult fieldResult = TXN__c.GlobalType__c.getDescribe(); 
            List<Schema.PicklistEntry> pl = fieldResult.getPicklistValues();
            for(Schema.PicklistEntry f : pl)
            {
            type = f.getLabel();
            break;    
            }
            Schema.DescribeFieldResult fieldResult1 = TXN__c.GlobalSubType__c.getDescribe(); 
            List<Schema.PicklistEntry> plSub = fieldResult1.getPicklistValues();
            for(Schema.PicklistEntry f : plSub)
            {
            subtype = f.getLabel();
            break;    
            } 
            MappingAndTaxUtilityTest.createTaxMapping(type,subtype);
            
            List<TxnAllTaxesController.aTableRow> tablerow = AllTaxCont.allCharges;
      }
}