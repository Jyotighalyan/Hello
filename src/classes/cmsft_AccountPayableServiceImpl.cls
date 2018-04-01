/**
* https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Service_Layer
* @Date: 20th May - 2017
* @Author: Jyotig@mobifyi.com 
* @group: Financial Management 
* @Description: Bussiness logic for AccountsPayableController
*/

public with sharing class cmsft_AccountPayableServiceImpl {
    
    /**
* @Description : bussiness logic for searching vendor invoices that are not posted between startdate and enddate
* @return : returns list of invoices not posted and having invoice date b/w passed dates
* @ param startDate : startdate date to be searched - inclusive 
* @ param endDate : till endDate date searching - inclusive 
*/
    public static List<Vendor_Invoice__c> getVendorInvoiceListImpl(Date startDate, Date endDate) {
        String sDate = String.valueOf(startDate);
        String eDate = String.valueOf(endDate);
        return new cmsft_vendorInvoiceTriggerSelector().selectVendorInvoicesWithPassedCondition('Invoice_Date__c>='+sDate.split(' ').get(0)+' AND Invoice_Date__c<='+eDate.split(' ').get(0)+' AND Post_Status__c=false AND Hold_Status__c=false');
    }
    
    /**
* @Description : method calls utility post invoice method to post invoices
* @return : return page to be refreshed
* @ param unpostedVendInv : list of invoices to be posted
*/
    public static void postSelectedEnteries(List<Vendor_Invoice__c> postInvoices, Date postDate, Date endDate){
        postInvoice(postInvoices, postDate, endDate);
    }
    
    /**
* @Description : bussiness logic behind getting posted invoices that are posted today
* @return : returns list of vendor invoices that are posted in todays date
* @ param todaysDate : date of today
*/
    public static List<Vendor_Invoice__c> getListOfPostedInvoices(Date startDate, Date endDate){
        return Data.read('select Posted__c, Post_Status__c, Hold_Status__c, Vendor__c, Invoice_Date__c, Amount__c, Invoice_Number__c, Posted_Date__c, Post_Date__c, Due_Date__c, Name from Vendor_Invoice__c where Posted__c=:pstStatus AND Invoice_Date__c>= :sDate AND Invoice_Date__c<= :eDate limit 1000',
                         new Map<String, Object> {'pstStatus' => true, 'sDate' => startDate, 'eDate' => endDate});
    }
    
    /**
* @Description : get list of vendor invoices selected for posting
*/
    public static List<Vendor_Invoice__c> getListOfSelectedInvoicesForPosting(List<Vendor_Invoice__c> vendInvList)
    {
        List<Vendor_Invoice__c> vendInvToBePosted = new List<Vendor_Invoice__c>();
        for(Vendor_Invoice__c unpInv :vendInvList){if(unpInv.Post_Status__c) vendInvToBePosted.add(unpInv);}
        return vendInvToBePosted;
    }
    
    /**
* @Description : check for the total amount of vendor invoice is equal to sum vendor invoice line amount or not
*/
    public static List<Vendor_Invoice__c> checkAmount(List<Vendor_Invoice__c> vendInv, String amountEqualOrNot)
    {
        List<Id> idList = new List<Id>();
        for(Vendor_Invoice__c venInvObj :vendInv) idList.add(venInvObj.id);
        List<Vendor_Invoice__c> vendInvObj = new cmsft_vendorInvoiceTriggerSelector().getVendorInvoicesWithLinesAmountEqual(idList, amountEqualOrNot);
        return vendInvObj;
    }
    
    /**
    * @Description : mark the post status as true
    */
    public static List<Vendor_Invoice__c> markInvoicePostStatusChecked(List<Vendor_Invoice__c> unpostedVendInv, List<Vendor_Invoice__c> InvListToChangePS)
    {
        Map<Id, Vendor_Invoice__c> InvListToChangePSMap = new Map<Id, Vendor_Invoice__c>(InvListToChangePS);
        for(Vendor_Invoice__c vendInvObj :unpostedVendInv)
        {  
            if(InvListToChangePSMap.containsKey(vendInvObj.id))
                vendInvObj.Post_Status__c = true;
        }
        return unpostedVendInv;
    }

    /**
    * @Description : bussiness logic behind change post date of journal entry
    */
    public static void changePostDateOfFJE(List<Financial_Journal_Entry__c> finJeEntry)
    {
        Map<Id, Financial_Journal_Entry__c> finIds = new Map<Id, Financial_Journal_Entry__c>();
        for(Financial_Journal_Entry__c finJeObj :finJeEntry) {finIds.put(finJeObj.id, finJeObj);}
        List<Vendor_Invoice__c> vendInvListForThisFinEntry = Data.read('Select Id, Post_Date__c, Journal_Entry__c from Vendor_Invoice__c where Journal_Entry__c in :finId', new Map<String, Object> {'finId' => finIds.Keyset()});
        List<Financial_Journal_Line__c> financialJournalLinesList = Data.read('Select Id, Posted__c, Post_Date__c, Financial_Journal_Entry__c from Financial_Journal_Line__c where Financial_Journal_Entry__c in :finId', new Map<String, Object> {'finId' => finIds.Keyset()});
        
        Map<Id, List<Vendor_Invoice__c>> vendorInvoices = new Map<Id, List<Vendor_Invoice__c>>();
        Map<Id, List<Financial_Journal_Line__c>> finJList = new Map<Id, List<Financial_Journal_Line__c>>();

        // fill the vendorInvoices map
        for(Vendor_Invoice__c vendInv :vendInvListForThisFinEntry) {
            if(vendorInvoices.get(vendInv.Journal_Entry__c)==null)
                vendorInvoices.put(vendInv.Journal_Entry__c, new List<Vendor_Invoice__c>());
            vendorInvoices.get(vendInv.Journal_Entry__c).add(vendInv);
        }

        // fill the finJList map
        for(Financial_Journal_Line__c finJl :financialJournalLinesList) {
            if(finJList.get(finJl.Financial_Journal_Entry__c)==null)
                finJList.put(finJl.Financial_Journal_Entry__c, new List<Financial_Journal_Line__c>());
            finJList.get(finJl.Financial_Journal_Entry__c).add(finJl);
        }

        List<Vendor_Invoice__c> vendorInvoicesToUpdate = new List<Vendor_Invoice__c>();
        List<Financial_Journal_Line__c> finJListToUpdate = new List<Financial_Journal_Line__c>();

        for(Id finObjId :finIds.Keyset())
        {
            if(vendorInvoices.get(finObjId)!=null)
            for(Vendor_Invoice__c vendInv : vendorInvoices.get(finObjId))
            {
                vendInv.Post_Date__c = finIds.get(finObjId).Post_Date__c;
                vendorInvoicesToUpdate.add(vendInv);
            }
            if(finJList.get(finObjId)!=null)
            for(Financial_Journal_Line__c finJL :finJList.get(finObjId))
            {
                finJL.Post_Date__c = finIds.get(finObjId).Post_Date__c;
                finJListToUpdate.add(finJL);
            }
        }

        Data.modify(finIds.values());
        Data.modify(vendorInvoicesToUpdate);
        Data.modify(finJListToUpdate);
    }
    
    /**
    * @Description : logic behind post vendor invoices
    * @param : pass the list of vendor invoices
    */
    public static void postInvoice(List<Vendor_Invoice__c> vendInvData, Date PostDate, Date endDate)
    {
        
        Map<Id, SObject> DefaultAPFinAccountList = new cmsft_FinancialAccountSelector().selectAllFinancialAccount();
        List<postInvoiceStructure> postInvoiceList = new List<postInvoiceStructure>();
        
        // get the default AP account from TXN to financial mapping object
        List<Default_Account__c> defaultAPMapping = new cmsft_DefaultAccountSelector().selectByPassedCondition('Default_Type_Name__c=\'Accounts Payable\'');
        
        Financial_Account__c DefaultAPFinAccount;
        
        // check size of list, and assign it to DefaultAPFinAccount
        if(defaultAPMapping.size()>0) 
            DefaultAPFinAccount = (Financial_Account__c)DefaultAPFinAccountList.get(defaultAPMapping.get(0).Financial_Account__c); 
        
        // lists to be inserted after loop
        List<Financial_Journal_Line__c> finLineList = new List<Financial_Journal_Line__c>();
        List<Vendor_Invoice_Payment__c> vendInvPayment = new List<Vendor_Invoice_Payment__c>();
        List<Id> vendInvIdsList = new List<Id>();
        
        // loop to fill list with vendor invoice ids
        for(Vendor_Invoice__c vendObj :vendInvData) vendInvIdsList.add(vendObj.id);
        
        // Query vendor invoices having id in list vendInvIdsList with data of vendor invoice lines child records
        List<Vendor_Invoice__c> vendInvLines = new cmsft_vendorInvoiceTriggerSelector().getVendorInvoiceWithLines(vendInvIdsList);
        
        // prepare financial entry
        Financial_Journal_Entry__c fje = new Financial_Journal_Entry__c();
        fje.Post_Date__c = PostDate;
        fje.Description__c = 'Vendor Invoices '+endDate.format();
        fje.Posted__c = true;
        
        // loop over result of query
        for(Vendor_Invoice__c vendInv : vendInvLines){
            postInvoiceStructure postInvoiceStructureObject;
            List<Financial_Journal_Line__c> creditFinLineList = new List<Financial_Journal_Line__c>();
            List<Financial_Journal_Line__c> debitFinLineList = new List<Financial_Journal_Line__c>();

            // Debit financial entries
            List<postInvoiceLineStructure> postInvoiceLineStructureList = new List<postInvoiceLineStructure>();
            
            //get all use taxes from database.
            double TotalTax = 0;
            
            List<Tax_To_Account_Mapping__c> allMappings = (List<Tax_To_Account_Mapping__c>)Data.read(
            	'select UseTax_Value__c ,UseTax_Name__c, Financial_Accounts__c  '+
            	'from Tax_To_Account_Mapping__c where UseTax_Name__c!=\'\'',
            	new Map<String,Object> {
            	}
        	); 
            for (Tax_To_Account_Mapping__c Maping : allMappings){
                TotalTax += double.valueOf(Maping.UseTax_Value__c);
            }
            
            // prepare debit enteries for all the types from vendor invoice lines
            for(Vendor_Invoice_Line__c vendInvoiceLine :vendInv.Vendor_Invoice_Lines__r){
                postInvoiceLineStructure postinvLineStrucObj;
                Financial_Journal_Line__c debitFjl = new Financial_Journal_Line__c();
                debitFjl.Financial_Account__c = vendInvoiceLine.Financial_Account__c;
                double amountForJE=vendInvoiceLine.Amount__c;
                if(vendInvoiceLine.Use_Tax__c == true){
                	amountForJE += (amountForJE * TotalTax) / 100;   
                }
                if(((Financial_Account__c)DefaultAPFinAccountList.get(vendInvoiceLine.Financial_Account__c)).Debit_Credit__c=='Credit'){
                    debitFjl.Amount__c = -amountForJE;
                }
                else{
                    debitFjl.Amount__c = amountForJE;
                }
                debitFjl.Posted__c = true;
                debitFjl.Description__c = vendInv.Vendor__r.Name+' '+vendInv.Invoice_Number__c;
                debitFjl.Post_Date__c = PostDate;
                finLineList.add(debitFjl);
                // store the debit financial lines with vendor invoice line
                postinvLineStrucObj = new postInvoiceLineStructure(vendInvoiceLine, debitFjl); 
                postInvoiceLineStructureList.add(postinvLineStrucObj);
                Vendor_Invoice_Payment__c payNewObj= new Vendor_Invoice_Payment__c(Vendor_Invoice__c=vendInv.id, Vendor_Invoice_Line__c=vendInvoiceLine.id);
                if(vendInvoiceLine.Payment_Type__c=='Credit Card' || vendInvoiceLine.Payment_Type__c=='ACH'){
                    payNewObj.Amount_Paid__c=vendInvoiceLine.Amount__c;
                }
                vendInvPayment.add(payNewObj);   
            }
            
            // add complete item in postInvoiceStructureObject
            postInvoiceStructureObject = new postInvoiceStructure(vendInv, postInvoiceLineStructureList, creditFinLineList);
            postInvoiceList.add(postInvoiceStructureObject);
            
            // credit financial entry declaration 
            Financial_Journal_Line__c crefinJLIfCheckPT;
            for(Vendor_Invoice_Line__c vendInvoiceLine :vendInv.Vendor_Invoice_Lines__r){
                
                // credit financial line
                Financial_Journal_Line__c creFjl = new Financial_Journal_Line__c();
                creFjl.Posted__c = true;
                creFjl.Post_Date__c = PostDate;
                creFjl.Description__c = vendInv.Vendor__r.Name+' '+vendInv.Invoice_Number__c;
                if(vendInvoiceLine.Payment_Type__c=='check'){
                    
                    // throw error to user if Default account not found
                    if(DefaultAPFinAccount==null) throw new Utility.CustomException('Posting Can not be done. Default Account Payable not found. Please add it and try again.');
                    creFjl.Financial_Account__c = DefaultAPFinAccount.id;
                    if(DefaultAPFinAccount.Debit_Credit__c=='Credit'){
                        creFjl.Amount__c = vendInvoiceLine.Amount__c;
                    }
                    else{
                        creFjl.Amount__c = -vendInvoiceLine.Amount__c;
                    }
                }
                else if(vendInvoiceLine.Payment_Type__c=='Credit Card' || vendInvoiceLine.Payment_Type__c=='ACH'){
                    
                    //if credit card then credit from payment financial account
                    creFjl.Financial_Account__c = vendInvoiceLine.Payment_Financial_Account__c;
                    Financial_Account__c DefaultAPFinAccount1 = (Financial_Account__c) DefaultAPFinAccountList.get(creFjl.Financial_Account__c);
                    if(DefaultAPFinAccount1.Debit_Credit__c=='Credit'){
                        creFjl.Amount__c = vendInvoiceLine.Amount__c;
                    }
                    else{
                        creFjl.Amount__c = -vendInvoiceLine.Amount__c;
                    }
                }
                //author : kiran@3embed.com
                //check if use tax check box is checked in invoice line 
                double totalTaxValue=0;
                if(vendInvoiceLine.Use_Tax__c == true){
                    for (Tax_To_Account_Mapping__c Maping : allMappings){
                        Financial_Journal_Line__c useTaxFJL = new Financial_Journal_Line__c();
                		useTaxFJL.Posted__c = true;
                		useTaxFJL.Post_Date__c = PostDate;
                		useTaxFJL.Description__c = vendInvoiceLine.Name+' '+vendInv.Invoice_Number__c;
                        double useTaxAmountForJE = (vendInvoiceLine.Amount__c * double.valueOf(Maping.UseTax_Value__c)) / 100;
                    	Financial_Account__c TaxAccount = (Financial_Account__c) DefaultAPFinAccountList.get(Maping.Financial_Accounts__c);
                    	useTaxFJL.Financial_Account__c=Maping.Financial_Accounts__c;
                    	if(TaxAccount.Debit_Credit__c=='Credit'){
                    	    useTaxFJL.Amount__c = useTaxAmountForJE;
                    	}
                    	else{
                    	    useTaxFJL.Amount__c = -useTaxAmountForJE;
                    	}
                    	creditFinLineList.add(useTaxFJL); 
                    	finLineList.add(useTaxFJL);
                    }
                }
                // adding in this list so that this can be passed in postInvoiceStructure constructor to store the mapping of vendor invoice and financial entry
                creditFinLineList.add(creFjl); 
                
                // adding this credit fin line to list that can be inserted later   
                finLineList.add(creFjl);
            }
        }
        
        // insert all the fin journal lines, fin entry and vendor inv payment once
        Data.create(finLineList);
        
        // check for Financial Journal Entry create permission else throw exception to the caller
        Data.create(fje);
        
        // check for Vendor Invoice Payment create permission else throw exception to the caller
        Data.create(vendInvPayment);
        
        // list of vendor invoice and vendor invoice line to update
        List<Vendor_Invoice__c> vendInvListToUpdate = new List<Vendor_Invoice__c>();
        List<Vendor_Invoice_Line__c> venInvLineListToUpdate = new List<Vendor_Invoice_Line__c>();
        List<Financial_Journal_Line__c> finJLLineListToUpdate = new List<Financial_Journal_Line__c>();
        
        // loop to fill the ids in vendor invoice, vendor invoice line and financial journal lines
        for(postInvoiceStructure pInvoiceStructure :postInvoiceList){
            Vendor_Invoice__c vi = pInvoiceStructure.vendInv;
            vi.Journal_Entry__c= fje.id;
            vi.Post_Status__c = true;
            vi.Post_Date__c = PostDate;
            vendInvListToUpdate.add(vi);
            for(Financial_Journal_Line__c credFinancialJLOne :pInvoiceStructure.crefinJL){
                credFinancialJLOne.Financial_Journal_Entry__c = fje.id;
                finJLLineListToUpdate.add(credFinancialJLOne);
            }
            for(postInvoiceLineStructure invLineStructObj :pInvoiceStructure.invLineStructureList){
                Vendor_Invoice_Line__c vendInvLineObj = invLineStructObj.vendInvLine;
                vendInvLineObj.Financial_Journal_Line__c = invLineStructObj.debfinJL.id;
                vendInvLineObj.Posted__c = true;
                venInvLineListToUpdate.add(vendInvLineObj);
                invLineStructObj.debfinJL.Financial_Journal_Entry__c = fje.id;
                finJLLineListToUpdate.add(invLineStructObj.debfinJL);
            }
        }
        
        // update the vendor invoice after filling journal entry id and vendor invoice line after filling journal lines id and journal lines after filling financial journal entry line id
        Data.modify(vendInvListToUpdate);
        
        // check for vendor invoice line edit permission else throw exception to the caller
        Data.modify(venInvLineListToUpdate);
        
        // check for Financial Journal Line edit permission else throw exception to the caller
        Data.modify(finJLLineListToUpdate);
    }
    
    // structure for storing vendor invoice, journal lines, journal entry so that ids can be updated easily
    class postInvoiceStructure{
        Vendor_Invoice__c vendInv;
        List<postInvoiceLineStructure> invLineStructureList;
        List<Financial_Journal_Line__c> crefinJL;
        
        public postInvoiceStructure(Vendor_Invoice__c vendInv, List<postInvoiceLineStructure> invLineStructureList, List<Financial_Journal_Line__c> crefinJL){
            this.vendInv = vendInv;
            this.invLineStructureList = invLineStructureList;
            this.crefinJL = crefinJL;
        }
    }
    
    // structure for storing vendor invoice line and journal lines
    class postInvoiceLineStructure{
        Vendor_Invoice_Line__c vendInvLine;
        Financial_Journal_Line__c debfinJL;
        public postInvoiceLineStructure (Vendor_Invoice_Line__c vendInvLine, Financial_Journal_Line__c debfinJL){
            this.vendInvLine = vendInvLine;
            this.debfinJL = debfinJL;
        }
    }
    
}