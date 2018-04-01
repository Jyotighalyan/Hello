/**
* @Author             : jyoti@mobifyi.com
* @Date               : June 15, 2016
* @Description        : The above combination of VF and APEX are allow user to create add and delete the their addresses.
* @group              : Member Management
*/

public with sharing class ManageAddressServiceImpl implements cmsft_IManageAddress {
    public Contact currentMemberContactRecord;
    public List<Contact> dependentsListOfcurrentMember;
    public Address__c selectedAddressForEdit;
    // to store all the addresses with the type before edit so that we can check and all unchecked deps this type address can be marked false for copied from dependent checkbox
    public List<Address__c> allAddressesOfTypeForEdit;

    public ManageAddressServiceImpl() {

    }
    // get contact record with passed member Id
    public Contact getContactRecordWithPassesId(Id memberId) {
        Id MemRecTypeId = Utility.searchRecordType('Member', 'Contact');
        Id receProcalRecTypeId = Utility.searchRecordType('Reciprocal Club', 'Contact');
        //return new cmsft_ContactSelector().getAllContactsWithTheDynamicCondition('where id=\'' + memberId + '\' AND RecordTypeId =\'' + MemRecTypeId + '\'').get(0);
        return new cmsft_ContactSelector().getAllContactsWithTheDynamicCondition('where id=\'' + memberId + '\' AND (RecordTypeId =\'' + MemRecTypeId + '\' OR RecordTypeId =\''+receProcalRecTypeId+'\')').get(0);
        //return new cmsft_ContactSelector().getAllContactsWithTheDynamicCondition('where id=\'' + memberId).get(0);
    }
    // to set currentMemberContactRecord so that membername, accountname can be fetched
    public void setcurrentMemberContactRecord(Id memberId) {
        currentMemberContactRecord = getContactRecordWithPassesId(memberId);
    }

    // to get dependents parimary member name to show up on breadcrump
    public String getDependentsPrimaryMemberName(Id dependentPrimaryMemId) {
        return getContactRecordWithPassesId(dependentPrimaryMemId).Name;
    }

    // to get all addresses list for current contact
    public List<List<Address__c>> getAllAddressesListToShowUpOnLandingPage() {
        Integer index = 1;
        List<Address__c> tempAddressList = new List<Address__c>();
        List<List<Address__c>> actualAddressList = new List<List<Address__c>>();
        if(currentMemberContactRecord!=null){
            for (Address__c eachAddressOfMember : new cmsft_AddressSelector().getAllAddressesWithTheDynamicCondition('where Customer__c=\'' + currentMemberContactRecord.id + '\'')) {
                if (math.mod(index, 2) == 0) {
                    tempAddressList.add(eachAddressOfMember);
                    actualAddressList.add(tempAddressList);
                    index++;
                    tempAddressList = new  List<Address__c>();
                    continue;
                }

                tempAddressList.add(eachAddressOfMember);
                index++;
            }
        }

        if (math.mod(index, 2) == 0)actualAddressList.add(tempAddressList);
        return actualAddressList;
    }

    // to get all dependent list with shared and independent addresses - if member then list and if dependent then change color of address
    public List<tableRow> getDependentListWithSharedAndCommonAddress(boolean isMember) {
        List<tableRow> Data = new List<tableRow>();
        List<Contact> dependentContacts;
        if (isMember == true) {
            dependentContacts = new cmsft_ContactSelector().getAllContactsWithTheDynamicCondition('where Account.Id =\'' + currentMemberContactRecord.AccountId + '\' AND Id !=\'' + currentMemberContactRecord.id + '\' AND Account.Id !=\'\'');
            dependentsListOfcurrentMember = dependentContacts;
        } else
            dependentContacts = new cmsft_ContactSelector().getAllContactsWithTheDynamicCondition('WHERE Account.Id =\'' + currentMemberContactRecord.AccountId + '\' AND Id != \'' + currentMemberContactRecord.id + '\' AND Account.Id != \'\' AND Relationship__c = \'Primary\'');

        String IdsOfDependents = '';
        for (Integer i = 0; i < dependentContacts.size(); i++) {
            if (i < (dependentContacts.size() - 1))
                IdsOfDependents = IdsOfDependents + '\'' + dependentContacts.get(i).id + '\',';
            if (i == (dependentContacts.size() - 1))
                IdsOfDependents = IdsOfDependents + '\'' + dependentContacts.get(i).id + '\'';
        }
        List<Address__c> allAddressesOfDependentContacts = new List<Address__c>();
        if(!String.isEmpty(IdsOfDependents))
            allAddressesOfDependentContacts = new cmsft_AddressSelector().getAllAddressesWithTheDynamicCondition('where Customer__c in (' + IdsOfDependents + ')');

        List<Address__c> allAddressesOfCurrentMember = new cmsft_AddressSelector().getAllAddressesWithTheDynamicCondition('where Customer__c=\'' + currentMemberContactRecord.id + '\'');

        // starting of for loop1
        for (Integer i = 0; i < dependentContacts.size(); i++) {
            List<AddressRows> addressesAlone = new  List<AddressRows>();
            List<AddressRows> commonAddress = new List<AddressRows>();

            for (Integer j = 0; j < allAddressesOfDependentContacts.size(); j++) {
                // starting of if statement
                if (allAddressesOfDependentContacts.get(j).Customer__c == dependentContacts.get(i).id) {
                    Boolean addressFlag = false;
                    for (Address__c contAddress : allAddressesOfCurrentMember) {
                        if (allAddressesOfDependentContacts[j].Type__c == string.valueOf(contAddress.Type__c)) {
                            if (isMember == true) {
                                if (allAddressesOfDependentContacts[j].Copied_From_Dependent__c == true) {
                                    commonAddress.add(new  AddressRows(allAddressesOfDependentContacts[j].Type__c + ', ', allAddressesOfDependentContacts[j].id));
                                    addressFlag = true;
                                    break;
                                }
                            } else {
                                if (contAddress.Copied_From_Dependent__c == true) {
                                    commonAddress.add(new  AddressRows(allAddressesOfDependentContacts[j].Type__c + ', ', allAddressesOfDependentContacts[j].id));
                                    addressFlag = true;
                                    break;
                                }
                            }
                        }
                    }
                    if (!addressFlag)
                        addressesAlone.add(new AddressRows(allAddressesOfDependentContacts[j].Type__c + ', ', allAddressesOfDependentContacts[j].id));
                } // end of if statement
            }
            if (addressesAlone.size() > 0) {
                AddressRows addressrow = addressesAlone.get(addressesAlone.size() - 1);
                addressrow.addressName = (addressrow.addressName).substring(0, (addressrow.addressName).indexOf(','));
                addressesAlone.set(addressesAlone.size() - 1, addressrow);
            }

            if (commonAddress.size() > 0) {
                AddressRows addressrow = commonAddress.get(commonAddress.size() - 1);
                addressrow.addressName = (addressrow.addressName).substring(0, (addressrow.addressName).indexOf(','));
                commonAddress.set(commonAddress.size() - 1, addressrow);
            }
            Data.add(new tableRow(dependentContacts.get(i).Id, dependentContacts.get(i).Name, dependentContacts.get(i).Relationship__c, false, addressesAlone, commonAddress));
        }
        // end of for loop1
        return Data;
    }

    //to get the dependents list to show up on add new address popup
    public List<tableRow> getDependentListForAddNewAddressPopup() {
        List<tableRow> addNewDependentList = new List<tableRow>();
        if (dependentsListOfcurrentMember != null)
            for (Contact DependentOne : dependentsListOfcurrentMember) {
                addNewDependentList.add(new tableRow(DependentOne.Id, DependentOne.Name, DependentOne.Relationship__c, '', true));
            }
        return addNewDependentList;
    }

    // to save new address on dependents and get lis of addresses that have the type same as of new address type
    public List<Address__c> saveNewAddressOnDependents(Address__c newAddress, List<tableRow> dependentsListWithCopyOrNotStatus) {
        List<Id> dependentsIdList = new List<Id>();
        List<Address__c> addressListToInsert = new List<Address__c>();
        List<Address__c> dependentsListHavingNewAddressType = new List<Address__c>();
        List<Address__c> partialInsertDependentAddressesDontHaveThisType = new List<Address__c>();

        if (newAddress.Name == null || newAddress.Name == '') {
            throw new AddressException('Error: Address Name is mandatory.');
        }
        if (newAddress.Type__c == null) {
            throw new AddressException('Error: Address Type is mandatory.');
        }
        List<Address__c> memberAddressWithTheNewAddressType = new cmsft_AddressSelector().getAllAddressesWithTheDynamicCondition('where Type__c=\'' + newAddress.Type__c + '\' AND Customer__c=\'' + currentMemberContactRecord.Id + '\'');
        if (memberAddressWithTheNewAddressType.size() > 0) {
            throw new AddressException('Error: Error: This member already has an address of this type on their account. Please choose a different type or edit an existing address on the account.');
        }
        newAddress.Customer__c = currentMemberContactRecord.Id;
        Data.create(newAddress);
        for (tableRow depDataOne : dependentsListWithCopyOrNotStatus) {
            if (depDataOne.chechIfDependSel)
                dependentsIdList.add(depDataOne.Id);
        }
        if (dependentsIdList.size() > 0) {
            for (Id depIdOne : dependentsIdList) {
                Address__c address = new Address__c();
                address = newAddress.clone(false, true);
                address.Customer__c = string.valueOf(depIdOne);
                address.Copied_From_Dependent__c = true;
                addressListToInsert.add(address);
            }
        }

        String allDeps = '';
        for (Integer i = 0; i < dependentsIdList.size(); i++) {
            if (i < (dependentsIdList.size() - 1))
                allDeps = allDeps + '\'' + dependentsIdList[i] + '\',';
            if (i == (dependentsIdList.size() - 1))
                allDeps = allDeps + '\'' + dependentsIdList[i] + '\'';
        }
        List<Address__c> addressesOfAllDependentsHavingSameAddressType;
        if (dependentsIdList.size() > 0)
            addressesOfAllDependentsHavingSameAddressType = new cmsft_AddressSelector().getAllAddressesWithTheDynamicCondition('where Type__c=\'' + newAddress.Type__c + '\' AND Customer__c in (' + allDeps + ')');

        boolean typeExistOnAnyOfTheDependentBoolean = false;
        for (Address__c addressOne : addressListToInsert) {
            boolean flag = false;
            for (Address__c address2One : addressesOfAllDependentsHavingSameAddressType) {
                if (addressOne.Customer__c == address2One.Customer__c) {
                    flag = true;
                    typeExistOnAnyOfTheDependentBoolean = true;
                    dependentsListHavingNewAddressType.add(addressOne);
                }
            }
            if (flag == false)
                partialInsertDependentAddressesDontHaveThisType.add(addressOne);
        }
        if (typeExistOnAnyOfTheDependentBoolean == false) {
            if (addressListToInsert != null && addressListToInsert.size() > 0)
                Insert addressListToInsert;
        } else {
            Data.create(partialInsertDependentAddressesDontHaveThisType);
        }
        return dependentsListHavingNewAddressType;
    }

    // to get name of the owner of address before save due i.e not able to fetch with relationship fields
    public List<String> getListOfNamesAlreadyHaveType(List<Address__c> addressesList) {
        List<String> namesList = new List<String>();
        String customerIds = '';
        for (Integer i = 0; i < addressesList.size(); i++) {
            if (i < (addressesList.size() - 1))
                customerIds = customerIds + '\'' + addressesList[i].Customer__c + '\',';
            if (i == (addressesList.size() - 1))
                customerIds = customerIds + '\'' + addressesList[i].Customer__c + '\'';
        }
        List<Contact> contactRec = new cmsft_ContactSelector().getAllContactsWithTheDynamicCondition('where Id in (' + CustomerIds + ')');
        for (Contact con : contactRec) {
            namesList.add(con.Name);
        }
        return namesList;
    }

    public PageReference saveAddressesAfterConfirmationOnJqueryPopup(string addOrEdit, List<Address__c> depLFIA, string typeName) {
        String depLFIACustomerIdList = '';
        for (Integer i = 0; i < depLFIA.size(); i++) {
            if (i < (depLFIA.size() - 1))
                depLFIACustomerIdList = depLFIACustomerIdList + '\'' + depLFIA[i].Customer__c + '\',';
            if (i == (depLFIA.size() - 1))
                depLFIACustomerIdList = depLFIACustomerIdList + '\'' + depLFIA[i].Customer__c + '\'';
        }
        Delete new cmsft_AddressSelector().getAllAddressesWithTheDynamicCondition('where Type__c = \'' + typeName + '\' AND Customer__c in (' + depLFIACustomerIdList + ')');
        insert depLFIA;
        PageReference pg = new  PageReference('/apex/manageAddresses?memberId=' + currentMemberContactRecord.id);
        pg.setRedirect(true);
        return pg;
    }

    // to get all address of all the dependents dependentsListOfcurrentMember
    public List<Address__c> getAllAddressesOfDependents(){
        String allDeps = '';

        for (Integer i = 0; i < dependentsListOfcurrentMember.size(); i++) {
            if (i < (dependentsListOfcurrentMember.size() - 1))
                allDeps = allDeps + '\'' + dependentsListOfcurrentMember[i].Id + '\',';
            if (i == (dependentsListOfcurrentMember.size() - 1))
                allDeps = allDeps + '\'' + dependentsListOfcurrentMember[i].Id + '\'';
        }
        List<Address__c> addressesOfDependents = new cmsft_AddressSelector().getAllAddressesWithTheDynamicCondition('where Customer__c in ('+allDeps+')');
        return addressesOfDependents;
    }

    // to get lists of dependents having address with same type as selected
    public Map<String, List<tableRow>> getMapOfDepsNCpdAddresses(String selectedAddressForEditId){
        allAddressesOfTypeForEdit = new List<Address__c>();
        Map<String, List<tableRow>> mapOfListsOfDepsWithCpdStatusNAddressesCpd = new Map<String, List<tableRow>>();
        selectedAddressForEdit = new cmsft_AddressSelector().getAllAddressesWithTheDynamicCondition('where id=\''+selectedAddressForEditId+'\'').get(0);
        List<tableRow> listOfCpdAddressesOfDeps = new List<tableRow>();
        List<tableRow> listOfDepsWithCpdStatus = new List<tableRow>();
        if(dependentsListofCurrentMember!=null){
            for(Contact dependentOne :dependentsListOfcurrentMember){
                boolean depStatus = false;
                for(Address__c addressOne :getAllAddressesOfDependents()){
                    if(addressOne.Customer__c==dependentOne.id){
                        if(addressOne.Type__c==selectedAddressForEdit.Type__c){
                            allAddressesOfTypeForEdit.add(addressOne);
                            if (addressOne.Copied_From_Dependent__c == true) {
                                depStatus = true;
                                listOfCpdAddressesOfDeps.add(new tableRow(string.valueOf(dependentOne.Id), dependentOne.Name, dependentOne.Relationship__c, '', depStatus, addressOne));
                            }
                        }
                    }
                }
                string addressString = '';
                listOfDepsWithCpdStatus.add(new  ManageAddressServiceImpl.tableRow(string.valueOf(dependentOne.Id), dependentOne.Name, dependentOne.Relationship__c, addressString, depStatus, null));
            }
        }

        mapOfListsOfDepsWithCpdStatusNAddressesCpd.put('DepsData',listOfDepsWithCpdStatus);
        mapOfListsOfDepsWithCpdStatusNAddressesCpd.put('CopiedAddressesData',listOfCpdAddressesOfDeps);
        return mapOfListsOfDepsWithCpdStatusNAddressesCpd;
    }


    public static PageReference autoRunMethodAfterConstructorToInitialize(PageReference pg, Id memberId) {
        pg.setRedirect(true);
        return null;
    }

    public static PageReference RedirectTo(String page) {
        PageReference pg = new PageReference('/apex/' + page);
        pg.setRedirect(true);
        return pg;
    }

    // Structure to show address with link
    public class AddressRows {
        public string addressName {get; set;}
        public string addressId {get; set;}
        public AddressRows(string p_addressName, string p_addressId) {
            addressName = p_addressName;
            addressId = p_addressId;
        }
    }

    //structure to show dependent table
    public class tableRow {
        public string Name {get; set;}
        public string Relationship {get; set;}
        public string Id {get; set;}
        public string address {get; set;}
        public boolean statusBool {get; set;}
        public List<AddressRows> indepAddressList {get; set;}
        public List<AddressRows> sharedaddressList {get; set;}
        public Address__c selectedAddressDetail {get; set;}
        public boolean chechIfDependSel {get; set;}

        public tableRow(string p_Id, string p_name, string p_RelationshipName, string p_address, boolean p_status) {
            Id = p_Id;
            chechIfDependSel = true;
            Name = p_name;
            Relationship = p_RelationshipName;
            address = p_address;
            statusBool = p_status;
            chechIfDependSel = p_status;
        }

        public tableRow(string p_Id, string p_name, string p_RelationshipName, boolean p_status, List<AddressRows> p_independentaddressList, List<AddressRows>p_sharedaddressList) {
            Id = p_Id;
            Name = p_name;
            chechIfDependSel = true;
            Relationship = p_RelationshipName;
            indepAddressList = p_independentaddressList;
            sharedaddressList = p_sharedaddressList;
            statusBool = p_status;
        }

        public tableRow(string p_Id, string p_name, string p_RelationshipName, string p_address, boolean p_status, Address__c add) {
            selectedAddressDetail = add;
            Id = p_Id;
            chechIfDependSel = true;
            Name = p_name;
            Relationship = p_RelationshipName;
            statusBool = p_status;
            chechIfDependSel = p_status;
        }
    }

    public class AddressException extends Exception {}
}