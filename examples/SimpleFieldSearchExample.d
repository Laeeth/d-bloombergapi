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

string d_host;
int d_port;

const char * APIFLDS_SVC   = "//blp/apiflds";
static std::string PADDING = "                                            ";

namespace {
    const Name FIELD_ID("id");
    const Name FIELD_MNEMONIC("mnemonic");
    const Name FIELD_DATA("fieldData");
    const Name FIELD_DESC("description");
    const Name FIELD_INFO("fieldInfo");
    const Name FIELD_ERROR("fieldError");
    const Name FIELD_MSG("message");
};

enum {
    ID_LEN         = 13,
    MNEMONIC_LEN   = 36,
    DESC_LEN       = 40,
};

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
        if (!(argv[i]=="-ip") ) {
            if (++i >= argv.length) return false;
            d_host = argv[i];
        }
        else if (!(argv[i]=="-p")) {
            if (++i >= argv.length) return false;
            d_port = atoi(argv[i]);
        }
        else return false;
    }
    return true;
}

string padString(string str, uint width)
{
    if (str.length() >= width || str.length() >= PADDING.length())
        return str;
    else return str ~ PADDING.substr(0, width-str.length());
}

void printField (const Element &field)
{
    string  fldId = field.getElementAsString(FIELD_ID);
    if (field.hasElement(FIELD_INFO)) {
        Element fldInfo          = field.getElement (FIELD_INFO) ;
        string fldMnemonic = fldInfo.getElementAsString(FIELD_MNEMONIC);
        string  fldDesc     = fldInfo.getElementAsString(FIELD_DESC);
        writefln("%s %s %s",padString(fldId, ID_LEN), padString(fldMnemonic, MNEMONIC_LEN), padString(fldDesc, DESC_LEN));
    }
    else {
        Element fldError = field.getElement(FIELD_ERROR) ;
        string errorMsg = fldError.getElementAsString(FIELD_MSG) ;

        writefln("\nERROR: ^s, - %s " fldId, errorMsg);
    }
}

void printHeader ()
{
    writefln("%s %s %s",padString("FIELD ID", ID_LEN), padString("MNEMONIC", MNEMONIC_LEN), padString("DESCRIPTION", DESC_LEN));
    writefln("%s %s %2",padString("-----------", ID_LEN),  padString("-----------", MNEMONIC_LEN), padString("-----------", DESC_LEN));
}


void run(string[] argv)
{
    d_host = "localhost";
    d_port = 8194;

    if (!parseCommandLine(argv)) {
        printUsage();
        return;
    }

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    writefln("Connecting to %s:%s" d_host, d_port);
    Session session(sessionOptions);

    if (!session.start()) {
        stderr.writefln("Failed to start session.");
        return;
    }

    if (!session.openService(APIFLDS_SVC)) {
        stderr.writefln("Failed to open %s",APIFLDS_SVC);
        return;
    }

    Service fieldInfoService = session.getService(APIFLDS_SVC);
    Request request = fieldInfoService.createRequest("FieldSearchRequest");
    request.set ("searchSpec", "last price");
    Element exclude = request.getElement("exclude");
    exclude.setElement("fieldType", "Static");
    request.set ("returnFieldDocumentation", false);

    writefln("Sending Request: %s", request);
    session.sendRequest(request);

    printHeader();
    while (true) {
        Event event = session.nextEvent();

        if (event.eventType() != Event::RESPONSE &&
            event.eventType() != Event::PARTIAL_RESPONSE) {
                continue;
        }

        MessageIterator msgIter(event);
        while (msgIter.next()) {
            Message msg = msgIter.message();
            Element fields = msg.getElement("fieldData");
            int numElements = fields.numValues();

            for (int i=0; i < numElements; i++) {
                printField (fields.getValueAsElement(i));
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
    SimpleFieldSearchExample example;

    try {
        example.run(argc, argv);
    }
    catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s",e.description());
    }
    catch (...) {
        stderr.writefln("Unknown exception!");
    }

    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}
