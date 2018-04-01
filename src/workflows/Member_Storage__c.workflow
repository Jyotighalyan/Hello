<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Member_Storage_Rental_Status</fullName>
        <description>Updates &quot;Rental Status&quot; field to Past, when the Member Storage end date is &lt; today&apos;s date.</description>
        <field>Rental_Status__c</field>
        <literalValue>Past</literalValue>
        <name>Update Member Storage Rental Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Update Member Storage Rental Status</fullName>
        <actions>
            <name>Update_Member_Storage_Rental_Status</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>End_Date__c &lt;  TODAY()</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
