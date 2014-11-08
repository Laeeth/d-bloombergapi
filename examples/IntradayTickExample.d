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
