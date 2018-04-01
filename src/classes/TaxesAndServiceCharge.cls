/**
* @Description : extend it if want to get taxes and service charge with passed in type and subtype
*/
public virtual class TaxesAndServiceCharge {

    public String serviceCharge {get; set;}
    public Decimal originalAmount;
    public Decimal SCAmount {get; set;}
    public Decimal SCPercentage {get; set;}
    public String type;
    public String subtype;
    public List<Taxes> taxesList {get; set;}
    public Decimal originalTaxAmount;
    public Decimal originalScAmount;

    public TaxesAndServiceCharge(String type, String subtype, Decimal originalAmount,Decimal originalTaxAmount,Decimal originalScAmount) {
        this.type = type;
        this.subtype = subtype;
        taxesList = new List<Taxes>();
        this.originalAmount = originalAmount;
        this.originalTaxAmount = originalTaxAmount;
        this.originalScAmount = originalScAmount;
        populateTaxesAndSCAmounts();
    }
    
    public TaxesAndServiceCharge(String type, String subtype, Decimal originalAmount) {
        this.type = type;
        this.subtype = subtype;
        taxesList = new List<Taxes>();
        this.originalAmount = originalAmount;        
        populateTaxesAndSCAmounts();
    }
 
    public TaxesAndServiceCharge(String type, String subtype)
    {
        this.type = type;
        this.subtype = subtype;
    }

    public class Taxes
    {
        public boolean taxAppliedOnSC;
        public String taxName {get; set;}
        public Decimal Amount {get; set;}
        public Decimal percentage {get; set;}
        public boolean taxExemption {get; set;}
    }

    public virtual void populateTaxesAndSCAmounts()
    {
        Boolean isServiceChargeCalculated = false;
        List<TxnChargeToTaxMapping__c> taxAndServiceChargeMapping = (List<TxnChargeToTaxMapping__c>)Data.read('SELECT Type__c, Subtype__c, TaxId__c, Service_Charge_applicable__c, Service_Charge_Name__c, Tax_Name_applicable_on_service_charge__c, Taxes_applicable_on_service_charge__c FROM TxnChargeToTaxMapping__c WHERE Type__c =:TypeName AND SubType__c =:SubtypeName', new Map<String, Object>{'TypeName'=> type, 'SubtypeName' => subtype});
        
        for(TxnChargeToTaxMapping__c txnTaxMap :taxAndServiceChargeMapping)
        {
            //NOTE: We need to decide how to handle null Values for taxes/service charges
            if(txnTaxMap.Service_Charge_applicable__c && !isServiceChargeCalculated && txnTaxMap.Service_Charge_Name__c != null){
                serviceCharge = Utility.getNameOfServiceCharge(txnTaxMap.Service_Charge_Name__c); 
                SCPercentage = Utility.getPercentageOfServiceCharge(txnTaxMap.Service_Charge_Name__c).setScale(3);
                isServiceChargeCalculated = true;
                SCAmount = ((originalAmount / 100) * SCPercentage).setScale(2);
            }

            //Calculate all applicable taxes on the amount
            if (txnTaxMap.TaxId__c != null) 
            {
                Taxes taxObj = new Taxes();
                taxObj.taxName = Utility.getNameOfTax(txnTaxMap.TaxId__c);
                taxObj.percentage = Utility.getPercentageOfTax(txnTaxMap.TaxId__c).setScale(3);
                if(txnTaxMap.Tax_Name_applicable_on_service_charge__c!=null && isServiceChargeCalculated){
                    taxObj.Amount = (((SCAmount + originalAmount)/100) * taxObj.percentage).setScale(2);
                }else{
                    taxObj.Amount = ((originalAmount / 100) * taxObj.percentage).setScale(2);
                }                
                taxesList.add(taxObj);
            }
        }
    }
}