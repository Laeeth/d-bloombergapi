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
		return cast(int)fwrite(data, length, 1, cast(FILE *)stream);
	}

	struct _UserData {
		const char *d_label;
		FILE *d_stream;
	}
	alias UserData_t=_UserData;

	static void dumpEvent(const blpapi_Event_t *event,  UserData_t *userData)
	{
		blpapi_MessageIterator_t *iter = cast(blpapi_MessageIterator_t*)0;
		blpapi_Message_t *message = cast(blpapi_Message_t*)0;
		assert(event);
		assert(userData);
		assert(userData.d_label);
		assert(userData.d_stream);
		fprintf(userData.d_stream, cast(const(char*))"handler label=%s\n", userData.d_label);
		fprintf(userData.d_stream, cast(const(char*))"eventType=%d\n",
		blpapi_Event_eventType(event));
		iter = blpapi_MessageIterator_create(event);
		assert(iter);
		while (0 == blpapi_MessageIterator_next(iter, &message)) {
			blpapi_CorrelationId_t correlationId;
			blpapi_Element_t *messageElements = cast(blpapi_Element_t *)0;
			assert(message);
			writefln("messageType=%s", blpapi_Message_typeString(message));
			messageElements=blpapi_Message_elements(message);
			correlationId = blpapi_Message_correlationId(message, 0);
			writefln("correlationId=%d %d %lld", correlationId.valueType, correlationId.classId, correlationId.value.intValue);
			blpapi_Element_print(messageElements, &streamWriter, cast(void*)&stdout, 0, 4);
		}
	}

	static void handleDataEvent(const blpapi_Event_t *event, const blpapi_Session_t *session, UserData_t *userData)
	{
		assert(event);
		assert(userData);
		fprintf(userData.d_stream, cast(const(char*))"handleDataEventHandler: enter\n");
		dumpEvent(event, userData);
		fprintf(userData.d_stream, "handleDataEventHandler: leave\n");
	}

	static void handleStatusEvent(const blpapi_Event_t *event, const blpapi_Session_t *session, UserData_t *userData)
	{
		assert(event);
		assert(session);
		assert(userData); /* this application expects userData */
		fprintf(userData.d_stream, "handleStatusEventHandler: enter\n");
		dumpEvent(event, userData);
		fprintf(userData.d_stream, "handleStatusEventHandler: leave\n");
	}

	static void handleOtherEvent(const blpapi_Event_t *event, const blpapi_Session_t *session, UserData_t *userData)
	{
		assert(event);
		assert(userData);
		assert(userData.d_stream);
		fprintf(userData.d_stream, "handleOtherEventHandler: enter\n");
		dumpEvent(event, userData);
		fprintf(userData.d_stream, "handleOtherEventHandler: leave\n");
	}

	static void processEvent(blpapi_Event_t *event, blpapi_Session_t *session, void *buffer)
	{
		UserData_t *userData = cast(UserData_t *)buffer;
		assert(event);
		assert(session);
		assert(buffer);
		switch (blpapi_Event_eventType(event)) {
			case BLPAPI.EVENTTYPE_SUBSCRIPTION_DATA:
				handleDataEvent(event, session, userData);
				break;
			case BLPAPI.EVENTTYPE_SESSION_STATUS, BLPAPI.EVENTTYPE_SERVICE_STATUS, BLPAPI.EVENTTYPE_SUBSCRIPTION_STATUS:
				handleStatusEvent(event, session, userData);
				break;
			default:
				handleOtherEvent(event, session, userData);
				break;
		}
	}
} // extern C

int main(string[] argv)
{
	blpapi_SessionOptions_t *sessionOptions = cast(blpapi_SessionOptions_t *)0;
	blpapi_Session_t *session = cast(blpapi_Session_t*)0;
	UserData_t userData = { "myLabel", cast(shared(_iobuf*))&stdout };
	/* IBM */
	string topic_IBM = "IBM US Equity";
	string[] fields_IBM = [ "LAST_TRADE" ];
	const char **options_IBM = cast(const(char**))0;
	int numFields_IBM = cast(int)fields_IBM.length;
	int numOptions_IBM = 0;
	/* GOOG */
	string topic_GOOG = "/ticket/GOOG US Equity";
	string[] fields_GOOG = [ "BID", "ASK", "LAST_TRADE" ];
	const (char **)options_GOOG = cast(const(char**))0;
	int numFields_GOOG = cast(int)fields_GOOG.length;
	int numOptions_GOOG = 0;
	 /* MSFT */
	string topic_MSFT = "MSFTT US Equity"; /* Note: Typo! */
	string[] fields_MSFT = [ "LAST_PRICE" ];
	string[]options_MSFT =  ["interval=.5" ];
	int numFields_MSFT = cast(int)fields_MSFT.length;
	int numOptions_MSFT = cast(int)options_MSFT.length;
	/* CUSIP 097023105 */
	string topic_097023105 = "/cusip/ 097023105?fields=LAST_PRICE&interval=5.0";
	const char** fields_097023105 = cast(const char**)0;
	const char** options_097023105 = cast(const char**)0;
	int numFields_097023105 = 0;
	int numOptions_097023105 = 0;
	setbuf(cast(shared(_iobuf*))&stdout, cast(char*)0); /* DO NOT SHOW */
	blpapi_CorrelationId_t subscriptionId_IBM;
	blpapi_CorrelationId_t subscriptionId_GOOG;
	blpapi_CorrelationId_t subscriptionId_MSFT;
	blpapi_CorrelationId_t subscriptionId_097023105;
	memset(&subscriptionId_IBM, '\0', subscriptionId_IBM.size);
	subscriptionId_IBM.valueType = BLPAPI.CORRELATION_TYPE_INT;
	subscriptionId_IBM.value.intValue = cast(blpapi_UInt64_t)10;
	memset(&subscriptionId_GOOG, '\0', subscriptionId_GOOG.size);
	subscriptionId_GOOG.valueType = BLPAPI.CORRELATION_TYPE_INT;
	subscriptionId_GOOG.value.intValue = cast(blpapi_UInt64_t)20;
	memset(&subscriptionId_MSFT, '\0', subscriptionId_MSFT.size);
	subscriptionId_MSFT.valueType = BLPAPI.CORRELATION_TYPE_INT;
	subscriptionId_MSFT.value.intValue = cast(blpapi_UInt64_t)30;
	memset(&subscriptionId_097023105, '\0', subscriptionId_097023105.size);
	subscriptionId_097023105.valueType = BLPAPI.CORRELATION_TYPE_INT;
	subscriptionId_097023105.value.intValue = cast(blpapi_UInt64_t)40;
	sessionOptions = blpapi_SessionOptions_create();
	assert(sessionOptions);
	blpapi_SessionOptions_setServerHost(sessionOptions, "localhost");
	blpapi_SessionOptions_setServerPort(sessionOptions, 8194);
	session = blpapi_Session_create(sessionOptions, &processEvent, cast(blpapi_EventDispatcher*)0, cast(void*)&userData);
	assert(session);
	blpapi_SessionOptions_destroy(sessionOptions);
	if (0 != blpapi_Session_start(session)) {
		stderr.writefln("Failed to start session.");
		blpapi_Session_destroy(session);
		return 1;
	}
	if (0 != blpapi_Session_openService(session,"//blp/mktdata")){
		stderr.writefln("Failed to open service //blp/mktdata.");
		blpapi_Session_destroy(session);
		return 1;
	}
	blpapi_SubscriptionList_t *subscriptions = blpapi_SubscriptionList_create();
	blpapi_SubscriptionList_add(subscriptions, cast(const(char*)) topic_IBM, &subscriptionId_IBM, cast(const(char**))fields_IBM, cast(const(char**))options_IBM, cast(ulong)numFields_IBM, cast(ulong)numOptions_IBM);
	blpapi_SubscriptionList_add(subscriptions, cast(const(char*))topic_GOOG, &subscriptionId_GOOG, cast(const(char**))fields_GOOG, cast(const(char**))options_GOOG, cast(ulong)numFields_GOOG, cast(ulong)numOptions_GOOG);
	blpapi_SubscriptionList_add(subscriptions, cast(const(char*))topic_MSFT, &subscriptionId_MSFT, cast(const(char**))fields_MSFT, cast(const(char**))options_MSFT, cast(ulong)numFields_MSFT, cast(ulong)numOptions_MSFT);
	blpapi_SubscriptionList_add(subscriptions, cast(const(char*))topic_097023105, &subscriptionId_097023105, cast(const(char**))fields_097023105, cast(const(char**))options_097023105, cast(ulong)numFields_097023105, cast(ulong)numOptions_097023105);
	blpapi_Session_subscribe(session, subscriptions, cast(const(blpapi_Identity*))0, cast(const(char*))0, 0);
	//pause(); from threading library
	blpapi_SubscriptionList_destroy(subscriptions);
	blpapi_Session_destroy(session);
	return 0;
}