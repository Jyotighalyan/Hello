public with sharing class VendorCheckRunService {
    
    //Batch that ties all checks generated this run together
    public Vendor_Invoice_Check_Batch__c vicb{get;set;}
    //Closed Month Variables
    private Set<Date> closedFCMap{get;set;}
    public String closedMonthWarning{get;set;}
    //Selected Number of checks
    public Integer numOfSelChecks{get;set;}
    public Integer numOfSelHoldChecks{get;set;}
    //Holds all of our Invoice Wrapper <Index,Wrapper>
    public static Map<Id,VendorInvoiceWrapper> viwMap{get;set;}
    public static Map<Id,VendorInvoiceWrapper> viwHoldMap{get;set;}
    public static Map<Id,List<Id>> viwVendorMap{get;set;}
    public static Map<Id,List<Id>> viwHoldVendorMap{get;set;}
    public Decimal grandTotal{get;set;}
    public Decimal grandHoldTotal{get;set;}
    public Decimal payingAmount{get;set;}
    public Decimal payingHoldAmount{get;set;}

    public Integer nextCheckNumber{get;set;}
    //public Integer checkDigits{get;set;}
    public Check_Run__c checkRun{get;set;}
    //Location for Check Run and Operating Checks Account - Defaults to Operating Check check box
    public Vendor_Invoice__c locationSelection{get;set;}
    public Financial_Account__c operatingChecks{get;set;}
    //Check Print Page
    public Map<Id,List<Vendor_Invoice__c>> printedCheckVIMap{get;set;}
    public List<Vendor_Invoice_Check__c> printedCheckVCList{get;set;}
    public Map<Id,Map<Id,FinancialJournalLineWrapper>> printedCheckFJLMap{get;set;}
    public Map<Id,Decimal> printedCheckAmountSentMap{get;set;}
    public Map<Id,String> printedCheckAmountWordsMap{get;set;}
    public Map<Id,Integer> printedCheckNumberOfInvoicesMap{get;set;}
    public static Map<Id,List<Vendor_Invoice_Payment__c>> vipPreviewMap{get;set;}
    public Map<Id,Vendor_Invoice_Check__c> vicPreviewMap{get;set;}
    public Map<Id,Contact> venPreviewMap{get;set;}
    public VendorCheckRunService() {

    }
    public Check_Run__c getNextCheckNumber(){
        try{
            checkRun = [Select id,Next_Check_Number__c,Printed_Check_Digits__c from Check_Run__c limit 1];
        	integer nextCheckNumber=0;
        	if(Schema.sObjectType.Check_Run__c.fields.Next_Check_Number__c.isAccessible()){
        	  	nextCheckNumber = integer.valueOf(checkRun.Next_Check_Number__c);
			}
        }catch(exception e){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error, 'Please add values in "check run" custom setting first.'));    
        }
        return checkRun;
    }
   
    //Return a list of all of the invoices wrappers for pageblocktable
    public List<VendorInvoiceWrapper> getPostedInvoices(Map<Id,VendorInvoiceWrapper> data){
        List<VendorInvoiceWrapper> tempWrap = data.values();
        tempWrap.sort();
        return tempWrap;
    }
    public void loadPostedInvoices(string PurchaseCategory, date endDate){
        
        viwMap = new Map<Id,VendorInvoiceWrapper>();
        viwVendorMap = new Map<Id,List<Id>>();
        grandTotal = 0.00;
        payingAmount = 0.00;
        Map<Id, Decimal> vendorIdToTotal = new Map<Id,Decimal>();
        Map<Id,String> vendorIdToName = new Map<Id,String>();
        //Only Load Vendor Invoice Lines that have been booked but were not previously included on a check.
        List<Vendor_Invoice_Payment__c> vipList;
        if (PurchaseCategory == null || PurchaseCategory  == ''){
            vipList = (List<Vendor_Invoice_Payment__c>)Data.read(
                'Select Id,Amount__c,Vendor_Invoice__r.Amount_Remaining__c,Amount_Paid__c,Vendor_Invoice__c,Vendor_Invoice_Line__r.Amount__c ' +
                    'FROM Vendor_Invoice_Payment__c '+
                    'WHERE Check_Generated__c = false AND Payment_Type__c= \'Check\' AND vendor_invoice__r.Hold_Status__c = false '+          
                	'AND Vendor_Invoice__r.Due_Date__c <=:endDate and '+
                      'Vendor_Invoice__r.Amount_Remaining__c!=0 and (Vendor_Invoice__r.Vendor__c != \'\' or Vendor_Invoice__r.Vendor__c != null)',
                new Map<String,Object> {
                    'endDate' => endDate
                }
            );
        }else {  
            vipList = (List<Vendor_Invoice_Payment__c>)Data.read(
                'Select Id,Amount__c,Vendor_Invoice__r.Amount_Remaining__c,Amount_Paid__c,Vendor_Invoice__c,Vendor_Invoice_Line__r.Amount__c '+
                'FROM Vendor_Invoice_Payment__c '+
                'WHERE Check_Generated__c = false AND Payment_Type__c= \'Check\' AND vendor_invoice__r.Hold_Status__c = false '+
                'AND Vendor_Invoice__r.Due_Date__c <=:endDate '+
                'AND Vendor_Invoice__r.Vendor__r.Purchase_Category__c  =:PurchaseCategory and '+
                'Vendor_Invoice__r.Amount_Remaining__c!=0 and (Vendor_Invoice__r.Vendor__c != \'\' or Vendor_Invoice__r.Vendor__c != null)',
                new Map<String,Object> {
                    'endDate' => endDate,
                    'PurchaseCategory'=>PurchaseCategory
                }
            );
        }
        Set<Id> viIdSet = new Set<Id>();
        for(Vendor_Invoice_Payment__c vip : vipList){
            viIdSet.add(vip.Vendor_Invoice__c);
        }


        Map<Id,Vendor_Invoice__c> viMap = new Map<Id,Vendor_Invoice__c>([SELECT id,Notes__c,Include_Notes_on_Check__c,Name,Amount__c,Due_Date__c,Invoice_Number__c,Vendor__c,Vendor__r.Name,
                                                                             Vendor_Invoice_Check__c
                                                                             FROM Vendor_Invoice__c
                                                                             WHERE id in :viIdSet ]);
        Set<Id> vendorInvoiceIds = new Set<Id>();
        
        for(Vendor_Invoice_Payment__c vip : vipList){
             if(!viwVendorMap.containsKey(viMap.get(vip.Vendor_Invoice__c).Vendor__c)){
                
                viwVendorMap.put(viMap.get(vip.Vendor_Invoice__c).Vendor__c,new List<Id>());
            }
            if(!viwMap.containsKey(vip.Vendor_Invoice__c)){
                
                VendorInvoiceWrapper viw = new VendorInvoiceWrapper(viMap.get(vip.Vendor_Invoice__c));
                viwMap.put(vip.Vendor_Invoice__c,viw);
                viwVendorMap.get(viMap.get(vip.Vendor_Invoice__c).Vendor__c).add(vip.Vendor_Invoice__c);
            }


            viwMap.get(vip.Vendor_Invoice__c).vipList.add(vip);
            if(!vendorInvoiceIds.contains(vip.Vendor_Invoice__c)){
               
                viwMap.get(vip.Vendor_Invoice__c).amount+=vip.Vendor_Invoice__r.Amount_Remaining__c;
                grandTotal+=vip.Amount__c;//(vip.Amount__c-vip.Vendor_Invoice_Line__r.Amount_Sent__c);
            }

            if(!vendorIdToName.containsKey(viMap.get(vip.Vendor_Invoice__c).Vendor__c)){
                
                vendorIdToName.put(viMap.get(vip.Vendor_Invoice__c).Vendor__c,viMap.get(vip.Vendor_Invoice__c).Vendor__r.Name);
                if(!vendorInvoiceIds.contains(vip.Vendor_Invoice__c)){
                    
                    vendorIdToTotal.put(viMap.get(vip.Vendor_Invoice__c).Vendor__c,vip.Vendor_Invoice__r.Amount_Remaining__c);
                }

            }else{
                
                if(!vendorInvoiceIds.contains(vip.Vendor_Invoice__c)){
                
                    vendorIdToTotal.put(viMap.get(vip.Vendor_Invoice__c).Vendor__c,vendorIdToTotal.get(viMap.get(vip.Vendor_Invoice__c).Vendor__c)+vip.Vendor_Invoice__r.Amount_Remaining__c);
                }
            }
            
            vendorInvoiceIds.add(vip.Vendor_Invoice__c);
        }
        
        for(Id ven : vendorIdToTotal.keySet()){
            
            VendorInvoiceWrapper viw = new VendorInvoiceWrapper(vendorIdtoName.get(ven),vendorIdToTotal.get(ven),ven);
            viwMap.put(ven,viw);
            viwVendorMap.get(ven).add(ven);
        }
    }
     //Return a list of all of the invoices wrappers for pageblocktable with Hold Status
    public List<VendorInvoiceWrapper> getNotPostedInvoices(Map<Id,VendorInvoiceWrapper> data){
        List<VendorInvoiceWrapper> tempWrap = data.values();
        tempWrap.sort();
        return tempWrap;
    }
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
     public class remotingReturnResponse{
        public String severityCode;
        public String messageStr;
        public String redirectURL;

    }
    public class remotingSaveRequest{
        public String invId;
        public Id vid;
        public Boolean selected;
        public Decimal amtToPay;
        public String memo;
    }
    public static List<remotingReturnResponse> testPreviewCheckRA(List<remotingSaveRequest> checkList,Boolean doInsert,Id operatingChecks,Date batchDate,String batchDescription,Integer nextCheckNumber,Boolean paidManually){
        
        for(remotingSaveRequest rsr : checkList){
            if(rsr.selected!=null){
            }
        }
        Set<Id> venInvoiceIds = new Set<Id>();
        Map<Id,Vendor_Invoice_Check__c> vicList = new Map<Id,Vendor_Invoice_Check__c>();
        List<Vendor_Invoice_Payment__c> invoicePaymentsToUpdate = new List<Vendor_Invoice_Payment__c>();
        Set<Vendor_Invoice__c> invoicesToUpdate = new Set<Vendor_Invoice__c>();
        Set<Vendor_Invoice_Line__c> invoiceLinesToUpdate = new Set<Vendor_Invoice_Line__c>();
        
         vipPreviewMap = new Map<Id,List<Vendor_Invoice_Payment__c>>();
        Map<Id,Vendor_Invoice_Check__c> vicPreviewMap = new Map<Id,Vendor_Invoice_Check__c>();
        Vendor_Invoice_Check_Batch__c vicb = new Vendor_Invoice_Check_Batch__c();
        vicb.Batch_Date__c = batchDate;
        vicb.Description__c=batchDescription;
        //vicb.Location__c = location;
        if(doInsert == true){
            if(Schema.sObjectType.Vendor_Invoice_Check_Batch__c.isCreateable()){Data.create(vicb);}
        }
        Check_Run__c checkRun = new Check_Run__c();
        List<Check_Run__c> checkRunDetail = (List<Check_Run__c>)Data.read(
                'Select id,Next_Check_Number__c,Printed_Check_Digits__c from Check_Run__c limit 1',
                new Map<String,Object> {
                }
            );
        checkRun.id=checkRunDetail[0].id;
        checkRun.Next_Check_Number__c=checkRunDetail[0].Next_Check_Number__c;
        checkRun.Printed_Check_Digits__c=checkRunDetail[0].Printed_Check_Digits__c;
        Decimal totalCheckAmount = 0;
        List<Financial_Journal_Line__c> fjsToInsert = new List<Financial_Journal_Line__c>();
        Map<Id,Decimal> vendTotalMap = new Map<Id,Decimal>();

        for(remotingSaveRequest viw : checkList){
            if(viw.vid!=null && viw.invId!=null && !viw.invId.contains('Total')){
                if(viw.selected == true){
                    venInvoiceIds.add(viw.invId);
                    if(!vicList.containsKey(viw.vid)){
                        Vendor_Invoice_Check__c vic = new Vendor_Invoice_Check__c();
                        vic.Amount__c = viw.amtToPay;
                        vic.Check_Date__c = vicb.Batch_Date__c;
                        vic.check_link__c ='/apex/CheckAsPDF?bid='+vicb.id;
                        vic.Check_Number__c = (nextCheckNumber+'').replaceAll(',','');
                        vic.Paid_Manually__c = paidManually;
                        String tempCheck = '';
                        for(Integer i = vic.Check_Number__c.length();i<checkRun.Printed_Check_Digits__c;i++){
                            tempCheck +='0';
                        }
                        vic.Check_Number__c=vic.Check_Number__c;
                        vic.Vendor_Invoice_Check_Batch__c = vicb.id;
                        vic.Vendor__c = viw.vid;
                        nextCheckNumber++;
                        vicList.put(viw.vid,vic);
                    }else{
                        vicList.get(viw.vid).amount__c+=viw.amtToPay;
                    }
                    if(!vendTotalMap.containsKey(viw.vid)){
                        vendTotalMap.put(viw.vid,0);
                    }
                    if(viw.amtToPay!=null){
                       vendTotalMap.put(viw.vid,vendTotalMap.get(viw.vid)+viw.amtToPay);
                       totalCheckAmount+=viw.amtToPay;
                   }
                }
            }
        }

        for(remotingSaveRequest viw : checkList){
            if(viw.invId!=null && viw.invId.contains('Total')){
                if(vicList.containsKey(viw.vid)){
                    if(vicList.get(viw.vid).Memo__c==null || vicList.get(viw.vid).Memo__c==''){
                        vicList.get(viw.vid).Memo__c=viw.memo;
                    }
                    //vicList.get(viw.vid).Total_Amount__c = vendTotalMap.get(viw.vid) +'';
                }
            }
        }
        if(doInsert==true){
            if(Schema.sObjectType.Vendor_Invoice_Check__c.isCreateable()){insert vicList.values();}
        }
        checkRun.Next_Check_Number__c = string.valueOf(nextCheckNumber);
        if(doInsert == true && Schema.sObjectType.Check_Run__c.isUpdateable()){update checkRun;}
        Map<Id,List<Vendor_Invoice_Payment__c>> vipMap = new Map<Id,List<Vendor_Invoice_Payment__c>>();
        for(Vendor_Invoice_Payment__c vip : [select Id,Vendor_Invoice__c, Vendor_Invoice_Line__c ,Amount__c,Amount_Paid__c from Vendor_Invoice_Payment__c where Vendor_Invoice__c in :venInvoiceIds and Check_Generated__c = false AND Payment_Type__c= 'Check' AND vendor_invoice__r.Hold_Status__c = false and (Vendor_Invoice__r.Vendor__c != '' or Vendor_Invoice__r.Vendor__c != null) ]){
            if(!vipMap.containsKey(vip.Vendor_Invoice__c)){
                vipMap.put(vip.Vendor_Invoice__c,new List<Vendor_Invoice_Payment__c>());
            }
            vipMap.get(vip.vendor_Invoice__c).add(vip);
        }
        for(remotingSaveRequest viw : checkList){
            Decimal viAmountAvailable = viw.amtToPay;
            if(viw.selected==true){
                if(viw.vid!=null && viw.invId!=null && !viw.invId.contains('Total') && viAmountAvailable!=null){
                    for(Vendor_Invoice_Payment__c vip : vipMap.get(viw.invId)){
                        //Decimal amt = 0;//vip.Amount__c-vip.Vendor_Invoice_Line__r.Amount_Sent__c;
						Decimal amt = vip.Amount__c-vip.Amount_Paid__c;
                        boolean assignCheck = false;
                        //We have plenty of money to cover this VIP
                        if(viAmountAvailable>=amt){
                            viAmountAvailable -= amt;
                            vip.Amount_Paid__c = amt;
                            vip.Vendor_Invoice_Check__c = vicList.get(viw.vid).id;
                            invoicePaymentsToUpdate.add(vip);
                            assignCheck = true;
                            vip.Vendor_Invoice_Check__c = vicList.get(viw.vid).id;
                        }else{
                            //We didn't have enough money to cover the whole thing
                            vip.Amount_Paid__c = viAmountAvailable;
                            viAmountAvailable -= amt;
                            vip.Vendor_Invoice_Check__c = vicList.get(viw.vid).id;
                            //Create a new line so we can pay off the remaining balance
                            invoicePaymentsToUpdate.add(new Vendor_Invoice_Payment__c(Vendor_Invoice__c=vip.Vendor_Invoice__c,Vendor_Invoice_Line__c=vip.Vendor_Invoice_Line__c,Amount_Paid__c=0));
                            invoicePaymentsToUpdate.add(vip);
                            vip.Vendor_Invoice_Check__c = vicList.get(viw.vid).id;
                        }
                        if(assignCheck){
                            Vendor_Invoice__c vi = new Vendor_Invoice__c(id=vip.Vendor_Invoice__c,Vendor_Invoice_Check__c=vicList.get(viw.vid).id);
                            invoicesToUpdate.add(vi);
                            Vendor_Invoice_Line__c vil = new Vendor_Invoice_Line__c(id=vip.Vendor_Invoice_Line__c,Vendor_Invoice_Check__c=vicList.get(viw.vid).id);
                            invoiceLinesToUpdate.add(vil);
                            
                        }
                        if(!vipPreviewMap.containsKey(viw.vid)){
                            vipPreviewMap.put(viw.vid,new List<Vendor_Invoice_Payment__c>());
                        }
                        vipPreviewMap.get(viw.vid).add(vip);
                        if(viAmountAvailable<=0){
                            break;
                        }
                    }
                }
            }
        }
        if(doInsert == true && Schema.sObjectType.Vendor_Invoice_Payment__c.isUpdateable() && Schema.sObjectType.Vendor_Invoice_Payment__c.isCreateable()){upsert invoicePaymentsToUpdate;}
        if(doInsert == true && Schema.sObjectType.Vendor_Invoice__c.isUpdateable()){update new List<Vendor_Invoice__c>(invoicesToUpdate);}
        if(doInsert == true && Schema.sObjectType.Vendor_Invoice_Line__c.isUpdateable()){update new List<Vendor_Invoice_Line__c>(invoiceLinesToUpdate);}
        remotingReturnResponse p = new remotingReturnResponse();
        if(doInsert == true){
            List<Default_Account__c> tradeAccount = (List<Default_Account__c>)Data.read(
                			'select id, Financial_Account__c from Default_Account__c where Default_Type_Name__c =:Value ',
                			new Map<String,Object> {
                			    'Value'=>'Accounts Payable'
                			}
                     ); 
            Financial_Journal_Entry__c fjEntry = new Financial_Journal_Entry__c();
            //vicb = [Select Name,Batch_Date__c from Vendor_Invoice_Check_Batch__c where Id=:vicb.Id limit 1];
            vicb = (Vendor_Invoice_Check_Batch__c)Data.read(
                			'Select Name,Batch_Date__c from Vendor_Invoice_Check_Batch__c where Id=:Value ',
                			new Map<String,Object> {
                			    'Value'=>vicb.Id
                			}
                     ).get(0); 
            
            fjEntry.Description__c = 'Invoice Check Batch '+vicb.Name;
            fjEntry.Entry_Date__c = vicb.Batch_Date__c;
            fjEntry.Posted__c = true;
            fjEntry.Post_Date__c = vicb.Batch_Date__c;
            if(Schema.sObjectType.Financial_Journal_Entry__c.isCreateable()){insert fjEntry;}
            Financial_Journal_Line__c tradeJournal = new Financial_Journal_Line__c();
            tradeJournal.Amount__c = totalCheckAmount;
            if(Utility.getCredDebitStatus(tradeAccount[0].Financial_Account__c) == 'Credit'){
                tradeJournal.Amount__c = -totalCheckAmount;
            }
            tradeJournal.Description__c = 'Invoice Check Batch '+vicb.Name;
            tradeJournal.Financial_Account__c=tradeAccount[0].Financial_Account__c;
            tradeJournal.Financial_Journal_Entry__c = fjEntry.Id;
            tradeJournal.Post_Date__c = vicb.Batch_Date__c;
            tradeJournal.Posted__c = true;
            tradeJournal.Transaction_Date__c = vicb.Batch_Date__c;
            Financial_Journal_Line__c cashJournal = new Financial_Journal_Line__c();
            cashJournal.Description__c = 'Invoice Check Batch '+vicb.Name;
            cashJournal.Amount__c = -totalCheckAmount;
            if(Utility.getCredDebitStatus(operatingChecks) == 'Credit'){
                cashJournal.Amount__c = totalCheckAmount;
            }
            cashJournal.Financial_Account__c=operatingChecks;
            cashJournal.Financial_Journal_Entry__c = fjEntry.Id;
            cashJournal.Post_Date__c = vicb.Batch_Date__c;
            cashJournal.Posted__c = true;
            cashJournal.Transaction_Date__c = vicb.Batch_Date__c;
            fjsToInsert.add(tradeJournal);
            fjsToInsert.add(cashJournal);
            if(Schema.sObjectType.Financial_Journal_Line__c.isCreateable()){Data.create(fjsToInsert);}
            p.redirectURL ='/apex/CheckAsPDF?bid='+vicb.id;
           
            p.severityCode = 'CONFIRM';
            p.messageStr = '';
            vicb.A_P_Trade_Journal_Line__c=tradeJournal.Id;
            vicb.Cash_Financial_Journal_Line__c=cashJournal.Id;
            vicb.Financial_Journal_Entry__c = fjEntry.Id;
            if(Schema.sObjectType.Vendor_Invoice_Check_Batch__c.isUpdateable()){Data.modify(vicb);}
            //vicb = new Vendor_Invoice_Check_Batch__c();
            //vicb.Batch_Date__c = Date.Today();
        }else{
            p.severityCode = 'CONFIRM';
            p.messageStr = '';
        }
        List<remotingReturnResponse> rrrLst = new List<remotingReturnResponse>();
        rrrLst.add(p);
        return rrrLst;
    }
    public static List<VendorInvoiceWrapper> loadPostedInvoicesRA(Date dueDate,String purchaseCategory){
        viwMap = new Map<Id,VendorInvoiceWrapper>();
         viwVendorMap = new Map<Id,List<Id>>();
        
        //grandTotal = 0.00;
        //payingAmount = 0.00;
        Map<Id, Decimal> vendorIdToTotal = new Map<Id,Decimal>();
        Map<Id,String> vendorIdToName = new Map<Id,String>();
        //Only Load Vendor Invoice Lines that have been booked but were not previously included on a check.
        List<Vendor_Invoice_Payment__c> vipList;
        if (purchaseCategory == null || purchaseCategory  == ''){
            /*vipList = [Select Id,Amount__c,Vendor_Invoice__r.Amount_Remaining__c,Amount_Paid__c,Vendor_Invoice__c,Vendor_Invoice_Line__r.Amount__c
                      FROM Vendor_Invoice_Payment__c
                      WHERE Check_Generated__c = false AND Payment_Type__c= 'Check' AND vendor_invoice__r.Hold_Status__c = false
                      AND Vendor_Invoice__r.Due_Date__c <=:dueDate and 
                      Vendor_Invoice__r.Amount_Remaining__c!=0];*/
            vipList = (List<Vendor_Invoice_Payment__c>)Data.read(
                		'Select Id,Amount__c,Vendor_Invoice__r.Amount_Remaining__c,Amount_Paid__c,Vendor_Invoice__c,Vendor_Invoice_Line__r.Amount__c '+
                      'FROM Vendor_Invoice_Payment__c '+
                      'WHERE Check_Generated__c = false AND Payment_Type__c= \'Check\' AND vendor_invoice__r.Hold_Status__c = false '+
                      'AND Vendor_Invoice__r.Due_Date__c <=:dueDate and '+
                      'Vendor_Invoice__r.Amount_Remaining__c!=0 and (Vendor_Invoice__r.Vendor__c != \'\' or Vendor_Invoice__r.Vendor__c != null)',
                new Map<String,Object> {
                    'dueDate' => dueDate
                }
            );
        }else {
            /*vipList = [Select Id,Amount__c,Vendor_Invoice__r.Amount_Remaining__c,Amount_Paid__c,Vendor_Invoice__c,Vendor_Invoice_Line__r.Amount__c
                      FROM Vendor_Invoice_Payment__c
                      WHERE Check_Generated__c = false AND Payment_Type__c= 'Check' AND vendor_invoice__r.Hold_Status__c = false
                      AND Vendor_Invoice__r.Due_Date__c <=:dueDate
                      AND Vendor_Invoice__r.Vendor__r.Purchase_Category__c  =:purchaseCategory and 
                      Vendor_Invoice__r.Amount_Remaining__c!=0];*/
            vipList = (List<Vendor_Invoice_Payment__c>)Data.read(
                	  'Select Id,Amount__c,Vendor_Invoice__r.Amount_Remaining__c,Amount_Paid__c,Vendor_Invoice__c,Vendor_Invoice_Line__r.Amount__c '+
                      'FROM Vendor_Invoice_Payment__c '+
                      'WHERE Check_Generated__c = false AND Payment_Type__c= \'Check\' AND vendor_invoice__r.Hold_Status__c = false '+
                      'AND Vendor_Invoice__r.Due_Date__c <=:dueDate and '+
                	  'Vendor_Invoice__r.Vendor__r.Purchase_Category__c  =:purchaseCategory and '+
                      'Vendor_Invoice__r.Amount_Remaining__c!=0 and (Vendor_Invoice__r.Vendor__c != \'\' or Vendor_Invoice__r.Vendor__c != null)',
                new Map<String,Object> {
                    'dueDate' => dueDate,
                    'purchaseCategory'=>purchaseCategory
                }
            );
            
        }
        Set<Id> viIdSet = new Set<Id>();
        for(Vendor_Invoice_Payment__c vip : vipList){
            viIdSet.add(vip.Vendor_Invoice__c);
        }
        Map<Id,Vendor_Invoice__c> viMap = new Map<Id,Vendor_Invoice__c>([SELECT id,Notes__c,Include_Notes_on_Check__c,Name,Amount__c,Due_Date__c,Invoice_Number__c,Vendor__c,Vendor__r.Name,
                                                                             Vendor_Invoice_Check__c
                                                                             FROM Vendor_Invoice__c
                                                                             WHERE id in :viIdSet ]);
        Set<Id> vendorInvoiceIds = new Set<Id>();
        
        for(Vendor_Invoice_Payment__c vip : vipList){
            if(!viwVendorMap.containsKey(viMap.get(vip.Vendor_Invoice__c).Vendor__c)){
                viwVendorMap.put(viMap.get(vip.Vendor_Invoice__c).Vendor__c,new List<Id>());
            }
            if(!viwMap.containsKey(vip.Vendor_Invoice__c)){
                VendorInvoiceWrapper viw = new VendorInvoiceWrapper(viMap.get(vip.Vendor_Invoice__c));
                viwMap.put(vip.Vendor_Invoice__c,viw);
                viwVendorMap.get(viMap.get(vip.Vendor_Invoice__c).Vendor__c).add(vip.Vendor_Invoice__c);
            }
            viwMap.get(vip.Vendor_Invoice__c).vipList.add(vip);
            viwMap.get(vip.Vendor_Invoice__c).Due_date = string.valueOf(viMap.get(vip.Vendor_Invoice__c).Due_Date__c.month() + '/' + viMap.get(vip.Vendor_Invoice__c).Due_Date__c.day() + '/' + viMap.get(vip.Vendor_Invoice__c).Due_Date__c.year());
            if(!vendorInvoiceIds.contains(vip.Vendor_Invoice__c)){
                viwMap.get(vip.Vendor_Invoice__c).amount+=vip.Vendor_Invoice__r.Amount_Remaining__c;
                //grandTotal+=(vip.Amount__c-vip.Vendor_Invoice_Line__r.Amount_Sent__c);
            }
            if(!vendorIdToName.containsKey(viMap.get(vip.Vendor_Invoice__c).Vendor__c)){
                vendorIdToName.put(viMap.get(vip.Vendor_Invoice__c).Vendor__c,viMap.get(vip.Vendor_Invoice__c).Vendor__r.Name);
                if(!vendorInvoiceIds.contains(vip.Vendor_Invoice__c)){
                    vendorIdToTotal.put(viMap.get(vip.Vendor_Invoice__c).Vendor__c,vip.Vendor_Invoice__r.Amount_Remaining__c);
                }

            }else{
                if(!vendorInvoiceIds.contains(vip.Vendor_Invoice__c)){
                    vendorIdToTotal.put(viMap.get(vip.Vendor_Invoice__c).Vendor__c,vendorIdToTotal.get(viMap.get(vip.Vendor_Invoice__c).Vendor__c)+vip.Vendor_Invoice__r.Amount_Remaining__c);
                }
            }
            vendorInvoiceIds.add(vip.Vendor_Invoice__c);
        }
        for(Id ven : vendorIdToTotal.keySet()){
            VendorInvoiceWrapper viw = new VendorInvoiceWrapper(vendorIdtoName.get(ven),vendorIdToTotal.get(ven),ven);
            viwMap.put(ven,viw);
        }
        List<VendorInvoiceWrapper> viwMapreturn = viwMap.values();
        viwMapreturn.sort();
        return viwMapReturn;
    }
    public void loadNotPostedInvoices(string PurchaseCategory, date endDate){
        
        viwHoldMap = new Map<Id,VendorInvoiceWrapper>();
        viwHoldVendorMap = new Map<Id,List<Id>>();
        grandHoldTotal = 0.00;
        payingHoldAmount = 0.00;
        Map<Id, Decimal> vendorIdToTotal = new Map<Id,Decimal>();
        Map<Id,String> vendorIdToName = new Map<Id,String>();
        //Only Load Vendor Invoice Lines that have been booked but were not previously included on a check.
        List<Vendor_Invoice_Payment__c> vipHoldList;
        if (PurchaseCategory == null || PurchaseCategory  == ''){
            vipHoldList = (List<Vendor_Invoice_Payment__c>)Data.read(
                	  'Select Id,Amount__c,Vendor_Invoice__r.Amount_Remaining__c,Amount_Paid__c,Vendor_Invoice__c,Vendor_Invoice_Line__r.Amount__c '+
                      'FROM Vendor_Invoice_Payment__c '+
                      'WHERE Check_Generated__c = false AND Payment_Type__c= \'Check\' AND vendor_invoice__r.Hold_Status__c = true '+
                      'AND Vendor_Invoice__r.Due_Date__c <=:endDate and '+
                      'Vendor_Invoice__r.Amount_Remaining__c!=0 and (Vendor_Invoice__r.Vendor__c != \'\' or Vendor_Invoice__r.Vendor__c != null)',
                new Map<String,Object> {
                    'endDate' => endDate
                }
            );
            
        }else {
            vipHoldList = (List<Vendor_Invoice_Payment__c>)Data.read(
                	  'Select Id,Amount__c,Vendor_Invoice__r.Amount_Remaining__c,Amount_Paid__c,Vendor_Invoice__c,Vendor_Invoice_Line__r.Amount__c '+
                      'FROM Vendor_Invoice_Payment__c '+
                      'WHERE Check_Generated__c = false AND Payment_Type__c= \'Check\' AND vendor_invoice__r.Hold_Status__c = true '+
                      'AND Vendor_Invoice__r.Due_Date__c <=:endDate and '+
                	  'Vendor_Invoice__r.Vendor__r.Purchase_Category__c  =:purchaseCategory and '+
                      'Vendor_Invoice__r.Amount_Remaining__c!=0 and (Vendor_Invoice__r.Vendor__c != \'\' or Vendor_Invoice__r.Vendor__c != null)',
                new Map<String,Object> {
                    'endDate' => endDate,
                    'purchaseCategory'=>purchaseCategory
                }
            );
            
        }
        Set<Id> viIdSet = new Set<Id>();
        for(Vendor_Invoice_Payment__c vip : vipHoldList){
            viIdSet.add(vip.Vendor_Invoice__c);
        }
        Map<Id,Vendor_Invoice__c> viHoldMap = new Map<Id,Vendor_Invoice__c>([SELECT id,Notes__c,Include_Notes_on_Check__c,Name,Amount__c,Due_Date__c,Invoice_Number__c,Vendor__c,Vendor__r.Name,
                                                                             Vendor_Invoice_Check__c
                                                                             FROM Vendor_Invoice__c
                                                                            WHERE id in :viIdSet ]);
        Set<Id> vendorInvoiceIds = new Set<Id>();
        for(Vendor_Invoice_Payment__c vip : vipHoldList){
            if(!viwHoldVendorMap.containsKey(viHoldMap.get(vip.Vendor_Invoice__c).Vendor__c)){
                viwHoldVendorMap.put(viHoldMap.get(vip.Vendor_Invoice__c).Vendor__c,new List<Id>());
            }
            if(!viwHoldMap.containsKey(vip.Vendor_Invoice__c)){
                VendorInvoiceWrapper viw = new VendorInvoiceWrapper(viHoldMap.get(vip.Vendor_Invoice__c));
                viwHoldMap.put(vip.Vendor_Invoice__c,viw);
                viwHoldVendorMap.get(viHoldMap.get(vip.Vendor_Invoice__c).Vendor__c).add(vip.Vendor_Invoice__c);
            }
            viwHoldMap.get(vip.Vendor_Invoice__c).vipList.add(vip);
            if(!vendorInvoiceIds.contains(vip.Vendor_Invoice__c)){
                viwHoldMap.get(vip.Vendor_Invoice__c).amount+=vip.Vendor_Invoice__r.Amount_Remaining__c;
            }
            if(!vendorIdToName.containsKey(viHoldMap.get(vip.Vendor_Invoice__c).Vendor__c)){
                vendorIdToName.put(viHoldMap.get(vip.Vendor_Invoice__c).Vendor__c,viHoldMap.get(vip.Vendor_Invoice__c).Vendor__r.Name);
                if(!vendorInvoiceIds.contains(vip.Vendor_Invoice__c)){
                    vendorIdToTotal.put(viHoldMap.get(vip.Vendor_Invoice__c).Vendor__c,vip.Vendor_Invoice__r.Amount_Remaining__c);
                }
            }else{
                if(!vendorInvoiceIds.contains(vip.Vendor_Invoice__c)){
                    vendorIdToTotal.put(viHoldMap.get(vip.Vendor_Invoice__c).Vendor__c,vendorIdToTotal.get(viHoldMap.get(vip.Vendor_Invoice__c).Vendor__c)+vip.Vendor_Invoice__r.Amount_Remaining__c);
                }
            }
            vendorInvoiceIds.add(vip.Vendor_Invoice__c);
        }
        for(Id ven : vendorIdToTotal.keySet()){
            VendorInvoiceWrapper viw = new VendorInvoiceWrapper(vendorIdtoName.get(ven),vendorIdToTotal.get(ven),ven);
            viwHoldMap.put(ven,viw);
            viwHoldVendorMap.get(ven).add(ven);
        }
    }
    public static Map<Id,VendorInvoiceWrapper> getViewMap(){
        return viwMap;
    }
    public static Map<Id,List<Id>> getviwVendorMap(){
        return viwVendorMap;
    }
    public static Map<Id,VendorInvoiceWrapper> getviwHoldMap(){
        return viwHoldMap;
    }
    public static Map<Id,List<Id>> getviwHoldVendorMap(){
        return viwHoldVendorMap;
    }
    public static Map<Id,List<Vendor_Invoice_Payment__c>> getvipPreviewMap(){
        return vipPreviewMap;
    }
    //Wrapper class for VendorInvoices
    public class VendorInvoiceWrapper implements Comparable{
        public Vendor_Invoice__c vi{get;set;}
        public List<Vendor_Invoice_Payment__c> vipList{get;set;}
        public Boolean selected{get;set;}
        public String name{get;set;}
        public Decimal amount{get;set;}
        public Decimal amountToPay{get;set;}
        public Decimal checkRunAmount{get;set;}
        public Integer index{get;set;}
        public String memo{get;set;}
        public String vendor{get;set;}
        public String totalAmount{get;set;}
        public String Due_date{get;set;}
        public VendorInvoiceWrapper(Vendor_Invoice__c vi){
            this.vi = vi;
            vipList = new List<Vendor_Invoice_Payment__c>();
            amount = 0.00;
            amountToPay = 0.00;
            checkRunAmount=0.00;
            name = '';
        }
        public VendorInvoiceWrapper(String n, Decimal a,String v){
            name = n+' Total';
            amount = a;
            checkRunAmount = 0.00;
            amountToPay = 0.00;
            vendor = v;
        }
        public Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            VendorInvoiceWrapper compareToVIW = (VendorInvoiceWrapper)compareTo;

            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if(vi!=null && compareToVIW.vi!=null){
                if(vi.Vendor__r.Name<compareToVIW.vi.Vendor__r.Name){
                    returnValue = -1;
                }else{
                    returnValue = 1;
                }
            }else if(vi!=null){
                if(vi.Vendor__r.Name<compareToVIW.name){
                    returnValue = -1;
                }else{
                    returnValue = 1;
                }
            }else if(compareToVIW.vi!=null){
                if(name<compareToVIW.vi.Vendor__r.Name){
                    returnValue = -1;
                }else{
                    returnValue = 1;
                }
            }else{
                if(name<compareToVIW.name){
                    returnValue = -1;
                }else{
                    returnValue = 1;
                }
            }
            return returnValue;
        }
    }
     public class FinancialJournalLineWrapper{
        public String accName{get;set;}
        public String accNum{get;set;}
        public Decimal accTotal{get;set;}
        public FinancialJournalLineWrapper(String accName, String accNum){
            this.accName = accName;
            this.accNum = accNum;
            accTotal = 0;
        }
    }
}