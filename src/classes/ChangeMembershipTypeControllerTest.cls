@isTest
private class ChangeMembershipTypeControllerTest
{
	@isTest
	static void TestMethod1()
	{
		Account acc = TxnTestUtility.createAccount(Utility.searchRecordType('Household', 'Account'));
		Contact member = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member', 'Contact'));
		//Contact member1 = TxnTestUtility.createMember(acc, 'Dependent', Utility.searchRecordType('Member', 'Contact'));
		//member1.FirstName = 'ZTest';
		//member1.LastName = 'Test';
		//update member1;
		Test.setCurrentPage(Page.ChangeMembershipType);
		Test.startTest();
		ChangeMembershipTypeController changeMemCont = new ChangeMembershipTypeController();
		changeMemCont.next();
		changeMemCont.previous();
		System.assertEquals(changeMemCont.getTotalPages(), 1);
		changeMemCont.refreshPageSize();
		changeMemCont.first();
		changeMemCont.last();
		changeMemCont.isSelectAll = true;
		changeMemCont.selectAll();
		System.assertEquals(changeMemCont.listToShow[0].isUpdate, true);
		changeMemCont.changeMT();
		System.assertEquals(changeMemCont.selectedMemType, changeMemCont.listToShow[0].member.Membership_Type__c);
		ApexPages.currentPage().getParameters().put('columnName','Name');
		ApexPages.currentPage().getParameters().put('description','asc');
		changeMemCont.doSort();
		System.assertEquals(changeMemCont.listToShow[0].member.id, member.id);
		Test.stopTest();
	}
}