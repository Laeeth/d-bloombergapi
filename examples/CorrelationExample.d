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


/**
 * An example to demonstrate use of CorrelationID.
 */
class CorrelationExample {
    /**
    * A helper class to simulate a GUI window.
    */
class Window {
    std::string  d_name;

public:
    Window(const char * name): d_name(name) {
    }

    void displaySecurityInfo(Message &msg) {
        std::cout << this->d_name << ": ";
        msg.print(std::cout);
    }
};

std::string         d_host;
int                 d_port;
Window              d_secInfoWindow;
CorrelationId       d_cid;

void printUsage()
{
    writefln("Usage:\n"
         "    Retrieve reference data " 
         "        [-ip        <ipAddress  = localhost>" 
         "        [-p         <tcpPort    = 8194>");
}

bool parseCommandLine(string[] argv)
{
    foreach (int i = 1; i < argc; ++i) {
        if (!std::strcmp(argv[i],"-ip") && i + 1 < argc) {
            d_host = argv[++i];
            continue;
        }
        if (!std::strcmp(argv[i],"-p") && i + 1 < argc) {
            d_port = std::atoi(argv[++i]);
            continue;
        }
        printUsage();
        return false;
    }
    return true;
}

bool startSession(Session &session){
    if (!session.start()) {
        stderr.writefln("Failed to connect!")
        return false;
    }
    if (!session.openService("//blp/refdata")) {
        stderr.writefln("Failed to open //blp/refdata");
        session.stop();
        return false;
    }

    return true;
}

public:

CorrelationExample(): d_secInfoWindow("SecurityInfo"), d_cid(&d_secInfoWindow) {
    d_host = "localhost";
    d_port = 8194;
}

~CorrelationExample() {
}

void run(string[] argv) {

    if (!parseCommandLine(argv)) return;

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s" d_host, d_port);
    Session session(sessionOptions);
    if (!startSession(session)) return;

    Service refDataService = session.getService("//blp/refdata");
    Request request = refDataService.createRequest("ReferenceDataRequest");
    request.append("securities", "IBM US Equity");
    request.append("fields", "PX_LAST");
    request.append("fields", "DS002");

    session.sendRequest(request, d_cid);

    while (true) {
        Event event = session.nextEvent();
        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            if (event.eventType() == Event::RESPONSE ||
                event.eventType() == Event::PARTIAL_RESPONSE) {
                ((Window *)msg.correlationId().asPointer())->
                        displaySecurityInfo(msg);
            }
        }
        if (event.eventType() == Event::RESPONSE) {
            // received final response
            break;
        }
    }
}

int main(strings[] argv)
{
    writefln("CorrelationExample");
    CorrelationExample example;
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
