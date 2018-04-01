/**
 * See https://github.com/financialforcedev/fflib-apex-common for more info
 *
 * Install library via
 * https://githubsfdeploy.herokuapp.com/app/githubdeploy/financialforcedev/fflib-apex-common
 */

/**
 * Encapsulates all service layer logic for a given function or module in the application
 *
 * For more guidelines and details see
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Service_Layer
 *
 */
public class ManageAddressService {

    public ManageAddressServiceImpl serviceImpObj;

    // to get dependent's primary member name to show up on breadcrump
    public string getDependentsPrimaryMemberName(Id dependentPrimaryMemId) {
        return serviceImpObj.getDependentsPrimaryMemberName(dependentPrimaryMemId);
    }

    // to set a variable contact var so that address name and passes member id name can be fetched
    public void setcurrentMemberContactRecordService(Id memberId) {
        serviceImpObj.setcurrentMemberContactRecord(memberId);
    }

    // to get all addresses list for the current contact
    public List<List<Address__c>> getAllAddressesOfCurrentContactService() {
        return serviceImpObj.getAllAddressesListToShowUpOnLandingPage();
    }

    // to get all dependent list with shared and independent addresses list
    public List<ManageAddressServiceImpl.tableRow> getDependentListWithSharedAndCommonAddressService(boolean isMember) {
        return serviceImpObj.getDependentListWithSharedAndCommonAddress(isMember);
    }

    // to get dependents list to add new addresses
    public List<ManageAddressServiceImpl.tableRow> getDependentListForAddNewAddressPopupService() {
        return serviceImpObj.getDependentListForAddNewAddressPopup();
    }

    // to get list of addresses that have the new address type already and to save new addredd on selected dependents
    public List<Address__c> saveNewAddressOnDependentsService(Address__c newAddress, List<ManageAddressServiceImpl.tableRow> dependentsListWithCopyOrNotStatus) {
        return serviceImpObj.saveNewAddressOnDependents(newAddress, dependentsListWithCopyOrNotStatus);
    }

    // to get list of names to show on jquery modal
    public List<String> getListOfNamesAlreadyHaveTypeService(List<Address__c> listOfAddresses){
        return serviceImpObj.getListOfNamesAlreadyHaveType(listOfAddresses);
    }

    // to redirect to error page
    public PageReference RedirectToErrorPage(String Pg) {
        return ManageAddressServiceImpl.RedirectTo(Pg);
    }

    // to save addresses on dependents after confirmation through jquery popup - delete existing and save new one
    public PageReference saveAddressesAfterConfirmationOnJqueryPopupService(String addOrEdit, List<Address__c> depLFIA, String typeName){
        if (depLFIA!=null) {
            return serviceImpObj.saveAddressesAfterConfirmationOnJqueryPopup(addOrEdit, depLFIA, typeName);
        } else {
            return null;
        }
    }

    // to get address list of dependents with passed type
    public Map<String, List<ManageAddressServiceImpl.tableRow>> getMapOfDepsNCpdAddressesService(String selectedAddressForEditId){
        return serviceImpObj.getMapOfDepsNCpdAddresses(selectedAddressForEditId);
    }

    // to get selectedAddressForEdit
    public Address__c getselectedAddressForEdit(){
        return serviceImpObj.selectedAddressForEdit;
    }

    // get implementationclass of massEmail service
    public void service() {
        serviceImpObj = new ManageAddressServiceImpl();
    }
}