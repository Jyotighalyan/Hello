/**
* @author joshi Prakash
* @date 09-22-2017
* @group Event management
* @description Controller class containing the test code for cancel event.
 **/
@isTest
private class CancelEventControllerTest
{
	@isTest
	static void cancelParentEvent() {
		/*Set CancelBanquet as test page.*/
		PageReference pageRef = Page.CancelBanquet;
		Test.setCurrentPage(pageRef);

		User ftUser = UserTest.createForeTeesUser();
		System.runAs(ftUser) {
			Event__c event = TestHandler.getEvent();
			event.RecordTypeId = Utility.searchRecordType('Sponsored Event', 'Event__c');
			update event;

			Event__c childEvent = TestHandler.getEvent();
			childEvent.Parent_Reservation__c = event.Id;
			update childEvent;
						
			ApexPages.currentPage().getParameters().put('id', event.id);
			Test.startTest();
			CancelEventController apc = new CancelEventController();
			PageReference p = apc.cancelEvent();
			System.assertNotEquals(p,null);
			Test.stopTest();
		}
	}

	@isTest
	static void cancelChildEvent() {
		/*Set Cancel Banquet as test page.*/
		PageReference pageRef = Page.CancelBanquet;
		Test.setCurrentPage(pageRef);

		User ftUser = UserTest.createForeTeesUser();
		System.runAs(ftUser) {
			Event__c event = TestHandler.getEvent();
			event.RecordTypeId = Utility.searchRecordType('Sponsored Event', 'Event__c');
			update event;

			Event__c childEvent = TestHandler.getEvent();
			childEvent.Parent_Reservation__c = event.Id;
			update childEvent;
						
			ApexPages.currentPage().getParameters().put('id', childEvent.id);
			Test.startTest();
			CancelEventController apc = new CancelEventController();
			PageReference p = apc.cancelChild();
			System.assertNotEquals(p,null);
			Test.stopTest();
		}
	}
}