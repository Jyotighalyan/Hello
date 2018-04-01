/**
 *  Class containing methods for handling trigger behavior on the
 *  Event Object.
 */
public class EventObjectTriggerHandler {

    private static boolean run = true;
    /**
     * EventStatusCheckOnUpdate Method for checking the Status of the Event on update
     * @param  triggerNew    triggerNew State of Records after the update
     * @param  triggerOldMap triggerOldMap State of Records before the update
     */
    public static void EventStatusCheckOnUpdate(Map<Id, Event__c> triggerNewMap, Map<Id, Event__c> triggerOldMap) {
        if (run) {
            //Whitelist of fields that will not be tested for updates
            final String NAMESPACE_PREFIX = NameSpaceUtils.getNamespaceWithPrefix();
            Set<String> whitelist = new Set<String> {NAMESPACE_PREFIX+'status__c', 'lastmodifiedbyid', NAMESPACE_PREFIX+'post_close_date_time__c', 'lastmodifieddate', 'systemmodstamp', NAMESPACE_PREFIX+'adjustments__c', NAMESPACE_PREFIX+'additions__c',
             NAMESPACE_PREFIX+'amount_due__c',NAMESPACE_PREFIX+'total_charge_amount__c', NAMESPACE_PREFIX+'adjusted_gross_revenue__c',
             NAMESPACE_PREFIX+'price_per_plate_before_tax_service__c',NAMESPACE_PREFIX+'price_per_plate_after_tax_service__c',
             NAMESPACE_PREFIX+'payments_received__c',NAMESPACE_PREFIX+'total_adjustments__c',NAMESPACE_PREFIX+'total_taxes__c',
             NAMESPACE_PREFIX+'total_service_charges__c',NAMESPACE_PREFIX+'revenue__c',
             NAMESPACE_PREFIX+'liquor_amount__c',NAMESPACE_PREFIX+'liquor_service_charges__c',NAMESPACE_PREFIX+'liquor_taxes__c',
             NAMESPACE_PREFIX+'beverage_amount__c',NAMESPACE_PREFIX+'beverage_service_charges__c',NAMESPACE_PREFIX+'beverage_taxes__c',          
             NAMESPACE_PREFIX+'beverage_liquor_amount__c',NAMESPACE_PREFIX+'beverage_service_charges__c',NAMESPACE_PREFIX+'beverage_liquor_taxes__c',   
             NAMESPACE_PREFIX+'food_amount__c',NAMESPACE_PREFIX+'food_service_charges__c',NAMESPACE_PREFIX+'food_taxes__c',    
             NAMESPACE_PREFIX+'food_beverage_amount__c',NAMESPACE_PREFIX+'food_beverage_service_charges__c',NAMESPACE_PREFIX+'food_beverage_taxes__c',
             NAMESPACE_PREFIX+'gratuity_amount__c',NAMESPACE_PREFIX+'gratuity_service_charges__c',NAMESPACE_PREFIX+'gratuity_taxes__c',
             NAMESPACE_PREFIX+'labor_amount__c',NAMESPACE_PREFIX+'labor_service_charges__c',NAMESPACE_PREFIX+'labor_taxes__c',
             NAMESPACE_PREFIX+'miscellaneous_fees_amount__c',NAMESPACE_PREFIX+'miscellaneous_fees_service_charges__c',NAMESPACE_PREFIX+'Miscellaneous_Fees_Taxes__c',
             NAMESPACE_PREFIX+'other_amount__c',NAMESPACE_PREFIX+'other_service_charges__c',NAMESPACE_PREFIX+'other_taxes__c',
             NAMESPACE_PREFIX+'rental_amount__c',NAMESPACE_PREFIX+'rental_service_charges__c',NAMESPACE_PREFIX+'rental_taxes__c',
             NAMESPACE_PREFIX+'other_amount__c',NAMESPACE_PREFIX+'other_service_charges__c',NAMESPACE_PREFIX+'other_taxes__c',
             NAMESPACE_PREFIX+'rental_amount__c',NAMESPACE_PREFIX+'rental_service_charges__c',NAMESPACE_PREFIX+'rental_taxes__c',         
             NAMESPACE_PREFIX+'total_beverage_liquor_revenue__c',NAMESPACE_PREFIX+'total_beverage_revenue__c',NAMESPACE_PREFIX+'total_food_beverage_revenue__c',
             NAMESPACE_PREFIX+'total_labor_revenue__c',NAMESPACE_PREFIX+'total_gratuity_revenue__c',NAMESPACE_PREFIX+'total_food_revenue__c',
             NAMESPACE_PREFIX+'total_liquor_revenue__c',NAMESPACE_PREFIX+'total_miscellaneous_fees__c',NAMESPACE_PREFIX+'total_other_revenue__c',
             NAMESPACE_PREFIX+'total_rental_revenue__c'
            };

            List<Id> triggerNewIds = new List<Id>();
            //For all the 'Closed/Posted' Events run finalize method.
            for (Event__c event : triggerNewMap.values()) {

                Event__c oldEvent = triggerOldMap.get(event.ID);

                if (('Closed/Posted'.equals(event.Status__c) || 'Cancelled'.equals(event.Status__c)) && event.Status__c != oldEvent.Status__c) {
                    triggerNewIds.add(event.id);
                }
            }
            if (triggerNewIds.size() > 0) EventHandler.finalizeEvent(triggerNewIds);

            // If the Status is 'Closed/Posted' or 'Cancelled':
            // Check fields that may have been updated. If the fields are not whitelisted,
            // output an error.
            for (Event__c event : triggerNewMap.values()) {
                // System.debug('-- Event: ' + event);
                Map<String, Schema.SObjectField> fieldMap = event.Id.getSObjectType().getDescribe().fields.getMap();
                // System.debug('-- Field Map: ' + fieldMap);
                if (('Closed/Posted'.equals(event.Status__c) || 'Cancelled'.equals(event.Status__c)) && event.Status__c == triggerOldMap.get(event.Id).Status__c) {

                    for (String field : fieldMap.keySet()) {                       
                        // System.debug('WL contains? ' + whitelist.contains(field));
                        if (!whitelist.contains(field)) {

                            // System.debug('NEW field value: ' + String.valueOf(triggerNewMap.get(event.Id).get(field)));
                            // System.debug('OLD field value: ' + String.valueOf(triggerOldMap.get(event.Id).get(field)));

                            if (triggerOldMap.get(event.Id).get(field) == null && triggerNewMap.get(event.Id).get(field) != null) {
                                event.AddError('This event is Closed/Posted or Cancelled. If you wish to make changes, you must re-open your event.');
                            } else if (triggerNewMap.get(event.Id).get(field) == null && triggerOldMap.get(event.Id).get(field) != null) {
                                event.AddError('This event is Closed/Posted or Cancelled. If you wish to make changes, you must re-open your event.');
                            } else if (triggerOldMap.get(event.Id).get(field) == null && triggerNewMap.get(event.Id).get(field) == null) {
                                continue;
                            } else if ((!triggerOldMap.get(event.Id).get(field).equals(triggerNewMap.get(event.Id).get(field)))) {
                                event.AddError('This event is Closed/Posted or Cancelled. If you wish to make changes, you must re-open your event.');
                            }
                        }
                    }
                }
            }
        }
    }
    //Method to check Status of Event on Delete
    public static void EventStatusCheckBeforeDelete(List<Event__c> records) {
        if (run) {
            for (Event__c event : records) {
                if ('Cancelled'.equals(event.Status__c)) {
                    event.AddError('This event is Cancelled. You can no longer make changes.');
                } else if ('Closed/Posted'.equals(event.Status__c)) {
                    event.AddError('This event has been Closed/Posted. You can no longer make changes.');
                } else if ('Re-opened'.equals(event.Status__c)) {
                    event.AddError('This event is Re-opened. You can no longer delete it.');
                } else if ('Confirmed'.equals(event.Status__c)) {
                    event.AddError('This event has been Confirmed. You can no longer delete it.');
                }
            }
        }
    }

    /**
    *@Name   :joshi
    *@Description :Create the reserved reservation if any parent is get booked automatilcally book the child for that
    *facility
    *@param : List of the new and old event.
    **/
    public static void createUnavailableReservation(List<Event__c> triggerNewMap, Map<Id, Event__c> triggerOldMap, String eventAction) {
        Map<ID, ID> banqRecTypeMap = new Map<ID, ID>();
        ID rtReservedID;
        List<Schema.RecordTypeInfo> recLst = Schema.SObjectType.Event__c.getRecordTypeInfos();

        for (Schema.RecordTypeInfo rt : recLst) {
            if (rt.getName() == 'Sponsored Event' || rt.getName() == 'Sponsored Event - Child') {banqRecTypeMap.put(rt.getRecordTypeId(), rt.getRecordTypeId());}
            if (rt.getName() == 'Reserved') {rtReservedID = rt.getRecordTypeId();}
        }

        //Only fire if there is only 1 record and it is not a Reserved Event
        //Creates or moves Reserved record type Events going up and down the Facility hierarchy but not parallel
        //Reserves time period for Parent, GrandParent, Child, GrandChild etc.. but does not reserved Sibling time periods
        if (triggerNewMap.size() == 1 && triggerNewMap.get(0).RecordTypeId != rtReservedID && triggerNewMap.get(0).Location__c != null) {
            Event__c trgEvent = triggerNewMap.get(0);
            DateTime sdt = trgEvent.StartTime__c;
            DateTime edt = trgEvent.EndTime__c;
            Location__c facility = (Location__c)Data.read('SELECT Id, Name, Parent_Facility__c FROM Location__c WHERE Id = :location',
            new map<String, Object> {
                'location' => trgEvent.Location__c
            }).get(0);

            List<Location__c> lstChainFacilities = new List<Location__c>();
            //Get all of the Facilities up the chain
            //Get all of the Facilities down the chain
            List<Location__c> lstFacs = new List<Location__c>();
            lstFacs.add(facility);
            lstChainFacilities.addAll(Utility.getChildFacilities(lstFacs));
            //Create the Reserved Events if the items in the chain don't have one
            Set<Id> setFacIds = new Set<Id>();
            for (Location__c fac : lstChainFacilities) {
                setFacIds.add(fac.Id);
            }

            List<Event__c> lstReservations = new List<Event__c>();
            if (eventAction == 'Update') {
                //During update, check if reserved events exist and move them or add them
                List<Event__c> existingReserved = new List<Event__c>();
                Event__c parentTrgReservation;
                List<Event__c> parentTrgEvent = (List<Event__c>) Data.read('SELECT Id, Location__c, StartTime__c, EndTime__c, (SELECT Id, Name, StartTime__c, EndTime__c,' +
                                                ' Location__c FROM Reservations__r WHERE RecordType.Name = :Reserved)' +
                                                ' FROM Event__c' +
                                                ' WHERE Id = :eventId',
                new Map<String, Object> {
                    'Reserved' => 'Reserved',
                    'eventId' => trgEvent.Id
                });

                for (Event__c pTrgEvt : parentTrgEvent) {
                    parentTrgReservation = pTrgEvt;
                    for (Event__c rEvt : pTrgEvt.Reservations__r) {
                        existingReserved.add(rEvt);
                    }
                }
                Map<Id, Event__c> mapFacEvents = new Map<Id, Event__c>();
                for (Event__c event : existingReserved) {
                    mapFacEvents.put(event.Location__c, event);
                }
                Set<Id> setChainEventIds = new Set<Id>();
                for (Location__c fac : lstChainFacilities) {
                    if (mapFacEvents.containsKey(fac.Id)) {
                        //Move the time
                        if (parentTrgReservation != null && (parentTrgReservation.Location__c != trgEvent.Location__c || triggerOldMap.get(trgEvent.Id).StartTime__c != trgEvent.StartTime__c || triggerOldMap.get(trgEvent.Id).EndTime__c != trgEvent.EndTime__c)) {
                            Event__c event = mapFacEvents.get(fac.Id);
                            event.StartTime__c = sdt;
                            event.EndTime__c = edt;
                            event.Setup_Time__c = trgEvent.Setup_Time__c;
                            event.Cleanup_Time__c = trgEvent.Cleanup_Time__c;
                            event.Status__c = trgEvent.Status__c;
                            event.Contract_Due_Date__c = trgEvent.Contract_Due_Date__c;
                            event.SponsoringMember__c = trgEvent.SponsoringMember__c;
                            event.Sponsoring_Customer__c = trgEvent.Sponsoring_Customer__c;
                            event.Max_Seats__c = trgEvent.Max_Seats__c;

                            lstReservations.add(event);
                        }
                        setChainEventIds.add(mapFacEvents.get(fac.Id).Id);
                    } else {
                        //Create the reservation
                        Event__c event = new Event__c(
                            Name = 'Reserved',
                            StartTime__c = sdt,
                            EndTime__c = edt,
                            Parent_Reservation__c = trgEvent.id,
                            RecordTypeId = rtReservedID,
                            Location__c = fac.id,
                            Setup_Time__c = trgEvent.Setup_Time__c,
                            Cleanup_Time__c = trgEvent.Cleanup_Time__c,
                            Status__c = trgEvent.Status__c,
                            Contract_Due_Date__c = trgEvent.Contract_Due_Date__c,
                            SponsoringMember__c = trgEvent.SponsoringMember__c,
                            Sponsoring_Customer__c = trgEvent.Sponsoring_Customer__c,
                            Max_Seats__c = trgEvent.Max_Seats__c
                        );
                        lstReservations.add(event);
                    }
                }
                //Delete the reserved events that are not part of the hierarchy
                List<Event__c> lstDelete = new List<Event__c>();
                for (Event__c event : existingReserved) {
                    if (!setChainEventIds.contains(event.id)) {
                        lstDelete.add(event);
                    }
                }
                if (lstDelete.size() > 0) {
                    Data.remove(lstDelete);
                }
            } else {
                //During insert, add new reserved events
                for (Location__c fac : lstChainFacilities) {
                    Event__c event = new Event__c(
                        Name = 'Reserved',                        
                        StartTime__c = sdt,
                        EndTime__c = edt,
                        Parent_Reservation__c = trgEvent.id,
                        RecordTypeId = rtReservedID,
                        Location__c = fac.id,
                        Setup_Time__c = trgEvent.Setup_Time__c,
                        Cleanup_Time__c = trgEvent.Cleanup_Time__c,
                        Status__c = trgEvent.Status__c,
                        Contract_Due_Date__c = trgEvent.Contract_Due_Date__c,
                        SponsoringMember__c = trgEvent.SponsoringMember__c,
                        Sponsoring_Customer__c = trgEvent.Sponsoring_Customer__c,
                        Max_Seats__c = trgEvent.Max_Seats__c
                    );
                    lstReservations.add(event);
                }
            }
            Data.upsurt(lstReservations, Event__c.Id.getDescribe().getSObjectField(), new Set<String>());
        }
    }
    
    public static void TaxExemptTrueForLineItemsWhileMakingEventTotalTransTrue(List<Event__c> eventList,Map<Id, Event__c> triggerOldMap) {
        List<Id> eventIdsList = new List<Id>();
        Map<Id,Event__c> eventIdTaxExemptMap = new Map<Id,Event__c>();
        for(Event__c event : eventList) {
            if(event.Total_Tax_Exempt__c != triggerOldMap.get(event.Id).Total_Tax_Exempt__c ) {
                eventIdsList.add(event.Id);
                eventIdTaxExemptMap.put(event.Id,event);
            }
        }
        if(!eventIdsList.isEmpty()) {
           List<Line_Item__c> lineItemList = [select id,Reservation_line__c,Tax_Exempt__c from Line_Item__c where Reservation_line__c in :eventIdsList ];
           for(Line_Item__c lItem : lineItemList) {
               lItem.Tax_Exempt__c = eventIdTaxExemptMap.get(lItem.Reservation_line__c).Total_Tax_Exempt__c;
           }
           
           if(!lineItemList.isEmpty()) {
               update lineItemList;
           }
        }
    }
}