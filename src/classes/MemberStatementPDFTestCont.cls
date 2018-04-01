public with sharing class MemberStatementPDFTestCont {
    public Member_statement_pdf__c   spacing{get;set;}
    public MemberStatementPDFTestCont() {
        spacing = new Member_statement_pdf__c  ();
        if(Member_statement_pdf__c.getall().values().size()>0){
            spacing = new Member_statement_pdf__c  ();
        	spacing = Member_statement_pdf__c.getall().values();
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please set the values for check spacing in "Member statement PDF" custom setting first.'));
        }
    }
    @RemoteAction
    public static List<Member_statement_pdf__c> SpacingSetting(string fieldName,string top, string left){
        Member_statement_pdf__c setting =new Member_statement_pdf__c();
        List<Member_statement_pdf__c> AllCSData = Member_statement_pdf__c.getall().values();
        if(fieldName == 'LogoDrag'){
        	setting.logo_left__c  = double.valueOf(left);
            setting.logo_top__c  = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'ClubNameDrag'){
        	setting.club_name_left__c  = double.valueOf(left);
            setting.club_name_top__c  = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'EmailIdDrag'){
        	setting.club_email_left__c   = double.valueOf(left);
            setting.club_email_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'faxDrag'){
        	setting.fax_left__c  = double.valueOf(left);
            setting.fax_top__c  = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'phoneDrag'){
        	setting.club_phone_left__c   = double.valueOf(left);
            setting.club_phone_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'AddressDrag'){
        	setting.club_address_left__c   = double.valueOf(left);
            setting.club_address_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'StatementLabelDrag'){
        	setting.statement_label_left__c   = double.valueOf(left);
            setting.statement_label_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'note1Drag'){
        	setting.notes_1_left__c    = double.valueOf(left);
            setting.notes_1_top__c    = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'note2Drag'){
        	setting.notes_2_left__c    = double.valueOf(left);
            setting.notes_2_top__c    = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'AccountNoDrag'){
        	setting.account_no_left__c    = double.valueOf(left);
            setting.account_no_top__c    = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'StatementDateDrag'){
        	setting.statement_date_left__c    = double.valueOf(left);
            setting.statement_date_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'pageNoDrag'){
        	setting.page_no_left__c     = double.valueOf(left);
            setting.page_no_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'BalanceDueDrag'){
        	setting.due_left__c     = double.valueOf(left);
            setting.due_top__c    = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'amountPaidDrag'){
        	setting.amount_paid_left__c     = double.valueOf(left);
            setting.amount_paid_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'tableDrag'){
        	setting.table_left__c     = double.valueOf(left);
            setting.table_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }
        else
        if(fieldName == 'CurrentDrag'){
        	setting.Current_left__c      = double.valueOf(left);
            setting.Current_top__c    = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'over30Drag'){
        	setting.over_30_left__c     = double.valueOf(left);
            setting.over_30_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'over60Drag'){
        	setting.over_60_left__c     = double.valueOf(left);
            setting.over_60_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'over90Drag'){
        	setting.over_90_left__c     = double.valueOf(left);
            setting.over_90_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'BalanceDue2Drag'){
        	setting.balance_due_left__c     = double.valueOf(left);
            setting.balance_due_top__c   = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'color'){
        	setting.color__c     = top;
            setting.Id=AllCSData[0].id;
        }/*if(fieldName=='reorderColumns'){
            integer fromm = integer.valueOf(top);
            integer to = integer.valueOf(left);
           	string temp='';
           	String[]  csvFieldNames = AllCSData[0].column_order__c.split(',');
            temp = csvFieldNames[fromm];
            csvFieldNames[fromm]=csvFieldNames[to];
            csvFieldNames[to]=temp;
            setting.column_order__c  = string.join(csvFieldNames,',') ;
            setting.Id=AllCSData[0].id;
           
        }*/
		    
        data.modify(setting);
        return null; 
    }
    
    public void save(){
        List<Member_statement_pdf__c> AllCSData = Member_statement_pdf__c.getall().values();
        AllCSData[0].Note_1__c =spacing.Note_1__c;
		AllCSData[0].Note_2__c =spacing.Note_2__c;
        AllCSData[0].table_header_1__c =spacing.table_header_1__c;
		AllCSData[0].table_header_2__c =spacing.table_header_2__c;
        AllCSData[0].table_header_3__c =spacing.table_header_3__c;
		AllCSData[0].table_header_4__c =spacing.table_header_4__c;
        AllCSData[0].table_header_5__c =spacing.table_header_5__c;
		AllCSData[0].table_header_6__c =spacing.table_header_6__c;
        AllCSData[0].table_header_7__c =spacing.table_header_7__c;
        AllCSData[0].table_header_8__c =spacing.table_header_8__c;
        AllCSData[0].table_header_9__c =spacing.table_header_9__c;
        AllCSData[0].table_header_10__c =spacing.table_header_10__c;
        
        AllCSData[0].table_header_1_hide__c =spacing.table_header_1_hide__c;
        AllCSData[0].table_header_2_hide__c =spacing.table_header_2_hide__c;
        AllCSData[0].table_header_3_hide__c =spacing.table_header_3_hide__c;
        AllCSData[0].table_header_4_hide__c =spacing.table_header_4_hide__c;
        AllCSData[0].table_header_5_hide__c =spacing.table_header_5_hide__c;
        AllCSData[0].table_header_6_hide__c =spacing.table_header_6_hide__c;
        AllCSData[0].table_header_7_hide__c =spacing.table_header_7_hide__c;
        AllCSData[0].table_header_8_hide__c =spacing.table_header_8_hide__c;
        AllCSData[0].table_header_9_hide__c =spacing.table_header_9_hide__c;
        AllCSData[0].table_header_10_hide__c =spacing.table_header_10_hide__c;
        
        AllCSData[0].table_header_1_Width__c =spacing.table_header_1_Width__c;
        AllCSData[0].table_header_2_Width__c =spacing.table_header_2_Width__c;
        AllCSData[0].table_header_3_Width__c =spacing.table_header_3_Width__c;
        AllCSData[0].table_header_4_Width__c =spacing.table_header_4_Width__c;
        AllCSData[0].table_header_5_Width__c =spacing.table_header_5_Width__c;
        AllCSData[0].table_header_6_Width__c =spacing.table_header_6_Width__c;
        AllCSData[0].table_header_7_Width__c =spacing.table_header_7_Width__c;
        AllCSData[0].table_header_8_Width__c =spacing.table_header_8_Width__c;
        AllCSData[0].table_header_9_Width__c =spacing.table_header_9_Width__c;
        AllCSData[0].table_header_10_Width__c =spacing.table_header_10_Width__c;
        
        AllCSData[0].email_id__c =spacing.email_id__c;
        AllCSData[0].total_rows_to_show__c=spacing.total_rows_to_show__c;
         
        
        
        data.modify(AllCSData);
    }
}