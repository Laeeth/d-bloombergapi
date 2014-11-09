/* AsynchronousEventHandling_from_c.d */

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
		return cast(int) fwrite(data, length, 1, cast(FILE *)stream);
	}

	static void dumpEvent(blpapi_Event_t *event) /* not const! */
	{
		blpapi_MessageIterator_t* iter = cast(blpapi_MessageIterator_t*)0;
		blpapi_Message_t* message = cast(blpapi_Message_t*)0;
		assert(event);
		writefln("eventType=%d", blpapi_Event_eventType(event));
		iter = blpapi_MessageIterator_create(event);
		assert(iter);
		while (0 == blpapi_MessageIterator_next(iter, &message)) {
			blpapi_CorrelationId_t correlationId;
			blpapi_Element_t* messageElements = cast(blpapi_Element_t*)0;
			assert(message);
			writefln("messageType=%s", blpapi_Message_typeString(message));
			correlationId = blpapi_Message_correlationId(message, 0);
			writefln("correlationId=%d %d %lld", correlationId.valueType, correlationId.classId, correlationId.value.intValue);
			messageElements = blpapi_Message_elements(message);
			assert(messageElements);
			blpapi_Element_print(messageElements, &streamWriter, cast(void*)&stdout, 0, 4);
		}
	}

	static void processEvent(blpapi_Event_t *event, blpapi_Session_t *session, void *userData)
	{
		assert(event);
		assert(session);
		switch (blpapi_Event_eventType(event)) {
			case BLPAPI.EVENTTYPE_SESSION_STATUS: {
				blpapi_MessageIterator_t* iter = cast(blpapi_MessageIterator_t*)0;
				blpapi_Message_t* message = cast(blpapi_Message_t*)0;
				iter = blpapi_MessageIterator_create(event);
				assert(iter);
				while (0 == blpapi_MessageIterator_next(iter, &message)) {
					if ("SessionStarted" == blpapi_Message_typeString(message)) {
						blpapi_CorrelationId_t correlationId;
						memset(&correlationId, '\0', correlationId.size);
						correlationId.size = correlationId.size;
						correlationId.valueType = BLPAPI.CORRELATION_TYPE_INT;
						correlationId.value.intValue = cast(blpapi_UInt64_t)99;
						blpapi_Session_openServiceAsync(session, "//blp/refdata", &correlationId);
					} else {
						blpapi_Element_t* messageElements = cast(blpapi_Element_t*)0;
						messageElements = blpapi_Message_elements(message);
						assert(messageElements);
						blpapi_Element_print(messageElements, &streamWriter, cast(void*)&stdout, 0, 4);
						throw new Exception("shutdown requested");
					}
				}
				break;
			 }

			case BLPAPI.EVENTTYPE_SERVICE_STATUS: {
				blpapi_MessageIterator_t* iter = cast(blpapi_MessageIterator_t*)0;
				blpapi_Message_t* message = cast(blpapi_Message_t*)0;
				blpapi_Service_t* refDataSvc = cast(blpapi_Service_t*)0;
				blpapi_CorrelationId_t correlationId;
				iter = blpapi_MessageIterator_create(event);
				assert(iter);
				while (0 == blpapi_MessageIterator_next(iter, &message)) {
					assert(message);
					correlationId = blpapi_Message_correlationId(message, 0);
					if (correlationId.value.intValue == cast(blpapi_UInt64_t)99 && ("ServiceOpened"==blpapi_Message_typeString(message)))
					{
						blpapi_Request_t* request = cast(blpapi_Request_t*)0;
						blpapi_Element_t* elements = cast(blpapi_Element_t*)0;
						blpapi_Element_t* securitiesElements = cast(blpapi_Element_t*)0;
						blpapi_Element_t* fieldsElements = cast(blpapi_Element_t*)0;
						/* Construct and issue a Request */
						blpapi_Session_getService(session, &refDataSvc, "//blp/refdata");
						blpapi_Service_createRequest(refDataSvc, &request, "ReferenceDataRequest");
						assert(request);
						elements = blpapi_Request_elements(request);
						assert(elements);
						blpapi_Element_getElement(elements, &securitiesElements, "securities", cast(const(blpapi_Name*))0);
						assert(securitiesElements);
						blpapi_Element_setValueString(securitiesElements, "IBM US Equity", BLPAPI.ELEMENT_INDEX_END);
						blpapi_Element_getElement(elements, &fieldsElements, "fields", cast(const(blpapi_Name*))0);
						blpapi_Element_setValueString(fieldsElements, "PX_LAST", BLPAPI.ELEMENT_INDEX_END);
						memset(&correlationId, '\0', correlationId.size);
						correlationId.valueType = BLPAPI.CORRELATION_TYPE_INT;
						correlationId.value.intValue = cast(blpapi_UInt64_t)86;
						blpapi_Session_sendRequest(session, request, &correlationId, cast(blpapi_Identity*)0, cast(blpapi_EventQueue*)0, cast(const(char*))0, 0);
					}
					else {
						blpapi_Element_t* messageElements = cast(blpapi_Element_t*)0;
						stderr.writefln("Unexpected message");
						messageElements = blpapi_Message_elements(message);
						assert(messageElements);
						blpapi_Element_print(messageElements, &streamWriter, cast(void*)&stdout, 0, 4);
					}
				}
				break;
				}
			case BLPAPI.EVENTTYPE_PARTIAL_RESPONSE: {
				dumpEvent(event);
				break;
			}
			case BLPAPI.EVENTTYPE_RESPONSE: {
				dumpEvent(event);
				assert(session);
				writefln("terminate process from handler");
				blpapi_Session_stop(session);
				return; // should be exit program
				break;
			}
			default:
			{
				stderr.writefln("default-case");
				stderr.writefln("Unxepected Event Type %d\n",blpapi_Event_eventType(event));
				throw new Exception("default-case");
				break;
			}
			
		}
	}
} //extern (C)
int main(string[] args)
{
	blpapi_SessionOptions_t* sessionOptions = cast(blpapi_SessionOptions_t*)0;
	blpapi_Session_t* session = cast(blpapi_Session_t*)0;
	sessionOptions = blpapi_SessionOptions_create();
	assert(sessionOptions);
	blpapi_SessionOptions_setServerHost(sessionOptions, "localhost");
	blpapi_SessionOptions_setServerPort(sessionOptions, 8194);
	session = blpapi_Session_create(sessionOptions, &processEvent, cast(blpapi_EventDispatcher*)0, cast(void*)0);
	assert(session);
	blpapi_SessionOptions_destroy(sessionOptions);
	if (0 != blpapi_Session_start(session)) {
		stderr.writefln("Failed to start async session");
		blpapi_Session_destroy(session);
		return 1;
	}
	//pause(); from threading header
	blpapi_Session_destroy(session);
	return 0;
}
