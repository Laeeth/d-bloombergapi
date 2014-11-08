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
import std.container;
import std.string;
import std.stdio;
import std.stdlib;
import blpapi;

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
