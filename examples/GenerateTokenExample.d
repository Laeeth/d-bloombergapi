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

    const Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
    const Name AUTHORIZATION_FAILURE("AuthorizationFailure");
    const Name TOKEN_SUCCESS("TokenGenerationSuccess");
    const Name TOKEN_FAILURE("TokenGenerationFailure");

string d_host;
int d_port;
string d_DSProperty;
bool d_useDS;
string[] d_securities;
string[] d_fields;
Session *d_session;
Identity d_identity;

void printUsage()
{
    writefln("Usage:\n"
         "    Generate a token for authorization \n" 
         "        [-ip        <ipAddress  = localhost>\n"
         "        [-p         <tcpPort    = 8194>\n" 
         "        [-s         <security   = IBM US Equity>\n"
         "        [-f         <field      = PX_LAST>\n" 
         "        [-d         <dirSvcProperty = NULL>\n" );
}

bool parseCommandLine(string[] argv)
{
    foreach(i; 1..argv.length) {
        if (!strcmp(argv[i]=="-ip") && (i + 1 < argc))
            d_host = argv[++i];
        else if (!strcmp(argv[i]=="-p") &&  (i + 1 < argc))
            d_port = std::atoi(argv[++i]);
        else if (!std::strcmp(argv[i]=="-s") && (i + 1 < argc))
            d_securities.push_back(argv[++i]);
        else if (!std::strcmp(argv[i]=="-f") && (i + 1 < argc))
            d_fields.push_back(argv[++i]);
        else if (!std::strcmp(argv[i]=="-d") &&  (i + 1 < argc)) {
            d_useDS = true;
            d_DSProperty = argv[++i];
        } else {
            printUsage();
            return false;
        }
    }
    // handle default arguments
    if (d_securities.size() == 0) {
        d_securities.push_back("IBM US Equity");
    }

    if (d_fields.size() == 0) {
        d_fields.push_back("PX_LAST");
    }
    return true;
}

void sendRequest()
{
    Service refDataService = d_session.getService("//blp/refdata");
    Request request = refDataService.createRequest("ReferenceDataRequest");

    // Add securities to request
    Element securities = request.getElement("securities");
    for (size_t i = 0; i < d_securities.size(); ++i) {
        securities.appendValue(d_securities[i].c_str());
    }

    // Add fields to request
    Element fields = request.getElement("fields");
    for (size_t i = 0; i < d_fields.size(); ++i) {
        fields.appendValue(d_fields[i].c_str());
    }

    std::cout << "Sending Request: " << request << std::endl;
    d_session.sendRequest(request, d_identity);
}

bool processTokenStatus(const Event &event)
{
    std::cout << "processTokenEvents" << std::endl;
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        if (msg.messageType() == TOKEN_SUCCESS) {
            msg.print(std::cout);

            Service authService = d_session.getService("//blp/apiauth");
            Request authRequest = authService.createAuthorizationRequest();
            authRequest.set("token", msg.getElementAsString("token"));

            d_identity = d_session.createIdentity();
            d_session.sendAuthorizationRequest(authRequest, &d_identity,
                CorrelationId(1));
        } else if (msg.messageType() == TOKEN_FAILURE) {
            msg.print(std::cout);
            return false;
        }
    }

    return true;
}

bool processEvent(const Event &event)
{
    std::cout << "processEvent" << std::endl;
    MessageIterator msgIter(event);
    while (msgIter.next()) {
        Message msg = msgIter.message();
        if (msg.messageType() == AUTHORIZATION_SUCCESS) {
            writefln("Authorization SUCCESS");
            sendRequest();
        } else if (msg.messageType() == AUTHORIZATION_FAILURE) {
            writefln( "Authorization FAILED");
            return false;
        } else {
            msg.print(std::cout);
            if (event.eventType() == Event::RESPONSE) {
                writefln("Got Final Response");
                return false;
            }
        }
    }
    return true;
}

public:
GenerateTokenExample()
    : d_host("localhost"), d_port(8194), d_useDS(false), d_session(0)
{
}

~GenerateTokenExample()
{
    if (d_session) {
        d_session.stop();
        delete d_session;
    }
}

void run(string[] argv)
{
    if (!parseCommandLine(argc, argv)) return;

    SessionOptions sessionOptions;
    sessionOptions.setServerHost(d_host.c_str());
    sessionOptions.setServerPort(d_port);

    string authOptions = "AuthenticationType=OS_LOGON";
    if (d_useDS) {
        authOptions = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
        authOptions.append(d_DSProperty);
    }
    writefln("authOptions = %s", authOptions);
    sessionOptions.setAuthenticationOptions(authOptions.c_str());

    writefln("Connecting to %s:%s", d_host , d_port);
        << std::endl;
    d_session = new Session(sessionOptions);
    if (!d_session.start()) {
        stderr.writefln("Failed to start session.");
        return;
    }

    if (!d_session.openService("//blp/refdata")) {
        stderr.writefln("Failed to open //blp/refdata");
        return;
    }
    if (!d_session.openService("//blp/apiauth")) {
        stderr.writefln("Failed to open //blp/apiauth");
        return;
    }

    CorrelationId tokenReqId(99);
    d_session.generateToken(tokenReqId);

    while (true) {
        Event event = d_session.nextEvent();
        if (event.eventType() == Event::TOKEN_STATUS) {
            if (!processTokenStatus(event)) {
                break;
            }
        } else {
            if (!processEvent(event)) {
                break;
            }
        }
    }
}

int main(string[] argv)
{
    writefln("GenerateTokenExample");
    GenerateTokenExample example;
    try {
        example.run(argc, argv);
    }
    catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s",e.description())
    }

    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);

    return 0;
}
