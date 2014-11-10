import std.stdio;
import std.string;
import std.conv;
import blpapi;

void memset(void* ptr, ubyte val, long nbytes)
{
	foreach(i;0..nbytes)
		*cast(ubyte*)(cast(ubyte)ptr+i)=val;
}
extern (Windows)
{
	static int streamWriter(const char* data, int length, void *stream)
	{
		assert(data);
		assert(stream);
		return cast(int) fwrite(data, length, 1, cast(FILE *)stream);
	}
	static void handleDataEvent(const blpapi_Event_t *event, int updateCount)
	{
		blpapi_MessageIterator_t* iter = cast(blpapi_MessageIterator_t*)0;
		blpapi_Message_t* message = cast(blpapi_Message_t*)0;
		assert(event);
		writefln("EventType=%d", blpapi_Event_eventType(event));
		writefln("updateCount = %d", updateCount);
		iter = blpapi_MessageIterator_create(event);
		assert(iter);
		while (0 == blpapi_MessageIterator_next(iter, &message)) {
			blpapi_CorrelationId_t correlationId;
			blpapi_Element_t* messageElements = cast(blpapi_Element_t*)0;
			assert(message);
			correlationId = blpapi_Message_correlationId(message, 0);
			writefln("correlationId=%d %d %lld", correlationId.valueType, correlationId.classId, correlationId.value.intValue);
			writefln("messageType = %s", blpapi_Message_typeString(message));
			messageElements = blpapi_Message_elements(message);
			blpapi_Element_print(messageElements, &streamWriter, cast(void*)&stdout, 0, 4);
		}
		blpapi_MessageIterator_destroy(iter);
	}

	static void handleOtherEvent(const blpapi_Event_t *event)
	{
		blpapi_MessageIterator_t *iter = cast(blpapi_MessageIterator_t *)0;
		blpapi_Message_t *message = cast(blpapi_Message_t *)0;
		assert(event);
		writefln("EventType=%d", blpapi_Event_eventType(event));
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
			blpapi_Element_print(messageElements, &streamWriter, cast(void*)&stdout, 0, 4);
			if ((BLPAPI.EVENTTYPE_SESSION_STATUS == blpapi_Event_eventType(event)) && ("SessionTerminated"==blpapi_Message_typeString(message))){
				writefln("Terminating: %s",blpapi_Message_typeString(message));
				return;  // should be exit main ?
			}
		}
		blpapi_MessageIterator_destroy(iter);
	}
}

int main()
{
	blpapi_SessionOptions_t *sessionOptions = cast(blpapi_SessionOptions_t *)0;
	blpapi_Session_t* session = cast(blpapi_Session_t* )0;
	blpapi_CorrelationId_t subscriptionId;
	blpapi_SubscriptionList *subscriptions = cast(blpapi_SubscriptionList *)0;
	string[] fields = ["LAST_PRICE"];
	const char **options = cast(const(char**))0;
	int updateCount = 0;
	setbuf(cast(shared(_IO_FILE*))&stdout, cast(char*)0); /* NO SHOW */
	sessionOptions = blpapi_SessionOptions_create();
	assert(sessionOptions);
	blpapi_SessionOptions_setServerHost(sessionOptions, "localhost");
	blpapi_SessionOptions_setServerPort(sessionOptions, 8194);
	session = blpapi_Session_create(sessionOptions,cast(blpapi_EventHandler_t) 0, cast(blpapi_EventDispatcher*)0, cast(void*)0);
	assert(session);
	blpapi_SessionOptions_destroy(sessionOptions);
	if (0 != blpapi_Session_start(session)) {
		stderr.writefln("Failed to start session.");
		blpapi_Session_destroy(session);
		return 1;
	}
	if (0 != blpapi_Session_openService(session, "//blp/mktdata")){
		stderr.writefln("Failed to open service //blp/mktdata.");
		blpapi_Session_destroy(session);
		return 1;
	}
	memset(&subscriptionId, '\0', subscriptionId.size);
	subscriptionId.valueType = BLPAPI.CORRELATION_TYPE_INT;
	subscriptionId.value.intValue = cast(blpapi_UInt64_t)2;
	subscriptions = blpapi_SubscriptionList_create();
	assert(subscriptions);
	blpapi_SubscriptionList_add(subscriptions, cast(const(char*))"AAPL US Equity", &subscriptionId, cast(const(char**))fields, cast(const(char**))options, cast(ulong)1, cast(ulong)0);
	blpapi_Session_subscribe(session, subscriptions, cast(const(blpapi_Identity*))0, cast(const(char*))0, 0);
	
	while (1) {
		blpapi_Event_t* event = cast(blpapi_Event_t* )0;
		blpapi_Session_nextEvent(session, &event, 0);
		assert(event);
		switch (blpapi_Event_eventType(event)) {
			case BLPAPI.EVENTTYPE_SUBSCRIPTION_DATA:
			handleDataEvent(event, updateCount++);
			break;
			default:
			handleOtherEvent(event);
			break;
		}
	blpapi_Event_release(event);
	}
	return 0;
}