/*
@Name            : VendorCheckRunController
@Author          : customersuccess@cloud62.com
@Date            : March 11 2014
@Description     : Controller for Vendor Check Run Page
*/
public with sharing class VendorCheckRunController {
    public VendorCheckRunService serviceImpObj;
    // The Start and End date that are used for filtering the invoices
    public Account cEndDate {get;set;}   // of type Vendor__c so binding in VF page works
    public Account cPurchaseCategory {get;set;}
    //public Boolean isFilter {get;set;} // Specifies if the checkBatchDate method is called via the filter fields or not
    public Boolean paidManually{get;set;}
    public Boolean checkPreview{get;set;}
    
    
    //Batch that ties all checks generated this run together
    public Vendor_Invoice_Check_Batch__c vicb{get;set;}
    public Boolean validCheckBatchDate{get;set;}
    
    //Closed Month Variables
    private Set<Date> closedFCMap{get;set;}
    public String closedMonthWarning{get;set;}
    
    //Selected Number of checks
    public Integer numOfSelChecks{get;set;}
    public Integer numOfSelHoldChecks{get;set;}
    
    //Holds all of our Invoice Wrapper <Index,Wrapper>
    public Map<Id,VendorCheckRunService.VendorInvoiceWrapper> viwMap{get;set;}
    public Map<Id,VendorCheckRunService.VendorInvoiceWrapper> viwHoldMap{get;set;}
    public Map<Id,List<Id>> viwVendorMap{get;set;}
    public Map<Id,List<Id>> viwHoldVendorMap{get;set;}
    
    public Boolean selectAll{get;set;}
    
    public Decimal grandTotal{get;set;}
    public Decimal grandHoldTotal{get;set;}
    public Decimal payingAmount{get;set;}
    public Decimal payingHoldAmount{get;set;}
    
    public Integer nextCheckNumber{get;set;}
    //public Integer checkDigits{get;set;}
    public Check_Run__c checkRun{get;set;}
    //Location for Check Run and Operating Checks Account - Defaults to Operating Check check box
    public Vendor_Invoice_Line__c locationSelection{get;set;}
    public Financial_Account__c operatingChecks{get;set;}
    
    
    public String selectAllOnHold{get;set;}
    //for selectvendor action function
    public String selectedVendor{get;set;}
    public String selectedInvoice{get;set;}
    
    //Check Print Page
    public Map<Id,List<Vendor_Invoice__c>> printedCheckVIMap{get;set;}
    public List<Vendor_Invoice_Check__c> printedCheckVCList{get;set;}
    public Map<Id,Map<Id,VendorCheckRunService.FinancialJournalLineWrapper>> printedCheckFJLMap{get;set;}
    public Map<Id,Decimal> printedCheckAmountSentMap{get;set;}
    public Map<Id,String> printedCheckAmountWordsMap{get;set;}
    public Map<Id,Integer> printedCheckNumberOfInvoicesMap{get;set;}
    public Map<Id,List<Vendor_Invoice_Payment__c>> vipPreviewMap{get;set;}
    public Map<Id,Vendor_Invoice_Check__c> vicPreviewMap{get;set;}
    public Map<Id,Account> venPreviewMap{get;set;}
    public check_PDF_Spacing__c  spacing{get;set;}
    //Constructor to initalize the page
    public VendorCheckRunController(ApexPages.StandardController stdController) {
        spacing = new check_PDF_Spacing__c ();
        if(check_PDF_Spacing__c.getall().values().size()>0){
            spacing = new check_PDF_Spacing__c ();
        	spacing = check_PDF_Spacing__c.getall().values();
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please set the values for check spacing in "check PDF spacing" custom setting first.'));
        }
        locationSelection = new Vendor_Invoice_Line__c();
        serviceImpObj =new VendorCheckRunService();
        checkRun = serviceImpObj.getNextCheckNumber();
        paidManually = false;
        vicb = new Vendor_Invoice_Check_Batch__c();
        vicb.Batch_Date__c = Date.Today();
        cPurchaseCategory  = new Account();
        //cStartDate = new Vendor__c(Cert_of_Liability_Expiration_Date__c = Date.today());
        cEndDate = new Account(Cert_of_Liability_Expiration_Date__c = Date.today());
        validCheckBatchDate = false;
        regenerateClosedMonths();
        numOfSelChecks = 0;
        checkPreview = false;
        
    }
    //Return a list of all of the invoices wrappers for pageblocktable
    public List<VendorCheckRunService.VendorInvoiceWrapper> getPostedInvoices(){
        List<VendorCheckRunService.VendorInvoiceWrapper> tempWrap= serviceImpObj.getPostedInvoices(viwMap);
        return tempWrap;
        
    }
    //Return a list of all of the invoices wrappers for pageblocktable with Hold Status
    public List<VendorCheckRunService.VendorInvoiceWrapper> getNotPostedInvoices(){
        List<VendorCheckRunService.VendorInvoiceWrapper> tempWrap= serviceImpObj.getNotPostedInvoices(viwHoldMap);
        return tempWrap; 
    }
    //Get list of posted invoices that don't have checks
    // if isFilterCall == true, was called from via the filter fields in VF page
    public void loadPostedInvoices(){
        serviceImpObj.loadPostedInvoices(cPurchaseCategory.Purchase_Category__c,cEndDate.Cert_of_Liability_Expiration_Date__c);
        viwMap = VendorCheckRunService.getViewMap();
        viwVendorMap = VendorCheckRunService.getviwVendorMap();
    }
    //Load all invoices to display on Page
    @RemoteAction
    public static List<VendorCheckRunService.VendorInvoiceWrapper> loadPostedInvoicesRA(Date dueDate,String purchaseCategory){
        Map<Id,VendorCheckRunService.VendorInvoiceWrapper> viwMap = new Map<Id,VendorCheckRunService.VendorInvoiceWrapper>();
        List<VendorCheckRunService.VendorInvoiceWrapper> tempWrap= VendorCheckRunService.loadPostedInvoicesRA(dueDate,purchaseCategory);
        viwMap = VendorCheckRunService.getViewMap();
        Map<Id,List<Id>> viwVendorMap = new Map<Id,List<Id>>();
        viwVendorMap = VendorCheckRunService.getviwVendorMap();
        return tempWrap; 
        
    }
    //Load invoices that are on hold and display them at the bottom of the page
    public void loadNotPostedInvoices(){
        serviceImpObj.loadNotPostedInvoices(cPurchaseCategory.Purchase_Category__c,cEndDate.Cert_of_Liability_Expiration_Date__c);
        viwHoldMap = VendorCheckRunService.getviwHoldMap();
        viwHoldVendorMap = VendorCheckRunService.getviwHoldVendorMap();
    }
    public void getOperatingChecksFA(){
        if(locationSelection.Payment_FInancial_Account__c!=null){
            operatingChecks = [Select id,Name,Account_Number__c from Financial_Account__c where id =:locationSelection.Payment_Financial_Account__c];
        }else{
            operatingChecks = null;
        }
    }
    public String errorLevel {get; set;}
    public String messageName {get; set;}
    public void showMessage() {
        List<VendorCheckRunService.remotingReturnResponse> rRRLst = (List<VendorCheckRunService.remotingReturnResponse>)JSON.deserialize(messageName.unescapeHtml4(),List<VendorCheckRunService.remotingReturnResponse>.class);
        for(VendorCheckRunService.remotingReturnResponse rrr : rrrLst){
            if(rrr.severityCode == 'WARNING') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, rrr.messageStr));
            }else if(rrr.severityCode == 'ERROR'){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, rrr.messageStr));
            }else if(rrr.severityCode == 'CONFIRM'){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, rrr.messageStr));
            }
        }
    }
    @RemoteAction
    public static List<check_PDF_Spacing__c> SpacingSetting(string fieldName,string top, string left){
        check_PDF_Spacing__c setting =new check_PDF_Spacing__c();
        List<check_PDF_Spacing__c> AllCSData = check_PDF_Spacing__c.getall().values();
        if(fieldName == 'CheckNumberDrag'){
        	setting.section1_check_number_left__c = double.valueOf(left);
            setting.section1_check_number_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'CheckDateDrag'){
        	setting.date_left__c = double.valueOf(left);
            setting.date_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'VendorNameDrag'){
        	setting.section1_vendor_name_left__c = double.valueOf(left);
            setting.section1_vendor_name_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'AmountInWordDrag'){
        	setting.amount_in_words_left__c = double.valueOf(left);
            setting.amount_in_words_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'AmountDrag'){
        	setting.section1_amount_left__c = double.valueOf(left);
            setting.section1_amount_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'Sec2VendorNameDrag'){
        	setting.section2_vendor_name_left__c = double.valueOf(left);
            setting.section2_vendor_name_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'Sec2CheckNumberDrag'){
        	setting.section2_check_number_left__c = double.valueOf(left);
            setting.section2_check_number_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'Sec2'){
        	setting.section2_left__c = double.valueOf(left);
            setting.section2_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'Sec3VendorNameDrag'){
        	setting.section3_vendor_name_left__c = double.valueOf(left);
            setting.section3_vendor_name_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'Sec3CheckNumberDrag'){
        	setting.section3_check_number_left__c = double.valueOf(left);
            setting.section3_check_number_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'Sec3'){
        	setting.section3_left__c = double.valueOf(left);
            setting.section3_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }else
        if(fieldName == 'vendorBillingAddressDrag'){
        	setting.vendor_billing_address_left__c = double.valueOf(left);
            setting.vendor_billing_address_top__c = double.valueOf(top);
            setting.Id=AllCSData[0].id;
        }
        data.modify(setting);
        return null; 
    }
    //Prepare the page to display a preview of the finished checks.
    @RemoteAction
    public static List<VendorCheckRunService.remotingReturnResponse> testPreviewCheckRA(List<VendorCheckRunService.remotingSaveRequest> checkList,Boolean doInsert,Id operatingChecks,Date batchDate,String batchDescription,Integer nextCheckNumber,Boolean paidManually){
        List<VendorCheckRunService.remotingReturnResponse> tempWrap= VendorCheckRunService.testPreviewCheckRA(checkList,doInsert,operatingChecks,batchDate,batchDescription,nextCheckNumber,paidManually);
        return tempWrap; 
    }
    
    public void getPrintCheckListPreview(){
        vipPreviewMap = VendorCheckRunService.getvipPreviewMap();
        printedCheckVIMap = new Map<Id,List<Vendor_Invoice__c>>();
        printedCheckVCList = new List<Vendor_Invoice_Check__c>();
        printedCheckAmountWordsMap = new Map<Id,String>();
        printedCheckAmountSentMap = new Map<Id,Decimal>();
        printedCheckFJLMap = new Map<Id,Map<Id,VendorCheckRunService.FinancialJournalLineWrapper>>();
        printedCheckNumberOfInvoicesMap = new Map<Id,Integer>();
        checkPreview = true;
        
        //Map<Vendor_Invoice_Check__c,List<Vendor_Invoice__c>> vicViMap = new Map<Vendor_Invoice_Check__c,List<Vendor_Invoice__c>>();
        Set<Id> viId = new Set<Id>();
        Set<Id> vilIds = new Set<Id>();
        Set<Id> venIds = new Set<Id>();
        
        for(List<Vendor_Invoice_Payment__c> vipL : vipPreviewMap.values()){
            for(Vendor_Invoice_Payment__c vip : vipL){
                vilIds.add(vip.Vendor_Invoice_Line__c);
            }
        }
        for(Vendor_Invoice_Check__c vic : vicPreviewMap.values()){
            venIds.add(vic.Vendor__c);
        }
        Map<Id,Vendor_Invoice_Line__c> vilPreviewMap= new Map<Id,Vendor_Invoice_Line__c>([Select id,Financial_Account__c,Financial_Account__r.Name,Financial_Account__r.Account_Number__c from Vendor_Invoice_Line__c where Id in :vilIds]);
        venPreviewMap = new Map<Id,Account>([select id,Name
                                             from Account where id in :venIds]);
        for(Vendor_Invoice_Check__c vic : vicPreviewMap.values()){
            Set<Id> viIdForCheck = new Set<Id>();
            NumberToWordConversion nwcObj = new NumberToWordConversion();
            String numInWords = nwcObj.getNumberToWordConversion(vic.Amount__c);
            printedCheckAmountWordsMap.put(vic.vendor__c,numInWords);
            printedCheckVCList.add(vic);
            if(!printedCheckFJLMap.containsKey(vic.Vendor__c)){
                printedCheckFJLMap.put(vic.Vendor__c,new Map<Id,VendorCheckRunService.FinancialJournalLineWrapper>());
            }
            if(!printedCheckNumberOfInvoicesMap.containsKey(vic.Vendor__c)){
                printedCheckNumberOfInvoicesMap.put(vic.Vendor__c,0);
            }
            for(Vendor_Invoice_Payment__c vi : vipPreviewMap.get(vic.Vendor__c)){
                
                
                if(!printedCheckAmountSentMap.containsKey(vi.Vendor_Invoice__c)){
                    printedCheckAmountSentMap.put(vi.Vendor_Invoice__c,0);
                }
                if (vi.Amount_Paid__c != null && vi.Amount_Paid__c >0 ) {
                	printedCheckAmountSentMap.put(vi.Vendor_Invoice__c,printedCheckAmountSentMap.get(vi.Vendor_Invoice__c)+vi.Amount_Paid__c);
                }
                if(!viIdForCheck.contains(vi.Vendor_Invoice__c)){
                    printedCheckNumberOfInvoicesMap.put(vic.Vendor__c,printedCheckNumberOfInvoicesMap.get(vic.Vendor__c)+1);
                }
                viIdForCheck.add(vi.Vendor_Invoice__c);
                viId.add(vi.Vendor_Invoice__c);
                
                if(!printedCheckFJLMap.get(vic.Vendor__c).containsKey(vilPreviewMap.get(vi.Vendor_Invoice_Line__c).Financial_Account__c)){
                    printedCheckFJLMap.get(vic.Vendor__c).put(vilPreviewMap.get(vi.Vendor_Invoice_Line__c).Financial_Account__c,new VendorCheckRunService.FinancialJournalLineWrapper(vilPreviewMap.get(vi.Vendor_Invoice_Line__c).Financial_Account__r.Name,vilPreviewMap.get(vi.Vendor_Invoice_Line__c).Financial_Account__r.Account_Number__c));
                }
                
                printedCheckFJLMap.get(vic.Vendor__c).get(vilPreviewMap.get(vi.Vendor_Invoice_Line__c).Financial_Account__c).accTotal += vi.Amount_Paid__c;
                
            }
        }/**/
        Map<Id,Vendor_Invoice__c> vilMap = new Map<Id,Vendor_Invoice__c>([Select Id, Name, Amount__c, Invoice_Date__c, Invoice_Number__c,
                                                                          Include_Notes_on_Check__c, Notes__c, PO_Number__c,Amount_Remaining__c
                                                                          from Vendor_Invoice__c where Id in:viId]);
        for(Vendor_Invoice_Check__c vic :vicPreviewMap.values()){
            if(!printedCheckVIMap.containsKey(vic.Vendor__c)){
                printedCheckVIMap.put(vic.Vendor__c,new List<Vendor_Invoice__c>());
            }
            Set<ID> viIds = new Set<Id>();
            for(Vendor_Invoice_Payment__c vil : vipPreviewMap.get(vic.Vendor__c)){
                if(!viIds.contains(vil.Vendor_Invoice__c)){
                    printedcheckvimap.get(vic.Vendor__c).add(vilMap.get(vil.Vendor_Invoice__c));
                    viIds.add(vil.Vendor_Invoice__c);
                }
            }
        }/**/
        system.debug('print data :'+printedCheckVIMap);
    }
    public void getprintCheckList(){
        String batchid = ApexPages.currentPage().getparameters().get('bid');
        checkPreview = false;
        if((batchId==null || batchId=='')|| checkPreview==true){
            getprintCheckListPreview();
            return;
        }
        printedCheckVIMap = new Map<Id,List<Vendor_Invoice__c>>();
        printedCheckVCList = new List<Vendor_Invoice_Check__c>();
        printedCheckAmountWordsMap = new Map<Id,String>();
        printedCheckAmountSentMap = new Map<Id,Decimal>();
        printedCheckFJLMap = new Map<Id,Map<Id,VendorCheckRunService.FinancialJournalLineWrapper>>();
        printedCheckNumberOfInvoicesMap = new Map<Id,Integer>();
        List<Vendor_Invoice_Check__c> checkVICList = (List<Vendor_Invoice_Check__c>)Data.read(
            'Select Vendor__c, Vendor__r.Name, Amount__c, Check_Date__c, '+
            'Check_Number__c, Memo__c,Vendor__r.ShippingStreet,Vendor__r.ShippingCity,Vendor__r.ShippingCountry,Vendor__r.ShippingPostalCode, '+
            '(Select Id, Amount_Paid__c,Vendor_Invoice__c,Vendor_Invoice_Line__r.Financial_Account__c,Vendor_Invoice_Line__r.Financial_Account__r.Name,Vendor_Invoice_Line__r.Financial_Account__r.Account_Number__c ' +
            'from Vendor_Invoice_Payments__r) '+
            'from Vendor_Invoice_Check__c where Vendor_Invoice_Check_Batch__c=:batchid order by Check_Number__c ASC',
            new Map<String,Object> {
                'batchid' => batchid
                    }
        );
        
        
        Set<Id> viId = new Set<Id>();
        Integer i=0;
        for(Vendor_Invoice_Check__c vic : checkVICList){
            Set<Id> viIdForCheck = new Set<Id>();
   			NumberToWordConversion nwcObj = new NumberToWordConversion();
            double amtToWord=vic.Amount__c;
            if(amtToWord < 0){
                amtToWord = amtToWord*-1;
            }
           	String numInWords = nwcObj.getNumberToWordConversion(amtToWord);
            printedCheckAmountWordsMap.put(vic.Id,numInWords);
            
            if(i==0){
            }
            i++;
            printedCheckVCList.add(vic);
            if(!printedCheckFJLMap.containsKey(vic.Id)){
                printedCheckFJLMap.put(vic.Id,new Map<Id,VendorCheckRunService.FinancialJournalLineWrapper>());
            }
            if(!printedCheckNumberOfInvoicesMap.containsKey(vic.Id)){
                printedCheckNumberOfInvoicesMap.put(vic.Id,0);
            }
            for(Vendor_Invoice_Payment__c vi : vic.Vendor_Invoice_Payments__r){
                if(!printedCheckAmountSentMap.containsKey(vi.Vendor_Invoice__c)){
                    printedCheckAmountSentMap.put(vi.Vendor_Invoice__c,0);
                }
                if (vi.Amount_Paid__c != null ) {
                    printedCheckAmountSentMap.put(vi.Vendor_Invoice__c,printedCheckAmountSentMap.get(vi.Vendor_Invoice__c)+vi.Amount_Paid__c);
                }
                if(!viIdForCheck.contains(vi.Vendor_Invoice__c)){
                    printedCheckNumberOfInvoicesMap.put(vic.Id,printedCheckNumberOfInvoicesMap.get(vic.Id)+1);
                }
                viIdForCheck.add(vi.Vendor_Invoice__c);
                viId.add(vi.Vendor_Invoice__c);
                
                if(!printedCheckFJLMap.get(vic.Id).containsKey(vi.Vendor_Invoice_Line__r.Financial_Account__c)){
                    printedCheckFJLMap.get(vic.Id).put(vi.Vendor_Invoice_Line__r.Financial_Account__c,new VendorCheckRunService.FinancialJournalLineWrapper(vi.Vendor_Invoice_Line__r.Financial_Account__r.Name,vi.Vendor_Invoice_Line__r.Financial_Account__r.Account_Number__c));
                }
                
                if (vi.Amount_Paid__c != null) {
                    printedCheckFJLMap.get(vic.Id).get(vi.Vendor_Invoice_Line__r.Financial_Account__c).accTotal += vi.Amount_Paid__c;
                }
            }
        }
        Map<Id,Vendor_Invoice__c> vilMap = new Map<Id,Vendor_Invoice__c>([Select Id, Name, Amount__c, Invoice_Date__c, Invoice_Number__c,
                                                                          Include_Notes_on_Check__c, Notes__c, PO_Number__c,Amount_Remaining__c
                                                                          from Vendor_Invoice__c where Id in:viId]);
        for(Vendor_Invoice_Check__c vic :checkVICList){
            printedCheckVIMap.put(vic.Id,new List<Vendor_Invoice__c>());
            Set<ID> viIds = new Set<Id>();
            for(Vendor_Invoice_Payment__c vil : vic.Vendor_Invoice_Payments__r){
                if(!viIds.contains(vil.Vendor_Invoice__c)){
                    printedcheckvimap.get(vic.Id).add(vilMap.get(vil.Vendor_Invoice__c));
                    viIds.add(vil.Vendor_Invoice__c);
                }
            }
        }
        
    }
    
    public void selectInvoice(){
        if(selectedVendor!=null){
            if(viwVendorMap.containsKey(selectedVendor)){
                if(selectedInvoice!=null){
                    if(viwMap.containsKey(selectedInvoice)){
                        viwMap.get(selectedInvoice).amountToPay = viwMap.get(selectedInvoice).amount;
                    }else if(viwHoldMap.containsKey(selectedInvoice)){
                        viwHoldMap.get(selectedInvoice).amountToPay = viwHoldMap.get(selectedInvoice).amount;
                    }
                }
            }else if(viwHoldVendorMap.containsKey(selectedVendor)){
                if(selectedInvoice!=null){
                    if(viwHoldMap.containsKey(selectedInvoice)){
                        viwHoldMap.get(selectedInvoice).amountToPay = viwHoldMap.get(selectedInvoice).amount;
                    }
                }
            }
        }
        reCalcTotal();
    }
    
    //Recalc total amount
    public void reCalcTotal(){
        payingAmount = 0.00;
        payingHoldAmount = 0.00;
        numOfSelChecks = 0;
        numOfSelHoldChecks = 0;
        Set<Id> venId = new Set<Id>();
        Set<Id> venHoldId = new Set<Id>();
        Map<Id,Decimal> venSumAmount = new Map<Id,Decimal>();
        Map<Id,Decimal> venHoldSumAmount = new Map<Id,Decimal>();
        for(VendorCheckRunService.VendorInvoiceWrapper viw : viwMap.values()){
            viw.checkRunAmount = 0.00;
        }
        for(VendorCheckRunService.VendorInvoiceWrapper viw : viwHoldMap.values()){
            viw.checkRunAmount = 0.00;
        }
        for(VendorCheckRunService.VendorInvoiceWrapper viw : viwMap.values()){
            if(viw.selected==true && viw.vi!=null){
                if((viw.amount>0 && (viw.amountToPay>viw.amount || viw.amountToPay<0))|| (viw.amount<0 && (viw.amountToPay<viw.amount || viw.amountToPay>0))){
                    viw.amountToPay = viw.amount;
                }
                if(viw.amountToPay == 0){
                    viw.amountToPay = viw.amount;
                }
                payingAmount+=viw.amountToPay;
                venId.add(viw.vi.Vendor__c);
                if(!venSumAmount.containsKey(viw.vi.Vendor__c)){
                    venSumAmount.put(viw.vi.Vendor__c,viw.amounttopay);
                }else{
                    venSumAmount.put(viw.vi.Vendor__c,venSumAmount.get(viw.vi.Vendor__c)+viw.amounttopay);
                }
            }
        }
        
        //Checks On Hold
        for(VendorCheckRunService.VendorInvoiceWrapper viw : viwHoldMap.values()){
            if(viw.selected==true && viw.vi!=null){
                if(viw.amountToPay>viw.amount){
                    viw.amountToPay = viw.amount;
                }
                if(viw.amountToPay == 0){
                    viw.amountToPay = viw.amount;
                }
                payingHoldAmount+=viw.amountToPay;
                venHoldId.add(viw.vi.Vendor__c);
                if(!venHoldSumAmount.containsKey(viw.vi.Vendor__c)){
                    venHoldSumAmount.put(viw.vi.Vendor__c,viw.amounttopay);
                }else{
                    venHoldSumAmount.put(viw.vi.Vendor__c,venHoldSumAmount.get(viw.vi.Vendor__c)+viw.amounttopay);
                }
            }
        }
        for(Id vid : venSumAmount.keySet()){
            viwMap.get(vid).checkRunAmount=venSumAmount.get(vid);
        }
        for(Id vid : venHoldSumAmount.keySet()){
            viwHoldMap.get(vid).checkRunAmount=venHoldSumAmount.get(vid);
        }
        numOfSelChecks = venId.size();
        numOfSelHoldChecks = venHoldId.size();
    }
    //Select all invoices for vendor
    public void selectAllVendor(){
        if(selectedVendor!=null){
            if(selectAllOnHold=='false'){
                if(viwVendorMap.containsKey(selectedVendor)){
                    Boolean selectedValue = viwMap.get(selectedVendor).selected;
                    for(Id viId : viwVendorMap.get(selectedVendor)){
                        viwMap.get(viId).selected = selectedValue;
                    }
                    
                    reCalcTotal();
                }
            }else if(selectAllOnHold=='true'){
                if(viwHoldVendorMap.containsKey(selectedVendor)){
                    Boolean selectedValue = viwHoldMap.get(selectedVendor).selected;
                    for(Id viId : viwHoldVendorMap.get(selectedVendor)){
                        viwHoldMap.get(viId).selected = selectedValue;
                    }
                    
                    reCalcTotal();
                }
            }
        }
    }
    //Select all vendor invoices
    public void selectAll(){
        if(selectAllOnHold=='false'){
            for(VendorCheckRunService.VendorInvoiceWrapper viw : viwMap.values()){
                viw.selected = selectAll;
            }
        }else if(selectAllOnHold == 'true'){
            for(VendorCheckRunService.VendorInvoiceWrapper viw : viwHoldMap.values()){
                viw.selected = selectAll;
            }
        }
        reCalcTotal();
    }
    //Get a list of all closed Months within a range
    //Reload which months are open/closed
    public void regenerateClosedMonths(){
        //Calculate which months have closed
        Date startFCDate = Date.newInstance(vicb.Batch_Date__c.year(),vicb.Batch_Date__c.month(),1);
        Date endFCDate = Date.newInstance(vicb.Batch_Date__c.year(), vicb.Batch_Date__c.month(), 1).addMonths(1).addDays(-1);        
        
        closedFCMap = new Set<Date>();        
        //Let user know which months are closed ahead of time.
        closedMonthWarning = '';
        for(Date d : closedFCMap){
            closedMonthWarning+=','+d.month()+'/'+d.year();
        }
        if(closedMonthWarning.length()>0){
            closedMonthWarning = closedMonthWarning.substring(1);
        }
    }
    public Boolean checkClosedMonth(Date d){
        Boolean check = false;
        if(closedFCMap.contains(Date.newInstance(d.year(), 1, d.day()))){
            check = true;
        }
        return check;
    }
    //Check to make sure Batch Date is not in the past or for a closed month
    public void checkBatchDate(){        
        validCheckBatchDate = !checkClosedMonth(vicb.Batch_Date__c);
        if(validCheckBatchDate==false){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Fatal,'Batch Date is within a closed month.'));
        }else{
            loadPostedInvoices();                    
            loadNotPostedInvoices();
            
        }
    }
    // Call loadPostedInvoices from the filter fields
    public void filterInvoices(){
        loadPostedInvoices();
        loadNotPostedInvoices();
    }
    //Cancel the current Batch/Start over
    public void cancelBatch(){
        validCheckBatchDate = false;
        vicb.Description__c = '';
        numOfSelChecks = 0;
        numOfSelHoldChecks = 0;
        regenerateClosedMonths();
        selectAll = false;
        viwMap.clear();
        viwHoldMap.clear();
    }    
}