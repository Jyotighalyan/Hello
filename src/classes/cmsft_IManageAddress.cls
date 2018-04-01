public interface cmsft_IManageAddress {

	//Define the method signature to be implemented in classes that implements the interface
	//Example method
	void setcurrentMemberContactRecord(Id member);
	List<String> getListOfNamesAlreadyHaveType(List<Address__c> listOfAddresses);
	//List<Address__c> saveNewAddressOnDependents(Address__c newAddress, List<cmsft_C62manageAddressServiceImpl.tableRow> dependentsListWithCopyOrNotStatus);
	//List<cmsft_C62manageAddressServiceImpl.tableRow> getDependentListForAddNewAddressPopup();
	string getDependentsPrimaryMemberName(Id dependentPrimaryMemId);
	List<List<Address__c>> getAllAddressesListToShowUpOnLandingPage();
}