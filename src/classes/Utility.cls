/**
* @Description : common cmsft utility class
*/

public with sharing class Utility {
    /**
    * @Description : to get recordtype id
    * @Param rtype pass the name of the recordtype
    * @param objtype name of the object
    * @return id of the rtype passed in string datatype
    */

    public static Set<String> cSetExecuted = new Set<String>(); //Keeps name of item, item is assumed to be executed already if in map

    private static Map<String, String> countryMap = new Map<String, String>{
        'Afghanistan'=>'AF', 'Albania'=>'AL', 'Algeria'=>'DZ', 'American Samoa'=>'AS', 'Andorra'=>'AD', 'Angola'=>'AO',
        'Anguilla'=>'AI', 'Antarctica'=>'AQ', 'Antigua and Barbuda'=>'AG', 'Argentina'=>'AR', 'Armenia'=>'AM',
        'Aruba'=>'AW', 'Australia'=>'AU', 'Austria'=>'AT', 'Azerbaijan'=>'AZ', 'Bahamas'=>'BS', 'Bahrain'=>'BH',
        'Bangladesh'=>'BD', 'Barbados'=>'BB', 'Belarus'=>'BY', 'Belgium'=>'BE', 'Belize'=>'BZ', 'Benin'=>'BJ',
        'Bermuda'=>'BM', 'Bhutan'=>'BT', 'Bolivia'=>'BO', 'Bosnia and Herzegovina'=>'BA', 'Botswana'=>'BW',
        'Bouvet Island'=>'BV', 'Brazil'=>'BR', 'British Indian Ocean Territory'=>'IO', 'Brunei Darussalam'=>'BN',
        'Bulgaria'=>'BG','Burkina Faso'=>'BF', 'Burundi'=>'BI', 'Cambodia'=>'KH', 'Cameroon'=>'CM',
        'Canada'=>'CA', 'Cape Verde'=>'CV', 'Cayman Islands'=>'KY', 'Central African Republic'=>'CF',
        'Chad'=>'TD', 'Chile'=>'CL', 'China'=>'CN', 'Christmas Island'=>'CX', 'Cocos (Keeling) Islands'=>'CC', 'Colombia'=>'CO',
        'Comoros'=>'KM', 'Congo'=>'CG', 'Congo, Democratic Republic'=>'CD', 'Cook Islands'=>'CK', 'Costa Rica'=>'CR',
        'Cote D\'Ivoire (Ivory Coast)'=>'CI', 'Croatia (Hrvatska)'=>'HR', 'Cuba'=>'CU', 'Cyprus'=>'CY', 'Czech Republic'=>'CZ',
        'Czechoslovakia (former)'=>'CS', 'Denmark'=>'DK', 'Djibouti'=>'DJ', 'Dominica'=>'DM', 'Dominican Republic'=>'DO',
        'East Timor'=>'TP', 'Ecuador'=>'EC', 'Egypt'=>'EG', 'El Salvador'=>'SV', 'Equatorial Guinea'=>'GQ', 'Eritrea'=>'ER',
        'Estonia'=>'EE', 'Ethiopia'=>'ET', 'F.Y.R.O.M. (Macedonia)'=>'MK', 'Falkland Islands (Malvinas)'=>'FK', 'Faroe Islands'=>'FO',
        'Fiji'=>'FJ', 'Finland'=>'FI', 'France'=>'FR', 'France, Metropolitan'=>'FR', 'French Guiana'=>'GF', 'French Polynesia'=>'PF',
        'French Southern Territories'=>'TF', 'Gabon'=>'GA', 'Gambia'=>'GM', 'Georgia'=>'GE', 'Germany'=>'DE', 'Ghana'=>'GH',
        'Gibraltar'=>'GI', 'Great Britain (UK)'=>'GB', 'Greece'=>'GR', 'Greenland'=>'GL', 'Grenada'=>'GD', 'Guadeloupe'=>'GP',
        'Guam'=>'GU', 'Guatemala'=>'GT', 'Guernsey'=>'GG', 'Guinea'=>'GN', 'Guinea-Bissau'=>'GW', 'Guyana'=>'GY', 'Haiti'=>'HT',
        'Heard Island and Mcdonald Islands'=>'HM','Holy See�(Vatican City State)'=>'VA', 'Honduras'=>'HN', 'Hungary'=>'HU', 'Iceland'=>'IS',
        'India'=>'IN', 'Indonesia'=>'ID', 'Iran, Islamic Republic of'=>'IR', 'Iraq'=>'IQ', 'Ireland'=>'IE','Isle of Man'=>'IM', 'Israel'=>'IL',
        'Italy'=>'IT','Jamaica'=>'JM', 'Japan'=>'JP', 'Jordan'=>'JO', 'Kazakhstan'=>'KZ', 'Kenya'=>'KE', 'Kiribati'=>'KI', 'Korea (North)'=>'KP',
        'Korea (South)'=>'KR', 'Kuwait'=>'KW', 'Kyrgyzstan'=>'KG', 'Laos'=>'LA', 'Latvia'=>'LV', 'Lebanon'=>'LB', 'Lesotho'=>'LS', 'Liberia'=>'LR',
        'Libya'=>'LY','Liechtenstein'=>'LI', 'Lithuania'=>'LT',  'Luxembourg'=>'LU', 'Macau'=>'MO', 'Madagascar'=>'MG', 'Malawi'=>'MW', 'Malaysia'=>'MY',
        'Maldives'=>'MV', 'Mali'=>'ML', 'Malta'=>'MT', 'Marshall Islands'=>'MH', 'Martinique'=>'MQ', 'Mauritania'=>'MR', 'Mauritius'=>'MU',
        'Mayotte'=>'YT', 'Mexico'=>'MX', 'Micronesia'=>'FM', 'Moldova'=>'MD', 'Monaco'=>'MC', 'Mongolia'=>'MN', 'Montserrat'=>'MS', 'Morocco'=>'MA',
        'Mozambique'=>'MZ', 'Myanmar'=>'MM', 'Namibia'=>'NA', 'Nauru'=>'NR', 'Nepal'=>'NP', 'Netherlands'=>'NL', 'Netherlands Antilles'=>'AN',
        'Neutral Zone'=>'NT', 'New Caledonia'=>'NC', 'New Zealand (Aotearoa)'=>'NZ', 'Nicaragua'=>'NI', 'Niger'=>'NE', 'Nigeria'=>'NG',
        'Niue'=>'NU', 'Norfolk Island'=>'NF', 'Northern Mariana Islands'=>'MP', 'Norway'=>'NO', 'Oman'=>'OM', 'Pakistan'=>'PK', 'Palau'=>'PW',
        'Panama'=>'PA', 'Papua New Guinea'=>'PG', 'Paraguay'=>'PY', 'Peru'=>'PE', 'Philippines'=>'PH', 'Pitcairn'=>'PN', 'Poland'=>'PL', 'Portugal'=>'PT',
        'Puerto Rico'=>'PR', 'Qatar'=>'QA', 'Reunion'=>'RE', 'Romania'=>'RO', 'Russian Federation'=>'RU', 'Rwanda'=>'RW', 'S. Georgia and S. Sandwich Islands'=>'GS',
        'Saint Kitts and Nevis'=>'KN', 'Saint Lucia'=>'LC', 'Saint Vincent & the Grenadines'=>'VC', 'Samoa'=>'WS', 'San Marino'=>'SM', 'Sao Tome and Principe'=>'ST',
        'Saudi Arabia'=>'SA', 'Scotland'=>'GB', 'Senegal'=>'SN', 'Serbia and Montenegro'=>'RS', 'Seychelles'=>'SC', 'Sierra Leone'=>'SL', 'Singapore'=>'SG',
        'Slovak Republic'=>'SK', 'Slovenia'=>'SI', 'Solomon Islands'=>'SB', 'Somalia'=>'SO', 'South Africa'=>'ZA', 'Spain'=>'ES', 'Sri Lanka'=>'LK',
        'St. Helena'=>'SH', 'St. Pierre and Miquelon'=>'PM', 'Sudan'=>'SD', 'Suriname'=>'SR', 'Svalbard & Jan Mayen Islands'=>'SJ', 'Swaziland'=>'SZ',
        'Sweden'=>'SE', 'Switzerland'=>'CH', 'Syria'=>'SY', 'Taiwan'=>'TW', 'Tajikistan'=>'TJ', 'Tanzania'=>'TZ', 'Thailand'=>'TH', 'Togo'=>'TG',
        'Tokelau'=>'TK', 'Tonga'=>'TO', 'Trinidad and Tobago'=>'TT', 'Tunisia'=>'TN', 'Turkey'=>'TR', 'Turkmenistan'=>'TM', 'Turks and Caicos Islands'=>'TC',
        'Tuvalu'=>'TV', 'Uganda'=>'UG', 'Ukraine'=>'UA', 'United Arab Emirates'=>'AE', 'United Kingdom'=>'UK', 'United States'=>'US',
        'US Minor Outlying Islands'=>'UM', 'USSR (former)'=>'SU', 'Uruguay'=>'UY', 'Uzbekistan'=>'UZ', 'Vanuatu'=>'VU', 'Vatican City State (Holy Sea)'=>'VA',
        'Venezuela'=>'VE', 'Viet Nam'=>'VN', 'Virgin Islands (British)'=>'VB', 'Virgin Islands (U.S.)'=>'VI', 'Wallis and Futuna Islands'=>'WF','Western Sahara'=>'EH',
        'West Indies'=>'WI', 'Yemen'=>'YE', 'Zair'=>'ZR', 'Zambia'=>'ZM', 'Zimbabwe'=>'ZW'
    };

    public static String searchRecordType(String rtype, String objType) {
        Id devRecordTypeId = Schema.getGlobalDescribe().get(objType).getDescribe().getRecordTypeInfosByName().get(rtype).getRecordTypeId();
        return string.valueOf(devRecordTypeId);
    }

    //check if financial account is for credit or debit
    public static string AccountDebitOrCredit(string AccountId){
         List<Financial_Account__c> CheckCreditDebit = (List<Financial_Account__c>)Data.read(
                            'select Debit_Credit__c  from Financial_Account__c  where id =: AccId ',
                            new Map<String,Object> {
                                'AccId'=>AccountId
                            }
                      ); 
         return CheckCreditDebit[0].Debit_Credit__c;
     }
    /**
    * @Description : custom exception class
    */
    public class CustomException extends Exception{

    }

    public static double Round2(double valuetoRound) {
        decimal decimalVal = (decimal)valuetoRound;
        return (double)decimalVal.setScale(2);
    }
    //get financial account based on default type and payment type
    public static string financialAccountFromDefaultType(string DefaultType, string paymentType){
        List<Default_Account__c> accList = null;
        if(paymentType!=''){
              accList = (List<Default_Account__c>)Data.read(
                        'select id, Financial_Account__c from Default_Account__c where Default_Type_Name__c =:dType and Payment_Type__c=:pType ',
                        new Map<String,Object> {
                            'dType'=>DefaultType,
                            'pType'=>paymentType
                                }
                    );
        }else{
              accList = (List<Default_Account__c>)Data.read(
                        'select id, Financial_Account__c from Default_Account__c where Default_Type_Name__c =:dType ',
                        new Map<String,Object> {
                            'dType'=>DefaultType
                                }
                    );
        }
       
        if(accList.size()>0){
            return accList[0].Financial_Account__c; 
        }
        return null;
    }
    //get financial account based on recordtype and payment type
    public static string financialAccountFromRecordType(string recordType, string paymentType){
        List<Default_Account__c> accList = null;
        if(paymentType!=''){
              accList = (List<Default_Account__c>)Data.read(
                        'select id, Financial_Account__c from Default_Account__c where RecordTypeId =:rType and Payment_Type__c=:pType ',
                        new Map<String,Object> {
                            'rType'=>recordType,
                            'pType'=>paymentType
                                }
                    );
        }else{
              accList = (List<Default_Account__c>)Data.read(
                        'select id, Financial_Account__c from Default_Account__c where RecordTypeId =:rType ',
                        new Map<String,Object> {
                            'rType'=>recordType
                                }
                    );
        }
       
        if(accList.size()>0){
            return accList[0].Financial_Account__c; 
        }
        return null;
    }

   public static Map<Map<String, Id>, Map<String, Id>> getCreditAndDebitAccountsByRecordType(Map<String, String> creditAccountMap, Map<String, String> debitAccountMap ){
       Map<Map<String, Id>, Map<String, Id>> financialAccountsMappedToRecordType = new Map<Map<String, Id>, Map<String, Id>>();
       List<Default_Account__c> allDefaultAccounts = [SELECT Id, Financial_Account__c, Payment_Type__c, Default_Type_Name__c, RecordType.Name FROM Default_Account__c];
       Map<String, Id> creditFinancialAccountMap = new Map<String, Id>();
       Map<String, Id> debitFinancialAccountMap = new Map<String, Id>();
       for(String creditRecordType: creditAccountMap.keyset()){

           for(String debitRecordType: debitAccountMap.keyset()){

               for(Default_Account__c account: allDefaultAccounts){

                    if(creditRecordType == 'Refund' && debitRecordType == 'Refund'){

                        if(account.Payment_Type__c == creditAccountMap.get(creditRecordType) && account.RecordType.Name == 'Refund'){

                            creditFinancialAccountMap.put(creditRecordType, account.Financial_Account__c);

                        }else if(account.Default_Type_Name__c == debitAccountMap.get(debitRecordType)){

                            debitFinancialAccountMap.put(debitRecordType, account.Financial_Account__c);
                        }
                    }else if(creditRecordType == 'Deposit' && debitRecordType == 'Deposit'){

                        if(account.Default_Type_Name__c == creditAccountMap.get(creditRecordType)){

                            creditFinancialAccountMap.put(creditRecordType, account.Financial_Account__c);

                        }else if(account.Default_Type_Name__c == debitAccountMap.get(debitRecordType)){

                            debitFinancialAccountMap.put(debitRecordType, account.Financial_Account__c);
                        }
                    }else if(creditRecordType == 'Payment' && debitRecordType == 'Payment'){

                        if(account.Default_Type_Name__c == creditAccountMap.get(creditRecordType)){

                            creditFinancialAccountMap.put(creditRecordType, account.Financial_Account__c);

                        }else if(account.Payment_Type__c == debitAccountMap.get(debitRecordType) && account.RecordType.Name == 'Payments'){

                            debitFinancialAccountMap.put(debitRecordType, account.Financial_Account__c);
                        }
                    } else if(creditRecordType == 'Charge' && debitRecordType == 'Charge'){

                        if(account.Default_Type_Name__c == creditAccountMap.get(creditRecordType)){

                            creditFinancialAccountMap.put(creditRecordType, account.Financial_Account__c);

                        }else if(account.Default_Type_Name__c == debitAccountMap.get(debitRecordType)){

                            debitFinancialAccountMap.put(debitRecordType, account.Financial_Account__c);
                        }
                    }                  
                }
           }           
       }
       financialAccountsMappedToRecordType.put(creditFinancialAccountMap,debitFinancialAccountMap);
       return financialAccountsMappedToRecordType;
    }




   
    
     //get Label of Tax with passed id
    public static string getNameOfTax(string Id) {
        string name = '';
        Map<string, Schema.SObjectField> fieldsMap = Taxes__c.sObjectType.getDescribe().fields.getMap();
        Set<string> customHierarchyFieldNames = new  Set<string>();
        for (string field : fieldsMap.keySet()) {
            Schema.SObjectField F = fieldsMap.get(field);
            Schema.DescribeFieldResult R = F.getDescribe();
            if (R.isCustom()) {
                string fName = R.getName();
                string fLabel = R.getLabel();
                if (Id == fName) {
                    name = fLabel;
                    
                }
            }
        }
        return name;
    }

     //get Service charge Names and values with passed id
    public static Decimal getPercentageOfTax(string Id) {
        
        
        Decimal value = 0;
        Taxes__c setting = Taxes__c.getInstance();
        
        Map<string, Schema.SObjectField> fieldsMap = Taxes__c.sObjectType.getDescribe().fields.getMap();
        
        Set<string> customHierarchyFieldNames = new  Set<string>();
        for (string field : fieldsMap.keySet()) {
            
            Schema.SObjectField F = fieldsMap.get(field);
            
            Schema.DescribeFieldResult R = F.getDescribe();
            
            if (R.isCustom()) {
                
                if (Id == R.getName()) {
                    
                    Taxes__c allTaxesHSettings = Taxes__c.getInstance();
                    value = Decimal.valueOf(Double.valueOf(allTaxesHSettings.get(R.getName()))).setScale(3);                    
                }
            }
        }
        
        return value;
       
        
    }

     //get Service charge Names and values with passed id
    public static string getNameOfServiceCharge(string Id) {
        
        string name = '';
        
        Map<string, Schema.SObjectField> fieldsMap = ServiceCharges__c.sObjectType.getDescribe().fields.getMap();
        
        Set<string> customHierarchyFieldNames = new  Set<string>();
        for (string field : fieldsMap.keySet()) {
            
            Schema.SObjectField F = fieldsMap.get(field);
            
            Schema.DescribeFieldResult R = F.getDescribe();
            
            if (R.isCustom()) {
                string fName = R.getName();
                
                string fLabel = R.getLabel();
                
                if (Id == fName) {
                    name = fLabel;                    
                }
            }
        }

        return name;
    }

    //get Service charge Names and values with passed id
    public static Decimal getPercentageOfServiceCharge(string Id) {
        
        
        Decimal value = 0;
        ServiceCharges__c setting = ServiceCharges__c.getInstance();
        
        Map<string, Schema.SObjectField> fieldsMap = ServiceCharges__c.sObjectType.getDescribe().fields.getMap();
        
        Set<string> customHierarchyFieldNames = new  Set<string>();
        for (string field : fieldsMap.keySet()) {
            
            Schema.SObjectField F = fieldsMap.get(field);
            
            Schema.DescribeFieldResult R = F.getDescribe();
            
            if (R.isCustom()) {
                
                if (Id == R.getName()) {
                    
                    ServiceCharges__c allTaxesHSettings = ServiceCharges__c.getInstance();
                    value = Decimal.valueOf(double.valueOf(allTaxesHSettings.get(R.getName()))).setScale(3);                    
                }
            }
        }
        
        return value;
    }

    public static string getFinancialAccountForTax(string taxNameOrSCName, boolean SC) {
        try {
            String finAccountId;
            if (SC) {
                finAccountId = [Select Financial_Accounts__c from Tax_To_Account_Mapping__c where Service_Charge__c = :taxNameOrSCName].Financial_Accounts__c;
            } else {
                finAccountId = [Select Financial_Accounts__c from Tax_To_Account_Mapping__c where Tax__c = :taxNameOrSCName].Financial_Accounts__c;
            }
            if (finAccountId == '' || finAccountId == null) {
                throw new NoDataFoundException();
            }
            return finAccountId;
        } catch (Exception ex) {
            throw ex;
            return null;
        }
    }

    public static string getFinancialAccountForTxnRecTypes(string recType, string type, string subtype) {
        String finAccName;
        String recTypeId = Utility.searchRecordType(recType, 'Default_Account__c');

        try {
            if(recType=='Default'){
               List<Default_Account__c> txnMapList = [select Financial_Account__c from Default_Account__c where RecordTypeId = :recTypeId AND Default_Type_Name__c= :type Limit 1];
                if (txnMapList.size() > 0) {
                    finAccName = txnMapList[0].Financial_Account__c;
                }
                if (finAccName == '' || finAccName == null) {
                    throw new NoDataFoundException();
                }
            } 
            return finAccName;
        } catch (Exception ex) {
            throw ex;
            return null;
        }
    }

    public static string getCredDebitStatus(string finAcid) {
        if (finAcid != '')
            return [select Debit_Credit__c from Financial_Account__c where id = :finAcid].Debit_Credit__c;
        else
            return null;
    }

    public static String getFields(String strSObjectName) {
        SObjectType sot = Schema.getGlobalDescribe().get(strSObjectName);
        if (sot == null) {
            return null;
        }
        List<Schema.SObjectField> lstFields = sot.getDescribe().fields.getMap().values();
        String strReturn = '';
        for(Integer i = 0; i < lstFields.size(); i++){
           if(i == lstFields.size() - 1){
               strReturn += lstFields.get(i).getDescribe().Name;
           } else {
               strReturn += lstFields.get(i).getDescribe().Name + ',';
           }
        }
        
        if('Event__c'.equals(strSObjectName))
        {
            if(strReturn.Contains(',BEO_Auto_Number__c'))
            {
                strReturn = strReturn.replace(',BEO_Auto_Number__c','');
            }     
        }

        if(strSObjectName=='Contact'){
            if(strReturn.Contains(',Remaining_Current_Quarter_Event_Spends__c')){strReturn = strReturn.replace(',Remaining_Current_Quarter_Event_Spends__c','');}
            if(strReturn.Contains('Remaining_Current_Quarter_Event_Spends__c,')){strReturn = strReturn.replace('Remaining_Current_Quarter_Event_Spends__c,','');}
            if(strReturn.Contains(',Remaining_Current_Quarter_F_B_Spends__c')){strReturn = strReturn.replace(',Remaining_Current_Quarter_F_B_Spends__c','');}
            if(strReturn.Contains('Remaining_Current_Quarter_F_B_Spends__c,')){strReturn = strReturn.replace('Remaining_Current_Quarter_F_B_Spends__c,','');}
            if(strReturn.Contains(',Remaining_Current_Quarter_Room_Spends__c')){strReturn = strReturn.replace(',Remaining_Current_Quarter_Room_Spends__c','');}
            if(strReturn.Contains('Remaining_Current_Quarter_Room_Spends__c,')){strReturn = strReturn.replace('Remaining_Current_Quarter_Room_Spends__c,','');}
            if(strReturn.Contains(',Remaining_Current_Quarter_Sports_Spends__c')){strReturn = strReturn.replace(',Remaining_Current_Quarter_Sports_Spends__c','');}
            if(strReturn.Contains('Remaining_Current_Quarter_Sports_Spends__c,')){strReturn = strReturn.replace('Remaining_Current_Quarter_Sports_Spends__c,','');}
            if(strReturn.Contains(',Remaining_Current_Year_Event_Spends__c')){strReturn = strReturn.replace(',Remaining_Current_Year_Event_Spends__c','');}
            if(strReturn.Contains('Remaining_Current_Year_Event_Spends__c,')){strReturn = strReturn.replace('Remaining_Current_Year_Event_Spends__c,','');}
            if(strReturn.Contains(',Remaining_Current_Year_F_B_Spends__c')){strReturn = strReturn.replace(',Remaining_Current_Year_F_B_Spends__c','');}
            if(strReturn.Contains('Remaining_Current_Year_F_B_Spends__c,')){strReturn = strReturn.replace('Remaining_Current_Year_F_B_Spends__c,','');}
            if(strReturn.Contains(',Remaining_Current_Year_Room_Spends__c')){strReturn = strReturn.replace(',Remaining_Current_Year_Room_Spends__c','');}
            if(strReturn.Contains('Remaining_Current_Year_Room_Spends__c,')){strReturn = strReturn.replace('Remaining_Current_Year_Room_Spends__c,','');}
            if(strReturn.Contains(',Remaining_Current_Year_Sports_Spends__c')){strReturn = strReturn.replace(',Remaining_Current_Year_Sports_Spends__c','');}
            if(strReturn.Contains('Remaining_Current_Year_Sports_Spends__c,')){strReturn = strReturn.replace('Remaining_Current_Year_Sports_Spends__c,','');}
            if(strReturn.Contains(',OtherAddress')){strReturn = strReturn.replace(',OtherAddress','');}
            if(strReturn.Contains('OtherAddress,')){strReturn = strReturn.replace('OtherAddress,','');}
            if(strReturn.Contains(',MailingAddress')){strReturn = strReturn.replace(',MailingAddress','');}
            if(strReturn.Contains('MailingAddress,')){strReturn = strReturn.replace('MailingAddress,','');}
        }
        if(strSObjectName=='Reservation_Registration__c'){
            if(strReturn.Contains(',Cancellation_Status_Flag__c')){strReturn = strReturn.replace(',Cancellation_Status_Flag__c','');}
            if(strReturn.Contains('Cancellation_Status_Flag__c,')){strReturn = strReturn.replace('Cancellation_Status_Flag__c,','');}
        }
        return strReturn;
    }

    public static Payment_Gateway__c GetFirstDefaultGateway()
    {
        return Database.query('SELECT ' + Utility.getFields(Payment_Gateway__c.class.GetName())
                                            + ' FROM ' + Payment_Gateway__c.class.GetName()
                                            + ' WHERE Default__c = true LIMIT 1');
    }

    public static String getCountryCode(String countryName){
        return countryMap.get(countryName);
    }

    /*
    Returns a map of object prefixes to api names or api names to prefixes based on passed in boolean
    */
    public static Map<String,String> getPrefixMap(Boolean idKey)
    {
        //Get a map of the prefixes to tell the object based on the id
        Map<String,String> mapPrefix = new Map<String,String>();

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Set<String> keyPrefixSet = gd.keySet();
        for(String sObj : keyPrefixSet)
        {
           Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
           String tempName = r.getName();
           String tempPrefix = r.getKeyPrefix();
           if(idKey)
           {
               mapPrefix.put(tempName,tempPrefix);
           }
           else
           {
               mapPrefix.put(tempPrefix,tempName);
           }
        }
        return mapPrefix;
    }

    /**
    * @Description : to get current currency symbol
    */
    public static string getcurrencySymbol() {
        String currencySymbol = UserInfo.getDefaultCurrency();
        if (currencySymbol == 'USD')
            currencySymbol = '$';
        else if (currencySymbol == 'EUR')
            currencySymbol = '€';
        return currencySymbol;
    }

    

   /**
    * @Description : method will return false if type/subtype is not mapped to taxes
    */
    public static boolean isTaxMapped(String type, String subtype)
    {
        return isTaxAndFinancialAccountMapped(type, subtype, Utility.getTaxAndFinancialAccountMappings());    
    }

   /**
    * getTaxAndFinancialAccountMappings 
    * @return   return map of Taxes and Service Charges mapped to their respective Financial Account.
    */
    public static Map<String, Tax_To_Account_Mapping__c> getTaxAndFinancialAccountMappings()
	{
		Map<String, Tax_To_Account_Mapping__c> mapOTaxesAndSC = new Map<String, Tax_To_Account_Mapping__c>();
		for(Tax_To_Account_Mapping__c taxToAccMap : (List<Tax_To_Account_Mapping__c>) Data.read('Select Financial_Accounts__c, Financial_Accounts__r.Name, Financial_Accounts__r.Debit_Credit__c, Service_Charge__c, Tax__c from Tax_To_Account_Mapping__c limit 50000', new Map<String, Object> ()))
		{
			if(taxToAccMap.Tax__c != null || taxToAccMap.Tax__c != '')
				mapOTaxesAndSC.put(taxToAccMap.Tax__c, taxToAccMap);
 
			if(taxToAccMap.Service_Charge__c != null || taxToAccMap.Service_Charge__c != '')
				mapOTaxesAndSC.put(taxToAccMap.Service_Charge__c, taxToAccMap);
		}
		return mapOTaxesAndSC;
	}

    /**
    * getTaxAndFinancialAccountMappings 
    * @return   return map of Taxes and Service Charges mapped to their respective Financial Account.
    */
    public static Map<String, Tax_To_Account_Mapping__c> getTaxAndFinancialAccountMappings(Set<String> taxesAndSCNamesSet)
    {
        Map<String, Tax_To_Account_Mapping__c> mapOTaxesAndSC = new Map<String, Tax_To_Account_Mapping__c>();
        for(Tax_To_Account_Mapping__c taxToAccMap : (List<Tax_To_Account_Mapping__c>) Data.read('Select Financial_Accounts__c, Financial_Accounts__r.Name, Financial_Accounts__r.Debit_Credit__c, Service_Charge__c, Tax__c from Tax_To_Account_Mapping__c where Tax__c in :taxesAndSCNamesSet OR Service_Charge__c in :taxesAndSCNamesSet limit 50000', new Map<String, Object> {
            'taxesAndSCNamesSet' => taxesAndSCNamesSet
            }))
        {
            if(taxToAccMap.Tax__c != null)
                mapOTaxesAndSC.put(taxToAccMap.Tax__c, taxToAccMap);
     
            if(taxToAccMap.Service_Charge__c != null)
                mapOTaxesAndSC.put(taxToAccMap.Service_Charge__c, taxToAccMap);
        }
        return mapOTaxesAndSC;
    }

    /**
    * @Description : method will return false if type/subtype is not mapped to taxes
    */
    public static boolean isTaxAndFinancialAccountMapped(String type, String subtype, Map<String, Tax_To_Account_Mapping__c> allFinancialMapping)
    {

        Boolean isFinAccMapped;
        List<TxnChargeToTaxMapping__c> taxMappingRecs = Data.read('select id, Service_Charge_applicable__c, Service_Charge_Name__c, TaxId__c from TxnChargeToTaxMapping__c where Type__c=:dueTypeName AND Subtype__c=:dueSubtypeName', 
        new Map<String, Object>{
            'dueTypeName' => type, 
            'dueSubtypeName' => subtype
        });

        if(taxMappingRecs!=null && taxMappingRecs.size()>0 && (taxMappingRecs[0].TaxId__c!=null || (taxMappingRecs[0].Service_Charge_applicable__c && taxMappingRecs[0].Service_Charge_Name__c!=null)))
        {
            system.debug('++ ' + taxMappingRecs + ' ' + allFinancialMapping);
            isFinAccMapped = isTaxesAppliedToFinancialAccount(taxMappingRecs, allFinancialMapping);
            system.debug('++ ' + isFinAccMapped);
            if(isFinAccMapped)
                return isFinAccMapped;
        }
        if(isFinAccMapped!=null && !isFinAccMapped)
        {
            taxMappingRecs = Data.read('select id, TaxId__c, Service_Charge_Name__c, Service_Charge_applicable__c from TxnChargeToTaxMapping__c where Type__c=:dueTypeName AND Subtype__c=:dueSubtypeName', 
            new Map<String, Object>
            {
                'dueTypeName' => type,
                'dueSubtypeName' => ''
            });
            if(taxMappingRecs!=null && taxMappingRecs.size()>0 && (taxMappingRecs[0].TaxId__c!=null || (taxMappingRecs[0].Service_Charge_applicable__c && taxMappingRecs[0].Service_Charge_Name__c!=null)))
            {
                isFinAccMapped = isTaxesAppliedToFinancialAccount(taxMappingRecs, allFinancialMapping);
                if(isFinAccMapped)
                    return isFinAccMapped;
            }
        }
        return false;    
    }

    /**
    *  @Description : check if tax is mapped to financial account
    */
    public static boolean isTaxesAppliedToFinancialAccount(List<TxnChargeToTaxMapping__c> taxToCharge, Map<String, Tax_To_Account_Mapping__c> allFinancialMapping)
    {
        for(TxnChargeToTaxMapping__c taxToChargeObj :taxToCharge)
        {
            if(taxToChargeObj.Service_Charge_Name__c != null){
                if(!allFinancialMapping.containsKey(getNameOfServiceCharge(taxToChargeObj.Service_Charge_Name__c)))
                    return false;
            }
            if(taxToChargeObj.TaxId__c != null)
            {
                if(!allFinancialMapping.containsKey(getNameOfTax(taxToChargeObj.TaxId__c)))
                    return false;
            }
        }
        return true;
    }

    /**
      *@Name   :joshi
      *@Description :Returns the list of Child, GrandChild etc Facilities
      *@param : List of Location object for which you want to get the child location if it is parent of any.
      *@return : Returns the list of all  child and super child for passed facility.
    **/
    public static List<Location__c> getChildFacilities(List<Location__c> facs) {
        List<Location__c> lstReturn = new List<Location__c>();
        //Create the set of ids
        Set<Id> setIds = new Set<Id>();
        for(Location__c fac : facs){
            setIds.add(fac.id);
        }
        
        List<Location__c> lstFacs = (List<Location__c>) Data.read('SELECT Id, (SELECT Id, Name, Parent_Facility__c FROM Facilities__r) FROM Location__c WHERE Id IN :setIds',
            new Map<String,Object>{
                'setIds'=>setIds
            });

        if(lstFacs.size() > 0){
            //Add the children then check for lower children
            List<Location__c> lstChildren = new List<Location__c>();
            for(Location__c fac : lstFacs){
                lstChildren.addAll(fac.Facilities__r);
            }
            lstReturn.addAll(lstChildren);
            lstReturn.addAll(getChildFacilities(lstChildren));
        }
        return lstReturn;
    }

    public static Default_Account__c getDefaultFinancialAccount(String defaultTypeName)
    {
        List<Default_Account__c> defaultFinAcc = Data.read('Select Financial_Account__c, Financial_Account__r.Name,  Financial_Account__r.Debit_Credit__c, Default_Type_Name__c from Default_Account__c where Default_Type_Name__c=:TypeName AND RecordTypeId=:recId', new Map<String, Object> {'TypeName' => defaultTypeName, 'recId' => Utility.searchRecordType('Default','Default_Account__c')});
        if(defaultFinAcc.size()>0){
            return defaultFinAcc[0];
        }
        else {
            return null;    
        }
    }

    public static Map<Id, Id> getBillToMember(List<Id> contactIds){
            
            Map<Id, Id> contactIdToParentMap = new Map<Id, Id>();
            List<Contact> contactsList = [SELECT Id, Bill_To_Member__r.Id, 
                                            Bill_To_Member__r.Bill_To_Member__r.Id, 
                                            Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id, 
                                            Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id, 
                                            Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id 
                                            FROM Contact WHERE Id IN :contactIds];
            
            for(Contact contact : contactsList) {
                Id superParent = contact.Id;
                if(contact.Bill_To_Member__r.Id != null) {
                    superParent = contact.Bill_To_Member__r.Id;
                }
                if(contact.Bill_To_Member__r.Bill_To_Member__r.Id != null) {
                    superParent = contact.Bill_To_Member__r.Bill_To_Member__r.Id;
                }
                if(contact.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id != null) {
                    superParent = contact.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id;
                }
                if(contact.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id != null) {
                    superParent = contact.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id;
                }
                if(contact.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id != null) {
                    superParent = contact.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Bill_To_Member__r.Id;
                }
                contactIdToParentMap.put(contact.Id, superParent);
            }
        return contactIdToParentMap;
    }

    /*
    @Name   :getParentFacilities
    @Description :Returns the list of Parent, GrandParent etc Facilities
    */
    public static List<Location__c> getParentFacilities(Location__c fac) {
        List<Location__c> lstReturn = new List<Location__c>();
        if(fac.Parent_Facility__c != null){        
           List<Location__c> lstParents = (List<Location__c>)Data.read('SELECT ' + getFields('Location__c') + ' FROM Location__c'+
                ' WHERE Id =:facilityId',
                new Map<String,Object>{
                    'facilityId' => fac.Parent_Facility__c
                });

            if(lstParents.size() > 0){
                //Add the parent then check for higher parents
                lstReturn.addAll(lstParents);
                for(Location__c pFac : lstParents){
                    lstReturn.addAll(getParentFacilities(pFac));
                }
            }
        }
        return lstReturn;
    }
}