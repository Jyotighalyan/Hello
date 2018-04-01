@isTest
public class ManageAddressesControllerTest {

    public static String AccountMemberId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public static string ContactMemberId = Schema.SObjectType.contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();

    private testMethod static void runAll() {
        Address__c add=new Address__c();
        ApexPages.StandardController sc=new ApexPages.StandardController(add);
        ManageAddressesController c = new ManageAddressesController(sc);
        PageReference manageAdddressPage=Page.manageAddresses;
        Test.setCurrentPage(manageAdddressPage);
        c.deletePopupBoolean = false;
        c.isMember = true;
        c.DeleteAddress();
        Account account=TxnTestUtility.createAccount(AccountMemberId);
        Contact primaryMember=TxnTestUtility.createMember(account,'Primary',ContactMemberId);
        Address__c homeAddress=TxnTestUtility.getAddress(primaryMember,'Home');
        ApexPages.currentPage().getParameters().put('Data',homeAddress.id);
        c.EditAddress();
        PageReference p = c.saveNewDependentAddress();
    }

    private testMethod static void AddAddressProcess() {
        Address__c add=new Address__c();
        ApexPages.StandardController sc=new ApexPages.StandardController(add);
        Account account=TxnTestUtility.createAccount(AccountMemberId);
        Contact primaryMember=TxnTestUtility.createMember(account,'Primary',ContactMemberId);

        Contact spousePartnerMember = new Contact(FirstName='Test', LastName='spouseMember', RecordTypeId=ContactMemberId, AccountId=account.id);
        spousePartnerMember.Relationship__c = 'Spouse/Partner';
        insert spousePartnerMember;

        Address__c homeAddress=TxnTestUtility.getAddress(primaryMember,'Home');
        ManageAddressesController manageAddress;

        Contact sonAsDependent = new Contact(FirstName='Test', LastName='SonMember', RecordTypeId=ContactMemberId, AccountId=account.id);
        sonAsDependent.Relationship__c = 'Dependent';
        insert sonAsDependent;

        Contact daughterAsDependent = new Contact(FirstName='Test', LastName='DependentMember', RecordTypeId=ContactMemberId, AccountId=account.id);
        daughterAsDependent.Relationship__c = 'Dependent';
        insert daughterAsDependent;

        Address__c businessAddress=TxnTestUtility.getAddress(primaryMember,'Business');
        Address__c sonHomeAddress = TxnTestUtility.getAddress(sonAsDependent,'Winter');

        Address__c wifeAsSpouse_PartnerHomeAddress = homeAddress.Clone(false,true);
        wifeAsSpouse_PartnerHomeAddress.Customer__c = spousePartnerMember.id;
        wifeAsSpouse_PartnerHomeAddress.Copied_From_Dependent__c = true;
        insert wifeAsSpouse_PartnerHomeAddress;

        PageReference manageAdddressPage=Page.manageAddresses;
        Test.setCurrentPage(manageAdddressPage);
        ApexPages.currentPage().getParameters().put('memberId',primaryMember.id);

        manageAddress=new ManageAddressesController(sc);
        manageAddress.checkId();

        //Test code for add address process
        manageAddress.newAddress.Name='Test Code Home';
        manageAddress.newAddress.Type__c='Winter';
       /* manageAddress.fromMonth='3';
        manageAddress.fromDate='3';

        manageAddress.toMonth='10';
        manageAddress.toDate='3'; */

        List<String> dependentMembersIds=new List<String>();
        dependentMembersIds.add(sonAsDependent.id);
        dependentMembersIds.add(daughterAsDependent.id);

        String dependentMembersIdsJSON=JSON.serialize(dependentMembersIds);
        ApexPages.currentPage().getParameters().put('node',dependentMembersIdsJSON);
        manageAddress.addNew();
        manageAddress.AddingNew();
        manageAddress.checkId();
        //manageAddress.saveNewDependentAddress();
    }

    public testMethod static void EditAddressProcess() {
        Address__c add = new Address__c();
        ApexPages.StandardController sc=new ApexPages.StandardController(add);
        Account account=TxnTestUtility.createAccount(AccountMemberId);
        Contact primaryMember=TxnTestUtility.createMember(account,'Primary',ContactMemberId);

        Contact spousePartnerMember = new Contact(FirstName='Test', LastName='SpousePartnerMember', RecordTypeId=ContactMemberId, AccountId=account.id);
        spousePartnerMember.Relationship__c = 'Dependent';
        insert spousePartnerMember;

        Address__c homeAddress=TxnTestUtility.getAddress(primaryMember,'Home');
        ManageAddressesController manageAddress;

        Contact sonAsDependent = new Contact(FirstName='Test', LastName='SonMember', RecordTypeId=ContactMemberId, AccountId=account.id);
        sonAsDependent.Relationship__c = 'Dependent';
        insert sonAsDependent;

        Contact daughterAsDependent = new Contact(FirstName='Test', LastName='DependentMember', RecordTypeId=ContactMemberId, AccountId=account.id);
        daughterAsDependent.Relationship__c = 'Dependent';
        insert daughterAsDependent;
        
        Address__c sonHomeAddress = TxnTestUtility.getAddress(sonAsDependent,'Home');
        PageReference manageAdddressPage=Page.manageAddresses;
        Test.setCurrentPage(manageAdddressPage);
        ApexPages.currentPage().getParameters().put('memberId',primaryMember.id);
        manageAddress=new ManageAddressesController(sc);
        manageAddress.checkId();

        //Test code for edit address process
        manageAddress.newAddress.Name='Test Code Home';
        manageAddress.newAddress.Type__c='Home';
       /* manageAddress.fromMonth='3';
        manageAddress.fromDate='3';

        manageAddress.toMonth='10';
        manageAddress.toDate='4'; */

        List<String> dependentMembersIds=new List<String>();
        dependentMembersIds.add(sonAsDependent.id);
        dependentMembersIds.add(daughterAsDependent.id);

        String dependentMembersIdsJSON=JSON.serialize(dependentMembersIds);
        ApexPages.currentPage().getParameters().put('Data',homeAddress.id);
        ApexPages.currentPage().getParameters().put('node2',dependentMembersIdsJSON);
        //manageAddress.EditAddress();
        manageAddress.isMember = true;
        manageAddress.EditingAddress();

        dependentMembersIds.remove(0);
        ApexPages.currentPage().getParameters().put('node2',null);
        manageAddress.EditingAddress();
    }

    public testMethod static void DeleteAddressProcess() {
        Address__c add = new Address__c();
        ApexPages.StandardController sc=new ApexPages.StandardController(add);
        Account account=TxnTestUtility.createAccount(AccountMemberId);
        Contact primaryMember=TxnTestUtility.createMember(account,'Primary');
        Contact spousePartnerMember=TxnTestUtility.createMember(account,'Spouse/Partner');
        Address__c homeAddress=TxnTestUtility.getAddress(primaryMember,'Home');
        ManageAddressesController manageAddress;
        Contact sonAsDependent=TxnTestUtility.createMember(account,'Dependent');
        Contact daughterAsDependent=TxnTestUtility.createMember(account,'Dependent');
        Address__c sonHomeAddress = TxnTestUtility.getAddress(sonAsDependent,'Home');
        PageReference manageAdddressPage=Page.manageAddresses;
        Test.setCurrentPage(manageAdddressPage);
        ApexPages.currentPage().getParameters().put('memberId',primaryMember.id);
        manageAddress = new ManageAddressesController(sc);
        manageAddress.checkId();

        //Test code for edit address process
        manageAddress.newAddress.Name='Test Code Home';
        manageAddress.newAddress.Type__c='Home';
       /* manageAddress.fromMonth='3';
        manageAddress.fromDate='3';

        manageAddress.toMonth='10';
        manageAddress.toDate='4'; */

        List<String> dependentMembersIds=new List<String>();
        dependentMembersIds.add(sonAsDependent.id);
        dependentMembersIds.add(daughterAsDependent.id);

        String dependentMembersIdsJSON=JSON.serialize(dependentMembersIds);
        ApexPages.currentPage().getParameters().put('Data',homeAddress.id);
        ApexPages.currentPage().getParameters().put('node2',dependentMembersIdsJSON);
        //manageAddress.EditAddress();
        manageAddress.EditingAddress();

        dependentMembersIds.remove(0);
        ApexPages.currentPage().getParameters().put('node2',null);
        manageAddress.EditingAddress();

        //Test code for DeleteAddress
        ApexPages.currentPage().getParameters().put('deleteAddressID',homeAddress.id);
        manageAddress.DeleteAddress();

        //Test code for DeletingAddress
        ApexPages.currentPage().getParameters().put('node1',dependentMembersIdsJSON);
        manageAddress.DeletingAddresses();

        //Test code for saveDependentAdd
        manageAddress.saveDependentAdd();
        manageAddress.makeFalseCopiedToIfNoEditSelected();
    }

    private testMethod static void testMonthsDays() {
        Address__c add=new Address__c();
        ApexPages.StandardController sc=new ApexPages.StandardController(add);
        ManageAddressesController c = new ManageAddressesController(sc);

        List<SelectOption> months = c.getMonths();
        System.assert(months.size() == 12);

        List<SelectOption> days =  c.getDays();
        System.assert(days.size() == 31);

        Date dt = ManageAddressesController.getDateFromValues(6, 12, false);
        System.assert(dt.day() == 12);

        dt = ManageAddressesController.getDateFromValues(6, 12, true);
        System.assert(dt.year() == 2100);

        try
        {
            dt = ManageAddressesController.getDateFromValues(6, 31, false);
        }
        catch(Utility.CustomException shouldBeHere)
        {
            System.assert(shouldBeHere!=null);
        }

        try
        {
            dt = ManageAddressesController.getDateFromValues(2, 31, false);
        }
        catch(Utility.CustomException shouldBeHere)
        {
            System.assert(shouldBeHere!=null);
        }

        try
        {
            dt = ManageAddressesController.getDateFromValues(0, 0, false);
        }
        catch(Utility.CustomException shouldBeHere)
        {
            System.assert(shouldBeHere!=null);
        }

    }

}