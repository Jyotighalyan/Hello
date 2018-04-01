public with sharing class GeneralLedgerReportCont {
    public TXN__c txnRec{get;set;}
    public List<Financial_Journal_Line__c> entries{get;set;}
    public List <id> accounts{get;set;}
    public integer startAccNo{get;set;}
    public integer endAccNo{get;set;}
    public List<Financial_Account__c> acList{get;set;}
    public Financial_Account__c fAcc{get;set;}
    public Decimal starting_bal{get;set;}
    public Decimal total_debit{get;set;}
    public Decimal total_credit{get;set;}
    public Decimal current_balance{get;set;}
    public Decimal totalBalance{get;set;}
    public boolean showTable{get;set;}
    public List<SelectOption> options{get;set;}
    public GeneralLedgerReportCont(){
        accounts = new List <id>();
        acList=new List<Financial_Account__c>();
        txnRec=new TXN__c();
        fAcc=new Financial_Account__c();
        showTable=false;
        entries= new List<Financial_Journal_Line__c>();
        
        acList = (List<Financial_Account__c>)Data.read(
            'select id, name   from Financial_Account__c where Active__c = true',
            new Map<String,Object> {
            }
        ); 
         options = new List<SelectOption>();
        for(Financial_Account__c accs : acList){
            options.add(new SelectOption(accs.id,accs.name));
        }
    }
    public void sortAccounts(){
       
        string addon='';
        if( fAcc.Category__c!=null){
            addon = ' and Category__c= :AccCat';
        }
        if(fAcc.Department2__c!=null){
            addon = addon + ' and Department2__c= :selectedDepartment';
        }
        acList = (List<Financial_Account__c>)Data.read(
            'select id, name   from Financial_Account__c where Active__c = true '+ addon ,
            new Map<String,Object> {
                'AccCat'=>fAcc.Category__c,
                'selectedDepartment'=>fAcc.Department2__c
            }
        ); 
        options = new List<SelectOption>();
        for(Financial_Account__c accs : acList){
            options.add(new SelectOption(accs.id,accs.name));
        }
         system.debug('hi i am here ' + addon);
        
    }
    public List<SelectOption> getfullAccList() {
        return options;
    }
    public void LoadEntries(){
        
        if(ApexPages.CurrentPage().GetParameters().Get('from')!='' && ApexPages.CurrentPage().GetParameters().Get('from')!=null){
            txnRec.Date__c=date.valueOf(ApexPages.CurrentPage().GetParameters().Get('from'));
            txnRec.Check_Date__c=date.valueOf(ApexPages.CurrentPage().GetParameters().Get('to'));
            if(ApexPages.CurrentPage().GetParameters().Get('cat')!=null && ApexPages.CurrentPage().GetParameters().Get('cat')!=''){
                fAcc.Category__c = ApexPages.CurrentPage().GetParameters().Get('cat');
            }
            if(ApexPages.CurrentPage().GetParameters().Get('dep')!=null && ApexPages.CurrentPage().GetParameters().Get('dep')!=''){
                fAcc.Department2__c= ApexPages.CurrentPage().GetParameters().Get('dep');
            }
            
            if(ApexPages.CurrentPage().GetParameters().Get('acc')!=null && ApexPages.CurrentPage().GetParameters().Get('acc')!=''){
                string csvAcc='';
                csvAcc=ApexPages.CurrentPage().GetParameters().Get('acc');
                accounts = csvAcc.split(',');
            }
        }else{
            if(txnRec.Date__c == null ||txnRec.Check_Date__c == null ){
                ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'From and To date should be slected'));
                return;
            }
            if(txnRec.Date__c > txnRec.Check_Date__c  ){
                ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'From date should be less then to date'));
                return;
            }
        }
        string addon = '';
        if(fAcc.Department2__c!=null){
            addon = ' and Financial_Account__r.Department2__c = :selectedDepartment';
        }
        if(fAcc.Category__c!=null){
            addon = addon + ' and Financial_Account__r.Category__c = :AccCat';
        }
        if(accounts.size()>0){
            addon = addon + ' and Financial_Account__r.id in :financialAccs';
        }
        // fromDate =date.valueOf('2017-10-1');
        //toDate =date.valueOf('2017-10-31');
        
        
        entries = (List<Financial_Journal_Line__c>)Data.read(
            'Select Amount__c,Financial_Account__c,id,name, Description__c , Financial_Journal_Entry__c  , Credit__c , Debit__c , Post_Date__c   from Financial_Journal_Line__c '+
            ' where Post_Date__c>= :fromDate and Post_Date__c<= :toDate ' + addon,
            new Map<String,Object> {
                'fromDate'=>txnRec.Date__c,
                    'toDate'=>txnRec.Check_Date__c,
                    'AccCat'=>fAcc.Category__c,
                    'selectedDepartment'=>fAcc.Department2__c,
                    'financialAccs'=>accounts
                    }
        ); 
        if(entries.size()==0){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.INFO,'No entries found in selected criteria. Please change the criteria.'));
            return;
        }
        showTable=true;
        AggregateResult[] totalDebitCreditForSelectedPeriod = (AggregateResult[])Data.read(
            'Select sum(Credit__c) credit,sum(Debit__c) debit  from Financial_Journal_Line__c '+
            ' where Post_Date__c>= :fromDate and Post_Date__c<= :toDate '+addon,
            new Map<String,Object> {
                'fromDate'=>txnRec.Date__c,
                    'toDate'=>txnRec.Check_Date__c,
                    'AccCat'=>fAcc.Category__c,
                    'selectedDepartment'=>fAcc.Department2__c,
                    'financialAccs'=>accounts
                    }
        ); 
        total_debit=double.valueOf(totalDebitCreditForSelectedPeriod[0].get('debit'));
        total_credit=double.valueOf(totalDebitCreditForSelectedPeriod[0].get('credit'));
        current_balance=(total_debit-total_credit).setScale(2);
        AggregateResult[] startingBalanceGet = (AggregateResult[])Data.read(
            'Select sum(Credit__c) credit,sum(Debit__c) debit  from Financial_Journal_Line__c '+
            ' where Post_Date__c< :fromDate '+ addon,
            new Map<String,Object> {
                'fromDate'=>txnRec.Date__c,
                    'toDate'=>txnRec.Check_Date__c,
                    'AccCat'=>fAcc.Category__c,
                    'selectedDepartment'=>fAcc.Department2__c,
                    'financialAccs'=>accounts
                    }
        ); 
        
        starting_bal=double.valueOf(startingBalanceGet[0].get('debit'))-double.valueOf(startingBalanceGet[0].get('credit')); 
        starting_bal = starting_bal.setScale(2);
        totalBalance= (starting_bal + current_balance).setScale(2);
    }
    
    public PageReference exportPDF(){
        
        //page reference
        String[] tmp1 = New String[]{};
            for(string id:accounts){
                tmp1.add(id);
            }
        PageReference pg;
        pg=page.GeneralLedgerReportPDF;
        pg.getParameters().put('from',string.valueOf(txnRec.Date__c));
        pg.getParameters().put('to',string.valueOf(txnRec.Check_Date__c));
        pg.getParameters().put('cat',string.valueOf(fAcc.Category__c));
        pg.getParameters().put('dep',string.valueOf(fAcc.Department2__c));
        if(tmp1.size()>0){
            pg.getParameters().put('acc',string.join(tmp1,','));
        }
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Saved Successfully'));
        pg.setRedirect(true);
        return pg;
    }
    public pagereference exportExcel(){
        //page reference
        String[] tmp1 = New String[]{};
            for(string id:accounts){
                tmp1.add(id);
            }
        PageReference pg;
        pg=page.exportToExcel;
        pg.getParameters().put('from',string.valueOf(txnRec.Date__c));
        pg.getParameters().put('to',string.valueOf(txnRec.Check_Date__c));
        pg.getParameters().put('cat',string.valueOf(fAcc.Category__c));
        pg.getParameters().put('dep',string.valueOf(fAcc.Department2__c));
        if(tmp1.size()>0){
            pg.getParameters().put('acc',string.join(tmp1,','));
        }
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Saved Successfully'));
        pg.setRedirect(true);
        return pg;
    }
    
}