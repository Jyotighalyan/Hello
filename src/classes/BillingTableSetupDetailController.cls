/**
* @Description : controller class for BillingCustomDistributionDetail page - to show message if the annual amount is changed and distribution is not correct.
* @Date : 2017
* @group : Financial Management
*/
public with sharing class BillingTableSetupDetailController {

	public Member_Dues__c billTableObj {get; set;}

	// boolean var to check if any membership type exist to apply yhis due on
	public boolean isMembershipTypeSel {get; set;}

	//Refer to the page if Auto_Apply_On_Membership_Types__c is empty
	public string redirectTo {get; set;}

	// if installment is selected as default frequency
	public boolean isInstalSele {get; set;}
	

	public BillingTableSetupDetailController(ApexPages.StandardController std) {
		isInstalSele = false;
		isMembershipTypeSel = true;
		billTableObj = (Member_Dues__c) std.getRecord();
		billTableObj = (Member_Dues__c) Data.read('Select Auto_Apply_On_Membership_Types__c, Primary_Annual_Amount__c, Spouse_Partner_Annual_Amount__c, Dependent_Annual_Amount__c, Default_Billing_Frequency__c From Member_Dues__c where id=:billTId', new Map<String, Object> {'billTId' => billTableObj.id}).get(0);
	}

	public void setupPage()
	{
		Integer currentFiscalMonth = [SELECT FiscalYearStartMonth FROM Organization limit 1].FiscalYearStartMonth;
		if((billTableObj.Auto_Apply_On_Membership_Types__c==null || billTableObj.Auto_Apply_On_Membership_Types__c==''))
		isMembershipTypeSel = false;
		redirectTo = '/apex/InstallmentBilling?dueId='+billTableObj.id;
		List<Billing_Custom_Distribution__c> updateDistributions = new List<Billing_Custom_Distribution__c>();

		// make isInstalSele var true if Default billing frequency is selected as installment
		List<Billing_Custom_Distribution__c> billingCusDist = new List<Billing_Custom_Distribution__c>();
		billingCusDist = Data.read('Select Fiscal_Month__c , Total_distributed_amount__c, Type__c from Billing_Custom_Distribution__c where Member_Dues__c=:billingTableId', new Map<String, Object> {'billingTableId'=> billTableObj.id});
		if(billTableObj.Default_Billing_Frequency__c!='One Time'){
			if(billingCusDist==null || billingCusDist.size()<1){
				isInstalSele = true;
			}
			else
			{
				for(Billing_Custom_Distribution__c billCusDistr :billingCusDist)
				{
					boolean makeDistributionNull = false;
					if(billCusDistr.Type__c=='Primary'){
						if(billCusDistr.Total_distributed_amount__c!=billTableObj.Primary_Annual_Amount__c){
							if(billTableObj.Primary_Annual_Amount__c==0) {
								makeDistributionNull = true;
							}
							else {
							    isInstalSele = true;
							}
						}
					}
					else if(billCusDistr.Type__c=='Spouse/Partner'){
						if(billCusDistr.Total_distributed_amount__c!=billTableObj.Spouse_Partner_Annual_Amount__c) {
							if(billTableObj.Spouse_Partner_Annual_Amount__c==0) {
								makeDistributionNull = true;
							}
							else { 
								isInstalSele = true;
							}
						}
					}
					else if(billCusDistr.Type__c=='Dependent'){
						if(billCusDistr.Total_distributed_amount__c!=billTableObj.Dependent_Annual_Amount__c) {
							if(billTableObj.Dependent_Annual_Amount__c==0) {
								makeDistributionNull = true;
							}
							else {
								isInstalSele = true;
							}
						}
					}

					if(makeDistributionNull){
						updateDistributions.add(removeDistrAmounts(billCusDistr));
					}
				}
			}
		}
		if(updateDistributions.size()>0){
			Data.modify(updateDistributions);
		}
	}

	public static Billing_Custom_Distribution__c removeDistrAmounts(Billing_Custom_Distribution__c billCusDistr)
	{
		billCusDistr.January__c = 0;
		billCusDistr.February__c = 0;
		billCusDistr.March__c = 0;
		billCusDistr.April__c = 0;
		billCusDistr.May__c = 0;
		billCusDistr.June__c = 0;
		billCusDistr.July__c = 0;
		billCusDistr.August__c = 0;
		billCusDistr.September__c = 0;
		billCusDistr.October__c = 0;
		billCusDistr.November__c = 0;
		billCusDistr.December__c = 0;
		return billCusDistr;
	}
}