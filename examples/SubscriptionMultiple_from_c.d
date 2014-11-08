/* SubscriptionMultiple_from_c.d */
import std.stdio;
import std.string;
import blp;

static int streamWriter(const char* data, int length, void *stream)
{
	assert(data);
	assert(stream);
	return fwrite(data, length, 1, (FILE *)stream);
}

struct _UserData {
	const char *d_label;
	FILE *d_stream;
}
_Userdata UserData_t;

static void dumpEvent(const blpapi_Event_t *event, const UserData_t *userData)
{
	blpapi_MessageIterator_t *iter = 0;
	blpapi_Message_t *message = 0;
	assert(event);
	assert(userData);
	assert(userData.d_label);
	assert(userData.d_stream);
	fprintf(userData.d_stream, "handler label=%s\n", userData.d_label);
	fprintf(userData.d_stream, "eventType=%d\n",
	blpapi_Event_eventType(event));
	iter = blpapi_MessageIterator_create(event);
	assert(iter)
	while (0 == blpapi_MessageIterator_next(iter, &message)) {
		blpapi_CorrelationId_t correlationId;
		blpapi_Element_t *messageElements = 0;
		assert(message);
		writefln("messageType=%s", blpapi_Message_typeString(message));
		messageElements=blpapi_Message_elements(message);
		correlationId = blpapi_Message_correlationId(message, 0);
		writefln("correlationId=%d %d %lld", correlationId.valueType, correlationId.classId, correlationId.value.intValue);
		blpapi_Element_print(messageElements, &streamWriter, stdout, 0, 4);
	}
}

static void handleDataEvent(const blpapi_Event_t *event, const blpapi_Session_t *session, const UserData_t *userData)
{
	assert(event);
	assert(userData);
	fprintf(userData.d_stream, "handleDataEventHandler: enter\n");
	dumpEvent(event, userData);
	fprintf(userData.d_stream, "handleDataEventHandler: leave\n");
}

static void handleStatusEvent(const blpapi_Event_t *event, const blpapi_Session_t *session, const UserData_t *userData)
{
	assert(event);
	assert(session);
	assert(userData); /* this application expects userData */
	fprintf(userData.d_stream, "handleStatusEventHandler: enter\n");
	dumpEvent(event, userData);
	fprintf(userData.d_stream, "handleStatusEventHandler: leave\n");
}

static void handleOtherEvent(const blpapi_Event_t *event, const blpapi_Session_t *session, const UserData_t *userData)
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
	UserData_t *userData = (UserData_t *)buffer;
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


int main(string[] argv)
{
	blpapi_SessionOptions_t *sessionOptions = 0;
	blpapi_Session_t *session = 0;
	UserData_t userData = { "myLabel", stdout };
	/* IBM */
	const char *topic_IBM = "IBM US Equity";
	const char *fields_IBM[] = { "LAST_TRADE" };
	const char **options_IBM = 0;
	int numFields_IBM = fields_IBM.size/(*fields_IBM).size;
	int numOptions_IBM = 0;
	/* GOOG */
	const char *topic_GOOG = "/ticket/GOOG US Equity";
	const char *fields_GOOG[] = { "BID", "ASK", "LAST_TRADE" };
	const char **options_GOOG = 0;
	int numFields_GOOG = fields_GOOG.size/(*fields_GOOG).size;
	int numOptions_GOOG = 0;
	 /* MSFT */
	const char *topic_MSFT = "MSFTT US Equity"; /* Note: Typo! */
	const char *fields_MSFT[] = { "LAST_PRICE" };
	const char *options_MSFT[] = { "interval=.5" };
	int numFields_MSFT = sizeof(fields_MSFT)/
	sizeof(*fields_MSFT);
	int numOptions_MSFT = sizeof(options_MSFT)/
	sizeof(*options_MSFT);
	/* CUSIP 097023105 */
	const char *topic_097023105 = "/cusip/ 097023105?fields=LAST_PRICE&interval=5.0";
	const char **fields_097023105 = 0;
	const char **options_097023105 = 0;
	int numFields_097023105 = 0;
	int numOptions_097023105 = 0;
	setbuf(stdout, 0); /* DO NOT SHOW */
	blpapi_CorrelationId_t subscriptionId_IBM;
	blpapi_CorrelationId_t subscriptionId_GOOG;
	blpapi_CorrelationId_t subscriptionId_MSFT;
	blpapi_CorrelationId_t subscriptionId_097023105;
	memset(&subscriptionId_IBM, '\0', sizeof(subscriptionId_IBM));
	subscriptionId_IBM.size = sizeof(subscriptionId_IBM);
	subscriptionId_IBM.valueType = BLPAPI_CORRELATION_TYPE_INT;
	subscriptionId_IBM.value.intValue = (blpapi_UInt64_t)10;
	memset(&subscriptionId_GOOG, '\0', sizeof(subscriptionId_GOOG));
	subscriptionId_GOOG.size = sizeof(subscriptionId_GOOG);
	subscriptionId_GOOG.valueType = BLPAPI_CORRELATION_TYPE_INT;
	subscriptionId_GOOG.value.intValue = (blpapi_UInt64_t)20;
	memset(&subscriptionId_MSFT, '\0', sizeof(subscriptionId_MSFT));
	subscriptionId_MSFT.size = sizeof(subscriptionId_MSFT);
	subscriptionId_MSFT.valueType = BLPAPI_CORRELATION_TYPE_INT;
	subscriptionId_MSFT.value.intValue = (blpapi_UInt64_t)30;
	memset(&subscriptionId_097023105, '\0', sizeof(subscriptionId_097023105));
	subscriptionId_097023105.size = sizeof(subscriptionId_097023105);
	subscriptionId_097023105.valueType = BLPAPI_CORRELATION_TYPE_INT;
	subscriptionId_097023105.value.intValue = (blpapi_UInt64_t)40;
	sessionOptions = blpapi_SessionOptions_create();
	assert(sessionOptions);
	blpapi_SessionOptions_setServerHost(sessionOptions, "localhost");
	blpapi_SessionOptions_setServerPort(sessionOptions, "8194");
	session = blpapi_Session_create(sessionOptions, &processEvent, 0, &userData);
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
	blpapi_SubscriptionList_add(subscriptions, topic_IBM, &subscriptionId_IBM, fields_IBM, options_IBM, numFields_IBM, numOptions_IBM);
	blpapi_SubscriptionList_add(subscriptions, topic_GOOG, &subscriptionId_GOOG, fields_GOOG, options_GOOG, numFields_GOOG, numOptions_GOOG);
	blpapi_SubscriptionList_add(subscriptions, topic_MSFT, &subscriptionId_MSFT, fields_MSFT, options_MSFT, numFields_MSFT, numOptions_MSFT); blpapi_SubscriptionList_add(subscriptions, topic_097023105, &subscriptionId_097023105, fields_097023105, options_097023105, numFields_097023105, numOptions_097023105);
	blpapi_Session_subscribe(session, subscriptions, 0, 0, 0);
	pause();
	blpapi_SubscriptionList_destroy(subscriptions);
	blpapi_Session_destroy(session);
	return 0;
}