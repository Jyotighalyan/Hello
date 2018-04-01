public with sharing class CheckDepositController {
    public CheckDepositeService serviceImpObj;
    public Bank_Deposit__c bd{get;set;}
    public Bank_Deposit__c bdForMerge{get;set;}
    public String strGridField{get;set;}
    public Map<Integer,CheckDepositeService.PaymentWrapper> payList{get;set;}
    public Map<Integer,CheckDepositeService.PaymentWrapperToMerge> payListToMerge{get;set;}
    public List<String> autoApplyOptions{get;set;}
    public List<SelectOption> unPostedBDSO{get;set;}
    public List<SelectOption> unPostedBDSOForMerge{get;set;}
    public Map<Id,Bank_Deposit__c> unPostedBDMap{get;set;}
    public integer cObjIndex{get;set;}
    public Id selectedPastBD{get;set;}
    public Id selectedPastBDForMerge{get;set;}
    public integer lastIndex{get;set;}
    public boolean canIPost{get;set;}
    public List<CheckDepositeService.PaymentWrapper> payListToDelete{get;set;}
    
    public CheckDepositController(ApexPages.StandardController stdController) {
        canIPost=false;
        string message=''+ApexPages.CurrentPage().GetParameters().Get('message');
        if(message!=''&&message!='null'){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.CONFIRM,message));
        }
        serviceImpObj=new CheckDepositeService();
        bd=new Bank_Deposit__c(Total__c=0.00);
        bdForMerge=new Bank_Deposit__c(Total__c=0.00);
        payList = new Map<Integer,CheckDepositeService.PaymentWrapper>();
        payListToMerge = new Map<Integer,CheckDepositeService.PaymentWrapperToMerge>();
        autoApplyOptions = new List<String>();
        for(Integer i=1;i<=10;i++){
            Deposit_Batch_Check_Payment__c newObj=new Deposit_Batch_Check_Payment__c();
            payList.put(i,new CheckDepositeService.PaymentWrapper(i, newObj));
            lastIndex=i;
        }
        unPostedBDMap = new Map<Id,Bank_Deposit__c>();
        loadPastBankDeposits();
        payListToDelete = new List<CheckDepositeService.PaymentWrapper>();
    }
    public void addMoreRows(){
        payList = serviceImpObj.addMoreRows(lastIndex, payList);       
    }
    public void makeAmountFieldBlank(){
        CheckDepositeService.PaymentWrapper PLVal = payList.get(cObjIndex);
        if(PLVal.BCDP.Amount__c>0){
            recalcTotal();
        }else{
            PLVal.BCDP.Amount__c = null;
        }
        if(PLVal.BCDP.Check_Number__c=='0'){
            PLVal.BCDP.Check_Number__c = null;
        }
        system.debug('check check :'+PLVal.BCDP.Check_Date__c);
        if(PLVal.BCDP.Check_Date__c==date.valueOf('2017-08-01 00:00:00')){
            PLVal.BCDP.Check_Date__c = null;
        }
        recalcTotal();
    }
    public void recalcTotal(){
        
        bd.Total__c = 0.00;
        integer flag=0;
        for(CheckDepositeService.PaymentWrapper pw : payList.values()){
            flag++;
            if(pw.BCDP != null){
                if(pw.BCDP.Customer__c !=null && pw.BCDP.amount__c!=null){
                    bd.Total__c+=pw.BCDP.Amount__c;
                    CheckDepositeService.PaymentWrapper PLVal = payList.get(flag);
                    if(pw.BCDP.amount__c == 0){
                        PLVal.BCDP.Amount__c = null;
                    }
                    if(pw.BCDP.Check_Number__c == '0'){
                        PLVal.BCDP.Check_Number__c = null;
                    }
                    system.debug('check check :'+pw.BCDP.Check_Date__c);
                    if(pw.BCDP.Check_Date__c==date.valueOf('2017-08-01 00:00:00')){
                        PLVal.BCDP.Check_Date__c = null;
                    }
                }
            }
        }
        
    }
    
    public void setPastBankDepsoit(){
        if(selectedPastBD != null){
            bd = unPostedBDMap.get(selectedPastBD);
            payList.clear();
            cObjIndex = null;
            loadCheckDepositPayments();
            recalcTotal();
            canIPost=true;
        }else{
            bd = new Bank_Deposit__c(Total__c=0.00);
            payList.clear();
            Integer lastIndex = 0;
            for(Integer i=lastIndex;i<10;i++){
                Deposit_Batch_Check_Payment__c newObj=new Deposit_Batch_Check_Payment__c();
                payList.put(i,new CheckDepositeService.PaymentWrapper(i,newObj));
                lastIndex=i;
            }
            recalcTotal();
            canIPost=false;
            cObjIndex = null;
        }
        payListToDelete.clear();
    }
    public void getDetailOfBatchToMerge(){
        if(selectedPastBDForMerge != null){
            bdForMerge = unPostedBDMap.get(selectedPastBDForMerge);
            payListToMerge.clear();
            loadCheckDepositPaymentsForMerge();
        }else{
            payListToMerge.clear();
        }
    }
    
    public Integer loadCheckDepositPayments(){
        //Querying associated deposit batch check payment.
        List<Deposit_Batch_Check_Payment__c> dpcpList = (List<Deposit_Batch_Check_Payment__c>)Data.read(
            'SELECT Customer__r.Name,'+Utility.getFields('Deposit_Batch_Check_Payment__c')+' FROM Deposit_Batch_Check_Payment__c where Bank_Deposit__c =:ID order By Index__c ASC',
            new Map<String,Object> {
                'ID' => bd.Id
                    }
        );
        //system.debug('i am here with data ' + dpcpList);
        //Preparing wrapper
        for(Deposit_Batch_Check_Payment__c dpcp : dpcpList){
            CheckDepositeService.PaymentWrapper p = new CheckDepositeService.PaymentWrapper(Integer.valueOf(dpcp.Index__c),dpcp);
            p.BCDP = dpcp;            
            payList.put(Integer.valueOf(dpcp.Index__c),p);
            if(dpcp.Index__c>lastIndex){
                lastIndex = Integer.valueOf(dpcp.Index__c);
            }
        }
        return lastIndex;
    }
    public void loadCheckDepositPaymentsForMerge(){
        //Querying associated deposit batch check payment.
        List<Deposit_Batch_Check_Payment__c> dpcpList = (List<Deposit_Batch_Check_Payment__c>)Data.read(
            'SELECT Customer__r.Name,'+Utility.getFields('Deposit_Batch_Check_Payment__c')+' FROM Deposit_Batch_Check_Payment__c where Bank_Deposit__c =:ID order By Index__c ASC',
            new Map<String,Object> {
                'ID' => bdForMerge.Id
                    }
        );
        //Preparing wrapper
        for(Deposit_Batch_Check_Payment__c dpcp : dpcpList){
            CheckDepositeService.PaymentWrapperToMerge p = new CheckDepositeService.PaymentWrapperToMerge(Integer.valueOf(dpcp.Index__c),dpcp);
            p.BCDP = dpcp;            
            payListToMerge.put(Integer.valueOf(dpcp.Index__c),p);
        }
    }
    
    public void loadPastBankDeposits(){
        
        if(unPostedBDSO!=null){unPostedBDSO.clear();}else{unPostedBDSO=new List<SelectOption>();}
        if(unPostedBDSOForMerge!=null){unPostedBDSOForMerge.clear();}else{unPostedBDSOForMerge=new List<SelectOption>();}
        List<Bank_Deposit__c> bdLst = [Select id,name,Total__c,Financial_Account__c,Deposit_Date__c,Deposit_Slip_Number__c,createdBy.Name from Bank_Deposit__c where Posted__c = false];
        unPostedBDSo.add(new SelectOption('','New Deposit'));
        unPostedBDSOForMerge.add(new SelectOption('','Select Deposit'));
        for(Bank_Deposit__c pastBD : bdLst){
            unPostedBDSOForMerge.add(new SelectOption(pastBD.Id,pastBD.Deposit_Slip_Number__c));
            unPostedBDSO.add(new SelectOption(pastBD.Id,pastBD.Deposit_Slip_Number__c));
            unPostedBDMap.put(pastBD.Id,pastBD);
        }
    }
    public void delMember(){
        if(cObjIndex!=null){
            payListToDelete.add(payList.get(cObjIndex));
            payList.remove(cObjIndex);
        }
        recalcTotal();
    }
    public List<CheckDepositeService.PaymentWrapper> getPayListV(){
        return payList.values();
    }
    public List<CheckDepositeService.PaymentWrapperToMerge> getpayListToMergeV(){
        return payListToMerge.values();
    }
    public pagereference PostBatch(){
        try {
            if(selectedPastBD == null){
                ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Select batch to post.'));
                return null;
            }
            if(!serviceImpObj.saveCheckDepositPayments(bd,payListToDelete,selectedPastBD,payList)){
                return null;
            }
            if(!serviceImpObj.PostBatch(selectedPastBD,payList,bd.Financial_Account__c)){
                return null;
            }
        } catch(DMLException e) {
            return null;
        }
        
        PageReference pg;
        pg=page.CheckDepositHere;
        pg.getParameters().put('message','Batch Posted Successfully');
        pg.setRedirect(true);
        return pg;
    }
    public pagereference MergeBoth(){
        if(selectedPastBDForMerge == null || selectedPastBD == null){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Select batches to merge.'));
            return null;
        }
        if(!serviceImpObj.saveCheckDepositPayments(bd,payListToDelete,selectedPastBD,payList)){
            return null;
        }
        if(!serviceImpObj.MergeBoth(selectedPastBD,selectedPastBDForMerge,payListToMerge)){
            return null;
        }
        PageReference pg;
        pg=page.CheckDepositHere;
        pg.getParameters().put('message','Both Batches Merged Successfully');
        pg.setRedirect(true);
        return pg;
    }
    public pagereference saveCheckDepositPayments(){
        if(!serviceImpObj.saveCheckDepositPayments(bd,payListToDelete,selectedPastBD,payList)){
            return null;
        }
        
        //page reference
        PageReference pg;
        pg=page.CheckDepositHere;
        pg.getParameters().put('message','Saved Successfully');
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Saved Successfully'));
        pg.setRedirect(true);
        return pg;
    }
}