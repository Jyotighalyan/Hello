/**
 * @Name        : manageAddressesController
 * @Author      : jyoti@mobifyi.com
 * @Date        : June 15, 2016
 * @Description : The above combination of VF and APEX are allow user to create add and delete the their  *addresses. In addition this allows a primary member to update add and delete his address on his selected dependents and spouse.
 */

public with sharing class ManageAddressesController {
    public List<List<Address__c>> addressList {get; set;}
    public string selectedAddressId {get; set;}
    public string memberId {get; set;}
    public boolean isMember {get; set;}
    public boolean isDependent {get; set;}
    public string AccountId {get; set;}
    public List<ManageAddressServiceImpl.tableRow> TableData {get; set;}
    public boolean renderAddress {get; set;}
    public Address__c newAddress {get; set;}
    public boolean editPopupBoolean {get; set;}
    public boolean deletePopupBoolean {get; set;}
    public boolean addNewAddressBoolean {get; set;}
    public Address__c selectedAddressDetail {get; set;}
    public String memberName {get; set;}
    public String dependentPrimaryName {get; set;}
    public String primaryMemberId {get; set;}
    public String forColorChange {get; set;}
    public String addressTypeBeforeEdit {get; set;}
    public List<ManageAddressServiceImpl.tableRow> dependentSelectedTypeAddress {get; set;}
    public String dependentSelectedTypeAddressSize {get; set;}
    public Integer dependentSelectedTypeAddressSize1 {get; set;}
    public boolean accountNameBlankError {get; set;}
    public List<Address__c> depLFIA ;
    public boolean saveOnDependentBoolean {get; set;}
    public boolean refPage {get; set;}
    public List<String> currentSharedAddressList {get; set;}
    public List<Address__c> dependentListOfSelectedAddressType {get; set;}
    public manageAddressService service;

    public Integer selectedFromMonth{get;set;}
    public Integer selectedFromDay{get;set;}
    public Integer selectedToMonth{get;set;}
    public Integer selectedToDay{get;set;}

    // for testing - jyoti
    public List<ManageAddressServiceImpl.tableRow> testingAddNew {get; set;}
    public Integer testingAddNewSize {get; set;}

    public ManageAddressesController(ApexPages.StandardController controller) {
        dependentListOfSelectedAddressType = new List<Address__c>();
        service = new manageAddressService();
        service.service();
        testingAddNew = new List<ManageAddressServiceImpl.tableRow>();
        refPage = false;
        saveOnDependentBoolean = false;
        editPopupBoolean = false;
        newAddress = new  Address__c();
        newAddress.Country__c = 'United States';
        newAddress.From_Date__c = Date.today();
        newAddress.To_Date__c = Date.today();
    }

    // to capture data to be shown on add new popup
    public void addNew() {
        addNewAddressBoolean = true;
        testingAddNew = service.getDependentListForAddNewAddressPopupService();
    }

    // to save new address on member and dependent
    public void AddingNew() {
        try {
            newAddress.From_Date__c = ManageAddressesController.getDateFromValues(selectedFromMonth, selectedFromDay, false);
            newAddress.To_Date__c = ManageAddressesController.getDateFromValues(selectedToMonth, selectedToDay, true);

            currentSharedAddressList = new LIST<string>();
            depLFIA = service.saveNewAddressOnDependentsService(newAddress, testingAddNew);

            if (depLFIA == null || depLFIA.size() < 1) {
                addNewAddressBoolean = false;
                refPage = true;
            } else {
                currentSharedAddressList = service.getListOfNamesAlreadyHaveTypeService(depLFIA);
                saveOnDependentBoolean = true;
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }

    // to save address on dependent
    public PageReference saveNewDependentAddress() {
        addNewAddressBoolean = false;
        return service.saveAddressesAfterConfirmationOnJqueryPopupService('add', depLFIA, newAddress.Type__c);
    }

    // to delete a address first from member then from dependent if selected
    public PageReference DeletingAddresses() {
        if (!Schema.sObjectType.Address__c.isDeletable()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Error: You do not have permission to delete addresses.'));
            return null;
        }

        try {
            memberId = String.escapeSingleQuotes(memberId.trim()); // clean memberId from potential second order SOQL injection

            List<Id> dependentIdListToDeleteAddress = new List<Id>();

            for (ManageAddressServiceImpl.tableRow depId : testingAddNew) {
                if (depId.chechIfDependSel) {
                    dependentIdListToDeleteAddress.add(depId.id);
                }
            }

            List<Address__c> addressToDelete = (List<Address__c>)Data.read(
                'SELECT Type__c FROM Address__c WHERE Address__c.Id = :selectedAddressId',
                new Map<String,Object> {
                    'selectedAddressId' => selectedAddressId
                }
            );

            List<Address__c> addressIds = (List<Address__c>)Data.read(
                'SELECT id FROM Address__c WHERE Address__c.Customer__c = :memberId AND Address__c.Type__c = :addressType',
                new Map<String, Object> {
                    'memberId' => memberId,
                    'addressType' => addressToDelete[0].Type__c
                }
            );

            Data.remove(addressIds);

            if (dependentIdListToDeleteAddress != null) {
                List<Id> DDepIdList = new List<Id>();
                Integer ilen = dependentIdListToDeleteAddress.size();

                for (Integer i = 0; i < ilen; i++) {
                    DDepIdList.add(string.valueOf(dependentIdListToDeleteAddress[i]));
                }

                List<Address__c> dependentAddressIds = (List<Address__c>)Data.read(
                    'SELECT id FROM Address__c WHERE Address__c.Customer__c IN :DDepIdList AND Address__c.Type__c = :addressToDelete',
                    new Map<String, Object> {
                        'DDepIdList' => DDepIdList,
                        'addressToDelete' => addressToDelete[0].Type__c
                    }
                );

                Data.remove(dependentAddressIds);
            }

            PageReference pg = Page.manageAddresses;
            pg.getParameters().put('memberId', memberId);

            if (isDependent) {
                primaryMemberId = String.escapeSingleQuotes(primaryMemberId.trim());
                pg.getParameters().put('primaryMemId', primaryMemberId);
            }

            pg.setRedirect(true);
            return pg;
        }

        catch (Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Error :' + e.getMessage()));
            return null;
        }
    }

    // builds dependent details and functionality that appear in the delete popup
    public void DeleteAddress() {
        try {
            memberId = String.escapeSingleQuotes(memberId.trim()); // clean memberId from potential second order SOQL injection

            if (deletePopupBoolean == false) {
                deletePopupBoolean = true;
                testingAddNew = new List<ManageAddressServiceImpl.tableRow>();
                dependentSelectedTypeAddress = new List<ManageAddressServiceImpl.tableRow>();
                selectedAddressId = String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('Data').trim());

                if (isMember == true) {
                    List<Address__c> addressToCompareList = (List<Address__c>)Data.read(
                        'SELECT Name, City__c, Country__c, Active__c, State_Province__c, Street_1__c, Street_2__c, Street_3__c, Zip_Postal_Code__c, Type__c FROM Address__c WHERE Address__c.Id = :id',
                        new Map<String,Object> {
                            'id' => selectedAddressId
                        }
                    );

                    Address__c addressToCompare = addressToCompareList[0];

                    if (addressToCompareList.size() > 0) {
                        List<Contact> contactList = new List<Contact>([
                            SELECT Contact.Name, Contact.Relationship__c, Contact.Id
                            FROM Contact
                            WHERE Contact.Account.Id = :AccountId AND Contact.Id != :memberId
                        ]);

                        List<Id> recordTypeIdList = new List<Id>();
                        for (Contact sRecordType : contactList) {
                            recordTypeIdList.add(sRecordType.Id);
                        }

                        List<Address__c> addressL = (List<Address__c>)Data.read(
                            'SELECT Street_1__c, Street_2__c, Street_3__c, City__c, State_Province__c FROM Address__c WHERE Type__c = :addressType AND Customer__c IN :recordList AND Copied_From_Dependent__c = true',
                            new Map<String,Object> {
                                'addressType' => addressToCompare.Type__c,
                                'recordList' => recordTypeIdList
                            }
                        );

                        List<Address__c> dependentAddressList = [
                            SELECT Type__c, Copied_From_Dependent__c FROM Address__c WHERE Address__c.Customer__c IN :recordTypeIdList
                        ];

                        for (Contact sRecordType : contactList) {
                            boolean dep = false;

                            if (addressL.size() != 0) {
                                dependentSelectedTypeAddress.add(new ManageAddressServiceImpl.tableRow(string.valueOf(sRecordType.Id), sRecordType.Name, sRecordType.Relationship__c, '', dep, addressL[0]));
                            }

                            for (Address__c add : dependentAddressList) {
                                if (add.Type__c == addressToCompare.Type__c) {
                                    if (add.Copied_From_Dependent__c == true) {
                                        dep = true;
                                    }
                                }
                            }

                            string addressString = '';
                            testingAddNew.add(new ManageAddressServiceImpl.tableRow(sRecordType.Id, sRecordType.Name, sRecordType.Relationship__c, addressString, dep));
                        }
                    }
                }
            }

            testingAddNewSize = testingAddNew.size();
            dependentSelectedTypeAddressSize1 = dependentSelectedTypeAddress.size();

            if (dependentSelectedTypeAddressSize1 > 0) {
                dependentSelectedTypeAddressSize = string.valueOf(620 / dependentSelectedTypeAddressSize1);
            }
        } catch (Exception e) {
            ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR, 'Error : ' + e.getMessage()));
        }
    }

    // to prepare edit popup data
    public void EditAddress() {
        // sanitize Data parameter to prevent SOQL/SOSL injection
        String dataParam = Apexpages.currentPage().getParameters().get('Data');
        String dataParamSanitized = String.escapeSingleQuotes(dataParam);

        editPopupBoolean = true;
        selectedAddressId = dataParamSanitized;

        Map<String, List<ManageAddressServiceImpl.tableRow>> mapOfDepndentsAndAddresses = service.getMapOfDepsNCpdAddressesService(selectedAddressId);
        selectedAddressDetail = service.getselectedAddressForEdit();

        selectedFromMonth = selectedAddressDetail.From_Date__c.month();
        selectedFromDay = selectedAddressDetail.From_Date__c.day();
        selectedToMonth = selectedAddressDetail.To_Date__c.month();
        selectedToDay = selectedAddressDetail.To_Date__c.day();

        testingAddNew = mapOfDepndentsAndAddresses.get('DepsData');
        addressTypeBeforeEdit = selectedAddressDetail.Type__c;
        dependentSelectedTypeAddress = mapOfDepndentsAndAddresses.get('CopiedAddressesData');

        if (testingAddNew == null) {
            testingAddNew = new List<ManageAddressServiceImpl.tableRow>();
        }

        if (dependentSelectedTypeAddress == null) {
            dependentSelectedTypeAddress = new List<ManageAddressServiceImpl.tableRow>();
        }

        testingAddNewSize = testingAddNew.size();
        dependentSelectedTypeAddressSize1 = dependentSelectedTypeAddress.size();

        if (dependentSelectedTypeAddressSize1 > 0) {
            if (dependentSelectedTypeAddressSize1 > 2) {
                dependentSelectedTypeAddressSize = string.valueOf(720 / dependentSelectedTypeAddressSize1);
            } else {
                dependentSelectedTypeAddressSize = string.valueOf(500 / dependentSelectedTypeAddressSize1);
            }
        }
    }

    // to Edit Existing Address
    public void EditingAddress() {
        try {
            selectedAddressDetail.From_Date__c = ManageAddressesController.getDateFromValues(selectedFromMonth, selectedFromDay, false);
            selectedAddressDetail.To_Date__c = ManageAddressesController.getDateFromValues(selectedToMonth, selectedToDay,true);

            memberId = String.escapeSingleQuotes(memberId.trim()); // clean memberId from potential second order SOQL injection
            currentSharedAddressList = new LIST<string>();
            depLFIA = new List<Address__c>();
            List<Address__c> dependentIdList1 = new List<Address__c>();
            List<Id> dependentIdList = new List<Id>(); // Represents dependents that are checked
            Boolean exist = false;

            if (isMember) {
                List<Id> dependentUncheckedIdList = new List<Id>();

                for (ManageAddressServiceImpl.tableRow depId : testingAddNew) {
                    if (depId.chechIfDependSel) {
                        // cache dependent ids to update later
                        dependentIdList.add(depId.id);
                    } else {
                        // cache dependent ids to delete and re-create later
                        dependentUncheckedIdList.add(depId.id);
                    }
                }

                if (dependentUncheckedIdList.size() > 0 && dependentSelectedTypeAddress.size() > 0) {
                    List<Address__c> copiedDependentAddressesToAddList = new List<Address__c>();

                    // build collection of addresses to delete based on unchecked dependents from the edit address popup
                    List<Address__c> sharedAddressesToDeleteList = [
                        SELECT Id, Customer__c, Type__c
                        FROM Address__c
                        WHERE Customer__c IN :dependentUncheckedIdList
                        AND Type__c = :selectedAddressDetail.Type__c
                    ];

                    // clone selected address, update Customer__c, Type__c, and Copied_From_Dependent__c to false
                    List<Address__c> independentAddressesToAddList = new List<Address__c>();
                    Address__c copiedAdr = dependentSelectedTypeAddress[0].selectedAddressDetail;
                    Address__c copiedAddressToAdd = new Address__c();
                    for (Address__c adr : sharedAddressesToDeleteList) {
                        copiedAddressToAdd = copiedAdr.clone(false, true, false, false);
                        copiedAddressToAdd.Copied_From_Dependent__c = false;
                        copiedAddressToAdd.Customer__c = adr.Customer__c;
                        independentAddressesToAddList.add(copiedAddressToAdd);
                    }

                    // delete shared addresses for dependents that were unchecked in edit popup
                    Data.remove(sharedAddressesToDeleteList);

                    // created independent addresses for dependents that were unchecked in edit popup
                    Data.create(independentAddressesToAddList);
                }
            }

            List<Address__c> dependentListToInsertEditedAddress = new List<Address__c>();
            selectedAddressDetail.Customer__c = memberId;
            List<Address__c> existedAddr = [SELECT id FROM Address__c WHERE Type__c = :selectedAddressDetail.Type__c AND Customer__c = :selectedAddressDetail.Customer__c];

            if (existedAddr.size() > 0 && selectedAddressDetail.Id != existedAddr[0].Id) {
                ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR, 'Error: This member already has an address of this type on their account. Please choose a different type or edit an existing address on the account.'));
                return;
            }

            Data.modify(selectedAddressDetail);

            if (dependentIdList != null) {
                Map<Id,List<Address__c>> idMap = new Map<Id,List<Address__c>>();

                List<Address__c> adrList = new List<Address__c>([
                    SELECT id, Customer__c
                    FROM Address__c
                    WHERE Type__c = :addressTypeBeforeEdit
                    AND Customer__c IN :dependentIdList
                    AND Copied_From_Dependent__c = true
                ]);

                for (Address__c adr : adrList) {
                    if (idMap.get(adr.Customer__c) == null) {
                        idMap.put(adr.Customer__c, new List<Address__c>{adr});
                    } else {
                        List<Address__c> updatedList = idMap.get(adr.Customer__c);
                        updatedList.add(adr);
                        idMap.put(adr.Customer__c, updatedList);
                    }
                }

                for (Id dependent : dependentIdList) {
                    Address__c address = new Address__c();

                    address = selectedAddressDetail.clone(false, true);

                    if (idMap.get(dependent) != null) {
                        address.Id = idMap.get(dependent)[0].Id;
                    }

                    address.Customer__c = String.valueOf(dependent);
                    dependentListToInsertEditedAddress.add(address);
                }
            }

            List<Id> dependentListToInsertEditedAddressIdList = new List<Id>();

            for (Address__c adr : dependentListToInsertEditedAddress) {
                dependentListToInsertEditedAddressIdList.add(adr.Customer__c);
            }

            List<Address__c> existedAddr1 = new List<Address__c>([
                SELECT id
                FROM Address__c
                WHERE Type__c = :selectedAddressDetail.Type__c
                AND Customer__c IN :dependentListToInsertEditedAddressIdList
            ]);

            for (Integer i = 0; i < dependentListToInsertEditedAddress.size(); i++) {
                if (existedAddr1.size() > 0) {
                    exist = true;
                    depLFIA.add(dependentListToInsertEditedAddress[i]);
                } else {
                    dependentListToInsertEditedAddress[i].Copied_From_Dependent__c = true;
                    dependentIdList1.add(dependentListToInsertEditedAddress[i]);
                }
            }

            // if dependent(s) are unchecked
            if (exist == false) {
                editPopupBoolean = false;
                refPage = true;

                for (Integer i = 0; i < dependentListOfSelectedAddressType.size(); i++) {
                    Address__c con = dependentListOfSelectedAddressType[i];
                    con.id = dependentListOfSelectedAddressType[i].id;
                    boolean flag = false;

                    if (dependentListToInsertEditedAddress.size() < 1) {
                        if (con.Copied_From_Dependent__c == true) {
                            flag = true;
                            con.Copied_From_Dependent__c = false;
                        }
                    }

                    for (Address__c add : dependentListToInsertEditedAddress) {
                        if (con.Customer__c == add.Customer__c) {
                            flag = true;
                        }
                    }

                    if (flag == false) {
                        if (con.Copied_From_Dependent__c == true) {
                            con.Copied_From_Dependent__c = false;
                        }
                    }
                }

                Data.upsurt(dependentListToInsertEditedAddress,Address__c.Id.getDescribe().getSObjectField(),new Set<String>());
            } else {
                // Trigger confirmation: This Address Type already exists on some Dependent. Are you sure You want to Add/Update it?
                Integer addressCount = dependentListToInsertEditedAddress.size();
                List<Id> customerIdList = new List<Id>();

                for (Integer k = 0; k < addressCount; k++) {
                    customerIdList.add(String.valueOf(dependentListToInsertEditedAddress[k].Customer__c));
                }

                List<Contact> contactHavingSameAddressTypeList = new List<Contact>([
                    SELECT Contact.Name, Contact.Relationship__c, Contact.Id
                    FROM Contact
                    WHERE Id IN :customerIdList
                ]);

                List<Address__c> addressL = new List<Address__c>([
                    SELECT Street_1__c, Street_2__c, Street_3__c, City__c, State_Province__c
                    FROM Address__c
                    WHERE Type__c = :selectedAddressDetail.Type__c AND Customer__c IN :contactHavingSameAddressTypeList
                ]);

                List<Address__c> conList = new List<Address__c>();

                for (Integer j = 0; j < dependentListToInsertEditedAddress.size(); j++) {
                    Contact contactHavingSameAddressType = contactHavingSameAddressTypeList[j];

                    if (addressL.size() > 0) {
                        currentSharedAddressList.add(contactHavingSameAddressType.Name);
                    }

                    for (Integer i = 0; i < dependentListOfSelectedAddressType.size(); i++) {
                        Address__c con = dependentListOfSelectedAddressType[i];
                        con.id = dependentListOfSelectedAddressType[i].id;
                        boolean flag = false;

                        if (dependentIdList1.size() < 1) {
                            if (con.Copied_From_Dependent__c == true) {
                                flag = true;
                                con.Copied_From_Dependent__c = false;
                            }
                        }

                        for (Address__c add : dependentIdList1) {
                            if (depLFIA.size() < 1) {
                                if (con.Copied_From_Dependent__c == true) {
                                    flag = true;
                                    con.Copied_From_Dependent__c = false;
                                }
                            }

                            for (Address__c depF : depLFIA) {
                                if (con.Customer__c != add.Customer__c && con.Customer__c != depF.Customer__c) {
                                    if (con.Copied_From_Dependent__c == true) {
                                        flag = true;
                                        con.Copied_From_Dependent__c = false;
                                    }
                                }
                            }
                        }

                        if (flag) {
                            conList.add(con);
                        }
                    }
                }

                Data.modify(conList);
                Data.upsurt(dependentIdList1,Address__c.Id.getDescribe().getSObjectField(),new Set<String>());
                saveOnDependentBoolean = true;
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Error : ' + e.getMessage()));
        }
    }

    // to save edited address on dependent if already exists
    public PageReference saveDependentAdd() {
        if (!Schema.sObjectType.Address__c.isDeletable()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Error: You do not have permission to delete addresses.'));
            return null;
        }

        try {
            memberId = String.escapeSingleQuotes(memberId.trim()); // clean memberId from potential second order SOQL injection

            Map<Id, List<Address__c>> depLFIAMap = new Map<Id, List<Address__c>>();
            List<String> depLFIATypeList = new List<String>();
            List<Id> depLFIACustomerList = new List<Id>();
            List<Id> addressIdList = new List<Id>();

            for (Address__c depAdr : depLFIA) {
                depLFIATypeList.add(depAdr.Type__c);
                depLFIACustomerList.add(depAdr.Customer__c);
            }

            for (Address__c adr : [
                SELECT id, Customer__c, Type__c
                FROM Address__c
                WHERE Type__c IN :depLFIATypeList
                AND Customer__c IN :depLFIACustomerList
                AND Copied_From_Dependent__c = false
            ]) {
                if (depLFIAMap.get(adr.Customer__c) == null) {
                    depLFIAMap.put(adr.Customer__c, new List<Address__c>{adr});
                } else {
                    List<Address__c> updatedList = depLFIAMap.get(adr.Customer__c);
                    updatedList.add(adr);
                    depLFIAMap.put(adr.Customer__c, updatedList);
                }
            }

            for (Integer i = 0; i < depLFIA.size(); i++) {
                List<Address__c> addressWithTypeSameAsOfdepLFIA = new List<Address__c>();

                if (depLFIA[i].Customer__c != null && depLFIAMap.get(depLFIA[i].Customer__c) != null) {
                    for (Address__c adr : depLFIAMap.get(depLFIA[i].Customer__c)) {
                        if (adr.Type__c == depLFIA[i].Type__c) {
                            addressWithTypeSameAsOfdepLFIA.add(adr);
                        }
                    }
                }

                if (addressWithTypeSameAsOfdepLFIA.size() > 0) {
                    depLFIA[i].id = addressWithTypeSameAsOfdepLFIA[0].id;
                }

                if (selectedAddressDetail.Type__c != addressTypeBeforeEdit) {
                    addressIdList.add(depLFIA[i].Customer__c);
                }

                depLFIA[i].Copied_From_Dependent__c = true;
            }

            List<Address__c> addressIds = (List<Address__c>)Data.read(
                'SELECT id FROM Address__c WHERE Type__c = :selectedAddressDetailType AND Customer__c IN :addressIdList',
                new Map<String, Object> {
                    'selectedAddressDetailType' => selectedAddressDetail.Type__c,
                    'addressIdList' => addressIdList
                }
            );

            Data.remove(addressIds);
            Data.upsurt(depLFIA,Address__c.Id.getDescribe().getSObjectField(),new Set<String>());

            addNewAddressBoolean = false;
            editPopupBoolean = false;

            PageReference pg = Page.manageAddresses;
            pg.getParameters().put('memberId', memberId);
            pg.setRedirect(true);
            return pg;
        } catch (Exception e) {
            ApexPages.addMessage(new  ApexPages.message(ApexPages.Severity.ERROR, 'Error : ' + e.getMessage()));
            return null;
        }
    }

    // to make copied to false if no selected for dependents while editing
    public PageReference makeFalseCopiedToIfNoEditSelected() {
        List<Address__c> addList = new List<Address__c>();
        List<Address__c> conList = new List<Address__c>();

        if (depLFIA != null) {
            List<Id> customerList = new List<Id>();

            for (Address__c adr : depLFIA) {
                customerList.add(adr.Customer__c);
            }

            List<Address__c> addresList = new List<Address__c>([
                SELECT id, Copied_From_Dependent__c
                FROM Address__c
                WHERE Type__c = :addressTypeBeforeEdit
                AND Customer__c IN :customerList
            ]);


            for (Address__c adr : addresList) {
                if (adr.Copied_From_Dependent__c == true) {
                    adr.Copied_From_Dependent__c = false;
                    addList.add(adr);
                }
            }


            for (Integer i = 0; i < dependentListOfSelectedAddressType.size(); i++) {
                Address__c con = dependentListOfSelectedAddressType[i];
                con.id = dependentListOfSelectedAddressType[i].id;
                boolean flag = false;

                if (depLFIA.size() < 1) {
                    if (con.Copied_From_Dependent__c == true) {
                        flag = true;
                        con.Copied_From_Dependent__c = false;
                    }
                }

                for (Address__c add : depLFIA) {
                    if (con.Customer__c != add.Customer__c) {
                        if (con.Copied_From_Dependent__c == true) {
                            flag = true;
                            con.Copied_From_Dependent__c = false;
                        }
                    }
                }

                if (flag) {
                    conList.add(con);
                }
            }


            Data.modify(conList);
        }

        if (addList.size() > 0) {
            Data.modify(addList);
        }

        PageReference pg = Page.manageAddresses;
        pg.getParameters().put('memberId', memberId);
        pg.setRedirect(true);
        return pg;
    }

    public PageReference checkId() {
        Contact con;
        String getParam = ApexPages.currentPage().getParameters().get('memberId');

        memberId = String.escapeSingleQuotes(getParam);
        isDependent = false;
        isMember = false;

        if (ApexPages.currentPage().getParameters().get('primaryMemId') != null) {
            primaryMemberId = ApexPages.currentPage().getParameters().get('primaryMemId');
            dependentPrimaryName = service.getDependentsPrimaryMemberName(primaryMemberId);
        }

        if (memberId != null) {
            service.setcurrentMemberContactRecordService(memberId);
            Id MemRecTypeId = Utility.searchRecordType('Member', 'Contact');
            Id receProcalRecTypeId = Utility.searchRecordType('Reciprocal Club', 'Contact');
            //con = new cmsft_ContactSelector().getAllContactsWithTheDynamicCondition('where id=\'' + memberId + '\' AND RecordTypeId =\'' + MemRecTypeId + '\'').get(0);           
            con = new cmsft_ContactSelector().getAllContactsWithTheDynamicCondition('where id=\'' + memberId + '\' AND (RecordTypeId =\'' + MemRecTypeId + '\' OR RecordTypeId =\''+receProcalRecTypeId+'\')').get(0);
            //con = new cmsft_ContactSelector().getAllContactsWithTheDynamicCondition('where id=\'' + memberId).get(0);
            memberName = con.Name;

            AccountId = con.AccountID;
        }

        deletePopupBoolean = false;
        addNewAddressBoolean = false;
        selectedAddressDetail = new  Address__c();
        selectedFromMonth=1;
        selectedFromDay=1;
        selectedToMonth=12;
        selectedToDay=31;

        addressList = service.getAllAddressesOfCurrentContactService();

        if (con.Relationship__c == 'Primary') {
            isMember = true;
        } else {
            isDependent = true;
        }

        forColorChange = '';
        TableData = service.getDependentListWithSharedAndCommonAddressService(isMember);

        if (isDependent) {
            if (TableData.get(0) != null) {
                for (ManageAddressServiceImpl.AddressRows commonAddress : TableData.get(0).sharedaddressList) {
                    forColorChange = forColorChange + commonAddress.addressName;
                }
            }
        }

        if (AccountId == '' || AccountId == null) {
            accountNameBlankError = true;
        }

        return null;
    }

    public List<SelectOption> getMonths() {
        List<SelectOption> options = new List<SelectOption>();

        options.add(new SelectOption(String.valueOf(1), 'January'));
        options.add(new SelectOption(String.valueOf(2), 'February'));
        options.add(new SelectOption(String.valueOf(3), 'March'));
        options.add(new SelectOption(String.valueOf(4), 'April'));
        options.add(new SelectOption(String.valueOf(5), 'May'));
        options.add(new SelectOption(String.valueOf(6), 'June'));
        options.add(new SelectOption(String.valueOf(7), 'July'));
        options.add(new SelectOption(String.valueOf(8), 'August'));
        options.add(new SelectOption(String.valueOf(9), 'September'));
        options.add(new SelectOption(String.valueOf(10), 'October'));
        options.add(new SelectOption(String.valueOf(11), 'November'));
        options.add(new SelectOption(String.valueOf(12), 'December'));

        return options;
    }

    public List<SelectOption> getDays() {
        List<SelectOption> options = new List<SelectOption>();

        for(Integer i = 1; i<=31; i++)
            options.add(new SelectOption(String.valueOf(i), String.valueOf(i)));

        return options;
    }

    public static Date getDateFromValues(Integer month, Integer day, Boolean isToDate)
    {
        if(month <=0 || day <=0)
            throw new Utility.CustomException('Please select valid month and day');

        // Check to make sure day is valid for the month
        if(month==2) // Feb
        {
            if(day > 28)
                throw new Utility.CustomException('Please select a day that is valid for the month');
        }
        else if(month==4 || month==6 || month==9 || month==11)
        {
            if(day > 30)
                throw new Utility.CustomException('Please select a day that is valid for the month');
        }

        Integer year = 2099;
        if(isToDate) // allows the To date to always be ahead of the From date.
            year = 2100;

        return Date.newInstance(year, month, day); // Way in the future. All that matters are the month and day
    }
}