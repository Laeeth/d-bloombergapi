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

