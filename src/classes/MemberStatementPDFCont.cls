public with sharing class MemberStatementPDFCont {
     public Member_statement_pdf__c   spacing{get;set;}
    public List<Statements__c> statement{get;set;}
    public List<Statements__c> statementLines{get;set;}
    public Organization OrgDet{get;set;}
    public Map<integer,List<Statements__c>> sclns{get;set;}
    public List<integer> pages{get;set;}
    public integer totalPage{get;set;}
    public integer totalRowsToShow{get;set;}
    public MemberStatementPDFCont(){
        pages= new List<integer>();
         sclns=new Map<integer,List<Statements__c>>();
        spacing = new Member_statement_pdf__c  ();
        
        if(Member_statement_pdf__c.getall().values().size()>0){
            spacing = new Member_statement_pdf__c  ();
        	spacing = Member_statement_pdf__c.getall().values();
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please set the values for check spacing in "Member statement PDF" custom setting first.'));
        }
        totalRowsToShow=integer.valueOf(spacing.total_rows_to_show__c);
    }
    public void getprintCheckList(){
        OrgDet=[select id,name,Address, Phone,fax, Street from Organization];
        String StatementId = ApexPages.currentPage().getparameters().get('id');
        
        if(StatementId==null || StatementId==''){
            return;
        }
        statement = (List<Statements__c>)Data.read(
            'Select Amount__c , Billing_Period__c, Customer__c, Member__r.Customer_Id__c, Date__c , '+
            'Statement_Balance__c  '+
            'from Statements__c  where id=:StatementId order by Date__c ASC',
            new Map<String,Object> {
                'StatementId' => StatementId
                    }
        );
        statementLines= (List<Statements__c>)Data.read(
            'Select Amount__c , Billing_Period__c, Description__c , Service_Charge__c , Tax__c , Customer__c, Date__c , '+
            'Statement_Balance__c  '+
            'from Statements__c  where Statement__c=:StatementId order by Date__c ASC',
            new Map<String,Object> {
                'StatementId' => StatementId
                    }
        );
        integer i=0;
        for(i = 1;i<=100;i++){
            Statements__c sc=new Statements__c();
            sc.Amount__c=i *-1;
            sc.Description__c='testing' + i;
            sc.Date__c=date.today();
            sc.Tax__c=0;
            sc.Service_Charge__c=0;
            statementLines.add(sc);
        }
        for(i =1;i<=statementLines.size()/totalRowsToShow;i++){
            pages.add(i);
        }
        pages.add(i);
         i=1;
        integer tot=1;
        List<Statements__c> lc=new List<Statements__c>();
        for(Statements__c scc : statementLines){
            system.debug('check this list : '+  scc);
            lc.add(scc);
            if(tot==totalRowsToShow){
                sclns.put(i, lc);
                lc=new List<Statements__c>();
                tot=1;
                i++;
            }
            tot++;
        }
        sclns.put(i, lc);
        totalPage = i;
        system.debug('check this map : '+  sclns);
        
    }
}