public with sharing class TxnCreateChargeController
{
    public Payment_Method__c pm{get;set;}
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
    public Decimal serviceChargePercent{get;set;}
    public double serviceChargeAmount{get;set;}
    public Boolean isServiceChargeEnabled{get;set;}
    public Boolean tax_applied_on_Service_charge{get;set;}
    public String taxes_on_service_charge{get;set;}

    public Date todayDate{get;set;}
    public Boolean EditPg{get;set;}
    public Boolean EditPg1{get;set;}
    public Map<String, Decimal> taxMap{get;set;}
    public Map<String,Decimal> taxMapWithId{get;set;}
    public String memberId{get;set;}
    public TXN__c othCharge{get;set;}
    public String ChargeType{get;set;}
    public String ChargeSubType{get;set;}
    public String Charge_Amount{get;set;}

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
    public String memGuest{get;set;}
    public String exemptNumber{get;set;}

    private List<Charge_Item__c> chargeItems {get;set;}
    public List<SelectOption> chargeItemOptions {get;set;}
    public String selectedChargeItem{get;set;}
    public String itemCode{get;set;}

    public double Adjt_amt_detail{get;set;}

    public TxnCreateChargeController()
    {
        ChargeId=Apexpages.currentPage().getParameters().get('ChargeId');

        transactionId='none';

        todayDate=date.Today();
        DetailPage=false;
        EditPg=true;
        EditPg1=false;
        isTaxEnabled=false;
        isServiceChargeEnabled=false;
        othCharge=new TXN__c();
        Sub_Total = 0;

        othCharge.Date__c=todayDate;
        othCharge.Quantity__c=1;
        othCharge.GlobalType__c = '--None--';
        othCharge.GlobalSubType__c = '--None--';
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
        else if(TypeofContact=='guest')
        {
            breadCrumb='Guest Page';
            isGuest=true;
            isMember=false;
            displaylookup=true;
        }

        if(ChargeId!='' && ChargeId!=null)
        {
            DetailPage=true;
            EditPg=false;
            EditPg1=true;

            List<TXN__c> chargeDetailsList = (List<TXN__c>)Data.read(
                'SELECT ID,Name,Bill_To_Member__c,Customer__c,Tax__c,Date__c,RecordTypeId, Quantity__c, GlobalSubType__c,GlobalType__c, '+
                'Description__c,Total_Amount__c,Status__c,service_charge__c,Amount__c,Charge_Amount_Left__c FROM TXN__c WHERE Id=:ChargeId',
                new Map<String, Object> {
                    'ChargeId' => ChargeId
                }
            );

            String guestIdIfAny;

            TXN__C chargeDetails = null;
            if(chargeDetailsList.size()>0)
            {
                chargeDetails=chargeDetailsList.get(0);

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

            if(TypeofContact=='guest' && guestIdIfAny!=null)
            {
                List<Contact> mems = (List<Contact>)Data.read(
                    'SELECT id, Sponsor_1_Name__c FROM Contact WHERE id=:guestIdIfAny',
                    new Map<String, Object> {
                        'guestIdIfAny' => guestIdIfAny
                    }
                );

                refmem = mems.get(0);
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

            othCharge.GlobalType__c=String.valueOf(chargeDetails.GlobalType__c);
            othCharge.Charge_Amount_Left__c = chargeDetails.Charge_Amount_Left__c;

            othCharge.Date__c=date.valueOf(chargeDetails.Date__c);
            ChargeType=String.valueOf(chargeDetails.GlobalType__c);
            othCharge.GlobalSubType__c=String.valueOf(chargeDetails.GlobalSubType__c);
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
        else
        {
            memberId=Apexpages.currentPage().getParameters().get('memberId');
            memName=Apexpages.currentPage().getParameters().get('memberName');
            if(TypeofContact=='member')
            {
                List<Contact> ContDetail = (List<Contact>)Data.read(
                    'SELECT Tax_Exempt__c,Tax_Exempt_Number__c FROM Contact WHERE Id=:memberId',
                    new Map<String, Object> {
                        'memberId' => memberId
                    }
                );

                if(ContDetail.size()>0)
                {
                    Tax_exempt=Boolean.valueOf(ContDetail.get(0).Tax_Exempt__c);
                    exemptNumber=String.valueOf(ContDetail.get(0).Tax_Exempt_Number__c);
                    tax_exempt_number=String.valueOf(ContDetail.get(0).Tax_Exempt_Number__c);
                }
            }

            if(TypeofContact=='guest')
            {
                List<Contact> mems = (List<Contact>)Data.read(
                    'SELECT id, Sponsor_1_Name__c FROM Contact WHERE id=:memberId',
                    new Map<String, Object> {
                        'memberId' => memberId
                    }
                );

                refmem=mems.get(0);
            }

            memGuest=memberId;
        }

        String fromPage=Apexpages.currentPage().getParameters().get('from');
        if(fromPage=='payment' && ChargeId!=null)
        {
            FromLink='/'+memberId;
            currentPage='Charge Detail';
        }
        else if(fromPage=='payment' && TypeofContact=='guest')
        {
            FromLink='/'+memberId;
            currentPage='Charge Detail';
        }
        else if(fromPage=='MemberPage' && TypeofContact=='member')
        {
            FromLink='/'+memberId;
            if(ChargeId != '' && ChargeId != null)
                currentPage='Charge Detail';
            else
                currentPage='New Charge';
        }
        else if((fromPage == 'MemberPage' || fromPage == null) && TypeofContact == 'guest')
        {
            FromLink='/'+memberId;
            if(ChargeId!=''&&ChargeId!=null)
                currentPage='Charge Detail';
            else
                currentPage='New Charge';
        }

        retrieveChargeItems();
    }

    public List<tableRow> allpayment
    {
        get{
            List<tableRow> tableData=new  List<tableRow>();

            List<txn_payment_to_charge_mapping__c> mappings = (List<txn_payment_to_charge_mapping__c>)Data.read(
                    'SELECT amount_paid__c,Charge_Id__c,Payment_Id__c,Method__c,creditDate__c,Description__c FROM '+
                    'txn_payment_to_charge_mapping__c WHERE Charge_Id__c=:ChargeId',
                    new Map<String, Object> {
                        'ChargeId' => ChargeId
                    }
                );

            for(txn_payment_to_charge_mapping__c FromMapping : mappings)
            {
                String detailLink='/apex/TxnManualPayment?from=Charges&PaymentId='+(FromMapping.Payment_Id__c);
                if(FromMapping.Method__c == 'Payment' || FromMapping.Method__c ==' Manual Credit')
                {
                    Id idVal = FromMapping.Payment_Id__c;
                    List<TXN__c> transactions = (List<TXN__c>)Data.read(
                        'select Name,Date__c,Description__c,Amount__c,Payment_Type__c FROM TXN__c WHERE Id=:idVal',
                        new Map<String, Object> {
                            'idVal' => idVal
                        }
                    );

                    TXN__c trans=transactions.get(0);
                    tableData.add(new tableRow(trans.Name,trans.Date__c,trans.Description__c,Round2(Double.valueOf(FromMapping.amount_paid__c)),FromMapping.Method__c,detailLink,trans.Payment_Type__c));
                }
                else if(FromMapping.Method__c == 'Credit')
                {
                    detailLink='/apex/viewCreditRecord?memberId='+memberId+'&id='+FromMapping.id+'&creditId='+(FromMapping.Payment_Id__c);

                    Id idVal = FromMapping.Payment_Id__c;
                    List<Credit_Book__c> books = (List<Credit_Book__c>)Data.read(
                        'SELECT Name,Date__c,Description__c,Credit_Amount__c FROM Credit_Book__c WHERE ID=:idVal',
                        new Map<String, Object> {
                            'idVal' => idVal
                        }
                    );

                    Credit_Book__c book=books.get(0);
                    tableData.add(new tableRow(book.Name,book.Date__c,book.Description__c,Round2(double.valueOf(FromMapping.amount_paid__c)),FromMapping.Method__c,detailLink,'Credit'));
                }
                else
                {
                    detailLink='/apex/viewCreditRecord?memberId='+memberId+'&id='+FromMapping.id+'&creditId='+(FromMapping.Payment_Id__c);

                    Id idVal = FromMapping.Payment_Id__c;
                    List<Credit_Book__c> books = (List<Credit_Book__c>)Data.read(
                        'SELECT ID,Name FROM Credit_Book__c WHERE ID=:idVal',
                        new Map<String, Object> {
                            'idVal' => idVal
                        }
                    );

                    Credit_Book__c book=books.get(0);
                    tableData.add(new tableRow(book.Name,FromMapping.creditDate__c,FromMapping.Description__c,FromMapping.amount_paid__c,'Credit Book',detailLink,'Club Credit'));
                }
            }
            return tableData;
        }
        private set;
    }

    public List<aTableRow> allCharges
    {
        get{
            return new  List<aTableRow>();
        }
        private set;
    }

    public List<aTableAdjustment> allAdjustments
    {
        get{
            List<aTableAdjustment> tableData=new  List<aTableAdjustment>();

            List<TXN__c> transactions = (List<TXN__c>)Data.read(
                    'SELECT Amount__c,Date__c,Adjustment_Reason__c FROM TXN__c WHERE Related_To__c=:ChargeId',
                    new Map<String, Object> {
                        'ChargeId' => ChargeId
                    }
                );

            for(TXN__c trans : transactions)
            {
                tableData.add(new aTableAdjustment(trans.Adjustment_Reason__c,String.valueOf(Round2(double.valueOf(trans.Amount__c * -1))),String.valueOf(trans.Date__c)));
            }
            return tableData;
        }
        private set;
    }

    //get taxes and service charges from selected subtype
    public PageReference Get_other_data_based_on_Subtype()
    {
        Boolean foundMapping = false;
        taxMap = new Map<String,Decimal>();
        taxMapWithId = new Map<String,Decimal>();
        isServiceChargeEnabled = false;
        serviceChargeStatusText = '$0.00';
        serviceChargeName = '';
        serviceChargePercent = 0;
        Charge_Amount = getChargeFromChargeItem();
        Sub_Total = Double.valueOf(Charge_Amount);
        tax_applied_on_Service_charge = false;
        taxes_on_service_charge = '';

        List<TxnChargeToTaxMapping__c> mappings = (List<TxnChargeToTaxMapping__c>)Data.read(
                'SELECT TaxId__c,tax_on_service_charge__c,Service_Charge_applicable__c,Taxes_applicable_on_service_charge__c,Service_Charge_Name__c FROM '+
                'TxnChargeToTaxMapping__c WHERE Type__c=:ChargeType AND SubType__c=:ChargeSubType',
                new Map<String, Object> {
                    'ChargeType' => ChargeType,
                    'ChargeSubType' => ChargeSubType
                }
            );

        for(TxnChargeToTaxMapping__c mapping : mappings)
        {
            if(mapping.TaxId__c!=null)
            {
                foundMapping = true;
                String name = Utility.getNameOfTax(mapping.TaxId__c);
                Decimal value = Utility.getPercentageOfTax(mapping.TaxId__c);
                String taxId = mapping.TaxId__c;
                taxMap.put(name,value);
                taxMapWithId.put(mapping.TaxId__c,value);
                if(mapping.Service_Charge_applicable__c == true )
                {
                    serviceChargeAPIName = mapping.Service_Charge_Name__c;
                    serviceChargeName = Utility.getNameOfServiceCharge(mapping.Service_Charge_Name__c);
                    serviceChargePercent = Utility.getPercentageOfServiceCharge(mapping.Service_Charge_Name__c);
                    tax_applied_on_Service_charge = mapping.Service_Charge_applicable__c;
                    String taxName = Utility.getNameOfTax(mapping.TaxId__c);
                    if(mapping.Taxes_applicable_on_service_charge__c){
                        taxes_on_service_charge += ',' + taxName;
                    }
                        

                    isServiceChargeEnabled = true;

                    if(tax_applied_on_Service_charge == true){

                        serviceChargeStatusText = '(Taxable)';

                    }else{

                        serviceChargeStatusText = '$0.00';

                    }                        
                }
                else{

                    serviceChargePercent = 0.00;

                }                    
            }
        }

//if there is no tax on the subtype then check if taxes added for the type of this subtype
        if(!foundMapping)
        {
            mappings = (List<TxnChargeToTaxMapping__c>)Data.read(
                'SELECT TaxId__c,tax_on_service_charge__c,Service_Charge_applicable__c,Taxes_applicable_on_service_charge__c,Service_Charge_Name__c FROM '+
                'TxnChargeToTaxMapping__c WHERE Type__c=:ChargeType AND SubType__c=\'\'',
                new Map<String, Object> {
                    'ChargeType' => ChargeType
                }
            );

            for(TxnChargeToTaxMapping__c mapping : mappings)
            {
                if(mapping.TaxId__c!=null)
                {
                    isServiceChargeEnabled=false;
                    String name = Utility.getNameOfTax(mapping.TaxId__c);
                    Decimal value = Utility.getPercentageOfTax(mapping.TaxId__c);
                    String taxId = mapping.TaxId__c;
                    taxMap.put(name,value);
                    taxMapWithId.put(mapping.TaxId__c,value);
                    if(mapping.Service_Charge_applicable__c==true )
                    {
                        serviceChargeAPIName = mapping.Service_Charge_Name__c;
                        serviceChargeName = Utility.getNameOfServiceCharge(mapping.Service_Charge_Name__c);
                        serviceChargePercent = Utility.getPercentageOfServiceCharge(mapping.Service_Charge_Name__c);
                        tax_applied_on_Service_charge = mapping.Service_Charge_applicable__c;
                        String taxName2 = Utility.getNameOfTax(mapping.TaxId__c);
                        if(mapping.Taxes_applicable_on_service_charge__c == true){

                            taxes_on_service_charge += ',' + taxName2;

                        }
                        isServiceChargeEnabled = true;

                        if(tax_applied_on_Service_charge==true){

                            serviceChargeStatusText = '(Taxable)';

                        }else{
                            
                            serviceChargeStatusText = '$0.00';

                        }
                            
                    }
                    else{

                        serviceChargePercent = 0.00;

                    }                        
                }
            }
        }

        if(!taxMap.isEmpty())
        {
            isTaxEnabled=true;
        }
        else
        {
            isTaxEnabled=false;
        }
        return null;
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

    public void insert_data_to_payment_to_charges_object(Double amt, String chargeId, String paymentId)
    {
        txn_payment_to_charge_mapping__c payment_to_charge = new txn_payment_to_charge_mapping__c();
        payment_to_charge.amount_paid__c = amt;
        payment_to_charge.Charge_Id__c = chargeId;
        payment_to_charge.Payment_Id__c = paymentId;
        payment_to_charge.Method__c = 'Payment';
        Data.create(payment_to_charge);
    }

    public PageReference save()
    {
        Savepoint sp= Database.setSavepoint();
        List<Revenue_Split__c> SplitRecords= (List<Revenue_Split__c>)Data.read('SELECT Id,Charge_Item__c,Financial_Account__c,Split_Amount__c from Revenue_Split__c where Charge_Item__c=:chargeitemid',
                                                                                                  new Map<String,Object> {
                                                                                                      'chargeitemid'=>selectedChargeItem
                                                                                                  }
                                                                                                 );
        List<Charge_Item__c> chargeItemsList = (List<Charge_Item__c>)Data.read(
            'select Id, Name, Description__c, isActive__c, Default_A_R_Account__c, Financial_Account__c, Type__c, SubType__c,'+
            ' Item_Code__c,Price__c,Retail_Price__c from Charge_Item__c where id=:CHId',
            new Map<String, Object> {
                'CHId'=>selectedChargeItem
            }
        );
       
        txn = new TXN__c();

        if(othCharge.GlobalType__c == '' || othCharge.GlobalType__c == null)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Error No : TxnChargesError00002, Message: Type is Missing.'));
            return null;
        }
        else if(Charge_Amount == '' || Charge_Amount == null || double.valueOf(Charge_Amount) <= 0)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Error No : TxnChargesError00003, Message: Enter Positive Amount.'));
            return null;
        }
        if(chargeItemsList[0].Price__c != Double.valueOf(Charge_Amount) && SplitRecords.size()>0){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'The sum of your revenue splits do not equal the price of your charge item. Please update your split amounts in order to save.'));
            return null;
        }

        /*if(TypeofContact == 'guest')
        {
            if(paymentType == null || paymentType == '' )
            {
                ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR,'Error No : TxnPaymentError000012, Message: Select Payment Method'));
                return null;
            }
        }*/

        if(othCharge.Quantity__c <= 0)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Error : Quantity must be greater than 0.'));
            return null;
        }

        if(TypeofContact == 'member')
        {
            txn.Bill_To_Member__c = Utility.getBillToMember(new List<Id>{memberId}).get(memberId);
            txn.Customer__c = memberId;

        }else if(TypeofContact == 'guest')
        {
            reference=String.valueOf(refmem.Sponsor_1_Name__c);
            txn.Customer__c = memberId;
            txn.Bill_To_Member__c = Utility.getBillToMember(new List<Id>{txn.Customer__c}).get(txn.Customer__c);
            Data.modify(refmem);
        }

        txn.RecordTypeId=Utility.searchRecordType('Charge', 'TXN__c');
        txn.GlobalSubType__c=othCharge.GlobalSubType__c;
        txn.GlobalType__c=othCharge.GlobalType__c;
        txn.Item_Code__c = itemCode;
        txn.Internal_Notes__c = othCharge.Internal_Notes__c;
        txn.Statement_Description__c = othCharge.Statement_Description__c;
        txn.Quantity__c = othCharge.Quantity__c;
        txn.Employee__c = othCharge.Employee__c;
        txn.Is_Parent__c = true;
        
        String Txn_Id='';
        Double chargeAmountWithoutTax = Double.valueOf(Charge_Amount)*othCharge.Quantity__c;
        if(serviceChargePercent == null){

            serviceChargePercent = 0.00;

        }           

        Double sub_total=Double.valueOf(Charge_Amount)*othCharge.Quantity__c;
        Double SC_amt=(Double.valueOf(Charge_Amount)*othCharge.Quantity__c*Double.valueOf(serviceChargePercent))/100;
        Double amt=0;
        if(tax_applied_on_Service_charge==false)
            amt=Double.valueOf(Charge_Amount);
        else
            amt=Double.valueOf(Charge_Amount)+double.valueOf(SC_amt);

        Double main_tax_Amount=0;

        Charge_Amount = String.valueOf(ROUND2(Double.valueOf(Charge_Amount)));
        List<String> exempted=new List<String>();
        if(taxMap.size()>0)
        {
            for(String idKey : taxMap.keyset())
            {
                System.debug('**** idKey: '+idKey);
                Integer flag=0;
                Map<String,object> m=(Map<String,object>)JSON.deserializeUntyped(Apexpages.currentPage().getParameters().get('node'));
                List<object> pricing=(List<object>)m.get('data');
                if(pricing.size()>0)
                {
                    for(object o:pricing)
                    {
                        Map<String,object> p=(Map<String,object>)o;
                        exempted.add(String.valueOf(p.get('TaxName')));
                        if(String.valueOf(p.get('TaxName')) == idKey)
                            flag=1;
                    }
                }

                if(flag==0)
                {
                    Decimal Tax = taxMap.get(idKey);

                    Integer check =0;
                    List<TxnChargeToTaxMapping__c> applicableTaxes = (List<TxnChargeToTaxMapping__c>)Data.read(
                        'SELECT TaxId__c, SubType__c, Type__c, Tax_Name_applicable_on_service_charge__c,tax_on_service_charge__c, Service_Charge_applicable__c,'+
                        'Taxes_applicable_on_service_charge__c FROM TxnChargeToTaxMapping__c WHERE Type__c=:ChargeType AND SubType__c=:ChargeSubType',
                        new Map<String, Object> {
                            'ChargeType' => othCharge.GlobalType__c,
                            'ChargeSubType' => othCharge.GlobalSubType__c
                        }
                    );

                    for(TxnChargeToTaxMapping__c a :applicableTaxes)
                    {
                        String TaxName = Utility.getNameOfTax(String.valueOf(a.Tax_Name_applicable_on_service_charge__c));
            
                        if(idKey == TaxName )
                        {
                            check = 1;
                            break;
                        }

                    }

                    if(check == 1)
                    {
                        main_tax_Amount=main_tax_Amount+Round2((amt*double.valueOf(Tax))/100);
                        Charge_Amount=String.valueOf(Round2(double.valueOf(Charge_Amount))+Round2((amt*double.valueOf(Tax))/100));
                    }
                    else if(check!=1)
                    {
                        main_tax_Amount=main_tax_Amount+Round2((chargeAmountWithoutTax*Double.valueOf(Tax))/100);
                        Charge_Amount=String.valueOf(Round2(Double.valueOf(chargeAmountWithoutTax))+Round2((chargeAmountWithoutTax*Double.valueOf(Tax))/100));
                    }
                }
            }
        }
        else
        {
            Charge_Amount = String.valueOf(Round2(Double.valueOf(chargeAmountWithoutTax)) + Round2(main_tax_Amount));
        }
        if(!othCharge.Tax_Exempt__c) {
            txn.Tax__c=Round2(main_tax_Amount);
        }else {
            txn.Tax_Exempt__c = true;
        }
        txn.Description__c=charge_desc;
        txn.Status__c='Unpaid';
        txn.Amount__c=Round2(sub_total);
        txn.Date__c=othCharge.Date__c;
        txn.Credit_Financial_Account__c=chargeItemsList[0].Financial_Account__c;
        txn.Amount_Remaining__c=Round2(double.valueOf(Charge_Amount)); //+Round2(SC_amt));
        txn.service_charge__c=Round2(double.valueOf(SC_amt));
        txn.Charge_Item__c = selectedChargeItem;
        List<TXN__C> AllSpplitTxns = new List<TXN__C>();
        //check if charge item has split revenue records then split this charge 
        if(SplitRecords.size()>0){
            TXN__c masterRec = new TXN__c();
            integer flag =0;
            List<TXN__C> TxnCharges= new List<TXN__C>();
            for(Revenue_Split__c splits : SplitRecords){
                TXN__c newRec = new TXN__c();
                newRec=txn.clone();
                newRec.Amount__c = splits.Split_Amount__c * othCharge.Quantity__c;
                newRec.Charge_Amount_Left__c = splits.Split_Amount__c * othCharge.Quantity__c;
                newRec.Transaction_Split__c=true;
                newRec.Credit_Financial_Account__c = splits.Financial_Account__c;
                newRec.Amount_Remaining__c=splits.Split_Amount__c * othCharge.Quantity__c; //+Round2(SC_amt));
                if(flag==0){
                    masterRec = newRec;
                }else{
                    TxnCharges.add(newRec);
                }
                flag++;
            }
            Data.create(masterRec);
            List<TXN__c> ChildRecs= new List<TXN__c>();
            for(TXN__c childs: TxnCharges){
                childs.Related_To__c=masterRec.id;
                ChildRecs.add(childs);
            }
            AllSpplitTxns.add(masterRec);
            Data.create(ChildRecs);
             for(TXN__c childs: TxnCharges){
                 AllSpplitTxns.add(childs);
             }
        }else{
            Data.create(txn);
        }
        String latest_charge_id=txn.id;
        double Final_total=Round2(double.valueOf(Charge_Amount)); //+SC_amt);
        double guestFinal_total=Final_total;

        //check if customer has any extrapayment in his/her account so we can clear this charge as well
        Id recTypeCredId = Utility.searchRecordType('Credit', 'TXN__c');
        Id recTypePayId = Utility.searchRecordType('Payment', 'TXN__c');

        List<TXN__c> transactions = (List<TXN__c>)Data.read(
            ' SELECT Id,Amount_Remaining__c FROM TXN__c WHERE (RecordTypeId=:recTypePayId OR '+
            ' RecordTypeId=:recTypeCredId) AND (Bill_To_Member__c=:memberId OR Customer__c=:memberId) AND Amount_Remaining__c>0 '+
            ' ORDER BY DateTime__c ',
            new Map<String, Object> {
                'recTypePayId' => recTypePayId,
                'recTypeCredId' => recTypeCredId,
                'memberId' => memberId
            }
        );

        /*for(TXN__c GetRecord : transactions)
        {
            Double amount_let_to_clear=Double.valueOf(GetRecord.Amount_Remaining__c);
            if(amount_let_to_clear>=Final_total)
            {
                txn=new TXN__c();
                txn.Charge_Amount_Left__c=0;
                txn.Status__c='Fully Paid';
                txn.id=latest_charge_id;
                Data.modify(txn);
                GetRecord.Amount_Remaining__c=Round2(amount_let_to_clear-Final_total);
                insert_data_to_payment_to_charges_object(Final_total,latest_charge_id,GetRecord.Id);
                Data.modify(GetRecord);
            }
            else
            {
                txn=new TXN__c();
                txn.Charge_Amount_Left__c=Round2(Final_total-amount_let_to_clear);
                Final_total=Round2(Final_total-amount_let_to_clear);
                txn.Status__c='Partial';
                txn.id=latest_charge_id;
                Data.modify(txn);
                GetRecord.Amount_Remaining__c=0;
                insert_data_to_payment_to_charges_object(amount_let_to_clear,latest_charge_id,GetRecord.Id);
                Data.modify(GetRecord);
            }
        }*/
        Txn_Id = txn.Id;

        // create childreb txn_tax__c records for the taxes
        if(taxMapWithId.size()>0)
        {
            for(String idKey:taxMapWithId.keyset())
            {
                Decimal Tax = taxMapWithId.get(idKey);
                if(Tax == null)
                    Tax = 0;

                String TxName = Utility.getNameOfTax(idKey);
                integer flag = 0;
                for(String Txx : exempted)
                {
                    if(Txx == TxName)
                        flag = 1;
                }

                Integer check = 0;
                List<TxnChargeToTaxMapping__c> applicableTaxes = (List<TxnChargeToTaxMapping__c>)Data.read(
                        'SELECT TaxId__c, SubType__c, Type__c, Tax_Name_applicable_on_service_charge__c, tax_on_service_charge__c, Service_Charge_applicable__c, '+
                        'Taxes_applicable_on_service_charge__c FROM TxnChargeToTaxMapping__c WHERE Type__c=:ChargeType AND SubType__c=:ChargeSubType',
                        new Map<String, Object> {
                            'ChargeType' => ChargeType,
                            'ChargeSubType' => ChargeSubType
                        }
                    );

                for(TxnChargeToTaxMapping__c a : applicableTaxes)
                {
                    String TaxName = Utility.getNameOfTax(String.valueOf(a.Tax_Name_applicable_on_service_charge__c));

                    if(TxName == TaxName )
                    {
                        check = 1;
                        break;
                    }

                }
            }
        }

        txn = new TXN__c();
        othCharge.GlobalType__c='';
        othCharge.GlobalSubType__c='';
        charge_desc='';
        Charge_Amount='';
        isServiceChargeEnabled=false;
        isTaxEnabled=false;
        PageReference reRend;

        if(nickName == 'saveNew')
        {
            reRend=new PageReference('/apex/TxnCreateCharge?from=MemberPage&ContactType='+TypeofContact+'&memberId='+memberId+'&memberName='+memName);
            reRend.getParameters().put('message','Charged Successfully');
            reRend.setRedirect(true);
            return reRend;
        }
        else if(nickName=='save')
        {
            reRend=new PageReference('/'+memberId);
            reRend.setRedirect(true);
            return reRend;
        }
        else if(nickName=='makePayment'&&TypeofContact=='guest')
           reRend=new  PageReference('/apex/PersonOverride?id='+memberId+'&sfdc.override=1');

        return reRend;
    }

    private void retrieveChargeItems()
    {
        selectedChargeItem = null;
        chargeItems = (List<Charge_Item__c>)Data.read(
            'select Id, Name, Description__c, isActive__c, Default_A_R_Account__c, Financial_Account__c, Type__c, SubType__c,'+
            ' Item_Code__c,Price__c,Retail_Price__c from Charge_Item__c where isActive__c=true ORDER BY Name',
            new Map<String, Object> {

            }
        );

        chargeItemOptions = new List<SelectOption>();
        chargeItemOptions.add(new SelectOption('','Select Charge Item'));
        for(Charge_Item__c ci : chargeItems)
        {
            chargeItemOptions.add(new SelectOption(ci.Id,ci.Name));
        }
    }

    public PageReference selectChargeItem()
    {
        for(Charge_Item__c ci : chargeItems)
        {
            if(ci.Id == selectedChargeItem)
            {
                charge_desc = ci.Description__c;
                othCharge.GlobalType__c = ci.Type__c;
                ChargeType = ci.Type__c;
                othCharge.GlobalSubType__c  = ci.SubType__c;
                ChargeSubType = ci.SubType__c;

                itemCode = ci.Item_Code__c;
                Get_other_data_based_on_Subtype();
                break;
            }
        }

        return null;
    }

    private String getChargeFromChargeItem()
    {
        String charge = '0';
        for(Charge_Item__c ci : chargeItems)
        {
            if(selectedChargeItem != null && ci.Id == selectedChargeItem)
            {
                if(isMember)
                {
                    if(ci.Price__c != null)
                        charge = String.valueOf(ci.Price__c);
                }
                else
                {
                    if(ci.Retail_Price__c != null)
                        charge = String.valueOf(ci.Retail_Price__c);
                }
            }
        }

        return charge;
    }

    public class tableRow
    {
        public String Name{get;set;}
        public Date chargeDate{get;set;}
        public String details{get;set;}
        public decimal amt{get;set;}
        public String paidBy{get;set;}
        public String detailLink{get;set;}
        public String paymentType{get;set;}

        public tableRow(String p_name,Date p_chargeDate,String p_details,decimal p_amt,String p_paidBy,String p_detailLink,String p_paymentType)
        {
            Name=p_name;
            chargeDate=p_chargeDate;
            details=p_details;
            amt=p_amt;
            paidBy=p_paidBy;
            paymentType=p_paymentType;
            detailLink=p_detailLink;
        }
    }

    public class aTableRow
    {
        public String TaxName{get;set;}
        public String Per{get;set;}
        public String Amount{get;set;}
        public Boolean Exumption{get;set;}
        public aTableRow(String txnTaxName,String txnAmt,String txnPer,Boolean exmp)
        {
            TaxName=txnTaxName;
            Amount=txnAmt;
            Per=txnPer;
            Exumption=exmp;
        }
    }

    public class aTableAdjustment
    {
        public String Amount{get;set;}
        public String Dt{get;set;}
        public String Reason{get;set;}
        public aTableAdjustment(String txnReason,String txnAmt,String txnDt)
        {
            Reason=txnReason;
            Amount=txnAmt;
            Dt=txnDt;

        }
    }
}