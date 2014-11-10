/** *
  Copyright 2012. Bloomberg Finance L.P.
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:  The above
  copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.
 
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
 */

/**
 *
 	BLP API headers and examples ported from C/C++ to D Lang by Laeeth Isharc (2014)
 	Pre-alpha, so don't presume anything works till you have tested and read the code carefully
*/

// I converted all samples to a single source file - more work for the user, but easier for me
// and I do not have time to do them one by one.

/**
*
	Index of examples
	=================
	1.	Asynchronous Event Handling
	2.	Contributions Market Date
	3.	Contributions Page
	4.	Correlation
	5.	Entitlements Verification
	6.	Entitlements Verification Subscription
	7.	Entitlements Verification Token
	8.	Generate Token
	9.	Generate Token Subscription
	10.	Intraday Bar
	11.	Intraday Tick
	12.	Local Mkt Data Subscription
	12.	Mkt data Broadcast Publisher
	13. Mkt data publisher
	14. Page Publisher
	15. Ref Data Example
	16. Ref Data Table Override
	17. Request servic Example
	18. Security Lookup Example
	19. Simple Block Request
	20. Simple Categorized Field Search
	21. Simple Field Info
	22. Simple Field Search
	23. Simple History
	24. Simple Intraday Bar
	25. Simple Intraday Tick
	26. Simple Ref Data
	27. Simple Ref Data Override
	28. Simple Subscription INterval
	29. Subscription Correlation
	30. Subscription with Event Handler
	31. User Mode

*/

// define NOMINMAX
import blpapi;
import blputils;
import std.algorithm;
import std.containers;
import std.conv;
import std.datetime;
import std.file;
import std.stdio;
import std.stdlib;
import std.string;
import std.algorithm;

void memset(void* ptr, ubyte val, long nbytes)
{
	foreach(i;0..nbytes)
		*cast(ubyte*)(cast(ubyte)ptr+i)=val;
}

extern (Windows)
{
	struct example_static
	{
    	string[] hosts;
    	int d_port;
    	string d_service;
    	string d_topic;
    	string d_authOptions;
    }

    void printUsage()
    {
        writefln(   "Market data contribution.\n" 
                    "Usage:\n"
                    "\t[-ip   <ipAddress>]  \tserver name or IP (default: localhost)\n" 
                    "\t[-p    <tcpPort>]    \tserver port (default: 8194)\n" 
                    "\t[-s    <service>]    \tservice name (default: //blp/mpfbapi)\n" 
                    "\t[-t    <topic>]      \tservice name (default: /ticker/AUDEUR Curncy)\n" 
                    "\t[-auth <option>]     \tauthentication option: user|none|app=<app>|dir=<property> (default: user)\n");
    }



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
			writefln("correlationId=%d %d %lld", correlationId.xx.valueType, correlationId.xx.classId, correlationId.value.intValue);
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
						memset(&correlationId, '\0', correlationId.sizeof);
						//correlationId.size = correlationId.sizeof;
						//correlationId.valueType = BLPAPI.CORRELATION_TYPE_INT;
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
						memset(&correlationId, '\0', correlationId.sizeof);
						correlationId.xx.size=correlationId.sizeof;
						correlationId.xx.valueType = BLPAPI.CORRELATION_TYPE_INT;
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

	int winmain(string[] args)
	{
		blpapi_SessionOptions_t* sessionOptions = cast(blpapi_SessionOptions_t*)0;
		//blpapi_Session_t* session = cast(blpapi_Session_t*)0;
		sessionOptions = blpapi_SessionOptions_create();
		assert(sessionOptions);
		blpapi_SessionOptions_setServerHost(sessionOptions, "localhost");
		blpapi_SessionOptions_setServerPort(sessionOptions, 8194);
		auto session = blpapi_Session_create(sessionOptions, &processEvent, cast(blpapi_EventDispatcher*)0, cast(void*)0);
		assert(session);
		blpapi_SessionOptions_destroy(sessionOptions);
		if (blpapi_Session_start(session)!=0) {
			stderr.writefln("Failed to start async session");
			blpapi_Session_destroy(session);
			return 1;
		}
		writefln("press a key to exit");
		wait_key();
		//pause(); from threading header
		blpapi_Session_destroy(session);
		return 0;
	}

} // extern (Windows)

int main(string[] args)
{
	return winmain(args);

}


namespace {
    Name TOKEN_SUCCESS("TokenGenerationSuccess");
    Name TOKEN_FAILURE("TokenGenerationFailure");
    Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
    Name TOKEN("token");
    Name MARKET_DATA("MarketData");
    Name SESSION_TERMINATED("SessionTerminated");

    const char *AUTH_USER        = "AuthenticationType=OS_LOGON";
    const char *AUTH_APP_PREFIX  = "AuthenticationMode=APPLICATION_ONLY;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
    const char *AUTH_DIR_PREFIX  = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";

    const char *AUTH_OPTION_NONE = "none";
    const char *AUTH_OPTION_USER = "user";
    const char *AUTH_OPTION_APP  = "app=";
    const char *AUTH_OPTION_DIR  = "dir=";

    volatile bool g_running = true;

    Mutex g_lock;

    enum AuthorizationStatus {
        WAITING,
        AUTHORIZED,
        FAILED
    };

    std::map<CorrelationId, AuthorizationStatus> g_authorizationStatus;
}

class MyStream {
    std::string d_id;
    Topic d_topic;

public:
    MyStream() : d_id("") {}
    MyStream(std::string const& id) : d_id(id) {}
    void setTopic(Topic const& topic) { d_topic = topic; }
    std::string const& getId() { return d_id; }
    Topic const& getTopic() { return d_topic; }
};

typedef std::list<MyStream*> MyStreams;

class MyEventHandler : public ProviderEventHandler {
public:
    bool processEvent(const Event& event, ProviderSession* session);
};

bool MyEventHandler::processEvent(const Event& event, ProviderSession* session) {
    MessageIterator iter(event);
    while (iter.next()) {
        Message msg = iter.message();
        MutexGuard guard(&g_lock);
        msg.print(std::cout);
        if (event.eventType() == Event::SESSION_STATUS) {
            if (msg.messageType() == SESSION_TERMINATED) {
                g_running = false;
            }
            continue;
        }
        if (g_authorizationStatus.find(msg.correlationId()) != g_authorizationStatus.end()) {
            if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                g_authorizationStatus[msg.correlationId()] = AUTHORIZED;
            }
            else {
                g_authorizationStatus[msg.correlationId()] = FAILED;
            }
        }
    }

    return true;
}

// Contributins Market Data Example
    bool parseCommandLine(string[] argv)
    {
        auto argc=argv.length-1;
        foreach(i,arg;argv[1..$])
        {
            if ((arg=="-ip") && (i<argc))
                d_hosts.push_back(argv[++i]);
            else if ((arg=="-p") && (i<argc))
                d_port = to!int(argv[++i]);
            else if (argv=="-") && (i<argc))
                d_service = arg;
            else if ((arg=="-t") && (i<argc))
                d_topic = argv[++i];
            else if ((arg=="-auth") &&(i<argc))
            {
                ++ i;
                if (argv[i]==AUTH_OPTION_NONE) {
                    d_authOptions.clear();
            }
            else if (arg==AUTH_OPTION_USER)) {
                d_authOptions.assign(AUTH_USER);
            }
            else if (arg[0..AUTH_OPTION_APP.length]==AUTH_OPTION_APP)
            {
                d_authOptions.clear();
                d_authOptions.append(AUTH_APP_PREFIX);
                d_authOptions.append(argv[i] + strlen(AUTH_OPTION_APP));
            }
            else if (arg[0..AUTH_OPTION_DIR.length]==AUTH_OPTION_DIR)
            {
                d_authOptions.clear();
                d_authOptions.append(AUTH_DIR_PREFIX);
                d_authOptions.append(arg[0..AUTH_OPTION_DIR.length]);
            }
            else {
                printUsage();
                return false;
            }
        }

        if (d_hosts.empty()) {
            d_hosts.push_back("localhost");
        }
        return true;
    }

    ContributionsMktdataExample()
        : d_hosts()
        , d_port(8194)
        , d_service("//blp/mpfbapi")
        , d_topic("/ticker/AUDEUR Curncy")
        , d_authOptions(AUTH_USER)
    
    bool authorize(const Service& authService, Identity *providerIdentity, ProviderSession *session, const CorrelationId& cid)
    {
                {
            MutexGuard guard(&g_lock);
            g_authorizationStatus[cid] = WAITING;
        }
        EventQueue tokenEventQueue;
        session->generateToken(CorrelationId(), &tokenEventQueue);
        std::string token;
        Event event = tokenEventQueue.nextEvent();
        if (event.eventType() == Event::TOKEN_STATUS ||
            event.eventType() == Event::REQUEST_STATUS) {
            MessageIterator iter(event);
            while (iter.next()) {
                Message msg = iter.message();
                {
                    MutexGuard guard(&g_lock);
                    msg.print(std::cout);
                }
                if (msg.messageType() == TOKEN_SUCCESS) {
                    token = msg.getElementAsString(TOKEN);
                }
                else if (msg.messageType() == TOKEN_FAILURE) {
                    break;
                }
            }
        }
        if (token.length() == 0) {
            MutexGuard guard(&g_lock);
            std::cout << "Failed to get token" << std::endl;
            return false;
        }

        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set(TOKEN, token.c_str());

        session->sendAuthorizationRequest(
            authRequest,
            providerIdentity,
            cid);

        time_t startTime = time(0);
        const int WAIT_TIME_SECONDS = 10;
        while (true) {
            {
                MutexGuard guard(&g_lock);
                if (WAITING != g_authorizationStatus[cid]) {
                    return AUTHORIZED == g_authorizationStatus[cid];
                }
            }
            time_t endTime = time(0);
            if (endTime - startTime > WAIT_TIME_SECONDS) {
                return false;
            }
            SLEEP(1);
        }
    }

    
    void run(string[] argv)
    {
        if (!parseCommandLine(argc, argv))
            return;

        SessionOptions sessionOptions;
        for (size_t i = 0; i < d_hosts.size(); ++i) {
            sessionOptions.setServerAddress(d_hosts[i].c_str(), d_port, i);
        }
        sessionOptions.setServerPort(d_port);
        sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
        sessionOptions.setAutoRestartOnDisconnection(true);
        sessionOptions.setNumStartAttempts(d_hosts.size());

        MyEventHandler myEventHandler;
        ProviderSession session(sessionOptions, &myEventHandler, 0);

        std::cout << "Connecting to port " << d_port
                  << " on ";
        std::copy(d_hosts.begin(), d_hosts.end(), std::ostream_iterator<std::string>(std::cout, " "));
        std::cout << std::endl;

        if (!session.start()) {
            std::cerr <<"Failed to start session." << std::endl;
            return;
        }

        Identity providerIdentity = session.createIdentity();
        if (!d_authOptions.empty()) {
            bool isAuthorized = false;
            const char* authServiceName = "//blp/apiauth";
            if (session.openService(authServiceName)) {
                Service authService = session.getService(authServiceName);
                isAuthorized = authorize(authService, &providerIdentity,
                        &session, CorrelationId((void *)"auth"));
            }
            if (!isAuthorized) {
                std::cerr << "No authorization" << std::endl;
                return;
            }
        }

        TopicList topicList;
        topicList.add((d_service + d_topic).c_str(),
            CorrelationId(new MyStream(d_topic)));

        session.createTopics(
            &topicList,
            ProviderSession::AUTO_REGISTER_SERVICES,
            providerIdentity);
        // createTopics() is synchronous, topicList will be updated
        // with the results of topic creation (resolution will happen
        // under the covers)

        MyStreams myStreams;

        for (size_t i = 0; i < topicList.size(); ++i) {
            MyStream *stream = reinterpret_cast<MyStream*>(
                topicList.correlationIdAt(i).asPointer());
            int resolutionStatus = topicList.statusAt(i);
            if (resolutionStatus == TopicList::CREATED) {
                Topic topic = session.getTopic(topicList.messageAt(i));
                stream->setTopic(topic);
                myStreams.push_back(stream);
            }
            else {
                std::cout
                    << "Stream '"
                    << stream->getId()
                    << "': topic not resolved, status = "
                    << resolutionStatus
                    << std::endl;
            }
        }

        Service service = session.getService(d_service.c_str());

        // Now we will start publishing
        int value = 1;
        while (myStreams.size() > 0 && g_running) {
            Event event = service.createPublishEvent();
            EventFormatter eventFormatter(event);

            for (MyStreams::iterator iter = myStreams.begin();
                 iter != myStreams.end(); ++iter)
            {
                eventFormatter.appendMessage(MARKET_DATA, (*iter)->getTopic());
                eventFormatter.setElement("BID", 0.5 * ++value);
                eventFormatter.setElement("ASK", value);
            }

            MessageIterator iter(event);
            while (iter.next()) {
                Message msg = iter.message();
                msg.print(std::cout);
            }

            session.publish(event);
            SLEEP(10);
        }

        session.stop();
    }
};

int main(string[] argv)
{
    writefln("ContributionsMktdataExample");
    ContributionsMktdataExample example;
    try {
        realmain(argv);
    } catch (Exception &e) {
        writefln("Library Exception!!! " ~ e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    wait_key()
    return 0;
}

Name TOKEN_SUCCESS("TokenGenerationSuccess");
Name TOKEN_FAILURE("TokenGenerationFailure");
Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
Name TOKEN("token");
Name SESSION_TERMINATED("SessionTerminated");

const string AUTH_USER       = "AuthenticationType=OS_LOGON";
const string AUTH_APP_PREFIX = "AuthenticationMode=APPLICATION_ONLY;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const string AUTH_DIR_PREFIX = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
const char* AUTH_OPTION_NONE      = "none";
const char* AUTH_OPTION_USER      = "user";
const char* AUTH_OPTION_APP       = "app=";
const char* AUTH_OPTION_DIR       = "dir=";

volatile bool g_running = true;

Mutex g_lock;

enum AuthorizationStatus {
    WAITING,
    AUTHORIZED,
    FAILED
};

std::map<CorrelationId, AuthorizationStatus> g_authorizationStatus;
}

class MyStream {
    std::string d_id;
    Topic d_topic;

public:
    MyStream() : d_id("") {};
    MyStream(std::string const& id) : d_id(id) {}
    void setTopic(Topic const& topic) {d_topic = topic;}
    std::string const& getId() {return d_id;}
    Topic const& getTopic() {return d_topic;}
};

typedef std::list<MyStream*> MyStreams;

void printMessages(const Event& event)
{
    MessageIterator iter(event);
    while (iter.next()) {
        Message msg = iter.message();
        MutexGuard guard(&g_lock);
        msg.print(std::cout);
        if (event.eventType() == Event::SESSION_STATUS) {
            if (msg.messageType() == SESSION_TERMINATED) {
                g_running = false;
            }
            continue;
        }
        if (g_authorizationStatus.find(msg.correlationId()) != g_authorizationStatus.end()) {
            if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                g_authorizationStatus[msg.correlationId()] = AUTHORIZED;
            }
            else {
                g_authorizationStatus[msg.correlationId()] = FAILED;
            }
        }
    }
}

class MyEventHandler : public ProviderEventHandler {
public:
    bool processEvent(const Event& event, ProviderSession* session);
};

bool MyEventHandler::processEvent(const Event& event, ProviderSession* session)
{
    printMessages(event);
    return true;
}

class ContributionsPageExample
{
    string[]  d_hosts;
    int                      d_port;
    string              d_service;
    string              d_topic;
    string              d_authOptions;
    int                      d_contributorId;

    void printUsage()
    {
        writefln("Publish on a topic. \n"
             "Usage:\n" 
             "\t[-ip   <ipAddress>]    \tserver name or IP (default: localhost)\n" 
             "\t[-p    <tcpPort>]      \tserver port (default: 8194)\n" 
             "\t[-s    <service>]      \tservice name (default: //blp/mpfbapi)\n" 
             "\t[-t    <topic>]        \ttopic (default: 220/660/1)\n" 
             "\t[-c    <contributorId>]\tcontributor id (default: 8563)\n" 
             "\t[-auth <option>]       \tauthentication option: user|none|app=<app>|dir=<property> (default: user)\n";
    }

    bool parseCommandLine(string[] argv)
    {
        foreach(i;1..argv.length)
        {
            if (!std::strcmp(argv[i], "-ip") && i + 1 < argc)
                d_hosts.push_back(argv[++i]);
            else if (!std::strcmp(argv[i], "-p") &&  i + 1 < argc)
                d_port = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i], "-s") &&  i + 1 < argc)
                d_service = argv[++i];
            else if (!std::strcmp(argv[i], "-t") &&  i + 1 < argc)
                d_topic = argv[++i];
            else if (!std::strcmp(argv[i], "-c") &&  i + 1 < argc)
                d_contributorId = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i], "-auth") && i + 1 < argc) {
                ++i;
                if (!std::strcmp(argv[i], AUTH_OPTION_NONE)) {
                    d_authOptions.clear();
                }
                else if (!std::strcmp(argv[i], AUTH_OPTION_USER)) {
                    d_authOptions.assign(AUTH_USER);
                }
                else if (strncmp(argv[i], AUTH_OPTION_APP,
                                 strlen(AUTH_OPTION_APP)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_APP_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_APP));
                }
                else if (strncmp(argv[i], AUTH_OPTION_DIR,
                                 strlen(AUTH_OPTION_DIR)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_DIR_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_DIR));
                }
                else {
                    printUsage();
                    return false;
                }
            }
            else {
                printUsage();
                return false;
            }
        }
        if (d_hosts.empty()) {
            d_hosts.push_back("localhost");
        }
        return true;
    }

public:

    ContributionsPageExample()
    : d_port(8194)
    , d_service("//blp/mpfbapi")
    , d_authOptions(AUTH_USER)
    , d_topic("220/660/1")
    , d_contributorId(8563)
    {
    }

    void run(string[] argv)
    {
        if (!parseCommandLine(argc, argv)) return;

        SessionOptions sessionOptions;
        for (size_t i = 0; i < d_hosts.size(); ++i) {
            sessionOptions.setServerAddress(d_hosts[i].c_str(), d_port, i);
        }
        sessionOptions.setServerPort(d_port);
        sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
        sessionOptions.setAutoRestartOnDisconnection(true);
        sessionOptions.setNumStartAttempts(d_hosts.size());

        writefln("Connecting to port %s on %s", d_port, std::copy(d_hosts.begin(), d_hosts.end(), std::ostream_iterator<std::string>(std::cout, " "));

        MyEventHandler myEventHandler;
        ProviderSession session(sessionOptions, &myEventHandler, 0);
        if (!session.start()) {
            stderr.writefln("Failed to start session.");
            return;
        }

        Identity providerIdentity = session.createIdentity();
        if (!d_authOptions.empty()) {
            bool isAuthorized = false;
            const char* authServiceName = "//blp/apiauth";
            if (session.openService(authServiceName)) {
                Service authService = session.getService(authServiceName);
                isAuthorized = authorize(authService, &providerIdentity,
                        &session, CorrelationId((void *)"auth"));
            }
            if (!isAuthorized) {
                std::cerr << "No authorization" << std::endl;
                return;
            }
        }

        TopicList topicList;
        topicList.add(((d_service + "/") + d_topic).c_str(),
            CorrelationId(new MyStream(d_topic)));

        session.createTopics(
            &topicList,
            ProviderSession::AUTO_REGISTER_SERVICES,
            providerIdentity);

        MyStreams myStreams;

        foreach(i;0..topicList.size())
        {
            MyStream *stream = reinterpret_cast<MyStream*>(
                topicList.correlationIdAt(i).asPointer());
            int resolutionStatus = topicList.statusAt(i);
            if (resolutionStatus == TopicList::CREATED) {
                Topic topic = session.getTopic(topicList.messageAt(i));
                stream->setTopic(topic);
                myStreams.push_back(stream);
            }
            else {
                writefln("Stream '%s': topic not resolved, status=%s",stream->getId(),resolutionStatus);
            }
        }

        Service service = session.getService(d_service.c_str());

        // Now we will start publishing
        while (g_running) {
            Event event = service.createPublishEvent();
            EventFormatter eventFormatter(event);

            for (MyStreams::iterator iter = myStreams.begin();
                 iter != myStreams.end(); ++iter) {
                eventFormatter.appendMessage("PageData", (*iter)->getTopic());
                eventFormatter.pushElement("rowUpdate");

                eventFormatter.appendElement();
                eventFormatter.setElement("rowNum", 1);
                eventFormatter.pushElement("spanUpdate");

                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 20);
                eventFormatter.setElement("length", 4);
                eventFormatter.setElement("text", "TEST");
                eventFormatter.popElement();

                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 25);
                eventFormatter.setElement("length", 4);
                eventFormatter.setElement("text", "PAGE");
                eventFormatter.popElement();

                char buffer[10];
                time_t rawtime;
                std::time(&rawtime);
                int length = (int)std::strftime(buffer, 10, "%X", std::localtime(&rawtime));
                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 30);
                eventFormatter.setElement("length", length);
                eventFormatter.setElement("text", buffer);
                eventFormatter.setElement("attr", "BLINK");
                eventFormatter.popElement();

                eventFormatter.popElement();
                eventFormatter.popElement();

                eventFormatter.appendElement();
                eventFormatter.setElement("rowNum", 2);
                eventFormatter.pushElement("spanUpdate");
                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 20);
                eventFormatter.setElement("length", 9);
                eventFormatter.setElement("text", "---------");
                eventFormatter.setElement("attr", "UNDERLINE");
                eventFormatter.popElement();
                eventFormatter.popElement();
                eventFormatter.popElement();

                eventFormatter.appendElement();
                eventFormatter.setElement("rowNum", 3);
                eventFormatter.pushElement("spanUpdate");
                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 10);
                eventFormatter.setElement("length", 9);
                eventFormatter.setElement("text", "TEST LINE");
                eventFormatter.popElement();
                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 23);
                eventFormatter.setElement("length", 5);
                eventFormatter.setElement("text", "THREE");
                eventFormatter.popElement();
                eventFormatter.popElement();
                eventFormatter.popElement();
                eventFormatter.popElement();

                eventFormatter.setElement("contributorId", d_contributorId);
                eventFormatter.setElement("productCode", 1);
                eventFormatter.setElement("pageNumber", 1);
            }

            printMessages(event);

            session.publish(event);
            SLEEP(10);
        }

        session.stop();
    }
};

int main(string[] argv)
{
    writefln("ContributionsPageExample");
    ContributionsPageExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s",e.description());
    }
    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

const Name RESPONSE_ERROR("responseError");
const Name SECURITY_DATA("securityData");
const Name SECURITY("security");
const Name EID_DATA("eidData");
const Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
const Name AUTHORIZATION_FAILURE("AuthorizationFailure");

const char* REFRENCEDATA_REQUEST = "ReferenceDataRequest";
const char* APIAUTH_SVC          = "//blp/apiauth";
const char* REFDATA_SVC          = "//blp/refdata";

void printEvent(const Event &event)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        CorrelationId correlationId = msg.correlationId();
        if (correlationId.asInteger() != 0) {
            std::cout << "Correlator: " << correlationId.asInteger()
                << std::endl;
        }
        msg.print(std::cout);
        std::cout << std::endl;
    }
}

} // anonymous namespace

class SessionEventHandler: public  EventHandler
{
std::vector<Identity> &d_identities;
std::vector<int> &d_uuids;

void printFailedEntitlements(std::vector<int> &failedEntitlements,
    int numFailedEntitlements)
{
    for (int i = 0; i < numFailedEntitlements; ++i) {
        std::cout << failedEntitlements[i] << " ";
    }
    std::cout << std::endl;
}

void distributeMessage(Message &msg)
{
    Service service = msg.service();

    std::vector<int> failedEntitlements;
    Element securities = msg.getElement(SECURITY_DATA);
    int numSecurities = securities.numValues();

    std::cout << "Processing " << numSecurities << " securities:"
        << std::endl;
    for (int i = 0; i < numSecurities; ++i) {
        Element security     = securities.getValueAsElement(i);
        std::string ticker   = security.getElementAsString(SECURITY);
        Element entitlements;
        if (security.hasElement(EID_DATA)) {
            entitlements = security.getElement(EID_DATA);
        }

        int numUsers = d_identities.size();
        if (entitlements.isValid() && entitlements.numValues() > 0) {
            // Entitlements are required to access this data
            failedEntitlements.resize(entitlements.numValues());
            for (int j = 0; j < numUsers; ++j) {
                std::memset(&failedEntitlements[0], 0,
                    sizeof(int) * failedEntitlements.size());
                int numFailures = failedEntitlements.size();
                if (d_identities[j].hasEntitlements(service, entitlements,
                    &failedEntitlements[0], &numFailures)) {
                        std::cout << "User: " << d_uuids[j] <<
                            " is entitled to get data for: " << ticker
                            << std::endl;
                        // Now Distribute message to the user.
                }
                else {
                    std::cout << "User: " << d_uuids[j] <<
                        " is NOT entitled to get data for: "
                        << ticker << " - Failed eids: " << std::endl;
                    printFailedEntitlements(failedEntitlements,
                                            numFailures);
                }
            }
        }
        else {
            // No Entitlements are required to access this data.
            for (int j = 0; j < numUsers; ++j) {
                std::cout <<"User: " << d_uuids[j] <<
                    " is entitled to get data for: "
                    << ticker << std::endl;
                // Now Distribute message to the user.
            }
        }
    }
}

void processResponseEvent(const Event &event)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        if (msg.hasElement(RESPONSE_ERROR)) {
            msg.print(std::cout) << std::endl;
            continue;
        }
        // We have a valid response. Distribute it to all the users.
        distributeMessage(msg);
    }
}

public :

SessionEventHandler(std::vector<Identity> &identities,
    std::vector<int> &uuids) :
d_identities(identities), d_uuids(uuids) {
}

bool processEvent(const Event &event, Session *session)
{
    switch(event.eventType()) {
    case Event::SESSION_STATUS:
    case Event::SERVICE_STATUS:
    case Event::REQUEST_STATUS:
    case Event::AUTHORIZATION_STATUS:
        printEvent(event);
        break;

    case Event::RESPONSE:
    case Event::PARTIAL_RESPONSE:
        try {
            processResponseEvent(event);
        }
        catch (Exception &e) {
            std::cerr << "Library Exception!!! " << e.description()
                << std::endl;
            return true;
        } catch (...) {
            std::cerr << "Unknown Exception!!!" << std::endl;
            return true;
        }
        break;
     }
    return true;
}
};

class EntitlementsVerificationExample {

std::string               d_host;
int                       d_port;
std::vector<std::string>  d_securities;
std::vector<int>          d_uuids;
std::vector<Identity>     d_identities;
std::vector<std::string>  d_programAddresses;

void printUsage()
{
    writefln( "Usage:" << '\n'
         "    Entitlements verification example\n" 
         "        [-s     <security   = IBM US Equity>]\n" 
         "        [-c     <credential uuid:ipAddress\n" 
        " eg:12345:10.20.30.40>]\n"
        "        [-ip    <ipAddress  = localhost>]\n"
        "        [-p     <tcpPort    = 8194>]\n"
        "Note:\n" 
        "Multiple securities and credentials can be\n" 
        " specified." << std::endl;);
}

void openServices(Session *session)
{
    if (!session.openService(APIAUTH_SVC)) {
        writefln("Failed to open service: %s",APIAUTH_SVC);
        throw new Exception("Failed to open service: "~APIAUTH_SVC)
    }

    if (!session.openService(REFDATA_SVC)) {
        writefln("Failed to open service: %s" << REFDATA_SVC);
        throw new Exception("Failed to open service: "~REFDATA_SVC);
    }
}

bool authorizeUsers(EventQueue *authQueue, Session *session)
{
    Service authService = session.getService(APIAUTH_SVC);
    bool is_any_user_authorized = false;

    // Authorize each of the users
    d_identities.reserve(d_uuids.size());
    foreach(i;0..d_uuids.size())
    {
        d_identities.push_back(session.createIdentity());
        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set("uuid", d_uuids[i]);
        authRequest.set("ipAddress", d_programAddresses[i].c_str());

        CorrelationId correlator(d_uuids[i]);
        session.sendAuthorizationRequest(authRequest, &d_identities[i], correlator, authQueue);

        Event event = authQueue.nextEvent();

        if (event.eventType() == Event::RESPONSE ||
            event.eventType() == Event::PARTIAL_RESPONSE ||
            event.eventType() == Event::REQUEST_STATUS ||
            event.eventType() == Event::AUTHORIZATION_STATUS) {

            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();

                if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                    writefln("%s authorization success",msg.correlationId().asInteger());
                    is_any_user_authorized = true;
                }
                else if (msg.messageType() == AUTHORIZATION_FAILURE) {
                    writefln("%s authorization failed", msg.correlationId().asInteger());
                    writefln("%s",msg);
                }
                else {
                    writefln("%s",msg);
                }
            }
        }
    }
    return is_any_user_authorized;
}

void sendRefDataRequest(Session *session)
{
    Service service = session.getService(REFDATA_SVC);
    Request request = service.createRequest(REFRENCEDATA_REQUEST);

    // Add securities.
    Element securities = request.getElement("securities");
    for (size_t i = 0; i < d_securities.size(); ++i) {
        securities.appendValue(d_securities[i].c_str());
    }

    // Add fields
    Element fields = request.getElement("fields");
    fields.appendValue("PX_LAST");
    fields.appendValue("DS002");

    request.set("returnEids", true);

    // Send the request using the server's credentials
    writefln("Sending RefDataRequest using server credentials...");
    session.sendRequest(request);
}



bool parseCommandLine(string[] argv)
{
    foreach(i;1..argv.length) {
        if (!argv[i]=="-s") ) {
            if (++i >= argv.length) return false;
            d_securities.push_back(argv[i]);
        }
        else if (!argv[i]=="-c")) {
            if (++i >= argv.length) return false;

            string credential = argv[i];
            size_t idx = credential.find_first_of(':');
            if (idx == std::string::npos) return false;
            d_uuids.push_back(atoi(credential.substr(0,idx).c_str()));
            d_programAddresses.push_back(credential.substr(idx+1));
            continue;
        }
        else if (!argv[i]=="-ip")) {
            if (++i >= argc) return false;
            d_host = argv[i];
            continue;
        }
        else if (!argv[i]=="-p")) {
            if (++i >= argc) return false;
            d_port = std::atoi(argv[i]);
            continue;
        }
        else return false;
    }

    if (d_uuids.size() <= 0) {
        writefln("No uuids were specified");
        return false;
    }

    if (d_uuids.size() != d_programAddresses.size()) {
        writefln("Invalid number of program addresses provided");
        return false;
    }

    if (d_securities.size() <= 0) {
        d_securities.push_back("IBM US Equity");
    }

    return true;
}



public:

EntitlementsVerificationExample()
: d_host("localhost")
, d_port(8194)
{
}

void run(string[] argv) {
    if (!parseCommandLine(argc, argv)) {
        printUsage();
        return;
    }

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s",d_host,d_port);

    SessionEventHandler eventHandler(d_identities, d_uuids);
    Session session(sessionOptions, &eventHandler);

    if (!session.start()) {
        writefln("Failed to start session. Exiting...");
        throw new Exception("Failed to start session");
    }

    openServices(&session);

    EventQueue authQueue;

    // Authorize all the users that are interested in receiving data
    if (authorizeUsers(&authQueue, &session)) {
        // Make the various requests that we need to make
        sendRefDataRequest(&session);
    }

    // wait for enter key to exit application
    char dummy[2];
    std::cin.getline(dummy,2);

    {
        // Check if there were any authorization events received on the
        // 'authQueue'

        Event event;
        while (0 == authQueue.tryNextEvent(&event)) {
            printEvent(event);
        }
    }

    session.stop();
    writefln("Exiting...");
}

int main(string[] argv)
{
    writefln("Entitlements Verification Example");
    
    EntitlementsVerificationExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        writefln("Library Exception!!! %s",e.description());
    } catch (...) {
        writefln("Unknown Exception!!!");
    }

    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}


const Name EID("EID");
const Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
const Name AUTHORIZATION_FAILURE("AuthorizationFailure");

const char* APIAUTH_SVC             = "//blp/apiauth";
const char* MKTDATA_SVC             = "//blp/mktdata";

void printEvent(const Event &event)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        CorrelationId correlationId = msg.correlationId();
        if (correlationId.asInteger() != 0) {
            writefln("Correlator: %s",correlationId.asInteger());
        }
        msg.print(std.cout);
    }
}

} // anonymous namespace

class SessionEventHandler: public  EventHandler
{
std.vector<Identity>    &d_identities;
std.vector<int>         &d_uuids;
std.vector<std.string> &d_securities;
Name                      d_fieldName;

void processSubscriptionDataEvent(const Event &event)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        Service service = msg.service();

        int index = (int)msg.correlationId().asInteger();
        string &topic = d_securities[index];
        if (!msg.hasElement(d_fieldName)) {
            continue;
        }
        writefln("\t%s",topic);
        Element field = msg.getElement(d_fieldName);
        if (!field.isValid()) {
            continue;
        }
        bool needsEntitlement = msg.hasElement(EID);
        foreach(j;0..d_identities.size())
        {
            Identity* handle = &d_identities[j];
            if (!needsEntitlement || handle.hasEntitlements(service, msg.getElement(EID), 0, 0))
            {
                writefln("User: %s is entitled for %s",d_uuids[j], field);
            }
            else {
                writefln("User: %s is NOT entitled for %s",d_uuids[j],d_fieldName);
            }
        }
    }
}

public :
SessionEventHandler(std.vector<Identity>      &identities,
                    std.vector<int>           &uuids,
                    std.vector<std.string>   &securities,
                    const std.string          &field)
    : d_identities(identities)
    , d_uuids(uuids)
    , d_securities(securities)
    , d_fieldName(field.c_str())
{
}

bool processEvent(const Event &event, Session *session)
{
    switch(event.eventType()) {
    case Event.SESSION_STATUS, Event.SERVICE_STATUS, Event.REQUEST_STATUS, Event.AUTHORIZATION_STATUS:
        printEvent(event);
        break;
    case Event.SUBSCRIPTION_DATA:
        try {
            processSubscriptionDataEvent(event);
        } catch (Exception &e) {
            stderr.writefln( "Library Exception!!! %s",e.description());
        } catch (...) {
            stderr.writefln("Unknown Exception!!!");
        }
        break;
    }
    return true;
}
};

class EntitlementsVerificationSubscriptionExample {

string d_host;
int d_port;
string  d_field;
string[]  d_securities;
int[] d_uuids;
Identity[] d_identities;
string[]  d_programAddresses;

SubscriptionList d_subscriptions;

void printUsage()
{
    writefln("Usage:\n"
         "    Entitlements verification example\n"
         "        [-s     <security   = IBM US Equity>]\n"
         "        [-f     <field  = BEST_BID1>]\n"
         "        [-c     <credential uuid:ipAddress\n" 
        " eg:12345:10.20.30.40>]\n"
         "        [-ip    <ipAddress  = localhost>]\n"
         "        [-p     <tcpPort    = 8194>]\n"
         "Note:\n"
        "Multiple securities and credentials can be\n" 
        " specified. Only one field can be specified.");
}

void openServices(Session *session)
{
    if (!session.openService(APIAUTH_SVC)) {
        writefln("Failed to open service: %s" ,APIAUTH_SVC);
        throw new Exception("Failed to open service: %s" ~ APIAUTH_SVC)
    }

    if (!session.openService(MKTDATA_SVC)) {
        writefln("Failed to open service: %s",  MKTDATA_SVC);
        throw new Exception("Failed to open service: %s" ~ MKTDATA_SVC)
    }
}

bool authorizeUsers(EventQueue *authQueue, Session *session)
{
    Service authService = session.getService(APIAUTH_SVC);
    bool is_any_user_authorized = false;

    // Authorize each of the users
    d_identities.reserve(d_uuids.size());
    foreach(i; 0.. d_uuids.size())
    {
        d_identities.push_back(session.createIdentity());
        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set("uuid", d_uuids[i]);
        authRequest.set("ipAddress", d_programAddresses[i].c_str());
        CorrelationId correlator(d_uuids[i]);
        session.sendAuthorizationRequest(authRequest, &d_identities[i], correlator, authQueue);
        Event event = authQueue.nextEvent();

        if (event.eventType() == Event.RESPONSE || event.eventType() == Event.PARTIAL_RESPONSE || event.eventType() == Event.REQUEST_STATUS ||
            event.eventType() == Event.AUTHORIZATION_STATUS) {

            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();

                if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                    writefln("%s authorization success",msg.correlationId().asInteger());
                    is_any_user_authorized = true;
                }
                else if (msg.messageType() == AUTHORIZATION_FAILURE) {
                    writefln("%s authorization failed",msg.correlationId().asInteger());
                    writefln("%s",msg);
                }
                else {
                    writefln("%s",msg);
                }
            }
        }
    }
    return is_any_user_authorized;
}

bool parseCommandLine(string[] argv)
{
    foreach(i;1..argv.length)
    {
        if (!std.strcmp(argv[i],"-s") && i + 1 < argc) {
            d_securities.push_back(argv[++i]);
            continue;
        }

        if (!std.strcmp(argv[i],"-f") && i + 1 < argc) {
            d_field = std.string(argv[++i]);
            continue;
        }

        if (!std.strcmp(argv[i],"-c") && i + 1 < argc) {
            std.string credential = argv[++i];
            size_t idx = credential.find_first_of(':');
            if (idx == std.string.npos) {
                return false;
            }
            d_uuids.push_back(atoi(credential.substr(0,idx).c_str()));
            d_programAddresses.push_back(credential.substr(idx+1));
            continue;
        }
        if (!std.strcmp(argv[i],"-ip") && i + 1 < argc) {
            d_host = argv[++i];
            continue;
        }
        if (!std.strcmp(argv[i],"-p") &&  i + 1 < argc) {
            d_port = std.atoi(argv[++i]);
            continue;
        }
        return false;
    }

    if (d_uuids.size() <= 0) {
        writefln("No uuids were specified");
        return false;
    }

    if (d_uuids.size() != d_programAddresses.size()) {
        writefln("Invalid number of program addresses provided");
        return false;
    }

    if (d_securities.size() <= 0) {
        d_securities.push_back("MSFT US Equity");
    }

    foreach(i; 0.. d_securities.size()) {
        d_subscriptions.add(d_securities[i].c_str(), d_field.c_str(), "", CorrelationId(i));
    }
    return true;
}



public:

EntitlementsVerificationSubscriptionExample()
: d_host("localhost")
, d_port(8194)
, d_field("BEST_BID1")
{
}

void run(string[] argv) {
    if (!parseCommandLine(argv)) {
        printUsage();
        return;
    }

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s",d_host ,d_port);

    SessionEventHandler eventHandler(d_identities,
                                     d_uuids,
                                     d_securities,
                                     d_field);
    Session session(sessionOptions, &eventHandler);

    if (!session.start()) {
        stderr.writefln("Failed to start session. Exiting...");
        throw new Exception("Failed to start session");
    }

    openServices(&session);

    EventQueue authQueue;

    // Authorize all the users that are interested in receiving data
    if (authorizeUsers(&authQueue, &session)) {
        // Make the various requests that we need to make
        session.subscribe(d_subscriptions);
    } else {
        stderr.writefln("Unable to authorize users, Press Enter to Exit");
    }

    // wait for enter key to exit application
    char dummy[2];
    std.cin.getline(dummy,2);

    {
        // Check if there were any authorization events received on the
        // 'authQueue'

        Event event;
        while (0 == authQueue.tryNextEvent(&event)) {
            printEvent(event);
        }
    }

    session.stop();
    writefln("Exiting...");
}

};

int main(int argc, char **argv)
{
    writefln("Entitlements Verification Subscription Example");
    
    EntitlementsVerificationSubscriptionExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("main: Library Exception!!! %s", e.description());
    } catch (...) {
        stderr.writefln("main: Unknown Exception!!!");
    }

    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std.cin.getline(dummy, 2);
    return 0;
}

// EntitlementsVerificationSubscriptionTokenExample.cpp
//
// This program demonstrates a server mode application that authorizes its
// users with tokens returned by a generateToken request. For the purposes
// of this demonstration, the "GetAuthorizationToken" program can be used
// to generate a token and display it on the console. For ease of demonstration
// this application takes one or more 'tokens' on the command line. But in a real
// server mode application the 'token' would be received from the client
// applications using some IPC mechanism.
//
// Workflow:
// * connect to server
// * open services
// * send authorization request for each 'token' which represents a user.
// * subscribe to all specified 'securities'
// * for each subscription data message, check which users are entitled to
//   receive that data before distributing that message to the user.
//
// Command line arguments:
// -ip <serverHostNameOrIp>
// -p  <serverPort>
// -t  <token>
// -s  <security>
// -f  <field>
// Multiple securities and tokens can be specified but the application
// is limited to one field.
//



const Name EID("EID");
const Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
const Name AUTHORIZATION_FAILURE("AuthorizationFailure");

const char* APIAUTH_SVC             = "//blp/apiauth";
const char* MKTDATA_SVC             = "//blp/mktdata";

void printEvent(const Event &event)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        CorrelationId correlationId = msg.correlationId();
        if (correlationId.asInteger() != 0) {
            std::cout << "Correlator: " << correlationId.asInteger()
                << std::endl;
        }
        msg.print(std::cout);
        std::cout << std::endl;
    }
}

} // anonymous namespace

class SessionEventHandler: public  EventHandler
{
Identity[]    &d_identities;
string[] &d_tokens;
string[] &d_securities;
Name                      d_fieldName;

void processSubscriptionDataEvent(const Event &event)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        Service service = msg.service();

        int index = (int)msg.correlationId().asInteger();
        std::string &topic = d_securities[index];
        if (!msg.hasElement(d_fieldName)) {
            continue;
        }
        std::cout << "\t" << topic << std::endl;
        Element field = msg.getElement(d_fieldName);
        if (!field.isValid()) {
            continue;
        }
        bool needsEntitlement = msg.hasElement(EID);
        for (size_t i = 0; i < d_identities.size(); ++i) {
            Identity *handle = &d_identities[i];
            if (!needsEntitlement ||
                handle.hasEntitlements(service,
                    msg.getElement(EID), 0, 0))
            {
                    std::cout << "User #" << (i+1) << " is entitled"
                        << " for " << field << std::endl;
            }
            else {
                std::cout << "User #" << (i+1) << " is NOT entitled"
                    << " for " << d_fieldName << std::endl;
            }
        }
    }
}

public :
SessionEventHandler(std::vector<Identity>      &identities,
                    std::vector<std::string>   &tokens,
                    std::vector<std::string>   &securities,
                    const std::string          &field)
    : d_identities(identities)
    , d_tokens(tokens)
    , d_securities(securities)
    , d_fieldName(field.c_str())
{
}

bool processEvent(const Event &event, Session *session)
{
    switch(event.eventType()) {
    case Event::SESSION_STATUS:
    case Event::SERVICE_STATUS:
    case Event::REQUEST_STATUS:
    case Event::AUTHORIZATION_STATUS:
        printEvent(event);
        break;

    case Event::SUBSCRIPTION_DATA:
        try {
            processSubscriptionDataEvent(event);
        } catch (Exception &e) {
            std::cerr << "Library Exception!!! " << e.description()
                << std::endl;
        } catch (...) {
            std::cerr << "Unknown Exception!!!" << std::endl;
        }
        break;
    }
    return true;
}
};

class EntitlementsVerificationSubscriptionTokenExample {

string d_host;
int d_port;
string d_field;
string[] d_securities;
Identity[]  d_identities;
string[] d_tokens;
SubscriptionList          d_subscriptions;

void printUsage()
{
    writefln("Usage:\n"
         "    Entitlements verification example\n" 
         "        [-s     <security   = MSFT US Equity>]\n" 
         "        [-f     <field  = BEST_BID1>]\n" 
         "        [-t     <token string>]\n"
         " ie. token value returned in generateToken response\n" 
         "        [-ip    <ipAddress  = localhost>]\n" 
         "        [-p     <tcpPort    = 8194>]\n" 
         "Note:\n" 
         "Multiple securities and tokens can be specified.\n"
         " Only one field can be specified.");
}

void openServices(Session *session)
{
    if (!session.openService(APIAUTH_SVC)) {
        writefln("Failed to open service: %s", APIAUTH_SVC);
        throw new Exception("Failed to open service: "~APIAUTH_SVC);
    }

    if (!session.openService(MKTDATA_SVC)) {
        writefln("Failed to open service: %s",MKTDATA_SVC);
        throw new Exception("Failed to open service" ~MKTDATA_SVC);
    }
}

bool authorizeUsers(EventQueue *authQueue, Session *session)
{
    Service authService = session.getService(APIAUTH_SVC);
    bool is_any_user_authorized = false;

    // Authorize each of the users
    d_identities.reserve(d_tokens.size());
    for (size_t i = 0; i < d_tokens.size(); ++i) {
        d_identities.push_back(session.createIdentity());
        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set("token", d_tokens[i].c_str());

        CorrelationId correlator(i);
        session.sendAuthorizationRequest(authRequest,
                                          &d_identities[i],
                                          correlator,
                                          authQueue);

        Event event = authQueue.nextEvent();

        if (event.eventType() == Event::RESPONSE ||
            event.eventType() == Event::PARTIAL_RESPONSE ||
            event.eventType() == Event::REQUEST_STATUS ||
            event.eventType() == Event::AUTHORIZATION_STATUS) {

            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();

                if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                    writefln("User # %s authorization success",msg.correlationId().asInteger() + 1);
                    is_any_user_authorized = true;
                }
                else if (msg.messageType() == AUTHORIZATION_FAILURE) {
                    writefln("User #%s authorization failed",msg.correlationId().asInteger() + 1);
                }
                else {
                    writefln(msg);
                }
            }
        }
    }
    return is_any_user_authorized;
}

bool parseCommandLine(string[] argv)
{
    int tokenCount = 0;
    foreach(i; 1..argv.length) {
        if ((!(argv[i]=="-s") && (i + 1 < argv.length)) {
            d_securities.push_back(argv[++i]);
            continue;
        }

        if ((!(argv[i]=="-f") && (i + 1 < argv.length)) {
            d_field = std::string(argv[++i]);
            continue;
        }

        if ((!argv[i]=="-t") && (i + 1 < argv.length)) {
            d_tokens.push_back(argv[++i]);
            ++tokenCount;
            writefln("User #%s token: %s", tokenCount, argv[i]);
            continue;
        }
        if ((!argv[i]=="-ip") && (i + 1 < argv.length)) {
            d_host = argv[++i];
            continue;
        }
        if ((!argv[i]=="-p") &&  (i + 1 < argv.length)) {
            d_port = std::atoi(argv[++i]);
            continue;
        }
        return false;
    }

    if (!d_tokens.size()) {
        writefln("No tokens were specified");
        return false;
    }

    if (!d_securities.size()) {
        d_securities.push_back("MSFT US Equity");
    }

    foreach(i; 0.. d_securities.size())
    {
        d_subscriptions.add(d_securities[i].c_str(), d_field.c_str(), "", CorrelationId(i));
    }
    return true;
}



public:

EntitlementsVerificationSubscriptionTokenExample()
: d_host("localhost")
, d_port(8194)
, d_field("BEST_BID1")
{
}

void run(string[] argv) {
    if (!parseCommandLine(argc, argv)) {
        printUsage();
        return;
    }

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    std::cout << "Connecting to " + d_host + ":" << d_port << std::endl;

    SessionEventHandler eventHandler(d_identities,
                                     d_tokens,
                                     d_securities,
                                     d_field);
    Session session(sessionOptions, &eventHandler);

    if (!session.start()) {
        stderr.writefln("Failed to start session. Exiting...");
        throw new Exception("Failed to start session");
    }

    openServices(&session);

    EventQueue authQueue;

    // Authorize all the users that are interested in receiving data
    if (authorizeUsers(&authQueue, &session)) {
        // Make the various requests that we need to make
        session.subscribe(d_subscriptions);
    } else {
        stderr.writefln("Unable to authorize users, Press Enter to Exit");
    }

    // wait for enter key to exit application
    char dummy[2];
    std::cin.getline(dummy,2);

    {
        // Check if there were any authorization events received on the
        // 'authQueue'

        Event event;
        while (0 == authQueue.tryNextEvent(&event)) {
            printEvent(event);
        }
    }

    session.stop();
    writefln("Exiting...\n");
}

int main(int argc, string[] argv)
{
    writefln("Entitlements Verification Subscription Token Example");

    EntitlementsVerificationSubscriptionTokenExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("main: Library Exception!!! %s", e.description());
    } catch (...) {
        stderr.writefln("main: Unknown Exception!!! %s",std::endl);
    }

    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

// EntitlementsVerificationTokenExample.cpp
//
// This program demonstrates a server mode application that authorizes its
// users with tokens returned by a generateToken request. For the purposes
// of this demonstration, the "GetAuthorizationToken" program can be used
// to generate a token and display it on the console. For ease of demonstration
// this application takes one or more 'tokens' on the command line. But in a real
// server mode application the 'token' would be received from the client
// applications using some IPC mechanism.
//
// Workflow:
// * connect to server
// * open services
// * send authorization request for each 'token' which represents a user.
// * send "ReferenceDataRequest" for all specified 'securities'
// * for each response message, check which users are entitled to receive
//   that message before distributing that message to the user.
//
// Command line arguments:
// -ip <serverHostNameOrIp>
// -p  <serverPort>
// -t  <token>
// -s  <security>
// Multiple securities and tokens can be specified.
//

const Name RESPONSE_ERROR("responseError");
const Name SECURITY_DATA("securityData");
const Name SECURITY("security");
const Name EID_DATA("eidData");
const Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
const Name AUTHORIZATION_FAILURE("AuthorizationFailure");

const char* REFRENCEDATA_REQUEST = "ReferenceDataRequest";
const char* APIAUTH_SVC          = "//blp/apiauth";
const char* REFDATA_SVC          = "//blp/refdata";

void printEvent(const Event &event)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        CorrelationId correlationId = msg.correlationId();
        if (correlationId.asInteger() != 0) {
            writefln("Correlator: %s",correlationId.asInteger());
        }
        msg.print(std::cout);
    }
}

} // anonymous namespace

class SessionEventHandler: public  EventHandler
{
std::vector<Identity>   &d_identities;
std::vector<std::string>     &d_tokens;

void printFailedEntitlements(std::vector<int> &failedEntitlements,
    int numFailedEntitlements)
{
    for (int i = 0; i < numFailedEntitlements; ++i) {
        std::cout << failedEntitlements[i] << " ";
    }
    std::cout << std::endl;
}

void distributeMessage(Message &msg)
{
    Service service = msg.service();

    int[] failedEntitlements;
    Element securities = msg.getElement(SECURITY_DATA);
    int numSecurities = securities.numValues();

    writefln("Processing %s securities:",numSecurities);
    foreach(i;0.. numSecurities)
    {
        Element security     = securities.getValueAsElement(i);
        string ticker   = security.getElementAsString(SECURITY);
        Element entitlements;
        if (security.hasElement(EID_DATA)) {
            entitlements = security.getElement(EID_DATA);
        }

        int numUsers = d_identities.size();
        if (entitlements.isValid() && entitlements.numValues() > 0) {
            // Entitlements are required to access this data
            failedEntitlements.resize(entitlements.numValues());
            foreach(j;0.. numUsers) {
                std::memset(&failedEntitlements[0], 0,
                    sizeof(int) * failedEntitlements.size());
                int numFailures = failedEntitlements.size();
                if (d_identities[j].hasEntitlements(service, entitlements, &failedEntitlements[0], &numFailures))
                {
                    writefln("User # %s is entitled to get data for: ",to!string(j+1),ticker);
                }
                else {
                    writefln("User #%s is NOT entitled to get data for: %s  - Failed eids: ",to!string(j+1),ticker);
                    printFailedEntitlements(failedEntitlements, numFailures);
                }
            }
        }
        else {
            // No Entitlements are required to access this data.
            for (int j = 0; j < numUsers; ++j) {
                std::cout << "User: " << d_tokens[j] <<
                    " is entitled to get data for: "
                    << ticker << std::endl;
                // Now Distribute message to the user.
            }
        }
    }
}

void processResponseEvent(const Event &event)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        if (msg.hasElement(RESPONSE_ERROR)) {
            msg.print(std::cout) << std::endl;
            continue;
        }
        // We have a valid response. Distribute it to all the users.
        distributeMessage(msg);
    }
}

public :

SessionEventHandler(std::vector<Identity> &identities,
                    std::vector<std::string> &tokens) :
d_identities(identities), d_tokens(tokens) {
}

bool processEvent(const Event &event, Session *session)
{
    switch(event.eventType()) {
    case Event::SESSION_STATUS:
    case Event::SERVICE_STATUS:
    case Event::REQUEST_STATUS:
    case Event::AUTHORIZATION_STATUS:
        printEvent(event);
        break;

    case Event::RESPONSE:
    case Event::PARTIAL_RESPONSE:
        try {
            processResponseEvent(event);
        }
        catch (Exception &e) {
            std::cerr << "Library Exception!!! " << e.description()
                << std::endl;
            return true;
        } catch (...) {
            std::cerr << "Unknown Exception!!!" << std::endl;
            return true;
        }
        break;
     }
    return true;
}
};


string d_host;
int d_port;
string[] d_securities;
string[] d_identities;
string[] d_tokens;

void printUsage()
{
    writefln(
         "Usage:" << '\n'
         "    Entitlements verification token example" << '\n'
         "        [-s     <security   = MSFT US Equity>]" << '\n'
         "        [-t     <token string>]"
         " ie. token value returned in generateToken response" << '\n'
         "        [-ip    <ipAddress  = localhost>]" << '\n'
         "        [-p     <tcpPort    = 8194>]" << '\n'
         "Note:" << '\n'
         "Multiple securities and tokens can be specified.");
}         

void openServices(Session *session)
{
    if (!session->openService(APIAUTH_SVC)) {
        stderr.writefln( "Failed to open service: %s" ,APIAUTH_SVC);
        throw new Exception("failed to open service");
    }

    if (!session->openService(REFDATA_SVC)) {
        stderr.writefln("Failed to open service: %s",REFDATA_SVC);
        throw new Exception("failed to open service");
    }
}

bool authorizeUsers(EventQueue *authQueue, Session *session)
{
    Service authService = session->getService(APIAUTH_SVC);
    bool is_any_user_authorized = false;

    // Authorize each of the users
    d_identities.reserve(d_tokens.size());
    foreach(i;0.. d_tokens.size())
    {
        d_identities.push_back(session->createIdentity());
        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set("token", d_tokens[i].c_str());

        CorrelationId correlator(i);
        session->sendAuthorizationRequest(authRequest, &d_identities[i], correlator, authQueue);
        Event event = authQueue->nextEvent();

        if (event.eventType() == Event::RESPONSE ||
            event.eventType() == Event::PARTIAL_RESPONSE ||
            event.eventType() == Event::REQUEST_STATUS ||
            event.eventType() == Event::AUTHORIZATION_STATUS) {

            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();

                if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                    writefln("User #%s authorization success",msg.correlationId().asInteger() + 1);
                    is_any_user_authorized = true;
                }
                else if (msg.messageType() == AUTHORIZATION_FAILURE) {
                    writefln("User #%s authorization failed",msg.correlationId().asInteger() + 1);
                    writefln(msg);
                }
                else {
                    writefln(msg);
                }
            }
        }
    }
    return is_any_user_authorized;
}

void sendRefDataRequest(Session *session)
{
    Service service = session->getService(REFDATA_SVC);
    Request request = service.createRequest(REFRENCEDATA_REQUEST);

    // Add securities.
    Element securities = request.getElement("securities");
    foreach(i;0..d_securities.size()) {
        securities.appendValue(d_securities[i].c_str());
    }

    // Add fields
    Element fields = request.getElement("fields");
    fields.appendValue("PX_LAST");
    fields.appendValue("DS002");

    request.set("returnEids", true);

    // Send the request using the server's credentials
    std::cout <<"Sending RefDataRequest using server "
        << "credentials..." << std::endl;
    session->sendRequest(request);
}



bool parseCommandLine(string[] argv)
{
    int tokenCount = 0;
    foreach(i;1..argc; ++i)
    {
        if (!argv[i]=="-s") ) {
            if (++i >= argv.length) return false;
            d_securities.push_back(argv[i]);
        }
        else if (!argv[i]=="-t")) {
            if (++i >= argv.length) return false;
            d_tokens.push_back(argv[i]);
            ++tokenCount;
            writefln("User #%s token:%s",tokenCount,argv[i]);
        }
        else if (!argv[i]=="-ip") {
            if (++i >= argv.length) return false;
            d_host = argv[i];
        }
        else if (!argv[i]=="-p") {
            if (++i >= argv.length) return false;
            d_port = atoi(argv[i]);
        }
        else {
            // fail parse on any unknown command line argument
            return false;
        }
    }

    if (!d_tokens.size()) {
        writefln("No tokens were specified");
        return false;
    }

    if (!d_securities.size()) {
        d_securities.push_back("MSFT US Equity");
    }

    return true;
}



public:

EntitlementsVerificationTokenExample()
: d_host("localhost")
, d_port(8194)
{
}

void run(string[] argv) {
    if (!parseCommandLine(argv)) {
        printUsage();
        return;
    }

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s" + d_host, d_port);

    SessionEventHandler eventHandler(d_identities, d_tokens);
    Session session(sessionOptions, &eventHandler);

    if (!session.start()) {
        stderr.writefln("Failed to start session. Exiting...");
        throw new Exception("failed to start session");
    }

    openServices(&session);

    EventQueue authQueue;

    // Authorize all the users that are interested in receiving data
    if (authorizeUsers(&authQueue, &session)) {
        // Make the various requests that we need to make
        sendRefDataRequest(&session);
    }

    // wait for enter key to exit application
    char dummy[2];
    std::cin.getline(dummy,2);

    {
        // Check if there were any authorization events received on the
        // 'authQueue'

        Event event;
        while (0 == authQueue.tryNextEvent(&event)) {
            printEvent(event);
        }
    }

    session.stop();
    writefln("Exiting...");
}

int main(int argc, char **argv)
{
    writefln("Entitlements Verification Token Example");

    EntitlementsVerificationTokenExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s", e.description());
    } catch (...) {
        stderr.writefln("Unknown Exception!!!");
    }

    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}


    const Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
    const Name AUTHORIZATION_FAILURE("AuthorizationFailure");
    const Name TOKEN_SUCCESS("TokenGenerationSuccess");
    const Name TOKEN_FAILURE("TokenGenerationFailure");

string d_host;
int d_port;
string d_DSProperty;
bool d_useDS;
string[] d_securities;
string[] d_fields;
Session *d_session;
Identity d_identity;

void printUsage()
{
    writefln("Usage:\n"
         "    Generate a token for authorization \n" 
         "        [-ip        <ipAddress  = localhost>\n"
         "        [-p         <tcpPort    = 8194>\n" 
         "        [-s         <security   = IBM US Equity>\n"
         "        [-f         <field      = PX_LAST>\n" 
         "        [-d         <dirSvcProperty = NULL>\n" );
}

bool parseCommandLine(string[] argv)
{
    foreach(i; 1..argv.length) {
        if (!strcmp(argv[i]=="-ip") && (i + 1 < argc))
            d_host = argv[++i];
        else if (!strcmp(argv[i]=="-p") &&  (i + 1 < argc))
            d_port = std::atoi(argv[++i]);
        else if (!std::strcmp(argv[i]=="-s") && (i + 1 < argc))
            d_securities.push_back(argv[++i]);
        else if (!std::strcmp(argv[i]=="-f") && (i + 1 < argc))
            d_fields.push_back(argv[++i]);
        else if (!std::strcmp(argv[i]=="-d") &&  (i + 1 < argc)) {
            d_useDS = true;
            d_DSProperty = argv[++i];
        } else {
            printUsage();
            return false;
        }
    }
    // handle default arguments
    if (d_securities.size() == 0) {
        d_securities.push_back("IBM US Equity");
    }

    if (d_fields.size() == 0) {
        d_fields.push_back("PX_LAST");
    }
    return true;
}

void sendRequest()
{
    Service refDataService = d_session.getService("//blp/refdata");
    Request request = refDataService.createRequest("ReferenceDataRequest");

    // Add securities to request
    Element securities = request.getElement("securities");
    for (size_t i = 0; i < d_securities.size(); ++i) {
        securities.appendValue(d_securities[i].c_str());
    }

    // Add fields to request
    Element fields = request.getElement("fields");
    for (size_t i = 0; i < d_fields.size(); ++i) {
        fields.appendValue(d_fields[i].c_str());
    }

    std::cout << "Sending Request: " << request << std::endl;
    d_session.sendRequest(request, d_identity);
}

bool processTokenStatus(const Event &event)
{
    std::cout << "processTokenEvents" << std::endl;
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        if (msg.messageType() == TOKEN_SUCCESS) {
            msg.print(std::cout);

            Service authService = d_session.getService("//blp/apiauth");
            Request authRequest = authService.createAuthorizationRequest();
            authRequest.set("token", msg.getElementAsString("token"));

            d_identity = d_session.createIdentity();
            d_session.sendAuthorizationRequest(authRequest, &d_identity,
                CorrelationId(1));
        } else if (msg.messageType() == TOKEN_FAILURE) {
            msg.print(std::cout);
            return false;
        }
    }

    return true;
}

bool processEvent(const Event &event)
{
    std::cout << "processEvent" << std::endl;
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        if (msg.messageType() == AUTHORIZATION_SUCCESS) {
            writefln("Authorization SUCCESS");
            sendRequest();
        } else if (msg.messageType() == AUTHORIZATION_FAILURE) {
            writefln( "Authorization FAILED");
            return false;
        } else {
            msg.print(std::cout);
            if (event.eventType() == Event::RESPONSE) {
                writefln("Got Final Response");
                return false;
            }
        }
    }
    return true;
}

public:
GenerateTokenExample()
    : d_host("localhost"), d_port(8194), d_useDS(false), d_session(0)
{
}

~GenerateTokenExample()
{
    if (d_session) {
        d_session.stop();
        delete d_session;
    }
}

void run(string[] argv)
{
    if (!parseCommandLine(argc, argv)) return;

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    string authOptions = "AuthenticationType=OS_LOGON";
    if (d_useDS) {
        authOptions = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
        authOptions.append(d_DSProperty);
    }
    writefln("authOptions = %s", authOptions);
    sessionOptions.setAuthenticationOptions(authOptions.c_str());

    writefln("Connecting to %s:%s", d_host , d_port);
        << std::endl;
    d_session = new Session(sessionOptions);
    if (!d_session.start()) {
        stderr.writefln("Failed to start session.");
        return;
    }

    if (!d_session.openService("//blp/refdata")) {
        stderr.writefln("Failed to open //blp/refdata");
        return;
    }
    if (!d_session.openService("//blp/apiauth")) {
        stderr.writefln("Failed to open //blp/apiauth");
        return;
    }

    CorrelationId tokenReqId(99);
    d_session.generateToken(tokenReqId);

    while (true) {
        Event event = d_session.nextEvent();
        if (event.eventType() == Event::TOKEN_STATUS) {
            if (!processTokenStatus(event)) {
                break;
            }
        } else {
            if (!processEvent(event)) {
                break;
            }
        }
    }
}

int main(string[] argv)
{
    writefln("GenerateTokenExample");
    GenerateTokenExample example;
    try {
        example.run(argc, argv);
    }
    catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s",e.description())
    }

    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);

    return 0;
}


const Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
const Name AUTHORIZATION_FAILURE("AuthorizationFailure");
const Name TOKEN_SUCCESS("TokenGenerationSuccess");
const Name TOKEN_FAILURE("TokenGenerationFailure");

const string AUTH_USER       = "AuthenticationType=OS_LOGON";
const string AUTH_APP_PREFIX = "AuthenticationMode=APPLICATION_ONLY;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const string AUTH_USER_APP_PREFIX = "AuthenticationMode=USER_AND_APPLICATION;AuthenticationType=OS_LOGON;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const string AUTH_DIR_PREFIX = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
const char* AUTH_OPTION_NONE      = "none";
const char* AUTH_OPTION_USER      = "user";
const char* AUTH_OPTION_APP       = "app=";
const char* AUTH_OPTION_USER_APP  = "userapp=";
const char* AUTH_OPTION_DIR       = "dir=";

class GenerateTokenSubscriptionExample
{
string                 d_host;
int                         d_port;
string                 d_authOptions;
string[]    d_securities;
string[]    d_fields;
string[]    d_options;

Session            *d_session;
Identity            d_identity;

void printUsage()
{
    writefln("Usage:\n"
         "    Generate a token for authorization \n"
         "        [-ip        <ipAddress  = localhost>]\n"
         "        [-p         <tcpPort    = 8194>]\n"
         "        [-s         <security   = IBM US Equity>]\n"
         "        [-f         <field      = LAST_PRICE>]\n"
         "        [-o         <options    = NULL>]\n"
         "        [-auth      <option>    = user]\n");
}

bool parseCommandLine(string argv[]);
{
    foreach (int i = 1; i < argv.length)
    {
        if (!std::strcmp(argv[i],"-ip") && i + 1 < argc)
            d_host = argv[++i];
        else if (!std::strcmp(argv[i],"-p") &&  i + 1 < argc)
            d_port = std::atoi(argv[++i]);
        else if (!std::strcmp(argv[i],"-s") && i + 1 < argc)
            d_securities.push_back(argv[++i]);
        else if (!std::strcmp(argv[i],"-f") && i + 1 < argc)
            d_fields.push_back(argv[++i]);
        else if (!std::strcmp(argv[i],"-auth") && i + 1 < argc) {
            ++ i;
            if (!std::strcmp(argv[i], AUTH_OPTION_NONE)) {
                d_authOptions.clear();
            }
            else if (strncmp(argv[i], AUTH_OPTION_APP, strlen(AUTH_OPTION_APP)) == 0) {
                d_authOptions.clear();
                d_authOptions.append(AUTH_APP_PREFIX);
                d_authOptions.append(argv[i] + strlen(AUTH_OPTION_APP));
            }
            else if (strncmp(argv[i], AUTH_OPTION_USER_APP, strlen(AUTH_OPTION_USER_APP)) == 0) {
                d_authOptions.clear();
                d_authOptions.append(AUTH_USER_APP_PREFIX);
                d_authOptions.append(argv[i] + strlen(AUTH_OPTION_USER_APP));
            }
            else if (strncmp(argv[i], AUTH_OPTION_DIR, strlen(AUTH_OPTION_DIR)) == 0) {
                d_authOptions.clear();
                d_authOptions.append(AUTH_DIR_PREFIX);
                d_authOptions.append(argv[i] + strlen(AUTH_OPTION_DIR));
            }
            else if (!std::strcmp(argv[i], AUTH_OPTION_USER)) {
                d_authOptions.assign(AUTH_USER);
            }
            else {
                printUsage();
                return false;
            }
        }
        else {
            printUsage();
            return false;
        }
    }
    // handle default arguments
    if (d_securities.size() == 0) {
        d_securities.push_back("IBM US Equity");
    }

    if (d_fields.size() == 0) {
        d_fields.push_back("LAST_PRICE");
    }
    return true;
}

void subscribe()
{
    SubscriptionList subscriptions;

    foreach(i;0.. d_securities.size())
    {
        subscriptions.add(d_securities[i].c_str(), d_fields, d_options, CorrelationId(i + 100));
    }

    std::cout << "Subscribing..." << std::endl;
    d_session.subscribe(subscriptions, d_identity);
}

bool processTokenStatus(const Event &event)
{
    writefln("processTokenEvents");
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        if (msg.messageType() == TOKEN_SUCCESS) {
            msg.print(std::cout);

            Service authService = d_session.getService("//blp/apiauth");
            Request authRequest = authService.createAuthorizationRequest();
            authRequest.set("token", msg.getElementAsString("token"));

            d_identity = d_session.createIdentity();
            d_session.sendAuthorizationRequest(authRequest, 
                                                &d_identity,
                                                CorrelationId(1));
        } else if (msg.messageType() == TOKEN_FAILURE) {
            msg.print(std::cout);
            return false;
        }
    }

    return true;
}

bool processEvent(const Event &event)
{
    writefln("processEvent");
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        if (msg.messageType() == AUTHORIZATION_SUCCESS) {
            writefln("Authorization SUCCESS");
            subscribe();
        } else if (msg.messageType() == AUTHORIZATION_FAILURE) {
            writefln("Authorization FAILED");
            msg.print(std::cout);
            return false;
        } else {
            msg.print(std::cout);
        }
    }
    return true;
}

public:
GenerateTokenSubscriptionExample()
    : d_host("localhost")
    , d_port(8194)
    , d_session(0)
    , d_authOptions(AUTH_USER)
{
}

~GenerateTokenSubscriptionExample()
{
    if (d_session) {
        d_session.stop();
        delete d_session;
    }
}

void run(string[] argv)
{
    if (!parseCommandLine(argv)) return;

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("authOptions = % ",d_authOptions);
    sessionOptions.setAuthenticationOptions(d_authOptions.c_str());

    writefln( "Connecting to %s:%s",d_host, d_port);
    d_session = new Session(sessionOptions);
    if (!d_session.start()) {
        stderr.writefln("Failed to start session.");
        return;
    }

    if (!d_session.openService("//blp/mktdata")) {
        stderr.writefln("Failed to open //blp/mktdata");
        return;
    }
    if (!d_session.openService("//blp/apiauth")) {
        stderr.writefln( "Failed to open //blp/apiauth");
        return;
    }

    CorrelationId tokenReqId(99);
    d_session.generateToken(tokenReqId);

    while (true) {
        Event event = d_session.nextEvent();
        if (event.eventType() == Event::TOKEN_STATUS) {
            if (!processTokenStatus(event)) {
                break;
            }
        } else {
            if (!processEvent(event)) {
                break;
            }
        }
    }
}

int main(string[] argv)
{
    writefln("GenerateTokenSubscriptionExample");
    GenerateTokenSubscriptionExample example;
    try {
        example.run(argc, argv);
    }
    catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s",e.description());
    }

    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);

    return 0;
}


namespace {
    const Name BAR_DATA("barData");
    const Name BAR_TICK_DATA("barTickData");
    const Name OPEN("open");
    const Name HIGH("high");
    const Name LOW("low");
    const Name CLOSE("close");
    const Name VOLUME("volume");
    const Name NUM_EVENTS("numEvents");
    const Name TIME("time");
    const Name RESPONSE_ERROR("responseError");
    const Name SESSION_TERMINATED("SessionTerminated");
    const Name CATEGORY("category");
    const Name MESSAGE("message");
};

struct IntradayBarExample {
    string d_host;
    int d_port;
    string d_security;
    string d_eventType;
    int d_barInterval;
    bool d_gapFillInitialBar;
    string d_startDateTime;
    string d_endDateTime;

    void printUsage()
    {
        writefln("Usage:\n" 
            " Retrieve intraday bars\n" 
            "     [-s     <security   = IBM US Equity>\n"
            "     [-e     <event      = TRADE>\n"
            "     [-b     <barInterval= 60>\n"
            "     [-sd    <startDateTime  = 2008-08-11T13:30:00>\n"
            "     [-ed    <endDateTime    = 2008-08-12T13:30:00>\n" 
            "     [-g     <gapFillInitialBar = false>\n"
            "     [-ip    <ipAddress = localhost>\n"
            "     [-p     <tcpPort   = 8194>\n"
            "1) All times are in GMT.\n"
            "2) Only one security can be specified.\n"
            "3) Only one event can be specified.");
    }

    void printErrorInfo(const char *leadingStr, const Element &errorInfo)
    {
        writefln(leadingStr ~ errorInfo.getElementAsString(CATEGORY)~ " (" << errorInfo.getElementAsString(MESSAGE) ~ ")");
    }

    bool parseCommandLine(string[] argv)
    {
        foreach(i;1..argv.length)
        {
            if (argv[i]=="-s") && (i + 1) < argc) {
                d_security = argv[++i];
            } else if (argv[i]=="-ip") && (i+1<argc)) {
                d_host = argv[++i];
            } else if (!argb[i]=="-p") &&  i + 1 < argc) {
                d_port = std::atoi(argv[++i]);
            } else if (!std::strcmp(argv[i],"-e") &&  i + 1 < argc) {
                d_eventType = argv[++i];
            } else if (!std::strcmp(argv[i],"-b") &&  i + 1 < argc) {
                d_barInterval = std::atoi(argv[++i]);
            } else if (!std::strcmp(argv[i],"-g")) {
                d_gapFillInitialBar = true;
            } else if (!std::strcmp(argv[i],"-sd") && i + 1 < argc) {
                d_startDateTime = argv[++i];
            } else if (!std::strcmp(argv[i],"-ed") && i + 1 < argc) {
                d_endDateTime = argv[++i];
            } else {
                printUsage();
                return false;
            }
        }

        return true;
    }

    void processMessage(Message &msg) {
        Element data = msg.getElement(BAR_DATA).getElement(BAR_TICK_DATA);
        int numBars = data.numValues();
        std::cout <<"Response contains " << numBars << " bars" << std::endl;
        std::cout <<"Datetime\t\tOpen\t\tHigh\t\tLow\t\tClose" <<
            "\t\tNumEvents\tVolume" << std::endl;
        foreach(i;0 .. numBars)
        {
            Element bar = data.getValueAsElement(i);
            Datetime time = bar.getElementAsDatetime(TIME);
            assert(time.hasParts(DatetimeParts::DATE
                               | DatetimeParts::HOURS
                               | DatetimeParts::MINUTES));
            double open = bar.getElementAsFloat64(OPEN);
            double high = bar.getElementAsFloat64(HIGH);
            double low = bar.getElementAsFloat64(LOW);
            double close = bar.getElementAsFloat64(CLOSE);
            int numEvents = bar.getElementAsInt32(NUM_EVENTS);
            long long volume = bar.getElementAsInt64(VOLUME);

            std::cout.setf(std::ios::fixed, std::ios::floatfield);
            writefln("%s/%s/%s %s:%s\t\topen\t\thigh\t\tlow\t\tclose\t\tnumEvents\t\tvolume",
                time.month(),time.day(),time.year(),time.hours(),time.minutes(), open, high, low, close, numevents, volume);
        }
    }

    void processResponseEvent(Event &event, Session &session) {
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            if (msg.hasElement(RESPONSE_ERROR)) {
                printErrorInfo("REQUEST FAILED: ",
                    msg.getElement(RESPONSE_ERROR));
                continue;
            }
            processMessage(msg);
        }
    }

    void sendIntradayBarRequest(Session &session)
    {
        Service refDataService = session.getService("//blp/refdata");
        Request request = refDataService.createRequest("IntradayBarRequest");

        // only one security/eventType per request
        request.set("security", d_security.c_str());
        request.set("eventType", d_eventType.c_str());
        request.set("interval", d_barInterval);

        if (d_startDateTime.empty() || d_endDateTime.empty()) {
            Datetime startDateTime, endDateTime;
            if (0 == getTradingDateRange(&startDateTime, &endDateTime)) {
                request.set("startDateTime", startDateTime);
                request.set("endDateTime", endDateTime);
            }
        }
        else {
            if (!d_startDateTime.empty() && !d_endDateTime.empty()) {
                request.set("startDateTime", d_startDateTime.c_str());
                request.set("endDateTime", d_endDateTime.c_str());
            }
        }

        if (d_gapFillInitialBar) {
            request.set("gapFillInitialBar", d_gapFillInitialBar);
        }

        std::cout <<"Sending Request: " << request << std::endl;
        session.sendRequest(request);
    }

    void eventLoop(Session &session) {
        bool done = false;
        while (!done) {
            Event event = session.nextEvent();
            if (event.eventType() == Event::PARTIAL_RESPONSE) {
                writefln("Processing Partial Response");
                processResponseEvent(event, session);
            }
            else if (event.eventType() == Event::RESPONSE) {
                writefln("Processing Response");
                processResponseEvent(event, session);
                done = true;
            } else {
                MessageIterator msgIter(event);
                while (msgIter.next()) {
                    Message msg = msgIter.message();
                    if (event.eventType() == Event::SESSION_STATUS) {
                        if (msg.messageType() == SESSION_TERMINATED) {
                            done = true;
                        }
                    }
                }
            }
        }
    }

    int getTradingDateRange(Datetime *startDate_p, Datetime *endDate_p)
    {
        struct tm *tm_p;
        time_t currTime = time(0);

        while (currTime > 0) {
            currTime -= 86400; // GO back one day
            tm_p = localtime(&currTime);
            if (tm_p == NULL) {
                break;
            }

            // if not sunday / saturday, assign values & return
            if (tm_p->tm_wday == 0 || tm_p->tm_wday == 6 ) {// Sun/Sat
                continue ;
            }
            startDate_p->setDate(tm_p->tm_year + 1900,
                tm_p->tm_mon + 1,
                tm_p->tm_mday);
            startDate_p->setTime(13, 30, 0) ;

            //the next day is the end day
            currTime += 86400 ;
            tm_p = localtime(&currTime);
            if (tm_p == NULL) {
                break;
            }
            endDate_p->setDate(tm_p->tm_year + 1900,
                tm_p->tm_mon + 1,
                tm_p->tm_mday);
            endDate_p->setTime(13, 30, 0) ;

            return(0) ;
        }
        return (-1) ;
    }

public:

    IntradayBarExample() {
        d_host = "localhost";
        d_port = 8194;
        d_barInterval = 60;
        d_security = "IBM US Equity";
        d_eventType = "TRADE";
        d_gapFillInitialBar = false;
    }

    ~IntradayBarExample() {
    };

    void run(string[] argv)
    {
        if (!parseCommandLine(argc, argv)) return;
        SessionOptions sessionOptions;
        sessionOptions.setServerHost(d_host.c_str());
        sessionOptions.setServerPort(d_port);

        writefln("Connecting to %s:%s",d_host,d_port);
        Session session(sessionOptions);
        if (!session.start()) {
            stderr.writefln("Failed to start session.");
            return;
        }
        if (!session.openService("//blp/refdata")) {
            stderr.writefln("Failed to open //blp/refdata");
            return;
        }

        sendIntradayBarRequest(session);

        // wait for events from session.
        eventLoop(session);

        session.stop();
    }
};

int main(string[] argv)
{
    writefln("IntradayBarExample");
     IntradayBarExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s ",e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

using namespace BloombergLP;
using namespace blpapi;

namespace {
    const Name TICK_DATA("tickData");
    const Name COND_CODE("conditionCodes");
    const Name TICK_SIZE("size");
    const Name TIME("time");
    const Name TYPE("type");
    const Name VALUE("value");
    const Name RESPONSE_ERROR("responseError");
    const Name CATEGORY("category");
    const Name MESSAGE("message");
    const Name SESSION_TERMINATED("SessionTerminated");
};

string                 d_host;
int                         d_port;
string                 d_security;
string[] d_events;
bool                        d_conditionCodes;
string                 d_startDateTime;
string                 d_endDateTime;


void printUsage()
{
    writefln("Usage:" << '\n'
         "  Retrieve intraday rawticks \n"
         "    [-s     <security = IBM US Equity>\n"
         "    [-e     <event = TRADE>\n" 
         "    [-sd    <startDateTime  = 2008-08-11T15:30:00>\n"
         "    [-ed    <endDateTime    = 2008-08-11T15:35:00>\n" 
         "    [-cc    <includeConditionCodes = false>\n" 
         "    [-ip    <ipAddress = localhost>\n" 
         "    [-p     <tcpPort   = 8194>\n" 
         "Notes:\n" 
         "1) All times are in GMT.\n"
         "2) Only one security can be specified.");
}

void printErrorInfo(const char *leadingStr, const Element &errorInfo)
{
    std::cout
        << leadingStr
        << errorInfo.getElementAsString(CATEGORY)
        << " (" << errorInfo.getElementAsString(MESSAGE)
        << ")" << std::endl;
}

bool parseCommandLine(int argc, char **argv)
{
    for (int i = 1; i < argc; ++i) {
        if (!std::strcmp(argv[i],"-s") && i + 1 < argc) {
            d_security = argv[++i];
        } else if (!std::strcmp(argv[i],"-e") && i + 1 < argc) {
            d_events.push_back(argv[++i]);
        } else if (!std::strcmp(argv[i],"-cc")) {
            d_conditionCodes = true;
        } else if (!std::strcmp(argv[i],"-sd") && i + 1 < argc) {
            d_startDateTime = argv[++i];
        } else if (!std::strcmp(argv[i],"-ed") && i + 1 < argc) {
            d_endDateTime = argv[++i];
        } else if (!std::strcmp(argv[i],"-ip") && i + 1 < argc) {
            d_host = argv[++i];
        } else if (!std::strcmp(argv[i],"-p") &&  i + 1 < argc) {
            d_port = std::atoi(argv[++i]);
            continue;
        } else {
            printUsage();
            return false;
        }
    }

    if (d_events.size() == 0) {
        d_events.push_back("TRADE");
    }
    return true;
}

void processMessage(Message &msg)
{
    Element data = msg.getElement(TICK_DATA).getElement(TICK_DATA);
    int numItems = data.numValues();
    std::cout << "TIME\t\t\t\tTYPE\tVALUE\t\tSIZE\tCC" << std::endl;
    std::cout << "----\t\t\t\t----\t-----\t\t----\t--" << std::endl;
    std::string cc;
    std::string type;
    for (int i = 0; i < numItems; ++i) {
        Element item = data.getValueAsElement(i);
        std::string timeString = item.getElementAsString(TIME);
        type = item.getElementAsString(TYPE);
        double value = item.getElementAsFloat64(VALUE);
        int size = item.getElementAsInt32(TICK_SIZE);
        if (item.hasElement(COND_CODE)) {
            cc = item.getElementAsString(COND_CODE);
        }  else {
            cc.clear();
        }

        std::cout.setf(std::ios::fixed, std::ios::floatfield);
        std::cout << timeString <<  "\t"
            << type << "\t"
            << std::setprecision(3)
            << std::showpoint << value << "\t\t"
            << size << "\t" << std::noshowpoint
            << cc << std::endl;
    }
}

void processResponseEvent(Event &event)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        if (msg.hasElement(RESPONSE_ERROR)) {
            printErrorInfo("REQUEST FAILED: ",
                msg.getElement(RESPONSE_ERROR));
            continue;
        }
        processMessage(msg);
    }
}

void sendIntradayTickRequest(Session &session)
{
    Service refDataService = session.getService("//blp/refdata");
    Request request = refDataService.createRequest("IntradayTickRequest");

    // only one security/eventType per request
    request.set("security", d_security.c_str());

    // Add fields to request
    Element eventTypes = request.getElement("eventTypes");
    for (size_t i = 0; i < d_events.size(); ++i) {
        eventTypes.appendValue(d_events[i].c_str());
    }

    // All times are in GMT
    if (d_startDateTime.empty() || d_endDateTime.empty()) {
        Datetime startDateTime, endDateTime ;
        if (0 == getTradingDateRange(&startDateTime, &endDateTime)) {
            request.set("startDateTime", startDateTime);
            request.set("endDateTime", endDateTime);
        }
    }
    else {
        if (!d_startDateTime.empty() && !d_endDateTime.empty()) {
            request.set("startDateTime", d_startDateTime.c_str());
            request.set("endDateTime", d_endDateTime.c_str());
        }
    }

    if (d_conditionCodes) {
        request.set("includeConditionCodes", true);
    }

    std::cout <<"Sending Request: " << request << std::endl;
    session.sendRequest(request);
}

void eventLoop(Session &session)
{
    bool done = false;
    while (!done) {
        Event event = session.nextEvent();
        if (event.eventType() == Event::PARTIAL_RESPONSE) {
            std::cout <<"Processing Partial Response" << std::endl;
            processResponseEvent(event);
        }
        else if (event.eventType() == Event::RESPONSE) {
            std::cout <<"Processing Response" << std::endl;
            processResponseEvent(event);
            done = true;
        } else {
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (event.eventType() == Event::SESSION_STATUS) {
                    if (msg.messageType() == SESSION_TERMINATED) {
                        done = true;
                    }
                }
            }
        }
    }
}

int getTradingDateRange (Datetime *startDate_p, Datetime *endDate_p)
{
    struct tm *tm_p;
    time_t currTime = time(0);

    while (currTime > 0) {
        currTime -= 86400; // GO back one day
        tm_p = localtime(&currTime);
        if (tm_p == NULL) {
            break;
        }

        // if not sunday / saturday, assign values & return
        if (tm_p->tm_wday == 0 || tm_p->tm_wday == 6 ) {// Sun/Sat
            continue ;
        }

        startDate_p->setDate(tm_p->tm_year + 1900,
            tm_p->tm_mon + 1,
            tm_p->tm_mday);
        startDate_p->setTime(15, 30, 0) ;

        endDate_p->setDate(tm_p->tm_year + 1900,
            tm_p->tm_mon + 1,
            tm_p->tm_mday);
        endDate_p->setTime(15, 35, 0) ;
        return(0) ;
    }
    return (-1) ;
}

public:

IntradayTickExample()
{
    d_host = "localhost";
    d_port = 8194;
    d_security = "IBM US Equity";
    d_conditionCodes = false;
}

~IntradayTickExample() {
}

void run(int argc, string[] argv)
{
    if (!parseCommandLine(argc, argv)) return;
    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    std::cout <<"Connecting to " << d_host << ":" << d_port << std::endl;
    Session session(sessionOptions);
    if (!session.start()) {
        std::cerr << "Failed to start session." << std::endl;
        return;
    }
    if (!session.openService("//blp/refdata")) {
        std::cerr << "Failed to open //blp/refdata" << std::endl;
        return;
    }

    sendIntradayTickRequest(session);

    // wait for events from session.
    eventLoop(session);

    session.stop();
}

int main(string[] argv)
{
    writefln("IntradayTickExample");
    IntradayTickExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        writefln("Library Exception!!! %s", e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

using namespace BloombergLP;
using namespace blpapi;

namespace {

Name TOKEN_SUCCESS("TokenGenerationSuccess");
Name TOKEN_FAILURE("TokenGenerationFailure");
Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
Name TOKEN("token");

const std::string AUTH_USER       = "AuthenticationType=OS_LOGON";
const std::string AUTH_APP_PREFIX = "AuthenticationMode=APPLICATION_ONLY;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const std::string AUTH_USER_APP_PREFIX = "AuthenticationMode=USER_AND_APPLICATION;AuthenticationType=OS_LOGON;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const std::string AUTH_DIR_PREFIX = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
const char* AUTH_OPTION_NONE      = "none";
const char* AUTH_OPTION_USER      = "user";
const char* AUTH_OPTION_APP       = "app=";
const char* AUTH_OPTION_USER_APP  = "userapp=";
const char* AUTH_OPTION_DIR       = "dir=";

}

class LocalMktdataSubscriptionExample
{
    std::vector<std::string> d_hosts;
    int                      d_port;
    int                      d_maxEvents;
    int                      d_eventCount;
    std::string              d_service;
    std::vector<std::string> d_topics;
    std::vector<std::string> d_fields;
    std::vector<std::string> d_options;
    std::string              d_authOptions;

    void printUsage()
    {
        std::cout
            << "Retrieve realtime data." << std::endl
            << "Usage:" << std::endl
            << "\t[-ip   <ipAddress>]\tserver name or IP (default: localhost)" << std::endl
            << "\t[-p    <tcpPort>]  \tserver port (default: 8194)" << std::endl
            << "\t[-s    <service>]  \tservice name (default: //viper/mktdata))" << std::endl
            << "\t[-t    <topic>]    \ttopic name (default: /ticker/IBM Equity)" << std::endl
            << "\t[-f    <field>]    \tfield to subscribe to (default: empty)" << std::endl
            << "\t[-o    <option>]   \tsubscription options (default: empty)" << std::endl
            << "\t[-me   <maxEvents>]\tstop after this many events (default: INT_MAX)" << std::endl
            << "\t[-auth <option>]   \tauthentication option: user|none|app=<app>|userapp=<app>|dir=<property> (default: user)" << std::endl;
    }

    bool parseCommandLine(int argc, char **argv)
    {
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i],"-ip") && i + 1 < argc)
                d_hosts.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-p") && i + 1 < argc)
                d_port = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i],"-s") && i + 1 < argc)
                d_service = argv[++i];
            else if (!std::strcmp(argv[i],"-t") && i + 1 < argc)
                d_topics.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-f") && i + 1 < argc)
                d_fields.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-o") && i + 1 < argc)
                d_options.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-me") && i + 1 < argc)
                d_maxEvents = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i], "-auth") && i + 1 < argc) {
                ++ i;
                if (!std::strcmp(argv[i], AUTH_OPTION_NONE)) {
                    d_authOptions.clear();
                }
                else if (strncmp(argv[i], AUTH_OPTION_APP, strlen(AUTH_OPTION_APP)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_APP_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_APP));
                }
                else if (strncmp(argv[i], AUTH_OPTION_USER_APP, strlen(AUTH_OPTION_USER_APP)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_USER_APP_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_USER_APP));
                }
                else if (strncmp(argv[i], AUTH_OPTION_DIR, strlen(AUTH_OPTION_DIR)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_DIR_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_DIR));
                }
                else if (!std::strcmp(argv[i], AUTH_OPTION_USER)) {
                    d_authOptions.assign(AUTH_USER);
                }
                else {
                    printUsage();
                    return false;
                }
            }
            else {
                printUsage();
                return false;
            }
        }

        if (d_hosts.size() == 0) {
            d_hosts.push_back("localhost");
        }

        if (d_topics.size() == 0) {
            d_topics.push_back("/ticker/IBM Equity");
        }

        return true;
    }

   bool authorize(const Service &authService,
                  Identity *subscriptionIdentity,
                  Session *session,
                  const CorrelationId &cid)
    {
        EventQueue tokenEventQueue;
        session->generateToken(CorrelationId(), &tokenEventQueue);
        std::string token;
        Event event = tokenEventQueue.nextEvent();
        MessageIterator iter(event);
        if (event.eventType() == Event::TOKEN_STATUS ||
            event.eventType() == Event::REQUEST_STATUS) {
            MessageIterator iter(event);
            while (iter.next()) {
                Message msg = iter.message();
                msg.print(std::cout);
                if (msg.messageType() == TOKEN_SUCCESS) {
                    token = msg.getElementAsString(TOKEN);
                }
                else if (msg.messageType() == TOKEN_FAILURE) {
                    break;
                }
            }
        }
        if (token.length() == 0) {
            std::cout << "Failed to get token" << std::endl;
            return false;
        }

        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set(TOKEN, token.c_str());

        session->sendAuthorizationRequest(authRequest, subscriptionIdentity);

        time_t startTime = time(0);
        const int WAIT_TIME_SECONDS = 10;
        while (true) {
            Event event = session->nextEvent(WAIT_TIME_SECONDS * 1000);
            if (event.eventType() == Event::RESPONSE ||
                event.eventType() == Event::REQUEST_STATUS ||
                event.eventType() == Event::PARTIAL_RESPONSE)
            {
                MessageIterator msgIter(event);
                while (msgIter.next()) {
                    Message msg = msgIter.message();
                    msg.print(std::cout);
                    if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                        return true;
                    }
                    else {
                        std::cout << "Authorization failed" << std::endl;
                        return false;
                    }
                }
            }
            time_t endTime = time(0);
            if (endTime - startTime > WAIT_TIME_SECONDS) {
                return false;
            }
        }
    }

public:
    LocalMktdataSubscriptionExample()
        : d_port(8194)
        , d_maxEvents(INT_MAX)
        , d_eventCount(0)
        , d_service("//viper/mktdata")
        , d_authOptions(AUTH_USER)
    {
    }

    void run(int argc, char **argv)
    {
        if (!parseCommandLine(argc, argv))
            return;

        SessionOptions sessionOptions;
        for (size_t i = 0; i < d_hosts.size(); ++i) { // override default 'localhost:8194'
            sessionOptions.setServerAddress(d_hosts[i].c_str(), d_port, i);
        }
        sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
        sessionOptions.setAutoRestartOnDisconnection(true);

        // NOTE: If running without a backup server, make many attempts to
        // connect/reconnect to give that host a chance to come back up (the
        // larger the number, the longer it will take for SessionStartupFailure
        // to come on startup, or SessionTerminated due to inability to fail
        // over).  We don't have to do that in a redundant configuration - it's
        // expected at least one server is up and reachable at any given time,
        // so only try to connect to each server once.
        sessionOptions.setNumStartAttempts(d_hosts.size() > 1? 1: 1000);

        std::cout << "Connecting to port " << d_port
                  << " on ";
        for (size_t i = 0; i < sessionOptions.numServerAddresses(); ++i) {
            unsigned short port;
            const char *host;
            sessionOptions.getServerAddress(&host, &port, i);
            std::cout << (i? ", ": "") << host;
        }
        std::cout << std::endl;

        Session session(sessionOptions);
        if (!session.start()) {
            std::cerr <<"Failed to start session." << std::endl;
            return;
        }

        Identity subscriptionIdentity = session.createIdentity();
        if (!d_authOptions.empty()) {
            bool isAuthorized = false;
            const char* authServiceName = "//blp/apiauth";
            if (session.openService(authServiceName)) {
                Service authService = session.getService(authServiceName);
                isAuthorized = authorize(authService, &subscriptionIdentity,
                        &session, CorrelationId((void *)"auth"));
            }
            if (!isAuthorized) {
                std::cerr << "No authorization" << std::endl;
                return;
            }
        }

        SubscriptionList subscriptions;
        for (size_t i = 0; i < d_topics.size(); ++i) {
            std::string topic(d_service + d_topics[i]);
            subscriptions.add(topic.c_str(),
                              d_fields,
                              d_options,
                              CorrelationId((char*)d_topics[i].c_str()));
        }
        session.subscribe(subscriptions, subscriptionIdentity);

        while (true) {
            Event event = session.nextEvent();
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (event.eventType() == Event::SUBSCRIPTION_STATUS ||
                    event.eventType() == Event::SUBSCRIPTION_DATA) {

                    const char *topic = (char *)msg.correlationId().asPointer();
                    std::cout << topic << " - ";
                }
                msg.print(std::cout) << std::endl;
            }
            if (event.eventType() == Event::SUBSCRIPTION_DATA) {
                if (++d_eventCount >= d_maxEvents) break;
            }
        }
    }
};

int main(int argc, char **argv)
{
    std::cout << "LocalMktdataSubscriptionExample" << std::endl;
    LocalMktdataSubscriptionExample example;
    try {
        example.run(argc, argv);
    }
    catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description()
            << std::endl;
    }

    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

using namespace BloombergLP;
using namespace blpapi;

namespace {
Name TOKEN_SUCCESS("TokenGenerationSuccess");
Name TOKEN_FAILURE("TokenGenerationFailure");
Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
Name TOKEN("token");

const std::string AUTH_USER       = "AuthenticationType=OS_LOGON";
const std::string AUTH_APP_PREFIX = "AuthenticationMode=APPLICATION_ONLY;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const std::string AUTH_USER_APP_PREFIX = "AuthenticationMode=USER_AND_APPLICATION;AuthenticationType=OS_LOGON;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const std::string AUTH_DIR_PREFIX = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
const char* AUTH_OPTION_NONE      = "none";
const char* AUTH_OPTION_USER      = "user";
const char* AUTH_OPTION_APP       = "app=";
const char* AUTH_OPTION_USER_APP  = "userapp=";
const char* AUTH_OPTION_DIR       = "dir=";
} // namespace {

class LocalPageSubscriptionExample
{
    std::vector<std::string> d_hosts;
    int                      d_port;
    std::string              d_service;
    int                      d_maxEvents;
    int                      d_eventCount;
    std::string              d_authOptions;

    void printUsage()
    {
        std::cout
            << "Page monitor." << std::endl
            << "Usage:" << std::endl
            << "\t[-ip   <ipAddress>]  \tserver name or IP (default: localhost)" << std::endl
            << "\t[-p    <tcpPort>]    \tserver port (default: 8194)" << std::endl
            << "\t[-s    <service>]    \tservice name (default: //viper/page)" << std::endl
            << "\t[-me   <maxEvents>]  \tnumber of events to retrieve (default: MAX_INT)" << std::endl
            << "\t[-auth <option>]     \tauthentication option: user|none|app=<app>|userapp=<app>|dir=<property> (default: user)" << std::endl;
    }

    bool parseCommandLine(int argc, char **argv)
    {
        bool numAuthProvidedByUser = false;
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i], "-ip") && i + 1 < argc)
                d_hosts.push_back(argv[++i]);
            else if (!std::strcmp(argv[i], "-p") && i + 1 < argc)
                d_port = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i], "-s") && i + 1 < argc)
                d_service = argv[++i];
            else if (!std::strcmp(argv[i], "-me") && i + 1 < argc)
                d_maxEvents = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i], "-auth") && i + 1 < argc) {
                ++ i;
                if (!std::strcmp(argv[i], AUTH_OPTION_NONE)) {
                    d_authOptions.clear();
                }
                else if (strncmp(argv[i], AUTH_OPTION_APP, strlen(AUTH_OPTION_APP)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_APP_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_APP));
                }
                else if (strncmp(argv[i], AUTH_OPTION_USER_APP, strlen(AUTH_OPTION_USER_APP)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_USER_APP_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_USER_APP));
                }
                else if (strncmp(argv[i], AUTH_OPTION_DIR, strlen(AUTH_OPTION_DIR)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_DIR_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_DIR));
                }
                else if (!std::strcmp(argv[i], AUTH_OPTION_USER)) {
                    d_authOptions.assign(AUTH_USER);
                }
                else {
                    printUsage();
                    return false;
                }
            }
            else {
                printUsage();
                return false;
            }
        }

        if (d_hosts.size() == 0) {
            d_hosts.push_back("localhost");
        }

        return true;
    }

  public:

    bool authorize(const Service& authService,
                   Identity *subscriptionIdentity,
                   Session *session,
                   const CorrelationId& cid)
    {
        EventQueue tokenEventQueue;
        session->generateToken(CorrelationId(), &tokenEventQueue);
        std::string token;
        Event event = tokenEventQueue.nextEvent();
        MessageIterator iter(event);
        if (event.eventType() == Event::TOKEN_STATUS ||
            event.eventType() == Event::REQUEST_STATUS) {
            MessageIterator iter(event);
            while (iter.next()) {
                Message msg = iter.message();
                msg.print(std::cout);
                if (msg.messageType() == TOKEN_SUCCESS) {
                    token = msg.getElementAsString(TOKEN);
                }
                else if (msg.messageType() == TOKEN_FAILURE) {
                    break;
                }
            }
        }
        if (token.length() == 0) {
            std::cout << "Failed to get token" << std::endl;
            return false;
        }

        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set(TOKEN, token.c_str());

        session->sendAuthorizationRequest(authRequest, subscriptionIdentity);

        time_t startTime = time(0);
        const int WAIT_TIME_SECONDS = 10;
        while (true) {
            Event event = session->nextEvent(WAIT_TIME_SECONDS * 1000);
            if (event.eventType() == Event::RESPONSE ||
                event.eventType() == Event::REQUEST_STATUS ||
                event.eventType() == Event::PARTIAL_RESPONSE)
            {
                MessageIterator msgIter(event);
                while (msgIter.next()) {
                    Message msg = msgIter.message();
                    msg.print(std::cout);
                    if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                        return true;
                    }
                    else {
                        std::cout << "Authorization failed" << std::endl;
                        return false;
                    }
                }
            }
            time_t endTime = time(0);
            if (endTime - startTime > WAIT_TIME_SECONDS) {
                return false;
            }
        }
    }

    void run(int argc, char **argv)
    {
        d_port = 8194;
        d_maxEvents = INT_MAX;
        d_eventCount = 0;
        d_service = "//viper/page";
        d_authOptions = AUTH_USER;

        if (!parseCommandLine(argc, argv))
            return;

        SessionOptions sessionOptions;
        for (size_t i = 0; i < d_hosts.size(); ++i) { // override default 'localhost:8194'
            sessionOptions.setServerAddress(d_hosts[i].c_str(), d_port, i);
        }
        sessionOptions.setServerPort(d_port);
        sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
        sessionOptions.setAutoRestartOnDisconnection(true);
        sessionOptions.setNumStartAttempts(2);

        std::cout << "Connecting to port " << d_port
                  << " on ";
        for (size_t i = 0; i < sessionOptions.numServerAddresses(); ++i) {
            unsigned short port;
            const char *host;
            sessionOptions.getServerAddress(&host, &port, i);
            std::cout << (i? ", ": "") << host;
        }
        std::cout << std::endl;

        Session session(sessionOptions);
        if (!session.start()) {
            std::cerr <<"Failed to start session." << std::endl;
            return;
        }

        Identity subscriptionIdentity = session.createIdentity();
        if (!d_authOptions.empty()) {
            bool isAuthorized = false;
            const char* authServiceName = "//blp/apiauth";
            if (session.openService(authServiceName)) {
                Service authService = session.getService(authServiceName);
                if (authorize(authService, &subscriptionIdentity, &session,
                            CorrelationId((void *)"auth"))) {
                    isAuthorized = true;
                }
            }
            if (!isAuthorized) {
                std::cerr << "No authorization" << std::endl;
                return;
            }
        }

        std::string topic(d_service + "/1245/4/5");
        std::string topic2(d_service + "/330/1/1");
        SubscriptionList subscriptions;
        subscriptions.add(topic.c_str(), CorrelationId((char*)topic.c_str()));
        subscriptions.add(topic2.c_str(), CorrelationId((char*)topic2.c_str()));
        session.subscribe(subscriptions, subscriptionIdentity);

        while (true) {
            Event event = session.nextEvent();
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (event.eventType() == Event::SUBSCRIPTION_STATUS ||
                    event.eventType() == Event::SUBSCRIPTION_DATA) {

                    const char *topic = (const char *)msg.correlationId().asPointer();
                    std::cout << topic << " - ";
                }
                msg.print(std::cout) << std::endl;
            }
            if (event.eventType() == Event::SUBSCRIPTION_DATA) {
                if (++d_eventCount >= d_maxEvents) break;
            }
        }
    }
};

int main(int argc, char **argv)
{
    std::cout << "LocalPageSubscriptionExample" << std::endl;
    LocalPageSubscriptionExample example;
    try {
        example.run(argc, argv);
    }
    catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description()
            << std::endl;
    }

    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

using namespace BloombergLP;
using namespace blpapi;

namespace {

Name TOKEN_SUCCESS("TokenGenerationSuccess");
Name TOKEN_FAILURE("TokenGenerationFailure");
Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
Name TOKEN("token");
Name SESSION_TERMINATED("SessionTerminated");

const char *AUTH_USER        = "AuthenticationType=OS_LOGON";
const char *AUTH_APP_PREFIX  = "AuthenticationMode=APPLICATION_ONLY;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const char *AUTH_DIR_PREFIX  = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";

const char *AUTH_OPTION_NONE = "none";
const char *AUTH_OPTION_USER = "user";
const char *AUTH_OPTION_APP  = "app=";
const char *AUTH_OPTION_DIR  = "dir=";

volatile bool g_running = true;
Mutex g_lock;

enum AuthorizationStatus {
    WAITING,
    AUTHORIZED,
    FAILED
};

std::map<CorrelationId, AuthorizationStatus> g_authorizationStatus;

}

class MyStream {
    std::string d_id;
    Topic d_topic;

public:
    MyStream() : d_id("") {}
    MyStream(std::string const& id) : d_id(id) {}
    void setTopic(Topic const& topic) { d_topic = topic; }
    std::string const& getId() { return d_id; }
    Topic const& getTopic() { return d_topic; }
};

typedef std::list<MyStream*> MyStreams;

class MyEventHandler : public ProviderEventHandler {
public:
    bool processEvent(const Event& event, ProviderSession* session)
    {
        MessageIterator iter(event);
        while (iter.next()) {
            MutexGuard guard(&g_lock);
            Message msg = iter.message();
            msg.print(std::cout);
            if (event.eventType() == Event::SESSION_STATUS) {
                if (msg.messageType() == SESSION_TERMINATED) {
                    g_running = false;
                }
                continue;
            }
            if (g_authorizationStatus.find(msg.correlationId()) != g_authorizationStatus.end()) {
                if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                    g_authorizationStatus[msg.correlationId()] = AUTHORIZED;
                }
                else {
                    g_authorizationStatus[msg.correlationId()] = FAILED;
                }
            }
        }
        return true;
    }
};

class MktdataBroadcastPublisherExample
{
    std::vector<std::string> d_hosts;
    int                      d_port;
    std::string              d_service;
    std::vector<Name>        d_fields;
    std::string              d_messageType;
    std::string              d_topic;
    std::string              d_groupId;
    std::string              d_authOptions;

    void printUsage()
    {
        std::cout
            << "Publish market data." << std::endl
            << "Usage:" << std::endl
            << "\t[-ip   <ipAddress>]  \tserver name or IP (default: localhost)" << std::endl
            << "\t[-p    <tcpPort>]    \tserver port (default: 8194)" << std::endl
            << "\t[-s    <service>]    \tservice name (default: //viper/mktdata)" << std::endl
            << "\t[-f    <field>]      \tfields (default: LAST_PRICE)" << std::endl
            << "\t[-m    <messageType>]\ttype of published event (default: MarketDataEvents)" << std::endl
            << "\t[-t    <topic>]      \ttopic (default: IBM Equity>]" << std::endl
            << "\t[-g    <groupId>]    \tpublisher groupId (defaults to unique value)" << std::endl
            << "\t[-auth <option>]     \tauthentication option: user|none|app=<app>|dir=<property> (default: user)" << std::endl;
    }

    bool parseCommandLine(int argc, char **argv)
    {
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i],"-ip") && i + 1 < argc)
                d_hosts.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-p") && i + 1 < argc)
                d_port = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i],"-s") && i + 1 < argc)
                d_service = argv[++i];
            else if (!std::strcmp(argv[i],"-f") && i + 1 < argc)
                d_fields.push_back(Name(argv[++i]));
            else if (!std::strcmp(argv[i],"-m") && i + 1 < argc)
                d_messageType = argv[++i];
            else if (!std::strcmp(argv[i],"-t") && i + 1 < argc)
                d_topic = argv[++i];
            else if (!std::strcmp(argv[i],"-g") && i + 1 < argc)
                d_groupId = argv[++i];
            else if (!std::strcmp(argv[i], "-auth") && i + 1 < argc) {
                ++ i;
                if (!std::strcmp(argv[i], AUTH_OPTION_NONE)) {
                    d_authOptions.clear();
                }
                else if (!std::strcmp(argv[i], AUTH_OPTION_USER)) {
                    d_authOptions.assign(AUTH_USER);
                }
                else if (strncmp(argv[i], AUTH_OPTION_APP,
                                 strlen(AUTH_OPTION_APP)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_APP_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_APP));
                }
                else if (strncmp(argv[i], AUTH_OPTION_DIR,
                                 strlen(AUTH_OPTION_DIR)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_DIR_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_DIR));
                }
                else {
                    printUsage();
                    return false;
                }
            }
            else {
                printUsage();
                return false;
            }
        }

        if (d_hosts.empty()) {
            d_hosts.push_back("localhost");
        }
        if (d_fields.empty()) {
            d_fields.push_back(Name("BID"));
            d_fields.push_back(Name("ASK"));
        }
        return true;
    }

public:

    MktdataBroadcastPublisherExample()
        : d_port(8194)
        , d_service("//viper/mktdata")
        , d_messageType("MarketDataEvents")
        , d_topic("IBM Equity")
        , d_authOptions(AUTH_USER)
    {
    }

    bool authorize(const Service &authService,
                   Identity *providerIdentity,
                   ProviderSession *session,
                   const CorrelationId &cid)
    {
        {
            MutexGuard guard(&g_lock);
            g_authorizationStatus[cid] = WAITING;
        }
        EventQueue tokenEventQueue;
        session->generateToken(CorrelationId(), &tokenEventQueue);
        std::string token;
        Event event = tokenEventQueue.nextEvent();
        if (event.eventType() == Event::TOKEN_STATUS ||
            event.eventType() == Event::REQUEST_STATUS) {
            MessageIterator iter(event);
            while (iter.next()) {
                Message msg = iter.message();
                {
                    MutexGuard guard(&g_lock);
                    msg.print(std::cout);
                }
                if (msg.messageType() == TOKEN_SUCCESS) {
                    token = msg.getElementAsString(TOKEN);
                }
                else if (msg.messageType() == TOKEN_FAILURE) {
                    break;
                }
            }
        }
        if (token.length() == 0) {
            MutexGuard guard(&g_lock);
            std::cout << "Failed to get token" << std::endl;
            return false;
        }

        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set(TOKEN, token.c_str());

        session->sendAuthorizationRequest(
            authRequest,
            providerIdentity,
            cid);

        time_t startTime = time(0);
        const int WAIT_TIME_SECONDS = 10;
        while (true) {
            {
                MutexGuard guard(&g_lock);
                if (WAITING != g_authorizationStatus[cid]) {
                    return AUTHORIZED == g_authorizationStatus[cid];
                }
            }
            time_t endTime = time(0);
            if (endTime - startTime > WAIT_TIME_SECONDS) {
                return false;
            }
            SLEEP(1);
        }
    }

    void run(int argc, char **argv)
    {
        if (!parseCommandLine(argc, argv))
            return;

        SessionOptions sessionOptions;
        for (size_t i = 0; i < d_hosts.size(); ++i) {
            sessionOptions.setServerAddress(d_hosts[i].c_str(), d_port, i);
        }
        sessionOptions.setServerPort(d_port);
        sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
        sessionOptions.setAutoRestartOnDisconnection(true);

        // NOTE: If running without a backup server, make many attempts to
        // connect/reconnect to give that host a chance to come back up (the
        // larger the number, the longer it will take for SessionStartupFailure
        // to come on startup, or SessionTerminated due to inability to fail
        // over).  We don't have to do that in a redundant configuration - it's
        // expected at least one server is up and reachable at any given time,
        // so only try to connect to each server once.
        sessionOptions.setNumStartAttempts(d_hosts.size() > 1? 1: 1000);

        MyEventHandler myEventHandler;
        ProviderSession session(sessionOptions, &myEventHandler, 0);

        std::cout << "Connecting to port " << d_port
                  << " on ";
        std::copy(d_hosts.begin(), d_hosts.end(), std::ostream_iterator<std::string>(std::cout, " "));
        std::cout << std::endl;

        if (!session.start()) {
            MutexGuard guard(&g_lock);
            std::cerr << "Failed to start session." << std::endl;
            return;
        }

        Identity providerIdentity = session.createIdentity();
        if (!d_authOptions.empty()) {
            bool isAuthorized = false;
            const char* authServiceName = "//blp/apiauth";
            if (session.openService(authServiceName)) {
                Service authService = session.getService(authServiceName);
                isAuthorized = authorize(authService, &providerIdentity,
                        &session, CorrelationId((void *)"auth"));
            }
            if (!isAuthorized) {
                std::cerr << "No authorization" << std::endl;
                return;
            }
        }

        if (!d_groupId.empty()) {
            // NOTE: will perform explicit service registration here, instead of letting
            //       createTopics do it, as the latter approach doesn't allow for custom
            //       ServiceRegistrationOptions
            ServiceRegistrationOptions serviceOptions;
            serviceOptions.setGroupId(d_groupId.c_str(), d_groupId.size());

            if (!session.registerService(d_service.c_str(), providerIdentity, serviceOptions)) {
                MutexGuard guard(&g_lock);
                std::cerr << "Failed to register " << d_service << std::endl;
                return;
            }
        }

        TopicList topicList;
        topicList.add((d_service + "/ticker/" + d_topic).c_str(),
            CorrelationId(new MyStream(d_topic)));

        session.createTopics(
            &topicList,
            ProviderSession::AUTO_REGISTER_SERVICES,
            providerIdentity);
        // createTopics() is synchronous, topicList will be updated
        // with the results of topic creation (resolution will happen
        // under the covers)

        MyStreams myStreams;

        for (size_t i = 0; i < topicList.size(); ++i) {
            MyStream *stream = reinterpret_cast<MyStream*>(
                topicList.correlationIdAt(i).asPointer());
            int status = topicList.statusAt(i);
            if (status == TopicList::CREATED) {
                {
                    MutexGuard guard(&g_lock);
                    std::cout << "Start publishing on topic: " << d_topic << std::endl;
                }
                Topic topic = session.getTopic(topicList.messageAt(i));
                stream->setTopic(topic);
                myStreams.push_back(stream);
            }
            else {
                MutexGuard guard(&g_lock);
                std::cout
                    << "Stream '"
                    << stream->getId()
                    << "': topic not created, status = "
                    << status
                    << std::endl;
            }
        }

        Service service = session.getService(d_service.c_str());
        Name PUBLISH_MESSAGE_TYPE(d_messageType.c_str());

        // Now we will start publishing
        int tickCount = 1;
        while (myStreams.size() > 0 && g_running) {
            Event event = service.createPublishEvent();
            EventFormatter eventFormatter(event);

            for (MyStreams::iterator iter = myStreams.begin();
                 iter != myStreams.end(); ++iter)
            {
                const Topic& topic = (*iter)->getTopic();
                if (!topic.isActive())  {
                    std::cout << "[WARN] Publishing on an inactive topic."
                              << std::endl;
                }
                eventFormatter.appendMessage(PUBLISH_MESSAGE_TYPE, topic);

                for (unsigned int i = 0; i < d_fields.size(); ++i) {
                    eventFormatter.setElement(
                        d_fields[i],
                        tickCount + (i + 1.0f));
                }
                ++tickCount;
            }

            MessageIterator iter(event);
            while (iter.next()) {
                Message msg = iter.message();
                MutexGuard guard(&g_lock);
                msg.print(std::cout);
            }

            session.publish(event);
            SLEEP(10);
        }

        session.stop();
    }
};

int main(int argc, char **argv)
{
    std::cout << "MktdataBroadcastPublisherExample" << std::endl;

    MktdataBroadcastPublisherExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description() << std::endl;
    }

    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);

    return 0;
}

using namespace BloombergLP;
using namespace blpapi;

namespace {

Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
Name PERMISSION_REQUEST("PermissionRequest");
Name RESOLUTION_SUCCESS("ResolutionSuccess");
Name SESSION_TERMINATED("SessionTerminated");
Name TOKEN("token");
Name TOKEN_SUCCESS("TokenGenerationSuccess");
Name TOKEN_FAILURE("TokenGenerationFailure");
Name TOPICS("topics");
Name TOPIC_CREATED("TopicCreated");
Name TOPIC_SUBSCRIBED("TopicSubscribed");
Name TOPIC_UNSUBSCRIBED("TopicUnsubscribed");
Name TOPIC_RECAP("TopicRecap");

const std::string AUTH_USER       = "AuthenticationType=OS_LOGON";
const std::string AUTH_APP_PREFIX = "AuthenticationMode=APPLICATION_ONLY;"
    "ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const std::string AUTH_USER_APP_PREFIX =
    "AuthenticationMode=USER_AND_APPLICATION;AuthenticationType=OS_LOGON;"
    "ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const std::string AUTH_DIR_PREFIX =
    "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
const char* AUTH_OPTION_NONE      = "none";
const char* AUTH_OPTION_USER      = "user";
const char* AUTH_OPTION_APP       = "app=";
const char* AUTH_OPTION_USER_APP  = "userapp=";
const char* AUTH_OPTION_DIR       = "dir=";


bool g_running = true;

class MyStream
{
    const std::string       d_id;
    const std::vector<Name> d_fields;
    int                     d_lastValue;
    int                     d_fieldsPublished;

    Topic                   d_topic;
    bool                    d_isSubscribed;

public:
    MyStream()
    : d_id("")
    , d_lastValue(0)
    , d_fieldsPublished(0)
    {}

    MyStream(const std::string& id, const std::vector<Name>& fields)
    : d_id(id)
    , d_fields(fields)
    , d_lastValue(0)
    , d_fieldsPublished(0)
    {}

    void setTopic(Topic topic) {
        d_topic = topic;
    }

    void setSubscribedState(bool isSubscribed) {
        d_isSubscribed = isSubscribed;
    }

    void fillData(EventFormatter&                eventFormatter,
                  const SchemaElementDefinition& elementDef)
    {
        for (int i = 0; i < d_fields.size(); ++i) {
            if (!elementDef.typeDefinition().hasElementDefinition(
                    d_fields[i])) {
                std::cerr << "Invalid field " << d_fields[i] << std::endl;
                continue;
            }
            SchemaElementDefinition fieldDef =
                elementDef.typeDefinition().getElementDefinition(d_fields[i]);

            switch (fieldDef.typeDefinition().datatype()) {
            case BLPAPI_DATATYPE_BOOL:
                eventFormatter.setElement(d_fields[i],
                                          bool((d_lastValue + i) % 2 == 0));
                break;
            case BLPAPI_DATATYPE_CHAR:
                eventFormatter.setElement(d_fields[i],
                                          char((d_lastValue + i) % 100 + 32));
                break;
            case BLPAPI_DATATYPE_INT32:
            case BLPAPI_DATATYPE_INT64:
                eventFormatter.setElement(d_fields[i], d_lastValue + i);
                break;
            case BLPAPI_DATATYPE_FLOAT32:
            case BLPAPI_DATATYPE_FLOAT64:
                eventFormatter.setElement(d_fields[i],
                                          (d_lastValue + i) * 1.1f);
                break;
            case BLPAPI_DATATYPE_STRING:
                {
                    std::ostringstream s;
                    s << "S" << (d_lastValue + i);
                    eventFormatter.setElement(d_fields[i], s.str().c_str());
                }
                break;
            case BLPAPI_DATATYPE_DATE:
            case BLPAPI_DATATYPE_TIME:
            case BLPAPI_DATATYPE_DATETIME:
                Datetime datetime;
                datetime.setDate(2011, 1, d_lastValue / 100 % 30 + 1);
                {
                    time_t now = time(0);
                    datetime.setTime(now / 3600 % 24,
                                     now % 3600 / 60,
                                     now % 60);
                }
                datetime.setMilliseconds(i);
                eventFormatter.setElement(d_fields[i], datetime);
                break;
            }
        }
    }

    void fillDataNull(EventFormatter&                eventFormatter,
                      const SchemaElementDefinition& elementDef)
    {
        for (int i = 0; i < d_fields.size(); ++i) {
            if (!elementDef.typeDefinition().hasElementDefinition(
                    d_fields[i])) {
                std::cerr << "Invalid field " << d_fields[i] << std::endl;
                continue;
            }
            SchemaElementDefinition fieldDef =
                elementDef.typeDefinition().getElementDefinition(d_fields[i]);

            if (fieldDef.typeDefinition().isSimpleType()) {
                // Publishing NULL value
                eventFormatter.setElementNull(d_fields[i]);
            }
        }
    }

    const std::string& getId() { return d_id; }

    void next() { d_lastValue += 1; }

    Topic& topic() {
        return d_topic;
    }

    bool isAvailable() {
        return d_topic.isValid() && d_isSubscribed;
    }

};

typedef std::map<std::string, MyStream*> MyStreams;

MyStreams g_streams;
int       g_availableTopicCount;
Mutex     g_mutex;

enum AuthorizationStatus {
    WAITING,
    AUTHORIZED,
    FAILED
};

std::map<CorrelationId, AuthorizationStatus> g_authorizationStatus;

void printMessages(const Event& event)
{
    MessageIterator iter(event);
    while (iter.next()) {
        Message msg = iter.message();
        msg.print(std::cout);
    }
}

} // namespace {

class MyEventHandler : public ProviderEventHandler
{
    const std::string       d_serviceName;
    Name                    d_messageType;
    const std::vector<Name> d_fields;
    const std::vector<int>  d_eids;
    int                     d_resolveSubServiceCode;

public:
    MyEventHandler(const std::string&       serviceName,
                   const Name&              messageType,
                   const std::vector<Name>& fields,
                   const std::vector<int>&  eids,
                   int                      resolveSubServiceCode)
    : d_serviceName(serviceName)
    , d_messageType(messageType)
    , d_fields(fields)
    , d_eids(eids)
    , d_resolveSubServiceCode(resolveSubServiceCode)
    {}

    bool processEvent(const Event& event, ProviderSession* session);
};

bool MyEventHandler::processEvent(const Event& event, ProviderSession* session)
{
    if (event.eventType() == Event::SESSION_STATUS) {
        printMessages(event);
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            if (msg.messageType() == SESSION_TERMINATED) {
                g_running = false;
            }
        }
    }
    else if (event.eventType() == Event::TOPIC_STATUS) {
        TopicList topicList;
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            std::cout << msg << std::endl;
            if (msg.messageType() == TOPIC_SUBSCRIBED) {
                std::string topicStr = msg.getElementAsString("topic");
                MutexGuard guard(&g_mutex);
                MyStreams::iterator it = g_streams.find(topicStr);
                if (it == g_streams.end()) {
                    // TopicList knows how to add an entry based on a
                    // TOPIC_SUBSCRIBED message.
                    topicList.add(msg);
                    it = (g_streams.insert(MyStreams::value_type(
                                     topicStr,
                                     new MyStream(topicStr, d_fields)))).first;
                }
                it->second->setSubscribedState(true);
                if (it->second->isAvailable()) {
                    ++g_availableTopicCount;
                }
            }
            else if (msg.messageType() == TOPIC_UNSUBSCRIBED) {
                std::string topicStr = msg.getElementAsString("topic");
                MutexGuard guard(&g_mutex);
                MyStreams::iterator it = g_streams.find(topicStr);
                if (it == g_streams.end()) {
                    // we should never be coming here. TOPIC_UNSUBSCRIBED can
                    // not come before a TOPIC_SUBSCRIBED or TOPIC_CREATED
                    continue;
                }
                if (it->second->isAvailable()) {
                    --g_availableTopicCount;
                }
                it->second->setSubscribedState(false);
            }
            else if (msg.messageType() == TOPIC_CREATED) {
                std::string topicStr = msg.getElementAsString("topic");
                MutexGuard guard(&g_mutex);
                MyStreams::iterator it = g_streams.find(topicStr);
                if (it == g_streams.end()) {
                    it = (g_streams.insert(MyStreams::value_type(
                                     topicStr,
                                     new MyStream(topicStr, d_fields)))).first;
                }
                try {
                    Topic topic = session->getTopic(msg);
                    it->second->setTopic(topic);
                } catch (blpapi::Exception &e) {
                    std::cerr << "Exception while processing TOPIC_CREATED: "
                              << e.description()
                              << std::endl;
                    continue;
                }
                if (it->second->isAvailable()) {
                    ++g_availableTopicCount;
                }

            }
            else if (msg.messageType() == TOPIC_RECAP) {
                // Here we send a recap in response to a Recap request.
                try {
                    std::string topicStr = msg.getElementAsString("topic");
                    MyStreams::iterator it = g_streams.find(topicStr);
                    MutexGuard guard(&g_mutex);
                    if (it == g_streams.end() || !it->second->isAvailable()) {
                        continue;
                    }
                    Topic topic = session->getTopic(msg);
                    Service service = topic.service();
                    CorrelationId recapCid = msg.correlationId();

                    Event recapEvent = service.createPublishEvent();
                    SchemaElementDefinition elementDef =
                        service.getEventDefinition(d_messageType);
                    EventFormatter eventFormatter(recapEvent);
                    eventFormatter.appendRecapMessage(topic, &recapCid);
                    it->second->fillData(eventFormatter, elementDef);
                    guard.release()->unlock();
                    session->publish(recapEvent);
                } catch (blpapi::Exception &e) {
                    std::cerr << "Exception while processing TOPIC_RECAP: "
                              << e.description()
                              << std::endl;
                    continue;
                }
            }
        }
        if (topicList.size()) {
            // createTopicsAsync will result in RESOLUTION_STATUS,
            // TOPIC_CREATED events.
            session->createTopicsAsync(topicList);
        }
    }
    else if (event.eventType() == Event::RESOLUTION_STATUS) {
        printMessages(event);
    }
    else if (event.eventType() == Event::REQUEST) {
        Service service = session->getService(d_serviceName.c_str());
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            msg.print(std::cout);
            if (msg.messageType() == PERMISSION_REQUEST) {
                // Similar to createPublishEvent. We assume just one
                // service - d_service. A responseEvent can only be
                // for single request so we can specify the
                // correlationId - which establishes context -
                // when we create the Event.
                Event response =
                    service.createResponseEvent(msg.correlationId());
                int permission = 1; // ALLOWED: 0, DENIED: 1
                EventFormatter ef(response);
                if (msg.hasElement("uuid")) {
                    int uuid = msg.getElementAsInt32("uuid");
                    permission = 0;
                }
                if (msg.hasElement("applicationId")) {
                    int applicationId = msg.getElementAsInt32("applicationId");
                    permission = 0;
                }

                // In appendResponse the string is the name of the
                // operation, the correlationId indicates
                // which request we are responding to.
                ef.appendResponse("PermissionResponse");
                ef.pushElement("topicPermissions");
                // For each of the topics in the request, add an entry
                // to the response
                Element topicsElement = msg.getElement(TOPICS);
                for (size_t i = 0; i < topicsElement.numValues(); ++i) {
                    ef.appendElement();
                    ef.setElement("topic", topicsElement.getValueAsString(i));
                    if (d_resolveSubServiceCode != INT_MIN) {
                        try {
                            ef.setElement("subServiceCode",
                                          d_resolveSubServiceCode);
                            std::cout << "Mapping topic "
                                      << topicsElement.getValueAsString(i)
                                      << " to subServiceCode "
                                      << d_resolveSubServiceCode
                                      << std::endl;
                        }
                        catch (blpapi::Exception &e) {
                            std::cerr << "subServiceCode could not be set."
                                      << " Resolving without subServiceCode"
                                      << std::endl;
                        }
                    }
                    ef.setElement("result", permission);
                        // ALLOWED: 0, DENIED: 1

                    if (permission == 1) {
                            // DENIED

                        ef.pushElement("reason");
                        ef.setElement("source", "My Publisher Name");
                        ef.setElement("category", "NOT_AUTHORIZED");
                            // or BAD_TOPIC, or custom

                        ef.setElement("subcategory", "Publisher Controlled");
                        ef.setElement("description",
                            "Permission denied by My Publisher Name");
                        ef.popElement();
                    }
                    else {
                        if (d_eids.size()) {
                            ef.pushElement("permissions");
                            ef.appendElement();
                            ef.setElement("permissionService",
                                          "//blp/blpperm");
                            ef.pushElement("eids");
                            for (std::vector<int>::const_iterator it
                                     = d_eids.begin();
                                 it != d_eids.end();
                                 ++it) {
                                ef.appendValue(*it);
                            }
                            ef.popElement();
                            ef.popElement();
                            ef.popElement();
                        }
                    }
                    ef.popElement();
                }
                ef.popElement();
                // Service is implicit in the Event. sendResponse has a
                // second parameter - partialResponse -
                // that defaults to false.
                session->sendResponse(response);
            }
        }
    }
    else {
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            MutexGuard guard(&g_mutex);
            if (g_authorizationStatus.find(msg.correlationId())
                    != g_authorizationStatus.end()) {
                if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                    g_authorizationStatus[msg.correlationId()] = AUTHORIZED;
                }
                else {
                    g_authorizationStatus[msg.correlationId()] = FAILED;
                }
            }
        }
        printMessages(event);
    }

    return true;
}

class MktdataPublisherExample
{
    std::vector<std::string> d_hosts;
    int                      d_port;
    int                      d_priority;
    std::string              d_service;
    std::vector<Name>        d_fields;
    std::string              d_messageType;
    std::vector<int>         d_eids;
    std::string              d_groupId;
    std::string              d_authOptions;
    int                      d_clearInterval;

    bool                     d_useSsc;
    int                      d_sscBegin;
    int                      d_sscEnd;
    int                      d_sscPriority;

    int                      d_resolveSubServiceCode;
    ProviderSession         *d_session_p;

    void printUsage()
    {
        std::cout
            << "Publish market data." << std::endl
            << "Usage:" << std::endl
            << "\t[-ip   <ipAddress>]  \tserver name or IP"
            << " (default: localhost)"
            << std::endl
            << "\t[-p    <tcpPort>]    \tserver port (default: 8194)"
            << std::endl
            << "\t[-s    <service>]    \tservice name"
            << " (default: //viper/mktdata)"
            << std::endl
            << "\t[-f    <field>]      \tfields (default: LAST_PRICE)"
            << std::endl
            << "\t[-m    <messageType>]\ttype of published event"
            << " (default: MarketDataEvents)" << std::endl
            << "\t[-e    <EID>]        \tpermission eid for all subscriptions"
            << std::endl
            << "\t[-g    <groupId>]    \tpublisher groupId"
            << " (defaults to unique value)" << std::endl
            << "\t[-pri  <priority>]   \tset publisher priority level"
            << " (default: 10)" << std::endl
            << "\t[-c    <event count>]\tnumber of events after which cache"
            << " will be cleared (default: 0 i.e cache never cleared)"
            << std::endl
            << "\t[-auth <option>]     \tauthentication option: user|none|"
            << "app=<app>|userapp=<app>|dir=<property> (default: user)"
            << std::endl
            << "\t[-ssc <option>]      \tactive sub-service code option:"
            << "<begin>,<end>,<priority> "
            << std::endl
            << "\t[-rssc <option>      \tsub-service code to be used in"
            << " resolves."
            << std::endl;
    }

    bool parseCommandLine(int argc, char **argv)
    {
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i],"-ip") && i + 1 < argc)
                d_hosts.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-p") && i + 1 < argc)
                d_port = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i],"-s") && i + 1 < argc)
                d_service = argv[++i];
            else if (!std::strcmp(argv[i],"-f") && i + 1 < argc)
                d_fields.push_back(Name(argv[++i]));
            else if (!std::strcmp(argv[i],"-m") && i + 1 < argc)
                d_messageType = argv[++i];
            else if (!std::strcmp(argv[i],"-e") && i + 1 < argc)
                d_eids.push_back(std::atoi(argv[++i]));
            else if (!std::strcmp(argv[i],"-g") && i + 1 < argc)
                d_groupId = argv[++i];
            else if (!std::strcmp(argv[i],"-pri") && i + 1 < argc)
                d_priority = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i],"-c") && i + 1 < argc)
                d_clearInterval = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i], "-auth") && i + 1 < argc) {
                ++ i;
                if (!std::strcmp(argv[i], AUTH_OPTION_NONE)) {
                    d_authOptions.clear();
                }
                else if (strncmp(argv[i],
                                 AUTH_OPTION_APP,
                                 strlen(AUTH_OPTION_APP)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_APP_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_APP));
                }
                else if (strncmp(argv[i],
                                 AUTH_OPTION_USER_APP,
                                 strlen(AUTH_OPTION_USER_APP)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_USER_APP_PREFIX);
                    d_authOptions.append(
                        argv[i] + strlen(AUTH_OPTION_USER_APP));
                }
                else if (strncmp(argv[i],
                                 AUTH_OPTION_DIR,
                                 strlen(AUTH_OPTION_DIR)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_DIR_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_DIR));
                }
                else if (!std::strcmp(argv[i], AUTH_OPTION_USER)) {
                    d_authOptions.assign(AUTH_USER);
                }
                else {
                    printUsage();
                    return false;
                }
            }
            else if (!std::strcmp(argv[i], "-ssc") && i + 1 < argc) {
                // subservice code entires
                d_useSsc = true;
                std::sscanf(argv[++i],
                            "%d,%d,%d",
                            &d_sscBegin,
                            &d_sscEnd,
                            &d_sscPriority);
            }
            else if (!std::strcmp(argv[i], "-rssc") && i + 1 < argc) {
                d_resolveSubServiceCode = std::atoi(argv[++i]);
            }
            else {
                printUsage();
                return false;
            }
        }

        if (d_hosts.size() == 0) {
            d_hosts.push_back("localhost");
        }
        if (!d_fields.size()) {
            d_fields.push_back(Name("LAST_PRICE"));
        }
        return true;
    }

public:
    MktdataPublisherExample()
        : d_port(8194)
        , d_service("//viper/mktdata")
        , d_messageType("MarketDataEvents")
        , d_authOptions(AUTH_USER)
        , d_priority(10)
        , d_clearInterval(0)
        , d_useSsc(false)
        , d_resolveSubServiceCode(INT_MIN)
    {
    }

    void activate() {
        if (d_useSsc) {
            std::cout << "Activating sub service code range "
                      << "[" << d_sscBegin << ", " << d_sscEnd
                      << "] @ priority " << d_sscPriority << std::endl;
            d_session_p->activateSubServiceCodeRange(d_service.c_str(),
                                                     d_sscBegin,
                                                     d_sscEnd,
                                                     d_sscPriority);
        }
    }
    void deactivate() {
        if (d_useSsc) {
            std::cout << "DeActivating sub service code range "
                      << "[" << d_sscBegin << ", " << d_sscEnd
                      << "] @ priority " << d_sscPriority << std::endl;

            d_session_p->deactivateSubServiceCodeRange(d_service.c_str(),
                                                       d_sscBegin,
                                                       d_sscEnd);
        }
    }

    bool authorize(const Service &authService,
                   Identity *providerIdentity,
                   ProviderSession *session,
                   const CorrelationId &cid)
    {
        {
            MutexGuard guard(&g_mutex);
            g_authorizationStatus[cid] = WAITING;
        }
        EventQueue tokenEventQueue;
        session->generateToken(CorrelationId(), &tokenEventQueue);
        std::string token;
        Event event = tokenEventQueue.nextEvent();
        if (event.eventType() == Event::TOKEN_STATUS) {
            MessageIterator iter(event);
            while (iter.next()) {
                Message msg = iter.message();
                msg.print(std::cout);
                if (msg.messageType() == TOKEN_SUCCESS) {
                    token = msg.getElementAsString(TOKEN);
                }
                else if (msg.messageType() == TOKEN_FAILURE) {
                    break;
                }
            }
        }
        if (token.length() == 0) {
            std::cout << "Failed to get token" << std::endl;
            return false;
        }

        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set(TOKEN, token.c_str());

        session->sendAuthorizationRequest(
            authRequest,
            providerIdentity,
            cid);

        time_t startTime = time(0);
        const int WAIT_TIME_SECONDS = 10;
        while (true) {
            {
                MutexGuard guard(&g_mutex);
                if (WAITING != g_authorizationStatus[cid]) {
                    return AUTHORIZED == g_authorizationStatus[cid];
                }
            }
            time_t endTime = time(0);
            if (endTime - startTime > WAIT_TIME_SECONDS) {
                return false;
            }
            SLEEP(1);
        }
    }

    void run(int argc, char **argv)
    {
        if (!parseCommandLine(argc, argv))
            return;

        SessionOptions sessionOptions;
        for (size_t i = 0; i < d_hosts.size(); ++i) {
            sessionOptions.setServerAddress(d_hosts[i].c_str(), d_port, i);
        }
        sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
        sessionOptions.setAutoRestartOnDisconnection(true);

        // NOTE: If running without a backup server, make many attempts to
        // connect/reconnect to give that host a chance to come back up (the
        // larger the number, the longer it will take for SessionStartupFailure
        // to come on startup, or SessionTerminated due to inability to fail
        // over).  We don't have to do that in a redundant configuration - it's
        // expected at least one server is up and reachable at any given time,
        // so only try to connect to each server once.
        sessionOptions.setNumStartAttempts(d_hosts.size() > 1? 1: 1000);

        std::cout << "Connecting to port " << d_port
                  << " on ";
        std::copy(d_hosts.begin(),
                  d_hosts.end(),
                  std::ostream_iterator<std::string>(std::cout, " "));
        std::cout << std::endl;

        Name PUBLISH_MESSAGE_TYPE(d_messageType.c_str());

        MyEventHandler myEventHandler(d_service,
                                      PUBLISH_MESSAGE_TYPE,
                                      d_fields,
                                      d_eids,
                                      d_resolveSubServiceCode);
        ProviderSession session(sessionOptions, &myEventHandler, 0);
        d_session_p = & session;
        if (!session.start()) {
            std::cerr << "Failed to start session." << std::endl;
            return;
        }

        Identity providerIdentity = session.createIdentity();
        if (!d_authOptions.empty()) {
            bool isAuthorized = false;
            const char* authServiceName = "//blp/apiauth";
            if (session.openService(authServiceName)) {
                Service authService = session.getService(authServiceName);
                isAuthorized = authorize(authService, &providerIdentity,
                        &session, CorrelationId((void *)"auth"));
            }
            if (!isAuthorized) {
                std::cerr << "No authorization" << std::endl;
                return;
            }
        }

        ServiceRegistrationOptions serviceOptions;
        serviceOptions.setGroupId(d_groupId.c_str(), d_groupId.size());
        serviceOptions.setServicePriority(d_priority);
        if (d_useSsc) {
            std::cout << "Adding active sub service code range "
                      << "[" << d_sscBegin << ", " << d_sscEnd
                      << "] @ priority " << d_sscPriority << std::endl;
            try {
                serviceOptions.addActiveSubServiceCodeRange(d_sscBegin,
                                                            d_sscEnd,
                                                            d_sscPriority);
            }
            catch (Exception& e) {
                std::cerr << "FAILED to add active sub service codes."
                          << " Exception "
                          << e.description() << std::endl;
            }
        }
        if (!session.registerService(d_service.c_str(),
                                     providerIdentity,
                                     serviceOptions)) {
            std::cerr << "Failed to register " << d_service << std::endl;
            return;
        }

        Service service = session.getService(d_service.c_str());
        SchemaElementDefinition elementDef
            = service.getEventDefinition(PUBLISH_MESSAGE_TYPE);
        int eventCount = 0;

        // Now we will start publishing
        int numPublished = 0;
        while (g_running) {
            Event event = service.createPublishEvent();
            {
                MutexGuard guard(&g_mutex);
                if (0 == g_availableTopicCount) {
                    guard.release()->unlock();
                    SLEEP(1);
                    continue;
                }

                bool publishNull = false;
                if (d_clearInterval > 0 && eventCount == d_clearInterval) {
                    eventCount = 0;
                    publishNull = true;
                }
                EventFormatter eventFormatter(event);
                for (MyStreams::iterator iter = g_streams.begin();
                    iter != g_streams.end(); ++iter) {
                    if (!iter->second->isAvailable()) {
                        continue;
                    }
                    eventFormatter.appendMessage(
                            PUBLISH_MESSAGE_TYPE,
                            iter->second->topic());
                    if (publishNull) {
                        iter->second->fillDataNull(eventFormatter, elementDef);
                    } else {
                        ++eventCount;
                        iter->second->next();
                        iter->second->fillData(eventFormatter, elementDef);
                    }
                }
            }

            printMessages(event);
            session.publish(event);
            SLEEP(1);
            if (++numPublished % 10 == 0) {
               deactivate();
               SLEEP(30);
               activate();
            }

        }
        session.stop();
    }
};

int main(int argc, char **argv)
{
    std::cout << "MktdataPublisherExample" << std::endl;
    MktdataPublisherExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description() << std::endl;
    }
    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}
using namespace BloombergLP;
using namespace blpapi;

namespace {

Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
Name RESOLUTION_SUCCESS("ResolutionSuccess");
Name PERMISSION_REQUEST("PermissionRequest");
Name SESSION_TERMINATED("SessionTerminated");
Name TOKEN("token");
Name TOKEN_SUCCESS("TokenGenerationSuccess");
Name TOKEN_FAILURE("TokenGenerationFailure");
Name TOPICS("topics");
Name TOPIC_CREATED("TopicCreated");
Name TOPIC_RECAP("TopicRecap");
Name TOPIC_SUBSCRIBED("TopicSubscribed");
Name TOPIC_UNSUBSCRIBED("TopicUnsubscribed");

const std::string AUTH_USER       = "AuthenticationType=OS_LOGON";
const std::string AUTH_APP_PREFIX = "AuthenticationMode=APPLICATION_ONLY;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const std::string AUTH_USER_APP_PREFIX = "AuthenticationMode=USER_AND_APPLICATION;AuthenticationType=OS_LOGON;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const std::string AUTH_DIR_PREFIX = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
const char* AUTH_OPTION_NONE      = "none";
const char* AUTH_OPTION_USER      = "user";
const char* AUTH_OPTION_APP       = "app=";
const char* AUTH_OPTION_USER_APP  = "userapp=";
const char* AUTH_OPTION_DIR       = "dir=";

bool g_running = true;

Mutex g_lock;

enum AuthorizationStatus {
    WAITING,
    AUTHORIZED,
    FAILED
};

std::map<CorrelationId, AuthorizationStatus> g_authorizationStatus;

class MyStream {
    const std::string d_id;
    volatile bool d_isInitialPaintSent;

    Topic d_topic;
    bool  d_isSubscribed;

  public:
    MyStream()
        : d_id(""),
          d_isInitialPaintSent(false)
    {}

    MyStream(std::string const& id)
        : d_id(id),
          d_isInitialPaintSent(false)
    {}

    std::string const& getId()
    {
        return d_id;
    }

    bool isInitialPaintSent() const
    {
        return d_isInitialPaintSent;
    }

    void setIsInitialPaintSent(bool value)
    {
        d_isInitialPaintSent = value;
    }
    void setTopic(Topic topic) {
        d_topic = topic;
    }

    void setSubscribedState(bool isSubscribed) {
        d_isSubscribed = isSubscribed;
    }

    Topic& topic() {
        return d_topic;
    }

    bool isAvailable() {
        return d_topic.isValid() && d_isSubscribed;
    }

};

typedef std::map<std::string, MyStream*> MyStreams;

MyStreams g_streams;
int       g_availableTopicCount;
Mutex     g_mutex;

void printMessages(const Event& event)
{
    MessageIterator iter(event);
    while (iter.next()) {
        Message msg = iter.message();
        msg.print(std::cout);
    }
}

} // namespace {

class MyEventHandler : public ProviderEventHandler
{
    const std::string d_serviceName;

public:
    MyEventHandler(const std::string& serviceName)
    : d_serviceName(serviceName)
    {}

    bool processEvent(const Event& event, ProviderSession* session);
};

bool MyEventHandler::processEvent(const Event& event, ProviderSession* session)
{
    if (event.eventType() == Event::SESSION_STATUS) {
        printMessages(event);
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            if (msg.messageType() == SESSION_TERMINATED) {
                g_running = false;
            }
        }
    }
    else if (event.eventType() == Event::TOPIC_STATUS) {
        TopicList topicList;
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            std::cout << msg << std::endl;
            if (msg.messageType() == TOPIC_SUBSCRIBED) {
                std::string topicStr = msg.getElementAsString("topic");
                MutexGuard guard(&g_mutex);
                MyStreams::iterator it = g_streams.find(topicStr);
                if (it == g_streams.end()) {
                    // TopicList knows how to add an entry based on a
                    // TOPIC_SUBSCRIBED message.
                    topicList.add(msg);
                    it = (g_streams.insert(MyStreams::value_type(
                                     topicStr,
                                     new MyStream(topicStr)))).first;
                }
                it->second->setSubscribedState(true);
                if (it->second->isAvailable()) {
                    ++g_availableTopicCount;
                }
            }
            else if (msg.messageType() == TOPIC_UNSUBSCRIBED) {
                std::string topicStr = msg.getElementAsString("topic");
                MutexGuard guard(&g_mutex);
                MyStreams::iterator it = g_streams.find(topicStr);
                if (it == g_streams.end()) {
                    // we should never be coming here. TOPIC_UNSUBSCRIBED can
                    // not come before a TOPIC_SUBSCRIBED or TOPIC_CREATED
                    continue;
                }
                if (it->second->isAvailable()) {
                    --g_availableTopicCount;
                }
                it->second->setSubscribedState(false);
            }
            else if (msg.messageType() == TOPIC_CREATED) {
                std::string topicStr = msg.getElementAsString("topic");
                MutexGuard guard(&g_mutex);
                MyStreams::iterator it = g_streams.find(topicStr);
                if (it == g_streams.end()) {
                    it = (g_streams.insert(MyStreams::value_type(
                                     topicStr,
                                     new MyStream(topicStr)))).first;
                }
                try {
                    Topic topic = session->getTopic(msg);
                    it->second->setTopic(topic);
                } catch (blpapi::Exception &e) {
                    std::cerr
                        << "Exception in Session::getTopic(): "
                        << e.description()
                        << std::endl;
                    continue;
                }
                if (it->second->isAvailable()) {
                    ++g_availableTopicCount;
                }
            }
            else if (msg.messageType() == TOPIC_RECAP) {
                // Here we send a recap in response to a Recap request.
                try {
                    std::string topicStr = msg.getElementAsString("topic");
                    MyStreams::iterator it = g_streams.find(topicStr);
                    MutexGuard guard(&g_mutex);
                    if (it == g_streams.end() || !it->second->isAvailable()) {
                        continue;
                    }
                    Topic topic = session->getTopic(msg);
                    Service service = topic.service();
                    CorrelationId recapCid = msg.correlationId();

                    Event recapEvent = service.createPublishEvent();
                    EventFormatter eventFormatter(recapEvent);
                    eventFormatter.appendRecapMessage(topic, &recapCid);
                    eventFormatter.setElement("numRows", 25);
                    eventFormatter.setElement("numCols", 80);
                    eventFormatter.pushElement("rowUpdate");
                    for (int i = 1; i < 6; ++i) {
                        eventFormatter.appendElement();
                        eventFormatter.setElement("rowNum", i);
                        eventFormatter.pushElement("spanUpdate");
                        eventFormatter.appendElement();
                        eventFormatter.setElement("startCol", 1);
                        eventFormatter.setElement("length", 10);
                        eventFormatter.setElement("text", "RECAP");
                        eventFormatter.popElement();
                        eventFormatter.popElement();
                        eventFormatter.popElement();
                    }
                    eventFormatter.popElement();
                    guard.release()->unlock();
                    session->publish(recapEvent);
                } catch (blpapi::Exception &e) {
                    std::cerr
                        << "Exception in Session::getTopic(): "
                        << e.description()
                        << std::endl;
                    continue;
                }
            }
        }
        if (topicList.size()) {
            // createTopicsAsync will result in RESOLUTION_STATUS,
            // TOPIC_CREATED events.
            session->createTopicsAsync(topicList);
        }
    }
    else if (event.eventType() == Event::RESOLUTION_STATUS) {
        printMessages(event);
    }
    else if (event.eventType() == Event::REQUEST) {
        Service service = session->getService(d_serviceName.c_str());
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            msg.print(std::cout);
            if (msg.messageType() == PERMISSION_REQUEST) {
                // This example always sends a 'PERMISSIONED' response.
                // See 'MktdataPublisherExample' on how to parse a Permission
                // request and send an appropriate 'PermissionResponse'.
                Event response = service.createResponseEvent(
                                                          msg.correlationId());
                int permission = 0; // ALLOWED: 0, DENIED: 1
                EventFormatter ef(response);
                ef.appendResponse("PermissionResponse");
                ef.pushElement("topicPermissions");
                // For each of the topics in the request, add an entry
                // to the response
                Element topicsElement = msg.getElement(TOPICS);
                for (size_t i = 0; i < topicsElement.numValues(); ++i) {
                    ef.appendElement();
                    ef.setElement("topic", topicsElement.getValueAsString(i));
                    ef.setElement("result", permission); //PERMISSIONED
                    ef.popElement();
                }
                ef.popElement();
                session->sendResponse(response);
            }
        }
    }
    else {
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            MutexGuard guard(&g_lock);
            if (g_authorizationStatus.find(msg.correlationId()) !=
                    g_authorizationStatus.end()) {
                if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                    g_authorizationStatus[msg.correlationId()] = AUTHORIZED;
                }
                else {
                    g_authorizationStatus[msg.correlationId()] = FAILED;
                }
            }
            msg.print(std::cout);
        }
    }

    return true;
}

string d_hosts;
int d_port;
int d_priority;
string d_service;
string d_groupId;
string d_authOptions;

void printUsage()
{
    writefln("Publish on a topic. \n"
         "Usage:\n" 
         "\t[-ip   <ipAddress>]  \tserver name or IP (default: localhost)\n"
         "\t[-p    <tcpPort>]    \tserver port (default: 8194)\n"
         "\t[-s    <service>]    \tservice name (default: //viper/page)\n"
         "\t[-g    <groupId>]    \tpublisher groupId (defaults to unique value)\n"
         "\t[-pri  <priority>]   \tset publisher priority level (default: 10)\n"
         "\t[-auth <option>]     \tauthentication option: user|none|app=<app>|userapp=<app>|dir=<property> (default: user)\n");
}

bool parseCommandLine(string[] argv)
{
    foreach(i;1.. argv.length)
    {
        if (!std::strcmp(argv[i], "-ip") && i + 1 < argc)
            d_hosts.push_back(argv[++i]);
        else if (!std::strcmp(argv[i], "-p") &&  i + 1 < argc)
            d_port = std::atoi(argv[++i]);
        else if (!std::strcmp(argv[i], "-s") &&  i + 1 < argc)
            d_service = argv[++i];
        else if (!std::strcmp(argv[i],"-g") && i + 1 < argc)
            d_groupId = argv[++i];
        else if (!std::strcmp(argv[i],"-pri") && i + 1 < argc)
            d_priority = std::atoi(argv[++i]);
        else if (!std::strcmp(argv[i], "-auth") && i + 1 < argc) {
            ++ i;
            if (!std::strcmp(argv[i], AUTH_OPTION_NONE)) {
                d_authOptions.clear();
            }
            else if (strncmp(argv[i], AUTH_OPTION_APP, strlen(AUTH_OPTION_APP)) == 0) {
                d_authOptions.clear();
                d_authOptions.append(AUTH_APP_PREFIX);
                d_authOptions.append(argv[i] + strlen(AUTH_OPTION_APP));
            }
            else if (strncmp(argv[i], AUTH_OPTION_USER_APP, strlen(AUTH_OPTION_USER_APP)) == 0) {
                d_authOptions.clear();
                d_authOptions.append(AUTH_USER_APP_PREFIX);
                d_authOptions.append(argv[i] + strlen(AUTH_OPTION_USER_APP));
            }
            else if (strncmp(argv[i], AUTH_OPTION_DIR, strlen(AUTH_OPTION_DIR)) == 0) {
                d_authOptions.clear();
                d_authOptions.append(AUTH_DIR_PREFIX);
                d_authOptions.append(argv[i] + strlen(AUTH_OPTION_DIR));
            }
            else if (!std::strcmp(argv[i], AUTH_OPTION_USER)) {
                d_authOptions.assign(AUTH_USER);
            }
            else {
                printUsage();
                return false;
            }
        }
        else {
            printUsage();
            return false;
        }
    }

    if (d_hosts.size() == 0) {
        d_hosts.push_back("localhost");
    }

    return true;
}

PagePublisherExample()
    : d_port(8194)
    , d_service("//viper/page")
    , d_authOptions(AUTH_USER)
    , d_priority(10)
{
}

bool authorize(const Service &authService,
               Identity *providerIdentity,
               ProviderSession *session,
               const CorrelationId &cid)
{
    {
        MutexGuard guard(&g_lock);
        g_authorizationStatus[cid] = WAITING;
    }
    EventQueue tokenEventQueue;
    session->generateToken(CorrelationId(), &tokenEventQueue);
    std::string token;
    Event event = tokenEventQueue.nextEvent();
    if (event.eventType() == Event::TOKEN_STATUS ||
        event.eventType() == Event::REQUEST_STATUS) {
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            {
                MutexGuard guard(&g_lock);
                msg.print(std::cout);
            }
            if (msg.messageType() == TOKEN_SUCCESS) {
                token = msg.getElementAsString(TOKEN);
            }
            else if (msg.messageType() == TOKEN_FAILURE) {
                break;
            }
        }
    }
    if (token.length() == 0) {
        MutexGuard guard(&g_lock);
        std::cout << "Failed to get token" << std::endl;
        return false;
    }

    Request authRequest = authService.createAuthorizationRequest();
    authRequest.set(TOKEN, token.c_str());

    session->sendAuthorizationRequest(
        authRequest,
        providerIdentity,
        cid);

    time_t startTime = time(0);
    const int WAIT_TIME_SECONDS = 10;
    while (true) {
        {
            MutexGuard guard(&g_lock);
            if (WAITING != g_authorizationStatus[cid]) {
                return AUTHORIZED == g_authorizationStatus[cid];
            }
        }
        time_t endTime = time(0);
        if (endTime - startTime > WAIT_TIME_SECONDS) {
            return false;
        }
        SLEEP(1);
    }
}

void run(int argc, char **argv)
{
    if (!parseCommandLine(argc, argv))
        return;

    SessionOptions sessionOptions;
    for (size_t i = 0; i < d_hosts.size(); ++i) {
        sessionOptions.setServerAddress(d_hosts[i].c_str(), d_port, i);
    }
    sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
    sessionOptions.setAutoRestartOnDisconnection(true);
    sessionOptions.setNumStartAttempts(d_hosts.size());

    std::cout << "Connecting to port " << d_port
              << " on ";
    std::copy(d_hosts.begin(),
              d_hosts.end(),
              std::ostream_iterator<std::string>(std::cout, " "));
    std::cout << std::endl;

    MyEventHandler myEventHandler(d_service);
    ProviderSession session(sessionOptions, &myEventHandler, 0);
    if (!session.start()) {
        std::cerr <<"Failed to start session." << std::endl;
        return;
    }

    Identity providerIdentity = session.createIdentity();
    if (!d_authOptions.empty()) {
        bool isAuthorized = false;
        const char* authServiceName = "//blp/apiauth";
        if (session.openService(authServiceName)) {
            Service authService = session.getService(authServiceName);
            isAuthorized = authorize(authService, &providerIdentity,
                    &session, CorrelationId((void *)"auth"));
        }
        if (!isAuthorized) {
            std::cerr << "No authorization" << std::endl;
            return;
        }
    }

    ServiceRegistrationOptions serviceOptions;
    serviceOptions.setGroupId(d_groupId.c_str(), d_groupId.size());
    serviceOptions.setServicePriority(d_priority);
    if (!session.registerService(d_service.c_str(), providerIdentity, serviceOptions)) {
        std::cerr <<"Failed to register " << d_service << std::endl;
        return;
    }

    Service service = session.getService(d_service.c_str());

    // Now we will start publishing
    int value=1;
    while (g_running) {
        Event event = service.createPublishEvent();
        {
            MutexGuard guard(&g_mutex);
            if (0 == g_availableTopicCount) {
                guard.release()->unlock();
                SLEEP(1);
                continue;
            }

            EventFormatter eventFormatter(event);
            for (MyStreams::iterator iter = g_streams.begin();
                iter != g_streams.end(); ++iter) {
                if (!iter->second->isAvailable()) {
                    continue;
                }
                std::ostringstream os;
                os << ++value;

                if (!iter->second->isInitialPaintSent()) {
                    eventFormatter.appendRecapMessage(
                                                    iter->second->topic());
                    eventFormatter.setElement("numRows", 25);
                    eventFormatter.setElement("numCols", 80);
                    eventFormatter.pushElement("rowUpdate");
                    for (int i = 1; i < 6; ++i) {
                        eventFormatter.appendElement();
                        eventFormatter.setElement("rowNum", i);
                        eventFormatter.pushElement("spanUpdate");
                        eventFormatter.appendElement();
                        eventFormatter.setElement("startCol", 1);
                        eventFormatter.setElement("length", 10);
                        eventFormatter.setElement("text", "INITIAL");
                        eventFormatter.setElement("fgColor", "RED");
                        eventFormatter.popElement();
                        eventFormatter.popElement();
                        eventFormatter.popElement();
                    }
                    eventFormatter.popElement();
                    iter->second->setIsInitialPaintSent(true);
                }

                eventFormatter.appendMessage("RowUpdate",
                                             iter->second->topic());
                eventFormatter.setElement("rowNum", 1);
                eventFormatter.pushElement("spanUpdate");
                eventFormatter.appendElement();
                Name START_COL("startCol");
                eventFormatter.setElement(START_COL, 1);
                eventFormatter.setElement("length", int(os.str().size()));
                eventFormatter.setElement("text", os.str().c_str());
                eventFormatter.popElement();
                eventFormatter.popElement();
            }
        }

        printMessages(event);
        session.publish(event);
        SLEEP(10);
    }
    session.stop();
}

int main(int argc, char **argv)
{
    std::cout << "PagePublisherExample" << std::endl;
    PagePublisherExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description() << std::endl;
    }
    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

extern (C)
{

    struct bbgstruct
    {
        const Name SECURITY_DATA("securityData");
        const Name SECURITY("security");
        const Name FIELD_DATA("fieldData");
        const Name RESPONSE_ERROR("responseError");
        const Name SECURITY_ERROR("securityError");
        const Name FIELD_EXCEPTIONS("fieldExceptions");
        const Name FIELD_ID("fieldId");
        const Name ERROR_INFO("errorInfo");
        const Name CATEGORY("category");
        const Name MESSAGE("message");
        const Name REASON("reason");
        const Name SESSION_TERMINATED("SessionTerminated");
        const Name SESSION_STARTUP_FAILURE("SessionStartupFailure");
    };

    extern "C" void loggingCallback(blpapi_UInt64_t threadId, int severity, blpapi_Datetime_t  timestamp, const char        *category, const char        *message);

    void loggingCallback(blpapi_UInt64_t    threadId, int                severity, blpapi_Datetime_t  timestamp, const char        *category, const char        *message)
    {
        std::string severityString;
        switch(severity) {
        // The following cases will not happen if callback registered at OFF
        case blpapi_Logging_SEVERITY_FATAL:
        {
            severityString = "FATAL";
        } break;
        // The following cases will not happen if callback registered at FATAL
        case blpapi_Logging_SEVERITY_ERROR:
        {
            severityString = "ERROR";
        } break;
        // The following cases will not happen if callback registered at ERROR
        case blpapi_Logging_SEVERITY_WARN:
        {
            severityString = "WARN";
        } break;
        // The following cases will not happen if callback registered at WARN
        case blpapi_Logging_SEVERITY_INFO:
        {
            severityString = "INFO";
        } break;
        // The following cases will not happen if callback registered at INFO
        case blpapi_Logging_SEVERITY_DEBUG:
        {
            severityString = "DEBUG";
        } break;
        // The following case will not happen if callback registered at DEBUG
        case blpapi_Logging_SEVERITY_TRACE:
        {
            severityString = "TRACE";
        } break;

        };
        std::stringstream sstream;
        sstream << category <<" [" << severityString << "] Thread ID = "
                << threadId << ": " << message << std::endl;
        std::cout << sstream.str() << std::endl;;
    }

    class RefDataExample
    {
        std::string              d_host;
        int                      d_port;
        std::vector<std::string> d_securities;
        std::vector<std::string> d_fields;

        bool parseCommandLine(int argc, char **argv)
        {
            int verbosityCount = 0;
            for (int i = 1; i < argc; ++i) {
                if (!std::strcmp(argv[i],"-s") && i + 1 < argc) {
                    d_securities.push_back(argv[++i]);
                } else if (!std::strcmp(argv[i],"-f") && i + 1 < argc) {
                    d_fields.push_back(argv[++i]);
                } else if (!std::strcmp(argv[i],"-ip") && i + 1 < argc) {
                    d_host = argv[++i];
                } else if (!std::strcmp(argv[i],"-p") &&  i + 1 < argc) {
                    d_port = std::atoi(argv[++i]);
                } else if (!std::strcmp(argv[i],"-v")) {
                    ++verbosityCount;

                } else {
                    printUsage();
                    return false;
                }
            }
            if(verbosityCount) {
                registerCallback(verbosityCount);
            }
            // handle default arguments
            if (d_securities.size() == 0) {
                d_securities.push_back("IBM US Equity");
            }

            if (d_fields.size() == 0) {
                d_fields.push_back("PX_LAST");
            }

            return true;
        }

        void printErrorInfo(const char *leadingStr, const Element &errorInfo)
        {
            std::cout << leadingStr
                << errorInfo.getElementAsString(CATEGORY)
                << " ("
                << errorInfo.getElementAsString(MESSAGE)
                << ")" << std::endl;
        }

void printUsage()
{
    writefln("Usage:\n"
         "    Retrieve reference data \n" 
         "        [-s         <security   = IBM US Equity>\n" 
         "        [-f         <field      = PX_LAST>\n" 
         "        [-ip        <ipAddress  = localhost>\n" 
         "        [-p         <tcpPort    = 8194>\n" 
         "        [-v         increase verbosity\n"
         " (can be specified more than once)\n");
}


        void registerCallback(int verbosityCount)
        {
            blpapi_Logging_Severity_t severity = blpapi_Logging_SEVERITY_OFF;
            switch(verbosityCount) {
              case 1: {
                  severity = blpapi_Logging_SEVERITY_INFO;
              }break;
              case 2: {
                  severity = blpapi_Logging_SEVERITY_DEBUG;
              }break;
              default: {
                  severity = blpapi_Logging_SEVERITY_TRACE;
              }
            };
            blpapi_Logging_registerCallback(loggingCallback,
                                            severity);
        }

        // return true if processing is completed, false otherwise
        void processResponseEvent(Event event)
        {
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (msg.asElement().hasElement(RESPONSE_ERROR)) {
                    printErrorInfo("REQUEST FAILED: ",
                        msg.getElement(RESPONSE_ERROR));
                    continue;
                }

                Element securities = msg.getElement(SECURITY_DATA);
                size_t numSecurities = securities.numValues();
                std::cout << "Processing " << (unsigned int)numSecurities
                          << " securities:"<< std::endl;
                for (size_t i = 0; i < numSecurities; ++i) {
                    Element security = securities.getValueAsElement(i);
                    std::string ticker = security.getElementAsString(SECURITY);
                    std::cout << "\nTicker: " + ticker << std::endl;
                    if (security.hasElement(SECURITY_ERROR)) {
                        printErrorInfo("\tSECURITY FAILED: ",
                            security.getElement(SECURITY_ERROR));
                        continue;
                    }

                    if (security.hasElement(FIELD_DATA)) {
                        const Element fields = security.getElement(FIELD_DATA);
                        if (fields.numElements() > 0) {
                            std::cout << "FIELD\t\tVALUE"<<std::endl;
                            std::cout << "-----\t\t-----"<< std::endl;
                            size_t numElements = fields.numElements();
                            for (size_t j = 0; j < numElements; ++j) {
                                Element field = fields.getElement(j);
                                std::cout << field.name() << "\t\t" <<
                                    field.getValueAsString() << std::endl;
                            }
                        }
                    }
                    std::cout << std::endl;
                    Element fieldExceptions = security.getElement(
                                                                 FIELD_EXCEPTIONS);
                    if (fieldExceptions.numValues() > 0) {
                        std::cout << "FIELD\t\tEXCEPTION" << std::endl;
                        std::cout << "-----\t\t---------" << std::endl;
                        for (size_t k = 0; k < fieldExceptions.numValues(); ++k) {
                            Element fieldException =
                                fieldExceptions.getValueAsElement(k);
                            Element errInfo = fieldException.getElement(
                                                                       ERROR_INFO);
                            std::cout
                                     << fieldException.getElementAsString(FIELD_ID)
                                     << "\t\t"
                                     << errInfo.getElementAsString(CATEGORY)
                                     << " ( "
                                     << errInfo.getElementAsString(MESSAGE)
                                     << ")"
                                     << std::endl;
                        }
                    }
                }
            }
        }


} // extern (C)

int main(string[] argv)
{
    writefln("RefDataExample");
    RefDataExample example;
    try {
        example.run(argv);
    } catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description() << std::endl;
    }
    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

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

        void eventLoop(Session &session)
        {
            bool done = false;
            while (!done) {
                Event event = session.nextEvent();
                if (event.eventType() == Event::PARTIAL_RESPONSE) {
                    std::cout << "Processing Partial Response" << std::endl;
                    processResponseEvent(event);
                }
                else if (event.eventType() == Event::RESPONSE) {
                    std::cout << "Processing Response" << std::endl;
                    processResponseEvent(event);
                    done = true;
                } else {
                    MessageIterator msgIter(event);
                    while (msgIter.next()) {
                        Message msg = msgIter.message();
                        if (event.eventType() == Event::REQUEST_STATUS) {
                            std::cout << "REQUEST FAILED: " << msg.getElement(REASON) << std::endl;
                            done = true;
                        }
                        else if (event.eventType() == Event::SESSION_STATUS) {
                            if (msg.messageType() == SESSION_TERMINATED ||
                                msg.messageType() == SESSION_STARTUP_FAILURE) {
                                done = true;
                            }
                        }
                    }
                }
            }
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
using namespace BloombergLP;
using namespace blpapi;

namespace {
    const Name SECURITY_DATA("securityData");
    const Name SECURITY("security");
    const Name FIELD_DATA("fieldData");
    const Name FIELD_EXCEPTIONS("fieldExceptions");
    const Name FIELD_ID("fieldId");
    const Name ERROR_INFO("errorInfo");
}

class RefDataTableOverrideExample
{
    std::string         d_host;
    int                 d_port;

    void printUsage()
    {
        std::cout << "Usage:" << std::endl
            << "    Retrieve reference data " << std::endl
            << "        [-ip        <ipAddress  = localhost>" << std::endl
            << "        [-p         <tcpPort    = 8194>" << std::endl;
    }

    bool parseCommandLine(int argc, char **argv)
    {
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i],"-ip") && i + 1 < argc) {
                d_host = argv[++i];
            } else if (!std::strcmp(argv[i],"-p") &&  i + 1 < argc) {
                d_port = std::atoi(argv[++i]);
            } else {
                printUsage();
                return false;
            }
        }
        return true;
    }

    void processMessage(Message &msg)
    {
        Element securityDataArray = msg.getElement(SECURITY_DATA);
        int numSecurities = securityDataArray.numValues();
        for (int i = 0; i < numSecurities; ++i) {
            Element securityData = securityDataArray.getValueAsElement(i);
            std::cout << securityData.getElementAsString(SECURITY)
                      << std::endl;
            const Element fieldData = securityData.getElement(FIELD_DATA);
            for (size_t j = 0; j < fieldData.numElements(); ++j) {
                Element field = fieldData.getElement(j);
                if (!field.isValid()) {
                    std::cout << field.name() <<  " is NULL." << std::endl;
                } else if (field.isArray()) {
                    // The following illustrates how to iterate over complex
                    // data returns.
                    for (int i = 0; i < field.numValues(); ++i) {
                        Element row = field.getValueAsElement(i);
                        std::cout << "Row " << i << ": " << row << std::endl;
                    }
                } else {
                    std::cout << field.name() << " = "
                        << field.getValueAsString() << std::endl;
                }
            }

            Element fieldExceptionArray =
                securityData.getElement(FIELD_EXCEPTIONS);
            for (size_t k = 0; k < fieldExceptionArray.numValues(); ++k) {
                Element fieldException =
                    fieldExceptionArray.getValueAsElement(k);
                std::cout <<
                    fieldException.getElement(ERROR_INFO).getElementAsString(
                    "category")
                    << ": " << fieldException.getElementAsString(FIELD_ID);
            }
            std::cout << std::endl;
        }
    }

  public:

    void run(int argc, char **argv)
    {
        d_host = "localhost";
        d_port = 8194;
        if (!parseCommandLine(argc, argv)) return;

        SessionOptions sessionOptions;
        sessionOptions.setServerHost(d_host.c_str());
        sessionOptions.setServerPort(d_port);

        std::cout << "Connecting to " <<  d_host << ":"
                  << d_port << std::endl;
        Session session(sessionOptions);
        if (!session.start()) {
            std::cerr <<"Failed to start session." << std::endl;
            return;
        }
        if (!session.openService("//blp/refdata")) {
            std::cerr <<"Failed to open //blp/refdata" << std::endl;
            return;
        }

        Service refDataService = session.getService("//blp/refdata");
        Request request = refDataService.createRequest("ReferenceDataRequest");

        // Add securities to request.

        request.append("securities", "CWHL 2006-20 1A1 Mtge");
        // ...

        // Add fields to request. Cash flow is a table (data set) field.

        request.append("fields", "MTG_CASH_FLOW");
        request.append("fields", "SETTLE_DT");

        // Add scalar overrides to request.

        Element overrides = request.getElement("overrides");
        Element override1 = overrides.appendElement();
        override1.setElement("fieldId", "ALLOW_DYNAMIC_CASHFLOW_CALCS");
        override1.setElement("value", "Y");
        Element override2 = overrides.appendElement();
        override2.setElement("fieldId", "LOSS_SEVERITY");
        override2.setElement("value", 31);

        // Add table overrides to request.

        Element tableOverrides = request.getElement("tableOverrides");
        Element tableOverride = tableOverrides.appendElement();
        tableOverride.setElement("fieldId", "DEFAULT_VECTOR");
        Element rows = tableOverride.getElement("row");

        // Layout of input table is specified by the definition of
        // 'DEFAULT_VECTOR'. Attributes are specified in the first rows.
        // Subsequent rows include rate, duration, and transition.

        Element row = rows.appendElement();
        Element cols = row.getElement("value");
        cols.appendValue("Anchor");  // Anchor type
        cols.appendValue("PROJ");    // PROJ = Projected
        row = rows.appendElement();
        cols = row.getElement("value");
        cols.appendValue("Type");    // Type of default
        cols.appendValue("CDR");     // CDR = Conditional Default Rate

        struct RateVector {
            float       rate;
            int         duration;
            const char *transition;
        } rateVectors[] = {
            { 1.0, 12, "S" },  // S = Step
            { 2.0, 12, "R" }   // R = Ramp
        };

        for (int i = 0; i < sizeof(rateVectors)/sizeof(rateVectors[0]); ++i)
        {
            const RateVector& rateVector = rateVectors[i];

            row = rows.appendElement();
            cols = row.getElement("value");
            cols.appendValue(rateVector.rate);
            cols.appendValue(rateVector.duration);
            cols.appendValue(rateVector.transition);
        }

        std::cout << "Sending Request: " << request << std::endl;
        CorrelationId cid(this);
        session.sendRequest(request, cid);

        while (true) {
            Event event = session.nextEvent();
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (msg.correlationId() == cid) {
                    // Process the response generically.
                    processMessage(msg);
                }
            }
            if (event.eventType() == Event::RESPONSE) {
                break;
            }
        }
    }
};

int main(int argc, char **argv)
{
    std::cout << "RefDataTableOverrideExample" << std::endl;
    RefDataTableOverrideExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description() << std::endl;
    }
    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}


using namespace BloombergLP;
using namespace blpapi;

namespace {

Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
Name RESOLUTION_SUCCESS("ResolutionSuccess");
Name SESSION_TERMINATED("SessionTerminated");
Name TOKEN("token");
Name TOKEN_SUCCESS("TokenGenerationSuccess");
Name TOKEN_FAILURE("TokenGenerationFailure");

const std::string AUTH_USER       = "AuthenticationType=OS_LOGON";
const std::string AUTH_APP_PREFIX = "AuthenticationMode=APPLICATION_ONLY;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const std::string AUTH_USER_APP_PREFIX = "AuthenticationMode=USER_AND_APPLICATION;AuthenticationType=OS_LOGON;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const std::string AUTH_DIR_PREFIX = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
const char* AUTH_OPTION_NONE      = "none";
const char* AUTH_OPTION_USER      = "user";
const char* AUTH_OPTION_APP       = "app=";
const char* AUTH_OPTION_USER_APP  = "userapp=";
const char* AUTH_OPTION_DIR       = "dir=";


bool g_running = true;

Mutex     g_mutex;

enum AuthorizationStatus {
    WAITING,
    AUTHORIZED,
    FAILED
};

std::map<CorrelationId, AuthorizationStatus> g_authorizationStatus;

void printMessages(const Event& event)
{
    MessageIterator iter(event);
    while (iter.next()) {
        Message msg = iter.message();
        msg.print(std::cout);
    }
}

double getTimestamp()
{
    timeb curTime;
    ftime(&curTime);
    return curTime.time + ((double)curTime.millitm)/1000;
}

} // namespace {

class MyProviderEventHandler : public ProviderEventHandler
{
    const std::string       d_serviceName;

public:
    MyProviderEventHandler(const std::string &serviceName)
    : d_serviceName(serviceName)
    {}

    bool processEvent(const Event& event, ProviderSession* session);
};

bool MyProviderEventHandler::processEvent(
        const Event& event, ProviderSession* session)
{
    std::cout << std::endl << "Server received an event" << std::endl;
    if (event.eventType() == Event::SESSION_STATUS) {
        printMessages(event);
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            if (msg.messageType() == SESSION_TERMINATED) {
                g_running = false;
            }
        }
    }
    else if (event.eventType() == Event::RESOLUTION_STATUS) {
        printMessages(event);
    }
    else if (event.eventType() == Event::REQUEST) {
        Service service = session->getService(d_serviceName.c_str());
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            msg.print(std::cout);
            if (msg.messageType() == Name("ReferenceDataRequest")) {
                // Similar to createPublishEvent. We assume just one
                // service - d_service. A responseEvent can only be
                // for single request so we can specify the
                // correlationId - which establishes context -
                // when we create the Event.
                if (msg.hasElement("timestamp")) {
                    double requestTime = msg.getElementAsFloat64("timestamp");
                    double latency = getTimestamp() - requestTime;
                    std::cout << "Response latency = "
                              << latency << std::endl;
                }
                Event response = service.createResponseEvent(
                        msg.correlationId());
                EventFormatter ef(response);

                // In appendResponse the string is the name of the
                // operation, the correlationId indicates
                // which request we are responding to.
                ef.appendResponse("ReferenceDataRequest");
                Element securities = msg.getElement("securities");
                Element fields = msg.getElement("fields");
                ef.setElement("timestamp", getTimestamp());
                ef.pushElement("securityData");
                for (size_t i = 0; i < securities.numValues(); ++i) {
                    ef.appendElement();
                    ef.setElement("security", securities.getValueAsString(i));
                    ef.pushElement("fieldData");
                    for (size_t j = 0; j < fields.numValues(); ++j) {
                        ef.appendElement();
                        ef.setElement("fieldId", fields.getValueAsString(j));
                        ef.pushElement("data");
                        ef.setElement("doubleValue", getTimestamp());
                        ef.popElement();
                        ef.popElement();
                    }
                    ef.popElement();
                    ef.popElement();
                }
                ef.popElement();

                // Service is implicit in the Event. sendResponse has a
                // second parameter - partialResponse -
                // that defaults to false.
                session->sendResponse(response);
            }
        }
    }
    else {
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            MutexGuard guard(&g_mutex);
            if (g_authorizationStatus.find(msg.correlationId()) != g_authorizationStatus.end()) {
                if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                    g_authorizationStatus[msg.correlationId()] = AUTHORIZED;
                }
                else {
                    g_authorizationStatus[msg.correlationId()] = FAILED;
                }
            }
        }
        printMessages(event);
    }

    return true;
}

class MyRequesterEventHandler : public EventHandler
{

public:
    MyRequesterEventHandler()
    {}

    bool processEvent(const Event& event, Session *session);
};

bool MyRequesterEventHandler::processEvent(
        const Event& event, Session *session)
{
    std::cout << std::endl << "Client received an event" << std::endl;
    MessageIterator iter(event);
    while (iter.next()) {
        Message msg = iter.message();
        MutexGuard guard(&g_mutex);
        msg.print(std::cout);
        if (g_authorizationStatus.find(msg.correlationId()) !=
                g_authorizationStatus.end()) {
            if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                g_authorizationStatus[msg.correlationId()] = AUTHORIZED;
            }
            else {
                g_authorizationStatus[msg.correlationId()] = FAILED;
            }
        }
    }
    return true;
}

class RequestServiceExample
{
    enum Role {
        SERVER,
        CLIENT,
        BOTH
    };
    std::vector<std::string> d_hosts;
    int                      d_port;
    std::string              d_service;
    std::string              d_authOptions;
    Role                     d_role;

    std::vector<std::string> d_securities;
    std::vector<std::string> d_fields;

    void printUsage()
    {
        std::cout
            << "Usage:" << std::endl
            << "\t[-ip   <ipAddress>]  \tserver name or IP (default: localhost)" << std::endl
            << "\t[-p    <tcpPort>]    \tserver port (default: 8194)" << std::endl
            << "\t[-auth <option>]     \tauthentication option: user|none|app=<app>|userapp=<app>|dir=<property> (default: user)" << std::endl
            << "\t[-s    <security>]   \trequest security for client (default: IBM US Equity)" << std::endl
            << "\t[-f    <field>]      \trequest field for client (default: PX_LAST)" << std::endl
            << "\t[-r    <option>]     \tservice role option: server|client|both (default: both)" << std::endl;
    }

    bool parseCommandLine(int argc, char **argv)
    {
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i],"-ip") && i + 1 < argc)
                d_hosts.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-p") && i + 1 < argc)
                d_port = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i],"-s") && i + 1 < argc)
                d_securities.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-f") && i + 1 < argc)
                d_fields.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-r") && i + 1 < argc) {
                ++ i;
                if (!std::strcmp(argv[i], "server")) {
                    d_role = SERVER;
                }
                else if (!std::strcmp(argv[i], "client")) {
                    d_role = CLIENT;
                }
                else if (!std::strcmp(argv[i], "both")) {
                    d_role = BOTH;
                }
                else {
                    printUsage();
                    return false;
                }
            }
            else if (!std::strcmp(argv[i], "-auth") && i + 1 < argc) {
                ++ i;
                if (!std::strcmp(argv[i], AUTH_OPTION_NONE)) {
                    d_authOptions.clear();
                }
                else if (strncmp(argv[i], AUTH_OPTION_APP, strlen(AUTH_OPTION_APP)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_APP_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_APP));
                }
                else if (strncmp(argv[i], AUTH_OPTION_USER_APP, strlen(AUTH_OPTION_USER_APP)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_USER_APP_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_USER_APP));
                }
                else if (strncmp(argv[i], AUTH_OPTION_DIR, strlen(AUTH_OPTION_DIR)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_DIR_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_DIR));
                }
                else if (!std::strcmp(argv[i], AUTH_OPTION_USER)) {
                    d_authOptions.assign(AUTH_USER);
                }
                else {
                    printUsage();
                    return false;
                }
            }
            else {
                printUsage();
                return false;
            }
        }

        if (d_hosts.size() == 0) {
            d_hosts.push_back("localhost");
        }
        if (d_securities.size() == 0) {
            d_securities.push_back("IBM US Equity");
        }

        if (d_fields.size() == 0) {
            d_fields.push_back("PX_LAST");
        }
        return true;
    }

public:

    RequestServiceExample()
        : d_port(8194)
        , d_service("//example/refdata")
        , d_authOptions(AUTH_USER)
        , d_role(BOTH)
    {
    }

bool authorize(const Service &authService,
               Identity *providerIdentity,
               AbstractSession *session,
               const CorrelationId &cid)
{
    {
        MutexGuard guard(&g_mutex);
        g_authorizationStatus[cid] = WAITING;
    }
    EventQueue tokenEventQueue;
    session->generateToken(CorrelationId(), &tokenEventQueue);
    std::string token;
    Event event = tokenEventQueue.nextEvent();
    if (event.eventType() == Event::TOKEN_STATUS) {
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            msg.print(std::cout);
            if (msg.messageType() == TOKEN_SUCCESS) {
                token = msg.getElementAsString(TOKEN);
            }
            else if (msg.messageType() == TOKEN_FAILURE) {
                break;
            }
        }
    }
    if (token.length() == 0) {
        std::cout << "Failed to get token" << std::endl;
        return false;
    }

    Request authRequest = authService.createAuthorizationRequest();
    authRequest.set(TOKEN, token.c_str());

    session->sendAuthorizationRequest(
        authRequest,
        providerIdentity,
        cid);

    time_t startTime = time(0);
    const int WAIT_TIME_SECONDS = 10;
    while (true) {
        {
            MutexGuard guard(&g_mutex);
            if (WAITING != g_authorizationStatus[cid]) {
                return AUTHORIZED == g_authorizationStatus[cid];
            }
        }
        time_t endTime = time(0);
        if (endTime - startTime > WAIT_TIME_SECONDS) {
            return false;
        }
        SLEEP(1);
    }
}


void serverRun(ProviderSession *providerSession)
{
    ProviderSession& session = *providerSession;
    std::cout << "Server is starting------" << std::endl;
    if (!session.start()) {
        std::cerr << "Failed to start server session." << std::endl;
        return;
    }

    Identity providerIdentity = session.createIdentity();
    if (!d_authOptions.empty()) {
        bool isAuthorized = false;
        const char* authServiceName = "//blp/apiauth";
        if (session.openService(authServiceName)) {
            Service authService = session.getService(authServiceName);
            isAuthorized = authorize(authService, &providerIdentity,
                    &session, CorrelationId((void *)"sauth"));
        }
        if (!isAuthorized) {
            std::cerr << "No authorization" << std::endl;
            return;
        }
    }

    if (!session.registerService(d_service.c_str(), providerIdentity)) {
        std::cerr <<"Failed to register " << d_service << std::endl;
        return;
    }
}

void clientRun(Session *requesterSession)
{
    Session& session = *requesterSession;
    std::cout << "Client is starting------" << std::endl;
    if (!session.start()) {
        std::cerr <<"Failed to start client session." << std::endl;
        return;
    }

    Identity identity = session.createIdentity();
    if (!d_authOptions.empty()) {
        bool isAuthorized = false;
        const char* authServiceName = "//blp/apiauth";
        if (session.openService(authServiceName)) {
            Service authService = session.getService(authServiceName);
            isAuthorized = authorize(authService, &identity,
                    &session, CorrelationId((void *)"cauth"));
        }
        if (!isAuthorized) {
            std::cerr << "No authorization" << std::endl;
            return;
        }
    }

    if (!session.openService(d_service.c_str())) {
        std::cerr <<"Failed to open " << d_service << std::endl;
        return;
    }

    Service service = session.getService(d_service.c_str());
    Request request = service.createRequest("ReferenceDataRequest");

    // append securities to request
    // Add securities to request
    Element securities = request.getElement("securities");
    for (size_t i = 0; i < d_securities.size(); ++i) {
        securities.appendValue(d_securities[i].c_str());
    }

    // Add fields to request
    Element fields = request.getElement("fields");
    for (size_t i = 0; i < d_fields.size(); ++i) {
        fields.appendValue(d_fields[i].c_str());
    }

    request.set("timestamp", getTimestamp());

    {
        MutexGuard guard(&g_mutex);
        std::cout << "Sending Request: " << request << std::endl;
    }
    EventQueue eventQueue;
    session.sendRequest(request, identity,
            CorrelationId((void *)"AddRequest"), &eventQueue);

    while (true) {
        Event event = eventQueue.nextEvent();
        std::cout << std::endl << "Client received an event" << std::endl;
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            MutexGuard guard(&g_mutex);
            if (event.eventType() == Event::RESPONSE) {
                if (msg.hasElement("timestamp")) {
                    double responseTime = msg.getElementAsFloat64(
                                            "timestamp");
                    std::cout << "Response latency = "
                              << getTimestamp() - responseTime
                              << std::endl;
                }
            }
            msg.print(std::cout) << std::endl;
        }
        if (event.eventType() == Event::RESPONSE) {
            break;
        }
    }
}

void run(string[]argv)
{
    if (!parseCommandLine(argc, argv))
        return;

    SessionOptions sessionOptions;
    foreach(i; 0.. d_hosts.size())
    {
        sessionOptions.setServerAddress(d_hosts[i].c_str(), d_port, i);
    }
    sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
    sessionOptions.setAutoRestartOnDisconnection(true);
    sessionOptions.setNumStartAttempts(d_hosts.size());

    writefln("Connecting to port %s on %s" << d_port, copy(d_hosts.begin(), d_hosts.end(), std::ostream_iterator<std::string>(std::cout, " "));
    std::cout << std::endl;

    MyProviderEventHandler providerEventHandler(d_service);
    ProviderSession providerSession(
            sessionOptions, &providerEventHandler, 0);

    MyRequesterEventHandler requesterEventHandler;
    Session requesterSession(sessionOptions, &requesterEventHandler, 0);

    if (d_role == SERVER || d_role == BOTH) {
        serverRun(&providerSession);
    }
    if (d_role == CLIENT || d_role == BOTH) {
        clientRun(&requesterSession);
    }

    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    if (d_role == SERVER || d_role == BOTH) {
        providerSession.stop();
    }
    if (d_role == CLIENT || d_role == BOTH) {
        requesterSession.stop();
    }
}

int main(int argc, char **argv)
{
    std::cout << "RequestServiceExample" << std::endl;
    RequestServiceExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description() << std::endl;
    }
    return 0;
}


namespace {
    const Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
    const Name TOKEN_SUCCESS("TokenGenerationSuccess");
    const Name TOKEN_ELEMENT("token");
    const Name DESCRIPTION_ELEMENT("description");
    const Name QUERY_ELEMENT("query");
    const Name RESULTS_ELEMENT("results");
    const Name MAX_RESULTS_ELEMENT("maxResults");

    const Name INSTRUMENT_LIST_REQUEST("instrumentListRequest");
    const Name CURVE_LIST_REQUEST("curveListRequest");
    const Name GOVT_LIST_REQUEST("govtListRequest");

    const Name ERROR_RESPONSE("ErrorResponse");
    const Name INSTRUMENT_LIST_RESPONSE("InstrumentListResponse");
    const Name CURVE_LIST_RESPONSE("CurveListResponse");
    const Name GOVT_LIST_RESPONSE("GovtListResponse");

    const Name CATEGORY_ELEMENT("category");
    const Name MESSAGE_ELEMENT("message");

    const Name SESSION_TERMINATED("SessionTerminated");
    const Name SESSION_STARTUP_FAILURE("SessionStartupFailure");
    const Name TOKEN_FAILURE("TokenGenerationFailure");

    const Name SECURITY_ELEMENT("security");

    const Name PARSEKY_ELEMENT("parseky");
    const Name NAME_ELEMENT("name");
    const Name TICKER_ELEMENT("ticker");
    const Name PARTIAL_MATCH_ELEMENT("partialMatch");

    const Name COUNTRY_ELEMENT("country");
    const Name CURRENCY_ELEMENT("currency");
    const Name CURVEID_ELEMENT("curveid");
    const Name TYPE_ELEMENT("type");
    const Name SUBTYPE_ELEMENT("subtype");
    const Name PUBLISHER_ELEMENT("publisher");
    const Name BBGID_ELEMENT("bbgid");

    const std::string AUTH_USER("AuthenticationType=OS_LOGON");
    const std::string AUTH_APP_PREFIX(
                            "AuthenticationMode=APPLICATION_ONLY;"
                            "ApplicationAuthenticationType=APPNAME_AND_KEY;"
                            "ApplicationName=");
    const std::string AUTH_USER_APP_PREFIX(
                            "AuthenticationMode=USER_AND_APPLICATION;"
                            "AuthenticationType=OS_LOGON;"
                            "ApplicationAuthenticationType=APPNAME_AND_KEY;"
                            "ApplicationName=");
    const std::string AUTH_DIR_PREFIX(
                            "AuthenticationType=DIRECTORY_SERVICE;"
                            "DirSvcPropertyName=");
    const char* AUTH_OPTION_NONE("none");
    const char* AUTH_OPTION_USER("user");
    const char* AUTH_OPTION_APP("app=");
    const char* AUTH_OPTION_USER_APP("userapp=");
    const char* AUTH_OPTION_DIR("dir=");

    const char* AUTH_SERVICE("//blp/apiauth");
    const char* INSTRUMENTS_SERVICE("//blp/instruments");

    const char* DEFAULT_HOST("localhost");
    const int   DEFAULT_PORT(8194);
    const int   DEFAULT_MAX_RESULTS(10);
    const char* DEFAULT_QUERY_STRING("IBM");
    const bool  DEFAULT_PARTIAL_MATCH(false);
};

typedef std::map<std::string, std::string> FiltersMap;

std::string    d_host;
int            d_port;
Identity       d_identity;
std::string    d_authOptions;
SessionOptions d_sessionOptions;
int            d_maxResults;
Name           d_requestType;
FiltersMap     d_filters;
std::string    d_query;
bool           d_partialMatch;

void printUsage()
{
    writefln("Usage: SecurityLookupExample [options]\n"
         "\t[-r   \t<requestType> = instrumentListRequest]\n"
         "options:\n" 
         "\trequestType: instrumentListRequest|curveListRequest|\n"
         "govtListRequest\n" 
         "\t[-ip  \t<ipAddress    = localhost>]\n"
         "\t[-p   \t<tcpPort      = 8194>]\n"
         "\t[-s   \t<queryString  = IBM>]\n" 
         "\t[-m   \t<maxResults   = 10>]\n" 
         "\t[-auth\t<authOption>  = none]"
         "\tauthOption: user|none|app=<app>|userapp=<app>|dir=<property>\n"
         "\t[-f   \t<filter=value>]\n" 
         "\tfilter (for different requests):\n" 
         "\t\tinstrumentListRequest:\tyellowKeyFilter|languageOverride \n"
         "(default: none)\n" 
         "\t\tgovtListRequest:      \tticker|partialMatch \n"
         "(default: none)\n"
         "\t\tcurveListRequest:     \n"
         "\tcountryCode|currencyCode|type|subtype|curveid|bbgid \n"
         "(default: none)");
}

void printErrorInfo(const char *leadingStr, const Element &errorInfo)
{
    writefln("%s %s (%s)",leadingStr, errorInfo.getElementAsString(CATEGORY_ELEMENT), errorInfo.getElementAsString(MESSAGE_ELEMENT));
}

void processResponseEvent(const Event& event)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        if (msg.messageType() == INSTRUMENT_LIST_RESPONSE) {
            dumpInstrumentResults("result", msg);
        }
        else if (msg.messageType() == CURVE_LIST_RESPONSE) {
            dumpCurveResults("result", msg);
        }
        else if (msg.messageType() == GOVT_LIST_RESPONSE) {
            dumpGovtResults("result", msg);
        }
        else if (msg.messageType() == ERROR_RESPONSE) {
            string description = msg.getElementAsString(
                                                      DESCRIPTION_ELEMENT);
            stderr.writefln(">>> Received error: %s",description);
        }
        else {
            stderr.writefln(">>> Unexpected response: %s",msg.asElement());
        }
    }
}

void eventLoop(Session* session)
{
    bool done = false;
    while (!done) {
        Event event = session->nextEvent();
        if (event.eventType() == Event::PARTIAL_RESPONSE) {
            writefln(">>> Processing Partial Response:");
            processResponseEvent(event);
        }
        else if (event.eventType() == Event::RESPONSE) {
            writefln(">>> Processing Response");
            processResponseEvent(event);
            done = true;
        } else {
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (event.eventType() == Event::SESSION_STATUS) {
                    if (msg.messageType() == SESSION_TERMINATED ||
                        msg.messageType() ==
                                          SESSION_STARTUP_FAILURE) {
                        done = true;
                    }
                }
            }
        }
    }
}

void initializeSessionOptions()
{
    d_sessionOptions.setServerHost(d_host.c_str());
    d_sessionOptions.setServerPort(d_port);
    d_sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
}

bool authorize(const Service &authService,
              Session *session,
              const CorrelationId &cid)
{
    EventQueue tokenEventQueue;
    session->generateToken(cid, &tokenEventQueue);
    std::string token;
    Event event = tokenEventQueue.nextEvent();
    MessageIterator iter(event);
    if (event.eventType() == Event::TOKEN_STATUS ||
        event.eventType() == Event::REQUEST_STATUS) {
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            msg.print(std::cout);
            if (msg.messageType() == TOKEN_SUCCESS) {
                token = msg.getElementAsString(TOKEN_ELEMENT);
            }
            else if (msg.messageType() == TOKEN_FAILURE) {
                break;
            }
        }
    }
    if (token.length() == 0) {
        std::cout << ">>> Failed to get token" << std::endl;
        return false;
    }

    Request authRequest = authService.createAuthorizationRequest();
    authRequest.set(TOKEN_ELEMENT, token.c_str());

    d_identity = session->createIdentity();
    session->sendAuthorizationRequest(authRequest, &d_identity);

    time_t startTime = time(0);
    const int WAIT_TIME_SECONDS = 10;
    while (true) {
        Event event = session->nextEvent(WAIT_TIME_SECONDS * 1000);
        if (event.eventType() == Event::RESPONSE ||
            event.eventType() == Event::REQUEST_STATUS ||
            event.eventType() == Event::PARTIAL_RESPONSE)
        {
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                msg.print(std::cout);
                if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                    return true;
                }
                else {
                    std::cout << ">>> Authorization failed" << std::endl;
                    return false;
                }
            }
        }
        time_t endTime = time(0);
        if (endTime - startTime > WAIT_TIME_SECONDS) {
            return false;
        }
    }
}

void dumpInstrumentResults(const std::string& msgPrefix,
                           const Message& msg)
{
    const Element& response = msg.asElement();
    const Element& results  = response.getElement(RESULTS_ELEMENT);
    std::cout << ">>> Received " << results.numValues()
              << " elements" << std::endl;

    size_t numElements = results.numValues();

    std::cout << msgPrefix << ' ' << numElements << " results:"
              << std::endl;
    for (size_t i = 0; i < numElements; ++i) {
        Element result = results.getValueAsElement(i);
        std::cout << std::setw(2) << (i + 1) << ": " << std::setw(30)
                  << result.getElementAsString(SECURITY_ELEMENT)
                  << " - "
                  << result.getElementAsString(DESCRIPTION_ELEMENT)
                  << std::endl;
    }
}

void dumpGovtResults(const std::string& msgPrefix, const Message& msg)
{
    const Element& response = msg.asElement();
    const Element& results  = response.getElement(RESULTS_ELEMENT);
    std::cout << ">>> Received " << results.numValues()
              << " elements" << std::endl;

    size_t numElements = results.numValues();

    std::cout << msgPrefix << ' ' << numElements << " results:"
              << std::endl;
    for (size_t i = 0; i < numElements; ++i) {
        Element result = results.getValueAsElement(i);
        std::cout << std::setw(2) << (i + 1) << ": " << std::setw(30)
                  << result.getElementAsString(PARSEKY_ELEMENT)
                  << ", "
                  << result.getElementAsString(NAME_ELEMENT)
                  << " - "
                  << result.getElementAsString(TICKER_ELEMENT)
                  << std::endl;
    }
}

void dumpCurveResults(const std::string& msgPrefix, const Message& msg)
{
    const Element& response = msg.asElement();
    const Element& results  = response.getElement(RESULTS_ELEMENT);
    std::cout << ">>> Received " << results.numValues()
              << " elements" << std::endl;

    size_t numElements = results.numValues();

    std::cout << msgPrefix << ' ' << numElements << " results:"
              << std::endl;
    for (size_t i = 0; i < numElements; ++i) {
        Element result = results.getValueAsElement(i);
        std::cout << std::setw(2) << (i + 1) << ": " << std::setw(30)
                  << " - '"
                  << result.getElementAsString(DESCRIPTION_ELEMENT) << "' "
                  << "country="
                  << result.getElementAsString(COUNTRY_ELEMENT) << " "
                  << "currency="
                  << result.getElementAsString(CURRENCY_ELEMENT) << " "
                  << "curveid="
                  << result.getElementAsString(CURVEID_ELEMENT) << " "
                  << "type="
                  << result.getElementAsString(TYPE_ELEMENT) << " "
                  << "subtype="
                  << result.getElementAsString(SUBTYPE_ELEMENT) << " "
                  << "publisher="
                  << result.getElementAsString(PUBLISHER_ELEMENT) << " "
                  << "bbgid="
                  << result.getElementAsString(BBGID_ELEMENT)
                  << std::endl;
    }
}

bool sendRequest(Session* session)
{
    Service blpinstrService = session->getService(INSTRUMENTS_SERVICE);
    Request request = blpinstrService.createRequest(
                                                d_requestType.string());

    request.asElement().setElement(QUERY_ELEMENT, d_query.c_str());
    request.asElement().setElement(MAX_RESULTS_ELEMENT, d_maxResults);

    for (FiltersMap::iterator it = d_filters.begin();
         it != d_filters.end(); ++it) {
        request.asElement().setElement(it->first.c_str(),
                                       it->second.c_str());
    }

    std::cout << std::endl << ">>> Sending request: " << std::endl;
    request.print(std::cout);

    session->sendRequest(request, d_identity, CorrelationId());

    return true;
}


public:
SecurityLookupExample()
: d_host(DEFAULT_HOST)
, d_port(DEFAULT_PORT)
, d_maxResults(DEFAULT_MAX_RESULTS)
, d_requestType(INSTRUMENT_LIST_REQUEST)
, d_query(DEFAULT_QUERY_STRING)
, d_partialMatch(DEFAULT_PARTIAL_MATCH)
{}

bool parseCommandLine(int argc, char **argv)
{
    for (int i = 1; i < argc; ++i) {
        if (!std::strcmp(argv[i], "-r") && i + 1 < argc) {
            d_requestType = Name(argv[++i]);
            if (d_requestType != INSTRUMENT_LIST_REQUEST &&
                d_requestType != CURVE_LIST_REQUEST &&
                d_requestType != GOVT_LIST_REQUEST) {
                printUsage();
                return false;
                }
        }
        else if (!std::strcmp(argv[i],"-ip") && i + 1 < argc) {
            d_host = argv[++i];
        }
        else if (!std::strcmp(argv[i],"-p") && i + 1 < argc) {
            d_port = std::atoi(argv[++i]);
        }
        else if (!std::strcmp(argv[i],"-s") && i + 1 < argc) {
            d_query = argv[++i];
        }
        else if (!std::strcmp(argv[i], "-m") && i + 1 < argc) {
            d_maxResults = std::atoi(argv[++i]);
        }
        else if (!std::strcmp(argv[i], "-f") && i + 1 < argc) {
            std::string assign(argv[++i]);
            std::string::size_type idx = assign.find_first_of('=');
            d_filters[assign.substr(0, idx)] = assign.substr(idx + 1);
        }
        else if (!std::strcmp(argv[i], "-auth") && i + 1 < argc) {
            ++i;
            if (!std::strcmp(argv[i], AUTH_OPTION_NONE)) {
                d_authOptions.clear();
            }
            else if (strncmp(argv[i],
                             AUTH_OPTION_APP,
                             strlen(AUTH_OPTION_APP)) == 0) {
                d_authOptions.clear();
                d_authOptions.append(AUTH_APP_PREFIX);
                d_authOptions.append(argv[i] + strlen(AUTH_OPTION_APP));
            }
            else if (strncmp(argv[i],
                             AUTH_OPTION_USER_APP,
                             strlen(AUTH_OPTION_USER_APP)) == 0) {
                d_authOptions.clear();
                d_authOptions.append(AUTH_USER_APP_PREFIX);
                d_authOptions.append(
                                argv[i] + strlen(AUTH_OPTION_USER_APP));
            }
            else if (strncmp(argv[i],
                             AUTH_OPTION_DIR,
                             strlen(AUTH_OPTION_DIR)) == 0) {
                d_authOptions.clear();
                d_authOptions.append(AUTH_DIR_PREFIX);
                d_authOptions.append(argv[i] + strlen(AUTH_OPTION_DIR));
            }
            else if (!std::strcmp(argv[i], AUTH_OPTION_USER)) {
                d_authOptions.assign(AUTH_USER);
            }
            else {
                printUsage();
                return false;
            }
        }
        else {
            printUsage();
            return false;
        }
    }
    return true;
}


void run(int argc, char **argv)
{
    if (!parseCommandLine(argc, argv))
        return;

    initializeSessionOptions();

    std::cout << ">>> Connecting to " + d_host + ":" << d_port
              << std::endl;

    Session session(d_sessionOptions);
    if (!session.start()) {
        std::cout << ">>> Failed to start session" << std::endl;
        return;
    }

    if (!d_authOptions.empty()) {
        bool isAuthorized = false;
        const char* authServiceName = AUTH_SERVICE;
        if (session.openService(authServiceName)) {
            Service authService = session.getService(authServiceName);
            isAuthorized = authorize(authService,
                                     &session,
                                     CorrelationId((void*)("auth")));
        }
        if (!isAuthorized) {
            std::cerr << ">>> No authorization" << std::endl;
            return;
        }
    }

    if (!session.openService(INSTRUMENTS_SERVICE)) {
        std::cout << ">>> Failed to open " << INSTRUMENTS_SERVICE
                                           << std::endl;
        return;
    }

    sendRequest(&session);

    try {
        eventLoop(&session);
    } catch (Exception &e) {
        std::cerr << ">>> Exception caught: " << e.description()
                  << std::endl;
    } catch (...) {
        std::cerr << ">>> Unknown exception" << std::endl;
    }

    session.stop();
}

int main(string[] argv)
{
    SecurityLookupExample example;
    try {
        example.run(argc, argv);
    }
    catch (Exception& e) {
        stderr.writefln(">>> Exception caught: %s",e.description());
    }

    writefln("Press ENTER to quit");
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');

    return 0;
}

namespace {
    const Name LAST_PRICE("LAST_PRICE");
}

class MyEventHandler :public EventHandler {
// Process events using callback

public:
bool processEvent(const Event &event, Session *session) {
try {
    if (event.eventType() == Event::SUBSCRIPTION_DATA) {
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            if (msg.hasElement(LAST_PRICE)) {
                Element field = msg.getElement(LAST_PRICE);
                std::cout << field.name() << " = "
                    << field.getValueAsString() << std::endl;
            }
        }
    }
    return true;
} catch (Exception &e) {
    std::cerr << "Library Exception!!! " << e.description()
        << std::endl;
} catch (...) {
    std::cerr << "Unknown Exception!!!" << std::endl;
}
return false;
}
};

class SimpleBlockingRequestExample {

CorrelationId d_cid;
EventQueue d_eventQueue;
string d_host;
int d_port;

void printUsage()
{
    writefln("Usage:\n"
     "    Retrieve reference data \n"
     "        [-ip        <ipAddress  = localhost>\n"
     "        [-p         <tcpPort    = 8194>\n");
}

bool parseCommandLine(string[] argv)
{
foreach(i;1..argv.length)
{
    if ((!argv[i]=="-ip") && (i + 1 < argv.length)) {
        d_host = argv[++i];
        continue;
    }
    if (!(argv[i]=="-p") &&  (i + 1 < argv.length)) {
        d_port = std::atoi(argv[++i]);
        continue;
    }
    printUsage();
    return false;
}
return true;
}

SimpleBlockingRequestExample(): d_cid((int)1) {
}

void run(string[] argv)
{
    d_host = "localhost";
    d_port = 8194;
    if (!parseCommandLine(argc, argv)) return;

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln "Connecting to %s:%s", d_host, d_port);
    Session session(sessionOptions, new MyEventHandler());
    if (!session.start()) {
        stderr.writefln("Failed to start session.");
        return;
    }
    if (!session.openService("//blp/mktdata")) {
        stderr.writefln("Failed to open //blp/mktdata");
        return;
    }
    if (!session.openService("//blp/refdata")) {
        stderr.writefln("Failed to open //blp/refdata");
        return;
    }

    writefln("Subscribing to IBM US Equity");
    SubscriptionList subscriptions;
    subscriptions.add("IBM US Equity", "LAST_PRICE", "", d_cid);
    session.subscribe(subscriptions);

    writefln("Requesting reference data IBM US Equity");
    Service refDataService = session.getService("//blp/refdata");
    Request request = refDataService.createRequest("ReferenceDataRequest");
    request.append("securities", "IBM US Equity");
    request.append("fields", "DS002");

    CorrelationId cid(this);
    session.sendRequest(request, cid, &d_eventQueue);
    while (true) {
    Event event = d_eventQueue.nextEvent();
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        msg.print(std::cout);
    }
    if (event.eventType() == Event::RESPONSE) {
        break;
    }
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
}

int main(string[] argv)
{
    writefln("SimpleBlockingRequestExample");
    SimpleBlockingRequestExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s",e.description());
    }

    return 0;
}

using namespace BloombergLP;
using namespace blpapi;

namespace {
    const Name FIELD_ID("id");
    const Name FIELD_MNEMONIC("mnemonic");
    const Name FIELD_DATA("fieldData");
    const Name FIELD_DESC("description");
    const Name FIELD_INFO("fieldInfo");
    const Name FIELD_ERROR("fieldError");
    const Name FIELD_MSG("message");
    const Name CATEGORY("category");
    const Name CATEGORY_NAME("categoryName");
    const Name CATEGORY_ID("categoryId");
    const Name FIELD_SEARCH_ERROR("fieldSearchError");
};

int ID_LEN;
int MNEMONIC_LEN;
int DESC_LEN;
int CAT_NAME_LEN;
string PADDING;
string APIFLDS_SVC;
string d_host;
int d_port;

void printUsage()
{
  wrtefln("Usage:\n"
       "    Retrieve reference data \n"
       "        [-ip        <ipAddress  = localhost>\n"
       "        [-p         <tcpPort    = 8194>\n"
}

bool parseCommandLine(string[] argv)
{
  for (int i = 1; i < argc; ++i) {
      if (!std::strcmp(argv[i],"-ip") && i + 1 < argc) {
          d_host = argv[++i];
          continue;
      }
      if (!std::strcmp(argv[i],"-p") &&  i + 1 < argc) {
          d_port = std::atoi(argv[++i]);
          continue;
      }
      printUsage();
      return false;
  }
  return true;
}

std::string padString(std::string str, unsigned int width)
{
  if (str.length() >= width || str.length() >= PADDING.length() ) return str;
  else return str ~ PADDING.substr(0, width-str.length());
}

void printField (const Element &field)
{
  string  fldId       = field.getElementAsString(FIELD_ID);
  if (field.hasElement(FIELD_INFO)) {
      Element fldInfo          = field.getElement (FIELD_INFO) ;
      string  fldMnemonic = fldInfo.getElementAsString(FIELD_MNEMONIC);
      string  fldDesc     = fldInfo.getElementAsString(FIELD_DESC);

      writefln("%s %s %s",padString(fldId, ID_LEN), padString (fldMnemonic, MNEMONIC_LEN), padString (fldDesc, DESC_LEN));
  }
  else {
      Element fldError = field.getElement(FIELD_ERROR) ;
      string errorMsg = fldError.getElementAsString(FIELD_MSG) ;

      writefln(" ERROR: %s - %s",fldId, errorMsg);
  }
}

void printHeader ()
{
  writefln("%s %s %s",padString("FIELD ID", ID_LEN), padString("MNEMONIC", MNEMONIC_LEN), padString("DESCRIPTION", DESC_LEN));
  writefln("%s %s %s",padString("-----------", ID_LEN), padString("-----------", MNEMONIC_LEN), padString("-----------", DESC_LEN));
}

SimpleCategorizedFieldSearchExample():
PADDING("                                            "),
    APIFLDS_SVC("//blp/apiflds") {
        ID_LEN         = 13;
        MNEMONIC_LEN   = 36;
        DESC_LEN       = 40;
        CAT_NAME_LEN   = 40;
}

void run(string[] argv)
{
    d_host = "localhost";
    d_port = 8194;
    if (!parseCommandLine(argc, argv)) return;

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s",d_host,  d_port);
    Session session(sessionOptions);
    if (!session.start()) {
        stderr.writefln("Failed to start session.");
        return;
    }
    if (!session.openService(APIFLDS_SVC.c_str())) {
        stderr.writefln("Failed to open %s",APIFLDS_SVC);
        return;
    }

    Service fieldInfoService = session.getService(APIFLDS_SVC.c_str());
    Request request = fieldInfoService.createRequest("CategorizedFieldSearchRequest");
    request.set ("searchSpec", "last price");
    Element exclude = request.getElement("exclude");
    exclude.setElement("fieldType", "Static");
    request.set ("returnFieldDocumentation", false);

    writefln("Sending Request: %s",request);
    session.sendRequest(request, CorrelationId(this));

    while (true) {
        Event event = session.nextEvent();
        if (event.eventType() != Event::RESPONSE &&
            event.eventType() != Event::PARTIAL_RESPONSE) {
                continue;
        }

        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            if (msg.hasElement(FIELD_SEARCH_ERROR)) {
                msg.print(std::cout);
                continue;
            }

            Element categories = msg.getElement("category");
            int numCategories = categories.numValues();

            for (int catIdx=0; catIdx < numCategories; ++catIdx) {

                Element category = categories.getValueAsElement(catIdx);
                string Name = category.getElementAsString("categoryName");
                string Id = category.getElementAsString("categoryId");

                writefln("\n  Category Name:%s\tId:%s",padString (Name, CAT_NAME_LEN),Id);

                Element fields = category.getElement("fieldData");
                int numElements = fields.numValues();

                printHeader();
                for (int i=0; i < numElements; i++) {
                    printField (fields.getValueAsElement(i));
                }
            }
        }
        if (event.eventType() == Event::RESPONSE) {
            break;
        }
    }
}

int main(string[] argv)
{
    SimpleCategorizedFieldSearchExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s",e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

namespace {
    const Name FIELD_ID("id");
    const Name FIELD_MNEMONIC("mnemonic");
    const Name FIELD_DATA("fieldData");
    const Name FIELD_DESC("description");
    const Name FIELD_INFO("fieldInfo");
    const Name FIELD_ERROR("fieldError");
    const Name FIELD_MSG("message");
};

int ID_LEN;
int MNEMONIC_LEN;
int DESC_LEN;
string PADDING;
string APIFLDS_SVC;
string d_host;
int d_port;

void printUsage()
{
    writefln( "Usage:\n"
         "    Retrieve reference data \n"
         "        [-ip        <ipAddress  = localhost>\n"
         "        [-p         <tcpPort    = 8194>\n");
}

bool parseCommandLine(string[] argv)
{
    foreach(i; 1..argv.length)
    {
        if (!(argv[i]=="-ip") && (i + 1 < argv.length)) {
            d_host = argv[++i];
            continue;
        }
        if (!(argv[i]=="-p") &&  (i + 1 < argv.length)) {
            d_port = atoi(argv[++i]);
            continue;
        }
        printUsage();
        return false;
    }
    return true;
}

string padString(string str, uint width)
{
    if (str.length() >= width || str.length() >= PADDING.length() ) return str;
    else return str ~ PADDING.substr(0, width-str.length());
}

void printField (const Element &field)
{
    string  fldId = field.getElementAsString(FIELD_ID);
    if (field.hasElement(FIELD_INFO)) {
        Element fldInfo          = field.getElement (FIELD_INFO) ;
        string  fldMnemonic = fldInfo.getElementAsString(FIELD_MNEMONIC);
        string fldDesc     = fldInfo.getElementAsString(FIELD_DESC);

        writefln("%s %s %s",padString(fldId, ID_LEN),padString(fldMnemonic, MNEMONIC_LEN), padString(fldDesc, DESC_LEN));
         << std::endl;
    }
    else {
        Element fldError = field.getElement(FIELD_ERROR) ;
        string  errorMsg = fldError.getElementAsString(FIELD_MSG) ;

        writefln(" ERROR: %s - %s", fldId, errorMsg);
    }
}
void printHeader ()
{
    writefln("%s %s %s",padString("FIELD ID", ID_LEN),padString("MNEMONIC", MNEMONIC_LEN),padString("DESCRIPTION", DESC_LEN));
    writefln("%s %s %s",padString("-----------", ID_LEN), padString("-----------", MNEMONIC_LEN), padString("-----------", DESC_LEN));
}


public:
SimpleFieldInfoExample():
PADDING("                                            "),
    APIFLDS_SVC("//blp/apiflds") {
        ID_LEN         = 13;
        MNEMONIC_LEN   = 36;
        DESC_LEN       = 40;
}

void run(string[] argv)
{
  d_host = "localhost";
  d_port = 8194;
  if (!parseCommandLine(argc, argv)) return;

  SessionOptions sessionOptions;
  sessionOptions.setServerHost(d_host.c_str());
  sessionOptions.setServerPort(d_port);

  writefln("Connecting to %s:%s",  d_host , d_port);
  Session session(sessionOptions);
  if (!session.start()) {
      stderr.writefln("Failed to start session.");
      return;
  }
  if (!session.openService(APIFLDS_SVC.c_str())) {
      stderr.writefln("Failed to open %s",APIFLDS_SVC);
      return;
  }

  Service fieldInfoService = session.getService(APIFLDS_SVC.c_str());
  Request request = fieldInfoService.createRequest("FieldInfoRequest");
  request.append("id", "LAST_PRICE");
  request.append("id", "pq005");
  request.append("id", "zz0002");

  request.set("returnFieldDocumentation", true);

  writefln("Sending Request: %s" ,request);
  session.sendRequest(request, CorrelationId(this));

  while (true) {
      Event event = session.nextEvent();
      if (event.eventType() != Event::RESPONSE &&
          event.eventType() != Event::PARTIAL_RESPONSE) {
              continue;
      }

      MessageIterator msgIter(event);
      while (msgIter.next()) {
          Message msg = msgIter.message();
          Element fields = msg.getElement("fieldData");
          int numElements = fields.numValues();
          printHeader();
          for (int i=0; i < numElements; i++) {
              printField (fields.getValueAsElement(i));
          }
      }
      if (event.eventType() == Event::RESPONSE) {
          break;
      }
  }
}

int main(string[] argv)
{
    SimpleFieldInfoExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s", e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

string d_host;
int d_port;

const char * APIFLDS_SVC   = "//blp/apiflds";
static std::string PADDING = "                                            ";

namespace {
    const Name FIELD_ID("id");
    const Name FIELD_MNEMONIC("mnemonic");
    const Name FIELD_DATA("fieldData");
    const Name FIELD_DESC("description");
    const Name FIELD_INFO("fieldInfo");
    const Name FIELD_ERROR("fieldError");
    const Name FIELD_MSG("message");
};

enum {
    ID_LEN         = 13,
    MNEMONIC_LEN   = 36,
    DESC_LEN       = 40,
};

string d_host;
int d_port;

void printUsage()
{
    writefln("Usage:\n"
        "    Retrieve reference data \n"
        "        [-ip        <ipAddress  = localhost>\n"
        "        [-p         <tcpPort    = 8194>\n");
}

bool parseCommandLine(string[] argv)
{
    foreach(i;1..argv.length)
    {
        if (!(argv[i]=="-ip") ) {
            if (++i >= argv.length) return false;
            d_host = argv[i];
        }
        else if (!(argv[i]=="-p")) {
            if (++i >= argv.length) return false;
            d_port = atoi(argv[i]);
        }
        else return false;
    }
    return true;
}

string padString(string str, uint width)
{
    if (str.length() >= width || str.length() >= PADDING.length())
        return str;
    else return str ~ PADDING.substr(0, width-str.length());
}

void printField (const Element &field)
{
    string  fldId = field.getElementAsString(FIELD_ID);
    if (field.hasElement(FIELD_INFO)) {
        Element fldInfo          = field.getElement (FIELD_INFO) ;
        string fldMnemonic = fldInfo.getElementAsString(FIELD_MNEMONIC);
        string  fldDesc     = fldInfo.getElementAsString(FIELD_DESC);
        writefln("%s %s %s",padString(fldId, ID_LEN), padString(fldMnemonic, MNEMONIC_LEN), padString(fldDesc, DESC_LEN));
    }
    else {
        Element fldError = field.getElement(FIELD_ERROR) ;
        string errorMsg = fldError.getElementAsString(FIELD_MSG) ;

        writefln("\nERROR: ^s, - %s " fldId, errorMsg);
    }
}

void printHeader ()
{
    writefln("%s %s %s",padString("FIELD ID", ID_LEN), padString("MNEMONIC", MNEMONIC_LEN), padString("DESCRIPTION", DESC_LEN));
    writefln("%s %s %2",padString("-----------", ID_LEN),  padString("-----------", MNEMONIC_LEN), padString("-----------", DESC_LEN));
}


void run(string[] argv)
{
    d_host = "localhost";
    d_port = 8194;

    if (!parseCommandLine(argv)) {
        printUsage();
        return;
    }

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s" d_host, d_port);
    Session session(sessionOptions);

    if (!session.start()) {
        stderr.writefln("Failed to start session.");
        return;
    }

    if (!session.openService(APIFLDS_SVC)) {
        stderr.writefln("Failed to open %s",APIFLDS_SVC);
        return;
    }

    Service fieldInfoService = session.getService(APIFLDS_SVC);
    Request request = fieldInfoService.createRequest("FieldSearchRequest");
    request.set ("searchSpec", "last price");
    Element exclude = request.getElement("exclude");
    exclude.setElement("fieldType", "Static");
    request.set ("returnFieldDocumentation", false);

    writefln("Sending Request: %s", request);
    session.sendRequest(request);

    printHeader();
    while (true) {
        Event event = session.nextEvent();

        if (event.eventType() != Event::RESPONSE &&
            event.eventType() != Event::PARTIAL_RESPONSE) {
                continue;
        }

        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            Element fields = msg.getElement("fieldData");
            int numElements = fields.numValues();

            for (int i=0; i < numElements; i++) {
                printField (fields.getValueAsElement(i));
            }
        }
        if (event.eventType() == Event::RESPONSE) {
            break;
        }
    }
}
};

int main(string[] argv)
{
    SimpleFieldSearchExample example;

    try {
        example.run(argc, argv);
    }
    catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s",e.description());
    }
    catch (...) {
        stderr.writefln("Unknown exception!");
    }

    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

string d_host;
int d_port;

void printUsage()
{
    writefln("Usage:\n"
         "    Retrieve reference data \n" 
         "        [-ip        <ipAddress  = localhost>\n" 
         "        [-p         <tcpPort    = 8194>" );
}

bool parseCommandLine(string[] argv)
{
    foreach(i;1..argv.length)
    {
        if ((!argv[i]=="-ip") && (i + 1 < argv.length)) {
            d_host = argv[++i];
            continue;
        }
        if ((!argv[i]=="-p") &&  (i + 1 < argv.length)) {
            d_port = std::atoi(argv[++i]);
            continue;
        }
        printUsage();
        return false;
    }
    return true;
}

void run(string[] argv)
{
    d_host = "localhost";
    d_port = 8194;
    if (!parseCommandLine(argc, argv)) return;

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s",d_host,d_port);
    Session session(sessionOptions);
    if (!session.start()) {
        stderr.writefln("Failed to start session.");
        return;
    }
    if (!session.openService("//blp/refdata")) {
        stderr.writefln("Failed to open //blp/refdata");
        return;
    }
    Service refDataService = session.getService("//blp/refdata");
    Request request = refDataService.createRequest("HistoricalDataRequest");
    request.getElement("securities").appendValue("IBM US Equity");
    request.getElement("securities").appendValue("MSFT US Equity");
    request.getElement("fields").appendValue("PX_LAST");
    request.getElement("fields").appendValue("OPEN");
    request.set("periodicityAdjustment", "ACTUAL");
    request.set("periodicitySelection", "MONTHLY");
    request.set("startDate", "20060101");
    request.set("endDate", "20061231");
    request.set("maxDataPoints", 100);

    writefln("Sending Request: %s",request);
    session.sendRequest(request);

    while (true) {
        Event event = session.nextEvent();
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            msg.asElement().print(std::cout);
        }
        if (event.eventType() == Event::RESPONSE) {
            break;
        }
    }
}

int main(string[] argv)
{
    writefln("SimpleHistoryExample");
    SimpleHistoryExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s",e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

string d_host;
int d_port;

void printUsage()
{
    writefln("Usage:\n"
         "    Retrieve reference data \n"
         "        [-ip        <ipAddress = localhost>\n"
         "        [-p         <tcpPort   = 8194>\n");
}

bool parseCommandLine(string[] argv)
{
    foreach(i;1.. argv.length) {
        if ((!argv[i]=="-ip") && (i + 1 < argv.length)) {
            d_host = argv[++i];
            continue;
        }
        if ((!(argv[i]=="-p") &&  (i + 1 < argv.length)) {
            d_port = atoi(argv[++i]);
            continue;
        }
        printUsage();
        return false;
    }
    return true;
}

int getPreviousTradingDate (int *year_p, int *month_p, int *day_p)
{
    struct tm *tm_p;
    time_t currTime = time(0);

    while (currTime > 0) {
        currTime -= 86400; // GO back one day
        tm_p = localtime(&currTime);
        if (tm_p == NULL) {
            break;
        }

        // if not sunday / saturday, assign values & return
        if (tm_p->tm_wday != 0 && tm_p->tm_wday != 6 ) {// not Sun/Sat
            *year_p = tm_p->tm_year + 1900;
            *month_p = tm_p->tm_mon + 1;
            *day_p = tm_p->tm_mday;
            return (0) ;
        }
    }
    return (-1) ;
}

void run(int argc, char **argv)
{
    d_host = "localhost";
    d_port = 8194;
    if (!parseCommandLine(argc, argv)) return;

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s",d_host,d_port);
    Session session(sessionOptions);
    if (!session.start()) {
        stderr.writefln("Failed to start session.");
        return;
    }
    if (!session.openService("//blp/refdata")) {
        stderr.writefln("Failed to open //blp/refdata");
        return;
    }

    Service refDataService = session.getService("//blp/refdata");
    Request request = refDataService.createRequest("IntradayBarRequest");
    request.set("security", "IBM US Equity");
    request.set("eventType", "TRADE");
    request.set("interval", 60); // bar interval in minutes

    int tradedOnYear  = 0;
    int tradedOnMonth = 0;
    int tradedOnDay   = 0;
    if (0 != getPreviousTradingDate (&tradedOnYear, &tradedOnMonth, &tradedOnDay) ) {
            stderr.writefln("unable to get previous trading date");
            return;
    }

    Datetime starttime;
    starttime.setDate(tradedOnYear, tradedOnMonth, tradedOnDay);
    starttime.setTime(13, 30, 0, 0);
    request.set("startDateTime", starttime );

    Datetime endtime;
    endtime.setDate(tradedOnYear, tradedOnMonth, tradedOnDay);
    endtime.setTime(21, 30, 0, 0);
    request.set("endDateTime", endtime);

    writefln("Sending Request: %s",request);
    session.sendRequest(request);

    while (true) {
        Event event = session.nextEvent();
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            std::cout << msg.messageType();
            msg.print(std::cout) << std::endl;
        }
        if (event.eventType() == Event::RESPONSE) {
            break;
        }
    }
}

int main(string[] argv)
{
    writefln("SimpleIntradayBarExample");
    SimpleIntradayBarExample example;
    try {
        example.run(argc, argv);
    }
    catch (Exception &e) {
        writefln("Library Exception!!! %s",e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

string d_host;
int d_port;

void printUsage()
{
    writefln("Usage:\n"
         "    Retrieve reference data \n"
         "        [-ip        <ipAddress  = localhost>\n"
         "        [-p         <tcpPort    = 8194>\n");
}

bool parseCommandLine(string[] argv)
{
    foreach(i;1..argc)
    {
        if ((!argv[i]=="-ip") && (i+1<argv.length)) {
            d_host = argv[++i];
            continue;
        }
        if ((!(argv[i]=="-p") && (i+1<argv.length)) {
            d_port = atoi(argv[++i]);
            continue;
        }
        printUsage();
        return false;
    }
    return true;
}

int getPreviousTradingDate (int *year_p, int *month_p, int *day_p)
{
    struct tm *tm_p;
    time_t currTime = time(0);

    while (currTime > 0) {
        currTime -= 86400; // GO back one day
        tm_p = localtime(&currTime);
        if (tm_p == NULL) {
            break;
        }

        // if not sunday / saturday, assign values & return
        if (tm_p->tm_wday != 0 && tm_p->tm_wday != 6 ) {// not Sun/Sat
            *year_p = tm_p->tm_year + 1900;
            *month_p = tm_p->tm_mon + 1;
            *day_p = tm_p->tm_mday;
            return (0) ;
        }
    }
    return (-1) ;
}

void run(string[] argv)
{
    d_host = "localhost";
    d_port = 8194;
    if (!parseCommandLine(argc, argv)) return;

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s",d_host, d_port);
    Session session(sessionOptions);
    if (!session.start()) {
        stderr.writefln("Failed to start session.");
        return;
    }
    if (!session.openService("//blp/refdata")) {
        stderr.writefln("Failed to open //blp/refdata");
        return;
    }

    Service refDataService = session.getService("//blp/refdata");
    Request request = refDataService.createRequest("IntradayTickRequest");
    request.set("security", "VOD LN Equity");
    request.getElement("eventTypes").appendValue("TRADE");
    request.getElement("eventTypes").appendValue("AT_TRADE");
    request.set("includeConditionCodes", true);

    int tradedOnYear  = 0;
    int tradedOnMonth = 0;
    int tradedOnDay   = 0;
    if (0 != getPreviousTradingDate (&tradedOnYear,
        &tradedOnMonth,
        &tradedOnDay) ) {
            std::cerr << "unable to get previous trading date" << std::endl;
            return;
    }

    Datetime starttime;
    starttime.setDate(tradedOnYear, tradedOnMonth, tradedOnDay);
    starttime.setTime(13, 30, 0, 0);
    request.set("startDateTime", starttime );

    Datetime endtime;
    endtime.setDate(tradedOnYear, tradedOnMonth, tradedOnDay);
    endtime.setTime(13, 35, 0, 0);
    request.set("endDateTime", endtime);

    std::cout << "Sending Request: " << request << std::endl;
    session.sendRequest(request);

    while (true) {
        Event event = session.nextEvent();
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            msg.print(std::cout);
        }
        if (event.eventType() == Event::RESPONSE) {
            break;
        }
    }

}

int main(string[] argv)
{
    writefln("SimpleIntradayTickExample");
    SimpleIntradayTickExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s",e.description());
    }
    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

string d_host;
int d_port;

void printUsage()
{
    writefln("Usage:\n"
        "    Retrieve reference data \n"
        "        [-ip        <ipAddress  = localhost>\n"
        "        [-p         <tcpPort    = 8194>");
}

bool parseCommandLine(string[] argv)
{
    foreach(i;1.. argv.length)
    {
        if (!(argv[i]=="-ip") && (i+1<argc)) {
            d_host = argv[++i];
            continue;
        }
        if (!(argv[i]=="-p") &&  (i + 1 < argc)) {
            d_port = atoi(argv[++i]);
            continue;
        }
        printUsage();
        return false;
    }
    return true;
}

void run(string[] argv)
{
    d_host = "localhost";
    d_port = 8194;
    if (!parseCommandLine(argc, argv)) return;

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s",d_host, d_port);
    Session session(sessionOptions);
    if (!session.start()) {
        stderr.writefln("Failed to start session.");
        return;
    }
    if (!session.openService("//blp/refdata")) {
        stderr.writefln("Failed to open //blp/refdata");
        return;
    }

    Service refDataService = session.getService("//blp/refdata");
    Request request = refDataService.createRequest("ReferenceDataRequest");

    // append securities to request
    request.append("securities", "IBM US Equity");
    request.append("securities", "MSFT US Equity");

    // append fields to request
    request.append("fields","PX_LAST");
    request.append("fields","DS002");


    writefln("Sending Request: %s",request);
    session.sendRequest(request);

    while (true) {
        Event event = session.nextEvent();
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            msg.print(std::cout) << std::endl;
        }
        if (event.eventType() == Event::RESPONSE) {
            break;
        }
    }
}

int main(string[] argv)
{
    writefln("SimpleRefDataExample");
    SimpleRefDataExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s",e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}
//newfile

namespace {
    const Name SECURITY_DATA("securityData");
    const Name SECURITY("security");
    const Name FIELD_DATA("fieldData");
    const Name FIELD_EXCEPTIONS("fieldExceptions");
    const Name FIELD_ID("fieldId");
    const Name ERROR_INFO("errorInfo");
}

class SimpleRefDataOverrideExample
{
    std::string         d_host;
    int                 d_port;

    void printUsage()
    {
            writefln("Usage:" 
                "    Retrieve reference data \n"
                "        [-ip        <ipAddress  = localhost>\n"
                "        [-p         <tcpPort    = 8194>");
    }

    bool parseCommandLine(string[] argv)
    {
        foreach(i;1.. argv.length) {
            if ((argv[i]!="-ip") && (i+1<argc)) {
                d_host = argv[++i];
            } else if ((argv[i]!="-p") &&  (i + 1 < argc)) {
                d_port = std::atoi(argv[++i]);
            } else {
                printUsage();
                return false;
            }
        }
        return true;
    }

    void processMessage(Message &msg)
    {
        Element securityDataArray = msg.getElement(SECURITY_DATA);
        int numSecurities = securityDataArray.numValues();
        foreach(i; 0.. numSecurities)
        {
            Element securityData = securityDataArray.getValueAsElement(i);
            writefln(securityData.getElementAsString(SECURITY));
            const Element fieldData = securityData.getElement(FIELD_DATA);
            foreach(j;0.. fieldData.numElements())
            {
                Element field = fieldData.getElement(j);
                if (!field.isValid()) {
                    writefln("%s is NULL.",field.name());
                } else {
                    writefln("%s=%s",field.name(),field.getValueAsString());
                }
            }

            Element fieldExceptionArray = securityData.getElement(FIELD_EXCEPTIONS);
            foreach(k;0..fieldExceptionArray.numValues())
            {
                Element fieldException = fieldExceptionArray.getValueAsElement(k);
                writefln("%s:%s",fieldException.getElement(ERROR_INFO).getElementAsString(category"),fieldException.getElementAsString(FIELD_ID));
            }
            writefln("");
        }
    }
public:

    void run(string[] argv)
    {
        d_host = "localhost";
        d_port = 8194;
        if (!parseCommandLine(argv)) return;

        SessionOptions sessionOptions;
        sessionOptions.setServerHost(d_host.c_str());
        sessionOptions.setServerPort(d_port);

        writefln("Connecting to %s:%s ",d_host, d_port);
        Session session(sessionOptions);
        if (!session.start()) {
            stderr.writefln("Failed to start session.");
            return;
        }
        if (!session.openService("//blp/refdata")) {
            stderr.writefln("Failed to open //blp/refdata");
            return;
        }

        Service refDataService = session.getService("//blp/refdata");
        Request request = refDataService.createRequest("ReferenceDataRequest");

        request.append("securities", "IBM US Equity");
        request.append("securities", "MSFT US Equity");
        request.append("fields", "PX_LAST");
        request.append("fields", "DS002");
        request.append("fields", "EQY_WEIGHTED_AVG_PX");

        // add overrides
        Element overrides = request.getElement("overrides");
        Element override1 = overrides.appendElement();
        override1.setElement("fieldId", "VWAP_START_TIME");
        override1.setElement("value", "9:30");
        Element override2 = overrides.appendElement();
        override2.setElement("fieldId", "VWAP_END_TIME");
        override2.setElement("value", "11:30");

        writefln("Sending Request: %s",request);
        CorrelationId cid(this);
        session.sendRequest(request, cid);

        while (true) {
            Event event = session.nextEvent();
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (msg.correlationId() == cid) {
                    processMessage(msg);
                }
            }
            if (event.eventType() == Event::RESPONSE) {
                break;
            }
        }
    }
};

int main(string[] argv)
{
    writefln("SimpleRefDataOverrideExample");
    SimpleRefDataOverrideExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln( "Library Exception!!! %s", e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}
//newfile
using namespace BloombergLP;
using namespace blpapi;

class SimpleSubscriptionExample
{
    std::string         d_host;
    int                 d_port;
    int                 d_maxEvents;
    int                 d_eventCount;

    void printUsage()
    {
        std::cout << "Usage:" << std::endl
            << "    Retrieve realtime data " << std::endl
            << "        [-ip        <ipAddress  = localhost>" << std::endl
            << "        [-p         <tcpPort    = 8194>" << std::endl
            << "        [-me        <maxEvents  = MAX_INT>" << std::endl;
    }

    bool parseCommandLine(int argc, char **argv)
    {
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i],"-ip") && i + 1 < argc)
                d_host = argv[++i];
            else if (!std::strcmp(argv[i],"-p") &&  i + 1 < argc)
                d_port = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i],"-me") && i + 1 < argc)
                d_maxEvents = std::atoi(argv[++i]);
            else {
                printUsage();
                return false;
            }
        }
        return true;
    }

    public:

    void run(int argc, char **argv)
    {
        d_host = "localhost";
        d_port = 8194;
        d_maxEvents = INT_MAX;
        d_eventCount = 0;

        if (!parseCommandLine(argc, argv)) return;

        SessionOptions sessionOptions;
        sessionOptions.setServerHost(d_host.c_str());
        sessionOptions.setServerPort(d_port);

        std::cout << "Connecting to " <<  d_host << ":" << d_port
                  << std::endl;
        Session session(sessionOptions);
        if (!session.start()) {
            std::cerr <<"Failed to start session." << std::endl;
            return;
        }
        if (!session.openService("//blp/mktdata")) {
            std::cerr <<"Failed to open //blp/mktdata" << std::endl;
            return;
        }

        const char *security1 = "IBM US Equity";
        const char *security2 = "/cusip/912810RE0@BGN";
            // this CUSIP identifies US Treasury Bill 'T 3 5/8 02/15/44 Govt'

        SubscriptionList subscriptions;
        subscriptions.add(
                security1,
                "LAST_PRICE,BID,ASK",
                "",
                CorrelationId((char *)security1));
        subscriptions.add(
                security2,
                "LAST_PRICE,BID,ASK,BID_YIELD,ASK_YIELD",
                "",
                CorrelationId((char *)security2));
        session.subscribe(subscriptions);

        while (true) {
            Event event = session.nextEvent();
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (event.eventType() == Event::SUBSCRIPTION_STATUS ||
                    event.eventType() == Event::SUBSCRIPTION_DATA) {
                    const char *topic = (char *)msg.correlationId().asPointer();
                    std::cout << topic << " - ";
                }
                msg.print(std::cout) << std::endl;
            }
            if (event.eventType() == Event::SUBSCRIPTION_DATA) {
                if (++d_eventCount >= d_maxEvents) break;
            }
        }
    }
};

int main(int argc, char **argv)
{
    std::cout << "SimpleSubscriptionExample" << std::endl;
    SimpleSubscriptionExample example;
    try {
        example.run(argc, argv);
    }
    catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description()
                      << std::endl;
    }

    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

using namespace BloombergLP;
using namespace blpapi;

class SimpleSubscriptionIntervalExample
{
    std::string         d_host;
    int                 d_port;
    int                 d_maxEvents;
    int                 d_eventCount;

    void printUsage()
    {
        std::cout << "Usage:" << std::endl
            << "    Retrieve realtime data " << std::endl
            << "        [-ip        <ipAddress  = localhost>" << std::endl
            << "        [-p         <tcpPort    = 8194>" << std::endl
            << "        [-me        <maxEvents  = MAX_INT>" << std::endl;
    }

    bool parseCommandLine(int argc, char **argv)
    {
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i],"-ip") && i + 1 < argc)
                d_host = argv[++i];
            else if (!std::strcmp(argv[i],"-p") &&  i + 1 < argc)
                d_port = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i],"-me") && i + 1 < argc)
                d_maxEvents = std::atoi(argv[++i]);
            else {
                printUsage();
                return false;
            }
        }
        return true;
    }
    public:

    void run(int argc, char **argv)
    {
        d_host = "localhost";
        d_port = 8194;
        d_maxEvents = INT_MAX;
        d_eventCount = 0;

        if (!parseCommandLine(argc, argv)) return;

        SessionOptions sessionOptions;
        sessionOptions.setServerHost(d_host.c_str());
        sessionOptions.setServerPort(d_port);

        std::cout << "Connecting to " <<  d_host << ":" << d_port << std::endl;
        Session session(sessionOptions);
        if (!session.start()) {
            std::cerr <<"Failed to start session." << std::endl;
            return;
        }
        if (!session.openService("//blp/mktdata")) {
            std::cerr <<"Failed to open //blp/mktdata" << std::endl;
            return;
        }

        const char *security1 = "IBM US Equity";
        const char *security2 = "/cusip/912810RE0@BGN";
            // this CUSIP identifies US Treasury Bill 'T 3 5/8 02/15/44 Govt'

        SubscriptionList subscriptions;
        subscriptions.add(
                security1,
                "LAST_PRICE,BID,ASK",
                "interval=1.0",
                CorrelationId((char *)security1));
        subscriptions.add(
                security2,
                "LAST_PRICE,BID,ASK,BID_YIELD,ASK_YIELD",
                "interval=1.0",
                CorrelationId((char *)security2));
        session.subscribe(subscriptions);

        while (true) {
            Event event = session.nextEvent();
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (event.eventType() == Event::SUBSCRIPTION_STATUS ||
                    event.eventType() == Event::SUBSCRIPTION_DATA) {
                    const char *topic = (char *)msg.correlationId().asPointer();
                    std::cout << topic << " - ";
                }
                msg.print(std::cout) << std::endl;
            }
            if (event.eventType() == Event::SUBSCRIPTION_DATA) {
                if (++d_eventCount >= d_maxEvents) break;
            }
        }
    }
};

int main(int argc, char **argv)
{
    std::cout << "SimpleSubscriptionIntervalExample" << std::endl;
    SimpleSubscriptionIntervalExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description() << std::endl;
    }
    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}
//newfile

using namespace BloombergLP;
using namespace blpapi;

class SubscriptionCorrelationExample
{
    class GridWindow {
        std::string                  d_name;
        std::vector<std::string>    &d_securities;

    public :

        GridWindow(const char *name, std::vector<std::string> &securities)
            : d_name(name), d_securities(securities)
        {
        }

        void processSecurityUpdate(Message &msg, int row)
        {
            const std::string &topicname = d_securities[row];

            std::cout << d_name << ":" <<  row << ',' << topicname << std::endl;
        }
    };

    std::string              d_host;
    int                      d_port;
    int                      d_maxEvents;
    int                      d_eventCount;
    std::vector<std::string> d_securities;
    GridWindow               d_gridWindow;

    void printUsage()
    {
        std::cout << "Usage:" << std::endl
            << "    Retrieve realtime data " << std::endl
            << "        [-ip        <ipAddress  = localhost>" << std::endl
            << "        [-p         <tcpPort    = 8194>" << std::endl
            << "        [-me        <maxEvents  = MAX_INT>" << std::endl;
    }

    bool parseCommandLine(int argc, char **argv)
    {
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i],"-ip") && i + 1 < argc)
                d_host = argv[++i];
            else if (!std::strcmp(argv[i],"-p") &&  i + 1 < argc)
                d_port = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i],"-me") && i + 1 < argc)
                d_maxEvents = std::atoi(argv[++i]);
            else {
                printUsage();
                return false;
            }
        }
        return true;
    }

public:

    SubscriptionCorrelationExample()
        : d_gridWindow("SecurityInfo", d_securities)
    {
        d_securities.push_back("IBM US Equity");
        d_securities.push_back("VOD LN Equity");
    }

    void run(int argc, char **argv)
    {
        d_host = "localhost";
        d_port = 8194;
        d_maxEvents = INT_MAX;
        d_eventCount = 0;

        if (!parseCommandLine(argc, argv)) return;

        SessionOptions sessionOptions;
        sessionOptions.setServerHost(d_host.c_str());
        sessionOptions.setServerPort(d_port);

        std::cout << "Connecting to "  <<  d_host  <<  ":"
            << d_port << std::endl;
        Session session(sessionOptions);
        if (!session.start()) {
            std::cerr <<"Failed to start session." << std::endl;
            return;
        }
        if (!session.openService("//blp/mktdata")) {
            std::cerr <<"Failed to open //blp/mktdata" << std::endl;
            return;
        }

        SubscriptionList subscriptions;
        for (size_t i = 0; i < d_securities.size(); ++i) {
            subscriptions.add(d_securities[i].c_str(),
                "LAST_PRICE",
                "",
                CorrelationId(i));
        }
        session.subscribe(subscriptions);

        while (true) {
            Event event = session.nextEvent();
            if (event.eventType() == Event::SUBSCRIPTION_DATA) {
                MessageIterator msgIter(event);
                while (msgIter.next()) {
                    Message msg = msgIter.message();
                    int row = (int)msg.correlationId().asInteger();
                    d_gridWindow.processSecurityUpdate(msg, row);
                }
                if (++d_eventCount >= d_maxEvents) break;
            }
        }
    }
};

int main(int argc, char **argv)
{
    std::cout << "SubscriptionCorrelationExample" << std::endl;
    SubscriptionCorrelationExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description() << std::endl;
    }
    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
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

//newfile
using namespace BloombergLP;
using namespace blpapi;

namespace {

Name SLOW_CONSUMER_WARNING("SlowConsumerWarning");
Name SLOW_CONSUMER_WARNING_CLEARED("SlowConsumerWarningCleared");
Name DATA_LOSS("DataLoss");
Name SUBSCRIPTION_TERMINATED("SubscriptionTerminated");
Name SOURCE("source");

inline
std::string getTopic(const CorrelationId& cid)
{
    // Return the topic used to create the specified correlation 'cid'.
    // The behaviour is undefined unless the specified cid was
    return *(reinterpret_cast<std::string*>(cid.asPointer()));
}

std::string getTopicsString(const SubscriptionList& list)
{
    std::ostringstream out;
    int count = 0;
    for (size_t i = 0; i < list.size(); ++i) {
        if (count++ != 0) {
            out << ", ";
        }
        out << getTopic(list.correlationIdAt(i));
    }
    return out.str();
}

const char * getSubscriptionTopicString(const SubscriptionList& list,
                                       const CorrelationId&    cid)
{
    for (size_t i = 0; i < list.size(); ++i) {
        if (list.correlationIdAt(i) == cid) {
            return list.topicStringAt(i);
        }
    }
    return 0;
}

size_t getTimeStamp(char *buffer, size_t bufSize)
{
    const char *format = "%Y/%m/%d %X";

    time_t now = time(0);
    tm _timeInfo;
#ifdef _WIN32
    tm *timeInfo = &_timeInfo;
    localtime_s(&_timeInfo, &now);
#else
    tm *timeInfo = localtime_r(&now, &_timeInfo);
#endif
    return strftime(buffer, bufSize, format, timeInfo);
}

}

class ConsoleOut
{
  private:
    std::ostringstream  d_buffer;
    Mutex              *d_consoleLock;
    std::ostream&       d_stream;

    // NOT IMPLEMENTED
    ConsoleOut(const ConsoleOut&);
    ConsoleOut& operator=(const ConsoleOut&);

  public:
    explicit ConsoleOut(Mutex         *consoleLock,
                        std::ostream&  stream = std::cout)
    : d_consoleLock(consoleLock)
    , d_stream(stream)
    {}

    ~ConsoleOut() {
        MutexGuard guard(d_consoleLock);
        d_stream << d_buffer.str();
        d_stream.flush();
    }

    template <typename T>
    std::ostream& operator<<(const T& value) {
        return d_buffer << value;
    }

    std::ostream& stream() {
        return d_buffer;
    }
};

struct SessionContext
{
    Mutex            d_consoleLock;
    Mutex            d_mutex;
    bool             d_isStopped;
    SubscriptionList d_subscriptions;

    SessionContext()
    : d_isStopped(false)
    {
    }
};

class SubscriptionEventHandler: public EventHandler
{
    bool                     d_isSlow;
    SubscriptionList         d_pendingSubscriptions;
    std::set<CorrelationId>  d_pendingUnsubscribe;
    SessionContext          *d_context_p;
    Mutex                   *d_consoleLock_p;

    bool processSubscriptionStatus(const Event &event, Session *session)
    {
        char timeBuffer[64];
        getTimeStamp(timeBuffer, sizeof(timeBuffer));

        SubscriptionList subscriptionList;
        ConsoleOut(d_consoleLock_p)
            << "\nProcessing SUBSCRIPTION_STATUS"
            << std::endl;

        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            CorrelationId cid = msg.correlationId();

            std::string topic = getTopic(cid);
            {
                ConsoleOut out(d_consoleLock_p);
                out << timeBuffer << ": " << topic
                    << std::endl;
                msg.print(out.stream(), 0, 4);
            }

            if (msg.messageType() == SUBSCRIPTION_TERMINATED
                && d_pendingUnsubscribe.erase(cid)) {
                // If this message was due to a previous unsubscribe
                const char *topicString = getSubscriptionTopicString(
                    d_context_p->d_subscriptions,
                    cid);
                assert(topicString);
                if (d_isSlow) {
                    ConsoleOut(d_consoleLock_p)
                        << "Deferring subscription for topic = " << topic
                        << " because session is slow." << std::endl;
                    d_pendingSubscriptions.add(topicString, cid);
                }
                else {
                    subscriptionList.add(topicString, cid);
                }
            }
        }

        if (0 != subscriptionList.size() && !d_context_p->d_isStopped) {
            session->subscribe(subscriptionList);
        }

        return true;
    }

    bool processSubscriptionDataEvent(const Event &event)
    {
        char timeBuffer[64];
        getTimeStamp(timeBuffer, sizeof(timeBuffer));

        ConsoleOut(d_consoleLock_p)
            << "\nProcessing SUBSCRIPTION_DATA" << std::endl;
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            {
                ConsoleOut out(d_consoleLock_p);
                out << timeBuffer << ": " << getTopic(msg.correlationId())
                    << std::endl;
                msg.print(out.stream(), 0, 4);
            }
        }
        return true;
    }

    bool processAdminEvent(const Event &event, Session *session)
    {
        char timeBuffer[64];
        getTimeStamp(timeBuffer, sizeof(timeBuffer));

        ConsoleOut(d_consoleLock_p)
            << "\nProcessing ADMIN" << std::endl;
        std::vector<CorrelationId> cidsToCancel;
        bool previouslySlow = d_isSlow;
        MessageIterator msgIter(event);

        while (msgIter.next()) {
            Message msg = msgIter.message();
            // An admin event can have more than one messages.
            if (msg.messageType() == DATA_LOSS) {
                const CorrelationId& cid = msg.correlationId();
                {
                    ConsoleOut out(d_consoleLock_p);
                    out << timeBuffer << ": " << getTopic(msg.correlationId())
                        << std::endl;
                    msg.print(out.stream(), 0, 4);
                }

                if (msg.hasElement(SOURCE)) {
                    std::string sourceStr = msg.getElementAsString(SOURCE);
                    if (0 == sourceStr.compare("InProc")
                        && d_pendingUnsubscribe.find(cid) ==
                                                  d_pendingUnsubscribe.end()) {
                        // DataLoss was generated "InProc".
                        // This can only happen if applications are processing
                        // events slowly and hence are not able to keep-up with
                        // the incoming events.
                        cidsToCancel.push_back(cid);
                        d_pendingUnsubscribe.insert(cid);
                    }
                }
            }
            else {
                ConsoleOut(d_consoleLock_p)
                    << timeBuffer << ": "
                    << msg.messageType().string() << std::endl;
                if (msg.messageType() == SLOW_CONSUMER_WARNING) {
                    d_isSlow = true;
                }
                else if (msg.messageType() == SLOW_CONSUMER_WARNING_CLEARED) {
                    d_isSlow = false;
                }
            }
        }
        if (!d_context_p->d_isStopped) {
            if (0 != cidsToCancel.size()) {
                session->cancel(cidsToCancel);
            }
            else if (previouslySlow
                     && !d_isSlow
                     && d_pendingSubscriptions.size() > 0) {
                // Session was slow but is no longer slow. subscribe to any
                // topics for which we have previously received
                // SUBSCRIPTION_TERMINATED
                ConsoleOut(d_consoleLock_p)
                    << "Subscribing to topics - "
                    << getTopicsString(d_pendingSubscriptions)
                    << std::endl;
                session->subscribe(d_pendingSubscriptions);
                d_pendingSubscriptions.clear();
            }
        }

        return true;
    }

    bool processMiscEvents(const Event &event)
    {
        char timeBuffer[64];
        getTimeStamp(timeBuffer, sizeof(timeBuffer));

        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            ConsoleOut(d_consoleLock_p)
                << timeBuffer << ": "
                << msg.messageType().string() << std::endl;
        }
        return true;
    }

public:
    SubscriptionEventHandler(SessionContext *context)
    : d_isSlow(false)
    , d_context_p(context)
    , d_consoleLock_p(&context->d_consoleLock)
    {
    }

    bool processEvent(const Event &event, Session *session)
    {
        try {
            switch (event.eventType()) {
              case Event::SUBSCRIPTION_DATA: {
                return processSubscriptionDataEvent(event);
              } break;
              case Event::SUBSCRIPTION_STATUS: {
                MutexGuard guard(&d_context_p->d_mutex);
                return processSubscriptionStatus(event, session);
              } break;
              case Event::ADMIN: {
                MutexGuard guard(&d_context_p->d_mutex);
                return processAdminEvent(event, session);
              } break;
              default: {
                return processMiscEvents(event);
              }  break;
            }
        } catch (Exception &e) {
            ConsoleOut(d_consoleLock_p)
                << "Library Exception !!!"
                << e.description() << std::endl;
        }
        return false;
    }
};

class SubscriptionWithEventHandlerExample
{

    const std::string         d_service;
    SessionOptions            d_sessionOptions;
    Session                  *d_session;
    SubscriptionEventHandler *d_eventHandler;
    std::vector<std::string>  d_topics;
    std::vector<std::string>  d_fields;
    std::vector<std::string>  d_options;
    SessionContext            d_context;

    bool createSession() {
        ConsoleOut(&d_context.d_consoleLock)
            << "Connecting to " << d_sessionOptions.serverHost()
            << ":" << d_sessionOptions.serverPort() << std::endl;

        d_eventHandler = new SubscriptionEventHandler(&d_context);
        d_session = new Session(d_sessionOptions, d_eventHandler);

        if (!d_session->start()) {
            ConsoleOut(&d_context.d_consoleLock)
                << "Failed to start session." << std::endl;
            return false;
        }

        ConsoleOut(&d_context.d_consoleLock)
            << "Connected successfully" << std::endl;

        if (!d_session->openService(d_service.c_str())) {
            ConsoleOut(&d_context.d_consoleLock)
                << "Failed to open mktdata service" << std::endl;
            d_session->stop();
            return false;
        }

        ConsoleOut(&d_context.d_consoleLock) << "Subscribing..." << std::endl;
        d_session->subscribe(d_context.d_subscriptions);
        return true;
    }


    bool parseCommandLine(int argc, char **argv)
    {
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i],"-t") && i + 1 < argc)
                d_topics.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-f") && i + 1 < argc)
                d_fields.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-o") && i + 1 < argc)
                d_options.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-ip") && i + 1 < argc)
                d_sessionOptions.setServerHost(argv[++i]);
            else if (!std::strcmp(argv[i],"-p") &&  i + 1 < argc)
                d_sessionOptions.setServerPort(std::atoi(argv[++i]));
            else if (!std::strcmp(argv[i],"-qsize") &&  i + 1 < argc)
                d_sessionOptions.setMaxEventQueueSize(std::atoi(argv[++i]));
            else {
                printUsage();
                return false;
            }
        }

        if (d_fields.size() == 0) {
            d_fields.push_back("LAST_PRICE");
        }

        if (d_topics.size() == 0) {
            d_topics.push_back("IBM US Equity");
        }

        for (size_t i = 0; i < d_topics.size(); ++i) {
            std::string topic(d_service);
            if (*d_topics[i].c_str() != '/')
                topic += '/';
            topic += d_topics[i];
            d_context.d_subscriptions.add(
                topic.c_str(),
                d_fields,
                d_options,
                CorrelationId(&d_topics[i]));
        }

        return true;
    }

    void printUsage()
    {
        const char *usage =
            "Usage:\n"
            "    Retrieve realtime data\n"
            "        [-t     <topic      = IBM US Equity>\n"
            "        [-f     <field      = LAST_PRICE>\n"
            "        [-o     <subscriptionOptions>\n"
            "        [-ip    <ipAddress  = localhost>\n"
            "        [-p     <tcpPort    = 8194>\n"
            "        [-qsize <queuesize  = 10000>\n";
        ConsoleOut(&d_context.d_consoleLock) << usage << std::endl;
    }

public:

    SubscriptionWithEventHandlerExample()
    : d_service("//blp/mktdata")
    , d_session(0)
    , d_eventHandler(0)
    {
        d_sessionOptions.setServerHost("localhost");
        d_sessionOptions.setServerPort(8194);
        d_sessionOptions.setMaxEventQueueSize(10000);
    }

    ~SubscriptionWithEventHandlerExample()
    {
        if (d_session) delete d_session;
        if (d_eventHandler) delete d_eventHandler;
    }

    void run(int argc, char **argv)
    {
        if (!parseCommandLine(argc, argv)) return;
        if (!createSession()) return;

        // wait for enter key to exit application
        ConsoleOut(&d_context.d_consoleLock)
            << "\nPress ENTER to quit" << std::endl;
        char dummy[2];
        std::cin.getline(dummy,2);
        {
            MutexGuard guard(&d_context.d_mutex);
            d_context.d_isStopped = true;
        }
        d_session->stop();
        ConsoleOut(&d_context.d_consoleLock) << "\nExiting..." << std::endl;
    }
};

int main(int argc, char **argv)
{
    std::cout << "SubscriptionWithEventHandlerExample" << std::endl;
    SubscriptionWithEventHandlerExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        std::cout << "Library Exception!!!" << e.description() << std::endl;
    }
    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy,2);
    return 0;
}
// new file

namespace {

    const Name RESPONSE_ERROR("responseError");
    const Name SECURITY_DATA("securityData");
    const Name SECURITY("security");
    const Name EID_DATA("eidData");
    const Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
    const Name AUTHORIZATION_FAILURE("AuthorizationFailure");

    const char* REFRENCEDATA_REQUEST = "ReferenceDataRequest";
    const char* APIAUTH_SVC          = "//blp/apiauth";
    const char* REFDATA_SVC          = "//blp/refdata";

    void printEvent(const Event &event)
    {
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            CorrelationId correlationId = msg.correlationId();
            if (correlationId.asInteger() != 0) {
                std::cout << "Correlator: " << correlationId.asInteger()
                    << std::endl;
            }
            msg.print(std::cout);
            std::cout << std::endl;
        }
    }

} // anonymous namespace

class SessionEventHandler: public  EventHandler
{
    std::vector<Identity> &d_identities;
    std::vector<int> &d_uuids;

    void processResponseEvent(const Event &event)
    {
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            if (msg.hasElement(RESPONSE_ERROR)) {
                msg.print(std::cout) << std::endl;
                continue;
            }
            std::cout << "Response for User "
                      << msg.correlationId().asInteger() << ": "
                      << std::endl;
            msg.print(std::cout);
        }
    }

public :

    SessionEventHandler(std::vector<Identity> &identities,
        std::vector<int> &uuids) :
    d_identities(identities), d_uuids(uuids) {
    }

    bool processEvent(const Event &event, Session *session)
    {
        switch(event.eventType()) {
        case Event::SESSION_STATUS:
        case Event::SERVICE_STATUS:
        case Event::REQUEST_STATUS:
        case Event::AUTHORIZATION_STATUS:
            printEvent(event);
            break;

        case Event::RESPONSE:
        case Event::PARTIAL_RESPONSE:
            try {
                processResponseEvent(event);
            }
            catch (Exception &e) {
                std::cerr << "Library Exception!!! " << e.description()
                    << std::endl;
                return true;
            } catch (...) {
                std::cerr << "Unknown Exception!!!" << std::endl;
                return true;
            }
            break;
        }
        return true;
    }
};

class UserModeExample {

    std::string               d_host;
    int                       d_port;
    std::vector<std::string>  d_securities;
    std::vector<int>          d_uuids;
    std::vector<Identity>     d_identities;
    std::vector<std::string>  d_programAddresses;

    void printUsage()
    {
        std::cout
            << "Usage:" << '\n'
            << "    UserMode Example" << '\n'
            << "        [-s     <security   = IBM US Equity>]" << '\n'
            << "        [-c     <credential uuid:ipAddress" <<
            " eg:12345:10.20.30.40>]" << '\n'
            << "        [-ip    <ipAddress  = localhost>]" << '\n'
            << "        [-p     <tcpPort    = 8194>]" << '\n'
            << "Note:" << '\n'
            <<"Multiple securities and credentials can be" <<
            " specified." << std::endl;
    }

    void openServices(Session *session)
    {
        if (!session->openService(APIAUTH_SVC)) {
            std::cout << "Failed to open service: " << APIAUTH_SVC
                << std::endl;
            std::exit(-1);
        }

        if (!session->openService(REFDATA_SVC)) {
            std::cout << "Failed to open service: " << REFDATA_SVC
                << std::endl;
            std::exit(-2);
        }
    }

    bool authorizeUsers(EventQueue *authQueue, Session *session)
    {
        Service authService = session->getService(APIAUTH_SVC);
        bool is_any_user_authorized = false;

        // Authorize each of the users
        d_identities.reserve(d_uuids.size());
        for (size_t i = 0; i < d_uuids.size(); ++i) {
            d_identities.push_back(session->createIdentity());
            Request authRequest = authService.createAuthorizationRequest();
            authRequest.set("uuid", d_uuids[i]);
            authRequest.set("ipAddress", d_programAddresses[i].c_str());

            session->sendAuthorizationRequest(authRequest,
                                              &d_identities[i],
                                              CorrelationId(i),
                                              authQueue);

            Event event = authQueue->nextEvent();

            if (event.eventType() == Event::RESPONSE ||
                event.eventType() == Event::PARTIAL_RESPONSE ||
                event.eventType() == Event::REQUEST_STATUS ||
                event.eventType() == Event::AUTHORIZATION_STATUS) {

                MessageIterator msgIter(event);
                while (msgIter.next()) {
                    Message msg = msgIter.message();

                    if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                        std::cout << d_uuids[msg.correlationId().asInteger()]
                            << " authorization success"
                            << std::endl;
                        is_any_user_authorized = true;
                    }
                    else if (msg.messageType() == AUTHORIZATION_FAILURE) {
                        std::cout << d_uuids[msg.correlationId().asInteger()]
                            << " authorization failed"
                            << std::endl;
                        std::cout << msg << std::endl;
                    }
                    else {
                        std::cout << msg << std::endl;
                    }
                }
            }
        }
        return is_any_user_authorized;
    }

    void sendRefDataRequest(Session *session)
    {
        Service service = session->getService(REFDATA_SVC);
        Request request = service.createRequest(REFRENCEDATA_REQUEST);

        // Add securities.
        Element securities = request.getElement("securities");
        for (size_t i = 0; i < d_securities.size(); ++i) {
            securities.appendValue(d_securities[i].c_str());
        }

        // Add fields
        Element fields = request.getElement("fields");
        fields.appendValue("PX_LAST");
        fields.appendValue("LAST_UPDATE");

        request.set("returnEids", true);

        for (size_t j = 0; j < d_identities.size(); ++j) {
            int uuid = d_uuids[j];
            std::cout << "Sending RefDataRequest for User "
                      << uuid << std::endl;
            session->sendRequest(request,
                                 d_identities[j],
                                 CorrelationId(uuid));
        }
    }

    bool parseCommandLine(int argc, char **argv)
    {
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i],"-s") ) {
                if (++i >= argc) return false;
                d_securities.push_back(argv[i]);
            }
            else if (!std::strcmp(argv[i],"-c")) {
                if (++i >= argc) return false;

                std::string credential = argv[i];
                size_t idx = credential.find_first_of(':');
                if (idx == std::string::npos) return false;
                d_uuids.push_back(atoi(credential.substr(0,idx).c_str()));
                d_programAddresses.push_back(credential.substr(idx+1));
                continue;
            }
            else if (!std::strcmp(argv[i],"-ip")) {
                if (++i >= argc) return false;
                d_host = argv[i];
                continue;
            }
            else if (!std::strcmp(argv[i],"-p")) {
                if (++i >= argc) return false;
                d_port = std::atoi(argv[i]);
                continue;
            }
            else return false;
        }

        if (d_uuids.size() <= 0) {
            std::cout << "No uuids were specified" << std::endl;
            return false;
        }

        if (d_uuids.size() != d_programAddresses.size()) {
            std::cout << "Invalid number of program addresses provided"
                << std::endl;
            return false;
        }

        if (d_securities.size() <= 0) {
            d_securities.push_back("IBM US Equity");
        }

        return true;
    }


    UserModeExample()
    : d_host("localhost")
    , d_port(8194)
    {
    }

    void run(int argc, char **argv) {
        int example_UserMode(string[] argv)
{
    writefln("UserModeExample");
    UserModeExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writeln("Library Exception!!! %s", e.description());
    } catch (...) {
        stderr.writefln("Unknown Exception!!!");
    }

    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);

    return 0;
}

	if (!parseCommandLine(argc, argv)) {
            printUsage();
            return;
        }

        SessionOptions sessionOptions;
        sessionOptions.setServerHost(d_host.c_str());
        sessionOptions.setServerPort(d_port);

        std::cout << "Connecting to " + d_host + ":" << d_port << std::endl;

        SessionEventHandler eventHandler(d_identities, d_uuids);
        Session session(sessionOptions, &eventHandler);

        if (!session.start()) {
            std::cerr << "Failed to start session. Exiting..." << std::endl;
            std::exit(-1);
        }

        openServices(&session);

        EventQueue authQueue;

        // Authorize all the users that are interested in receiving data
        if (authorizeUsers(&authQueue, &session)) {
            // Make the various requests that we need to make
            sendRefDataRequest(&session);
        }

        // wait for enter key to exit application
        char dummy[2];
        std::cin.getline(dummy,2);

        {
            // Check if there were any authorization events received on the 'authQueue'
            Event event;
            while (0 == authQueue.tryNextEvent(&event)) {
                printEvent(event);
            }
        }
        session.stop();
        writefln("Exiting...");
    }
}
