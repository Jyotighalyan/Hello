public with sharing class ManualCreditController {
    public ManualCreditService serviceImpObj;
    public TXN__c txnObj{get;set;}
    public integer lastIndex{get;set;}
    public integer cObjIndex{get;set;}
    public Double TotalAmount{get;set;}
    public Map<Integer,ManualCreditService.CreditSplitWrapper> CreditList{get;set;}
    public ManualCreditController() {
        string message=''+ApexPages.CurrentPage().GetParameters().Get('message');
        if(message!=''&&message!='null'){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.CONFIRM,message));
        }
        serviceImpObj=new ManualCreditService();
        txnObj = new TXN__c();
        CreditList = new Map<Integer,ManualCreditService.CreditSplitWrapper>();
        for(Integer i=1;i<=5;i++){
            TXN__c newObj=new TXN__c();
            CreditList.put(i,new ManualCreditService.CreditSplitWrapper(i, newObj,''));
            lastIndex=i;
        }
    }
    public void delMember(){
        if(cObjIndex!=null){
            CreditList.remove(cObjIndex);
        }
    }
    public void addMoreRows(){
        CreditList = serviceImpObj.addMoreRows(lastIndex, CreditList);       
    }
    public List<ManualCreditService.CreditSplitWrapper> getCreditListV(){
        return CreditList.values();
    }
    public pagereference save(){
        double TotalDebit=0.00;
        integer TotalIndex=0;
        for(ManualCreditService.CreditSplitWrapper pw : CreditList.values()){
            if(pw.manCredit.Financial_Account__c!=null &&  pw.DebitAmt!=null && pw.DebitAmt!=''){
                TotalIndex = TotalIndex + 1;
                TotalDebit = TotalDebit + double.valueOf(pw.DebitAmt);
            }
        }
        
        if(TotalAmount == null || TotalAmount <= 0 ){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Please enter amount.'));
            return null;
        }
        if(txnObj.Date__c == null){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Please select date.'));
            return null;
        }
        if(txnObj.Customer__c == null){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Please select customer.'));
            return null;
        }
        if(txnObj.Credit_Financial_Account__c == null){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Enter credit financial account'));
            return null;
        }
        if(TotalIndex == 0){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Enter at least one debit account.'));
            return null;
        }
        if(TotalAmount != TotalDebit){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Total of Debit amount should be same as total amount.'));
            return null;
        }
        String creditRecordTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Credit').getRecordTypeId();
        if(TotalIndex==1){
            string debitAccount='';
            string creditAccount='';
            for(ManualCreditService.CreditSplitWrapper pw : CreditList.values()){
                if(pw.manCredit.Financial_Account__c!=null){
                    if(double.valueOf(pw.DebitAmt) > 0){
                        debitAccount = pw.manCredit.Financial_Account__c;
                    }
                }
            }
            txnObj.Amount__c=TotalAmount * -1;
            txnObj.RecordTypeId=creditRecordTypeId;
            txnObj.Customer__c=txnObj.Customer__c;
            txnObj.Bill_To_Member__c=txnObj.Customer__c;
            txnObj.Debit_Financial_Account__c=debitAccount;
            data.create(txnObj);
        }else{
            List<TXN__c> insertRecs=new List<TXN__c>();
            string creditAcc='';
            for(ManualCreditService.CreditSplitWrapper pw : CreditList.values()){
                if(pw.manCredit.Financial_Account__c!=null){
                    if(double.valueOf(pw.DebitAmt) > 0){
                        TXN__c rec=new TXN__c();
                        rec.Amount__c=double.valueOf(pw.DebitAmt) * -1;
                        rec.Amount_Remaining__c=double.valueOf(pw.DebitAmt);
                        rec.Internal_Notes__c=txnObj.Internal_Notes__c;
                        rec.RecordTypeId=creditRecordTypeId;
                        rec.Customer__c=txnObj.Customer__c;
                        rec.Bill_To_Member__c=txnObj.Customer__c;
                        rec.Transaction_Split__c =true;
                        rec.Date__c =txnObj.Date__c;
                        rec.Debit_Financial_Account__c=pw.manCredit.Financial_Account__c;
                        rec.Credit_Financial_Account__c=txnObj.Credit_Financial_Account__c;
                        rec.Statement_Description__c=txnObj.Statement_Description__c;
                        insertRecs.add(rec);  
                    }
                }
            }
            TXN__c masterRec=insertRecs[0];
            data.create(masterRec);
            insertRecs.remove(0);
            List<TXN__c> ChildRecs=new List<TXN__c>();
            for(TXN__c chils : insertRecs){
                chils.Related_To__c = masterRec.id;
                ChildRecs.add(chils);
            }
            data.create(ChildRecs);
        }
        PageReference pg;
        pg=page.ManualCredit;
        pg.getParameters().put('message','Saved Successfully');
        pg.setRedirect(true);
        return pg;
    }
}