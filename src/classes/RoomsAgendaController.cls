/*
@Name            : RoomsAgendaController
@Author          : joshi@3embed
@Date            : Sept 13, 2017
@Description     : Controller for display the related reservation and create and update the related reservation.
*/
public with sharing class RoomsAgendaController {

	//Class variables
	public Event__c res {get; set;}
	public List<GridItem> clstGI {get; set;}
	public Integer cIndex {get; set;}
	/*
	@Name : RoomsAgendaController
	@Description : Constructor to initalize the Rooms Agenda Page
	*/
	public RoomsAgendaController() {
		//Getting URL parameter to get reservation ID
		String recID = Apexpages.currentPage().getParameters().get('id');
		if (recID != null && recID != '') {
			Schema.SOBjectType sT = ((id)recID).getsObjectType();
			if (st.getDescribe().getName() == 'Event__c') {
				//Query Reservation
				List<Event__c> resLst = (List<Event__c>)Data.read('SELECT RecordType.Name,Location__r.Name,' + Utility.getFields('Event__c')
				                        + ' FROM Event__c WHERE ID =:eventid',

				new Map<String, Object> {
					'eventid' => recID
				});

				if (resLst.size() > 0) {
					res = resLst.get(0);
					prepareGridItemLst();
				}
			} else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invaild banquet Id.'));
			}
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invaild banquet Id.'));
		}
	}

	/*
	  @Name   :addNew
	  @Description :adds a new related reservation
	  */
	public void addNew() {
		GridItem gi = new GridItem();
		gi.index = 'new' + cIndex++;
		gi.isNew = true;
		gi.res = res.clone();
		gi.res.Is_Clone__c = true;
		gi.res.Parent_Reservation__c = res.Id;

		if (res.RecordType.Name == 'Sponsored Event' || res.RecordType.Name == 'Sponsored Event - Child') {
			gi.res.RecordTypeId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Sponsored Event - Child').getRecordTypeId();
		} 

		gi.res.Has_Children__c = FALSE;
		gi.res.Location__c = null;
		gi.res.Booked_Date__c = DateTime.Now();
		gi.res.Setup_Type__c = null;
		gi.res.Room_Setup_Details__c = null;
		gi.res.Post_Close_Date_Time__c = null;
		gi.res.Setup_Time__c = 'Half Hour';
		gi.res.Cleanup_Time__c = 'Half Hour';
		gi.res.External_Location__c = null;
		gi.res.Street_Address__c = null;
		gi.res.City__c = null;
		gi.res.State_Province__c = null;
		gi.res.Zip__c = null;
		gi.res.Deposit_Received_Date__c = null;
		gi.res.Deposit_Amount__c = null;
		gi.res.Deposit_Received__c = false;		
		gi.canFlag = false;
		clstGI.add(gi);
	}

	/*
	@Name   :saveRec
	@Description :Save multiple records
	*/
	public pageReference saveRec() {
		SavePoint sp = Database.setSavePoint();
		try {
	
			List<Event__c> resLst = new List<Event__c>();
			for (GridItem gi : clstGI) {
				gi.cErrorHighlight = '';
				//Check to get required information
				if (gi.res.Name == null || gi.res.Name == '' || gi.res.StartTime__c == null || gi.res.EndTime__c == null
				        || gi.res.Location__c == null) {
					throw new Utility.CustomException('Please enter the required information.');
				} else {
					if (gi.canFlag == true && gi.res.Status__c != 'Cancelled') { gi.res.Status__c = 'Cancelled'; }
					if (gi.res.Id != null && gi.res.Parent_Reservation__c == null && clstGI.size() > 1) {
						gi.res.Has_Children__c = true;
					}

					if(gi.isNew==true)
					{
						gi.res.Id = null;
					}

					resLst.add(gi.res);								
				}				
			}
		
			if (resLst.size() > 0 && Schema.sObjectType.Event__c.isCreateable()
			        && Schema.sObjectType.Event__c.isUpdateable()) {

				//upsert resLst;
				Data.upsurt(resLst, Event__c.Id.getDescribe().getSObjectField(), new Set<String>());
				Map<ID, Event__c> resMap = new Map<ID, Event__c>(resLst);
				Map<ID, ID> reserClubFa = new Map<ID, ID>();
				for (Event__c r : resLst) {
					reserClubFa.put(r.Id, r.Location__c);
				}

				List<Location__c> facilityLst = (List<Location__c>)Data.read('SELECT Id, Name, Parent_Facility__c FROM Location__c WHERE Id IN :locationIds',
				new Map<String, Object> {
					'locationIds' => reserClubFa.values()
				});

				Map<ID, List<Location__c>> facilityResLst = new Map<ID, List<Location__c>>();
				for (Location__c f : facilityLst) {
					facilityResLst.put(f.Id, new List<Location__c>());
					//Add all facilities parent and child				
					facilityResLst.get(f.Id).addAll(Utility.getChildFacilities(new List<Location__c> {f}));
				}

				List<Event__c> parentTrgEvent = (List<Event__c>)Data.read('SELECT Id, Location__c, Cleanup_Time__c, Setup_Time__c, StartTime__c, EndTime__c,'
												+ ' Status__c, SponsoringMember__c, Sponsoring_Customer__c, Contract_Due_Date__c, Max_Seats__c,'
												+ ' (SELECT Id, Name, StartTime__c, EndTime__c,'												
				                                + ' Location__c FROM Reservations__r WHERE RecordType.Name =:recordtype)'
				                                + ' FROM Event__c'
				                                + ' WHERE Id IN :eventIds',

				new Map<String, Object> {
					'recordtype' => 'Reserved',
					'eventIds' => reserClubFa.keySet()
				});
					
				List<Event__c> lstReservations = new List<Event__c>();
				List<Event__c> lstDelete = new List<Event__c>();

				for (Event__c pTrgEvt : parentTrgEvent) {
					List<Event__c> existingReserved = new List<Event__c>();
					for (Event__c rEvt : pTrgEvt.Reservations__r) {
						existingReserved.add(rEvt);
					}

					Map<Id, Event__c> mapFacEvents = new Map<Id, Event__c>();
					for (Event__c event : existingReserved) {
						mapFacEvents.put(event.Location__c, event);
					}
				
					Set<Id> setChainEventIds = new Set<Id>();
					if (facilityResLst.size() > 0 && facilityResLst.containsKey(pTrgEvt.Location__c)) {
						for (Location__c fac : facilityResLst.get(pTrgEvt.Location__c)) {
							if (mapFacEvents.containsKey(fac.Id)) {
								//Move the time
								Event__c event = mapFacEvents.get(fac.Id);
								event.StartTime__c = pTrgEvt.StartTime__c;
								event.EndTime__c = pTrgEvt.EndTime__c;
								event.Setup_Time__c = pTrgEvt.Setup_Time__c;
								event.Cleanup_Time__c = pTrgEvt.Cleanup_Time__c;								
								lstReservations.add(event);
								setChainEventIds.add(mapFacEvents.get(fac.Id).Id);
							} else {
								//Create the reservation
								Event__c event = new Event__c(
								    Name = 'Reserved',								  
								    StartTime__c = pTrgEvt.StartTime__c,
								    EndTime__c = pTrgEvt.EndTime__c,
								    Parent_Reservation__c = pTrgEvt.id,
								    RecordTypeId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Reserved').getRecordTypeId(),
								    Location__c = fac.id,
								    Setup_Time__c = pTrgEvt.Setup_Time__c,
								    Cleanup_Time__c = pTrgEvt.Cleanup_Time__c,
								    Status__c = pTrgEvt.Status__c,
								    Contract_Due_Date__c = pTrgEvt.Contract_Due_Date__c,
								    SponsoringMember__c = pTrgEvt.SponsoringMember__c,
								    Sponsoring_Customer__c = pTrgEvt.Sponsoring_Customer__c,
								    Max_Seats__c = pTrgEvt.Max_Seats__c
								);
								lstReservations.add(event);
							}
						}
					}
					//Delete the reserved events that are not part of the hierarchy
					for (Event__c event : existingReserved) {
						if (!setChainEventIds.contains(event.id)) {
							lstDelete.add(event);
						}
					}
				}			
				//upsert lstReservations;
				Data.upsurt(lstReservations, Event__c.Id.getDescribe().getSObjectField(), new Set<String>());
				Data.remove(lstDelete);
				resLst.addAll(lstReservations);

				List<Event__c> conflictList = new List<Event__c>();
				conflictList.addAll(resLst);

				Set<Id> locationIdSet = new Set<Id>();
				for (Event__c r : resLst) {
					locationIdSet.add(r.Location__c);
				}

				List<Event__c> allReservations = (List<Event__c>)Data.read(
				                                     'SELECT Id, Location__c, SetupTime__c, CleanupTime__c from Event__c'
				                                     + ' WHERE Status__c !=:Cancelled AND Location__c IN :locations',
				new Map<String, Object> {
					'Cancelled' => 'Cancelled',
					'locations' => locationIdSet
				});

				map<String, Double> setupCleanupMap = new Map<String, Double> {
					'Half Hour' => 0.02083,
					'1 Hour' => 0.04166,
					'2 Hours' => 0.08333
				};

				Datetime starttime;
				Datetime endtime;

				for (Event__c relatedEvent : conflictList) {

					starttime = relatedEvent.StartTime__c;
					endtime = relatedEvent.EndTime__c;

					if (relatedEvent.Setup_Time__c != null) {
						starttime = relatedEvent.StartTime__c - setupCleanupMap.get(relatedEvent.Setup_Time__c);
					}

					if (relatedEvent.Cleanup_Time__c != null) {
						endtime = relatedEvent.EndTime__c + setupCleanupMap.get(relatedEvent.Cleanup_Time__c);
					}

					for (Event__c existingEvent : allReservations) {
						if (existingEvent.Location__c == relatedEvent.Location__c && existingEvent.Id != relatedEvent.Id && ((existingEvent.SetupTime__c >= starttime && existingEvent.SetupTime__c <= endtime) || (existingEvent.CleanupTime__c >= starttime && existingEvent.CleanupTime__c <= endtime) || (starttime>= existingEvent.SetupTime__c && endtime<= existingEvent.CleanupTime__c))) {
							throw new Utility.CustomException('There is time conflict with an existing event. Please try again with a differet time.');
						}
					}
				}

				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Saved Successfully!'));
				prepareGridItemLst();

			}
		} catch (DMLException e) {
			Integer numErrors = e.getNumDml();
			Integer iError;
			for (Integer i = 0; i < numErrors; i++) {
				iError = e.getDmlIndex(i);
			}
			if (iError != null) { clstGI.get(iError).cErrorHighlight = 'Error'; }			
			ApexPages.addMessages(e);			
			Database.rollBack(sp);
		} catch (Exception e) {			
			ApexPages.addMessages(e);
			Database.rollBack(sp);
		}
		return null;
	}

	//Prepare Grid Item list
	public void prepareGridItemLst() {

		cIndex = 0;
		clstGI = new List<GridItem>();		
		List<Event__c> relResLst = (List<Event__c>)Data.read('SELECT  RecordType.Name, Location__r.Name, ' + Utility.getFields('Event__c')
		                           + ', (SELECT RecordType.Name,Location__r.Name,' + Utility.getFields('Event__c')
		                           + ' FROM Reservations__r WHERE Parent_Reservation__c=:parenteventid AND (Status__c !=:childstatus)'
		                           + ' AND RecordType.Name!=:recordtype) FROM Event__c WHERE ID =:eventid AND (Status__c !=:eventstatus)',

		new Map<String, Object> {
			'parenteventid' => res.Id,
			'childstatus' => 'Cancelled',
			'recordtype' => 'Reserved',
			'eventid' => res.Id,
			'eventstatus' => 'Cancelled'
		});

		//Prepare Grid Item wrapper to bind the reservation values
		for (Event__c r : relResLst) {
			GridItem gi = new GridItem();
			gi.index = 'new' + cIndex++;
			gi.rccID = r.Id;
			gi.res = r;
			gi.canFlag = false;
			gi.isNew = false;
			clstGI.add(gi);
			//For child reservations
			for (Event__c res : r.Reservations__r) {
				GridItem gii = new GridItem();
				gii.index = 'new' + cIndex++;
				gii.rccID = res.Id;
				gii.res = res;
				gii.canFlag = false;
				clstGI.add(gii);
			}
		}
	}

	/*
	@Name   :backTORes
	@Description :backTORes records
	*/
	public pageReference BackToEvent() {
		return new PageReference('/' + res.Id);
	}
	/*
	@Name   :GridItem
	@Description :Inner class for grid items
	*/
	public class GridItem {
		public Event__c res {get; set;}
		public Boolean canFlag {get; set;}
		public String index {get; set;}
		public String rccID {get; set;}
		public String cErrorHighlight {get; set;}
		public Boolean isNew {get; set;}
	}
}