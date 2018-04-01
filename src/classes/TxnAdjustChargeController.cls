public with sharing class TxnAdjustChargeController
{
    public String transactionId{get;set;}
    public String paymentType{get;set;}
    public Boolean isGuest{get;set;}
    public Boolean isMember{get;set;}
    public String breadCrumb{get;set;}
    public String nickName{get;set{nickName=value;}}
    public Boolean isTaxEnabled{get;set;}
    public Boolean DetailPage{get;set;}

    public String serviceChargeStatusText{get;set;}
    public String serviceChargeName{get;set;}
    private String serviceChargeAPIName{get;set;}
    public String serviceChargePercent{get;set;}
    public double serviceChargeAmount{get;set;}
    public Boolean isServiceChargeEnabled{get;set;}
    public Boolean tax_applied_on_Service_charge{get;set;}
    public String taxes_on_service_charge{get;set;}

    public Date todayDate{get;set;}
    public Boolean EditPg{get;set;}
    public Boolean EditPg1{get;set;}
    public Map<String,String> taxMap{get;set;}
    public Map<String,String> taxMapWithId{get;set;}
    public String memberId{get;set;}
    public TXN__c othCharge{get;set;}
    public List<TXN__c> othChargeRelatedTaxes{get;set;}
    public List<taxesWrapper> othChargeRelatedTaxesWrapper{get;set;}
    public String ChargeType{get;set;}
    public String ChargeSubType{get;set;}
    public String Charge_Amount{get;set;}
    public TXN__c adjustmentCharge{get;set;}
    public String adj_Amount{get;set;}

    public String charge_desc{get;set;}
    public String StatusOfStatus{get;set;}
    public String memName{get;set;}
    public String Final_Total{get;set;}

    public String ChargeId{get;set;}
    public String TxnIdForDetail{get;set;}
    public String FromLink{get;set;}
    public String currentPage{get;set;}
    public double Sub_Total{get;set;}
    public double Total{get;set;}
    public Boolean Tax_exempt{get;set;}
    public String tax_exempt_number{get;set;}
    public String TypeofContact{get;set;}
    public Contact refmem{get;set;}
    public String reference{get;set;}
    public Boolean displaylookup{get;set;}
    public String totalAdjustments{get;set;}
    public String itemCode{get;set;}

    public double Adjt_amt_detail{get;set;}

    public TxnAdjustChargeController()
    {
        ChargeId=Apexpages.currentPage().getParameters().get('ChargeId');
        adj_amount = '0.00';
		totalAdjustments = '0.00';
        transactionId='none';

        todayDate=date.Today();
        DetailPage=false;
        EditPg=true;
        EditPg1=false;
        isTaxEnabled=false;
        isServiceChargeEnabled=false;
        othCharge=new TXN__c();
        adjustmentCharge=new TXN__c();
        Sub_Total = 0;
        adjustmentCharge.Date__c = todayDate;
        Final_Total = '0.00';

        TypeofContact=Apexpages.currentPage().getParameters().get('ContactType');
        String message=''+ApexPages.CurrentPage().GetParameters().Get('message');

        if(message!='' && message!='null')
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.CONFIRM,message));
        isMember = false;
        if(TypeofContact=='member')
        {
            breadCrumb='Member Page';
            isGuest=false;
            isMember=true;
            displaylookup=false;
        }

        if(ChargeId!='' && ChargeId!=null)
        {
            DetailPage=true;
            EditPg=false;
            EditPg1=true;

            List<TXN__c> chargeDetailsList = (List<TXN__c>)Data.read(
                'SELECT ID,Name,Bill_To_Member__c,Customer__c,Tax__c,Date__c,RecordTypeId, Quantity__c, GlobalSubType__c,GlobalType__c, '+
                'Description__c,Total_Amount__c,Status__c,service_charge__c,Amount__c,Charge_Amount_Left__c, Statement_Description__c, Internal_Notes__c, Charge_Item__r.Name FROM TXN__c WHERE Id=:ChargeId',
                new Map<String, Object> {
                    'ChargeId' => ChargeId
                }
            );
            
            List<TXN__c> relatedTaxesList = (List<TXN__c>)Data.read(
            	'SELECT ID, Name, Bill_To_Member__c, Date__c, Amount__c, Service_Charge_Name__c, Tax_Name__c FROM TXN__c WHERE Related_To__c =:ChargeId AND (RecordType.Name =:taxes OR RecordType.Name =:servicecharge)',
                new Map<String, Object> {
                    'ChargeId' => ChargeId,
                     'taxes' => 'Taxes',
                    'servicecharge' => 'Service Charges'
                }
            );
            
            system.debug('*** charge details' + chargeDetailsList + ' related details' + relatedTaxesList);

            String guestIdIfAny;

            TXN__C chargeDetails = null;
            if(chargeDetailsList.size()>0)
            {
                chargeDetails=chargeDetailsList.get(0);
				othCharge = chargeDetailsList.get(0);
                if (relatedTaxesList.size()>0) {
                    othChargeRelatedTaxesWrapper = new List<taxesWrapper>();
                    for (TXN__c txn : relatedTaxesList) {
                        taxesWrapper tempWrap = new taxesWrapper();
                        tempWrap.txn = txn;
                        tempWrap.adjustment_amount = 0.00;
                        tempWrap.adjustment_quantity = 0;
                        othChargeRelatedTaxesWrapper.add(tempWrap);
                    }
                    othChargeRelatedTaxes = relatedTaxesList;
                }
              
                Id conId = String.valueOf(chargeDetails.Bill_To_Member__c);
                List<Contact> ContDetails = (List<Contact>)Data.read(
                    'SELECT ID,Name,Tax_Exempt__c,Tax_Exempt_Number__c FROM Contact WHERE Id=:conId',
                    new Map<String, Object> {
                        'conId' => conId
                    }
                );

                if(ContDetails.size()>0)
                {
                    Contact ContDetail=ContDetails.get(0);
                    memberId=String.valueOf(ContDetail.ID);
                    if(guestIdIfAny==null)
                        guestIdIfAny=String.valueOf(chargeDetailsList.get(0).Customer__c);
                    memName=String.valueOf(ContDetail.Name);
                    Tax_exempt=Boolean.valueOf(ContDetail.Tax_Exempt__c);
                    tax_exempt_number=String.valueOf(ContDetail.Tax_Exempt_Number__c);
                }
            }


            Adjt_amt_detail=0.00;

            List<TXN__c> adjustmentDetails = (List<TXN__c>)Data.read(
                    'SELECT ID,Adjustment_Reason__c,Amount__c FROM TXN__c WHERE Related_To__c=:ChargeId',
                    new Map<String, Object> {
                        'ChargeId' => ChargeId
                    }
                );

            for(TXN__c trans : adjustmentDetails)
            {
                Adjt_amt_detail += trans.Amount__c;
            }
            ChargeType=String.valueOf(chargeDetails.GlobalType__c);
            ChargeSubType=String.valueOf(chargeDetails.GlobalSubType__c);
            charge_desc=String.valueOf(chargeDetails.Description__c);
            Charge_Amount=String.valueOf(chargeDetails.Amount__c);
            StatusOfStatus=String.valueOf(chargeDetails.Status__c);
            if(chargeDetails.service_charge__c!=null)
            {
                serviceChargeAmount=double.valueOf(chargeDetails.service_charge__c);
            }
            else
            {
                serviceChargeAmount=0.00;
            }

            Sub_Total = Utility.Round2(double.valueOf(Charge_Amount)+double.valueOf(serviceChargeAmount));
            Total=double.valueOf(chargeDetails.Total_Amount__c);
            Final_Total=String.valueOf(chargeDetails.Total_Amount__c + Adjt_amt_detail);
            TxnIdForDetail=String.valueOf(chargeDetails.Id);
        }

        String fromPage=Apexpages.currentPage().getParameters().get('from');
        if((fromPage == 'MemberPage' || fromPage == null))
        {
            FromLink='/'+memberId;
            if(ChargeId!=''&&ChargeId!=null)
                currentPage='Charge Detail';
            else
                currentPage='New Charge';
        }

    }


    /*public List<aTableRow> allCharges
    {
        get{
            return new  List<aTableRow>();
        }
        private set;
    }*/

    public List<aTableAdjustment> allAdjustments
    {
        get{
            List<aTableAdjustment> tableData=new  List<aTableAdjustment>();

            List<TXN__c> transactions = (List<TXN__c>)Data.read(
                    'SELECT Id, Name, Amount__c,Date__c,Adjustment_Reason__c, Service_Charge_Name__c,Tax_Name__c, Charge_Item__r.Name FROM TXN__c WHERE Related_To__c=:ChargeId AND RecordType.Name =: adjustment',
                    new Map<String, Object> {
                        'ChargeId' => ChargeId,
                        'adjustment' => 'Adjustment'
                    }
                );

            for(TXN__c trans : transactions) 
            {
                String dateString = '';
                if (trans.Date__c != null) {
                   dateString = trans.Date__c.format();
                }
                if (trans.Charge_Item__r != null) tableData.add(new aTableAdjustment(trans.Name, trans.id,trans.Charge_Item__r.Name,String.valueOf(Round2(double.valueOf(trans.Amount__c * -1))),dateString));
            	else if (trans.Service_Charge_Name__c != '' && trans.Service_Charge_Name__c != null) tableData.add(new aTableAdjustment(trans.Name,trans.id,trans.Service_Charge_Name__c,String.valueOf(Round2(double.valueOf(trans.Amount__c * -1))),dateString));         
                else if (trans.Tax_Name__c != '' && trans.Tax_Name__c != null) tableData.add(new aTableAdjustment(trans.Name,trans.id,trans.Tax_Name__c,String.valueOf(Round2(double.valueOf(trans.Amount__c * -1))),dateString));
            }
            return tableData;
        }
        private set;
    }

    public TXN__c txn
    {
        get{
            if(txn==null)
                txn=new TXN__c();
            return txn;
        }
        set;
    }

    public double Round2(Double valuetoRound)
    {
        return Utility.Round2(valuetoRound);
    }

    public PageReference save()
    {
        Savepoint sp= Database.setSavepoint();
        txn = new TXN__c();

        if(Charge_Amount == '' || Charge_Amount == null || double.valueOf(Charge_Amount) <= 0)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Error No : TxnChargesError00003, Message: Enter Positive Amount.'));
            return null;
        } else if (adj_Amount == '' || adj_Amount == null || Decimal.valueOf(adj_Amount) > 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Error No : TxnChargesError00004, Message: Adjustment Amount must be negative.'));
            return null;
        }

       

        if(TypeofContact=='member')
        {
            txn.Bill_To_Member__c=memberId;
            txn.Customer__c=memberId;
        }

        txn.RecordTypeId=Utility.searchRecordType('Adjustment', 'TXN__c');
        txn.GlobalSubType__c=othCharge.GlobalSubType__c;
        txn.GlobalType__c=othCharge.GlobalType__c;
        txn.Item_Code__c = itemCode;
        txn.Internal_Notes__c = othCharge.Internal_Notes__c;
        txn.Statement_Description__c = othCharge.Statement_Description__c;
        txn.Quantity__c = adjustmentCharge.Quantity__c;
        txn.Related_To__c = ChargeId;

        String Txn_Id='';

        Charge_Amount = String.valueOf(ROUND2(Double.valueOf(Charge_Amount)));
        List<String> exempted=new List<String>();
       

        txn.Description__c=charge_desc;
        //txn.Status__c='Unpaid';
        txn.Amount__c=Decimal.valueOf(adj_Amount);
        txn.Date__c=adjustmentCharge.Date__c;
        txn.Charge_Item__c = othCharge.Charge_Item__c;
        txn.Customer__c = othCharge.Customer__c;
        txn.Adjustment_Reason__c = adjustmentCharge.Adjustment_Reason__c;
        txn.Is_Parent__c = true;
        
        List<TXN__c> insertTXNs = new List<TXN__c>();
        if (Math.abs(txn.Amount__c) > 0) insertTXNs.add(txn);
                
        for (taxesWrapper txnWrap : othChargeRelatedTaxesWrapper) {
            decimal unitPrice = txnWrap.txn.Amount__c / othCharge.Quantity__c ;
            //txnWrap.txn.Related_To__c = ChargeId;
            TXN__c newTXN = new TXN__c();
            newTXN.Related_To__c = ChargeId;
            newTxn.Bill_To_Member__c=memberId;
            newTXN.RecordTypeId = txn.RecordTypeId;
            //newTXN.Amount__c = -Math.abs(txnWrap.txn.Amount__c);
            system.debug('*** adj amount: ' + txnWrap.adjustment_quantity + ' unitPrice:' + unitPrice);
            newTXN.Amount__c = -Math.abs((txnWrap.adjustment_quantity * unitPrice));
            newTXN.Date__c = adjustmentCharge.Date__c;
            newTXN.Service_Charge_Name__c = txnWrap.txn.Service_Charge_Name__c;
            newTXN.Tax_Name__c = txnWrap.txn.Tax_Name__c;
            newTXN.Customer__c = txn.Customer__c;
            newTxn.Is_Parent__c = false;
            if (Math.abs(newTXN.Amount__c) > 0) insertTXNs.add(newTXN);
        }
        upsert(insertTXNs);

        String latest_charge_id=txn.id;
        double Final_total=Round2(double.valueOf(Charge_Amount)); //+SC_amt);
        double guestFinal_total=Final_total;

        Txn_Id=txn.Id;

        
        isServiceChargeEnabled=false;
        isTaxEnabled=false;
        PageReference reRend;

        if(nickName=='save')
        {
            reRend=new PageReference('/'+memberId);
            reRend.setRedirect(true);
            return reRend;
        }

        return reRend;
    }

    public class aTableAdjustment
    {
        public String Name {get;set;}
        public String ID {get;set;}
        public String Amount{get;set;}
        public String Dt{get;set;}
        public String Reason{get;set;}
        public aTableAdjustment(String recName, String recID, String txnReason,String txnAmt,String txnDt)
        {
            Name = recName;
            Id = recID;
            Reason=txnReason;
            Amount=txnAmt;
            Dt=txnDt;

        }
    }
    public class taxesWrapper {
        public TXN__c txn {get;set;}
        public double adjustment_amount {get;set;}
        public integer adjustment_quantity {get;set;}
    }
}