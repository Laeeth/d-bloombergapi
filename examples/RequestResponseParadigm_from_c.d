//missing end lines including main!
import std.stdio;
import std.string;
import std.conv;
import blpapi;

void memset(void* ptr, ubyte val, long nbytes)
{
	foreach(i;0..nbytes)
		*cast(ubyte*)(cast(ubyte)ptr+i)=val;
}

extern (C)
{
	static int streamWriter(const char* data, int length, void *stream)
	{
	 assert(data);
	 assert(stream);
	 return cast(int)fwrite(data, length, 1, cast(FILE *)stream);
	}

	static void handleResponseEvent(const blpapi_Event_t *event)
	{
		blpapi_MessageIterator_t *iter = cast(blpapi_MessageIterator_t*)0;
		blpapi_Message_t *message = cast(blpapi_Message_t*)0;
		assert(event);
		writefln("Event Type = %s", blpapi_Event_eventType(event));
		iter = blpapi_MessageIterator_create(event);
		assert(iter);
		while (0 == blpapi_MessageIterator_next(iter, &message)) {
			blpapi_CorrelationId_t correlationId;
			blpapi_Element_t* messageElements = cast(blpapi_Element_t*)0;
			assert(message);
			correlationId = blpapi_Message_correlationId(message, 0);
			writefln("correlationId=%d %d %lld", correlationId.valueType, correlationId.classId, correlationId.value.intValue);
			writefln("messageType =%s", blpapi_Message_typeString(message));
			messageElements = blpapi_Message_elements(message);
			assert(messageElements);
			blpapi_Element_print(messageElements, &streamWriter, cast(void*)&stdout, 0, 4);
		}
		blpapi_MessageIterator_destroy(iter);
	}

	static void handleOtherEvent(const blpapi_Event_t *event)
	{
		blpapi_MessageIterator_t *iter = cast(blpapi_MessageIterator_t*)0;
		blpapi_Message_t *message = cast(blpapi_Message_t*) 0;
		assert(event);
		writefln("EventType=%s", blpapi_Event_eventType(event));
		iter = blpapi_MessageIterator_create(event);
		assert(iter);
		while (0 == blpapi_MessageIterator_next(iter, &message)) {
			blpapi_CorrelationId_t correlationId;
			blpapi_Element_t* messageElements = cast(blpapi_Element_t*)0;
			assert(message);
			correlationId = blpapi_Message_correlationId(message, 0);
			writefln("correlationId=%d %d %lld", correlationId.valueType, correlationId.classId, correlationId.value.intValue);
			writefln("messageType=%s", blpapi_Message_typeString(message));
			messageElements = blpapi_Message_elements(message);
			assert(messageElements);
			blpapi_Element_print(messageElements, &streamWriter, cast(void*)&stdout, 0, 4);
			if (((BLPAPI.EVENTTYPE_SESSION_STATUS == blpapi_Event_eventType(event)) && ("SessionTerminated"!=blpapi_Message_typeString(message))))
			{
				writefln("Terminating: %s", blpapi_Message_typeString(message));
				return;
			}
		}
		blpapi_MessageIterator_destroy(iter);
	}
} // extern (C)

int main(string[] argv)
{
	blpapi_SessionOptions_t *sessionOptions = cast(blpapi_SessionOptions_t*)0;
	blpapi_Session_t *session = cast(blpapi_Session_t *)0;
	blpapi_CorrelationId_t requestId;
	blpapi_Service_t *refDataSvc = cast(blpapi_Service_t *)0;
	blpapi_Request_t *request = cast(blpapi_Request_t *)0;
	blpapi_Element_t *elements = cast(blpapi_Element_t *)0;
	blpapi_Element_t *securitiesElements = cast(blpapi_Element_t *)0;
	blpapi_Element_t *fieldsElements = cast(blpapi_Element_t *)0;
	int continueToLoop = 1;
	blpapi_CorrelationId_t correlationId;
	sessionOptions = blpapi_SessionOptions_create();
	assert(sessionOptions);
	blpapi_SessionOptions_setServerHost(sessionOptions, "localhost");
	blpapi_SessionOptions_setServerPort(sessionOptions, 8194);
	session = blpapi_Session_create(sessionOptions, cast(blpapi_EventHandler_t)0, cast(blpapi_EventDispatcher*)0, cast(void*)0);
	assert(session);
	blpapi_SessionOptions_destroy(sessionOptions);
	if (0 != blpapi_Session_start(session)) {
		stderr.writefln("Failed to start session.");
		blpapi_Session_destroy(session);
		return 1;
	}
	if (0 != blpapi_Session_openService(session, "//blp/refdata")){
		stderr.writefln("Failed to open service //blp/refdata.");
		blpapi_Session_destroy(session);
		return 1;
	}
	memset(&requestId, '\0', requestId.size);
	requestId.valueType = BLPAPI.CORRELATION_TYPE_INT;
	requestId.value.intValue = cast(blpapi_UInt64_t)1;
	blpapi_Session_getService(session, &refDataSvc, "//blp/refdata");
	blpapi_Service_createRequest(refDataSvc, &request, "ReferenceDataRequest");
	assert(request);elements = blpapi_Request_elements(request);
	assert(elements);
	blpapi_Element_getElement(elements, &securitiesElements, cast(const(char*))"securities", cast(const(blpapi_Name*))0);
	assert(securitiesElements);
	blpapi_Element_setValueString(securitiesElements, cast(const(char*))"IBM US Equity", BLPAPI.ELEMENT_INDEX_END);
	blpapi_Element_getElement(elements, &fieldsElements, cast(const(char*))"fields", cast(const(blpapi_Name*))0);
	blpapi_Element_setValueString(fieldsElements, cast(const(char*))"PX_LAST", BLPAPI.ELEMENT_INDEX_END);
	memset(&correlationId, '\0', correlationId.size);
	correlationId.valueType = BLPAPI.CORRELATION_TYPE_INT;
	correlationId.value.intValue = cast(blpapi_UInt64_t)1;
	blpapi_Session_sendRequest(session, request, &correlationId, cast(blpapi_Identity*) 0, cast(blpapi_EventQueue*)0, cast(const(char*))0, 0);
	while (continueToLoop) {
		blpapi_Event_t *event = cast(blpapi_Event_t *)0;
		blpapi_Session_nextEvent(session, &event, 0);
		assert(event);
		switch (blpapi_Event_eventType(event)) {
			case BLPAPI.EVENTTYPE_RESPONSE: // final event
				continueToLoop = 0; // fall through
			case BLPAPI.EVENTTYPE_PARTIAL_RESPONSE:
				handleResponseEvent(event);
				break;
			default:
				handleOtherEvent(event);
				break;
		}
		blpapi_Event_release(event);
	}
	blpapi_Session_stop(session);
	blpapi_Request_destroy(request);
	blpapi_Session_destroy(session);
	return 0;
	
}