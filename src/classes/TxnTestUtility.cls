public class TxnTestUtility {

    //Create test household account
    static Integer i=0;
    static Integer jj=0;
    public static Contact createMember(Account p_account,String relationship)
    {       
        Contact testMember = new Contact();
        testMember.Type__c ='Babson';
        testMember.AccountId = p_account.Id;
        testMember.Relationship__c = relationship;
        testMember.Email='test'+String.valueOf(++i)+'@test.com';
        testMember.FirstName='test'+String.valueOf(++i);
        testMember.LastName='Member'+String.valueOf(++i);  
        data.create(testMember);
        //insert testMember;
        return testMember;
    }

     public static Contact createMember(Account p_account,String relationship,String recordtype)
    {       
        Contact testMember = new Contact();
        testMember.Type__c ='Babson';
        testMember.AccountId = p_account.Id;
        testMember.Relationship__c = relationship;
        testMember.Email='test'+String.valueOf(++i)+'@test.com';
        testMember.FirstName='test'+String.valueOf(++i);
        testMember.LastName='Member'+String.valueOf(++i);
        testMember.RecordTypeId=recordtype;  
        testMember.Membership_Type__c = Contact.Membership_Type__c.getDescribe().getPicklistValues()[0].getValue(); 
        testMember.Customer_Id__c = '87654';      
        //insert testMember;
        data.create(testMember);
        return testMember;
    }

    public static Contact createContact(String fname, String lname, string recordtypeName)
    {  
        Account acc=createAccount(Utility.searchRecordType('Vendor','Account'));     
        Contact vend = new Contact(FirstName=fname, LastName=lname, RecordTypeId=Utility.searchRecordType('Vendor','Contact'), Account=acc);
        //insert vend;
        data.create(vend);
        return vend;
    }
    
    public static Vendor_Invoice__c createInvoice(double Amount,String invoiceNumber,String Vendor)
    {       
        Vendor_Invoice__c testInvoice = new Vendor_Invoice__c();
        testInvoice.Amount__c=Amount;
        testInvoice.Invoice_Number__c='invoice'+String.valueOf(++i);
        testInvoice.Vendor__c=Vendor;
        testInvoice.Due_Date__c= Date.today();
        testInvoice.Invoice_Date__c = Date.today();
        testInvoice.Post_Date__c  = Date.today();
        //insert testInvoice;
        data.create(testInvoice);
        return testInvoice;
    }
    
    public static Vendor_Invoice_Line__c createInvoiceLines(double Amount,String invoiceId)
    {       
        Financial_Account__c account = createFinancialAccount('TestVendInvLine');
        Vendor_Invoice_Line__c testInvoiceLine = new Vendor_Invoice_Line__c();
        testInvoiceLine.Amount__c=Amount;
        testInvoiceLine.Vendor_Invoice__c=invoiceId;
        testInvoiceLine.Financial_Account__c=account.id;
        //insert testInvoiceLine;
        data.create(testInvoiceLine);
        return testInvoiceLine;
    }
    public static void requiredDefaultAccounts()
    {
        Financial_Account__c fa = TxnTestUtility.createFinancialAccount('teest');
        Default_Account__c da =TxnTestUtility.getDefaultMapping('Accounts Receivable',fa);
        da =TxnTestUtility.getDefaultMapping('Accounts Payable',fa);
        da = TxnTestUtility.getDefaultPaymentMapping('Cash',fa) ;
        da = TxnTestUtility.getDefaultPaymentMapping('Check',fa) ;
        da = TxnTestUtility.getDefaultPaymentMapping('Credit Card',fa) ;
        da = TxnTestUtility.getDefaultPaymentMapping('ACH',fa) ;
        da = TxnTestUtility.getDefaultRefundMapping('ACH',fa) ;
        da = TxnTestUtility.getDefaultRefundMapping('Cash',fa) ;
        da = TxnTestUtility.getDefaultRefundMapping('Check',fa) ;
        da = TxnTestUtility.getDefaultRefundMapping('Credit Card',fa) ;
    }
    public static Financial_Account__c createFinancialAccount(string name)
    {       
        jj++;
        Financial_Account__c account = new Financial_Account__c();
        account.Account_Number__c='test'+ string.valueOf(jj++) ;
        account.Category__c = 'Asset';
        account.Name=name+string.valueOf(jj++);
        account.Active__c = true;
        //insert account;
        data.create(account);
        return account;
    }
     public static Vendor_Invoice_Line__c updateInvoiceLines(string invoiceLineId,double Amount)
    {       
        Vendor_Invoice_Line__c testInvoiceLine = new Vendor_Invoice_Line__c();
        testInvoiceLine.id=invoiceLineId;
        testInvoiceLine.Amount__c=Amount;
        //update testInvoiceLine;
        data.modify(testInvoiceLine);
        return testInvoiceLine;
    }

    public static Account createAccount(String recordtype)
    {       
        Account testAccount= new Account();
        testAccount.RecordTypeId=recordtype;
        testAccount.Name='TestNew'+string.valueOf(jj++)+'HouseHold';
        testAccount.AccountNumber='TestHouse Hold Family';
        //insert testAccount;
        data.create(testAccount);
        return testAccount;                
    }
    
    // Create address to addressMapping
    public static Address__c getAddress(Contact member,String addressType)
    {
        Address__c address=new Address__c();
        address.Type__c=addressType;
        address.Name='address test';
        address.Customer__c=member.Id;
        address.From_Date__c=Date.Parse(01+'/'+01+'/'+2016);
        address.To_Date__c=Date.Parse(03+'/'+03+'/'+2016);
        //insert address;
        data.create(address);
        return address;
    }
    
    // Create guest address
    public static  Address__c getGuestAddress(Contact guest,String addressType)
    {
        Address__c address=new Address__c();
        address.Type__c=addressType;
        address.Name='address test';
        address.Customer__c=guest.Id;
        address.From_Date__c=Date.Parse(01+'/'+01+'/'+2016);
        address.To_Date__c=Date.Parse(03+'/'+03+'/'+2016);
        //insert address;
        data.create(address);
        return address;
    }

    public static boolean checkList(List<String>a,List<String>b)    
    {
        boolean flag=false;
        Integer c=0;
        for(Integer ii=0;ii<a.size();ii++){
            c=0;
            for(Integer j=0;j<b.size();j++){
                if(a[ii]==b[j]){
                c++;
                }
            }
            if(c==0){
                flag=true;
                return flag;
            }
        }
            return flag;
    }

    /**
    * @Description : method to create payment on passed vendor invoice and invoice line
    * @return : Vendor_Invoice_Payment__c record
    */
    public static Vendor_Invoice_Payment__c createPaymentOnPassedInvoice(Vendor_Invoice__c vendInv, Vendor_Invoice_Line__c vendInvLine)
    {
        Vendor_Invoice_Payment__c vendPay = new Vendor_Invoice_Payment__c(Vendor_Invoice__c=vendInv.id, Vendor_Invoice_Line__c=vendInvLine.id);
        Vendor_Invoice_Check__c venCheck = new Vendor_Invoice_Check__c(Amount__c=vendInv.Amount__c, Check_Date__c=Date.today(), Vendor__c=vendInv.Vendor__c);
        Vendor_Invoice_Check_Batch__c vendInvBatch = new Vendor_Invoice_Check_Batch__c(Batch_Date__c=Date.today());
        Data.create(vendInvBatch);
        venCheck.Vendor_Invoice_Check_Batch__c = vendInvBatch.id;
        Data.create(venCheck);
        vendPay.Vendor_Invoice_Check__c = venCheck.id;
        vendPay.Amount_Paid__c = vendInv.Amount__c;
        Data.create(vendPay);
        return vendPay;
    }

    /**
    * @Description : method to get default financial mappings
    * @param defaultTypeName name to set in the Default_Type_Name__c field
    * @param finAcc Financial Account record
    */    
    public static Default_Account__c getDefaultMapping(String defaultTypeName, Financial_Account__c finAcc){
        Default_Account__c txnFinMapp = new Default_Account__c(RecordTypeId=Utility.searchRecordType('Default','Default_Account__c'), Default_Type_Name__c=defaultTypeName, Financial_Account__c = finAcc.id);
        Data.create(txnFinMapp);
        return txnFinMapp;
    } 
    /**
    * @Description : method to get default financial mappings payment record type
    * @param defaultTypeName name to set in the payment_type__c field
    * @param finAcc Financial Account record
    */    
    public static Default_Account__c getDefaultPaymentMapping(String paymentType, Financial_Account__c finAcc){
        Default_Account__c txnFinMapp = new Default_Account__c(RecordTypeId=Utility.searchRecordType('Payments','Default_Account__c'), Payment_Type__c=paymentType, Financial_Account__c = finAcc.id);
        Data.create(txnFinMapp);
        return txnFinMapp;
    } 
    /**
    * @Description : method to get default financial mappings for refund recordtype
    * @param defaultTypeName name to set in the payment_type__c field
    * @param finAcc Financial Account record
    */    
    public static Default_Account__c getDefaultRefundMapping(String paymentType, Financial_Account__c finAcc){
        Default_Account__c txnFinMapp = new Default_Account__c(RecordTypeId=Utility.searchRecordType('Refund','Default_Account__c'), Payment_Type__c=paymentType, Financial_Account__c = finAcc.id);
        Data.create(txnFinMapp);
        return txnFinMapp;
    } 
    /**
    * @Description : method to create due in the system
    * @param due name - name of the due
    */ 
    public static Member_Dues__c getDue(String nameOfDue, String defaultBillingFreq)
    {

        Member_Dues__c billTable = new Member_Dues__c(Name = nameOfDue, 
                                                          Category__c = Member_Dues__c.Category__c.getDescribe().getPicklistValues().get(0).getValue(), 
                                                          Type__c = Member_Dues__c.Type__c.getDescribe().getPicklistValues().get(0).getValue(), 
                                                          Subtype__c = Member_Dues__c.Subtype__c.getDescribe().getPicklistValues().get(0).getValue(),
                                                          Financial_Account__c = createFinancialAccount('TxnTestUtility Fin Accounts').id,
                                                          Start_Date__c = Date.today(),
                                                          Default_Billing_Frequency__c = defaultBillingFreq,
                                                          Primary_Annual_Amount__c = 1000,
                                                          Spouse_Partner_Annual_Amount__c = 1000,
                                                          Dependent_Annual_Amount__c = 1000,
                                                          Statements_Description__c = 'statement description test'
                                                          );
        Data.create(billTable);
        return billTable;
    }

    /**
    * @Description : create tax mapping
    * @param : type name and subtype name
    */
    public static TxnChargeToTaxMapping__c getTaxMapping(String type, String subtype)
    {
        Taxes__c tax = new Taxes__c(Transit_Improvement_Sales_Tax__c=10.00, Sales_Tax__c=10.00);
        Data.create(tax);
        ServiceCharges__c scharge = new ServiceCharges__c(Banquet_Bar_Service_Charge__c=10.00);
        Data.create(scharge);
        TxnChargeToTaxMapping__c taxMappingRec = new TxnChargeToTaxMapping__c(Type__c=type, Subtype__c=subtype, TaxId__c='Transit_Improvement_Sales_Tax__c', Service_Charge_applicable__c=true, Service_Charge_Name__c='Banquet_Bar_Service_Charge__c', Tax_Name_applicable_on_service_charge__c='Transit_Improvement_Sales_Tax__c');
        Data.create(taxMappingRec);
        return taxMappingRec;
    }

    /**
    * @description : apply due on members
    * @param : due id and member id
    */
    public static Apply_due_on_members__c applyDueOnMembers(Member_Dues__c dueObj, Contact member)
    {
        Apply_due_on_members__c appDue = new Apply_due_on_members__c(Member_Dues__c=dueObj.id, Contact__c=member.id);
        Data.create(appDue);
        return appDue;
    }
    public static TXN__c txnCreatePay(Contact p_member)
    {
        TXN__c payment= new TXN__c();     
        payment.Bill_To_Member__c=p_member.Id;    
        payment.RecordTypeId=Utility.searchRecordType('Payment','TXN__c');
        //charge.GlobalSubType__c='test subType';
        //charge.GlobalType__c='test Type';
        payment.Amount__c=-100.00;
        payment.Payment_Type__c='Cash';
        payment.Statement_Description__c = 'test';
        //payment.amount_left_to_refund__c=100;
        Date currentDate = system.today();
        payment.Date__c=Date.newInstance(currentDate.year(),currentDate.month(),currentDate.day());
        //payment.amount_left_to_clear__c =100.00;   
        insert payment;
        return payment;
    }
    public static TXN__c createChargeOnMember(Contact member, Decimal amount)
     {
        TXN__c txnObj= new TXN__c();     
        txnObj.Bill_To_Member__c=member.Id;    
        txnObj.RecordTypeId=Utility.searchRecordType('Charge','TXN__c');
        Map<string, string> typesubtypeMap = getTypeAndSubtype();
        txnObj.GlobalSubType__c=typesubtypeMap.get('subtype');
        txnObj.GlobalType__c=typesubtypeMap.get('type');
        txnObj.Status__c='Unpaid';
        txnObj.Amount__c=amount.setScale(2);
        Date currentDate = system.today();
        txnObj.Date__c=Date.newInstance(currentDate.year(),currentDate.month(),currentDate.day());
        txnObj.Charge_Amount_Left__c=200.00;
        //txnObj.amount_left_to_adjust__c=200.00;
        insert txnObj;
        return txnObj;
    }
    public static TXN__c txnMapPaymentToCharge(TXN__c p_charge,TXN__C p_payment, decimal amount)
     {
        txn_payment_to_charge_mapping__c chargeMapper = new txn_payment_to_charge_mapping__c();
        chargeMapper.amount_paid__c = amount;
        chargeMapper.Charge_Id__c = p_charge.Id;
        chargeMapper.Payment_Id__c = p_payment.Id;
        chargeMapper.Method__c = 'Payment';
        insert chargeMapper;
        return null;
    }
    public static Map<string, string> getTypeAndSubtype(){
        
        Map<string, string> typesubtypeMap = new Map<string, string>();
        
        Schema.DescribeFieldResult fieldResult = TXN__c.GlobalType__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pick : picklistValues)
        {
            typesubtypeMap.put('type', pick.getValue());
            break;
        }
        
        Schema.DescribeFieldResult fieldResult1 = TXN__c.GlobalSubType__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues1 = fieldResult1.getPicklistValues();
        for(Schema.PicklistEntry pick : picklistValues1)
        {
            if(typesubtypeMap.get('subtype')!=null)
            if(typesubtypeMap.get('subtype').split(' ').size() > 1)
            typesubtypeMap.put('subtype', pick.getValue());
            else
            break;
        }
        
        return typesubtypeMap;
    }

    public static List<Tax_To_Account_Mapping__c> mapFinancialAccountOnPassedTaxes(TxnChargeToTaxMapping__c taxMappingsList)
    {
        List<Tax_To_Account_Mapping__c> taxToAccList = new List<Tax_To_Account_Mapping__c>();
        Set<String> taxesAndSCNames = new Set<String>();
        Financial_Account__c finAcc = createFinancialAccount('TxnTestUtility Test');
        if(taxMappingsList.TaxId__c!=null)
        {
            Tax_To_Account_Mapping__c taxAcc = new Tax_To_Account_Mapping__c();
            taxAcc.Financial_Accounts__c = finAcc.id;
            taxAcc.Tax__c = Utility.getNameOfTax(taxMappingsList.TaxId__c);
            taxToAccList.add(taxAcc);
        }
        if(taxMappingsList.Service_Charge_Name__c!=null)
        {
            Tax_To_Account_Mapping__c taxAcc = new Tax_To_Account_Mapping__c();
            taxAcc.Financial_Accounts__c = finAcc.id;
            taxAcc.Service_Charge__c = Utility.getNameOfServiceCharge(taxMappingsList.Service_Charge_Name__c);
            taxToAccList.add(taxAcc);
        }
        Data.create(taxToAccList);
        return taxToAccList;
    }
 
    public static List<Dues_Summary__c> getDueSummAndRelatedDues(Member_Dues__c memDues, Contact member)
    {
        List<Dues_Summary__c> dueSummList = new List<Dues_Summary__c>();
        Dues_Summary__c dueSumm = new Dues_Summary__c(Member_Dues__c=memDues.id, Billing_Period__c='April', Post_Date__c=Date.today(), RecordTypeId=Utility.searchRecordType('Due Summary','Dues_Summary__c'));
        Data.create(dueSumm);
        dueSummList.add(dueSumm);
        Dues_Summary__c dues = new Dues_Summary__c(RecordTypeId=Utility.searchRecordType('Dues', 'Dues_Summary__c') ,Due_Summary__c=dueSumm.id, Amount__c=1000, Tax_Amount__c=100, Billing_Period__c=dueSumm.Billing_Period__c, Contact__c=member.id);
        Data.create(dues);
        dueSummList.add(dues);
        Dues_Summary__c taxes = new Dues_Summary__c(RecordTypeId=Utility.searchRecordType('Taxes','Dues_Summary__c'), Due_Summary__c=dues.id, Amount__c=100, Tax_Name__c=Utility.getNameOfTax(new List<String>(Taxes__c.sObjectType.getDescribe().fields.getMap().keySet())[0]));
        Data.create(taxes);
        dueSummList.add(taxes);
        return dueSummList;
    }

    public static List<TXN__c> getManualDuesWithTaxes(Member_Dues__c memDues, Contact member)
    {
        List<TXN__c> duesTxnsList = new List<TXN__c>();
        TXN__c dueRec = new TXN__c(RecordTypeId=Utility.searchRecordType('Dues','TXN__c'), Member_Dues__c=memDues.id, Date__c=Date.today(), Amount__c=150, Statement_Description__c='Testing dues adjustment', Bill_To_Member__c=member.id);
        Data.create(dueRec);
        duesTxnsList.add(dueRec);
        TXN__c taxes = new TXN__c(Related_To__C=dueRec.id, RecordTypeId=Utility.searchRecordType('Taxes','TXN__c'), Bill_To_Member__c=member.id, Amount__c=10, Tax_Name__c=Utility.getNameOfTax(new List<String>(Taxes__c.sObjectType.getDescribe().fields.getMap().keySet())[0]));
        Data.create(taxes);
        duesTxnsList.add(taxes);
        return duesTxnsList;
    }

    public static TXN__C getRefundFromPayment(TXN__C payment)
    {
        TXN__C refund = new TXN__C(RecordTypeId=Utility.searchRecordType('Refund','TXN__C'), Related_To__C=payment.id);
        refund.Amount__c = -payment.Amount__c;
        refund.Bill_To_Member__c = payment.Bill_To_Member__c;
        refund.Date__c = payment.Date__c;
        refund.Payment_Type__c = payment.Payment_Type__c;
        Data.create(refund);
        return refund;
    }

    public static List<TXN__c> getAdjustmentRecordsOnDues(TXN__C txnDue)
    {
        List<TXN__c> adjustTxnsList = new List<TXN__c>();
        TXN__C adjust = new TXN__C(RecordTypeId=Utility.searchRecordType('Adjustment','TXN__C'), Related_To__C=txnDue.id);
        adjust.Amount__c = -txnDue.Amount__c/2;
        adjust.Bill_To_Member__c = txnDue.Bill_To_Member__c;
        adjust.Date__c = txnDue.Date__c;
        adjustTxnsList.add(adjust);
        TXN__C adjust1 = new TXN__C(RecordTypeId=Utility.searchRecordType('Adjustment','TXN__C'), Related_To__C=txnDue.id);
        adjust1.Amount__c = -txnDue.Amount__c/2;
        adjust1.Date__c = txnDue.Date__c;
        adjust1.Bill_To_Member__c = txnDue.Bill_To_Member__c;
        adjustTxnsList.add(adjust1);
        Data.create(adjustTxnsList);
        return adjustTxnsList;
    }

    public static TXN__C getEventCharges(Contact member)
    {
        Event__c reservation = new Event__c(RecordTypeId=Utility.searchRecordType('Reserved','Event__c'), Contract_Due_Date__c=Date.today(), Name='test utility'+i);
        reservation.Sponsoring_Customer__c = member.id;
        reservation.SponsoringMember__c = member.id;
        reservation.Status__c = 'Tentative';
        Location__c loc = new Location__c(Maximum_Capacity__c=30, Name='Utility Test'+i);
        Data.create(loc);
        reservation.Location__c = loc.id;
        reservation.StartTime__c = Datetime.now().addHours(-3);
        reservation.EndTime__c = Datetime.now();
        Data.create(reservation);
        TXN__c charge = createChargeOnMember(member, 200);
        charge.Reservation__c = reservation.id;
        Data.modify(charge);
        return charge;
    }

    public static Statements__c getStatementSummary(Contact member){
        Date todaysDate = Date.today();
        Statements__c stmtSumm = new Statements__c(RecordTypeId=Utility.searchRecordType('Statement Summary','Statements__c'), Date__c=Date.newInstance(todaysDate.year(), todaysDate.month()-1, 1));
        Data.create(stmtSumm);
        Statements__c memStmt = new Statements__c(RecordTypeId=Utility.searchRecordType('Member Statement','Statements__c'), Statement__c=stmtSumm.id, Member__C=member.id);
        memStmt.Statement_Balance__c = 200;
        Data.create(memStmt);
        Statements__c stmtLine = new Statements__c(RecordTypeId=Utility.searchRecordType('Statement Line', 'Statements__c'), Amount__c=200, Statement__c=memStmt.id);
        stmtLine.Bill_To_Member__c = member.id;
        stmtLine.Customer__c = member.id;
        Data.create(stmtLine);
        return stmtSumm;
    }

    public static Credit_Book__c getCredits(Contact member){
        Financial_Account__c finAcc = createFinancialAccount('CreditCreAccount');
        Credit_Book__c credit = new Credit_Book__c(Member_ID__c=member.id);
        credit.CreditBookType__c = Credit_Book__c.CreditBookType__c.getDescribe().getPicklistValues()[0].getValue();
        credit.Credit_Amount__c = 200;
        credit.Credit_Financial_Account__c = finAcc.id;
        credit.Debit_Financial_Account__c = finAcc.id;
        Data.create(credit);
        return credit;
    }
}