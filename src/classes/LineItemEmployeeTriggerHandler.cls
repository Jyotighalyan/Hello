/**
 * Handler class for EventChargeItemTrigger
 *
 */
public with sharing class LineItemEmployeeTriggerHandler {

    /**
     * OnBeforeInsert Handles before insert 
     * @param  newRecords
     */
    public static void OnBeforeInsert(List<Line_Item_Employee__c> newRecords)
    {
        preventGratuityOverAllocation(newRecords);
        UpdateEventOnInsert(newRecords);

    }
    /**
     * OnBeforeUpdate Handles before update 
     * @param  newRecords newRecords
     * @param  oldMap
     */
    public static void OnBeforeUpdate(List<Line_Item_Employee__c> newRecords, Map<id,Line_Item_Employee__c> oldMap)
    {
        preventGratuityOverAllocation(newRecords);
    }

    /**
     * preventGratuityOverAllocation Prevents the Gratuity splits from being greater than the EventChargeItem total amount
     * @param  records List of Line_Item_Employee__c
     * 
     */
    private static void preventGratuityOverAllocation(List<Line_Item_Employee__c> records)
    {
        //Map EventChargeItemEmployees in the current trigger context to their parent EventChargeItem
        Map<id,List<Line_Item_Employee__c>> lineItemEmployeeToChargeItemMap = new Map<id,List<Line_Item_Employee__c>>();
        Set<id> recordIDs = new Set<id>();
        for(Line_Item_Employee__c rec:records)
        {
            if(lineItemEmployeeToChargeItemMap.get(rec.Line_Item__c) == null)
            {
                lineItemEmployeeToChargeItemMap.put(rec.Line_Item__c,new List<Line_Item_Employee__c>{rec});
            }
            else
            {
                List<Line_Item_Employee__c> existingList = lineItemEmployeeToChargeItemMap.get(rec.Line_Item__c);
                existingList.add(rec);
                lineItemEmployeeToChargeItemMap.put(rec.Line_Item__c,existingList);
            }

            recordIDs.add(rec.id);
        }

        //Add sibling EventChargeItemEmployees to the map
        for(Line_Item_Employee__c rec:(List<Line_Item_Employee__c>) Data.read('Select id, Line_Item__c, Split_Amount__c from Line_Item_Employee__c where Line_Item__c in: keyset and Id NOT IN: recordIDs', new Map<String, Object>{'keyset' => lineItemEmployeeToChargeItemMap.keyset(), 'recordIDs' => recordIDs}))
        {
            if(lineItemEmployeeToChargeItemMap.get(rec.Line_Item__c) == null)
            {
                lineItemEmployeeToChargeItemMap.put(rec.Line_Item__c,new List<Line_Item_Employee__c>{rec});
            }
            else
            {
                List<Line_Item_Employee__c> existingList = lineItemEmployeeToChargeItemMap.get(rec.Line_Item__c);
                existingList.add(rec);
                lineItemEmployeeToChargeItemMap.put(rec.Line_Item__c,existingList);
            }
        }

        //Check whether the sum of the EventChargeItemEmployees Split Amounts is > the EventChargeItem Amount
        for(Line_Item__c eci:(List<Line_Item__c>) Data.read('Select id, Amount__c from Line_Item__c where Id in: keyset', new Map<String, Object>{'keyset' => lineItemEmployeeToChargeItemMap.keyset()}))
        {
            Decimal runningTotal = 0;
            for(Line_Item_Employee__c lineItemEmployee:lineItemEmployeeToChargeItemMap.get(eci.id))
            {
                if(lineItemEmployee.Split_Amount__c != NULL){
                     runningTotal += lineItemEmployee.Split_Amount__c;
                }               
            }

            if(runningTotal > eci.Amount__c)
            {
                lineItemEmployeeToChargeItemMap.get(eci.id)[0].adderror('Your split amounts are greater than your charge item total. Please update your split amount and click save.');
            }
        }
    }

    /**
     * Method to update the event on an Line_Item_Employee__c based on the Charge_Item selected.
     * @param records List of Line_Item_Employee__c
     */    
    public static void UpdateEventOnInsert(List<Line_Item_Employee__c> records){
       
        List<Line_Item_Employee__c> employeesToUpdate = new List<Line_Item_Employee__c>();
        Map<Id, Id> maplineItemEmployeeToChargeItem = new Map<Id,Id>();
        Map<Id, Id> mapEventToEmployee = new Map<Id,Id>();
        Set<Id> events = new Set<Id>();
        Set<Id> eventChargeItemIds = new Set<Id>();

        //Map the Employee to the Charge item
        for(Line_Item_Employee__c thisEmployee : records){
            if(thisEmployee.Line_Item__c !=NULL){
                maplineItemEmployeeToChargeItem.put(thisEmployee.Line_Item__c, thisEmployee.Id);
            }            
        }

        //Map the Event to the Employee based on the Charge Item
        for(Line_Item__c thisEventChargeItem : [SELECT Id, Reservation_Line__c FROM Line_Item__c WHERE Id IN :maplineItemEmployeeToChargeItem.keyset()]){
            if(thisEventChargeItem.Reservation_Line__c != NULL){
                mapEventToEmployee.put(maplineItemEmployeeToChargeItem.get(thisEventChargeItem.Id), thisEventChargeItem.Reservation_Line__c);
            }            
        }
                
        //Update the Event field on the Employee        
        for(Line_Item_Employee__c employee : records){
            if(employee.Event__c == NULL){
                employee.Event__c = mapEventToEmployee.get(employee.Id);
            }
        }        
    }

    public class LineItemEmployeeException extends Exception {}
}