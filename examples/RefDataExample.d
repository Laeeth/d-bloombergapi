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

import std.stdio;
import std.string;
import std.conv;
import blpapi;

void memset(void* ptr, ubyte val, long nbytes)
{
    foreach(i;0..nbytes)
        *cast(ubyte*)(cast(ubyte)ptr+i)=val;
}

extern (C)
{

    struct bbgstruct
    {
        const Name SECURITY_DATA("securityData");
        const Name SECURITY("security");
        const Name FIELD_DATA("fieldData");
        const Name RESPONSE_ERROR("responseError");
        const Name SECURITY_ERROR("securityError");
        const Name FIELD_EXCEPTIONS("fieldExceptions");
        const Name FIELD_ID("fieldId");
        const Name ERROR_INFO("errorInfo");
        const Name CATEGORY("category");
        const Name MESSAGE("message");
        const Name REASON("reason");
        const Name SESSION_TERMINATED("SessionTerminated");
        const Name SESSION_STARTUP_FAILURE("SessionStartupFailure");
    };

    extern "C" void loggingCallback(blpapi_UInt64_t threadId, int severity, blpapi_Datetime_t  timestamp, const char        *category, const char        *message);

    void loggingCallback(blpapi_UInt64_t    threadId, int                severity, blpapi_Datetime_t  timestamp, const char        *category, const char        *message)
    {
        std::string severityString;
        switch(severity) {
        // The following cases will not happen if callback registered at OFF
        case blpapi_Logging_SEVERITY_FATAL:
        {
            severityString = "FATAL";
        } break;
        // The following cases will not happen if callback registered at FATAL
        case blpapi_Logging_SEVERITY_ERROR:
        {
            severityString = "ERROR";
        } break;
        // The following cases will not happen if callback registered at ERROR
        case blpapi_Logging_SEVERITY_WARN:
        {
            severityString = "WARN";
        } break;
        // The following cases will not happen if callback registered at WARN
        case blpapi_Logging_SEVERITY_INFO:
        {
            severityString = "INFO";
        } break;
        // The following cases will not happen if callback registered at INFO
        case blpapi_Logging_SEVERITY_DEBUG:
        {
            severityString = "DEBUG";
        } break;
        // The following case will not happen if callback registered at DEBUG
        case blpapi_Logging_SEVERITY_TRACE:
        {
            severityString = "TRACE";
        } break;

        };
        std::stringstream sstream;
        sstream << category <<" [" << severityString << "] Thread ID = "
                << threadId << ": " << message << std::endl;
        std::cout << sstream.str() << std::endl;;
    }

    class RefDataExample
    {
        std::string              d_host;
        int                      d_port;
        std::vector<std::string> d_securities;
        std::vector<std::string> d_fields;

        bool parseCommandLine(int argc, char **argv)
        {
            int verbosityCount = 0;
            for (int i = 1; i < argc; ++i) {
                if (!std::strcmp(argv[i],"-s") && i + 1 < argc) {
                    d_securities.push_back(argv[++i]);
                } else if (!std::strcmp(argv[i],"-f") && i + 1 < argc) {
                    d_fields.push_back(argv[++i]);
                } else if (!std::strcmp(argv[i],"-ip") && i + 1 < argc) {
                    d_host = argv[++i];
                } else if (!std::strcmp(argv[i],"-p") &&  i + 1 < argc) {
                    d_port = std::atoi(argv[++i]);
                } else if (!std::strcmp(argv[i],"-v")) {
                    ++verbosityCount;

                } else {
                    printUsage();
                    return false;
                }
            }
            if(verbosityCount) {
                registerCallback(verbosityCount);
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

        void printErrorInfo(const char *leadingStr, const Element &errorInfo)
        {
            std::cout << leadingStr
                << errorInfo.getElementAsString(CATEGORY)
                << " ("
                << errorInfo.getElementAsString(MESSAGE)
                << ")" << std::endl;
        }

void printUsage()
{
    writefln("Usage:\n"
         "    Retrieve reference data \n" 
         "        [-s         <security   = IBM US Equity>\n" 
         "        [-f         <field      = PX_LAST>\n" 
         "        [-ip        <ipAddress  = localhost>\n" 
         "        [-p         <tcpPort    = 8194>\n" 
         "        [-v         increase verbosity\n"
         " (can be specified more than once)\n");
}


        void registerCallback(int verbosityCount)
        {
            blpapi_Logging_Severity_t severity = blpapi_Logging_SEVERITY_OFF;
            switch(verbosityCount) {
              case 1: {
                  severity = blpapi_Logging_SEVERITY_INFO;
              }break;
              case 2: {
                  severity = blpapi_Logging_SEVERITY_DEBUG;
              }break;
              default: {
                  severity = blpapi_Logging_SEVERITY_TRACE;
              }
            };
            blpapi_Logging_registerCallback(loggingCallback,
                                            severity);
        }

        // return true if processing is completed, false otherwise
        void processResponseEvent(Event event)
        {
            MessageIterator msgIter(event);
            while (msgIter.next()) {
                Message msg = msgIter.message();
                if (msg.asElement().hasElement(RESPONSE_ERROR)) {
                    printErrorInfo("REQUEST FAILED: ",
                        msg.getElement(RESPONSE_ERROR));
                    continue;
                }

                Element securities = msg.getElement(SECURITY_DATA);
                size_t numSecurities = securities.numValues();
                std::cout << "Processing " << (unsigned int)numSecurities
                          << " securities:"<< std::endl;
                for (size_t i = 0; i < numSecurities; ++i) {
                    Element security = securities.getValueAsElement(i);
                    std::string ticker = security.getElementAsString(SECURITY);
                    std::cout << "\nTicker: " + ticker << std::endl;
                    if (security.hasElement(SECURITY_ERROR)) {
                        printErrorInfo("\tSECURITY FAILED: ",
                            security.getElement(SECURITY_ERROR));
                        continue;
                    }

                    if (security.hasElement(FIELD_DATA)) {
                        const Element fields = security.getElement(FIELD_DATA);
                        if (fields.numElements() > 0) {
                            std::cout << "FIELD\t\tVALUE"<<std::endl;
                            std::cout << "-----\t\t-----"<< std::endl;
                            size_t numElements = fields.numElements();
                            for (size_t j = 0; j < numElements; ++j) {
                                Element field = fields.getElement(j);
                                std::cout << field.name() << "\t\t" <<
                                    field.getValueAsString() << std::endl;
                            }
                        }
                    }
                    std::cout << std::endl;
                    Element fieldExceptions = security.getElement(
                                                                 FIELD_EXCEPTIONS);
                    if (fieldExceptions.numValues() > 0) {
                        std::cout << "FIELD\t\tEXCEPTION" << std::endl;
                        std::cout << "-----\t\t---------" << std::endl;
                        for (size_t k = 0; k < fieldExceptions.numValues(); ++k) {
                            Element fieldException =
                                fieldExceptions.getValueAsElement(k);
                            Element errInfo = fieldException.getElement(
                                                                       ERROR_INFO);
                            std::cout
                                     << fieldException.getElementAsString(FIELD_ID)
                                     << "\t\t"
                                     << errInfo.getElementAsString(CATEGORY)
                                     << " ( "
                                     << errInfo.getElementAsString(MESSAGE)
                                     << ")"
                                     << std::endl;
                        }
                    }
                }
            }
        }


} // extern (C)

int main(string[] argv)
{
    writefln("RefDataExample");
    RefDataExample example;
    try {
        example.run(argv);
    } catch (Exception &e) {
        std::cerr << "Library Exception!!! " << e.description() << std::endl;
    }
    // wait for enter key to exit application
    std::cout << "Press ENTER to quit" << std::endl;
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}

    static int streamWriter(const char* data, int length, void *stream)
    {
     assert(data);
     assert(stream);
     return cast(int)fwrite(data, length, 1, cast(FILE *)stream);
    }

    static void handleResponseEvent(const blpapi_Event_t *event)
    {
        blpapi_MessageIterator_t *iter = cast(blpapi_MessageIterator_t*)0;
        blpapi_Message_t *message = cast(blpapi_Message_t*)0;
        assert(event);
        writefln("Event Type = %s", blpapi_Event_eventType(event));
        iter = blpapi_MessageIterator_create(event);
        assert(iter);
        while (0 == blpapi_MessageIterator_next(iter, &message)) {
            blpapi_CorrelationId_t correlationId;
            blpapi_Element_t* messageElements = cast(blpapi_Element_t*)0;
            assert(message);
            correlationId = blpapi_Message_correlationId(message, 0);
            writefln("correlationId=%d %d %lld", correlationId.valueType, correlationId.classId, correlationId.value.intValue);
            writefln("messageType =%s", blpapi_Message_typeString(message));
            messageElements = blpapi_Message_elements(message);
            assert(messageElements);
            blpapi_Element_print(messageElements, &streamWriter, cast(void*)&stdout, 0, 4);
        }
        blpapi_MessageIterator_destroy(iter);
    }

        void eventLoop(Session &session)
        {
            bool done = false;
            while (!done) {
                Event event = session.nextEvent();
                if (event.eventType() == Event::PARTIAL_RESPONSE) {
                    std::cout << "Processing Partial Response" << std::endl;
                    processResponseEvent(event);
                }
                else if (event.eventType() == Event::RESPONSE) {
                    std::cout << "Processing Response" << std::endl;
                    processResponseEvent(event);
                    done = true;
                } else {
                    MessageIterator msgIter(event);
                    while (msgIter.next()) {
                        Message msg = msgIter.message();
                        if (event.eventType() == Event::REQUEST_STATUS) {
                            std::cout << "REQUEST FAILED: " << msg.getElement(REASON) << std::endl;
                            done = true;
                        }
                        else if (event.eventType() == Event::SESSION_STATUS) {
                            if (msg.messageType() == SESSION_TERMINATED ||
                                msg.messageType() == SESSION_STARTUP_FAILURE) {
                                done = true;
                            }
                        }
                    }
                }
            }
        }
    static void handleOtherEvent(const blpapi_Event_t *event)
    {
        blpapi_MessageIterator_t *iter = cast(blpapi_MessageIterator_t*)0;
        blpapi_Message_t *message = cast(blpapi_Message_t*) 0;
        assert(event);
        writefln("EventType=%s", blpapi_Event_eventType(event));
        iter = blpapi_MessageIterator_create(event);
        assert(iter);
        while (0 == blpapi_MessageIterator_next(iter, &message)) {
            blpapi_CorrelationId_t correlationId;
            blpapi_Element_t* messageElements = cast(blpapi_Element_t*)0;
            assert(message);
            correlationId = blpapi_Message_correlationId(message, 0);
            writefln("correlationId=%d %d %lld", correlationId.valueType, correlationId.classId, correlationId.value.intValue);
            writefln("messageType=%s", blpapi_Message_typeString(message));
            messageElements = blpapi_Message_elements(message);
            assert(messageElements);
            blpapi_Element_print(messageElements, &streamWriter, cast(void*)&stdout, 0, 4);
            if (((BLPAPI.EVENTTYPE_SESSION_STATUS == blpapi_Event_eventType(event)) && ("SessionTerminated"!=blpapi_Message_typeString(message))))
            {
                writefln("Terminating: %s", blpapi_Message_typeString(message));
                return;
            }
        }
        blpapi_MessageIterator_destroy(iter);
    }
} // extern (C)

int main(string[] argv)
{
    blpapi_SessionOptions_t *sessionOptions = cast(blpapi_SessionOptions_t*)0;
    blpapi_Session_t *session = cast(blpapi_Session_t *)0;
    blpapi_CorrelationId_t requestId;
    blpapi_Service_t *refDataSvc = cast(blpapi_Service_t *)0;
    blpapi_Request_t *request = cast(blpapi_Request_t *)0;
    blpapi_Element_t *elements = cast(blpapi_Element_t *)0;
    blpapi_Element_t *securitiesElements = cast(blpapi_Element_t *)0;
    blpapi_Element_t *fieldsElements = cast(blpapi_Element_t *)0;
    int continueToLoop = 1;
    blpapi_CorrelationId_t correlationId;
    sessionOptions = blpapi_SessionOptions_create();
    assert(sessionOptions);
    blpapi_SessionOptions_setServerHost(sessionOptions, "localhost");
    blpapi_SessionOptions_setServerPort(sessionOptions, 8194);
    session = blpapi_Session_create(sessionOptions, cast(blpapi_EventHandler_t)0, cast(blpapi_EventDispatcher*)0, cast(void*)0);
    assert(session);
    blpapi_SessionOptions_destroy(sessionOptions);
    if (0 != blpapi_Session_start(session)) {
        stderr.writefln("Failed to start session.");
        blpapi_Session_destroy(session);
        return 1;
    }
    if (0 != blpapi_Session_openService(session, "//blp/refdata")){
        stderr.writefln("Failed to open service //blp/refdata.");
        blpapi_Session_destroy(session);
        return 1;
    }
    memset(&requestId, '\0', requestId.size);
    requestId.valueType = BLPAPI.CORRELATION_TYPE_INT;
    requestId.value.intValue = cast(blpapi_UInt64_t)1;
    blpapi_Session_getService(session, &refDataSvc, "//blp/refdata");
    blpapi_Service_createRequest(refDataSvc, &request, "ReferenceDataRequest");
    assert(request);elements = blpapi_Request_elements(request);
    assert(elements);
    blpapi_Element_getElement(elements, &securitiesElements, cast(const(char*))"securities", cast(const(blpapi_Name*))0);
    assert(securitiesElements);
    blpapi_Element_setValueString(securitiesElements, cast(const(char*))"IBM US Equity", BLPAPI.ELEMENT_INDEX_END);
    blpapi_Element_getElement(elements, &fieldsElements, cast(const(char*))"fields", cast(const(blpapi_Name*))0);
    blpapi_Element_setValueString(fieldsElements, cast(const(char*))"PX_LAST", BLPAPI.ELEMENT_INDEX_END);
    memset(&correlationId, '\0', correlationId.size);
    correlationId.valueType = BLPAPI.CORRELATION_TYPE_INT;
    correlationId.value.intValue = cast(blpapi_UInt64_t)1;
    blpapi_Session_sendRequest(session, request, &correlationId, cast(blpapi_Identity*) 0, cast(blpapi_EventQueue*)0, cast(const(char*))0, 0);
    while (continueToLoop) {
        blpapi_Event_t *event = cast(blpapi_Event_t *)0;
        blpapi_Session_nextEvent(session, &event, 0);
        assert(event);
        switch (blpapi_Event_eventType(event)) {
            case BLPAPI.EVENTTYPE_RESPONSE: // final event
                continueToLoop = 0; // fall through
            case BLPAPI.EVENTTYPE_PARTIAL_RESPONSE:
                handleResponseEvent(event);
                break;
            default:
                handleOtherEvent(event);
                break;
        }
        blpapi_Event_release(event);
    }
    blpapi_Session_stop(session);
    blpapi_Request_destroy(request);
    blpapi_Session_destroy(session);
    return 0;
    
}