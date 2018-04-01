/**
*@Name            : EventsController
*@Author          : joshi prakash
*@Date            : 8-4-2017
*@Description     : Controller for EventCalendar page
*/
global with sharing class EventsController {

    //Custom settings for calendar option
    private static EventCalendarOptions__c cCalOpts {get; set;}
    public Long cStartDt {get; set;}
    public Long cEndDt {get; set;}
    public String cFacId {get; set;}
    public List<Event__c> filterResultList {get; set;}
    //List to hold all the record types of an event object
    public static Map<String, RecordType> cmapRT {get
        {
            if (cmapRT == null) {
                cmapRT = new Map<String, RecordType>();
                for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Event__c']) {
                    cmapRT.put(rt.Name, rt);
                }
            }
            return cmapRT;
        } set;
    }
    
    public static Map<String, String> cmapVARs {get{
            if (cmapVARs == null) {
                cmapVARs = new Map<String, String>();
                cmapVARs.put('"id":', '"idVAR":');
                cmapVARs.put('"title":', '"titleVAR":');
                cmapVARs.put('"allDay":', '"allDayVAR":');
                cmapVARs.put('"start":', '"startVAR":');
                cmapVARs.put('"url":', '"urlVAR":');
                cmapVARs.put('"color":', '"colorVAR":');
                cmapVARs.put('"tooltip":', '"tooltipVAR":');
                cmapVARs.put('"resource":', '"resourceVAR":');
                cmapVARs.put('"reservation":', '"reservationVAR":');
                cmapVARs.put('"editable":', '"editableVAR":');
                cmapVARs.put('"type":', '"typeVAR":');
                cmapVARs.put('"end":', '"endVAR":');
            }
            return cmapVARs;
        } set;
    }

    public String tabId {get; set;}

    //Object to create reservation
    public Event__c cReservation {get; set;}
    public Boolean cShowPopup {get; set;}
    public String cRTName {get; set;}
    //Location id with holding its child location
    public Map<Id, Location__c> facIdToMap {get; set;}

    /*
    @Name   :FCEvent
    @Description :Event object for the calendar fields gathered from this link: http://arshaw.com/fullcalendar/docs/event_data/Event_Object/
    @Note: Added VAR to end of each class variable as some are reserved words, remove VAR when converting to JSON
    */
    public class FCEvent {
        String idVAR {get; set;}
        String titleVAR {get; set;}
        Boolean allDayVAR {get; set;}
        DateTime startVAR {get; set;}
        DateTime endVAR {get; set;}
        String urlVAR {get; set;}
        String colorVAR {get; set;}
        String tooltipVAR {get; set;}
        String resourceVAR {get; set;}
        Event__c reservationVAR {get; set;}
        Boolean editableVAR {get; set;}
        String typeVAR {get; set;}
    }

    /*
    @Name   :FCResource
    @Description :Resource object for the calendar fields gathered from this link: http://arshaw.com/fullcalendar/docs/event_data/Event_Object/
    @Note: Added VAR to end of each class variable as some are reserved words, remove VAR when converting to JSON
    */
    public class FCResource {
        String idVAR {get; set;}
        String nameVAR {get; set;}
        String parentVAR {get; set;}
        Boolean readonlyVAR {get; set;}
    }

    //Object to filter the events based on certain criteares.
    public Event__c filterEvent {get; set;}
    /*
    @Name   :EventsController
    @Description :Constructor to initalize the page
    */
    public EventsController() {

        filterEvent = new Event__c();
        cCalOpts = EventCalendarOptions__c.getOrgDefaults();
        cReservation = new Event__c();
        facIdToMap = new Map<Id, Location__c>();
        cmapRT = new Map<String, RecordType>();
        for (RecordType rt :[SELECT Id, Name FROM RecordType WHERE sObjectType = 'Event__c']) {
            cmapRT.put(rt.Name, rt);
        }

        tabId = ApexPages.currentPage().getParameters().get('sfdc.tabName');

    }

    /*
    @Name   :gotoDetails
    @Description :Redirects to the cReservation details page
    */
    public PageReference gotoDetails() {
        return new PageReference('/' + cReservation.id);
    }

    /*
    @Name   :Add room
    @Description :Add child or related reservations to this reservation 
    */
    public PageReference addRoom() {
        return new PageReference('/apex/'+NameSpaceUtils.getNamespaceWithPrefix()+'RoomsAgenda?id='+cReservation.id);
    }

    /*
    @Name   :closePopup
    @Description :Used by VF to close the popup
    */
    public PageReference closePopup() {
        cShowPopup = false;
        PageReference reRend;
        reRend = new  PageReference('/apex/'+NameSpaceUtils.getNamespaceWithPrefix()+'Events?sfdc.tabName=' + tabId);
        reRend.setRedirect(true);
        return reRend;
    }

    /*
    @Name   :saveReservation
    @Description :Saves the Reservation
    */
    public void saveReservation() {

        try {
           
            /*Check for the time conflict if the the parent facility is booking and if there is any child is already booked.
             under that facility for that perticular time duration.
            */
                
            map<String,Double> setupCleanupMap = new Map<String,Double>{
                'Half Hour'=>0.02083,
                '1 Hour'=>0.04166,
                '2 Hours'=>0.08333
            };

            Datetime starttime = cReservation.StartTime__c;
            Datetime endtime = cReservation.EndTime__c;
            if(cReservation.Setup_Time__c!=null)
            {
                starttime = cReservation.StartTime__c - setupCleanupMap.get(cReservation.Setup_Time__c);
            }

            if(cReservation.Cleanup_Time__c!=null)
            {
                endtime = cReservation.EndTime__c + setupCleanupMap.get(cReservation.Cleanup_Time__c);
            }

            Location__c facility = (Location__c)Data.read('SELECT Id, Name, Parent_Facility__c FROM Location__c WHERE Id = :location', 
            new map<String, Object> {
                'location' => cReservation.Location__c               
            }).get(0);

            List<Location__c> allChildLocations = Utility.getChildFacilities(new List<Location__c> {facility});

            Set<Id> setFacIds = new Set<Id>();
            setFacIds.add(facility.Id);
            
            for (Location__c fac : allChildLocations) {
                setFacIds.add(fac.Id);
            }
            //During update, check if reserved events exist and move them or add the
            List<Event__c> parentTrgEvent = (List<Event__c>)Data.read('SELECT Id, Location__c FROM Event__c WHERE Location__c IN :locations AND ((SetupTime__c >= :starttime AND SetupTime__c <= :endtime) OR (CleanupTime__c>= :starttime AND CleanupTime__c<= :endtime)) AND Status__c !=:cancelled',
            new Map<String, Object> {
                'locations' => setFacIds,
                'starttime' => starttime,
                'endtime' => endtime,
                'cancelled' =>'Cancelled'
            });

            if (parentTrgEvent.size() > 0) {
                throw new Utility.CustomException('There is time conflict with an existing event. Please try again with a differet time.');
            }

            List<Event__c> events = new List<Event__c>();
            events.add(cReservation);
            Data.upsurt(events, Event__c.Id.getDescribe().getSObjectField(), new Set<String>());
        } catch (Exception e) {         
            ApexPages.addMessages(e);
        }
    }

    /*
    @Name   :createReservation
    @Description :Defaults the values and redirects to the new reservation page
    */
    public PageReference createReservation() {
        PageReference pgReturn = null;

        if (cRTName == 'Sponsored Event') {
            cReservation = new Event__c(
                StartTime__c = DateTime.newInstance(cStartDt),
                EndTime__c = DateTime.newInstance(cEndDt),
                Location__c = cFacId,
                Setup_Time__c = 'Half Hour',
                Cleanup_Time__c = 'Half Hour',
                RecordTypeId = cmapRT.get(cRTName).id
            );
        }
        cShowPopup = true;
        return null;
    }

    /*
    @Name   :getReservations
    @Description :Populates the grid
    */
    @RemoteAction
    public static String getEvents(Long startTime, Long endTime, List<String> lstRTNames, List<String> lstFacTypes) {
        DateTime startDT = DateTime.newInstance(startTime);
        DateTime endDT = DateTime.newInstance(endTime);
        String startT = startDT.format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        String endT = endDT.format('yyyy-MM-dd\'T\'HH:mm:ssZ');

        List<FCEvent> lstGridEvents = new List<FCEvent>();        
        String strQueryFac = 'SELECT Id, Name, Parent_Facility__c '
                             + 'FROM Location__c';

        List<Location__c> lstFac = (List<Location__c>)Data.read(strQueryFac,
                                   new Map<String, sObject>());

        System.debug('startTime'+startT);
        System.debug('endTime'+endT);

        //Get the reservations for the timeframe        
        String strQuery = 'SELECT  Owner__r.Name, Parent_Reservation__r.Name, RecordType.Name, Location__r.Name, Sponsoring_Customer__r.Name, '
                          + 'Parent_Reservation__r.Sponsoring_Customer__c, Parent_Reservation__r.Sponsoring_Customer__r.Name, Parent_Reservation__r.Status__c, '
                          +  Utility.getFields('Event__c')
                          + ' FROM Event__c WHERE ((StartTime__c >= '
                          + startT + ' AND StartTime__c < '
                          + endT + ') OR (EndTime__c > '
                          + startT + ' AND EndTime__c <= '
                          + endT + ') OR (StartTime__c < '
                          + startT + ' AND EndTime__c > '
                          + endT + '))'
                          + ' AND (Status__c in (\'Tentative\',\'Confirmed\',\'Prospective\',\'Re-opened\',\'Closed/Posted\') or (RecordType.Name = \'Reserved\' AND Status__c !=\'Cancelled\'))';

        if (lstFac.size() > 0) {
            List<String> lstFacIds = new List<String>();
            for (Location__c fac : lstFac) {
                lstFacIds.add(fac.Id);
            }
            strQuery += ' AND Location__c IN (\'' + String.join(lstFacIds, '\',\'') + '\')';
        }
       
        List<Event__c> lstReservations = Database.query(strQuery);
        for (Event__c reservation : lstReservations) {
            convertReservation(reservation, lstGridEvents, reservation.RecordType.Name, new Set<String>(lstRTNames));
        }

        String jsonGridEventsTMP = JSON.serialize(lstGridEvents);
        List<String> tmpJsonLst = safeSplit(jsonGridEventsTMP, 'VAR');
        String jsonGridEvents = '';
        for (String s : tmpJsonLst) {
            jsonGridEvents += s.replaceAll('VAR', '');
        }

        jsonGridEvents = jsonGridEvents.replaceAll('VAR', '');
        System.debug(LoggingLevel.Info, 'jsonGridEvents List' + jsonGridEvents);
        return jsonGridEvents;
    }

    /**
    * Split a string of any size, while avoiding the dreaded 'Regex too complicated'
    * error, which the String.split(String) method causes on some large inputs.
    * Note that this method does not avoid other errors, such as those related to excess heap size or CPU time.
    */
    public static List<String> safeSplit(String inStr, String delim) {
        Integer regexFindLimit = 100;
        Integer regexFindCount = 0;
        List<String> output = new List<String>();
        Matcher m = Pattern.compile(delim).matcher(inStr);
        Integer lastEnd = 0;
        while (!m.hitEnd()) {
            while (regexFindCount < regexFindLimit && !m.hitEnd()) {
                if (m.find()) {
                    output.add(inStr.substring(lastEnd, m.start()));
                    lastEnd = m.end();
                } else {
                    output.add(inStr.substring(lastEnd));
                    lastEnd = inStr.length();
                }
                regexFindCount++;
            }

            // Note: Using region() to advance instead of substring() saves drastically on heap size.
            // Nonetheless, we still must reset the (unmodified) input sequence to avoid a 'Regex too complicated' error.
            m.reset(inStr);
            m.region(lastEnd, m.regionEnd());
            regexFindCount = 0;
        }
        return output;
    }

    /**
    *@Name   :Location
    *@Description : Fetch all the location where the event can be happened and the user can book a slot on that
    *This all the location will be get displayed to the left side of booking slot.
    **/

    public String getResources() {
        List<Location__c> lstFac = (List<Location__c>)Data.read('SELECT ' + Utility.getFields('Location__c')
                                   + ' FROM Location__c '
                                   + ' WHERE Hidden_From_Calendar__c != :isHideFromCal ORDER BY Parent_Facility__c, Order__c Asc', new Map<String, Object>{'isHideFromCal' => true});
        Set<Location__c> setFac = new Set<Location__c>(lstFac);
        Map<String, List<Location__c>> mapPCFac = new Map<String, List<Location__c>>();
        for (Location__c fac : lstFac) {
            if (fac.Parent_Facility__c != null) {
                if (mapPCFac.containsKey(fac.Parent_Facility__c)) {
                    mapPCFac.get(fac.Parent_Facility__c).add(fac);
                } else {
                    List<Location__c> lstF = new List<Location__c>();
                    lstF.add(fac);
                    mapPCFac.put(fac.Parent_Facility__c, lstF);
                }
            }
        }

        if (facIdToMap != null) {facIdToMap.clear();} else {facIdToMap = new Map<Id, Location__c>();}

        List<FCResource> lstRes = new List<FCResource>();
        //Go through the list of facilities
        for (Location__c fac : lstFac) {
            facIdToMap.put(fac.id, fac);
            //If the facility exists in the set, convert it to the final list, remove it from the set, and look for its children
            if (setFac.contains(fac)) {
                lstRes.add(convertResource(fac));
                setFac.remove(fac);
                orderHierarchy(fac.id, setFac, mapPCFac, lstRes, '&nbsp;&nbsp;&nbsp;&nbsp;');
            }
        }
        String jsonResources = JSON.serialize(lstRes);
        jsonResources = jsonResources.replaceAll('VAR', '');
        return jsonResources;
    }

    /*
    @Name   :orderHierarchy
    @Description :Recursive function to add children,grandchildren etc to the hierarchy list
    */
    public void orderHierarchy(String parentId, Set<Location__c> setUnmoved, Map<String, List<Location__c>> mapPC, List<FCResource> lstHier, String indent) {
        //check if the parent has children
        String moreIndent = indent + '&nbsp;&nbsp;&nbsp;&nbsp;';
        if (mapPC.containsKey(parentId)) {
            for (Location__c fac : mapPC.get(parentId)) {
                //convert and add the child to the list, remove it from the set, and search for its children
                fac.name = indent + fac.name;
                lstHier.add(convertResource(fac));
                setUnmoved.remove(fac);
                orderHierarchy(fac.id, setUnmoved, mapPC, lstHier, moreIndent);
            }
        }
    }

    /*
     @Name   :getStartHour
    @Description :Returns the start hour used in the day view
    */
    public Decimal getStartHour() {
        Decimal decSH = 5.5;
        if (cCalOpts != null && cCalOpts.Start_Hour__c != null && cCalOpts.Start_Hour__c > -1 && cCalOpts.Start_Hour__c < 24) {
            decSH = cCalOpts.Start_Hour__c;
        }
        return decSH;
    }

    /*
    @Name   :getEndHour
    @Description :Returns the end hour used in the day view
    */
    public Decimal getEndHour() {
        Decimal decEH = 22;
        if (cCalOpts != null && cCalOpts.End_Hour__c != null && cCalOpts.End_Hour__c > -1 && cCalOpts.End_Hour__c < 24) {
            decEH = cCalOpts.End_Hour__c ;
        }
        return decEH;
    }

    /*
    @Name   :getSlotMinutes
    @Description :Returns the minutes per slot for the day view
    */
    public Decimal getSlotMinutes() {
        Decimal decSM = 30;
        if (cCalOpts != null && cCalOpts.Slot_Minutes__c != null && cCalOpts.Slot_Minutes__c > 0 && cCalOpts.Slot_Minutes__c <= 60) {
            decSM = cCalOpts.Slot_Minutes__c;
        }
        return decSM;
    }
    /*
    @Name   :convertReservation
    @Description :Converts Event__c objects into FCEvent objects and add them to the passed in list
    */
    public static void convertReservation(Event__c reservation, List<FCEvent> lstGridEvents, String CRTName, Set<String> setPageRTs) {
        FCEvent fce = new FCEvent();
        fce.idVAR = reservation.id;
        if (reservation.Name.startsWith('<')) {reservation.Name = reservation.Name.replace('<', '');}
        fce.reservationVAR = reservation;
        if (reservation.Sponsoring_Customer__c != null) {
            fce.titleVAR = reservation.name;
        } else {
            fce.titleVAR = reservation.name;
        }

        fce.startVAR = reservation.StartTime__c;
        fce.endVAR = reservation.EndTime__c;
        //Keep track of the setup and cleanup time offset in minutes
        Integer intSetup = 0;
        Integer intCleanup = 0;

        map<String,Integer> cleanupSetupMinutes = new Map<String,Integer>{
            'Half Hour'=>30,
            '1 Hour'=>60,
            '2 Hours'=>120
        };

        if(reservation.Setup_Time__c!=null)
        {
            intSetup = cleanupSetupMinutes.get(reservation.Setup_Time__c);
        }
        if(reservation.Cleanup_Time__c!=null)
        {
            intCleanup = cleanupSetupMinutes.get(reservation.Cleanup_Time__c);
        }

        map<String,String> colorMap = new Map<String,String>{
            'Tentative'=>'#FF7744',
            'Confirmed'=>'#008000',
            'Re-opened'=>'#008000',
            'Prospective'=>'#800080',
            'Closed/Posted'=>'#808080'
        };
       
        //Past reservations are grey, future reservations are green, reserved slots are light blue
        if (reservation.RecordType.Name == 'Reserved') { //Reserved type event
            //Add setup and cleanup time to the reserved time
            fce.tooltipVAR = fce.startVAR.format('h:mm a') + ' - ' + fce.endVAR.format('h:mm a')
                             + '<br/>Reserved by ' + reservation.Parent_Reservation__r.Name;

            fce.colorVAR = colorMap.get(reservation.Parent_reservation__r.Status__c);    
            if (reservation.Parent_Reservation__r.Sponsoring_Customer__c != null) {
                fce.titleVAR = 'Unavailable';

                fce.tooltipVAR += '<br/>Sponsored by ' + reservation.Parent_Reservation__r.Sponsoring_Customer__r.Name;                           
            } else {
                fce.titleVAR = 'Reserved by Parent';
                fce.titleVAR = 'Unavailable';                           
            }

            fce.startVAR = fce.startVAR.addMinutes(-intSetup);
            fce.endVAR = fce.endVAR.addMinutes(intCleanup);
            fce.editableVAR = false;
            fce.typeVAR = 'reserved';
            //The url points to the parent if there is one, otherwise point to the reservation
            if (reservation.Parent_Reservation__c != null) {
                fce.urlVAR = '/' + reservation.Parent_Reservation__c;
            } else {
                fce.urlVAR = '/' + reservation.id;
            }

        } else {

            fce.tooltipVAR = fce.startVAR.format('h:mm a') + ' - ' + fce.endVAR.format('h:mm a');
            if (reservation.Sponsoring_Customer__c != null) {
                fce.tooltipVAR += '<br/> B: ' + reservation.Name;
            }

            fce.tooltipVAR +=
                '<br/>' + reservation.Location__r.Name;
            if (reservation.Owner__c != null) {
                fce.tooltipVAR += '<br/>' + 'Sales Manager: ' + reservation.Owner__r.Name;
            }
            if (reservation.Function__c != null) {
                fce.tooltipVAR += '<br/>' + reservation.Function__c;
            }
            if (reservation.Street_Address__c != null) {
                fce.tooltipVAR += '<br/>' + reservation.Street_Address__c;
            }
            if (reservation.City__c != null && reservation.State_Province__c != null) {
                fce.tooltipVAR += '<br/>' + reservation.City__c + ', ' + reservation.State_Province__c;
            }
            if (reservation.Zip__c != null) {
                fce.tooltipVAR += '<br/>' + reservation.Zip__c;
            }

            fce.editableVAR = false;
            fce.typeVAR = 'futureReservation';
            //Editable only if type is future and record type name matches the page we are on            
            fce.urlVAR = '/' + reservation.id;
            //set the legends for event calendar
            if (reservation.RecordType.Name == 'Sponsored Event'  || reservation.RecordType.Name == 'Sponsored Event - Child') {
                fce.colorVAR = colorMap.get(reservation.Status__c);                  
            }

            //Create setup and cleanup timeslots for actual reservations
            if (intSetup != 0) {
                FCEvent fceSetup = new FCEvent();
                fceSetup.resourceVAR = reservation.Location__c;
                fceSetup.colorVAR = '#002b7f';
                fceSetup.idVAR = reservation.id + 'setup';
                fceSetup.titleVAR = '';
                fceSetup.startVAR = reservation.StartTime__c.addMinutes(-intSetup);
                fceSetup.endVAR = reservation.StartTime__c;
                fceSetup.tooltipVAR = fceSetup.startVAR.format('h:mm a') + ' - ' + fceSetup.endVAR.format('h:mm a') + '<br/>Setup time for ' + reservation.name;
                fceSetup.editableVAR = false;
                fceSetup.typeVAR = 'setupTime';
                lstGridEvents.add(fceSetup);
            }
            if (intCleanup != 0) {
                FCEvent fceCleanup = new FCEvent();
                fceCleanup.resourceVAR = reservation.Location__c;
                fceCleanup.colorVAR = '#002b7f';
                fceCleanup.idVAR = reservation.id + 'cleanup';
                fceCleanup.titleVAR = '';
                fceCleanup.startVAR = reservation.EndTime__c;
                fceCleanup.endVAR = reservation.EndTime__c.addMinutes(intCleanup);
                fceCleanup.tooltipVAR = fceCleanup.startVAR.format('h:mm a') + ' - ' + fceCleanup.endVAR.format('h:mm a') + '<br/>Cleanup time for ' + reservation.name;
                fceCleanup.editableVAR = false;
                fceCleanup.typeVAR = 'cleanupTime';
                lstGridEvents.add(fceCleanup);
            }
        }

        fce.resourceVAR = reservation.Location__c;
        lstGridEvents.add(fce);
    }

    /*
    @Name   :convertResource
    @Description :Converts Location__c objects into FCResource objects
    */
    public static FCResource convertResource(Location__c resource) {
        FCResource fcr = new FCResource();
        fcr.idVAR = resource.id;
        if (resource.name.contains('&nbsp;')) {
            String strSpaces = '';
            String strName = '';
            strSpaces = resource.name.substring(0, resource.name.lastIndexOf('&nbsp;') + 6);
            strName = resource.name.substring(resource.name.lastIndexOf('&nbsp;') + 6);
            if (strName.startsWith('<')) {strName = strName.replace('<', '');}
            fcr.nameVAR = strSpaces + strName;//'<a href=\'/' + resource.id + '\'>' + strName + '</a>';
        } else {
            String strName = resource.name;
            if (strName.startsWith('<')) {strName = strName.replace('<', '');}
            fcr.nameVAR = strName;//'<a href=\'/' + resource.id + '\'>' + strName + '</a>';
        }
        fcr.readonlyVAR = false;
        fcr.parentVAR = resource.Parent_Facility__c;
        return fcr;
    }

    
    /**
    * @description get all the events from the reservation calendar service passing the event critearea object.
    * @return will not return anything to the caller, It will set the list of reservation used in visual force page.
    */
    public void getFilteredEvents() {
        String queryCondition = 'Where Id!=null AND Parent_Reservation__c=null';
        Map<String, Object> params = new Map<String, Object>();

        if (filterEvent.StartTime__c != null) {
            queryCondition += ' AND StartTime__c >= ' + filterEvent.StartTime__c.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');

        }

        if (filterEvent.EndTime__c != null) {
            queryCondition += ' AND EndTime__c <= ' + filterEvent.EndTime__c.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        }

        if (filterEvent.Status__c != null && filterEvent.Status__c != '') {
            queryCondition += ' AND Status__c = :status';
            params.put('status', filterEvent.Status__c);
        }

        if (filterEvent.SponsoringMember__c != null && String.valueOf(filterEvent.SponsoringMember__c) != '') {
            queryCondition += ' AND SponsoringMember__c = :accounttobill';
            params.put('accounttobill', String.escapeSingleQuotes(String.valueOf(filterEvent.SponsoringMember__c)));
        }

        if (filterEvent.Sponsoring_Customer__c != null && String.valueOf(filterEvent.Sponsoring_Customer__c) != '') {
            queryCondition += ' AND Sponsoring_Customer__c = :sponseringmember';
            params.put('sponseringmember', String.escapeSingleQuotes(String.valueOf(filterEvent.Sponsoring_Customer__c)));
        }

        filterResultList = (List<Event__c>)Data.read(
                               'select id, Location__c, Name, StartTime__c, EndTime__c, Status__c, SponsoringMember__c, Sponsoring_Customer__c from Event__c ' + queryCondition, params);
    }
}