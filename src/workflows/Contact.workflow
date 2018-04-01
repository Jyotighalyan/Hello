<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Join_Date</fullName>
        <field>Join_Date__c</field>
        <formula>TODAY()</formula>
        <name>Set Join Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Join Date</fullName>
        <actions>
            <name>Set_Join_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND(PRIORVALUE(Record_Type_Name__c) = &quot;Guest&quot;,Record_Type_Name__c = &quot;Member&quot;)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
