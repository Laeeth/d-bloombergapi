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

usage["refdata"]=	"Usage:\n"
         			"    Retrieve reference data \n" 
         			"        [-ip        <ipAddress  = localhost>\n" 
         			"        [-p         <tcpPort    = 8194>" ;
usage["realtime"]=	"Usage:\n"
             		"    Retrieve realtime data \n"
             		"        [-ip        <ipAddress  = localhost>\n" 
             		"        [-p         <tcpPort    = 8194>\n" 
             		"        [-me        <maxEvents  = MAX_INT>\n" ;
usage["realtimesub"]=	"Usage:\n"
	            "    Retrieve realtime data\n"
    	        "        [-t     <topic      = IBM US Equity>\n"
        	    "        [-f     <field      = LAST_PRICE>\n"
            	"        [-o     <subscriptionOptions>\n"
	            "        [-ip    <ipAddress  = localhost>\n"
    	        "        [-p     <tcpPort    = 8194>\n"
	            "        [-qsize <queuesize  = 10000>\n";

usage["usermode"]=		"Usage:" 
            			"    UserMode Example" 
            			"        [-s     <security   = IBM US Equity>]" 
            			"        [-c     <credential uuid:ipAddress" 
            			" eg:12345:10.20.30.40>]" 
            			"        [-ip    <ipAddress  = localhost>]" 
            			"        [-p     <tcpPort    = 8194>]" 
            			"Note:" 
            			"Multiple securities and credentials can be" 
            			" specified.";

usage["contibutemktdata"]=
						"Market data contribution.\n" 
                    	"Usage:\n"
                    	"\t[-ip   <ipAddress>]  \tserver name or IP (default: localhost)\n" 
                    	"\t[-p    <tcpPort>]    \tserver port (default: 8194)\n" 
                    	"\t[-s    <service>]    \tservice name (default: //blp/mpfbapi)\n" 
                    	"\t[-t    <topic>]      \tservice name (default: /ticker/AUDEUR Curncy)\n" 
                    	"\t[-auth <option>]     \tauthentication option: user|none|app=<app>|dir=<property> (default: user)\n");
    
usage["entitlements"]=	 "Usage:\n"
        				"    Entitlements verification example\n" 
         				"        [-s     <security   = IBM US Equity>]\n" 
			            "        [-f     <field  = BEST_BID1>]\n"
         				"        [-c     <credential uuid:ipAddress\n" 
        				" eg:12345:10.20.30.40>]\n"
        				"        [-ip    <ipAddress  = localhost>]\n"
        				"        [-p     <tcpPort    = 8194>]\n"
        		         "        [-t     <token string>]\n"
				         " ie. token value returned in generateToken response\n" 
         			
        				"Note:\n" 
        				"Multiple securities and credentials or tokens can be\n" 
				        " specified, but only one field.";

usage["publishtopic"]=	"Publish on a topic. \n"
			             "Usage:\n" 
			             "\t[-ip   <ipAddress>]    \tserver name or IP (default: localhost)\n" 
			             "\t[-p    <tcpPort>]      \tserver port (default: 8194)\n" 
			             "\t[-s    <service>]      \tservice name (default: //blp/mpfbapi)\n" 
			             "\t[-t    <topic>]        \ttopic (default: 220/660/1)\n" 
			             "\t[-c    <contributorId>]\tcontributor id (default: 8563)\n" 
			             "\t[-auth <option>]       \tauthentication option: user|none|app=<app>|dir=<property> (default: user)\n";

usage["verifytoken"]=
				         "Usage:\n" 
				         "    Entitlements verification token example" 
				        "[-s     <security   = MSFT US Equity>]" 
				         "        [-t     <token string>]"
				         " ie. token value returned in generateToken response\n"
				         "        [-ip    <ipAddress  = localhost>]\n"
				         "        [-p     <tcpPort    = 8194>]\n'
				         "Note:\n"
				         "Multiple securities and tokens can be specified.");

usage["gentoken"]=
				    	"Usage:\n"
				         "    Generate a token for authorization \n" 
				         "        [-ip        <ipAddress  = localhost>\n"
				         "        [-p         <tcpPort    = 8194>\n" 
				         "        [-s         <security   = IBM US Equity>\n"
				         "        [-f         <field      = PX_LAST> or LAST_PRICE]\n" 
				         "        [-d         <dirSvcProperty = NULL>\n" );
				         "        [-o         <options    = NULL>]\n"
         				 "        [-auth      <option>    = user]\n");

usage["intradaybars"]=	"Usage:\n" 
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

usage["intradayticks"]="Usage:" << '\n'
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

usage["realtime"]= 		"Retrieve realtime data."
			        	 "Usage:" 
			             "\t[-ip   <ipAddress>]\tserver name or IP (default: localhost)" 
			             "\t[-p    <tcpPort>]  \tserver port (default: 8194)" 
			             "\t[-s    <service>]  \tservice name (default: //viper/mktdata))" 
			             "\t[-t    <topic>]    \ttopic name (default: /ticker/IBM Equity)" 
			             "\t[-f    <field>]    \tfield to subscribe to (default: empty)" 
			             "\t[-o    <option>]   \tsubscription options (default: empty)" 
			             "\t[-me   <maxEvents>]\tstop after this many events (default: INT_MAX)" 
			             "\t[-auth <option>]   \tauthentication option: user|none|app=<app>|userapp=<app>|dir=<property> (default: user)" 
usage["pagemon"]=		 "Page monitor."
			             "Usage:" 
			             "\t[-ip   <ipAddress>]  \tserver name or IP (default: localhost)" 
			             "\t[-p    <tcpPort>]    \tserver port (default: 8194)" 
			             "\t[-s    <service>]    \tservice name (default: //viper/page)" 
			             "\t[-me   <maxEvents>]  \tnumber of events to retrieve (default: MAX_INT)" 
			             "\t[-auth <option>]     \tauthentication option: user|none|app=<app>|userapp=<app>|dir=<property> (default: user)";

usage["publishmarket"]=	"Publish market data."
			             "Usage:"
			             "\t[-ip   <ipAddress>]  \tserver name or IP (default: localhost)" 
			             "\t[-p    <tcpPort>]    \tserver port (default: 8194)"
			             "\t[-s    <service>]    \tservice name (default: //viper/mktdata)"
			             "\t[-f    <field>]      \tfields (default: LAST_PRICE)"
			             "\t[-m    <messageType>]\ttype of published event (default: MarketDataEvents)"
			             "\t[-t    <topic>]      \ttopic (default: IBM Equity>]"
			             "\t[-g    <groupId>]    \tpublisher groupId (defaults to unique value)"
			             "\t[-auth <option>]     \tauthentication option: user|none|app=<app>|dir=<property> (default: user)";
			                 "\t[-e    <EID>]        \tpermission eid for all subscriptions"
			             "\t[-pri  <priority>]   \tset publisher priority level" " (default: 10)"
			             "\t[-c    <event count>]\tnumber of events after which cache" " will be cleared (default: 0 i.e cache never cleared)"
			             "\t[-ssc <option>]      \tactive sub-service code option:" "<begin>,<end>,<priority> "
			             "\t[-rssc <option>      \tsub-service code to be used in" " resolves."
usage["publishtopic"]=	("Publish on a topic. \n"
			         "Usage:\n" 
			         "\t[-ip   <ipAddress>]  \tserver name or IP (default: localhost)\n"
			         "\t[-p    <tcpPort>]    \tserver port (default: 8194)\n"
			         "\t[-s    <service>]    \tservice name (default: //viper/page)\n"
			         "\t[-g    <groupId>]    \tpublisher groupId (defaults to unique value)\n"
			         "\t[-pri  <priority>]   \tset publisher priority level (default: 10)\n"
			         "\t[-auth <option>]     \tauthentication option: user|none|app=<app>|userapp=<app>|dir=<property> (default: user)\n");

usage["retrieveref"]=	"Usage:\n"
				         "    Retrieve reference data \n" 
				         "        [-s         <security   = IBM US Equity>\n" 
				         "        [-f         <field      = PX_LAST>\n" 
				         "        [-ip        <ipAddress  = localhost>\n" 
				         "        [-p         <tcpPort    = 8194>\n" 
				         "        [-v         increase verbosity\n"
				         " (can be specified more than once)\n");

			             "\t[-r    <option>]     \tservice role option: server|client|both (default: both)";
            			 "\t[-auth <option>]     \tauthentication option: user|none|app=<app>|userapp=<app>|dir=<property> (default: user)"


usage["securitylookup"]="Usage: SecurityLookupExample [options]\n"
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


	
	static int streamWriter(const char* data, int length, void *stream)
    {
     assert(data);
     assert(stream);
     return cast(int)fwrite(data, length, 1, cast(FILE *)stream);
    }

	static void dumpEvent(const blpapi_Event_t *event,  UserData_t *userData)
	{
		blpapi_MessageIterator_t *iter = cast(blpapi_MessageIterator_t*)0;
		blpapi_Message_t *message = cast(blpapi_Message_t*)0;
		assert(event);
		static if (userData)
		{
			assert(userData.d_label);
			assert(userData.d_stream);
			fprintf(userData.d_stream, cast(const(char*))"handler label=%s\n", userData.d_label);
			fprintf(userData.d_stream, cast(const(char*))"eventType=%d\n",
		}
		writefln("eventType=%d", blpapi_Event_eventType(event));
		iter = blpapi_MessageIterator_create(event);
		assert(iter);
		while (0 == blpapi_MessageIterator_next(iter, &message)) {
			blpapi_CorrelationId_t correlationId;
			blpapi_Element_t *messageElements = cast(blpapi_Element_t *)0;
			assert(message);
			writefln("messageType=%s", blpapi_Message_typeString(message));
			messageElements=blpapi_Message_elements(message);
			correlationId = blpapi_Message_correlationId(message, 0);
			writefln("correlationId=%d %d %s", correlationId.xx.valueType, correlationId.xx.classId, correlationId.value.intValue);
			blpapi_Element_print(messageElements, &streamWriter, cast(void*)&stdout, 0, 4);
		}
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


    bool processEvent(const Event& event, Session *session)
	{
    	writefln("Client received an event");
	    MessageIterator iter(event);
	    while (iter.next()) {
	        Message msg = iter.message();
	        MutexGuard guard(&g_mutex);
	        writefln("%s",msg);
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


void openServices(Session *session,bool staticdata,bool mktdata)
{
    if (!session.openService(APIAUTH_SVC)) {
        writefln("Failed to open service: %s",APIAUTH_SVC);
        throw new Exception("Failed to open service: "~APIAUTH_SVC)
    }

    if staticdata
	{
		if (!session.openService(REFDATA_SVC)) {
    		writefln("Failed to open service: %s", REFDATA_SVC);
    		throw new Exception("Failed to open service: "~REFDATA_SVC);
		}
	}
	if mktdata
	{
	    if (!session.openService(MKTDATA_SVC)) {
	        writefln("Failed to open service: %s",  MKTDATA_SVC);
	        throw new Exception("Failed to open service: %s" ~ MKTDATA_SVC)
	    }
	}
}

void prepareServices(bool staticdata, bool mktdata)
{
 	SessionOptions sessionOptions;
 	sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s" , d_host , d_port);

    SessionEventHandler eventHandler(d_identities, d_uuids);
    Session session(sessionOptions, &eventHandler);

    if (!session.start()) {
        throw new Exception)("Failed to start session. Exiting...");
    }

	openServices(&session,staticdata,mktdata);

}

void lostname_butforauth()
{
        EventQueue authQueue;
        // Authorize all the users that are interested in receiving data
        if (authorizeUsers(&authQueue, &session)) {
            // Make the various requests that we need to make
            sendRefDataRequest(&session);
        }
        writefln("Press any key to continue");
        wait_key();
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

bool processEvent(const Event &event, Session *session) {
    if (event.eventType() == Event::SUBSCRIPTION_DATA) {
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            if (msg.hasElement(LAST_PRICE)) {
                Element field = msg.getElement(LAST_PRICE);
                writefln("%s = %s",field.name(),field.getValueAsString());
            }
        }
    }
    return true;
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

bool processEvent(const Event &event, Session *session)
    {
        try {
            switch (event.eventType()) {
              case Event::SUBSCRIPTION_DATA: {
                return processSubscriptionDataEvent(event);
              } break;
              case Event::SUBSCRIPTION_STATUS: {
                MutexGuard guard(&d_context_p.d_mutex);
                return processSubscriptionStatus(event, session);
              } break;
              case Event::ADMIN: {
                MutexGuard guard(&d_context_p.d_mutex);
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
        case Event::SESSION_STATUS:
        case Event::SERVICE_STATUS:
        case Event::REQUEST_STATUS:
        case Event::AUTHORIZATION_STATUS:
            printEvent(event);
            break;

        case Event::RESPONSE:
        case Event::PARTIAL_RESPONSE:
            processResponseEvent(event);
            break;
        }
        return true;
    }
}

bool processEvent(const Event& event, ProviderSession* session)
{
    printMessages(event);
    return true;
}

bool processEvent(const Event& event, ProviderSession* session)
{
    writefln("Server received an event");
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
        Service service = session.getService(d_serviceName.c_str());
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            writefln("%s",msg);
            if (msg.messageType() == Name("ReferenceDataRequest")) {
                // Similar to createPublishEvent. We assume just one
                // service - d_service. A responseEvent can only be
                // for single request so we can specify the
                // correlationId - which establishes context -
                // when we create the Event.
                if (msg.hasElement("timestamp")) {
                    double requestTime = msg.getElementAsFloat64("timestamp");
                    double latency = getTimestamp() - requestTime;
                    writefln("Response latency = %s",latency);
                }
                Event response = service.createResponseEvent(msg.correlationId());
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
                session.sendResponse(response);
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
            writefln("%s",msg);
            return false;
        } else {
            writefln("%s",msg);
        }
    }
    return true;
}
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
            writefln("%s",msg);
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
                it.second.setSubscribedState(true);
                if (it.second.isAvailable()) {
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
                if (it.second.isAvailable()) {
                    --g_availableTopicCount;
                }
                it.second.setSubscribedState(false);
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
                    Topic topic = session.getTopic(msg);
                    it.second.setTopic(topic);
                } catch (blpapi::Exception &e) {
                    stderr.writefln("Exception while processing TOPIC_CREATED: ",e.description());
                    continue;
                }
                if (it.second.isAvailable()) {
                    ++g_availableTopicCount;
                }

            }
            else if (msg.messageType() == TOPIC_RECAP) {
                // Here we send a recap in response to a Recap request.
                try {
                    std::string topicStr = msg.getElementAsString("topic");
                    MyStreams::iterator it = g_streams.find(topicStr);
                    MutexGuard guard(&g_mutex);
                    if (it == g_streams.end() || !it.second.isAvailable()) {
                        continue;
                    }
                    Topic topic = session.getTopic(msg);
                    Service service = topic.service();
                    CorrelationId recapCid = msg.correlationId();

                    Event recapEvent = service.createPublishEvent();
                    SchemaElementDefinition elementDef = service.getEventDefinition(d_messageType);
                    EventFormatter eventFormatter(recapEvent);
                    eventFormatter.appendRecapMessage(topic, &recapCid);
                    it.second.fillData(eventFormatter, elementDef);
                    guard.release().unlock();
                    session.publish(recapEvent);
                } catch (blpapi::Exception &e) {
                    stderr.writefln("Exception while processing TOPIC_RECAP: %s",e.description());
                    continue;
                }
            }
        }
        if (topicList.size()) {
            // createTopicsAsync will result in RESOLUTION_STATUS,
            // TOPIC_CREATED events.
            session.createTopicsAsync(topicList);
        }
    }
    else if (event.eventType() == Event::RESOLUTION_STATUS) {
        printMessages(event);
    }
    else if (event.eventType() == Event::REQUEST) {
        Service service = session.getService(d_serviceName.c_str());
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            writefln("%s",msg);
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
                            writefln("Mapping topic %s to subServiceCode %s",topicsElement.getValueAsString(i), d_resolveSubServiceCode);
                        }
                        catch (blpapi::Exception &e) {
                            stderr.writefln("subServiceCode could not be set.  Resolving without subServiceCode");
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
                session.sendResponse(response);
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
            writefln("%s",msg);
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
                it.second.setSubscribedState(true);
                if (it.second.isAvailable()) {
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
                if (it.second.isAvailable()) {
                    --g_availableTopicCount;
                }
                it.second.setSubscribedState(false);
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
                    Topic topic = session.getTopic(msg);
                    it.second.setTopic(topic);
                } catch (blpapi::Exception &e) {
                    stderr.writefln("Exception in Session::getTopic(): %s",e.description());
                    continue;
                }
                if (it.second.isAvailable()) {
                    ++g_availableTopicCount;
                }
            }
            else if (msg.messageType() == TOPIC_RECAP) {
                // Here we send a recap in response to a Recap request.
                try {
                    std::string topicStr = msg.getElementAsString("topic");
                    MyStreams::iterator it = g_streams.find(topicStr);
                    MutexGuard guard(&g_mutex);
                    if (it == g_streams.end() || !it.second.isAvailable()) {
                        continue;
                    }
                    Topic topic = session.getTopic(msg);
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
                    guard.release().unlock();
                    session.publish(recapEvent);
                } catch (blpapi::Exception &e) {
                    stderr.writefln("Exception in Session::getTopic(): %s",e.description());
                    continue;
                }
            }
        }
        if (topicList.size()) {
            // createTopicsAsync will result in RESOLUTION_STATUS,
            // TOPIC_CREATED events.
            session.createTopicsAsync(topicList);
        }
    }
    else if (event.eventType() == Event::RESOLUTION_STATUS) {
        printMessages(event);
    }
    else if (event.eventType() == Event::REQUEST) {
        Service service = session.getService(d_serviceName.c_str());
        MessageIterator iter(event);
        while (iter.next()) {
            Message msg = iter.message();
            writefln("%s",msg);
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
                session.sendResponse(response);
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
            writefln("%s",msg);
        }
    }

    return true;
}
bool MyEventHandler::processEvent(const Event& event, ProviderSession* session) {
    MessageIterator iter(event);
    while (iter.next()) {
        Message msg = iter.message();
        MutexGuard guard(&g_lock);
        writefln("%s",msg);
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
		processResponseEvent(event);
        break;
    return true;
}

bool processEvent(const Event &event, Session *session)
{
    switch(event.eventType()) {
    case Event.SESSION_STATUS, Event.SERVICE_STATUS, Event.REQUEST_STATUS, Event.AUTHORIZATION_STATUS:
        printEvent(event);
        break;
    case Event.SUBSCRIPTION_DATA:
		processSubscriptionDataEvent(event);
        break;
    }
    return true;
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
        processSubscriptionDataEvent(event);
        break;
    }
    return true;
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
		processResponseEvent(event);
        break;
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
            sendRequest();
        } else if (msg.messageType() == AUTHORIZATION_FAILURE) {
            writefln( "Authorization FAILED");
            return false;
        } else {
            writefln("%s",msg);
            if (event.eventType() == Event::RESPONSE) {
                writefln("Got Final Response");
                return false;
            }
        }
    }
    return true;
}
bool processEvent(const Event& event, ProviderSession* session)
    {
        MessageIterator iter(event);
        while (iter.next()) {
            MutexGuard guard(&g_lock);
            Message msg = iter.message();
            writefln("%s",msg);
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

    
void processResponseEvent(const Event &event,Session &session - optional bool distribute)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        if (msg.hasElement(RESPONSE_ERROR)) {
            writefln("%s",msg);
            printErrorInfo("REQUEST FAILED: ", msg.getElement(RESPONSE_ERROR));
            continue;
        }
        // We have a valid response. Distribute it to all the users.
        if (distribute)
			distributeMessage(msg);
		else
			processMessage(msg);

    }
}

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
                writefln("Processing %s securities",cast(uint)numSecurities);
                for (size_t i = 0; i < numSecurities; ++i) {
                    Element security = securities.getValueAsElement(i);
                    std::string ticker = security.getElementAsString(SECURITY);
                    writefln("Ticker: %s", ticker);
                    if (security.hasElement(SECURITY_ERROR)) {
                        printErrorInfo("\tSECURITY FAILED: ",
                            security.getElement(SECURITY_ERROR));
                        continue;
                    }

                    if (security.hasElement(FIELD_DATA)) {
                        const Element fields = security.getElement(FIELD_DATA);
                        if (fields.numElements() > 0) {
                            writefln("FIELD\t\tVALUE");
                            writefln("-----\t\t-----");
                            auto numElements = fields.numElements();
                            foreach(j; 0.. numElements)
                            {
                                Element field = fields.getElement(j);
                                writefln("%s\t\t%s",field.name(),field.getValueAsString());
                            }
                        }
                    }
                    writefln("");
                    Element fieldExceptions = security.getElement(FIELD_EXCEPTIONS);
                    if (fieldExceptions.numValues() > 0) {
                        writefln("FIELD\t\tEXCEPTION");
                        writefln("-----\t\t---------");
                        for (size_t k = 0; k < fieldExceptions.numValues(); ++k) {
                            Element fieldException = fieldExceptions.getValueAsElement(k);
                            Element errInfo = fieldException.getElement(ERROR_INFO);
                            writefln("%s\t\t%s ( %s )",fieldException.getElementAsString(FIELD_ID), errInfo.getElementAsString(CATEGORY),errInfo.getElementAsString(MESSAGE));
                        }
                    }
                }
            }
        }


} // extern (C)
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

void processResponseEvent(const Event &event)
    {
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            if (msg.hasElement(RESPONSE_ERROR)) {
                writefln("%s",msg);
            }
            writefln("Response for User %s",msg.correlationId().asInteger())
			writefln("%s",msg);
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


int main(string[] argv)
{
	blpapi_SessionOptions_t *sessionOptions = cast(blpapi_SessionOptions_t *)0;
	blpapi_Session_t *session = cast(blpapi_Session_t*)0;
	UserData_t userData = { "myLabel", cast(shared(_iobuf*))&stdout };
	/* IBM */
	string topic_IBM = "IBM US Equity";
	string[] fields_IBM = [ "LAST_TRADE" ];
	*options_IBM = cast(const(char**))0;
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

void printEvent(const Event &event)
{
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        CorrelationId correlationId = msg.correlationId();
        if (correlationId.asInteger() != 0) {
            writefln("Correlator: %s",correlationId.asInteger());
        }
        writefln("%s",msg);
    }
}



int main(string[] argv)
{
    writefln("ContributionsMktdataExample");
    writefln("ContributionsPageExample");
    writefln("Entitlements Verification Example");
    writefln("Entitlements Verification Subscription Example");
    writefln("Entitlements Verification Subscription Token Example");
    writefln("Entitlements Verification Token Example");
    writefln("GenerateTokenExample");
    writefln("GenerateTokenSubscriptionExample");
    writefln("IntradayBarExample");
    writefln("IntradayTickExample");
    writefln("LocalMktdataSubscriptionExample");
    writefln( "LocalPageSubscriptionExample");
    writefln( "MktdataBroadcastPublisherExample");
    writefln("MktdataPublisherExample");
	writefln("PagePublisherExample");
	writefln("RefDataExample");
	writefln("RefDataTableOverrideExample");
	writefln("RequestServiceExample");
	writefln("SecurityLookUp");
    writefln("SimpleBlockingRequestExample");
    writefln("SimpleCategorizedFieldSearchExample");
    writefln("SimpleFieldInfoExample");
    writefln("SimpleFieldSearchExample");
    writefln("SimpleHistoryExample");
    writefln("SimpleIntradayBarExample");
    writefln("SimpleIntradayTickExample");
    writefln("SimpleRefDataExample");
    writefln("SimpleRefDataOverrideExample");
    writefln("SimpleSubscriptionExample");
    writefln("SimpleSubscriptionIntervalExample");
    writefln("SimpleSubscriptionIntervalExample");
    writefln("SubscriptionCorrelationExample");
    writefln("SubscriptionCorrelationExample");
	writefln("UserModeExample");

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


string d_id;
Topic d_topic;
MyStream() : d_id("") {}
MyStream(string const& id) : d_id(id) {}
void setTopic(Topic const& topic) { d_topic = topic; }
string const& getId() { return d_id; }
Topic const& getTopic() { return d_topic; }
MyStream[] MyStreams
bool processEvent(const Event& event, ProviderSession* session);


bool parseCommandLine(string[] argv, whichmode mode)
{
	string[] securities;
	auto argc=argv.length-1
	foreach(i,arg;argv[1..$])
	{
        switch(arg)
        {
        	case "-s":
        		if (i<argc)
        		{
        			securities~=argv[i+1];
        			skipnextarg=true;
        		}
        	case "-f":
        		if (i<argc)
      			{
        			fields~=argv[i+1];
        			skipnextarg=true;
        		}
        	case "-ip":
        		if (i<argc)
      			{
        			hosts~=argv[i+1];
        			skipnextarg=true;
        		}
        	case "-p":
        		if (i<argc)
      			{
        			ports~=to!int(argv[i+1]);
        			skipnextarg=true;
        		}
  		    case "-v":
  		    	verbosityCount++;
			case "-r":
				if (i<argc)
				{
					d_requestType = Name(argv[++i]);
		            if (d_requestType != INSTRUMENT_LIST_REQUEST && d_requestType != CURVE_LIST_REQUEST && d_requestType != GOVT_LIST_REQUEST)
		            {
		                printUsage();
                		return false;
                	}
        		}
        	case  "-sq":
				if (i<argc)
        		{
        			queries~=argv[i+1];
        			skipnextarg=true;
        		}
        
			case "-m":
				if (i<argc)
        		{
        			maxresults=to!int(argv[i+1]);
        			skipnextarg=true;
        		}

			case "-ff":
				if (i<argc)
        		{
		            //std::string assign(argv[++i]);
        		    //std::string::size_type idx = assign.find_first_of('=');
            		//d_filters[assign.substr(0, idx)] = assign.substr(idx + 1);
        			//fo;yersmaxresults=to!int(argv[i+1]);
        			skipnextarg=true;
        		}

        	case "-r":
				if (i<argc)
        		{
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
        			skipnextarg=true;
        		}

        	case "-ss":
				if (i<argc)
        		{
	            d_service = argv[++i];
        			skipnextarg=true;
        		}

        	case "-g":
				if (i<argc)
        		{
		            d_groupId = argv[++i];
        			skipnextarg=true;
        		}

        	case "-pri":
				if (i<argc)
        		{
		            d_priority = std::atoi(argv[++i]);
        			skipnextarg=true;
        		}

        	case "-c":
				if (i<argc)
        		{
	                d_clearInterval = std::atoi(argv[++i]);
		            skipnextarg=true;
        		}
        	case "-m":
				if (i<argc)
        		{
	                d_messageType = argv[++i];
		            skipnextarg=true;
        		}
        	case "-t":
				if (i<argc)
        		{
	                d_topic = argv[++i];
		            skipnextarg=true;
        		}
			case "-me":
				if (i<argc)
        		{
	                d_maxEvents = std::atoi(argv[++i]);
		            skipnextarg=true;
        		}
            case "-o":
				if (i<argc)
        		{
	                options~=argv[i+1];
		            skipnextarg=true;
        		}
            case "-d":
				if (i<argc)
        		{
            		d_useDS = true;
            		d_DSProperty = argv[++i];
            	}
			case "-cc":
	            d_conditionCodes = true;
    		case "-sd":
				if (i<argc)
        		{
		            d_startDateTime = pbdatetime(argv[i+1]);
		            skipnextarg=true;
            	}
        	case "-ed":
        		break;
			case "-":
				if (i<argc)
        		{
	                d_service = arg;
            	}

            case "-auth":
				if (i<argc)
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
		        }
        if ((!argv[i]=="-t") && (i + 1 < argv.length)) {
            d_tokens.push_back(argv[++i]);
            ++tokenCount;
            writefln("User #%s token: %s", tokenCount, argv[i]);
            continue;
        }
            if (!std::strcmp(argv[i],"-t") && i + 1 < argc)
                d_topics.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-f") && i + 1 < argc)
                d_fields.push_back(argv[++i]);
            else if (!std::strcmp(argv[i],"-o") && i + 1 < argc)
                d_options.push_back(argv[++i]);
                d_sessionOptions.setServerPort(std::atoi(argv[++i]));
            else if (!std::strcmp(argv[i],"-qsize") &&  i + 1 < argc)
                d_sessionOptions.setMaxEventQueueSize(std::atoi(argv[++i]));

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

		   else if (!argv[i]=="-c")) {
            if (++i >= argv.length) return false;

            string credential = argv[i];
            size_t idx = credential.find_first_of(':');
            if (idx == std::string::npos) return false;
            d_uuids.push_back(atoi(credential.substr(0,idx).c_str()));
            d_programAddresses.push_back(credential.substr(idx+1));
            continue;
     

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

            if (!std::strcmp(argv[i],"-s") ) {
                if (++i >= argc) return false;
                d_securities.push_back(argv[i]);
            }

            else {
    


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


			default:
                printUsage();
                return false;
		}
        return true;

                if (d_uuids.size() <= 0) {
            writefln("No uuids were specified");
            return false;
        }

        if (d_uuids.size() != d_programAddresses.size()) {
            writefln(""Invalid number of program addresses provided");
            return false;
        }

        if (d_securities.size() <= 0) {
            d_securities~="IBM US Equity";
        }

        return true;
    }
        if (d_hosts.empty()) {
            d_hosts.push_back("localhost");
        }
        return true;
    }

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

    if (d_fields.size() == 0) {
        d_fields.push_back("PX_LAST");
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
        if (d_fields.empty()) {
            d_fields.push_back(Name("BID"));
            d_fields.push_back(Name("ASK"));
        }
        return true;
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
        if (!d_fields.size()) {
            d_fields.push_back(Name("LAST_PRICE"));

            if(verbosityCount) {
                registerCallback(verbosityCount);
            }


    }


struct exampledata
{
	string[] hosts;
	int[] ports;
	string contribservice="//blp/mpfbapi";
    string contribtopic="/ticker/AUDEUR Curncy";
    string authOptions=AUTH_USER;
 }
    bool authorize(const Service& authService, Identity *providerIdentity, ProviderSession *session, const CorrelationId& cid)
    {
		{
            MutexGuard guard(&g_lock); g_authorizationStatus[cid] = WAITING;
        }
        EventQueue tokenEventQueue;
        session.generateToken(CorrelationId(), &tokenEventQueue);
        std::string token;
        Event event = tokenEventQueue.nextEvent();
        if (event.eventType() == Event::TOKEN_STATUS || event.eventType() == Event::REQUEST_STATUS) {
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
            writefln("Failed to get token");
            return false;
        }

        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set(TOKEN, token.c_str());

        session.sendAuthorizationRequest(
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

    



    void publishrun(string[] argv,bool pagemode)
    {
        if (!parseCommandLine(argc, argv)) return;

        SessionOptions sessionOptions;
        foreach(i,host; hosts)
        {
            sessionOptions.setServerAddress(host.c_str(), d_port, i);
        }
        sessionOptions.setServerPort(d_port);
        sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
        sessionOptions.setAutoRestartOnDisconnection(true);
        sessionOptions.setNumStartAttempts(d_hosts.size());

        writefln("Connecting to port %s on %s", d_port, std::copy(d_hosts.begin(), d_hosts.end(),streamWriter checksyntax, " "));

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
                isAuthorized = authorize(authService, &providerIdentity, &session, CorrelationId((void *)"auth"));
            }
            if (!isAuthorized) {
                stderr.writefln("No authorization");
                return;
            }
        }

        TopicList topicList;
        topicList.add(((d_service ~"/") ~ d_topic).c_str(), CorrelationId(new MyStream(d_topic))); // do we need the slash in there

        session.createTopics(&topicList, ProviderSession::AUTO_REGISTER_SERVICES, providerIdentity);
        // createTopics() is synchronous, topicList will be updated
        // with the results of topic creation (resolution will happen
        // under the covers)

        MyStreams myStreams;

        foreach(i;0..topicList.size())
        {
            MyStream *stream = cast(MyStream*)(topicList.correlationIdAt(i).asPointer());
            int resolutionStatus = topicList.statusAt(i);
            if (resolutionStatus == TopicList::CREATED) {
                Topic topic = session.getTopic(topicList.messageAt(i));
                stream.setTopic(topic);
                myStreams.push_back(stream);
            }
            else {
                writefln("Stream '%s': topic not resolved, status=%s",stream.getId(),resolutionStatus);
            }
        }

        Service service = session.getService(d_service.c_str());
        // Now we will start publishing


        if (!pagemode)
        {
	        int value = 1;
	        while (myStreams.size() > 0 && g_running) {
	            Event event = service.createPublishEvent();
	            EventFormatter eventFormatter(event);

	            for (MyStreams::iterator iter = myStreams.begin();
	                 iter != myStreams.end(); ++iter)
	            {
	                eventFormatter.appendMessage(MARKET_DATA, (*iter).getTopic());
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
	    else
	    {
	        while (g_running) {
	            Event event = service.createPublishEvent();
	            EventFormatter eventFormatter(event);

	            for (MyStreams::iterator iter = myStreams.begin();
	                 iter != myStreams.end(); ++iter) {
	                eventFormatter.appendMessage("PageData", (*iter).getTopic());
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

void run(string[] argv) {
    if (!parseCommandLine(argc, argv)) {
        printUsage();
        return;
    }

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);
    writefln("Connecting to %s:%s", d_host , d_port);
    SessionEventHandler eventHandler(d_identities, d_tokens, d_securities, d_field);
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
// EntitlementsVerificationTokenExample.cpp
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
void run(int argc, string[] argv)
{
    if (!parseCommandLine(argc, argv)) return;
    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s", d_host , d_port);
    Session session(sessionOptions);
    if (!session.start()) {
        stderr.writefln( "Failed to start session.");
        return;
    }
    if (!session.openService("//blp/refdata")) {
        stderr.writefln("Failed to open //blp/refdata");
        return;
    }

    sendIntradayTickRequest(session);

    // wait for events from session.
    eventLoop(session);

    session.stop();
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

        writefln("Connecting to port %s on:",d_port);
        foreach(i;0..sessionOptions.numServerAddresses())
        {
            ushort port;
            const char *host;
            sessionOptions.getServerAddress(&host, &port, i);
            writefln((i? ", ": "") ~ host);
        }

        Session session(sessionOptions);
        if (!session.start()) {
            stderr.writefln("Failed to start session.");
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
                stderr.writefln("No authorization");
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
                    writefln("%s - ",topic);
                }
                writefln("%s",msg);
            }
            if (event.eventType() == Event::SUBSCRIPTION_DATA) {
                if (++d_eventCount >= d_maxEvents) break;
            }
        }
    }
};
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

        writefln("Connecting to port %s on ", d_port);
        foreach(i;0..sessionOptions.numServerAddresses())
        {
            ushort port;
            const char *host;
            sessionOptions.getServerAddress(&host, &port, i);
            writefln("%s,: ",i,host);
        }
        
        Session session(sessionOptions);
        if (!session.start()) {
            stderr.writefln("Failed to start session.");
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
                stderr.writefln("No authorization");
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
                    writefln("%s - ", topic);
                }
                writefln("%s",msg);
            }
            if (event.eventType() == Event::SUBSCRIPTION_DATA) {
                if (++d_eventCount >= d_maxEvents) break;
            }
        }
    }
};

void test_topicpublish(0
{
    SessionOptions sessionOptions;
    foreach(i,host;d_hosts)
    {
        sessionOptions.setServerAddress(host.c_str(), d_port, i);
    }
    sessionOptions.setServerPort(d_port);
    sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
    sessionOptions.setAutoRestartOnDisconnection(true);
    sessionOptions.setNumStartAttempts(d_hosts.size() > 1? 1: 1000);

    MyEventHandler myEventHandler;
    ProviderSession session(sessionOptions, &myEventHandler, 0);

    writefln("Connecting to port %s on %s",d_port,d_hosts()); // range check works

    if (!session.start()) {
        MutexGuard guard(&g_lock);
        stderr.writefln("Failed to start session - mutex lock.");
        return;
    }

    Identity providerIdentity = session.createIdentity();
    if (!d_authOptions.empty()) {
        bool isAuthorized = false;
        const char* authServiceName = "//blp/apiauth";
        if (session.openService(authServiceName)) {
            Service authService = session.getService(authServiceName);
            isAuthorized = authorize(authService, &providerIdentity, &session, CorrelationId((void *)"auth"));
        }
        if (!isAuthorized) {
            stderr.writefln("No authorization");
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
            stderr.writefln("Failed to register %s", d_service);
            return;
        }
    }

    TopicList topicList;
    topicList.add((d_service + "/ticker/" + d_topic).c_str(), CorrelationId(new MyStream(d_topic)));

    session.createTopics(&topicList, ProviderSession::AUTO_REGISTER_SERVICES, providerIdentity);
    // createTopics() is synchronous, topicList will be updated
    // with the results of topic creation (resolution will happen
    // under the covers)

    MyStreams myStreams;

    foreach(i,topic;topicList)
    {
        auto *stream = cast(MyStream*)(topicList.correlationIdAt(i).asPointer());
        int status = topicList.statusAt(i);
        if (status == TopicList::CREATED) {
            {
                MutexGuard guard(&g_lock);
                writefln("Start publishing on topic: %s", d_topic);
            }
            auto topic = session.getTopic(topicList.messageAt(i));
            stream.setTopic(topic);
            myStreams.push_back(stream);
        }
        else {
            MutexGuard guard(&g_lock);
            writefln("Stream '%s': topic not created, status = ",stream.getId(),status);
        }
    }

    auto  service = session.getService(d_service.c_str());
    Name PUBLISH_MESSAGE_TYPE(d_messageType.c_str());

    // Now we will start publishing
    int tickCount = 1;
    while (myStreams.size() > 0 && g_running) {
        Event event = service.createPublishEvent();
        EventFormatter eventFormatter(event);

        for (iter; myStreams)
        {
            const Topic& topic = (*iter).getTopic();
            if (!topic.isActive())  {
                writefln("[WARN] Publishing on an inactive topic.");
            }
            eventFormatter.appendMessage(PUBLISH_MESSAGE_TYPE, topic);

            for (uint i = 0; i < d_fields.size(); ++i) {
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

void run(int argc, char **argv)
{
    if (!parseCommandLine(argc, argv))
        return;

    SessionOptions sessionOptions;
    foreach(i,host;d_hosts)
    {
        sessionOptions.setServerAddress(d_hosts[i].c_str(), d_port, i);
    }
    sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
    sessionOptions.setAutoRestartOnDisconnection(true);
    sessionOptions.setNumStartAttempts(d_hosts.size());

    writefln("Connecting to port %s on %s", d_port,d_hosts);
    MyEventHandler myEventHandler(d_service);
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
            stderr.writefln( "No authorization");
            return;
        }
    }

    ServiceRegistrationOptions serviceOptions;
    serviceOptions.setGroupId(d_groupId.c_str(), d_groupId.size());
    serviceOptions.setServicePriority(d_priority);
    if (!session.registerService(d_service.c_str(), providerIdentity, serviceOptions)) {
        stderr.writefln("Failed to register %s", d_service);
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
                guard.release().unlock();
                SLEEP(1);
                continue;
            }

            EventFormatter eventFormatter(event);
            for (MyStreams::iterator iter = g_streams.begin();
                iter != g_streams.end(); ++iter) {
                if (!iter.second.isAvailable()) {
                    continue;
                }
                std::ostringstream os;
                os << ++value;

                if (!iter.second.isInitialPaintSent()) {
                    eventFormatter.appendRecapMessage(
                                                    iter.second.topic());
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
                    iter.second.setIsInitialPaintSent(true);
                }

                eventFormatter.appendMessage("RowUpdate", iter.second.topic());
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

        writefln("Connecting to port %s on ", d_port);
        std::copy(d_hosts.begin(),
                  d_hosts.end(),
                  std::ostream_iterator<std::string>(std::cout, " "));

        Name PUBLISH_MESSAGE_TYPE(d_messageType.c_str());

        MyEventHandler myEventHandler(d_service,
                                      PUBLISH_MESSAGE_TYPE,
                                      d_fields,
                                      d_eids,
                                      d_resolveSubServiceCode);
        ProviderSession session(sessionOptions, &myEventHandler, 0);
        d_session_p = & session;
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
                stderr.writefln( "No authorization");
                return;
            }
        }

        ServiceRegistrationOptions serviceOptions;
        serviceOptions.setGroupId(d_groupId.c_str(), d_groupId.size());
        serviceOptions.setServicePriority(d_priority);
        if (d_useSsc) {
            writefln("Adding active sub service code range [%s,%s] @ priority %s",d_sscBegin, d_sscEnd, d_sscPriority);
            try {
                serviceOptions.addActiveSubServiceCodeRange(d_sscBegin, d_sscEnd, d_sscPriority);
            }
            catch (Exception& e) {
                stderr.writefln("FAILED to add active sub service codes. Exception %s",e.description());
            }
        }
        if (!session.registerService(d_service.c_str(),
                                     providerIdentity,
                                     serviceOptions)) {
            stderr.writefln("Failed to register %s",d_service);
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
                    guard.release().unlock();
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
                    if (!iter.second.isAvailable()) {
                        continue;
                    }
                    eventFormatter.appendMessage(
                            PUBLISH_MESSAGE_TYPE,
                            iter.second.topic());
                    if (publishNull) {
                        iter.second.fillDataNull(eventFormatter, elementDef);
                    } else {
                        ++eventCount;
                        iter.second.next();
                        iter.second.fillData(eventFormatter, elementDef);
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
    



void serverRun(ProviderSession *providerSession)
{
    ProviderSession& session = *providerSession;
    writefln("Server is starting------");
    if (!session.start()) {
        stderr.writefln("Failed to start server session.");
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
            stderr.writefln("No authorization");
            return;
        }
    }

    if (!session.registerService(d_service.c_str(), providerIdentity)) {
        stderr.writefln("Failed to register %s", d_service);
        return;
    }
}

void clientRun(Session *requesterSession)
{
    Session& session = *requesterSession;
    writefln("Client is starting------");
    if (!session.start()) {
        stderr.writefln("Failed to start client session.");
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
            stderr.writefln("No authorization");
            return;
        }
    }

    if (!session.openService(d_service.c_str())) {
        stderr.writefln("Failed to open %s", d_service);
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
        writefln("Sending Request: %s",request);
    }
    EventQueue eventQueue;
    session.sendRequest(request, identity,
            CorrelationId((void *)"AddRequest"), &eventQueue);

    while (true) {
        Event event = eventQueue.nextEvent();
        writefln("Client received an event");
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            MutexGuard guard(&g_mutex);
            if (event.eventType() == Event::RESPONSE) {
                if (msg.hasElement("timestamp")) {
                    double responseTime = msg.getElementAsFloat64(
                                            "timestamp");
                    writefln("Response latency = %s",getTimestamp() - responseTime);
                }
            }
            writefln("%s",msg);
        }
        if (event.eventType() == Event::RESPONSE) {
            break;
        }
    }
}

    void run(int argc, char **argv)
    {
        d_host = "localhost";
        d_port = 8194;
        if (!parseCommandLine(argc, argv)) return;

        SessionOptions sessionOptions;
        sessionOptions.setServerHost(d_host.c_str());
        sessionOptions.setServerPort(d_port);

        writefln("Connecting to %s:%s", d_host, d_port);
        Session session(sessionOptions);
        if (!session.start()) {
            stderr.writefln("Failed to start session.";
            return;
        }
        if (!session.openService("//blp/refdata")) {
            stderr.writefln("Failed to open //blp/refdata");
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

        writefln("Sending Request: %s",request)l;
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

    writefln("Connecting to port %s on %s", d_port, copy(d_hosts.begin(), d_hosts.end(), std::ostream_iterator<std::string>(std::cout, " "));
    
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
    writefln("Press ENTER to quit");
	wait_key();
    if (d_role == SERVER || d_role == BOTH) {
        providerSession.stop();
    }
    if (d_role == CLIENT || d_role == BOTH) {
        requesterSession.stop();
    }
}

void run(int argc, char **argv)
{
    if (!parseCommandLine(argc, argv))
        return;

    initializeSessionOptions();

    writefln(">>> Connecting to %s:%s",d_host,d_port);
    
    Session session(d_sessionOptions);
    if (!session.start()) {
        writefln(">>> Failed to start session");
        return;
    }

    if (!d_authOptions.empty()) {
        bool isAuthorized = false;
        const char* authServiceName = AUTH_SERVICE;
        if (session.openService(authServiceName)) {
            Service authService = session.getService(authServiceName);
            isAuthorized = authorize(authService, &session, CorrelationId((void*)("auth")));
        }
        if (!isAuthorized) {
            stderr.writefln(">>> No authorization");
            return;
        }
    }

    if (!session.openService(INSTRUMENTS_SERVICE)) {
        writefln(">>> Failed to open %s",INSTRUMENTS_SERVICE);
        return;
    }

    sendRequest(&session);

    eventLoop(&session);
    session.stop();
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


string d_host;
int d_port;


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
            writefln("%s",msg.messageType());
            writefln("%s",msg);
        }
        if (event.eventType() == Event::RESPONSE) {
            break;
        }
    }
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
            stderr.writefln("unable to get previous trading date");
    }

    Datetime starttime;
    starttime.setDate(tradedOnYear, tradedOnMonth, tradedOnDay);
    starttime.setTime(13, 30, 0, 0);
    request.set("startDateTime", starttime );

    Datetime endtime;
    endtime.setDate(tradedOnYear, tradedOnMonth, tradedOnDay);
    endtime.setTime(13, 35, 0, 0);
    request.set("endDateTime", endtime);

    writefln("Sending Request: %s", request);
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
string d_host;
int d_port;

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
            writefln("%s",msg);
        }
        if (event.eventType() == Event::RESPONSE) {
            break;
        }
    }
}

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

        writefln("Connecting to %s:%s",  d_host, d_port);
        Session session(sessionOptions);
        if (!session.start()) {
            stderr.writefln("Failed to start session.");
            return;
        }
        if (!session.openService("//blp/mktdata")) {
            stderr.writefln("Failed to open //blp/mktdata");
            return;
        }

        const char *security1 = "IBM US Equity";
        const char *security2 = "/cusip/912810RE0@BGN";
            // this CUSIP identifies US Treasury Bill 'T 3 5/8 02/15/44 Govt'

        SubscriptionList subscriptions;
        subscriptions.add(security1, "LAST_PRICE,BID,ASK", "", CorrelationId((char *)security1));
        subscriptions.add(security2, "LAST_PRICE,BID,ASK,BID_YIELD,ASK_YIELD", "", CorrelationId((char *)security2));
        session.subscribe(subscriptions);

        while (true) {
            Event event = session.nextEvent();
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (event.eventType() == Event::SUBSCRIPTION_STATUS ||
                    event.eventType() == Event::SUBSCRIPTION_DATA) {
                    const char *topic = (char *)msg.correlationId().asPointer();
                    writefln("%s - ",topic);
                }
                writefln("%s",msg);
            }
            if (event.eventType() == Event::SUBSCRIPTION_DATA) {
                if (++d_eventCount >= d_maxEvents) break;
            }
        }
    }
};



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

        writefln("Connecting to %s:%s",d_host, d_port);
        Session session(sessionOptions);
        if (!session.start()) {
            stderr.writefln("Failed to start session.");
            return;
        }
        if (!session.openService("//blp/mktdata")) {
            stderr.writefln("Failed to open //blp/mktdata");
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
                    writefln("%s - ", topic);
                }
                writefln("%s",msg);
            }
            if (event.eventType() == Event::SUBSCRIPTION_DATA) {
                if (++d_eventCount >= d_maxEvents) break;
            }
        }
    }
};
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

        writefln("Connecting to %s:%s", d_host ,d_port);
        Session session(sessionOptions);
        if (!session.start()) {
            stderr.writefln("Failed to start session.");
            return;
        }
        if (!session.openService("//blp/mktdata")) {
            stderr.writefln("Failed to open //blp/mktdata");
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

void run(int argc, char **argv)
    {
        if (!parseCommandLine(argc, argv)) return;
        if (!createSession()) return;

        // wait for enter key to exit application
        writefln("Press ENTER to quit");
        wait_key();
        {
            MutexGuard guard(&d_context.d_mutex);
            d_context.d_isStopped = true;
        }
        d_session.stop();
        writefln("\nExiting...");
    }
};

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


} // anonymous namespace

class SessionEventHandler: public  EventHandler
{
std::vector<Identity> &d_identities;
std::vector<int> &d_uuids;

void printFailedEntitlements(std::vector<int> &failedEntitlements,
    int numFailedEntitlements)
{
    for (int i = 0; i < numFailedEntitlements; ++i) {
        writefln("%s", failedEntitlements[i]);
    }
}

void distributeMessage(Message &msg)
{
    Service service = msg.service();

    std::vector<int> failedEntitlements;
    Element securities = msg.getElement(SECURITY_DATA);
    int numSecurities = securities.numValues();

    writefln("Processing %s securities", numSecurities);
    foreach( i;0.. numSecurities)
    {
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
                        writefln("User: %s is entitled to get data for: %s", d_uuids[j],ticker);
                        // Now Distribute message to the user.
                }
                else {
                    writefln("User: %s is NOT entitled to get data for: %s - Failed eids:", d_uuids[j], ticker);
                    printFailedEntitlements(failedEntitlements, numFailures);
                }
            }
        }
        else {
            // No Entitlements are required to access this data.
            foreach(j;0.. numUsers; ++j) {
                writefln("User: %s is entitled to get data for: %s", d_uuids[j]. ticker);
                // Now Distribute message to the user.
            }
        }
    }
}


// need to fix this to work with ipaddress and token not just uuid

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
        //authRequest.set("ipAddress", d_programAddresses[i].c_str());

        //authRequest.set("token", d_tokens[i].c_str());
        //CorrelationId correlator(i);
        
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

bool authorizeUsers(EventQueue *authQueue, Session *session)
{
    Service authService = session.getService(APIAUTH_SVC);
    bool is_any_user_authorized = false;

    // Authorize each of the users
    d_identities.reserve(d_tokens.size());
    foreach(i;0.. d_tokens.size())
    {
        d_identities.push_back(session.createIdentity());
        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set("token", d_tokens[i].c_str());

        CorrelationId correlator(i);
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

bool authorizeUsers(EventQueue *authQueue, Session *session)
    {
        Service authService = session.getService(APIAUTH_SVC);
        bool is_any_user_authorized = false;

        // Authorize each of the users
        d_identities.reserve(d_uuids.size());
        for (size_t i = 0; i < d_uuids.size(); ++i) {
            d_identities.push_back(session.createIdentity());
            Request authRequest = authService.createAuthorizationRequest();
            authRequest.set("uuid", d_uuids[i]);
            authRequest.set("ipAddress", d_programAddresses[i].c_str());

            session.sendAuthorizationRequest(authRequest,
                                              &d_identities[i],
                                              CorrelationId(i),
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
                        writefln("%s authorization success",d_uuids[msg.correlationId().asInteger()]);
                        is_any_user_authorized = true;
                    }
                    else if (msg.messageType() == AUTHORIZATION_FAILURE) {
                        writefln("%s authorization failed",d_uuids[msg.correlationId().asInteger()]);
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



void sendRefDataRequest(Session *session,bool lastupdat,bool server)
{
    Service service = session.getService(REFDATA_SVC);
    Request request = service.createRequest(REFRENCEDATA_REQUEST);

    // Add securities.
    Element securities = request.getElement("securities");
    foreach(i;0..d_securities.size()) {
        securities.appendValue(d_securities[i].c_str());
    }

    // Add fields
    Element fields = request.getElement("fields");
    fields.appendValue("PX_LAST");
    if (lastupdate)
		fields.appendValue("LAST_UPDATE");
	else
		fields.appendValue("DS002");

    request.set("returnEids", true);

    if (server)
    {
    	writefln("Sending RefDataRequest using server credentials...");
    	session.sendRequest(request),d_identities[];
    }
    else
    {
    	int uuid;
    	foreach(k;0..d_identities.size())
    	{
            uuid = d_uuids[j];
            writefln("Sending RefDataRequest for User %s",uuid);
			session.sendRequest(request,d_identities[j],CorrelationId(uuid));
        }
    }

}




bytesEID("EID");
bytesAUTHORIZATION_SUCCESS("AuthorizationSuccess");
bytesAUTHORIZATION_FAILURE("AuthorizationFailure");

const char* APIAUTH_SVC             = "//blp/apiauth";
const char* MKTDATA_SVC             = "//blp/mktdata";

} // anonymous namespace



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








public:

EntitlementsVerificationSubscriptionExample()
: d_host("localhost")
, d_port(8194)
, d_field("BEST_BID1")
{
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
        writefln("\t%s", topic);
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
                    writefln("User #%s is entitled for %s",to!string((i+1)), field);
            }
            else {
                writefln("User #%s is NOT entitled for %s", to!string(i+1), d_fieldName);
            }
        }
    }
}


void printFailedEntitlements(int[] failedEntitlements, int numFailedEntitlements)
{
    foreach(i;0.. numFailedEntitlements)
        writefln("%s",failedEntitlements[i]);
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
            foreach(j;0.. numUsers) []
                writefln("User: %s is entitled to get data for: %s",d_tokens[j],ticker);
            }
        }
    }
}


void sendRequest()
{
	auto refDataService = d_session.getService("//blp/refdata");
    auto request = refDataService.createRequest("ReferenceDataRequest");

    // Add securities to request
    Element securities = request.getElement("securities");
    foreach(i;0.. d_securities.size()) {
        securities.appendValue(d_securities[i].c_str());
    
    }

    // Add fields to request
    Element fields = request.getElement("fields");
    for (size_t i = 0; i < d_fields.size(); ++i) {
        fields.appendValue(d_fields[i].c_str());
    }

    writefln("Sending Request: %s", request);
     _session.sendRequest(request, d_identity);
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
            d_session.sendAuthorizationRequest(authRequest, &d_identity,
                CorrelationId(1));
        } else if (msg.messageType() == TOKEN_FAILURE) {
            msg.print(std::cout);
            return false;
        }
    }

    return true;
}


~GenerateTokenExample()
{
    if (d_session) {
        d_session.stop();
        delete d_session;
    }
}


void subscribe()
{
    SubscriptionList subscriptions;

    foreach(i;0.. d_securities.size())
    {
        subscriptions.add(d_securities[i].c_str(), d_fields, d_options, CorrelationId(i + 100));
    }

    writefln("Subscribing...");
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



    void printErrorInfo(const char *leadingStr, const Element &errorInfo)
    {
        writefln("%s %s  (%s)",leadingStr,errorInfo.getElementAsString(CATEGORY),errorInfo.getElementAsString(MESSAGE));
    }

    
    void processMessage(Message &msg) {
        Element data = msg.getElement(BAR_DATA).getElement(BAR_TICK_DATA);
        auto numBars = data.numValues();
        writefln("Response contains %s bars", numBars);
        writefln("Datetime\t\tOpen\t\tHigh\t\tLow\t\tClose\t\tNumEvents\tVolume");
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

        writefln("Sending Request: %s",request);
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
            if (tm_p.tm_wday == 0 || tm_p.tm_wday == 6 ) {// Sun/Sat
                continue ;
            }
            startDate_p.setDate(tm_p.tm_year + 1900,
                tm_p.tm_mon + 1,
                tm_p.tm_mday);
            startDate_p.setTime(13, 30, 0) ;

            //the next day is the end day
            currTime += 86400 ;
            tm_p = localtime(&currTime);
            if (tm_p == NULL) {
                break;
            }
            endDate_p.setDate(tm_p.tm_year + 1900,
                tm_p.tm_mon + 1,
                tm_p.tm_mday);
            endDate_p.setTime(13, 30, 0) ;

            return(0) ;
        }
        return (-1) ;
    }

    



void printErrorInfo(const char *leadingStr, const Element &errorInfo)
{
    writefln("%s %s (%s)",leadingStr,errorInfo.getElementAsString(CATEGORY), errorInfo.getElementAsString(MESSAGE));
}


void processMessage(Message &msg)
{
    Element data = msg.getElement(TICK_DATA).getElement(TICK_DATA);
    int numItems = data.numValues();
    writefln("TIME\t\t\t\tTYPE\tVALUE\t\tSIZE\tCC");
    writefln("----\t\t\t\t----\t-----\t\t----\t--");
    std::string cc;
    std::string type;
    foreach(i;0.. numItems)
    {
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

        writefln("%s\t%s\t%s\t%s\t%s",timeString,type,value,size,cc); // we can make it pretty later
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

    writefln("Sending Request: %s", request);
    session.sendRequest(request);
}

void eventLoop(Session &session)
{
    bool done = false;
    while (!done) {
        Event event = session.nextEvent();
        if (event.eventType() == Event::PARTIAL_RESPONSE) {
            writefln("Processing Partial Response");
            processResponseEvent(event);
        }
        else if (event.eventType() == Event::RESPONSE) {
            writefln("Processing Response");
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
        if (tm_p.tm_wday == 0 || tm_p.tm_wday == 6 ) {// Sun/Sat
            continue ;
        }

        startDate_p.setDate(tm_p.tm_year + 1900,
            tm_p.tm_mon + 1,
            tm_p.tm_mday);
        startDate_p.setTime(15, 30, 0) ;

        endDate_p.setDate(tm_p.tm_year + 1900,
            tm_p.tm_mon + 1,
            tm_p.tm_mday);
        endDate_p.setTime(15, 35, 0) ;
        return(0) ;
    }
    return (-1) ;
}



    
   bool authorize(const Service &authService,
                  Identity *subscriptionIdentity,
                  Session *session,
                  const CorrelationId &cid)
    {
        EventQueue tokenEventQueue;
        session.generateToken(CorrelationId(), &tokenEventQueue);
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
            writefln("Failed to get token");
            return false;
        }

        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set(TOKEN, token.c_str());

        session.sendAuthorizationRequest(authRequest, subscriptionIdentity);

        time_t startTime = time(0);
        const int WAIT_TIME_SECONDS = 10;
        while (true) {
            Event event = session.nextEvent(WAIT_TIME_SECONDS * 1000);
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
                        writefln("Authorization failed");
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

    

    bool authorize(const Service& authService,
                   Identity *subscriptionIdentity,
                   Session *session,
                   const CorrelationId& cid)
    {
        EventQueue tokenEventQueue;
        session.generateToken(CorrelationId(), &tokenEventQueue);
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
            writefln("Failed to get token");
            return false;
        }

        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set(TOKEN, token.c_str());

        session.sendAuthorizationRequest(authRequest, subscriptionIdentity);

        time_t startTime = time(0);
        const int WAIT_TIME_SECONDS = 10;
        while (true) {
            Event event = session.nextEvent(WAIT_TIME_SECONDS * 1000);
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
                        writefln("Authorization failed");
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

    
class MyEventHandler : public ProviderEventHandler {
public:
    
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
        session.generateToken(CorrelationId(), &tokenEventQueue);
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
            writefln("Failed to get token");
            return false;
        }

        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set(TOKEN, token.c_str());

        session.sendAuthorizationRequest(
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
                stderr.writefln("Invalid field %s",d_fields[i]);
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

void printMessages(const Event& event)
{
    MessageIterator iter(event);
    while (iter.next()) {
        Message msg = iter.message();
        msg.print(std::cout);
    }
}



    void activate() {
        if (d_useSsc) {
            std::cout << "Activating sub service code range "
                      << "[" << d_sscBegin << ", " << d_sscEnd
                      << "] @ priority " << d_sscPriority << std::endl;
            d_session_p.activateSubServiceCodeRange(d_service.c_str(),
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

            d_session_p.deactivateSubServiceCodeRange(d_service.c_str(),
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
        session.generateToken(CorrelationId(), &tokenEventQueue);
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

        session.sendAuthorizationRequest(
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

bool authorize(const Service &authService, Identity *providerIdentity, ProviderSession *session, const CorrelationId &cid)
{
    {
        MutexGuard guard(&g_lock);
        g_authorizationStatus[cid] = WAITING;
    }
    EventQueue tokenEventQueue;
    session.generateToken(CorrelationId(), &tokenEventQueue);
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
        writefln("Failed to get token");
        return false;
    }

    Request authRequest = authService.createAuthorizationRequest();
    authRequest.set(TOKEN, token.c_str());

    session.sendAuthorizationRequest(authRequest, providerIdentity, cid);

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
        void printErrorInfo(const char *leadingStr, const Element &errorInfo)
        {
            std::cout << leadingStr
                << errorInfo.getElementAsString(CATEGORY)
                << " ("
                << errorInfo.getElementAsString(MESSAGE)
                << ")" << std::endl;
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


class MyRequesterEventHandler : public EventHandler
{

public:
    MyRequesterEventHandler()
    {}

    bool processEvent(const Event& event, Session *session);
};



void printErrorInfo(const char *leadingStr, const Element &errorInfo)
{
    writefln("%s %s (%s)",leadingStr, errorInfo.getElementAsString(CATEGORY_ELEMENT), errorInfo.getElementAsString(MESSAGE_ELEMENT));
}

        // return true if processing is completed, false otherwise
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
void eventLoop(Session* session)
{
    bool done = false;
    while (!done) {
        Event event = session.nextEvent();
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
    session.generateToken(cid, &tokenEventQueue);
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
        writefln(">>> Failed to get token");
        return false;
    }

    Request authRequest = authService.createAuthorizationRequest();
    authRequest.set(TOKEN_ELEMENT, token.c_str());

    d_identity = session.createIdentity();
    session.sendAuthorizationRequest(authRequest, &d_identity);

    time_t startTime = time(0);
    const int WAIT_TIME_SECONDS = 10;
    while (true) {
        Event event = session.nextEvent(WAIT_TIME_SECONDS * 1000);
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
                    writefln(">>> Authorization failed");
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
    writefln(">>> Received %s elements", results.numValues());
    
    size_t numElements = results.numValues();

    writefln("%s %s results:",msgPrefix, numElements);
    foreach(i;0.. numElements)
    {
        Element result = results.getValueAsElement(i);
        writefln("%s:%s - %s", (i + 1),result.getElementAsString(SECURITY_ELEMENT),result.getElementAsString(DESCRIPTION_ELEMENT));
    }
}

void dumpGovtResults(string msgPrefix, Message* msg)
{
    auto response = msg.asElement();
    auto results  = response.getElement(RESULTS_ELEMENT);
    writefln(">>> Received %s elements",results.numValues());
    auto numElements = results.numValues();
	writefln(msgPrefix ~ " %s results:", numElements);
	foreach(i;numElements)
	{
        auto result = results.getValueAsElement(i);
        writefln("%s:%s, %s - %s",(i + 1),result.getElementAsString(PARSEKY_ELEMENT),result.getElementAsString(NAME_ELEMENT),result.getElementAsString(TICKER_ELEMENT));
    }
}

void dumpCurveResults(string msgPrefix,  Message* msg)
{
    auto response = msg.asElement();
    auto results  = response.getElement(RESULTS_ELEMENT);
    writefln(">>> Received %s elements",results.numValues());
    auto numElements = results.numValues();
	writefln(msgPrefix ~ " %s results:", numElements);
	foreach(i;numElements)
    {
    	auto result = results.getValueAsElement(i);
        writefln("%s: - '%s' country=%s currency=%s curveid=%s type=%s subtype=%s publisher=%s bbgid=%s",(i + 1),
      		result.getElementAsString(DESCRIPTION_ELEMENT), result.getElementAsString(COUNTRY_ELEMENT), result.getElementAsString(CURRENCY_ELEMENT),
			result.getElementAsString(CURVEID_ELEMENT), result.getElementAsString(TYPE_ELEMENT), result.getElementAsString(SUBTYPE_ELEMENT),
			result.getElementAsString(PUBLISHER_ELEMENT), result.getElementAsString(BBGID_ELEMENT));
	}
}

bool sendRequest(Session* session)
{
    auto blpinstrService = session.getService(INSTRUMENTS_SERVICE);
    auto request = blpinstrService.createRequest(d_requestType.string());

    request.asElement().setElement(QUERY_ELEMENT, d_query.c_str());
    request.asElement().setElement(MAX_RESULTS_ELEMENT, d_maxResults);

    foreach(it;d_filters)
	{
		request.asElement().setElement(it.first.c_str(), it.second.c_str());
    }

    writefln(">>> Sending request: ");
    request.print(std::cout);
    session.sendRequest(request, d_identity, CorrelationId());
    return true;
}


string padString(string str, uint width)
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


SimpleFieldInfoExample():
PADDING("                                            "),
    APIFLDS_SVC("//blp/apiflds") {
        ID_LEN         = 13;
        MNEMONIC_LEN   = 36;
        DESC_LEN       = 40;
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
        if (tm_p.tm_wday != 0 && tm_p.tm_wday != 6 ) {// not Sun/Sat
            *year_p = tm_p.tm_year + 1900;
            *month_p = tm_p.tm_mon + 1;
            *day_p = tm_p.tm_mday;
            return (0) ;
        }
    }
    return (-1) ;
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

	GridWindow(string name, string[] securities,d_name(name), d_securities(securities))
    {}

	void processSecurityUpdate(Message &msg, int row)
    {
    	string topicname = d_securities[row];
        writefln("%s:%s,%s",d_name ,row, topicname);
	}

	struct _UserData {
		const char *d_label;
		FILE *d_stream;
	}
	alias UserData_t=_UserData;

	
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


	string getTopic(const CorrelationId& cid)
	{
	    // Return the topic used to create the specified correlation 'cid'.
	    // The behaviour is undefined unless the specified cid was
	    return cast(string)(cid.asPointer()));
	}

	string getSubscriptionTopicString(const SubscriptionList& list, const CorrelationId&    cid)
	{
	    foreach(i;0.. list.size()) {
    	    if (list.correlationIdAt(i) == cid) {
        	    return to!string(list.topicStringAt(i));
    	    }
    	}
    	return 0;
	}

	size_t getTimeStamp(char *buffer, size_t bufSize)
	{
	    const char *format = "%Y/%m/%d %X";

	    time_t now = time(0);
	    tm _timeInfo;
	    tm *timeInfo = localtime_r(&now, &_timeInfo);
	    return strftime(buffer, bufSize, format, timeInfo);
	}


    bool processSubscriptionStatus(const Event &event, Session *session)
    {
        char timeBuffer[64];
        getTimeStamp(timeBuffer, sizeof(timeBuffer));

        SubscriptionList subscriptionList;
        writefln("Processing SUBSCRIPTION_STATUS");

        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            CorrelationId cid = msg.correlationId();

            std::string topic = getTopic(cid);
            {
                writefln("%s:%s",timeBuffer, topic);
            }

            if (msg.messageType() == SUBSCRIPTION_TERMINATED
                && d_pendingUnsubscribe.erase(cid)) {
                // If this message was due to a previous unsubscribe
                const char *topicString = getSubscriptionTopicString(
                    d_context_p.d_subscriptions,
                    cid);
                assert(topicString);
                if (d_isSlow) {
                    writefln("Deferring subscription for topic = %s because session is slow",topic);
                    d_pendingSubscriptions.add(topicString, cid);
                }
                else {
                    subscriptionList.add(topicString, cid);
                }
            }
        }

        if (0 != subscriptionList.size() && !d_context_p.d_isStopped) {
            session.subscribe(subscriptionList);
        }

        return true;
    }

    bool processSubscriptionDataEvent(const Event &event)
    {
        char timeBuffer[64];
        getTimeStamp(timeBuffer, sizeof(timeBuffer));

        writefln("Processing SUBSCRIPTION_DATA");
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            {
                writefln("%s:%s %s",timeBuffer,getTopic(msg.correlationId()),msg);
            }
        }
        return true;
    }

    bool processAdminEvent(const Event &event, Session *session)
    {
        char timeBuffer[64];
        getTimeStamp(timeBuffer, sizeof(timeBuffer));

        writefln("Processing ADMIN");
        CorrelationId[] cidsToCancel;
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
        if (!d_context_p.d_isStopped) {
            if (0 != cidsToCancel.size()) {
                session.cancel(cidsToCancel);
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
                session.subscribe(d_pendingSubscriptions);
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

    SubscriptionEventHandler(SessionContext *context)
    : d_isSlow(false)
    , d_context_p(context)
    , d_consoleLock_p(&context.d_consoleLock)
    {
    }


    bool createSession()
    {
        writefln("Connecting to ^s:%s",d_sessionOptions.serverHost(), d_sessionOptions.serverPort());

        d_eventHandler = new SubscriptionEventHandler(&d_context);
        d_session = new Session(d_sessionOptions, d_eventHandler);

        if (!d_session.start()) {
            writefln("Failed to start session.");
            return false;
        }

        writefln("Connected successfully");

        if (!d_session.openService(d_service.c_str())) {
            writefln("Failed to open mktdata service");
            d_session.stop();
            return false;
        }

        writefln("Subscribing...");
        d_session.subscribe(d_context.d_subscriptions);
        return true;
    }
    ~SubscriptionWithEventHandlerExample()
    {
        if (d_session) delete d_session;
        if (d_eventHandler) delete d_eventHandler;
    }


    writefln("SubscriptionWithEventHandlerExample");


public :

    SessionEventHandler(std::vector<Identity> &identities,
        std::vector<int> &uuids) :
    d_identities(identities), d_uuids(uuids) {
    }

bool authorize(const Service &authService, Identity *providerIdentity, AbstractSession *session, const CorrelationId &cid)
{
    {
        MutexGuard guard(&g_mutex);
        g_authorizationStatus[cid] = WAITING;
    }
    EventQueue tokenEventQueue;
    session.generateToken(CorrelationId(), &tokenEventQueue);
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
        writefln("Failed to get token");
        return false;
    }

    Request authRequest = authService.createAuthorizationRequest();
    authRequest.set(TOKEN, token.c_str());

    session.sendAuthorizationRequest(
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
struct Example_Static_Data
{
    string d_host;
    int d_port;
    string[] d_securities;
    int[] d_uuids;
    Identity[] d_identities;
    string[] d_programAddresses;
    const string d_service;
    SessionOptions d_sessionOptions;
    Session *d_session;
    SubscriptionEventHandler *d_eventHandler;
    string[]  d_topics;
    string[] d_fields;
    string[]  d_options;
    SessionContext            d_context;

}
    

class SimpleSubscriptionIntervalExample
{
    std::string         d_host;
    int                 d_port;
    int                 d_maxEvents;
    int                 d_eventCount;

        
    public:

class SubscriptionCorrelationExample
{
    class GridWindow {
        std::string                  d_name;
        std::vector<std::string>    &d_securities;

    std::string              d_host;
    int                      d_port;
    int                      d_maxEvents;
    int                      d_eventCount;
    std::vector<std::string> d_securities;
    GridWindow               d_gridWindow;

    
public:

    SubscriptionCorrelationExample()
        : d_gridWindow("SecurityInfo", d_securities)
    {
        d_securities.push_back("IBM US Equity");
        d_securities.push_back("VOD LN Equity");
    }


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
}

class SubscriptionEventHandler: public EventHandler
{
    bool                     d_isSlow;
    SubscriptionList         d_pendingSubscriptions;
    std::set<CorrelationId>  d_pendingUnsubscribe;
    SessionContext          *d_context_p;
    Mutex                   *d_consoleLock_p;
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
class MyEventHandler : public ProviderEventHandler {
public:
    bool processEvent(const Event& event, ProviderSession* session);
};


class ContributionsPageExample
{
    string[]  d_hosts;
    int                      d_port;
    string              d_service;
    string              d_topic;
    string              d_authOptions;
    int                      d_contributorId;

    
    ContributionsPageExample()
    : d_port(8194)
    , d_service("//blp/mpfbapi")
    , d_authOptions(AUTH_USER)
    , d_topic("220/660/1")
    , d_contributorId(8563)
    {
    }


SessionEventHandler(std::vector<Identity> &identities,
    std::vector<int> &uuids) :
d_identities(identities), d_uuids(uuids) {
}
class EntitlementsVerificationExample {

std::string               d_host;
int                       d_port;
std::vector<std::string>  d_securities;
std::vector<int>          d_uuids;
std::vector<Identity>     d_identities;
std::vector<std::string>  d_programAddresses;


class SessionEventHandler: public  EventHandler
{
std.vector<Identity>    &d_identities;
std.vector<int>         &d_uuids;
std.vector<std.string> &d_securities;
Name                      d_fieldName;

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
struct EntitlementsVerificationSubscription
{
	int[] d_uuids;
	Identity[] d_identities;
	string[]  d_programAddresses;
	SubscriptionList d_subscriptions;
}


public :
S

struct IntradayBarExample {
    string d_host="localhost";
	string[] hosts;
    int d_port=8194;
    string[] d_securities=["IBM US Equity"];
    string d_eventType="TRADE";
    string[] d_identities;
	string[] d_tokens;
	string d_DSProperty;
	bool d_useDS;
	Session *d_session;
	Identity d_identity;

    int d_barInterval;
    bool d_gapFillInitialBar;
    string d_startDateTime;
    string d_endDateTime;
	string[] d_events;
	int d_maxEvents=INT_MAX;
	int d_eventCount=0;
	string d_service="//viper/mktdata";
	string[] d_topics;
	string[] d_fields;
	string[] d_options;
	string authOptions="AUTH_USER";
	string d_id=""
	string d_topic="IBM Equity";
	bool d_conditionCodes;
	string d_startDateTime;
	string d_endDateTime;


	d_barInterval = 60;
    d_gapFillInitialBar = false;


	volatile bool g_running = true;
	Mutex g_lock;
	ubyte[CorrelationId] g_authorizationStatus;
	dMyStream() : d_id("") {}
	MyStream(string const& id) : d_id(id) {}
	void setTopic(Topic const& topic) { d_topic = topic; }
	string const& getId() { return d_id; }
	Topic const& getTopic() { return d_topic; }

	MyStream[] MyStreams;
	MyStreams g_streams;
	int       g_availableTopicCount;
	Mutex     g_mutex;
	string d_messageType = "MarketDataEvents"
	string d_groupId;
	    

	string d_serviceName;
	int[] d_eids;
	int d_resolveSubServiceCode=INT_MIN;
	string serviceName,
	Name& messageType,
	Name[] fields;
	int[] eids;

	int d_priority=10;
	int d_clearInterval=0;
	bool d_useSsc=false;
	int d_sscBegin,d_sscEnd,d_sscPriority;
	ProviderSession         *d_session_p;
	volatile bool d_isInitialPaintSent;
	bool  d_isSubscribed;
	bool g_running = true;
	int  d_lastValue=0;
	int d_fieldsPublished;
	bool d_conditionCodes = false;
	int d_maxResults=DEFAULT_MAX_RESULTS;
	Name d_requestType=INSTRUMENT_LIST_REQUEST;
	string d_query=DEFAULT_QUERY_STRING;
	bool d_partialMatch=DEFAULT_PARTIAL_MATCH;

	CorrelationId d_cid;
	EventQueue d_eventQueue;
	int CAT_NAME_LEN;
	int ID_LEN;
	int MNEMONIC_LEN;
	int DESC_LEN;
	string PADDING;
	string APIFLDS_SVC;

	alias FiltersMap=string[string];
	Identity       d_identity;
	SessionOptions d_sessionOptions;
	FiltersMap     d_filters;
}

enum AuthorizationStatus {
    WAITING,
    AUTHORIZED,
    FAILED
}

enum Role {
    SERVER,
    CLIENT,
    BOTH
}

enum {
	ID_LEN         = 13,
	MNEMONIC_LEN   = 36,
	DESC_LEN       = 40,
}


APIAUTH_SVC = "//blp/apiauth";
APIFLDS_SVC = "//blp/apiflds";
ApplicationAuthenticationType=APPNAME_AND_KEY;"
ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
AUTH_APP_PREFIX = "AuthenticationMode=APPLICATION_ONLY;"
AUTH_APP_PREFIX = "AuthenticationMode=APPLICATION_ONLY;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
AUTH_DIR_PREFIX = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
AuthenticationMode=APPLICATION_ONLY;"
AuthenticationMode=USER_AND_APPLICATION;"
AuthenticationMode=USER_AND_APPLICATION;AuthenticationType=OS_LOGON;"
AuthenticationType=DIRECTORY_SERVICE;"
AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
AuthenticationType=OS_LOGON;"
AUTH_OPTION_APP= "app=";
AUTH_OPTION_DIR = "dir=";
AUTH_OPTION_NONE= "none";
AUTH_OPTION_USER_APP("userapp=");
AUTH_OPTION_USER("user");
AUTHORIZATION_SUCCESS("AuthorizationSuccess");
AUTH_SERVICE("//blp/apiauth");
AUTH_USER_APP_PREFIX = "AuthenticationMode=USER_AND_APPLICATION;AuthenticationType=OS_LOGON;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
AUTH_USER_APP_PREFIX = "AuthenticationMode=USER_AND_APPLICATION;AuthenticationType=OS_LOGON;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
AUTH_USER("AuthenticationType=OS_LOGON");
bytesAUTHORIZATION_FAILURE("AuthorizationFailure");
bytesAUTHORIZATION_SUCCESS("AuthorizationSuccess");
bytesBAR_DATA("barData");
bytesBAR_TICK_DATA("barTickData");
bytesBBGID_ELEMENT("bbgid");
bytesCATEGORY("category");
bytesCATEGORY_ELEMENT("category");
bytesCATEGORY_ID("categoryId");
bytesCATEGORY_NAME("categoryName");
bytesCLOSE("close");
bytesCOND_CODE("conditionCodes");
bytesCOUNTRY_ELEMENT("country");
bytesCURRENCY_ELEMENT("currency");
bytesCURVEID_ELEMENT("curveid");
bytesCURVE_LIST_REQUEST("curveListRequest");
bytesCURVE_LIST_RESPONSE("CurveListResponse");
bytesDESCRIPTION_ELEMENT("description");
bytesEID_DATA("eidData");
bytesEID("EID");
bytesERROR_INFO("errorInfo");
bytesERROR_RESPONSE("ErrorResponse");
bytesFIELD_DATA("fieldData");
bytesFIELD_DESC("description");
bytesFIELD_ERROR("fieldError");
bytesFIELD_EXCEPTIONS("fieldExceptions");
bytesFIELD_ID("fieldId");
bytesFIELD_ID("id");
bytesFIELD_INFO("fieldInfo");
bytesFIELD_MNEMONIC("mnemonic");
bytesFIELD_MSG("message");
bytesFIELD_SEARCH_ERROR("fieldSearchError");
bytesGOVT_LIST_REQUEST("govtListRequest");
bytesGOVT_LIST_RESPONSE("GovtListResponse");
bytesHIGH("high");
bytesINSTRUMENT_LIST_REQUEST("instrumentListRequest");
bytesINSTRUMENT_LIST_RESPONSE("InstrumentListResponse");
bytesLAST_PRICE("LAST_PRICE");
bytesLOW("low");
bytesMAX_RESULTS_ELEMENT("maxResults");
bytesMESSAGE_ELEMENT("message");
bytesMESSAGE("message");
bytesNAME_ELEMENT("name");
bytesNUM_EVENTS("numEvents");
bytesOPEN("open");
bytesPARSEKY_ELEMENT("parseky");
bytesPARTIAL_MATCH_ELEMENT("partialMatch");
bytesPUBLISHER_ELEMENT("publisher");
bytesQUERY_ELEMENT("query");
bytesREASON("reason");
bytesRESPONSE_ERROR("responseError");
bytesRESULTS_ELEMENT("results");
bytesSECURITY_DATA("securityData");
bytesSECURITY_ELEMENT("security");
bytesSECURITY_ERROR("securityError");
bytesSECURITY("security");
bytesSESSION_STARTUP_FAILURE("SessionStartupFailure");
bytesSESSION_TERMINATED("SessionTerminated");
bytesSUBTYPE_ELEMENT("subtype");
bytesTICK_DATA("tickData");
bytesTICKER_ELEMENT("ticker");
bytesTICK_SIZE("size");
bytesTIME("time");
bytesTOKEN_ELEMENT("token");
bytesTOKEN_FAILURE("TokenGenerationFailure");
bytesTOKEN_SUCCESS("TokenGenerationSuccess");
bytesTYPE_ELEMENT("type");
bytesTYPE("type");
bytesVALUE("value");
bytesVOLUME("volume");
DATA_LOSS("DataLoss");
DEFAULT_HOST("localhost");
DEFAULT_PARTIAL_MATCH(false);
DEFAULT_QUERY_STRING("IBM");
INSTRUMENTS_SERVICE("//blp/instruments");
MARKET_DATA("MarketData");
MKTDATA_SVC = "//blp/mktdata";
PERMISSION_REQUEST("PermissionRequest");
REFDATA_SVC= "//blp/refdata";
REFRENCEDATA_REQUEST = "ReferenceDataRequest";
RESOLUTION_SUCCESS("ResolutionSuccess");
SESSION_TERMINATED("SessionTerminated");
SLOW_CONSUMER_WARNING_CLEARED("SlowConsumerWarningCleared");
SLOW_CONSUMER_WARNING("SlowConsumerWarning");
SOURCE("source");
PADDING = "";
SUBSCRIPTION_TERMINATED("SubscriptionTerminated");
TOKEN_FAILURE("TokenGenerationFailure");
TOKEN_SUCCESS("TokenGenerationSuccess");
TOKEN("token");
TOPIC_CREATED("TopicCreated");
TOPIC_RECAP("TopicRecap");
TOPICS("topics");
TOPIC_SUBSCRIBED("TopicSubscribed");
TOPIC_UNSUBSCRIBED("TopicUnsubscribed");
