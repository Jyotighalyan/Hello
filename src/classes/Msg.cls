public with sharing abstract class Msg {
	public Id recordId;
	public String name;
	
	public Msg() {}

	public static List<Msg> fromRecords(Type msgType, List<SObject> records) {
		List<Msg> msgs = new List<Msg>();

		for (SObject so : records) {
			msgs.add(fromRecord(msgType, so));
		}

		return msgs;
	}
	
	public static Msg fromRecord(Type msgType, SObject record) {
		Map<String,Object> msgFieldData = new Map<String,Object>();

		msgFieldData.put('recordId', record.Id);
		msgFieldData.put('name', record.get('Name'));

		Msg m = (Msg)msgType.newInstance();

		for (FieldMapping fm : m.getFieldMappings()) {
			if (fm.serializeType != null) {
				// list conversion
				List<Msg> childMsgs = new List<Msg>();
				for (SObject so : record.getSObjects(fm.fieldApiName)) {
					childMsgs.add(Msg.fromRecord(fm.serializeType, so));
				}
				msgFieldData.put(fm.fieldAlias, childMsgs);
			} else {
				msgFieldData.put(fm.fieldAlias, record.get(fm.fieldApiName));
			}
		}

		return (Msg)JSON.deserialize(JSON.serialize(msgFieldData), msgType);
	}

	public SObject toRecord() {
		SObjectType sot 	= getType();
		SObject rec 		= sot.newSObject(this.recordId);
		try {
			rec.put('Name', this.name);
		} catch (Exception e) {
			system.debug('ignore, its likely Field Name is not editable (because its an autonumber)');
		}

		// JSON Serialize 'this' and then desirialize to a Map<String,Object>
		// crappy hack to support dynamic reflection of class field members
		Map<String,Object> msgData = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this));

		for (FieldMapping fm : this.getFieldMappings()) {
			if (!fm.isReadOnly) {
				rec.put(fm.fieldApiName, msgData.get(fm.fieldAlias));
				// @todo: access violation issues
				// @todo: data conversion issues
				// don't convert child records because those need to be processed separately by the caller.
			}
		}
		
		return rec;
	}

	public abstract SObjectType getType();
	public abstract List<FieldMapping> getFieldMappings();

	public class FieldMapping {
		public String fieldApiName;
		public String fieldAlias;
		public Boolean isReadOnly;
		public Type serializeType;

		public FieldMapping(String fieldApiName, String fieldAlias) {
			this(fieldApiName, fieldAlias, false, null);
		}

		public FieldMapping(String fieldApiName, String fieldAlias, Type serializeType) {
			this(fieldApiName, fieldAlias, false, serializeType);
		}

		public FieldMapping(String fieldApiName, String fieldAlias, Boolean isReadOnly) {
			this(fieldApiName, fieldAlias, isReadOnly, null);
		}

		public FieldMapping(String fieldApiName, String fieldAlias, Boolean isReadOnly, Type serializeType) {
			this.fieldApiName 	= fieldApiName;
			this.fieldAlias 	= fieldAlias;
			this.isReadOnly 	= isReadOnly;
			this.serializeType 	= serializeType;
		}
	}
}