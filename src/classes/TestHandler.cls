@isTest
public class TestHandler{
    
    public static Integer addressCounter=0;
    public static Integer accountNumber=0;
    public static Integer contactCallCounter = 0;   
             
    @isTest
    public static Account createAccount(){
       string accountName='testAccount'+string.valueOf(accountNumber);
        //string householdName='testHoseHold'+string.valueOf(accountNumber);
        accountNumber++;
        Account a = new Account(Name=accountName);
        insert a;
        return a;
    }
    /*
    @Name :Member1
    @Description : prepare the test data for Member record.
    */
    @isTest
    public static Contact getMember1(){       
        Account act=createAccount();
        act.RecordTypeId=Utility.searchRecordType('Household', 'Account');
        update act;

        Contact c = new Contact(FirstName='Test',Suffix__c = 'Smith',LastName='Smith',Relationship__c ='Dependent',AccountId=act.Id,
            Birthdate=date.newInstance(1999,03,05),Title__c = 'Test new',Email='smith1@test.com', Customer_Id__c =string.valueOf(accountNumber));
        accountNumber++;
        try{
            insert c;
        }
        catch(Exception e ){
            c.Email = 'abc@gmail.com';
            upsert c;
        }
        return c;
    }

    /**
    * @Description : prepare the test data for Contact records.
    * @param recordtypeid that can be passed to create record with specified recordtypeid
    */
    public static Contact getContact(String rectype){
        Account act=getAccount('Household');
        Contact c = new Contact(RecordTypeId=Utility.searchRecordType(rectype, 'Contact'), FirstName='Test',Suffix__c = 'Smith',LastName='Smith',Relationship__c ='Dependent',AccountId=act.Id,
        Birthdate=date.newInstance(1999,03,05),Title__c = 'Test new',Email='smith1@test.com', Customer_Id__c =string.valueOf(accountNumber));
        accountNumber++;
        try{
            insert c;
        }
        catch(Exception e ){
            c.Email = 'abc@gmail.com';
            upsert c;
        }
        return c;
    }

    /**
    * @Description : prepare the test data for Account records.
    * @param recordtypeid that can be passed to create record with specified recordtypeid
    */
    public static Account getAccount(String rectype){
        String accountName='testAccount'+string.valueOf(accountNumber);
        //string householdName='testHoseHold'+string.valueOf(accountNumber);
        accountNumber++;
        Account a = new Account(RecordTypeId=Utility.searchRecordType(rectype, 'Account'), Name=accountName);
        insert a;
        return a;
    }
    
    /*
    @Name :getMember2
    @Description : prepare the test data for Member record.
    */
    @isTest
    public static Contact getMember2(){
        System.debug(LoggingLevel.Info, 'Create getMember2-accountNumber'+accountNumber);
        Account act=createAccount();
        act.RecordTypeId=Utility.searchRecordType('Household', 'Account');
        update act;

        Contact c = new Contact(FirstName='Test',Suffix__c = 'Smith',LastName='Smith',Relationship__c ='Primary',AccountId=act.Id,
        Birthdate=date.newInstance(1999,03,05),Title__c = 'Test new',Email='smith2@test.com', Customer_Id__c =string.valueOf(accountNumber));
        accountNumber++;
        try{ 
            insert c;
        }
        catch(Exception e){
            Account act2=createAccount();
            c.AccountId = act2.Id;
            c.Email = 'getMember2@gmail.com';
        }
        upsert c;
        return c;
    } 

    /*
    @Name :getMemAddress1
    @Description : prepare the test data for Address record.
    */
    public static Address__c getMemAddress1(Contact m){    
        Address__c a = new Address__c(Name='Test',From_Date__c=date.newInstance(1999,03,05),
                Country__c='United States',State_Province__c='NY',City__c='Lewiston',Street_1__c='102 River Road',
                Street_2__c='Apt B',Street_3__c='Street 3',Zip_Postal_Code__c='14095',Type__c='Home',Active__c = true);
        
        if(m != null){
            a.Customer__c = m.Id;
        }
        insert a;
        return a;
    }
    
    /*overiding the method getMemAddress1 because we have to generate few random address with different types.*/
    /*Author joshi*/
    public static Address__c getMemAddress1(Contact m,Boolean noDuplicate){
        string AddressType='Test Type '+string.valueOf(addressCounter);
        addressCounter++;               
        Address__c a = new Address__c(Name='Test',From_Date__c=date.newInstance(1999,03,05),
                Country__c='United States',State_Province__c='NY',City__c='Lewiston',Street_1__c='102 River Road',
                Street_2__c='Apt B',Street_3__c='Street 3',Zip_Postal_Code__c='14095',Type__c=AddressType,Active__c = true);
        
        if(m != null){
            a.Customer__c = m.Id;
        }
        insert a;
        return a;
    }
    
    /*
    @Name :getMemAddress1
    @Description : prepare the test data for Address record.
    */
    public static Address__c getMemAddress2(Contact m){
        string AddressType='Test Type '+string.valueOf(addressCounter);
        addressCounter++;        
       // delete [Select id from Address__c where Customer__c=:m.id];    
        Address__c a = new Address__c(Name='Test',From_Date__c=date.newInstance(2001,09,01),
                Country__c='United States',State_Province__c='NY',City__c='Lewiston',Street_1__c='1569 Washington Street',
                Street_2__c='789 River View Way',Active__c = true,Street_3__c='Near Plaza',Zip_Postal_Code__c='14094',Type__c='Home');                        
        if(m != null){
            a.Customer__c = m.Id;
        }
        insert a;
        return a;
    }
    
    /*overiding the method getMemAddress1 because we have to generate few random address with different types.*/
    /*Author joshi*/
    public static Address__c getMemAddress2(Contact m,Boolean noDuplicate){
        string AddressType='Test Type '+string.valueOf(addressCounter);
        addressCounter++;               
        Address__c a = new Address__c(Name='Test',From_Date__c=date.newInstance(1999,03,05),
                Country__c='United States',State_Province__c='NY',City__c='Lewiston',Street_1__c='102 River Road',
                Street_2__c='Apt B',Street_3__c='Street 3',Zip_Postal_Code__c='14095',Type__c=AddressType,Active__c = true);
        
        if(m != null){
            a.Customer__c = m.Id;
        }
        insert a;
        return a;
    }
     
    /*overiding the method because we have to generate few random address with different types.*/
    /*Author joshi*/
    public static Address__c getPersonAddress1(Contact m,Boolean noDuplicate){
        string AddressType='Test Type '+string.valueOf(addressCounter);
        addressCounter++;               
        Address__c a = new Address__c(Name='Test',From_Date__c=date.newInstance(1999,03,05),
                Country__c='United States',State_Province__c='NY',City__c='Lewiston',Street_1__c='102 River Road',
                Street_2__c='Apt B',Street_3__c='Street 3',Zip_Postal_Code__c='14095',Type__c=AddressType,Active__c = true);
        
        if(m != null){
            a.Customer__c = m.Id;
        }
        insert a;
        return a;
    }
    
    /*
    @Name :getAttachment
    @Description : prepare the test data for Attachment record.
    */
    public static Attachment getAttachment(sObject p) {          
        Blob b = Blob.valueOf('Test Data');            
        Attachment attachment = new Attachment();  
        attachment.ParentId = p.Id;  
        attachment.Name = 'Test Attachment for Parent';  
        attachment.Body = b;        
        insert attachment;
        return attachment;
    }
    
    @isTest
    public static Financial_Account__c getFinancialAccount(){
        Financial_Account__c fa = new Financial_Account__c(A_P_Trade__c=true,Name='Test',Account_Number__c='asd32sd',Balance_Sheet_Type__c='Current Assets',
                Balance_Sheet_Sub_Type__c='Accounts Receivables',Category__c='Assets',
                Statement_of_Activities_Type__c='Operating Expenses',Statement_of_Activities_Sub_Type__c='Food');
        insert fa;
        return fa;
    }

    @isTest
    public static Financial_Account__c getFinancialAccount1(){
        Financial_Account__c fa = new Financial_Account__c(A_P_Trade__c=false,Name='Test1',Account_Number__c='asd32sd',Balance_Sheet_Type__c='Current Assets',
                Balance_Sheet_Sub_Type__c='Accounts Receivables',Category__c='Assets',
                Statement_of_Activities_Type__c='Operating Expenses',Statement_of_Activities_Sub_Type__c='Food');
        insert fa;
        return fa;
    }

    public static Financial_Account__c getFinancialAccountWithChecks(Id locationId){
        Financial_Account__c fa = new Financial_Account__c(A_P_Trade__c=false,Name='TestCheck',Account_Number__c='asd32',Balance_Sheet_Type__c='Current Assets',
                Balance_Sheet_Sub_Type__c='Accounts Receivables',Category__c='Assets',Operating_Checks__c = true,
                Retained_Earnings__c = true, Use_Tax__c = true,Location__c=locationId,
                Statement_of_Activities_Type__c='Operating Expenses',Statement_of_Activities_Sub_Type__c='Food');
        insert fa;
        return fa;
    }

    @isTest
    public static Charge_Item__c getChargeItem(){
        Charge_Item__c item = new Charge_Item__c(RecordTypeId=Utility.searchRecordType('Event Menu', 'Charge_Item__c'),Name='Test Item',Type__c='Breakfast',
            Price__c=5);
        return item;
    }

    @isTest
    public static Default_Account__c getDefaultAccount(){
        Default_Account__c da = new Default_Account__c(Default_Type_Name__c='Bank Account');
        return da;
    }

    @isTest
    public static Location__c getLocation(){
        Location__c loc = new Location__c(Name='Test Location', Location__c='North Campus', Status__c='In Use');
        insert loc;
        return loc;
    }   

    @isTest
    public static Event__c getEvent(){
        
        Account act = getAccount('Household');
        String EmailId = 'smith'+String.valueOf(contactCallCounter)+'@test.com';
        contactCallCounter++;
        Contact contact = new Contact(RecordTypeId=Utility.searchRecordType('Member', 'Contact'), FirstName='Test',Suffix__c = 'Smith',LastName='Smith',Relationship__c ='Dependent',AccountId=act.Id,
        Birthdate=date.newInstance(1999,03,05),Title__c = 'Test new',Email=EmailId, Customer_Id__c=string.valueOf(accountNumber));
        insert contact;

        Event__c event = new Event__c();
        event.Name = 'Test Event';
        event.Location__c = getLocation().id;
        event.Status__c = 'Tentative';
        event.Sponsoring_Customer__c = contact.id;
        event.SponsoringMember__c = contact.Id;
        event.StartTime__c = System.now();
        event.EndTime__c = System.now().addHours(2);
        event.Setup_Time__c = 'Half Hour';
        event.Cleanup_Time__c = 'Half Hour';
        event.Contract_Due_Date__c = System.today();
        event.Max_Seats__c = 20;
        insert event;
        
        return event;
    }   
}