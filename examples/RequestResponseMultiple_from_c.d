/* RequestResponseParadigm_from_c.d */
import std.stdio;
import std.string;
import blpapi;

static int streamWriter(const char* data, int length, void *stream)
{
	assert(data);
	assert(stream);
	return cast(int) fwrite(data, length, 1, cast(FILE *)stream);
}
static void handleResponseEvent(const blpapi_Event_t *event)
{
	blpapi_MessageIterator_t* iter = cast(blpapi_MessageIterator_t*)0;
	blpapi_Message_t* message = cast(blpapi_Message_t)0;
	assert(event);
	iter = blpapi_MessageIterator_create(event);
	assert(iter);
	while (0 == blpapi_MessageIterator_next(iter, &message)) {
		blpapi_Element_t *referenceDataResponse = 0;
		blpapi_Element_t *securityDataArray = 0;
		int numItems = 0;
		assert(message);
		referenceDataResponse = blpapi_Message_elements(message);
		assert(referenceDataResponse);
		if (blpapi_Element_hasElement(referenceDataResponse, "responseError", 0)) {
			stderr.writefln("has responseError");
			blpapi_Element_print(referenceDataResponse, &streamWriter, stdout, 0, 4);
			throw new Exception("response error");
		}
		blpapi_Element_getElement(referenceDataResponse, &securityDataArray, "securityData", 0);
		numItems = blpapi_Element_numValues(securityDataArray);
		foreach(i;0..numItems)
		{
			blpapi_Element_t* securityData = cast(blpapi_Element_t*)0;
			blpapi_Element_t* securityElement = cast(blpapi_Element_t*)0;
			const char *security = 0;
			blpapi_Element_t* sequenceNumberElement = cast(blpapi_Element_t*)0;
			int sequenceNumber = -1;
			blpapi_Element_getValueAsElement(securityDataArray, &securityData, i);
			assert(securityData);
			blpapi_Element_getElement(securityData, &securityElement, "security", 0);
			assert(securityElement);
			blpapi_Element_getValueAsString(securityElement, &security, 0);
			assert(security);
			blpapi_Element_getElement(securityData, &sequenceNumberElement, "sequenceNumber", 0);
			assert(sequenceNumberElement);
			blpapi_Element_getValueAsInt32(sequenceNumberElement, &sequenceNumber, 0);
			if (blpapi_Element_hasElement(securityData, "securityError", 0)){
				blpapi_Element_t *securityErrorElement = 0;
				printf("*security =%s\n", security);
				blpapi_Element_getElement(securityData, &securityErrorElement, "securityError", 0);
				assert(securityErrorElement);
				blpapi_Element_print(securityErrorElement, &streamWriter, stdout, 0, 4);
				return;
			} else {
				blpapi_Element_t* fieldDataElement = cast(blpapi_Element_t*)0;
				blpapi_Element_t* PX_LAST_Element = cast(blpapi_Element_t*)0;
				blpapi_Element_t* DS002_Element = cast(blpapi_Element_t*)0;
				blpapi_Element_t* VWAP_VOLUME_Element = cast(blpapi_Element_t*)0;
				double px_last = cast(double)777;
				const char *ds002 = cast(const char*)0;
				double vwap_volume = cast(double)666;
				blpapi_Element_getElement(securityData, &fieldDataElement, "fieldData", 0);
				assert(fieldDataElement);
				blpapi_Element_getElement(fieldDataElement, &PX_LAST_Element, "PX_LAST", 0);
				assert(PX_LAST_Element);
				blpapi_Element_getValueAsFloat64(PX_LAST_Element, &px_last, 0);
				blpapi_Element_getElement(fieldDataElement, &DS002_Element, "DS002", 0);
				assert(DS002_Element);
				blpapi_Element_getValueAsString(DS002_Element, &ds002, 0);
				blpapi_Element_getElement(fieldDataElement, &VWAP_VOLUME_Element, "VWAP_VOLUME", 0);
				assert(VWAP_VOLUME_Element);
				blpapi_Element_getValueAsFloat64(VWAP_VOLUME_Element, &vwap_volume, 0);
				writefln("*security =%s", security);
				writefln("*sequenceNumber=%d", sequenceNumber);
				writefln("*px_last =%f", px_last);
				writefln("*ds002 =%s", ds002);
				writefln("*vwap_volume =%f", vwap_volume);
				writefln("");
			}
		}
	}
	blpapi_MessageIterator_destroy(iter);
}

static void handleOtherEvent(const blpapi_Event_t *event)
{
	blpapi_MessageIterator_t *iter = 0;
	blpapi_Message_t *message = 0;
	assert(event);
	printf("EventType=%d\n", blpapi_Event_eventType(event));
	iter = blpapi_MessageIterator_create(event);
	assert(iter);
	while (0 == blpapi_MessageIterator_next(iter, &message)) {
		blpapi_CorrelationId_t correlationId;
		blpapi_Element_t *messageElements = 0;
		assert(message);
		correlationId = blpapi_Message_correlationId(message, 0);
		printf("correlationId=%d %d %lld\n",
		correlationId.valueType,
		correlationId.classId,
		correlationId.value.intValue);
		printf("messageType=%s\n", blpapi_Message_typeString(message));
		messageElements = blpapi_Message_elements(message);
		assert(messageElements);
		blpapi_Element_print(messageElements, &streamWriter, stdout, 0, 4);
		if (BLPAPI_EVENTTYPE_SESSION_STATUS == blpapi_Event_eventType(event) && 0 == strcmp("SessionTerminated", blpapi_Message_typeString(message))){
			fprintf(stdout, "Terminating: %s\n", blpapi_Message_typeString(message));
			exit(1);
		}
	}
	blpapi_MessageIterator_destroy(iter);
}

int main(string[] argv)
{
	blpapi_SessionOptions_t *sessionOptions = 0;
	blpapi_Session_t *session = 0;
	blpapi_CorrelationId_t requestId;
	blpapi_Service_t *refDataSvc = 0;
	blpapi_Request_t *request = 0;
	blpapi_Element_t *elements = 0;
	blpapi_Element_t *securitiesElements = 0;
	blpapi_Element_t *fieldsElements = 0;
	blpapi_CorrelationId_t correlationId;
	int continueToLoop = 1;
	sessionOptions = blpapi_SessionOptions_create();
	assert(sessionOptions);
	blpapi_SessionOptions_setServerHost(sessionOptions, "localhost");
	blpapi_SessionOptions_setServerPort(sessionOptions, "8194");
	session = blpapi_Session_create(sessionOptions, 0, 0, 0);
	assert(session);
	blpapi_SessionOptions_destroy(sessionOptions);
	if (0 != blpapi_Session_start(session)) {
		stderr.writefln("Failed to start session.");
		blpapi_Session_destroy(session);
		return 1;
	}
	if (0 != blpapi_Session_openService(session,"//blp/refdata")){
		stderr.writefln("Failed to open service //blp/refdata.");
		blpapi_Session_destroy(session);
		return 1;
	}

	memset(&requestId, '\0', sizeof(requestId));
	requestId.size = sizeof(requestId);
	requestId.valueType = BLPAPI_CORRELATION_TYPE_INT;
	requestId.value.intValue = cast(blpapi_UInt64_t)1;
	blpapi_Session_getService(session, &refDataSvc, "//blp/refdata");
	blpapi_Service_createRequest(refDataSvc, &request, "ReferenceDataRequest");
	assert(request);
	elements = blpapi_Request_elements(request);
	assert(elements);
	blpapi_Element_getElement(elements, &securitiesElements, "securities", 0);
	assert(securitiesElements);
	blpapi_Element_setValueString(securitiesElements, "AAPL US Equity", BLPAPI_ELEMENT_INDEX_END); 
	blpapi_Element_setValueString(securitiesElements, "IBM US Equity", BLPAPI_ELEMENT_INDEX_END);
	blpapi_Element_setValueString(securitiesElements, "BLAHBLAHBLAH US Equity", BLPAPI_ELEMENT_INDEX_END);
	blpapi_Element_getElement(elements, &fieldsElements, "fields", 0);
	blpapi_Element_setValueString(fieldsElements, "PX_LAST", BLPAPI_ELEMENT_INDEX_END);
	blpapi_Element_setValueString(fieldsElements, "DS002", BLPAPI_ELEMENT_INDEX_END);
	blpapi_Element_setValueString(fieldsElements, "VWAP_VOLUME", BLPAPI_ELEMENT_INDEX_END);
	memset(&correlationId, '\0', sizeof(correlationId));
	correlationId.size = sizeof(correlationId);
	correlationId.valueType = BLPAPI_CORRELATION_TYPE_INT;
	correlationId.value.intValue = cast(blpapi_UInt64_t)1;
	blpapi_Session_sendRequest(session, request, &correlationId, 0, 0, 0, 0);
	
	while (continueToLoop) {
		blpapi_Event_t *event = 0;
		blpapi_Session_nextEvent(session, &event, 0);
		assert(event);
		switch (blpapi_Event_eventType(event)) {
			case BLPAPI_EVENTTYPE_RESPONSE: /* final event */
				continueToLoop = 0; /* fall through */
			case BLPAPI_EVENTTYPE_PARTIAL_RESPONSE:
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