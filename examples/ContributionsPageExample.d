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
#include <blpapi_correlationid.h>
#include <blpapi_defs.h>
#include <blpapi_event.h>
#include <blpapi_eventformatter.h>
#include <blpapi_exception.h>
#include <blpapi_identity.h>
#include <blpapi_message.h>
#include <blpapi_name.h>
#include <blpapi_providersession.h>
#include <blpapi_request.h>
#include <blpapi_topiclist.h>
#include <blpapi_service.h>
#include <blpapi_topic.h>

#include <cstdlib>
#include <cstring>
#include <ctime>
#include <iostream>
#include <iterator>
#include <list>
#include <map>
#include <string>

#include "BlpThreadUtil.h"

using namespace BloombergLP;
using namespace blpapi;

namespace {
Name TOKEN_SUCCESS("TokenGenerationSuccess");
Name TOKEN_FAILURE("TokenGenerationFailure");
Name AUTHORIZATION_SUCCESS("AuthorizationSuccess");
Name TOKEN("token");
Name SESSION_TERMINATED("SessionTerminated");

const std::string AUTH_USER       = "AuthenticationType=OS_LOGON";
const std::string AUTH_APP_PREFIX = "AuthenticationMode=APPLICATION_ONLY;ApplicationAuthenticationType=APPNAME_AND_KEY;ApplicationName=";
const std::string AUTH_DIR_PREFIX = "AuthenticationType=DIRECTORY_SERVICE;DirSvcPropertyName=";
const char* AUTH_OPTION_NONE      = "none";
const char* AUTH_OPTION_USER      = "user";
const char* AUTH_OPTION_APP       = "app=";
const char* AUTH_OPTION_DIR       = "dir=";

volatile bool g_running = true;

Mutex g_lock;

enum AuthorizationStatus {
    WAITING,
    AUTHORIZED,
    FAILED
};

std::map<CorrelationId, AuthorizationStatus> g_authorizationStatus;
}

class MyStream {
    std::string d_id;
    Topic d_topic;

public:
    MyStream() : d_id("") {};
    MyStream(std::string const& id) : d_id(id) {}
    void setTopic(Topic const& topic) {d_topic = topic;}
    std::string const& getId() {return d_id;}
    Topic const& getTopic() {return d_topic;}
};

typedef std::list<MyStream*> MyStreams;

void printMessages(const Event& event)
{
    MessageIterator iter(event);
    while (iter.next()) {
        Message msg = iter.message();
        MutexGuard guard(&g_lock);
        msg.print(std::cout);
        if (event.eventType() == Event::SESSION_STATUS) {
            if (msg.messageType() == SESSION_TERMINATED) {
                g_running = false;
            }
            continue;
        }
        if (g_authorizationStatus.find(msg.correlationId()) != g_authorizationStatus.end()) {
            if (msg.messageType() == AUTHORIZATION_SUCCESS) {
                g_authorizationStatus[msg.correlationId()] = AUTHORIZED;
            }
            else {
                g_authorizationStatus[msg.correlationId()] = FAILED;
            }
        }
    }
}

class MyEventHandler : public ProviderEventHandler {
public:
    bool processEvent(const Event& event, ProviderSession* session);
};

bool MyEventHandler::processEvent(const Event& event, ProviderSession* session)
{
    printMessages(event);
    return true;
}

class ContributionsPageExample
{
    std::vector<std::string> d_hosts;
    int                      d_port;
    std::string              d_service;
    std::string              d_topic;
    std::string              d_authOptions;
    int                      d_contributorId;

    void printUsage()
    {
        std::cout
            << "Publish on a topic. " << std::endl
            << "Usage:" << std::endl
            << "\t[-ip   <ipAddress>]    \tserver name or IP (default: localhost)" << std::endl
            << "\t[-p    <tcpPort>]      \tserver port (default: 8194)" << std::endl
            << "\t[-s    <service>]      \tservice name (default: //blp/mpfbapi)" << std::endl
            << "\t[-t    <topic>]        \ttopic (default: 220/660/1)" << std::endl
            << "\t[-c    <contributorId>]\tcontributor id (default: 8563)" << std::endl
            << "\t[-auth <option>]       \tauthentication option: user|none|app=<app>|dir=<property> (default: user)" << std::endl;
    }

    bool parseCommandLine(int argc, char **argv)
    {
        for (int i = 1; i < argc; ++i) {
            if (!std::strcmp(argv[i], "-ip") && i + 1 < argc)
                d_hosts.push_back(argv[++i]);
            else if (!std::strcmp(argv[i], "-p") &&  i + 1 < argc)
                d_port = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i], "-s") &&  i + 1 < argc)
                d_service = argv[++i];
            else if (!std::strcmp(argv[i], "-t") &&  i + 1 < argc)
                d_topic = argv[++i];
            else if (!std::strcmp(argv[i], "-c") &&  i + 1 < argc)
                d_contributorId = std::atoi(argv[++i]);
            else if (!std::strcmp(argv[i], "-auth") && i + 1 < argc) {
                ++i;
                if (!std::strcmp(argv[i], AUTH_OPTION_NONE)) {
                    d_authOptions.clear();
                }
                else if (!std::strcmp(argv[i], AUTH_OPTION_USER)) {
                    d_authOptions.assign(AUTH_USER);
                }
                else if (strncmp(argv[i], AUTH_OPTION_APP,
                                 strlen(AUTH_OPTION_APP)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_APP_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_APP));
                }
                else if (strncmp(argv[i], AUTH_OPTION_DIR,
                                 strlen(AUTH_OPTION_DIR)) == 0) {
                    d_authOptions.clear();
                    d_authOptions.append(AUTH_DIR_PREFIX);
                    d_authOptions.append(argv[i] + strlen(AUTH_OPTION_DIR));
                }
                else {
                    printUsage();
                    return false;
                }
            }
            else {
                printUsage();
                return false;
            }
        }
        if (d_hosts.empty()) {
            d_hosts.push_back("localhost");
        }
        return true;
    }

public:

    ContributionsPageExample()
    : d_port(8194)
    , d_service("//blp/mpfbapi")
    , d_authOptions(AUTH_USER)
    , d_topic("220/660/1")
    , d_contributorId(8563)
    {
    }

    bool authorize(const Service& authService,
                   Identity *providerIdentity,
                   ProviderSession *session,
                   const CorrelationId& cid)
    {
        {
            MutexGuard guard(&g_lock);
            g_authorizationStatus[cid] = WAITING;
        }
        EventQueue tokenEventQueue;
        session->generateToken(CorrelationId(), &tokenEventQueue);
        std::string token;
        Event event = tokenEventQueue.nextEvent();
        if (event.eventType() == Event::TOKEN_STATUS ||
            event.eventType() == Event::REQUEST_STATUS) {
            MessageIterator iter(event);
            while (iter.next()) {
                Message msg = iter.message();
                {
                    MutexGuard guard(&g_lock);
                    msg.print(std::cout);
                }
                if (msg.messageType() == TOKEN_SUCCESS) {
                    token = msg.getElementAsString(TOKEN);
                }
                else if (msg.messageType() == TOKEN_FAILURE) {
                    break;
                }
            }
        }
        if (token.length() == 0) {
            MutexGuard guard(&g_lock);
            std::cout << "Failed to get token" << std::endl;
            return false;
        }

        Request authRequest = authService.createAuthorizationRequest();
        authRequest.set(TOKEN, token.c_str());

        session->sendAuthorizationRequest(
            authRequest,
            providerIdentity,
            cid);

        time_t startTime = time(0);
        const int WAIT_TIME_SECONDS = 10;
        while (true) {
            {
                MutexGuard guard(&g_lock);
                if (WAITING != g_authorizationStatus[cid]) {
                    return AUTHORIZED == g_authorizationStatus[cid];
                }
            }
            time_t endTime = time(0);
            if (endTime - startTime > WAIT_TIME_SECONDS) {
                return false;
            }
            SLEEP(1);
        }
    }

    void run(int argc, char **argv)
    {
        if (!parseCommandLine(argc, argv)) return;

        SessionOptions sessionOptions;
        for (size_t i = 0; i < d_hosts.size(); ++i) {
            sessionOptions.setServerAddress(d_hosts[i].c_str(), d_port, i);
        }
        sessionOptions.setServerPort(d_port);
        sessionOptions.setAuthenticationOptions(d_authOptions.c_str());
        sessionOptions.setAutoRestartOnDisconnection(true);
        sessionOptions.setNumStartAttempts(d_hosts.size());

        std::cout << "Connecting to port " << d_port
                  << " on ";
        std::copy(d_hosts.begin(), d_hosts.end(), std::ostream_iterator<std::string>(std::cout, " "));
        std::cout << std::endl;

        MyEventHandler myEventHandler;
        ProviderSession session(sessionOptions, &myEventHandler, 0);
        if (!session.start()) {
            std::cerr <<"Failed to start session." << std::endl;
            return;
        }

        Identity providerIdentity = session.createIdentity();
        if (!d_authOptions.empty()) {
            bool isAuthorized = false;
            const char* authServiceName = "//blp/apiauth";
            if (session.openService(authServiceName)) {
                Service authService = session.getService(authServiceName);
                isAuthorized = authorize(authService, &providerIdentity,
                        &session, CorrelationId((void *)"auth"));
            }
            if (!isAuthorized) {
                std::cerr << "No authorization" << std::endl;
                return;
            }
        }

        TopicList topicList;
        topicList.add(((d_service + "/") + d_topic).c_str(),
            CorrelationId(new MyStream(d_topic)));

        session.createTopics(
            &topicList,
            ProviderSession::AUTO_REGISTER_SERVICES,
            providerIdentity);

        MyStreams myStreams;

        for (size_t i = 0; i < topicList.size(); ++i) {
            MyStream *stream = reinterpret_cast<MyStream*>(
                topicList.correlationIdAt(i).asPointer());
            int resolutionStatus = topicList.statusAt(i);
            if (resolutionStatus == TopicList::CREATED) {
                Topic topic = session.getTopic(topicList.messageAt(i));
                stream->setTopic(topic);
                myStreams.push_back(stream);
            }
            else {
                std::cout
                    << "Stream '"
                    << stream->getId()
                    << "': topic not resolved, status = "
                    << resolutionStatus
                    << std::endl;
            }
        }

        Service service = session.getService(d_service.c_str());

        // Now we will start publishing
        while (g_running) {
            Event event = service.createPublishEvent();
            EventFormatter eventFormatter(event);

            for (MyStreams::iterator iter = myStreams.begin();
                 iter != myStreams.end(); ++iter) {
                eventFormatter.appendMessage("PageData", (*iter)->getTopic());
                eventFormatter.pushElement("rowUpdate");

                eventFormatter.appendElement();
                eventFormatter.setElement("rowNum", 1);
                eventFormatter.pushElement("spanUpdate");

                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 20);
                eventFormatter.setElement("length", 4);
                eventFormatter.setElement("text", "TEST");
                eventFormatter.popElement();

                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 25);
                eventFormatter.setElement("length", 4);
                eventFormatter.setElement("text", "PAGE");
                eventFormatter.popElement();

                char buffer[10];
                time_t rawtime;
                std::time(&rawtime);
                int length = (int)std::strftime(buffer, 10, "%X", std::localtime(&rawtime));
                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 30);
                eventFormatter.setElement("length", length);
                eventFormatter.setElement("text", buffer);
                eventFormatter.setElement("attr", "BLINK");
                eventFormatter.popElement();

                eventFormatter.popElement();
                eventFormatter.popElement();

                eventFormatter.appendElement();
                eventFormatter.setElement("rowNum", 2);
                eventFormatter.pushElement("spanUpdate");
                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 20);
                eventFormatter.setElement("length", 9);
                eventFormatter.setElement("text", "---------");
                eventFormatter.setElement("attr", "UNDERLINE");
                eventFormatter.popElement();
                eventFormatter.popElement();
                eventFormatter.popElement();

                eventFormatter.appendElement();
                eventFormatter.setElement("rowNum", 3);
                eventFormatter.pushElement("spanUpdate");
                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 10);
                eventFormatter.setElement("length", 9);
                eventFormatter.setElement("text", "TEST LINE");
                eventFormatter.popElement();
                eventFormatter.appendElement();
                eventFormatter.setElement("startCol", 23);
                eventFormatter.setElement("length", 5);
                eventFormatter.setElement("text", "THREE");
                eventFormatter.popElement();
                eventFormatter.popElement();
                eventFormatter.popElement();
                eventFormatter.popElement();

                eventFormatter.setElement("contributorId", d_contributorId);
                eventFormatter.setElement("productCode", 1);
                eventFormatter.setElement("pageNumber", 1);
            }

            printMessages(event);

            session.publish(event);
            SLEEP(10);
        }

        session.stop();
    }
};

int main(int argc, char **argv)
{
    std::cout << "ContributionsPageExample" << std::endl;
    ContributionsPageExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description() << std::endl;
    }
    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}
