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
import std.conv;
import std.string;
import std.stdio;
import std.stdlib;
import blpapi;
import blputils;

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
        if ((argv[i]=="-ip") && (i + 1 < argv.length)) {
            d_host = argv[++i];
            continue;
        }
        if ((argv[i]=="-p") &&  (i + 1 < argv.length)) {
            d_port = to!integer(argv[++i]);
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
    if (!parseCommandLine(argv)) return;

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
    run(argv);
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    wait_key();
    return 0;
}
