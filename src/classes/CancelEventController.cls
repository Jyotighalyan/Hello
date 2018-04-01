public with sharing class CancelEventController {
	public boolean isShowPopUp {get; set;}
	public boolean isInfoPopUp {get; set;}
	public String eventId {get; set;}
	public Event__c event {get; set;}

	public CancelEventController() {
		isShowPopUp = false;
		isInfoPopUp = false;
		eventId = Apexpages.currentPage().getParameters().get('Id');

		//Query Reservation
		List<Event__c> eventList = (List<Event__c>)Data.read('SELECT Id, Name, Status__c, Cancellation_Date__c, Parent_Reservation__c'
		                           + ' FROM Event__c WHERE ID =:eventid',

		new Map<String, Object> {
			'eventid' => eventId
		});

		if (eventList.size() > 0) {
			event = eventList.get(0);
			if (event.Status__c == 'Cancelled'){
				isInfoPopUp = true;
			} else if (event.Parent_Reservation__c == null) {
				isShowPopUp = true;
			}
		}
	}

	public pageReference cancelChild() {
		if (event != null && isShowPopUp == false && isInfoPopUp ==false) {			
			return cancelEvent();
		}
		return null;
	}
	/*
	@Name   :backTORes
	@Description :backTORes records
	*/
	public pageReference backToEvent() {
		return new PageReference('/' + eventId);
	}

	public pageReference cancelEvent() {
		if (event != null) {
			List<Event__c> allEvents = new List<Event__c>();
			event.Cancellation_Date__c = System.today();
			event.Status__c = 'Cancelled';
			allEvents.add(event);
			//Query Reservation
			List<Event__c> eventList = (List<Event__c>)Data.read('SELECT Id, Name, Status__c, Cancellation_Date__c, Parent_Reservation__c'
			                           + ' FROM Event__c WHERE Parent_Reservation__c =:eventid and Status__c !=:Cancelled',

			new Map<String, Object> {
				'eventid' => eventId,
				'Cancelled' => 'Cancelled'
			});

			for (Event__c childEvent : eventList) {
				childEvent.Cancellation_Date__c = System.today();
				childEvent.Status__c = 'Cancelled';
				allEvents.add(childEvent);
			}

			Data.modify(allEvents);
			return backToEvent();
		}
		return null;
	}

}