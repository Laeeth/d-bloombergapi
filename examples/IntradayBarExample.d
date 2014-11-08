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

import blpapi;
import std.stdio;
import std.file;
import std.string;

namespace {
    const Name BAR_DATA("barData");
    const Name BAR_TICK_DATA("barTickData");
    const Name OPEN("open");
    const Name HIGH("high");
    const Name LOW("low");
    const Name CLOSE("close");
    const Name VOLUME("volume");
    const Name NUM_EVENTS("numEvents");
    const Name TIME("time");
    const Name RESPONSE_ERROR("responseError");
    const Name SESSION_TERMINATED("SessionTerminated");
    const Name CATEGORY("category");
    const Name MESSAGE("message");
};

struct IntradayBarExample {
    string d_host;
    int d_port;
    string d_security;
    string d_eventType;
    int d_barInterval;
    bool d_gapFillInitialBar;
    string d_startDateTime;
    string d_endDateTime;

    void printUsage()
    {
        writefln("Usage:\n" 
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
    }

    void printErrorInfo(const char *leadingStr, const Element &errorInfo)
    {
        writefln(leadingStr ~ errorInfo.getElementAsString(CATEGORY)~ " (" << errorInfo.getElementAsString(MESSAGE) ~ ")");
    }

    bool parseCommandLine(string[] argv)
    {
        foreach(i;1..argv.length)
        {
            if (argv[i]=="-s") && (i + 1) < argc) {
                d_security = argv[++i];
            } else if (argv[i]=="-ip") && (i+1<argc)) {
                d_host = argv[++i];
            } else if (!argb[i]=="-p") &&  i + 1 < argc) {
                d_port = std::atoi(argv[++i]);
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
            } else {
                printUsage();
                return false;
            }
        }

        return true;
    }

    void processMessage(Message &msg) {
        Element data = msg.getElement(BAR_DATA).getElement(BAR_TICK_DATA);
        int numBars = data.numValues();
        std::cout <<"Response contains " << numBars << " bars" << std::endl;
        std::cout <<"Datetime\t\tOpen\t\tHigh\t\tLow\t\tClose" <<
            "\t\tNumEvents\tVolume" << std::endl;
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

    void processResponseEvent(Event &event, Session &session) {
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

        std::cout <<"Sending Request: " << request << std::endl;
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
            if (tm_p->tm_wday == 0 || tm_p->tm_wday == 6 ) {// Sun/Sat
                continue ;
            }
            startDate_p->setDate(tm_p->tm_year + 1900,
                tm_p->tm_mon + 1,
                tm_p->tm_mday);
            startDate_p->setTime(13, 30, 0) ;

            //the next day is the end day
            currTime += 86400 ;
            tm_p = localtime(&currTime);
            if (tm_p == NULL) {
                break;
            }
            endDate_p->setDate(tm_p->tm_year + 1900,
                tm_p->tm_mon + 1,
                tm_p->tm_mday);
            endDate_p->setTime(13, 30, 0) ;

            return(0) ;
        }
        return (-1) ;
    }

public:

    IntradayBarExample() {
        d_host = "localhost";
        d_port = 8194;
        d_barInterval = 60;
        d_security = "IBM US Equity";
        d_eventType = "TRADE";
        d_gapFillInitialBar = false;
    }

    ~IntradayBarExample() {
    };

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

int main(string[] argv)
{
    writefln("IntradayBarExample");
     IntradayBarExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s ",e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}
