/* Copyright 2012. Bloomberg Finance L.P.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:  The above
 * copyright notice and this permission notice shall be included in all copies
 * or substantial portions of the Software.  THE SOFTWARE IS PROVIDED "AS IS",
 * WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 * TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
#define NOMINMAX
import std.container;
import std.string;
import std.stdio;
import std.stdlib;
import blpapi;


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
