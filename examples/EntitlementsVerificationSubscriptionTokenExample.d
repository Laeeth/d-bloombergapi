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


import std.stdio;
import std.file;
import std.string;
import std.containers;
import std.conv;
import std.algorithm;
import blp_api;

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

