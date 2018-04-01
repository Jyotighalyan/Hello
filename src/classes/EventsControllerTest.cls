/**
* @author joshi Prakash
* @date 07-18-2017
* @group Event management
* @description Controller class containing the test code for event calendar.
 **/
@isTest
private class EventsControllerTest {
	@isTest
	static void filterEventsTest() {
		/*Set event calendar as test page.*/
		PageReference pageRef = Page.Events;
		Test.setCurrentPage(pageRef);

		Contact contact = TestHandler.getContact('Member');

		Event__c event = new Event__c();
		event.Name = 'Test Event';
		event.Location__c = TestHandler.getLocation().id;
		event.Status__c = 'Tentative';
		event.Sponsoring_Customer__c = contact.id;
		event.SponsoringMember__c = contact.id;
		event.StartTime__c = System.now();
		event.EndTime__c = System.now().addHours(2);
		event.Setup_Time__c = 'Half Hour';
		event.Cleanup_Time__c = 'Half Hour';
		event.Contract_Due_Date__c = System.today();
		event.Max_Seats__c = 20;
		insert event;

		Test.startTest();

		EventsController apc = new EventsController();
		apc.filterEvent.StartTime__c = System.now().addDays(-1);
		apc.filterEvent.EndTime__c = System.now().addDays(1);
		apc.filterEvent.Status__c = 'Tentative';
		apc.filterEvent.SponsoringMember__c = contact.id;
		apc.filterEvent.Sponsoring_Customer__c = contact.id;

		apc.getFilteredEvents();
		System.assertEquals(1, apc.filterResultList.size());

		Test.stopTest();
	}

	@isTest
	static void calendarTest() {
		/*Set event calendar as test page.*/
		PageReference pageRef = Page.Events;
		Test.setCurrentPage(pageRef);

		//Create contact
		Contact contact = TestHandler.getContact('Member');

		//Create event calendar options
		EventCalendarOptions__c calenderOption = new EventCalendarOptions__c();
		calenderOption.End_Hour__c = 23;
		calenderOption.Slot_Minutes__c = 30;
		calenderOption.Start_Hour__c = 8;
		Data.create(calenderOption);

		//Create parent and child location.
		Location__c parentLoc = TestHandler.getLocation();
		Location__c childLoc = TestHandler.getLocation();
		childLoc.Parent_Facility__c = parentLoc.Id;
		data.modify(childLoc);

		Test.startTest();

		EventsController apc = new EventsController();
		System.assertEquals(8, apc.getStartHour());
		System.assertEquals(23, apc.getEndHour());
		System.assertEquals(30, apc.getSlotMinutes());

		System.assertNotEquals(null, apc.getResources());

		//Create reservation equvals to the drag on the calendar.
		apc.cStartDt = System.now().getTime();
		apc.cEndDt = System.now().addHours(2).getTime();
		apc.cFacId = parentLoc.Id;
		apc.cRTName = 'Sponsored Event';
		apc.createReservation();

		//fill all the required field from the pop up.
		apc.cReservation.Name = 'Test Event';
		apc.cReservation.Location__c = parentLoc.Id;
		apc.cReservation.Sponsoring_Customer__c = contact.id;
		apc.cReservation.SponsoringMember__c = contact.id;
		apc.cReservation.Contract_Due_Date__c = System.today();
		apc.cReservation.Max_Seats__c = 20;
		apc.cReservation.Status__c = 'Tentative';
		apc.cReservation.StartTime__c = System.now();
        apc.cReservation.EndTime__c = System.now().addHours(2);              
        apc.cReservation.Setup_Time__c = 'Half Hour';
        apc.cReservation.Cleanup_Time__c = 'Half Hour';

		apc.saveReservation();

		System.assertEquals(2,Data.read('SELECT id from Event__c',new  Map<String,Object>()).size());

		DateTime currentDate = System.today();
		DateTime startTime = currentDate.addHours(8);
		DateTime endTime = currentDate.addHours(23);

		//Get all created reservations to show on the calendar
		EventsController.getEvents(startTime.getTime(), endTime.getTime(), new List<String> {'Sponsored Event'}, new List<String> {'Event'});				
		//Other manual functions
		apc.closePopup();
		apc.gotoDetails();

		EventsController.cmapRT = null;
		EventsController.cmapVARs  = null;

		System.assertNotEquals(null,EventsController.cmapRT);
		System.assertNotEquals(null,EventsController.cmapVARs);

		/** make sure this method is also covering createUnavailableReservation method of evenObjectTrigger**/

		Event__c event = (Event__c)Data.read('SELECT Id, Name from Event__c where Name = :name',
			new  Map<String,Object>{
				'name'=>'Test Event'
			}).get(0);

		Data.modify(event);
		Test.stopTest();
	}
}