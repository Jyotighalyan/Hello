/*
@Name            : RESTServices
@Author          : cyoungmark@foretees.com
@Date            : 10/09/2017
@Description     : Holds all REST methods for web services
*/
@RestResource(urlMapping='/RESTServices/*')
global with sharing class RESTServices{
    private static Set<String> cSetActiveStatuses = new Set<String>{'Active','Reinstated'};
    public static Map<String, Schema.RecordTypeInfo> TXNrecordTypes = new Map<String,Schema.RecordTypeInfo>();
    
    /*
    @Name   :httpGet
    @Description :Calls the appropriate methods based on the function parameter
    */
    @HttpGet
    global static String httpGet() {
        String strReturn = null;
        String function = RestContext.request.params.get('function');
        if(function == 'getMembers'){
            strReturn = getMembers();
        }else if(function == 'getGuests'){
            strReturn = getGuests();
        }else if(function == 'getEmployees'){
            strReturn = getEmployees();
        }else if(function == 'getVendors'){
            strReturn = getVendors();
        }else if(function == 'getChargeItems'){
            strReturn = getChargeItems();
        } else if(function == 'getTaxAndServiceAmounts'){
            strReturn = getTaxAndServiceAmounts();
        } 
        return strReturn;
    }
    
    @HttpPost
    global static String httpPost() {
        TXNrecordTypes = Schema.SObjectType.TXN__c.getRecordTypeInfosByName();
        String strReturn = null;
        system.debug('in httpPost: ' + RestContext.request);
        String function = RestContext.request.params.get('function');
        if(function == 'updateTicket'){
            strReturn = updateTicket();
        } else if (function == 'memberPayment') {
            strReturn = memberPayment();
        } else if (function == 'memberRefund') {
            strReturn = memberRefund();
        }
        return strReturn;
    }
    
    /*
    @Name   :updateTicket
    @Description :creates transactions from ticket
    */
    private static String updateTicket() {
        List<TXN__c> TXNsToInsert = new List<TXN__c>();
        updateTicketJSON reqJSON;
        
        reqJSON = (updateTicketJSON) JSON.deserialize(RestContext.request.requestBody.toString(), updateTicketJSON.class);
        
        system.debug('in httpPost: ' + RestContext.request);
        
        system.debug('payload: ' + reqJSON.ticket_no + ' ' + reqJSON.ticket_line + ' ' + reqJSON.member_id + ' ' + reqJSON.item_id + ' ' + reqJSON.quantity + ' ' + 
                     reqJSON.net_total + ' ' + reqJSON.service_charge + ' ' + reqJSON.tax + ' ' + reqJSON.line_update_date + ' ' + 
                     reqJSON.pos_terminal + ' ' + reqJSON.is_open + ' ' + reqJSON.ticket_owner);
        
        response RESTResponse = new response();
                
        List<Contact> currentContactList = Data.read('SELECT Bill_To_Member__c FROM Contact WHERE Id =:mem_id', new Map<String, String>{
            'mem_id' => reqJSON.member_id
        });
            
        if (currentContactList.size() > 0) {
            Contact currentContact = currentContactList[0];
            try {
                TXN__c newTXN = new TXN__c();
                newTXN.Amount__c = Double.valueOf(reqJSON.net_total);
                if (currentContact.Bill_To_Member__c != null) {
                    newTXN.Bill_To_Member__c = currentContact.Bill_To_Member__c;
                } else {
                    newTXN.Bill_To_Member__c = reqJSON.member_id;
                }
                newTXN.Customer__c = reqJSON.member_id;
                newTXN.Quantity__c = Decimal.valueOf(reqJSON.quantity);
                newTXN.Service_Charge__c = Decimal.valueOf(reqJSON.service_charge);
                newTXN.Tax__c = Decimal.valueOf(reqJSON.tax);
                newTXN.Date__c = Date.parse(reqJSON.line_update_date);
                newTXN.employee__c = reqJSON.ticket_owner;
                newTXN.Ticket_Number__c = reqJSON.ticket_no;
                newTXN.Ticket_Line__c = reqJSON.ticket_line;
                newTXN.Charge_Item__c = reqJSON.item_id;
                newTXN.POS_Terminal__c = reqJSON.pos_terminal;
                newTXN.RecordTypeId = TXNrecordTypes.get('Charge').getRecordTypeId();
                //newTXN.Is_Parent__c = false;
                
                TXNsToInsert.add(newTXN);
                
                if (reqJSON.TaxOrServiceCharges.size() > 0) {
                    system.debug('taxes or service charges: ' + reqJSON.TaxOrServiceCharges);
                    for (TaxOrServiceCharge txn : reqJSON.TaxOrServiceCharges) {
                        TXN__c taxOrServiceChargeTXN = new TXN__c();
                        taxOrServiceChargeTXN.Amount__c = Double.valueOf(txn.amount);
                        taxOrServiceChargeTXN.Customer__c = reqJSON.member_id;
                        taxOrServiceChargeTXN.Quantity__c = 1.00;
                        taxOrServiceChargeTXN.Date__c = Date.parse(reqJSON.line_update_date);
                        taxOrServiceChargeTXN.employee__c = reqJSON.ticket_owner;
                        taxOrServiceChargeTXN.Ticket_Number__c = reqJSON.ticket_no;
                        taxOrServiceChargeTXN.Ticket_Line__c = reqJSON.ticket_line;
                        taxOrServiceChargeTXN.Charge_Item__c = reqJSON.item_id;
                        taxOrServiceChargeTXN.POS_Terminal__c = reqJSON.pos_terminal;
                        taxOrServiceChargeTXN.RecordTypeId = TXNrecordTypes.get(txn.type).getRecordTypeId();
                        TXNsToInsert.add(taxOrServiceChargeTXN);
                    }
                }
                system.debug('txnstoinsert: ' + TXNsToInsert);
                data.create(TXNsToInsert);
                
                //newTXN.
                RESTResponse.statusCode = '200';
                RESTResponse.status = 'success';
                RESTResponse.message = newTXN.Name;
            } catch (Exception e ) {
                RESTResponse.statusCode = '400';
                RESTResponse.status = 'error';
                RESTResponse.message = e.getMessage();
            }
        } else {
            RESTResponse.statusCode = '400';
            RESTResponse.status = 'error';
            RESTResponse.message = 'member_id is invalid';
        }
        return JSON.serialize(RESTResponse);
    }
    
    /*
    @Name   :memberPayment
    @Description :Creates a payment
    */
    private static String memberPayment() {
        
        memberPayment reqJSON;
        
        reqJSON = (memberPayment) JSON.deserialize(RestContext.request.requestBody.toString(), memberPayment.class);
        
        system.debug('in httpPost: ' + RestContext.request);
        
        response RESTResponse = new response();
        
        try {
            TXN__c newTXN = new TXN__c();
            newTXN.Amount__c = Double.valueOf(reqJSON.net_total);
            newTXN.Customer__c = reqJSON.member_id;
            newTXN.Quantity__c = Decimal.valueOf(reqJSON.quantity);
            newTXN.Date__c = Date.parse(reqJSON.line_update_date);
            newTXN.employee__c = reqJSON.ticket_owner;
            newTXN.Ticket_Number__c = reqJSON.ticket_no;
            newTXN.Ticket_Line__c = reqJSON.ticket_line;
            newTXN.Charge_Item__c = reqJSON.item_id;
            newTXN.POS_Terminal__c = reqJSON.pos_terminal;
            newTXN.Description__c = reqJSON.note;
            newTXN.Payment_Type__c = reqJSON.payment_method;
            newTXN.RecordTypeId = TXNrecordTypes.get('Payment').getRecordTypeId();
            
            data.create(newTXN);
            
            RESTResponse.statusCode = '200';
            RESTResponse.status = 'success';
            RESTResponse.message = '';
        } catch (Exception e ) {
            RESTResponse.statusCode = '400';
            RESTResponse.status = 'error';
            RESTResponse.message = e.getMessage();
        }
        return JSON.serialize(RESTResponse);
    }
    
    /*
    @Name   :memberRefund
    @Description :Creates a refund
    */
    private static String memberRefund() {
        
        memberRefund reqJSON;
        
        reqJSON = (memberRefund) JSON.deserialize(RestContext.request.requestBody.toString(), memberRefund.class);
        
        system.debug('in httpPost: ' + RestContext.request);
        
        response RESTResponse = new response();
        
        List<TXN__c> refTXN = Data.read('SELECT Id FROM TXN__c WHERE ID =:payment_ref', new Map<String, String>{
            'payment_ref' => reqJSON.payment_ref
        });
        
        if (refTXN.size() > 0) {
            try {
                TXN__c newTXN = new TXN__c();
                newTXN.Amount__c = Double.valueOf(reqJSON.net_total);
                newTXN.Customer__c = reqJSON.member_id;
                newTXN.Quantity__c = Decimal.valueOf(reqJSON.quantity);
                newTXN.Date__c = Date.parse(reqJSON.line_update_date);
                newTXN.employee__c = reqJSON.ticket_owner;
                newTXN.Ticket_Number__c = reqJSON.ticket_no;
                newTXN.Ticket_Line__c = reqJSON.ticket_line;
                newTXN.Charge_Item__c = reqJSON.item_id;
                newTXN.POS_Terminal__c = reqJSON.pos_terminal;
                newTXN.Description__c = reqJSON.note;
                newTXN.Refund_Reason__c = reqJSON.note;
                newTXN.Payment_Type__c = reqJSON.refund_method;
                newTXN.Related_To__c = refTXN[0].ID;
                newTXN.RecordTypeId = TXNrecordTypes.get('Refund').getRecordTypeId();
                
                data.create(newTXN);
                
                RESTResponse.statusCode = '200';
                RESTResponse.status = 'success';
                RESTResponse.message = '';
            } catch (Exception e ) {
                RESTResponse.statusCode = '400';
                RESTResponse.status = 'error';
                RESTResponse.message = e.getMessage();
            }
        } else {
            RESTResponse.statusCode = '400';
            RESTResponse.status = 'error';
            RESTResponse.message = 'payment_ref ID does not exist';
        }
        return JSON.serialize(RESTResponse);
    }
    
    /*
    @Name   :getChargeItems
    @Description :Returns list of charge items as a json string.
    */
    private static String getChargeItems() {
        List<Charge_Item__c> lstChargeItem = new List<Charge_Item__c>();
        
        String strQuery = 'SELECT Name,Price__c,Retail_Price__c,Item_Code__c,Description__c, Type__c'
            + ',SubType__c, LastModifiedDate'
            + ' FROM Charge_Item__c';
        lstChargeItem = Data.read(strQuery, new Map<String,String>{});
        return JSON.serialize(lstChargeItem);
    }
    public static String getTaxAndServiceAmounts() {
        List<string> allTxnTypes = new List<String>();
        List<string> allTxnSubtypes = new List<String>();
        Map<String, double> mapOfTaxesAndItsVal = new Map<String, double>();
        
        double value=0;
        Map<string,Schema.SObjectField> fieldsMap=Taxes__c.sObjectType.getDescribe().fields.getMap();
        Set<string> customHierarchyFieldNames=new  Set<string>();
        for(string field:fieldsMap.keySet()){
            Schema.SObjectField F=fieldsMap.get(field);
            Schema.DescribeFieldResult R=F.getDescribe();
            if(R.isCustom()){
                string fName=R.getName();
                Taxes__c allTaxesHSettings=Taxes__c.getInstance();
                try
                {
                    value=double.valueOf(allTaxesHSettings.get(fName));
                    mapOfTaxesAndItsVal.put(fName, value);
                }
                catch(Exception e)
                { 
                    // there are fields that aren't doubles in the Custom Setting.
                }
            }
        }
        
        
        Schema.DescribeFieldResult fieldResult = TXN__c.GlobalType__c.getDescribe(); 
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
            allTxnTypes.add(f.getLabel());
        
        Schema.DescribeFieldResult fieldResultsub = TXN__c.GlobalSubType__c.getDescribe(); 
        List<Schema.PicklistEntry> plesub = fieldResultsub.getPicklistValues();
        for( Schema.PicklistEntry f : plesub)
            allTxnSubtypes.add(f.getLabel());   
        
        List<aTableRow> dataRows=new  List<aTableRow>();
        string ChargeId='';
        string chargeName='';
        string name='';
        boolean serviceChargeApply=false;
        boolean TaxSErviceCharge=false;
        string scVal='';
        boolean TaxesOnS=false;
        
        List<TxnChargeToTaxMapping__c> datData=[SELECT Id,Name, If_Taxes_Are_Applicable__c,SubType__c,Type__c,Service_Charge_applicable__c,tax_on_service_charge__c,Taxes_applicable_on_service_charge__c,TaxId__c FROM TxnChargeToTaxMapping__c limit 50000];

        for(TxnChargeToTaxMapping__c SubTypes:datData){
            string finAccount = '';
            string defFinAccount = '';
            boolean typeExistInTxn = false;
            boolean subtypeExistInTxn = false;
            
            
            for(string txnType : allTxnTypes){
                if(txnType==string.valueOf(SubTypes.Type__c))
                    typeExistInTxn = true; 
            }
            //check for subtype existence
            for(string txnSubType: allTxnSubtypes){
                if(SubTypes.SubType__c!=null && SubTypes.SubType__c!=''){
                    if(txnSubType==string.valueOf(SubTypes.SubType__c))
                        subtypeExistInTxn = true;
                }
                else
                    subtypeExistInTxn = true;   
            }
            
            chargeName='';
            name='';
            serviceChargeApply=false;
            TaxSErviceCharge=false;
            scVal='';
            Map<String,String> taxes = new Map<String,String>();
            TaxesOnS=false;
            for(TxnChargeToTaxMapping__c dat : datData)
            {
                if(String.valueOf(dat.Type__c) == String.valueOf(SubTypes.Type__c) && String.valueOf(dat.SubType__c) == String.valueOf(SubTypes.SubType__c))
                {
                    if(dat.TaxId__c != null)
                    {
                        String val=String.valueOf(mapOfTaxesAndItsVal.get(dat.TaxId__c));
                        taxes.put(dat.TaxId__c, val);
                    }
                    
                    scVal=dat.tax_on_service_charge__c;
                    name=dat.Name;
                    serviceChargeApply=dat.Service_Charge_applicable__c;
                    TaxesOnS=dat.Taxes_applicable_on_service_charge__c;
                    TaxSErviceCharge=dat.Taxes_applicable_on_service_charge__c;
                }
            }
            
            if(taxes.size() == 0)
            {
                taxes.put('No taxes','No Taxes');
            }
            integer iii=0;
            for(aTableRow d:dataRows)
            {
                if(string.valueOf(SubTypes.Type__c)==d.Type&&string.valueOf(SubTypes.SubType__c)==d.SubType)
                {
                    iii=1;
                }
            }
            if(iii==0){
                if(typeExistInTxn==true && subtypeExistInTxn==true)
                    dataRows.add(new  aTableRow(name,'','',string.valueOf(SubTypes.Type__c),string.valueOf(SubTypes.SubType__c),taxes,serviceChargeApply,scVal,TaxSErviceCharge,finAccount,defFinAccount));
            }
        }
        system.debug(JSON.serialize(dataRows));
        return JSON.serialize(dataRows);
    }
    
    /*
    @Name   :getMembers
    @Description :Returns list of members as a json string.
    */
    private static String getMembers() {
        List<Contact> lstCon = new List<Contact>();
        String strQuery = 'SELECT Id,FirstName,LastName,Customer_Id__c,Status__c, Salutation'
            + ',BirthDate,Phone,HomePhone,Email,Account_Balance__c,FT_Photo_URL__c, RecordType.Name, SubStatus__c, LastModifiedDate'
            + ' FROM Contact'
            //+ ' WHERE ' + whereMemNum
            + ' ORDER BY LastName ASC';
        //+ ' LIMIT 100';
        //
        lstCon = Data.read('SELECT Id,FirstName,LastName,Customer_Id__c,Status__c, Salutation' +
                                             ',BirthDate,Phone,HomePhone,Email,Account_Balance__c,FT_Photo_URL__c, RecordType.Name, SubStatus__c, LastModifiedDate' +
                                             ' FROM Contact WHERE RecordType.Name = :recName', new Map<String, String>{
			'recName' => 'Member'
		});
        //lstCon = Data.read(strQuery, new Map<String,String>{});
        return JSON.serialize(lstCon);
    }
    
    private static String getEmployees() {
        List<Contact> lstCon = new List<Contact>();
        String strQuery = 'SELECT Id,FirstName,LastName,Customer_Id__c,Status__c, Salutation'
            + ',BirthDate,Phone,HomePhone,Email,Account_Balance__c,FT_Photo_URL__c, RecordType.Name, SubStatus__c, LastModifiedDate'
            + ' FROM Contact'
            + ' ORDER BY LastName ASC';
        //
        lstCon = Data.read('SELECT Id,FirstName,LastName,Customer_Id__c,Status__c, Salutation' +
                                             ',BirthDate,Phone,HomePhone,Email,Account_Balance__c,FT_Photo_URL__c, RecordType.Name, SubStatus__c, LastModifiedDate' +
                                             ' FROM Contact WHERE RecordType.Name = :recName', new Map<String, String>{
			'recName' => 'Employee'
		});
        return JSON.serialize(lstCon);
    }
    
    private static String getVendors() {
        List<Contact> lstCon = new List<Contact>();
        String strQuery = 'SELECT Id,FirstName,LastName,Customer_Id__c,Status__c, Salutation'
            + ',BirthDate,Phone,HomePhone,Email,Account_Balance__c,FT_Photo_URL__c, RecordType.Name, SubStatus__c, LastModifiedDate'
            + ' FROM Contact'
            + ' ORDER BY LastName ASC';
        //
        lstCon = Data.read('SELECT Id,FirstName,LastName,Customer_Id__c,Status__c, Salutation' +
                                             ',BirthDate,Phone,HomePhone,Email,Account_Balance__c,FT_Photo_URL__c, RecordType.Name, SubStatus__c, LastModifiedDate' +
                                             ' FROM Contact WHERE RecordType.Name = :recName', new Map<String, String>{
			'recName' => 'Vendor'
		});
        return JSON.serialize(lstCon);
    }
    
    private static String getGuests() {
        List<Contact> lstCon = new List<Contact>();
        String strQuery = 'SELECT Id,FirstName,LastName,Customer_Id__c,Status__c, Salutation'
            + ',BirthDate,Phone,HomePhone,Email,Account_Balance__c,FT_Photo_URL__c, RecordType.Name, SubStatus__c, LastModifiedDate'
            + ' FROM Contact'
            + ' ORDER BY LastName ASC';
        //
        lstCon = Data.read('SELECT Id,FirstName,LastName,Customer_Id__c,Status__c, Salutation' +
                                             ',BirthDate,Phone,HomePhone,Email,Account_Balance__c,FT_Photo_URL__c, RecordType.Name, SubStatus__c, LastModifiedDate' +
                                             ' FROM Contact WHERE RecordType.Name = :recName', new Map<String, String>{
			'recName' => 'Guest'
		});
        return JSON.serialize(lstCon);
    }
    
    private static String getStringParam(String key){
        try{
            return RestContext.request.params.get(key);
        } catch(Exception e){
            return null;
        }
    }
    
    /*private static Decimal getDecimalParam(String key){
        try{
            return Decimal.valueOf(RestContext.request.params.get(key)).setScale(2);
        } catch(Exception e){
            return 0;
        }
    }*/
    
    /*private static Long getLongParam(String key){
        try{
            return Long.valueOf(RestContext.request.params.get(key));
        } catch(Exception e){
            return -1;
        }
    }*/
    
    /*private static Integer getIntegerParam(String key){
        try{
            return Integer.valueOf(RestContext.request.params.get(key));
        } catch(Exception e){
            return 0;
        }
    }*/
    
    /*private static Boolean getBooleanParam(String key){
        try{
            return Boolean.valueOf(RestContext.request.params.get(key));
        } catch(Exception e){
            return false;
        }
    }*/
    public class response {
        public string statusCode {get;set;}
        public string status {get;set;}
        public string message {get;set;}
    }
    
    public class updateTicketJSON {
        public String ticket_no {get;set;}
        public String ticket_line {get;set;}
        public String member_id {get;set;}
        public String item_id {get;set;}
        public String quantity {get;set;}
        public String net_total {get;set;}
        public String service_charge {get;set;}
        public String tax {get;set;}
        public String line_update_date {get;set;}
        public String pos_terminal {get;set;}
        public String is_open {get;set;}
        public String ticket_owner {get;set;}
        public List<TaxOrServiceCharge> TaxOrServiceCharges {get;set;}
    }
    
    public class memberPayment {
        public String ticket_no {get;set;}
        public String ticket_line {get;set;}
        public String member_id {get;set;}
        public String item_id {get;set;}
        public String quantity {get;set;}
        public String net_total {get;set;}
        public String line_update_date {get;set;}
        public String pos_terminal {get;set;}
        public String is_open {get;set;}
        public String ticket_owner {get;set;}
        public String note {get;set;}
        public String payment_method {get;set;}
    }
    
    public class memberRefund {
        public String ticket_no {get;set;}
        public String ticket_line {get;set;}
        public String member_id {get;set;}
        public String item_id {get;set;}
        public String quantity {get;set;}
        public String net_total {get;set;}
        public String line_update_date {get;set;}
        public String pos_terminal {get;set;}
        public String is_open {get;set;}
        public String ticket_owner {get;set;}
        public String note {get;set;}
        public String refund_method {get;set;}
        public String payment_ref {get;set;}
    }
    
    public class TaxOrServiceCharge {
        public String amount {get;set;}
        public String type {get;set;}
    }
    
    public class aTableRow{
        public string Name{get;set;}
        public string Charge{get;set;}
        public string ChargeId{get;set;}
        public string Type{get;set;}
        public string SubType{get;set;}
        public Boolean SCApplicable{get;set;}
        public string SC{get;set;}
        public Map<String, String> Taxes{get;set;}
        public Boolean TaxOnSErviceCharge{get;set;}
        public string financialAccount {get; set;}
        public string defaultFinancialAccount {get; set;}
        
        public aTableRow(string txnId,string txnCharge,string txnChargeId,string txnType,string txnSubType,Map<String,String> txnTaxes,boolean txnSCApplicable,string txnSC,Boolean txnTaxOnSErviceCharge, string finAc, string defFinAc){
            Name=txnId;
            Charge=txnCharge;
            Type=txnType;
            SubType=txnSubType;
            ChargeId=txnChargeId;
            SCApplicable=txnSCApplicable;
            SC=txnSC;
            Taxes=txnTaxes;
            TaxOnSErviceCharge=txnTaxOnSErviceCharge;
            financialAccount=finAc;
            defaultFinancialAccount=defFinAc;
        }
    }
}