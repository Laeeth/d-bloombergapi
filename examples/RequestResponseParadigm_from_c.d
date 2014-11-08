import std.stdio;
import std.string;
import blpapi;

static ulong streamWriter(const char* data, int length, void *stream)
{
 assert(data);
 assert(stream);
 return fwrite(data, length, 1, cast(FILE *)stream);
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
		blpapi_Element_print(messageElements, &streamWriter, stdout, 0, 4);
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
		blpapi_Element_print(messageElements, &streamWriter, stdout, 0, 4);
		if (((BLPAPI.EVENTTYPE_SESSION_STATUS == blpapi_Event_eventType(event)) && ("SessionTerminated"!=blpapi_Message_typeString(message))))
		{
			fprintf(stdout, "Terminating: %s\n", blpapi_Message_typeString(message));
			return;
		}
	}
	blpapi_MessageIterator_destroy(iter);
	auto elements = blpapi_Request_elements(request);
	assert(elements);
	blpapi_Element_getElement(elements, &securitiesElements, "securities", 0);
	assert(securitiesElements);
	blpapi_Element_setValueString(securitiesElements, "IBM US Equity", BLPAPI.ELEMENT_INDEX_END);
	blpapi_Element_getElement(elements, &fieldsElements, "fields", 0);
	blpapi_Element_setValueString(fieldsElements, "PX_LAST", BLPAPI.ELEMENT_INDEX_END);
	memset(&correlationId, '\0', sizeof(correlationId));
	correlationId.size = sizeof(correlationId);
	correlationId.valueType = BLPAPI.CORRELATION_TYPE_INT;
	correlationId.value.intValue = cast(blpapi_UInt64_t)1;
	blpapi_Session_sendRequest(session, request, &correlationId, 0, 0, 0, 0);
	while (continueToLoop) {
		blpapi_Event_t *event = 0;
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