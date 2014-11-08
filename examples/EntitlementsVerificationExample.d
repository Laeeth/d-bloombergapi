/* Copyright 2012. Bloomberg Finance L.P.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:  The above
 * copyright notice and this permission notice shall be included in all copies
 * or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
import std.stdio;
import std.file;
import std.string;
import std.containers;
import std.conv;
import std.algorithm;
import blp_api;


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

