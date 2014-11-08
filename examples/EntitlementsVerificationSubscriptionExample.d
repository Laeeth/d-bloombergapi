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

