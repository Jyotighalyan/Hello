/**
* @author joshi Prakash
* @date 07-07-2017
* @group Financial Management
* @description Test class for adding credit debit total on financial account.
 **/
@isTest
private class FinancialJournalLineTriggerHandlerTest
{
	@isTest
	static void CreditDebitRollupLogic()
	{
		Financial_Account__c fa = TestHandler.getFinancialAccount1();
		Financial_Journal_Line__c journalLine=new Financial_Journal_Line__c();
        journalLine.Amount__c = 10;
        journalLine.Financial_Account__c = fa.id;
        journalLine.Description__c = 'Rollup';      
        journalLine.Posted__c=true;       
        Data.create(journalLine);
        
        List<Financial_Journal_Line__c> lines = (List<Financial_Journal_Line__c>)Data.read(
                     'Select id, Financial_Account__c from Financial_Journal_Line__c',null       
                 );

        System.assertEquals(lines.size(),1);

        lines.get(0).Amount__c=33;
        Data.modify(lines.get(0));
	}
}