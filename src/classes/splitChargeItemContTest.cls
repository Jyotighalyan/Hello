@isTest
public class splitChargeItemContTest {
	@isTest
	static void splitChargeItemContTest1()
	{
		Financial_Account__c fa = new Financial_Account__c(Name='Test',Account_Number__c='asd32sd',Category__c='Liability');
        insert fa;
        
        TxnChargeToTaxMapping__c taxObj= new TxnChargeToTaxMapping__c();
        taxObj.Type__c='Breakfast';
        taxObj.Subtype__c = 'Buffet';
        taxObj.Allow_in_POS__c=true;
        taxObj.Taxes_applicable_on_service_charge__c=false;
        taxObj.Service_Charge_applicable__c=false;
        insert taxObj;
        
		Id recId = Utility.searchRecordType('Misc Charges','Charge_Item__c');

		Charge_Item__c ci = new Charge_Item__c();
		ci.Type__c = 'Breakfast';
		ci.SubType__c = 'Buffet';
		ci.RecordTypeId = recId;
		ci.Price__c = 10;
		insert ci;
        
        Test.startTest();
        Revenue_Split__c revSplit = new Revenue_Split__c();
        revSplit.Split_Amount__c=10;
        revSplit.Charge_Item__c=ci.id;
        revSplit.Financial_Account__c=fa.id;
        insert revSplit;
        ApexPages.StandardController sc = new ApexPages.StandardController(revSplit);
        splitChargeItemController scic = new splitChargeItemController(sc);
        scic.revSplit.Split_Amount__c=10;
        scic.revSplit.Financial_Account__c=fa.id;
        scic.save();
        scic.savenew();
        scic.cancel();
        
        
        ci.Price__c = 20;
        update ci;
        
        PageReference pRef = Page.CreateVendInvLine;
  		pRef.getParameters().put('id', revSplit.Id);
        Test.setCurrentPage(pRef);
        scic = new splitChargeItemController(sc);
        scic.revSplit.Financial_Account__c=fa.id;
        scic.revSplit.Split_Amount__c=0;
        try{
             scic.save(); 
        }catch(exception e){
             System.assertEquals('Split amount should be more then 0', e.getMessage());
        }
       
        scic.revSplit.Split_Amount__c=20;
        scic.save();
        scic.revSplit.Split_Amount__c=0;
        try{
             scic.savenew(); 
        }catch(exception e){
             System.assertEquals('Split amount should be more then 0', e.getMessage());
        }
        scic.revSplit.Split_Amount__c=20;
        scic.savenew();
       test.stopTest();
    }
}