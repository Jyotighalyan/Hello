/**
 * Method to handle behavior when trigger is fired on Line_Item__c object.
 */
public class LineItemTriggerHandler {
    private static boolean run = true;

    public static void OnAfterInsert(Map<Id, Line_Item__c> records) {
        EventStatusValidation(records);
    }

    public static void OnBeforeUpdate(List<Line_Item__c> records) {
        preSetup(records,'update');
        EventStatusValidation(records);
    }

    public static void OnBeforeDelete(List<Line_Item__c> records) {
        EventStatusValidation(records);
    }

    public static void OnBeforeInsert(List<Line_Item__c> records) {
        preSetup(records,'insert');
    }
    /**
     * EventStatusValidation Verifies Status on the associated Event and determines whether changes may be made
     * to Event Charge Item records accordingly.
     * @param  records records Event Charge Items being modified.
     */
    public static void EventStatusValidation(List<Line_Item__c> records) {
        Map<Id, String> lineItemErrors = new Map<Id, String>();
        for (Line_Item__c lineItem : [SELECT Id, Reservation_Line__r.Status__c FROM Line_Item__c WHERE Id IN : records]) {
            if ('Closed/Posted'.equals(lineItem.Reservation_Line__r.Status__c)) {
                lineItemErrors.put(lineItem.Id, 'Closed/Posted');
            } else if ('Cancelled'.equals(lineItem.Reservation_Line__r.Status__c)) {
                lineItemErrors.put(lineItem.Id, 'Cancelled');
            }
        }
        for (Line_Item__c record : records) {
            if (lineItemErrors.containsKey(record.Id)) {
                if ('Closed/Posted'.equals(lineItemErrors.get(record.Id))) {
                    record.AddError('This event is Closed/Posted. If you wish to make changes, you must re-open your event.');
                } else if ('Cancelled'.equals(lineItemErrors.get(record.Id))) {
                    record.AddError('This event is Cancelled. You can no longer make changes.');
                }
            }
        }
    }
    /**
     * EventStatusValidation Verifies Status on the associated Event and determines whether changes may be made
     * to Event Charge Item records accordingly.
     * @param  records records Event Charge Items being modified.
     */
    public static void EventStatusValidation(Map<Id, Line_Item__c> records) {
        Map<Id, String> lineItemErrors = new Map<Id, String>();
        for (Line_Item__c lineItem : [SELECT Id, Reservation_Line__r.Status__c FROM Line_Item__c WHERE Id IN : records.keyset()]) {
            if ('Closed/Posted'.equals(lineItem.Reservation_Line__r.Status__c)) {
                lineItemErrors.put(lineItem.Id, 'Closed/Posted');
            } else if ('Cancelled'.equals(lineItem.Reservation_Line__r.Status__c)) {
                lineItemErrors.put(lineItem.Id, 'Cancelled');
            }
        }
        for (Line_Item__c record : records.values()) {
            if (lineItemErrors.containsKey(record.Id)) {
                if ('Closed/Posted'.equals(lineItemErrors.get(record.Id))) {
                    record.AddError('This event is Closed/Posted. If you wish to make changes, you must re-open your event.');
                } else if ('Cancelled'.equals(lineItemErrors.get(record.Id))) {
                    record.AddError('This event is Cancelled. You can no longer make changes.');
                }
            }
        }
    }

    /**
     * @description
     * Validate the price if override checkbox is ticked than price must be filled.
     * if price is not overriden than fill the price from the charge item object.
     * calculate the service tax and tax amount from the mapping based on the selected charge.
     * calculate the summary
     * @param  records records Event Charge Items being added newly.
     */
    public static void preSetup(List<Line_Item__c> records,String action) {
        Set<Id> chargeItemIds = new Set<Id>();
        Set<Id> eventIds = new Set<Id>();
        Id adjRecTypeId  = Schema.SObjectType.Line_Item__c.getRecordTypeInfosByName().get('Adjustment').getRecordTypeId();
        for (Line_Item__c record : records) {
            chargeItemIds.add(record.Charge_Item__c);
            eventIds .add(record.Reservation_line__c);
        }
        Map<Id,Event__c> eventsWithIdMap = new Map<Id,Event__c>((List<Event__c>)Data.read('SELECT Id, Total_Tax_Exempt__c FROM Event__c WHERE Id IN :eventIds', new Map<String, Object>{'eventIds' => eventIds}));
        
        Map<Id,Charge_Item__c> chargeItems = new Map<Id,Charge_Item__c>((List<Charge_Item__c>)Data.read(
                                               'SELECT Id, Price__c, Group__c, Type__c, SubType__c FROM Charge_Item__c' +
                                               ' WHERE Id in :chargeIds',
        new MAP<String, object> {
            'chargeIds' => chargeItemIds
        }));
        List<Revenue_Split__c> revSplit = (List<Revenue_Split__c>)Data.read(
                                               'SELECT Id, Charge_Item__c FROM Revenue_Split__c' ,
        new MAP<String, object> {
        });
        Set<Id> originalLIIdSet = new Set<Id>();
        Map<Id,Line_Item__c> orginalLineItemMap = null;
        for (Line_Item__c record : records) {
            if(record.Original_Line_Item__c != null) {
                originalLIIdSet.add(record.Original_Line_Item__c);
            }
        }  

        if(!originalLIIdSet.isEmpty()) {
            orginalLineItemMap = new Map<Id,Line_Item__c>((List<Line_Item__c>)Data.read('SELECT Id,Tax_Exempt__c, Amount__c from Line_Item__c where id IN: originalLIIdSet',
                                                                                            new Map<String, Object>{'originalLIIdSet' => originalLIIdSet}));            
        }       

        for (Line_Item__c record : records) 
        {
            if (record.Override_Price__c && record.Price__c == null) {                
                record.AddError('Price is mandatory if you are overriding the price.');
                continue;
            }

            if(record.Price__c == null)
            {
                record.Price__c = chargeItems.get(record.Charge_Item__c).Price__c;
            } 
            integer flag=0;
            for(Revenue_Split__c splits : revSplit){
                if(splits.Charge_Item__c == record.Charge_Item__c){
                    flag=1;
                    break;
                }
            }
            if(flag == 1 && chargeItems.get(record.Charge_Item__c).Price__c != record.Price__c){
                record.AddError('The sum of your revenue splits do not equal to  the price of your charge item. Please update your split amounts in order to save.');
                continue;
            }
            

            if(record.Group__c == null && chargeItems.get(record.Charge_Item__c).Group__c !=null)
            {
                record.Group__c = chargeItems.get(record.Charge_Item__c).Group__c;                
            }
             
            if(record.recordTypeId ==adjRecTypeId && record.Original_Line_Item__c != null) {
                if(orginalLineItemMap != null && orginalLineItemMap.get(record.Original_Line_Item__c) != null) {
                    record.Tax_Exempt__C = orginalLineItemMap.get(record.Original_Line_Item__c).Tax_Exempt__C;
                }
            }
            if(record.Qty__c == 0 && record.recordTypeId == adjRecTypeId ) {
                
                if(record.Tax_Adjustment_Quantity__c == null)  record.Tax_Adjustment_Quantity__c = 0;
                if(record.Service_Charge_Adjustment_Quantity__c == null)  record.Service_Charge_Adjustment_Quantity__c = 0;
                TaxesAndServiceCharge taxAndSCAmount = new TaxesAndServiceCharge(chargeItems.get(record.Charge_Item__c).Type__c,
                                                                                    chargeItems.get(record.Charge_Item__c).SubType__c,
                                                                                    (-1 * orginalLineItemMap.get(record.Original_Line_Item__c).Amount__c).setScale(2),
                                                                                    (record.Tax_Adjustment_Quantity__c * record.Price__c).setScale(2),
                                                                                    (record.Service_Charge_Adjustment_Quantity__c * record.Price__c).setScale(2));        
                record.Tax_Amount__c = 0.0;
                for(TaxesAndServiceCharge.Taxes TaxAmount : taxAndSCAmount.taxesList)
                {
                    record.Tax_Amount__c = record.Tax_Amount__c + TaxAmount.amount;
                    record.Tax_Name__c = TaxAmount.taxName;
                }
                record.Service_Charge__c = taxAndSCAmount.SCAmount;
                record.Service_Charge_Name__c = taxAndSCAmount.serviceCharge;
            }else {
                TaxesAndServiceCharge taxAndSCAmount = new TaxesAndServiceCharge(chargeItems.get(record.Charge_Item__c).Type__c, chargeItems.get(record.Charge_Item__c).SubType__c,(record.Qty__c * record.Price__c).setScale(2));        
                record.Tax_Amount__c = 0.0;
                for(TaxesAndServiceCharge.Taxes TaxAmount:taxAndSCAmount.taxesList)
                {
                    record.Tax_Amount__c = record.Tax_Amount__c + TaxAmount.amount;
                    record.Tax_Name__c = TaxAmount.taxName;
                }
                record.Service_Charge__c = taxAndSCAmount.SCAmount;
                record.Service_Charge_Name__c = taxAndSCAmount.serviceCharge;
            }
            if(record.Qty__c != null && record.Qty__c != 0 && record.recordTypeId ==adjRecTypeId ) {
                record.Service_Charge_Adjustment_Quantity__c = record.Qty__c;
                record.Tax_Adjustment_Quantity__c = record.Qty__c;
            }
            if(action == 'insert' && eventsWithIdMap != null && eventsWithIdMap.get(record.Reservation_line__c) != null && eventsWithIdMap.get(record.Reservation_line__c).Total_Tax_Exempt__c) {
               record.Tax_Exempt__c = eventsWithIdMap.get(record.Reservation_line__c).Total_Tax_Exempt__c;
               record.Tax_Amount__c = 0.0;
            }
            
            if(record.Tax_Exempt__c) {
                record.Tax_Amount__c = 0.0;
            }
        }
    }

    /**
     * @description
     * This method will sum of the amount of all added line items for the event.
     * @param  eevent id on which we have to store the total of all line items added.
     */
    public static void postSetup(Id eventId) {
        //Update revenue section.
        Decimal itemRevenue = 0;
        Decimal chargeAmountWithoutTaxSc = 0;
        Decimal totalChargeAmount = 0;
        Event__c event = (Event__c)Data.read(
                             'SELECT Id, Gross_Revenue__c, Revenue__c, Liquor_Amount__c, Total_Charge_Amount__c, Post_Close_Date_Time__c, Additions__c FROM Event__c' +
                             ' WHERE Id = :eventId',
        new MAP<String, object> {
            'eventId' => eventId
        }).get(0);

        List<Line_Item__c> lineItems = (List<Line_Item__c>)Data.read(
                                           'SELECT Id, Amount__c, Total_Amount__c, Tax_Amount__c, Service_Charge__c, Group__c, CreatedDate FROM Line_Item__c' +
                                           ' WHERE  Reservation_line__c =:eventId',
        new MAP<String, object> {
            'eventId' => eventId
        });

        final String NAMESPACE_PREFIX = NameSpaceUtils.getNamespaceWithPrefix();
        Map<String,Map<String,Decimal>> revenueApiNames = new Map<String,Map<String,Decimal>>{
            'Liquor'=>new Map<String,Decimal>{NAMESPACE_PREFIX+'Liquor_Amount__c'=>0,NAMESPACE_PREFIX+'Liquor_Service_Charges__c'=>0,NAMESPACE_PREFIX+'Liquor_Taxes__c'=>0},
            'Beverage'=>new Map<String,Decimal>{NAMESPACE_PREFIX+'Beverage_Amount__c'=>0,NAMESPACE_PREFIX+'Beverage_Service_Charges__c'=>0,NAMESPACE_PREFIX+'Beverage_Taxes__c'=>0},                         
            'Food'=>new Map<String,Decimal>{NAMESPACE_PREFIX+'Food_Amount__c'=>0,NAMESPACE_PREFIX+'Food_Service_Charges__c'=>0,NAMESPACE_PREFIX+'Food_Taxes__c'=>0},                
            'Gratuity'=>new Map<String,Decimal>{NAMESPACE_PREFIX+'Gratuity_Amount__c'=>0,NAMESPACE_PREFIX+'Gratuity_Service_Charges__c'=>0,NAMESPACE_PREFIX+'Gratuity_Taxes__c'=>0},
            'Labor'=>new Map<String,Decimal>{NAMESPACE_PREFIX+'Labor_Amount__c'=>0,NAMESPACE_PREFIX+'Labor_Service_Charges__c'=>0,NAMESPACE_PREFIX+'Labor_Taxes__c'=>0},
            'Miscellaneous Fees'=>new Map<String,Decimal>{NAMESPACE_PREFIX+'Miscellaneous_Fees_Amount__c'=>0,NAMESPACE_PREFIX+'Miscellaneous_Fees_Service_Charges__c'=>0,NAMESPACE_PREFIX+'Miscellaneous_Fees_Taxes__c'=>0},
            'Other'=>new Map<String,Decimal>{NAMESPACE_PREFIX+'Other_Amount__c'=>0,NAMESPACE_PREFIX+'Other_Service_Charges__c'=>0,NAMESPACE_PREFIX+'Other_Taxes__c'=>0},
            'Rental'=>new Map<String,Decimal>{NAMESPACE_PREFIX+'Rental_Amount__c'=>0,NAMESPACE_PREFIX+'Rental_Service_Charges__c'=>0,NAMESPACE_PREFIX+'Rental_Taxes__c'=>0}            
        };

        for (Line_Item__c item : lineItems) {
            if (event.Post_Close_Date_Time__c == null || item.CreatedDate < event.Post_Close_Date_Time__c) {
                itemRevenue = itemRevenue + item.Total_Amount__c;
            }

            chargeAmountWithoutTaxSc = chargeAmountWithoutTaxSc + item.Amount__c;
            totalChargeAmount = totalChargeAmount + item.Total_Amount__c;

            if(revenueApiNames.containsKey(item.Group__c))
            {
                Map<String,Decimal> groupRevenue = revenueApiNames.get(item.Group__c);
                for (String fieldName : groupRevenue.keySet())
                {
                    Decimal money = groupRevenue.get(fieldName);                    
                    if(fieldName.contains('Amount__c'))
                    {
                        money = money + item.Amount__c;                    
                    }
                    else if(fieldName.contains('Service_Charges__c') && item.Service_Charge__c!=null)
                    {
                        money = money + item.Service_Charge__c;
                    }
                    else
                    {
                        money = money + item.Tax_Amount__c;
                    }
                    groupRevenue.put(fieldName,money);
                }
                revenueApiNames.put(item.Group__c,groupRevenue);      
            }            
        }   

        for (String revenueKeys : revenueApiNames.keySet())
        {
                Map<String,Decimal> groupRevenue = revenueApiNames.get(revenueKeys);
                for (String fieldName : groupRevenue.keySet())
                {
                    Decimal money = groupRevenue.get(fieldName);                    
                    event.put(fieldName,money);
                }            
        }    
        event.Gross_Revenue__c = itemRevenue;
        event.Revenue__c = chargeAmountWithoutTaxSc;
        event.Total_Charge_Amount__c = totalChargeAmount;
        Data.modify(event);
    }
}