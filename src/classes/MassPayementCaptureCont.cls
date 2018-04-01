public class MassPayementCaptureCont {
    public MassPaymentCaptureService serviceImpObj;
    public Blob csvFileBody{get;set;}
    public Map<Integer,MassPaymentCaptureService.paymentWrapper> CreditCardList{get;set;}
    public integer lastIndex{get;set;}
    public Bank_Deposit__c bd{get;set;}
    public integer LastInsertedIndex{get;set;}
    public integer cObjIndex{get;set;}
    public string forwhat{get;set;}
    public boolean readSuccess{get;set;}
    public string paymentType{get;set;}
    public boolean ccPay{get;set;}
    public boolean achPay{get;set;}
    public String documentName {get;set;}
    public String[] contactDataLines {get;set;}
    String fieldValue;
    Contact conObj;
    Integer fieldNumber;
    Map < String, Integer > fieldNumberMap = new Map < String, Integer > ();
    public set<String> lstFieldNames{get;set;}
    String contactDataAsString;
    public MassPayementCaptureCont(){
        string message=''+ApexPages.CurrentPage().GetParameters().Get('message');
        if(message!=''&&message!='null'){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.CONFIRM,message));
        }
        bd=new Bank_Deposit__c();
        ccPay=true;
        achPay=false;
        //for csv
        documentName = '';
        readSuccess = FALSE;
        contactDataLines = new String[] {};
            lstFieldNames = new set<String>();
        //csv end
        
        serviceImpObj= new MassPaymentCaptureService();
        CreditCardList = new Map<Integer,MassPaymentCaptureService.paymentWrapper>();
        for(Integer i=1;i<=5;i++){
            TXN__c newObj=new TXN__c();
            newObj.Date__c=null;
            CreditCardList.put(i,new MassPaymentCaptureService.paymentWrapper(i, newObj,''));
            lastIndex=i;
        }
    }
    public void readFromFile(){
        
        try{
            contactDataAsString = csvFileBody.toString();	
        }
        catch(exception e){
            readSuccess = FALSE;
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR,'Please select valid file.');
            ApexPages.addMessage(errorMessage);
            return;
        }
        try{
            readCSVFile();
        }catch(exception e){
            readSuccess = FALSE;
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
            ApexPages.addMessage(errorMessage);
        }
        
    }
    public void readCSVFile() {
        List<Contact> CustomersList = (List<Contact>)Data.read(
            'SELECT Customer_Id__c, id  FROM Contact where Customer_Id__c!=null',
            new Map<String,Object> {
            }
        );
        
        contactDataLines = contactDataAsString.split('\n');
        string[] csvFieldNames = contactDataLines[0].split(',');
        for (Integer i = 0; i < csvFieldNames.size(); i++) {
            fieldNumberMap.put(csvFieldNames[i], i);
            system.debug('field name : ' + csvFieldNames[i].trim());
            lstFieldNames.add(csvFieldNames[i].trim());
        }
        if (lstFieldNames.contains('Member ID') && lstFieldNames.contains('Amount') 
            && lstFieldNames.contains('Date') && lstFieldNames.contains('Description') 
            && lstFieldNames.contains('Transaction ID') && lstFieldNames.contains('Authorization Code') 
            && ((lstFieldNames.contains('Cardholder Name') && lstFieldNames.contains('Card Type') 
                 && lstFieldNames.contains('Last 4 Digits')) || (lstFieldNames.contains('Name on Account')
                                                                 && lstFieldNames.contains('Bank Name')&& lstFieldNames.contains('Account # (Last 4 Digits)')
                                                                 && lstFieldNames.contains('Routing #') && lstFieldNames.contains('Account Type')))
           )
        {
        }else{
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'This file does not contains required fileds for payments. Please select correct file.'));
        }
        checkLastInsertedRow();
        integer val=1;
        integer inVal=1;
        for (Integer i = 1; i < contactDataLines.size(); i++) {
            conObj = new Contact();
            string[] csvRecordData = contactDataLines[i].split(',');
            TXN__c trans=new TXN__c();
            string customer='';
            
            for (String fieldName: csvFieldNames) {
                
                fieldNumber = fieldNumberMap.get(fieldName);
                fieldValue = csvRecordData[fieldNumber];
                if(fieldName.trim() == 'Member ID'){
                    customer = fieldValue;
                }
                if(fieldName.trim() == 'Amount'){   
                    trans.Amount__c = double.valueOf(fieldValue);
                }
                if(fieldName.trim() == 'Date'){
                    trans.Date__c = date.valueOf(fieldValue);
                    //trans.Date__c = date.valueOf('2017-10-10');
                }
                if(fieldName.trim() == 'Description'){
                    trans.Statement_Description__c = csvRecordData[fieldNumber];
                }
                if(fieldName.trim() == 'Cardholder Name'){
                    trans.Cardholder_Name__c = csvRecordData[fieldNumber];
                }
                if(fieldName.trim() == 'Card Type'){
                    trans.Card_Type__c = csvRecordData[fieldNumber];
                }
                if(fieldName.trim() == 'Last 4 Digits'){
                    trans.Card_Last_4_Digits__c = csvRecordData[fieldNumber];
                }
                if(fieldName.trim() == 'Name on Account'){
                    trans.Name_on_Account__c  = csvRecordData[fieldNumber];
                }
                if(fieldName.trim() == 'Bank Name'){
                    trans.Bank_Name__c   = csvRecordData[fieldNumber];
                }
                if(fieldName.trim() == 'Account # (Last 4 Digits)'){
                    trans.Account_Number_Last_4_Digits__c    = csvRecordData[fieldNumber];
                }
                if(fieldName.trim() == 'Routing #'){
                    trans.Routing_Number__c = csvRecordData[fieldNumber];
                }
                if(fieldName.trim() == 'Account Type'){
                    trans.Account_Type__c  = csvRecordData[fieldNumber];
                }   
                if(fieldName.trim() == 'Transaction ID'){
                    trans.External_Payment_Transaction_Code__c = csvRecordData[fieldNumber];
                }
                if(fieldName.trim() == 'Authorization Code'){
                    trans.External_Payment_Authorization_Code__c = csvRecordData[fieldNumber];
                }
            }   
            if(i == 1){
                bd.Deposit_Date__c=trans.Date__c;
            }
            boolean falg=false;
            string ContId='';
            for(Contact cont: CustomersList){
                if(cont.Customer_Id__c == customer){
                    falg=true;
                    ContId=cont.id;
                }
            }
            if(falg){
                trans.Customer__c= ContId;
                trans.Bill_To_Member__c= ContId;
            }else{
                trans.Customer__c= null;
                trans.Bill_To_Member__c= null;
            }
            String creditRecordTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId();
            
            
            trans.RecordTypeId=creditRecordTypeId;
            if(paymentType=='CreditCard'){
                trans.Payment_Type__c ='Credit Card';
            }else{
                trans.Payment_Type__c ='ACH';
            }
            CreditCardList.put(LastInsertedIndex,new MassPaymentCaptureService.paymentWrapper(LastInsertedIndex,trans,string.valueOf(trans.Amount__c)));
            LastInsertedIndex++;
        }
        if(CreditCardList.size() > 0){
            readSuccess = TRUE;
        }            
    }
    public List<SelectOption> getpaymentTypes() {
        List<SelectOption> paymentTypes = new List<SelectOption>();
        paymentTypes.add(new SelectOption('CreditCard','Credit Card'));
        paymentTypes.add(new SelectOption('ACH','ACH'));
        return paymentTypes;
    }
    
    public void delCC(){
        if(cObjIndex!=null){
            TXN__c newObj=new TXN__c();
            CreditCardList.put(cObjIndex,new MassPaymentCaptureService.paymentWrapper(cObjIndex, newObj,''));
        }
    }
    public void changePayType(){
        CreditCardList.clear();
        if(paymentType=='CreditCard'){
            ccPay=true;
            achPay=false;
        }else{
            ccPay=false;
            achPay=true;
        }
        for(Integer i=1;i<=5;i++){
            TXN__c newObj=new TXN__c();
            CreditCardList.put(i,new MassPaymentCaptureService.paymentWrapper(i, newObj,''));
            lastIndex=i;
        }
    }
    public void checkLastInsertedRow(){
        LastInsertedIndex=1;
        for(MassPaymentCaptureService.paymentWrapper pw : CreditCardList.values()){
            if(pw.txnObj.Customer__c!=null){
                LastInsertedIndex++;
            }
        }
    }
    public List<MassPaymentCaptureService.paymentWrapper> getCreditCardListV(){
        return CreditCardList.values();
    }
    public void addMoreRows(){
        CreditCardList = serviceImpObj.addMoreRows(lastIndex, CreditCardList);   
        lastIndex = lastIndex+5;
    }
    public pagereference save(){
        List<TXN__c> insertList=new List<TXN__c>();
        String creditRecordTypeId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId();
        double TotalAmt=0;
        if(bd.Deposit_Date__c == null ){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Please select deposit date.'));
            return null;
        }
        for(MassPaymentCaptureService.paymentWrapper pw : CreditCardList.values()){
            boolean cust=false;
            integer other=0;
            if(pw.txnObj.Customer__c!=null){
                
                if(pw.amount == null || pw.amount == '' || double.valueOf(pw.amount) == 0){
                    ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Amount should be more then 0'));
                    return null;
                }
                if(pw.txnObj.Date__c == null){
                    ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'You have to select payment date.'));
                    return null;
                }
                
                if(pw.txnObj.Statement_Description__c == null || pw.txnObj.Statement_Description__c == ''){
                    ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Statement description required for every payment.'));
                    return null;
                }
                if(paymentType=='CreditCard'){
                    if(pw.txnObj.Cardholder_Name__c == null || pw.txnObj.Cardholder_Name__c == ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Card holder\'s name required for every Credit card payment.'));
                        return null;
                    }
                    if(pw.txnObj.Card_Type__c == null || pw.txnObj.Card_Type__c == ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Card type required for every Credit card payment.'));
                        return null;
                    }
                    if(pw.txnObj.Card_Last_4_Digits__c == null){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Card\'s last 4 digits required for every Credit card payment.'));
                        return null;
                    }
                    pw.txnObj.Payment_Type__c ='Credit Card';
                }else{
                    if(pw.txnObj.Name_on_Account__c == null || pw.txnObj.Name_on_Account__c == ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Name on account is required for every ACH payment.'));
                        return null;
                    }
                    if(pw.txnObj.Account_Number_Last_4_Digits__c == null || pw.txnObj.Account_Number_Last_4_Digits__c == ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Account number\'s last 4 digits required for every ACH payment.'));
                        return null;
                    }
                    if(pw.txnObj.Routing_Number__c == null || pw.txnObj.Routing_Number__c == ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Routing is required for every ACH payment.'));
                        return null;
                    }
                    if(pw.txnObj.Account_Type__c == null || pw.txnObj.Account_Type__c == ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Account type is required for every ACH payment.'));
                        return null;
                    }
                    pw.txnObj.Payment_Type__c ='ACH';
                }
            }else{
                
                if(pw.amount != null && pw.amount != '' && double.valueOf(pw.amount) != 0){
                    ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'A member name is required for all payments. Please add a member name and save.'));
                    return null;
                }
                if(pw.txnObj.Statement_Description__c != null && pw.txnObj.Statement_Description__c != ''){
                    ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'A member name is required for all payments. Please add a member name and save.'));
                    return null;
                }
                if(paymentType=='CreditCard'){
                    if(pw.txnObj.Cardholder_Name__c != null && pw.txnObj.Cardholder_Name__c != ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'A member name is required for all payments. Please add a member name and save.'));
                        return null;
                    }
                    if(pw.txnObj.Card_Type__c != null && pw.txnObj.Card_Type__c != ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'A member name is required for all payments. Please add a member name and save.'));
                        return null;
                    }
                    if(pw.txnObj.Card_Last_4_Digits__c != null){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'A member name is required for all payments. Please add a member name and save.'));
                        return null;
                    }
                    pw.txnObj.Payment_Type__c ='Credit Card';
                }else{
                    if(pw.txnObj.Name_on_Account__c != null && pw.txnObj.Name_on_Account__c != ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'A member name is required for all payments. Please add a member name and save.'));
                        return null;
                    }
                    if(pw.txnObj.Account_Number_Last_4_Digits__c != null && pw.txnObj.Account_Number_Last_4_Digits__c != ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'A member name is required for all payments. Please add a member name and save.'));
                        return null;
                    }
                    if(pw.txnObj.Routing_Number__c != null && pw.txnObj.Routing_Number__c != ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'A member name is required for all payments. Please add a member name and save.'));
                        return null;
                    }
                    if(pw.txnObj.Account_Type__c != null && pw.txnObj.Account_Type__c != ''){
                        ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'A member name is required for all payments. Please add a member name and save.'));
                        return null;
                    }
                }
            }
            if(pw.txnObj.Customer__c!=null){
                pw.txnObj.Bill_To_Member__c =pw.txnObj.Customer__c;
                pw.txnObj.Amount__c=double.valueOf(pw.amount) * -1;
                pw.txnObj.RecordTypeId=creditRecordTypeId;
                TotalAmt=TotalAmt+double.valueOf(pw.amount);
                insertList.add(pw.txnObj);
            }
        }
        if(insertList.size() <=0){
            ApexPages.AddMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'Please enter at least one payment line to save.'));
            return null;
        }
        data.create(insertList);
        //create bank deposit record for creadit card and ACH payment whatever selected.
        Bank_Deposit__c bd1=new Bank_Deposit__c();
        bd1.Posted__c=true;
        bd1.Total__c=TotalAmt;
        bd1.Deposit_Date__c=bd.Deposit_Date__c;
        Data.create(bd1);
        List<Deposit_Batch_Check_Payment__c> batchPaymets=new List<Deposit_Batch_Check_Payment__c>();
        for(TXN__c txnRec : insertList)
        {
            Deposit_Batch_Check_Payment__c bp=new Deposit_Batch_Check_Payment__c();
            bp.Transaction__c=txnRec.id;
            bp.Amount__c=txnRec.Amount__c * -1;
            bp.Customer__c=txnRec.Customer__c;
            bp.Bank_Deposit__c=bd1.id;
            batchPaymets.add(bp);
        }
        Data.create(batchPaymets);
        
        PageReference pg;
        pg=page.MassPayementCapture;
        pg.getParameters().put('message','Saved Successfully');
        pg.setRedirect(true);
        return pg;
    }
}