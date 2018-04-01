@isTest
public class TestRestServices {
    
    /*@testSetup static void setup() {
        Id householdId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        
        Account acct = new Account(Name='testAcct', RecordTypeId=householdId);
        insert acct;
        
        Contact con = new Contact(LastName='test', AccountId=acct.id);
        insert con;
    }*/
 
   static testMethod void  testUpdateTicket(){
   
       RESTServices.TaxOrServiceCharge TorSC = new RESTServices.TaxOrServiceCharge();
       TorSC.amount = '1.50';
       TorSC.type = 'Taxes';
       
       List<RESTServices.TaxOrServiceCharge> TorSCList = new List<RESTServices.TaxOrServiceCharge>();
       
       TorSCList.add(TorSC);
       
       Id householdId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
       
       Account acct = new Account(Name='testAcct', RecordTypeId=householdId);
       insert acct;
       
       Contact con = new Contact(LastName='test', AccountId=acct.id);
       insert con;
   
       RESTServices.updateTicketJSON reqst=new RESTServices.updateTicketJSON();
       reqst.ticket_no = '1';
       reqst.ticket_line = '2';
       reqst.member_id = String.valueOf(con.id);
       reqst.item_id = 'a0A46000002ZwxA';
       reqst.quantity = '1';
       reqst.net_total = '10.00';
       reqst.service_charge = '1.00';
       reqst.tax = '1.00';
       reqst.line_update_date = '10/24/2017';
       reqst.pos_terminal = '12';
       reqst.is_open = 'false';
       reqst.ticket_owner = '0034600000vBZ3p';
       reqst.TaxOrServiceCharges = TorSCList;
   
       
       String JsonMsg=JSON.serialize(reqst);
       
       Test.startTest();
       
       //As Per Best Practice it is important to instantiate the Rest Context 
       
       RestRequest req = new RestRequest(); 
       RestResponse res = new RestResponse();
             
       req.requestURI = '/services/apexrest/RESTServices?function=updateTicket';  //Request URL
       req.httpMethod = 'POST';//HTTP Request Type
       req.requestBody = Blob.valueof(JsonMsg);
       RestContext.request = req;
       RestContext.response= res;
    
       req.addParameter('function', 'updateTicket');
       
       String ticket = RESTServices.httpPost();
    
       //MyRestResourcedemo.ResponseWrapper resp =new  
       //MyRestResourcedemo.ResponseWrapper(); 
       //resp=MyRestResourcedemo.doPost(reqst); //Call the Method of the Class with Proper       Constructor 
       //System.assert(resp.statusMessage.contains('Test success message'));//Assert the response has message as expected 
       //System.assert(resp.statusCode.contains('Done'));
       //System.assert(resp.acct.Id!=null);//Assert that the Account is inserted and has Id
       Test.stopTest();
   
   }
    
    static testMethod void  testMemberRefund(){
   
       RESTServices.TaxOrServiceCharge TorSC = new RESTServices.TaxOrServiceCharge();
       TorSC.amount = '1.50';
       TorSC.type = 'Taxes';
       
       List<RESTServices.TaxOrServiceCharge> TorSCList = new List<RESTServices.TaxOrServiceCharge>();
       
       TorSCList.add(TorSC);
        
        Id householdId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        Id txnId = Schema.SObjectType.TXN__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId();
        TXN__c txn = new TXN__c(Amount__c=-10.00,recordtypeid=txnId );
        insert txn;
        Account acct = new Account(Name='testAcct', RecordTypeId=householdId);
        insert acct;
        
        Contact con = new Contact(LastName='test', AccountId=acct.id);
        insert con;
        
        //Map<String, String> typesubtype = TxnTestUtility.getTypeAndSubtype();
        //system.debug(typesubtype);
        //for (String typ : typesubtype.keySet()) {
        //    TxnChargeToTaxMapping__c txnchargetotax = TxnTestUtility.getTaxMapping(typ, typesubtype.get(typ)) ;
       // }
        //TXN__c txn = TxnTestUtility.createChargeOnMember(con, 10.00);
       
   
       RESTServices.memberRefund reqst=new RESTServices.memberRefund();
       reqst.ticket_no = '1';
       reqst.ticket_line = '2';
       reqst.member_id = String.valueOf(con.id);
       //reqst.item_id = txnId;
       reqst.quantity = '1';
       reqst.net_total = '10.00';
       reqst.line_update_date = '10/24/2017';
       reqst.pos_terminal = '12';
       reqst.is_open = 'false';
       reqst.ticket_owner = '0034600000vBZ3p';
       //reqst.TaxOrServiceCharges = TorSCList;
       reqst.payment_ref = String.valueOf(txn.id);
   
       
       String JsonMsg=JSON.serialize(reqst);
       
       Test.startTest();
       
       //As Per Best Practice it is important to instantiate the Rest Context 
       
       RestRequest req = new RestRequest(); 
       RestResponse res = new RestResponse();
             
       req.requestURI = '/services/apexrest/RESTServices?function=memberRefund';  //Request URL
       
       req.httpMethod = 'POST';//HTTP Request Type
       req.requestBody = Blob.valueof(JsonMsg);
       RestContext.request = req;
       RestContext.response= res;
    
        req.addParameter('function', 'memberRefund');
        
        String ticket = RESTServices.httpPost();
    
       Test.stopTest();
   
   }
    
    static testMethod void  testMemberPayment(){
   

       
       
       
        Id householdId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        
        Account acct = new Account(Name='testAcct', RecordTypeId=householdId);
        insert acct;
        
        Contact con = new Contact(LastName='test', AccountId=acct.id);
        insert con;
        
        RESTServices.memberPayment reqst=new RESTServices.memberPayment();
        reqst.ticket_no = '1';
        reqst.ticket_line = '2';
        reqst.member_id = String.valueOf(con.id);
        reqst.item_id = 'a0A46000002ZwxA';
        reqst.quantity = '1';
        reqst.net_total = '10.00';
        reqst.line_update_date = '10/24/2017';
        reqst.pos_terminal = '12';
        reqst.is_open = 'false';
        reqst.ticket_owner = '0034600000vBZ3p';
        reqst.payment_method = 'Cash';
        reqst.note = 'Test note';
        
        
        String JsonMsg=JSON.serialize(reqst);
        
        Test.startTest();
        
        //As Per Best Practice it is important to instantiate the Rest Context 
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/RESTServices?function=memberPayment';  //Request URL
        req.httpMethod = 'POST';//HTTP Request Type
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response= res;
        
        req.addParameter('function', 'memberPayment');
        
        String ticket = RESTServices.httpPost();
        
        Test.stopTest();
        
   }
    
    static testMethod void  testHttpGet(){
          
       
       //As Per Best Practice it is important to instantiate the Rest Context 
       
       RestRequest req = new RestRequest(); 
       RestResponse res = new RestResponse();
             
       req.requestURI = '/services/apexrest/RESTServices?function=getMembers';  //Request URL
       req.httpMethod = 'GET';//HTTP Request Type
       //req.requestBody = Blob.valueof(JsonMsg);
       RestContext.request = req;
       RestContext.response= res;
        
        RESTServices service = new RESTServices();
    
    	Test.startTest();
        req.addParameter('function', 'getMembers');
        
        String members = RESTServices.httpGet();
        
        req.addParameter('function', 'getGuests');
        
        req.requestURI = '/services/apexrest/RESTServices?function=getGuests';  //Request URL
        
        String guests = RESTServices.httpGet();
        
        req.requestURI = '/services/apexrest/RESTServices?function=getEmployees';  //Request URL
        req.addParameter('function', 'getEmployees');
        
        String employees = RESTServices.httpGet();
        
        req.requestURI = '/services/apexrest/RESTServices?function=getVendors';  //Request URL
        req.addParameter('function', 'getVendors');
        
        String vendors = RESTServices.httpGet();
        
        req.requestURI = '/services/apexrest/RESTServices?function=getChargeItems';  //Request URL
        req.addParameter('function', 'getChargeItems');
        
        String chargeitems = RESTServices.httpGet();
        
        TxnChargeToTaxMapping__c newtc = new TxnChargeToTaxMapping__c(Type__c='ACH');
        insert newtc;
        req.requestURI = '/services/apexrest/RESTServices?function=getTaxAndServiceAmounts';  //Request URL
        req.addParameter('function', 'getTaxAndServiceAmounts');
        
        String taxes = RESTServices.httpGet();
        
       Test.stopTest();
   
   }
 }