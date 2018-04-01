/**
* @author joshi Prakash
* @date 06-20-2017
* @group Financial Management
* @description Controller class to create update and delete financial manual journal entry
 **/
@isTest
private class RecurringJournalEntryControllerTest {
    @isTest
    static void RecurringJournalEntryControllerCRUDTest() {

        /*Create new finacial journal entry block*/
        PageReference pageRef = Page.RecurringJournalEntry;
        Test.setCurrentPage(pageRef);

        Financial_Account__c fa = TestHandler.getFinancialAccount1();
        Financial_Journal_Line__c fjl = new Financial_Journal_Line__c(Financial_Account__c = fa.id, Transaction_Date__c = Date.today(), Posted__c = true, Amount__c = 10);
        ApexPages.StandardController sc = new ApexPages.StandardController(fjl);
        RecurringJournalEntryController apc = new RecurringJournalEntryController(sc);

        Test.startTest();

        List<RecurringJournalEntryController.ManualJournalLine> initialGrids = apc.manEntry.getJournalList();
        system.assertEquals(initialGrids.size(), 10);

        apc.numberLinesToAdd = 10;
        apc.addNewEntryLines();
        initialGrids = apc.manEntry.getJournalList();
        system.assertEquals(initialGrids.size(), 20);

        apc.manEntry.fje.Recurring_Entry_Name__c = 'Test';
        apc.manEntry.fje.Recurring_Journal_Frequency__c = 'Monthly';

        apc.manEntry.mjlList.get(0).linecrd = '10';
        apc.manEntry.mjlList.get(0).fjl.Financial_Account__c = fa.id;
        apc.manEntry.mjlList.get(0).fjl.Description__c = 'Test finacial journal line';

        apc.manEntry.mjlList.get(1).debit = '10';
        apc.manEntry.mjlList.get(1).fjl.Financial_Account__c = fa.id;
        apc.manEntry.mjlList.get(1).fjl.Description__c = 'Test finacial journal line';
        apc.calDebCredTotal();

        apc.addNewEntry();

        List<Financial_Journal_Entry__c> fjeLst = (List<Financial_Journal_Entry__c>)Data.read(
                    'select Id, (select id from Financial_Journals__r) from Financial_Journal_Entry__c where Recurring_Entry__c = :isRecurring',
        new Map<String, Object> {
            'isRecurring' => true
        }
                );

        System.assertEquals(fjeLst.get(0).Financial_Journals__r.size(), 2);
        /**Insert new new entries ends**/

        /**Update existing entries start**/
        apc.cSelId = apc.getmanualEntries().get(0).fje.id;
        apc.setSelFJE();
        apc.numberLinesToAdd = 10;
        apc.addNewExistingLines();

        apc.selectedMe.mjlList.get(2).linecrd = '10';
        apc.selectedMe.mjlList.get(2).fjl.Financial_Account__c = fa.id;
        apc.selectedMe.mjlList.get(2).fjl.Description__c = 'Test finacial journal line';

        apc.selectedMe.mjlList.get(3).debit = '10';
        apc.selectedMe.mjlList.get(3).fjl.Financial_Account__c = fa.id;
        apc.selectedMe.mjlList.get(3).fjl.Description__c = 'Test finacial journal line';

        //Delete one manual journal line at the time of editing the grid
        apc.fjeId = apc.getmanualEntries().get(0).fje.id;
        apc.fjlId = apc.selectedMe.mjlList.get(1).fjl.id;
        apc.delFJL();

        apc.updateEntry();
        apc.closeSelectedME();

        fjeLst = (List<Financial_Journal_Entry__c>)Data.read(
                     'select Id, (select id from Financial_Journals__r) from Financial_Journal_Entry__c where Recurring_Entry__c = :isRecurring',
        new Map<String, Object> {
            'isRecurring' => true
        }
                 );

        System.assertEquals(fjeLst.get(0).Financial_Journals__r.size(), 3);
        /**Update existing entries end**/

        /**Clone selected template**/
        apc.cSelId = apc.getmanualEntries().get(0).fje.id;
        apc.setSelFJE();
        apc.cloneSelected();

        /**Delete manual journal entry start**/
        apc.cSelDelId = apc.getmanualEntries().get(0).fje.id;
        apc.delSelFJE();
        System.assertEquals(apc.getmanualEntries().size(), 0);
        /**Delete manual journal entry end**/

        Test.stopTest();
    }
}