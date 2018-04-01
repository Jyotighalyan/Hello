/**
* @author joshi Prakash
* @date 09-22-2017
* @group Event management
* @description Controller class containing the test code for room agenda.
 **/
@isTest
private class RoomsAgendaControllerTest {
	@isTest
	static void addRoom() {
		/*Set Rooms Agenda as test page.*/
		PageReference pageRef = Page.RoomsAgenda;
		Test.setCurrentPage(pageRef);

		User ftUser = UserTest.createForeTeesUser();
		System.runAs(ftUser) {

			Event__c event = TestHandler.getEvent();
			event.RecordTypeId = Utility.searchRecordType('Sponsored Event', 'Event__c');
			update event;

			Location__c loc = new Location__c(Name = 'Test Location', Location__c = 'North Campus', Status__c = 'In Use');
			insert loc;

			Location__c loc2 = new Location__c(Name = 'child location', Location__c = 'North Campus2', Status__c = 'In Use', Parent_Facility__c = loc.id);
			insert loc2;

			ApexPages.currentPage().getParameters().put('id', event.id);

			Test.startTest();
			RoomsAgendaController apc = new RoomsAgendaController();
			//Create the related event without conflict
			apc.addNew();
			apc.clstGI.get(1).res.Location__c = loc.id;
			apc.addNew();
			apc.clstGI.get(2).res.Location__c = loc.id;
			apc.clstGI.get(2).res.StartTime__c = System.now().addHours(4);
			apc.clstGI.get(2).res.EndTime__c = System.now().addHours(6);
			apc.saveRec();

			System.assertEquals(apc.clstGI.size(), 3);
			//Create the reservation with time conflict
			apc.addNew();
			apc.clstGI.get(3).res.Location__c = loc.id;
			apc.saveRec();

			apc.BackToEvent();
			Test.stopTest();
		}
	}
}