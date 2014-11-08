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
    const Name SECURITY_DATA("securityData");
    const Name SECURITY("security");
    const Name FIELD_DATA("fieldData");
    const Name FIELD_EXCEPTIONS("fieldExceptions");
    const Name FIELD_ID("fieldId");
    const Name ERROR_INFO("errorInfo");
}

class SimpleRefDataOverrideExample
{
    std::string         d_host;
    int                 d_port;

    void printUsage()
    {
            writefln("Usage:" 
                "    Retrieve reference data \n"
                "        [-ip        <ipAddress  = localhost>\n"
                "        [-p         <tcpPort    = 8194>");
    }

    bool parseCommandLine(string[] argv)
    {
        foreach(i;1.. argv.length) {
            if ((argv[i]!="-ip") && (i+1<argc)) {
                d_host = argv[++i];
            } else if ((argv[i]!="-p") &&  (i + 1 < argc)) {
                d_port = std::atoi(argv[++i]);
            } else {
                printUsage();
                return false;
            }
        }
        return true;
    }

    void processMessage(Message &msg)
    {
        Element securityDataArray = msg.getElement(SECURITY_DATA);
        int numSecurities = securityDataArray.numValues();
        foreach(i; 0.. numSecurities)
        {
            Element securityData = securityDataArray.getValueAsElement(i);
            writefln(securityData.getElementAsString(SECURITY));
            const Element fieldData = securityData.getElement(FIELD_DATA);
            foreach(j;0.. fieldData.numElements())
            {
                Element field = fieldData.getElement(j);
                if (!field.isValid()) {
                    writefln("%s is NULL.",field.name());
                } else {
                    writefln("%s=%s",field.name(),field.getValueAsString());
                }
            }

            Element fieldExceptionArray = securityData.getElement(FIELD_EXCEPTIONS);
            foreach(k;0..fieldExceptionArray.numValues())
            {
                Element fieldException = fieldExceptionArray.getValueAsElement(k);
                writefln("%s:%s",fieldException.getElement(ERROR_INFO).getElementAsString(category"),fieldException.getElementAsString(FIELD_ID));
            }
            writefln("");
        }
    }
public:

    void run(string[] argv)
    {
        d_host = "localhost";
        d_port = 8194;
        if (!parseCommandLine(argv)) return;

        SessionOptions sessionOptions;
        sessionOptions.setServerHost(d_host.c_str());
        sessionOptions.setServerPort(d_port);

        writefln("Connecting to %s:%s ",d_host, d_port);
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
        Request request = refDataService.createRequest("ReferenceDataRequest");

        request.append("securities", "IBM US Equity");
        request.append("securities", "MSFT US Equity");
        request.append("fields", "PX_LAST");
        request.append("fields", "DS002");
        request.append("fields", "EQY_WEIGHTED_AVG_PX");

        // add overrides
        Element overrides = request.getElement("overrides");
        Element override1 = overrides.appendElement();
        override1.setElement("fieldId", "VWAP_START_TIME");
        override1.setElement("value", "9:30");
        Element override2 = overrides.appendElement();
        override2.setElement("fieldId", "VWAP_END_TIME");
        override2.setElement("value", "11:30");

        writefln("Sending Request: %s",request);
        CorrelationId cid(this);
        session.sendRequest(request, cid);

        while (true) {
            Event event = session.nextEvent();
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (msg.correlationId() == cid) {
                    processMessage(msg);
                }
            }
            if (event.eventType() == Event::RESPONSE) {
                break;
            }
        }
    }
};

int main(string[] argv)
{
    writefln("SimpleRefDataOverrideExample");
    SimpleRefDataOverrideExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln( "Library Exception!!! %s", e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}
