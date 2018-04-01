@isTest
public class MemberStatementPDFTestContTest {
	@isTest
    static void MemberStatementPDFTestContTest()
    {
        Member_statement_pdf__c cp=new Member_statement_pdf__c();
        cp.logo_left__c=0;
        cp.Name='section1';
        insert cp;
        MemberStatementPDFTestCont memStatement = new MemberStatementPDFTestCont();
        memStatement.save();
        try{
        MemberStatementPDFTestCont.SpacingSetting('LogoDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('ClubNameDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('EmailIdDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('faxDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('phoneDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('AddressDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('StatementLabelDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('note1Drag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('note2Drag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('AccountNoDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('StatementDateDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('pageNoDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('BalanceDueDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('amountPaidDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('tableDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('CurrentDrag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('over30Drag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('over60Drag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('over90Drag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('BalanceDue2Drag','10','10');
        MemberStatementPDFTestCont.SpacingSetting('color','10','10');
        MemberStatementPDFTestCont.SpacingSetting('reorderColumns','10','10');
        }catch(exception e){
            system.debug(e.getMessage());
        }
    }
}