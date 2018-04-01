public with sharing class CheckDepositeService {
    public CheckDepositeService(){
        
    }
    public class PaymentWrapper{
        public Integer index{get;set;}
        public Deposit_Batch_Check_Payment__c BCDP{get;set;}
        public PaymentWrapper(Integer i, Deposit_Batch_Check_Payment__c data){
            index = i;
            BCDP=data;
        }
    }
    public class PaymentWrapperToMerge{
        public Integer index{get;set;}
        public Deposit_Batch_Check_Payment__c BCDP{get;set;}
        public PaymentWrapperToMerge(Integer i, Deposit_Batch_Check_Payment__c data){
            index = i;
            BCDP=data;
        }
    }
    public Map<Integer,PaymentWrapper> addMoreRows(integer LastIndex, Map<Integer,PaymentWrapper> payList){
        lastIndex++;
        integer max=lastIndex + 10;
        for(Integer i=lastIndex;i<max;i++){
            system.debug('i am in with :'+i);
            Deposit_Batch_Check_Payment__c newObj=new Deposit_Batch_Check_Payment__c();
            payList.put(i,new CheckDepositeService.PaymentWrapper(i, newObj));
            lastIndex=i;
        }
        return payList;
    }
    public boolean PostBatch(id selectedPastBD,Map<Integer,PaymentWrapper> payList, string DebitAcc){
        Savepoint sp = Database.setSavepoint();
        List<Deposit_Batch_Check_Payment__c> updateList=new List<Deposit_Batch_Check_Payment__c>();
        List<TXN__c> addNewList=new List<TXN__c>();
        for(CheckDepositeService.PaymentWrapper p : payList.values()){
            
            if(p.BCDP.Customer__c!=null){
                if(p.BCDP.Amount__c == 0 || p.BCDP.Check_Number__c == '' ||p.BCDP.Check_Number__c == '0' ){
                    ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Please enter valid Amount or Check number.'));
                    Database.rollback(sp);
                    return false;
                }else{
                    TXN__c txnRecord=new TXN__c ();
                    txnRecord.Amount__c=p.BCDP.Amount__c * -1;
                    txnRecord.Customer__c=p.BCDP.Customer__c;
                    txnRecord.Bill_To_Member__c = Utility.getBillToMember(new List<Id>{p.BCDP.Customer__c}).get(p.BCDP.Customer__c);
                    txnRecord.Payment_Type__c='Check';
                    txnRecord.Check_Date__c=p.BCDP.Check_Date__c;
                    txnRecord.Check_Number__c=p.BCDP.Check_Number__c;
                    txnRecord.Name_on_Check__c=p.BCDP.Customer__r.name;
                    txnRecord.Date__c=date.today();
                    txnRecord.Debit_Financial_Account__c=DebitAcc;
                    txnRecord.Statement_Description__c='check payment';
                    String PyamentRecordTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId();
                    txnRecord.RecordTypeId=PyamentRecordTypeId;
                    addNewList.add(txnRecord);
                }
            }
        }
        data.create(addNewList);
        integer i=0;
        for(CheckDepositeService.PaymentWrapper p : payList.values()){
            if(p.BCDP.Customer__c!=null){
                if(p.BCDP.Amount__c == 0 || p.BCDP.Check_Number__c == '' ||p.BCDP.Check_Number__c == '0' ){

                }else{
                    p.BCDP.Transaction__c=addNewList[i].id;
                    i++;
                    updateList.add(p.BCDP);
                }
            }
            
        }
        data.modify(updateList);
        Bank_Deposit__c Deposit=new Bank_Deposit__c ();
        Deposit.id=selectedPastBD;
        Deposit.Posted__c=true;
        data.modify(Deposit);
        return true;
    }
    public boolean MergeBoth(id selectedPastBD, id selectedPastBDForMerge,Map<Integer,PaymentWrapperToMerge> payListToMerge){
        
        if(selectedPastBD == selectedPastBDForMerge){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'You can not mearge same batch.'));
            return false;
        }
        List<Deposit_Batch_Check_Payment__c> GetLastIndex = (List<Deposit_Batch_Check_Payment__c>)Data.read(
            'Select Index__c from Deposit_Batch_Check_Payment__c where Bank_Deposit__c=:selectedPastBD order by Index__c DESC',
            new Map<String,Object> {
                'selectedPastBD' => selectedPastBD
                    }
        );
        integer LastIndex = integer.valueOf(GetLastIndex.get(0).Index__c); 
        List<Deposit_Batch_Check_Payment__c> updateList=new List<Deposit_Batch_Check_Payment__c>();      
        for(CheckDepositeService.PaymentWrapperToMerge p : payListToMerge.values()){
            p.BCDP.Bank_Deposit__c=selectedPastBD;
            p.BCDP.Index__c=++LastIndex;
            updateList.add(p.BCDP);
        }
        data.modify(updateList);
        List<Bank_Deposit__c> OldBatch= (List<Bank_Deposit__c>)Data.read('Select Id From Bank_Deposit__c Where id =:selectedPastBDForMerge',
                                                                         new Map<String,Object> {
                                                                             'selectedPastBDForMerge'=> selectedPastBDForMerge
                                                                                 }
                                                                        );
        data.remove(OldBatch);
        return true;
    }
    public boolean saveCheckDepositPayments(Bank_Deposit__c bd,List<PaymentWrapper> payListToDelete, id selectedPastBD,Map<Integer,PaymentWrapper> payList){
        if(bd.Financial_Account__c==null){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Bank account is required'));
            return false;
        }
        if(bd.Deposit_Slip_Number__c==null || bd.Deposit_Slip_Number__c==''){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Deposite slip number is required'));
            return false;
        }
        if(bd.Deposit_Date__c==null){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Deposite date required.'));
            return false;
        }
        Savepoint sp = Database.setSavepoint();
        
        List<Deposit_Batch_Check_Payment__c> dbcpList = new List<Deposit_Batch_Check_Payment__c>();
        for(CheckDepositeService.PaymentWrapper pw : payListToDelete){
            if(pw.BCDP!=null){
                dbcpList.add(pw.BCDP);
            }
        }
        data.remove(dbcpList);
        payListToDelete.clear();
        List<Deposit_Batch_Check_Payment__c> updateList=new List<Deposit_Batch_Check_Payment__c>(); 
        List<Deposit_Batch_Check_Payment__c> addNewList=new List<Deposit_Batch_Check_Payment__c>(); 
        try{
            if(selectedPastBD != null){
                data.modify(bd);
                for(CheckDepositeService.PaymentWrapper p : payList.values()){
                    
                    if(p.BCDP.Customer__c!=null){
                        if(p.BCDP.Amount__c == 0 || p.BCDP.Check_Number__c == '' ||p.BCDP.Check_Number__c == '0' ){
                            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Please enter valid Amount or Check number.'));
                            Database.rollback(sp);
                            return false;
                        }
                        if(p.BCDP.id==null){
                            p.BCDP.Index__c=P.Index;
                            p.BCDP.Bank_Deposit__c=bd.Id;
                            addNewList.add(p.BCDP);
                        }else{
                            updateList.add(p.BCDP);
                        }
                    }
                }
                data.create(addNewList);
                data.modify(updateList);
            }else{
                data.create(bd);
                addNewList=new List<Deposit_Batch_Check_Payment__c>(); 
                for(CheckDepositeService.PaymentWrapper p : payList.values()){
                    if(p.BCDP.Customer__c!=null){
                        if(p.BCDP.Amount__c == 0 || p.BCDP.Check_Number__c == '' ||p.BCDP.Check_Number__c == '0' ){
                            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Please enter valid Amount or Check number.'));
                            Database.rollback(sp);
                            return false;
                        }
                        p.BCDP.Bank_Deposit__c=bd.id;
                        p.BCDP.Index__c=P.Index;
                        addNewList.add(p.BCDP);
                    }
                }
                data.create(addNewList);
            }
        }catch(Exception e){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
            Database.rollback(sp);
            return false;
        }
        return true;
    }
}