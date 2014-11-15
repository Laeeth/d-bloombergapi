
struct Request
{
    blpapi_Request_t *d_handle;


    void Request(blpapi_Request_t *newhandle)
    {
        d_handle = newHandle;
        if (newHandle) {
            d_elements.rebind(blpapi_Request_elements(newHandle));
        }
    }

    void Request(RequestRef ref)
    {
        Request *src = ref.ptr();
        d_handle = src.d_handle;
        d_elements = src.d_elements;
        src.d_handle = 0;
        src.d_elements.rebind(0);
    }


    void Request(Request &src)
    {
        d_handle = src.d_handle;
        d_elements = src.d_elements;
        src.d_handle = 0;
        src.d_elements.rebind(0);
    }


    void ~Request()
    {
        if (d_handle) {
            blpapi_Request_destroy(d_handle);
        }
    }


    // win for teh D templates.  we should check that type of value is
    // only bool, char, int, long, float, double, DateTime, const char*
    // and convert string types as required

    void set(T)(string element, T value)
    {
        d_elements.setElement(element, value);
    }
                            
    void append(T)(string element, T value)
    {
        Element namedElement = d_elements.getElement(element);
        namedElement.appendValue(value);
    }

    Element getElement(string name)
    {
        return d_elements.getElement(name);
    }

    Element asElement()
    {
        return d_elements;
    }

    @property blpapi_Request_t* handle()
    {
        return d_handle;
    }
        

    FILE* print(stream,int level,int spacesPerLevel)
    {
    return d_elements.print(stream, level, spacesPerLevel);
    }
       // Format this Element to the specified output 'stream' at the
       // (absolute value of) the optionally specified indentation
       // 'level' and return a reference to 'stream'. If 'level' is
       // specified, optionally specify 'spacesPerLevel', the number
       // of spaces per indentation level for this and all of its
       // nested objects. If 'level' is negative, suppress indentation
       // of the first line. If 'spacesPerLevel' is negative, format
       // the entire output on one line, suppressing all but the
       // initial indentation (as governed by 'level').
}



class EventHandler {
    virtual ~EventHandler() = 0;
    virtual bool processEvent(const Event& event, Session *session) = 0;
        
};
                         // =============
                         // class Session
                         // =============

    enum SubscriptionStatus {
        UNSUBSCRIBED         = BLPAPI_SUBSCRIPTIONSTATUS_UNSUBSCRIBED,
            // No longer active, terminated by API.
        SUBSCRIBING          = BLPAPI_SUBSCRIPTIONSTATUS_SUBSCRIBING,
            // Initiated but no updates received.
        SUBSCRIBED           = BLPAPI_SUBSCRIPTIONSTATUS_SUBSCRIBED,
            // Updates are flowing.
        CANCELLED            = BLPAPI_SUBSCRIPTIONSTATUS_CANCELLED,
            // No longer active, terminated by Application.
        PENDING_CANCELLATION = BLPAPI_SUBSCRIPTIONSTATUS_PENDING_CANCELLATION
    }

struct Session
{
    blpapi_Session_t            *d_handle_p;
    EventHandler                *d_eventHandler_p;

    void eventHandlerProxy(blpapi_Event_t* event, blpapi_Session_t *session, void *userData);
    void dispatchEvent(const Event& event);

void Session(const SessionOptions& parameters, EventHandler* handler, EventDispatcher* dispatcher) : d_eventHandler_p(handler)
{
    d_handle_p = blpapi_Session_create(parameters.handle(), handler ? (blpapi_EventHandler_t)eventHandlerProxy : 0, dispatcher ? dispatcher.impl() : 0, this);
    initAbstractSessionHandle(blpapi_Session_getAbstractSession(d_handle_p));
}

void Session(blpapi_Session_t *newHandle) : d_handle_p(newHandle)
{
    initAbstractSessionHandle(blpapi_Session_getAbstractSession(d_handle_p));
}

~this()
{
    blpapi_Session_destroy(d_handle_p);
}

bool start()
{
    return blpapi_Session_start(d_handle_p) ? false : true;
}

bool startAsync()
{
    return blpapi_Session_startAsync(d_handle_p) ? false : true;
}

bool stop()
{
    blpapi_Session_stop(d_handle_p);
}

bool stopAsync()
{
    blpapi_Session_stopAsync(d_handle_p);
}

Event nextEvent(int timeout)
{
    blpapi_Event_t *event;
    throwOnError(
        blpapi_Session_nextEvent(d_handle_p, &event, timeout));
    return Event(event);
}

int tryNextEvent(Event *event)
{
    blpapi_Event_t *impl;
    int ret = blpapi_Session_tryNextEvent(d_handle_p, &impl);
    if (0 == ret) {
        *event = Event(impl);
    }
    return ret;
}



void Session::setStatusCorrelationId(
        const Service& service,
        const CorrelationId& correlationID)
{
    throwOnError(
        blpapi_Session_setStatusCorrelationId(
            d_handle_p,
            service.handle(),
            0,
            &correlationID.impl()));
}


void Session::setStatusCorrelationId(
        const Service& service,
        const Identity& identity,
        const CorrelationId& correlationID)
{
    throwOnError(
        blpapi_Session_setStatusCorrelationId(
            d_handle_p,
            service.handle(),
            identity.handle(),
            &correlationID.impl()));
}


CorrelationId sendRequest(const Request& request, const Identity& identity, const CorrelationId& correlationId, EventQueue *eventQueue, const char *requestLabel, int requestLabelLen)
{
    CorrelationId retCorrelationId(correlationId);
    blpapi_Session_sendRequest(d_handle_p, request.handle(), const_cast<blpapi_CorrelationId_t *>(&retCorrelationId.impl()), identity.handle(), eventQueue ? eventQueue.handle() : 0, requestLabel, requestLabelLen));
    return retCorrelationId;
}


sendRequest(const Request& request, const CorrelationId& correlationId, EventQueue *eventQueue, const char *requestLabel, int requestLabelLen)
{
    CorrelationId retCorrelationId(correlationId);
    blpapi_Session_sendRequest(d_handle_p, request.handle(), const_cast<blpapi_CorrelationId_t *>(&retCorrelationId.impl()), 0, eventQueue ? eventQueue.handle() : 0, requestLabel, requestLabelLen));
    return retCorrelationId;
}


blpapi_Session_t* Session::handle() const
{
    return d_handle_p;
}

void dispatchEvent(Event* event)
{
    d_eventHandler_p.processEvent(event, this);
}

static void eventHandlerProxy(blpapi_Event_t   *event, blpapi_Session_t *, void *userData)
{
    cast(Session*)(userData).dispatchEvent(Event(event));
}
    this(const SessionOptions& options = SessionOptions(), EventHandler* eventHandler=0, EventDispatcher* eventDispatcher=0)
    {
        // Construct a Session using the optionally specified
        // 'options', the optionally specified 'eventHandler' and the
        // optionally specified 'eventDispatcher'.
        //
        // See the SessionOptions documentation for details on what
        // can be specified in the 'options'.
        //
        // If 'eventHandler' is not 0 then this Session will operation
        // in asynchronous mode, otherwise the Session will operate in
        // synchronous mode.
        //
        // If 'eventDispatcher' is 0 then the Session will create a
        // default EventDispatcher for this Session which will use a
        // single thread for dispatching events. For more control over
        // event dispatching a specific instance of EventDispatcher
        // can be supplied. This can be used to share a single
        // EventDispatcher amongst multiple Session objects.
        //
        // If an 'eventDispatcher' is supplied which uses more than
        // one thread the Session will ensure that events which should
        // be ordered are passed to callbacks in a correct order. For
        // example, partial response to a request or updates to a
        // single subscription.
        //
        // If 'eventHandler' is 0 and the 'eventDispatcher' is not
        // 0 an exception is thrown.
        //
        // Each EventDispatcher uses its own thread or pool of
        // threads so if you want to ensure that a session which
        // receives very large messages and takes a long time to
        // process them does not delay a session that receives small
        // messages and processes each one very quickly then give each
        // one a separate EventDispatcher.
    }

    this(blpapi_Session_t *handle)
    {

    }

    ~this()
    {
    }
        
    bool start
    {
        // Attempt to start this Session and blocks until the Session
        // has started or failed to start. If the Session is started
        // successfully 'true' is returned, otherwise 'false' is
        // returned. Before start() returns a SESSION_STATUS Event is
        // generated. If this is an asynchronous Session then the
        // SESSION_STATUS may be processed by the registered
        // EventHandler before start() has returned. A Session may
        // only be started once.
    }

    bool startAsync()
    {
        // Attempt to begin the process to start this Session and
        // return 'true' if successful, otherwise return 'false'. The
        // application must monitor events for a SESSION_STATUS Event
        // which will be generated once the Session has started or if
        // it fails to start. If this is an asynchronous Session then
        // the SESSION_STATUS Event may be processed by the registered
        // EventHandler before startAsync() has returned. A Session may
        // only be started once.
    }

    void stop()
    {
        // Stop operation of this session and block until all callbacks to
        // EventHandler objects relating to this Session which are currently in
        // progress have completed (including the callback to handle the
        // SESSION_STATUS Event with SessionTerminated message this call
        // generates). Once this returns no further callbacks to EventHandlers
        // will occur. If stop() is called from within an EventHandler callback
        // the behavior is undefined and may result in a deadlock. Once a
        // Session has been stopped it can only be destroyed.
    }

    void stopAsync()
    {
        // Begin the process to stop this Session and return immediately. The
        // application must monitor events for a SESSION_STATUS Event with
        // SessionTerminated message which will be generated once the
        // Session has been stopped. After this SESSION_STATUS Event no further
        // callbacks to EventHandlers will occur. This method can be called
        // from within an EventHandler callback to stop Sessions using
        // nondefault (external) EventDispatcher. Once a Session has been
        // stopped it can only be destroyed.
    }

    Event nextEvent(int timeout=0)
    {
        // Returns the next available Event for this session. If there
        // is no event available this will block for up to the
        // specified 'timeoutMillis' milliseconds for an Event to
        // arrive. A value of 0 for 'timeoutMillis' (the default)
        // indicates nextEvent() should not timeout and will not
        // return until the next Event is available.
        //
        // If nextEvent() returns due to a timeout it will return an
        // event of type 'EventType::TIMEOUT'.
        //
        // If this is invoked on a Session which was created in
        // asynchronous mode an InvalidStateException is thrown.
    }

    int tryNextEvent(Event *event)
    {
        // If there are Events available for the session, load the next Event
        // into event and return 0 indicating success. If there is no event
        // available for the session, return a non-zero value with no effect
        // on event. This method never blocks.
    }

    void subscribe(SubscriptionList[] subscriptionList, const Identity* identity, string requestLabel = "")
    {
        // Begin subscriptions for each entry in the specified
        // 'subscriptionList' using the specified 'identity' for
        // authorization. If the optional 'requestLabel' and
        // 'requestLabelLen' are provided they define a string which
        // will be recorded along with any diagnostics for this
        // operation. There must be at least 'requestLabelLen'
        // printable characters at the location 'requestLabel'.
        //
        // A SUBSCRIPTION_STATUS Event will be generated for each
        // entry in the 'subscriptionList'.
    }

    void subscribe(SubscriptionList[] subscriptionList, string requestLabel = "")
    {
        // Begin subscriptions for each entry in the specified
        // 'subscriptionList' using the default authorization
        // information. If the optional 'requestLabel' and
        // 'requestLabelLen' are provided they define a string which
        // will be recorded along with any diagnostics for this
        // operation. There must be at least 'requestLabelLen'
        // printable characters at the location 'requestLabel'.
        //
        // A SUBSCRIPTION_STATUS Event will be generated for each
        // entry in the 'subscriptionList'.
        blpapi_Session_subscribe(d_handle_p, subscriptions.impl(),0, requestLabel, requestLabel.length+1);
    }

    void subscribe(SubscriptionList[] subscriptionlist, const char* requestLabel, int requestLabelLen)
    {
        (blpapi_Session_subscribe(d_handle_p, subscriptions.impl(), identity.handle(), requestLabel, requestLabelLen);
    }





    void unsubscribe( SubscriptionList[] list)
    {
        // Cancel each of the current subscriptions identified by the
        // specified 'subscriptionList'. If the correlation ID of any
        // entry in the 'subscriptionList' does not identify a current
        // subscription then that entry is ignored. All entries which
        // have valid correlation IDs will be cancelled.
        //
        // Once this call returns the correlation ids in the
        // 'subscriptionList' will not be seen in any subsequent
        // Message obtained from a MessageIterator by calling
        // next(). However, any Message currently pointed to by a
        // MessageIterator when unsubscribe() is called is not
        // affected even if it has one of the correlation IDs in the
        // 'subscriptionList'. Also any Message where a reference has
        // been retained by the application may still contain a
        // correlation ID from the 'subscriptionList'. For these
        // reasons, although technically an application is free to
        // re-use the correlation IDs as soon as this method returns
        // it is preferable not to aggressively re-use correlation
        // IDs, particularly with an asynchronous Session.
        blpapi_Session_unsubscribe(d_handle_p, list.impl(), 0, 0));
    }

    void resubscribe(SubscriptionList[] subscriptions)
    {
        // Modify each subscription in the specified
        // 'subscriptionList' to reflect the modified options
        // specified for it.
        //
        // For each entry in the 'subscriptionList' which has a
        // correlation ID which identifies a current subscription the
        // modified options replace the current options for the
        // subscription and a SUBSCRIPTION_STATUS event will be
        // generated in the event stream before the first update based
        // on the new options. If the correlation ID of an entry in
        // the 'subscriptionList' does not identify a current
        // subscription then an exception is thrown.
        blpapi_Session_resubscribe(d_handle_p, subscriptions.impl(), 0, 0);
    }

    void resubscribe(SubscriptionList* subscriptions)
    {
        blpapi_Session_resubscribe(d_handle_p, subscriptions.impl(), 0, 0);
    }

    void resubscribe(SubscriptionList[] subscriptions, string requestLabel)
    {
        // Modify each subscription in the specified
        // 'subscriptionList' to reflect the modified options
        // specified for it. The specified 'requestLabel' and
        // 'requestLabelLen' define a string which
        // will be recorded along with any diagnostics for this
        // operation. There must be at least 'requestLabelLen'
        // printable characters at the location 'requestLabel'.
        //
        // For each entry in the 'subscriptionList' which has a
        // correlation ID which identifies a current subscription the
        // modified options replace the current options for the
        // subscription and a SUBSCRIPTION_STATUS event will be
        // generated in the event stream before the first update based
        // on the new options. If the correlation ID of an entry in
        // the 'subscriptionList' does not identify a current
        // subscription then an exception is thrown.
        blpapi_Session_resubscribe(d_handle_p, subscriptions.impl(), requestLabel, requestLabelLen);

    }
    
    void resubscribe(SubscriptionList[] subscriptions, int resubscriptionId)
    {
        // Modify each subscription in the specified
        // 'subscriptionList' to reflect the modified options
        // specified for it.
        //
        // For each entry in the 'subscriptionList' which has a
        // correlation ID which identifies a current subscription the
        // modified options replace the current options for the
        // subscription and a SUBSCRIPTION_STATUS event containing the
        // specified 'resubscriptionId' will be generated in the event
        // stream before the first update based on the new options. If
        // the correlation ID of an entry in the 'subscriptionList'
        // does not identify a current subscription then an exception
        // is thrown.
        BLPAPI_CALL_SESSION_RESUBSCRIBEWITHID(d_handle_p, subscriptions.impl(), resubscriptionId, 0, 0) ;
    }
    void resubscribe(SubscriptionList[] subscriptions, int resubscriptionId, string requestLabel)
    {
        // Modify each subscription in the specified
        // 'subscriptionList' to reflect the modified options
        // specified for it. The specified 'requestLabel' and
        // 'requestLabelLen' define a string which
        // will be recorded along with any diagnostics for this
        // operation. There must be at least 'requestLabelLen'
        // printable characters at the location 'requestLabel'.
        //
        // For each entry in the 'subscriptionList' which has a
        // correlation ID which identifies a current subscription the
        // modified options replace the current options for the
        // subscription and a SUBSCRIPTION_STATUS event containing the
        // specified 'resubscriptionId' will be generated in the event
        // stream before the first update based on the new options. If
        // the correlation ID of an entry in the 'subscriptionList'
        // does not identify a current subscription then an exception
        // is thrown.
        BLPAPI_CALL_SESSION_RESUBSCRIBEWITHID(d_handle_p, subscriptions.impl(), resubscriptionId, cast(const(char*))requestLabel, requestLabel.length+1);
    }


    void setStatusCorrelationId(
            const Service& service,
            const CorrelationId& correlationID);

    void setStatusCorrelationId(
            const Service& service,
            const Identity& identity,
            const CorrelationId& correlationID);
        // Set the CorrelationID on which service status messages will be
        // received.
        // Note: No service status messages are received prior to this call

    CorrelationId sendRequest(
            const Request& request,
            const CorrelationId& correlationId=CorrelationId(),
            EventQueue *eventQueue=0,
            const char *requestLabel = 0,
            int requestLabelLen = 0);
        // Send the specified 'request'. If the optionally specified
        // 'correlationId' is supplied use it otherwise create a
        // CorrelationId. The actual CorrelationId used is
        // returned. If the optionally specified 'eventQueue' is
        // supplied all events relating to this Request will arrive on
        // that EventQueue. If the optional 'requestLabel' and
        // 'requestLabelLen' are provided they define a string which
        // will be recorded along with any diagnostics for this
        // operation. There must be at least 'requestLabelLen'
        // printable characters at the location 'requestLabel'.
        //
        // A successful request will generate zero or more
        // PARTIAL_RESPONSE Messages followed by exactly one RESPONSE
        // Message. Once the final RESPONSE Message has been received
        // the correlation ID associated with this request may be
        // re-used. If the request fails at any stage a REQUEST_STATUS
        // will be generated after which the correlation ID associated
        // with the request may be re-used.

    CorrelationId sendRequest(Request* request, Identity* user, CorrelationId* correlationId=CorrelationId(),
        EventQueue *eventQueue=0, string requestLabel ="")
    {

        // Send the specified 'request' using the specified
        // 'identity' for authorization. If the optionally specified
        // 'correlationId' is supplied use it otherwise create a
        // CorrelationId. The actual CorrelationId used is
        // returned. If the optionally specified 'eventQueue' is
        // supplied all events relating to this Request will arrive on
        // that EventQueue. If the optional 'requestLabel' and
        // 'requestLabelLen' are provided they define a string which
        // will be recorded along with any diagnostics for this
        // operation. There must be at least 'requestLabelLen'
        // printable characters at the location 'requestLabel'.
        //
        // A successful request will generate zero or more
        // PARTIAL_RESPONSE Messages followed by exactly one RESPONSE
        // Message. Once the final RESPONSE Message has been received
        // the CorrelationId associated with this request may be
        // re-used. If the request fails at any stage a REQUEST_STATUS
        // will be generated after which the CorrelationId associated
        // with the request may be re-used.
    }


    // ACCESSORS

    blpapi_Session_t* handle() const;
};
                         // ==========================
                         // class SubscriptionIterator
                         // ==========================

class SubscriptionIterator {
    // An iterator which steps through all the subscriptions in a Session.
    //
    // The SubscriptionIterator can be used to iterate over all the
    // active subscriptions for a Session. However, with an
    // asynchronous Session it is possible for the set of active
    // subscriptions to change whilst the SubscriptionIterator is
    // being used. The SubscriptionIterator is guaranteed to never
    // return the same subscription twice. However, the subscription
    // the iterator points to may no longer be active. In this case
    // the result of subscriptionStatus() will be UNSUBSCRIBED or
    // CANCELLED.

    blpapi_SubscriptionIterator_t *d_handle_p;
    const char     *d_subscriptionString;
    CorrelationId   d_correlationId;
    int             d_status;
    bool            d_isValid;

  private:
    // NOT IMPLEMENTED
    SubscriptionIterator(const SubscriptionIterator&);
    SubscriptionIterator& operator=(const SubscriptionIterator&);

  public:
    SubscriptionIterator(Session *session);
        // Construct a forward iterator to iterate over the
        // subscriptions of the specified 'session'. The
        // SubscriptionIterator is created in a state where next()
        // must be called to advance it to the first item.

    ~SubscriptionIterator();
        // Destructor.

    // MANIPULATORS

    bool next();
        // Attempt to advance this iterator to the next subscription
        // record.  Returns 'true' on success and 'false' if there are
        // no more subscriptions. After next() returns true isValid()
        // is guaranteed to return true until the next call to
        // next(). After next() returns false isValid() will return
        // false.

    // ACCESSORS

    bool isValid() const;
        // Returns true if this iterator is currently positioned on a
        // valid subscription.  Returns false otherwise.

    const char* subscriptionString() const;
        // Returns a pointer to a null-terminated string which
        // contains the subscription string for this subscription. The
        // pointer returned remains valid until this
        // SubscriptionIterator is destroyed or the underlying
        // Session is destroyed or next() is called.

    const CorrelationId& correlationId() const;
        // Returns the CorrelationId for this subscription.

    Session::SubscriptionStatus subscriptionStatus() const;
        // Returns the status of this subscription.

    blpapi_SubscriptionIterator_t* handle() const;
};

// ============================================================================
//                       FUNCTION DEFINITIONS
// ============================================================================

                             // ------------------
                             // class EventHandler
                             // ------------------


EventHandler::~EventHandler()
{
}

                               // -------------
                               // class Session

                            // --------------------------
                            // class SubscriptionIterator
                            // --------------------------


SubscriptionIterator::SubscriptionIterator(Session *session)
    : d_isValid(false)
{
    d_handle_p = blpapi_SubscriptionItr_create(session.handle());
}


SubscriptionIterator::~SubscriptionIterator()
{
    blpapi_SubscriptionItr_destroy(d_handle_p);
}


bool SubscriptionIterator::next()
{
    d_isValid = !blpapi_SubscriptionItr_next(d_handle_p, &d_subscriptionString,
        const_cast<blpapi_CorrelationId_t *>(&d_correlationId.impl()),
        &d_status);

    return d_isValid;
}


bool SubscriptionIterator::isValid() const
{
    return d_isValid;
}


blpapi_SubscriptionIterator_t* SubscriptionIterator::handle() const
{
    return d_handle_p;
}


const char* SubscriptionIterator::subscriptionString() const
{
    if (!isValid()) {
        throwOnError(BLPAPI_ERROR_ILLEGAL_STATE);
    }

    return d_subscriptionString;
}


const CorrelationId& SubscriptionIterator::correlationId() const
{
    if (!isValid()) {
        throwOnError(BLPAPI_ERROR_ILLEGAL_STATE);
    }

    return d_correlationId;
}

struct SSub
Session::SubscriptionStatus SubscriptionIterator::subscriptionStatus() const
{
    if (!isValid()) {
        throwOnError(BLPAPI_ERROR_ILLEGAL_STATE);
    }

    return static_cast<Session::SubscriptionStatus>(d_status);
}






    enum ClientMode {
        AUTO = BLPAPI_CLIENTMODE_AUTO,  // Automatic (desktop if available
                                        // otherwise server)
        DAPI = BLPAPI_CLIENTMODE_DAPI,  // Always connect to the desktop API
        SAPI = BLPAPI_CLIENTMODE_SAPI   // Always connect to the server API
    }


struct SessionOptions {
    blpapi_SessionOptions_t *d_handle_p;
    d_handle_p = blpapi_SessionOptions_create();

    SessionOptions(const SessionOptions& options)
    {
        d_handle_p = blpapi_SessionOptions_duplicate(options.handle());
    }


    ~SessionOptions()
    {
        blpapi_SessionOptions_destroy(d_handle_p);
    }


    void setServerHost(string newServerHost)
    {
        blpapi_SessionOptions_setServerHost(d_handle_p, cast(const (char*))newServerHost);
    }


    void setServerPort(unsigned short newServerPort)
    {
        blpapi_SessionOptions_setServerPort(d_handle_p, newServerPort);
    }


    int setServerAddress(string newServerHost, unsigned short newServerPort, size_t index)
    {
        return blpapi_SessionOptions_setServerAddress(d_handle_p, cast(const(char*)) newServerHost, newServerPort, index);
    }


    int removeServerAddress(size_t index)
    {
        return blpapi_SessionOptions_removeServerAddress(d_handle_p, index);
    }


    void setConnectTimeout(uint timeoutMilliSeconds)
    {
        blpapi_SessionOptions_setConnectTimeout(d_handle_p, timeoutMilliSeconds));
    }


    void setDefaultServices(string newDefaultServices)
    {
        blpapi_SessionOptions_setDefaultServices(d_handle_p,cast(const(char*)) newDefaultServices);
    }


    void setDefaultSubscriptionService(string serviceIdentifier)
    {
        blpapi_SessionOptions_setDefaultSubscriptionService(d_handle_p, (const(char*))serviceIdentifier);
    }


    void setDefaultTopicPrefix(string prefix)
    {
        blpapi_SessionOptions_setDefaultTopicPrefix(d_handle_p, cast(const char*) prefix);
    }


    void setAllowMultipleCorrelatorsPerMsg(bool newAllowMultipleCorrelatorsPerMsg)
    {
        blpapi_SessionOptions_setAllowMultipleCorrelatorsPerMsg(d_handle_p, newAllowMultipleCorrelatorsPerMsg);
    }


    void setClientMode(int newClientMode)
    {
        blpapi_SessionOptions_setClientMode(d_handle_p, newClientMode);
    }


    void setMaxPendingRequests(int newMaxPendingRequests)
    {
        blpapi_SessionOptions_setMaxPendingRequests(d_handle_p, newMaxPendingRequests);
    }


    void setAutoRestartOnDisconnection(bool autoRestart)
    {
        blpapi_SessionOptions_setAutoRestartOnDisconnection(d_handle_p, autoRestart? 1: 0);
    }


    void setAuthenticationOptions(string authOptions)
    {
        blpapi_SessionOptions_setAuthenticationOptions(d_handle_p, cast(const(char*))authOptions);
    }


    void setNumStartAttempts(int newNumStartAttempts)
    {
        blpapi_SessionOptions_setNumStartAttempts(d_handle_p, newNumStartAttempts);
    }


    void setMaxEventQueueSize(size_t eventQueueSize)
    {
        BLPAPI_CALL_SESSIONOPTIONS_SETMAXEVENTQUEUESIZE(d_handle_p, eventQueueSize);
    }


    void setSlowConsumerWarningHiWaterMark(float hiWaterMark)
    {
        BLPAPI_CALL_SESSIONOPTIONS_SETSLOWCONSUMERHIWATERMARK(d_handle_p, hiWaterMark);
    }


    void setSlowConsumerWarningLoWaterMark(float loWaterMark)
    {
        BLPAPI_CALL_SESSIONOPTIONS_SETSLOWCONSUMERLOWATERMARK(d_handle_p, loWaterMark));
    }


    void setDefaultKeepAliveInactivityTime(int inactivityTime)
    {
        BLPAPI_CALL_SESSIONOPTIONS_SETDEFAULTKEEPALIVEINACTIVITYTIME(d_handle_p, inactivityTime));
    }


    void setDefaultKeepAliveResponseTimeout(int responseTimeout)
    {
        BLPAPI_CALL_SESSIONOPTIONS_SETDEFAULTKEEPALIVERESPONSETIMEOUT(d_handle_p, responseTimeout);
    }


    void setKeepAliveEnabled(bool isEnabled)
    {
        BLPAPI_CALL_SESSIONOPTIONS_SETKEEPALIVEENABLED(d_handle_p, isEnabled);
    }


    void setRecordSubscriptionDataReceiveTimes(bool shouldRecrod)
    {
        BLPAPI_CALL_SESSIONOPTION_SETRECORDSUBSCRIPTIONDATARECEIVETIMES(d_handle_p, shouldRecrod);
    }


    string serverHost() 
    {
        return to!string( blpapi_SessionOptions_serverHost(d_handle_p));
    }


    ushort serverPort()
    {
        return cast(ushort)blpapi_SessionOptions_serverPort(d_handle_p);
    }


    size_t numServerAddresses()
    {
        return blpapi_SessionOptions_numServerAddresses(d_handle_p);
    }


    int getServerAddress(const char **serverHostOut, ushort* serverPortOut, size_t index)
    {
        return blpapi_SessionOptions_getServerAddress(d_handle_p, serverHostOut, serverPortOut, index);
    }


    uint connectTimeout()
    {
        return blpapi_SessionOptions_connectTimeout(d_handle_p);
    }


    string defaultServices() 
    {
        return to!string(blpapi_SessionOptions_defaultServices(d_handle_p));
    }


    string defaultSubscriptionService() 
    {
        return blpapi_SessionOptions_defaultSubscriptionService(d_handle_p);
    }


    string defaultTopicPrefix()
    {
        return blpapi_SessionOptions_defaultTopicPrefix(d_handle_p);
    }


    bool allowMultipleCorrelatorsPerMsg() 
    {
        return blpapi_SessionOptions_allowMultipleCorrelatorsPerMsg(d_handle_p) ? true : false;
    }


    int clientMode() 
    {
        return blpapi_SessionOptions_clientMode(d_handle_p);
    }


    int maxPendingRequests()
    {
        return blpapi_SessionOptions_maxPendingRequests(d_handle_p);
    }


    bool autoRestartOnDisconnection() 
    {
        return blpapi_SessionOptions_autoRestartOnDisconnection(d_handle_p) != 0;
    }


    string authenticationOptions()
    {
        return to!string(blpapi_SessionOptions_authenticationOptions(d_handle_p));
    }


    int numStartAttempts() 
    {
        return blpapi_SessionOptions_numStartAttempts(d_handle_p);
    }


    size_t maxEventQueueSize()
    {
        return BLPAPI_CALL_SESSIONOPTIONS_MAXEVENTQUEUESIZE(d_handle_p);
    }


    float slowConsumerWarningHiWaterMark()
    {
        return BLPAPI_CALL_SESSIONOPTIONS_SLOWCONSUMERHIWATERMARK(d_handle_p);
    }

    float slowConsumerWarningLoWaterMark()
    {
        return BLPAPI_CALL_SESSIONOPTIONS_SLOWCONSUMERLOWATERMARK(d_handle_p);
    }

    @property int defaultKeepAliveInactivityTime()
    {
        return BLPAPI_CALL_SESSIONOPTIONS_DEFAULTKEEPALIVEINACTIVITYTIME(d_handle_p);
    }


    @property int defaultKeepAliveResponseTimeout()
    {
        return BLPAPI_CALL_SESSIONOPTIONS_DEFAULTKEEPALIVERESPONSETIMEOUT(d_handle_p);
    }

    bool keepAliveEnabled()
    {
        return BLPAPI_CALL_SESSIONOPTIONS_KEEPALIVEENABLED(d_handle_p) != 0 ? true : false;
    }


    bool recordSubscriptionDataReceiveTimes()
    {
        return BLPAPI_CALL_SESSIONOPTION_RECORDSUBSCRIPTIONDATARECEIVETIMES(d_handle_p)? true: false;
    }


    blpapi_SessionOptions_t* handle()
    {
        return d_handle_p;
    }
}


namespace BloombergLP {
namespace blpapi {
                         // ===============
                         // class Operation
                         // ===============

class Operation {
    // Defines an operation which can be performed by a Service.
    //
    // Operation objects are obtained from a Service object. They
    // provide read-only access to the schema of the Operations
    // Request and the schema of the possible response.

    blpapi_Operation_t *d_handle;

  public:
    Operation(blpapi_Operation_t *handle);



// FREE OPERATORS
std::ostream& operator<<(std::ostream& stream, const Service& service);
    // Write the value of the specified 'service' object to the specified
    // output 'stream' in a single-line format, and return a reference to
    // 'stream'.  If 'stream' is not valid on entry, this operation has no
    // effect.  Note that this human-readable format is not fully specified,
    // can change without notice, and is logically equivalent to:
    //..
    //  print(stream, 0, -1);
    //..

// ============================================================================
//                       FUNCTION DEFINITIONS
// ============================================================================

                            // ---------------
                            // class Operation
                            // ---------------

Operation::Operation(blpapi_Operation_t *newHandle)
: d_handle(newHandle)
{
}


Operation::~Operation()
{
}


const char* Operation::name() const
{
    return blpapi_Operation_name(d_handle);
}


const char* Operation::description() const
{
    return blpapi_Operation_description(d_handle);
}


SchemaElementDefinition Operation::requestDefinition() const
{
    blpapi_SchemaElementDefinition_t *definition;

    throwOnError(
            blpapi_Operation_requestDefinition(d_handle, &definition));
    return SchemaElementDefinition(definition);
}


int Operation::numResponseDefinitions() const
{
    return blpapi_Operation_numResponseDefinitions(d_handle);
}


SchemaElementDefinition Operation::responseDefinition(size_t index) const
{
    blpapi_SchemaElementDefinition_t *definition;

    throwOnError(
            blpapi_Operation_responseDefinition(d_handle, &definition, index));
    return SchemaElementDefinition(definition);
}


blpapi_Operation_t* Operation::handle() const
{
    return d_handle;
}


bool Operation::isValid() const
{
    return d_handle != 0;
}
                            // -------------
                            // class Service
                            // -------------


.Service()
: d_handle(0)
{
}

.Service(const Service& original)
    : d_handle(original.d_handle)
{
    addRef();
}

.Service(blpapi_Service_t *newHandle)
    : d_handle(newHandle)
{
    addRef();
}

.~Service()
{
    release();
}


Service& .operator=(const Service& rhs)
{
    if (&rhs != this) {
        release();
        d_handle = rhs.d_handle;
        addRef();
    }
    return *this;
}


void .addRef()
{
    if (d_handle) {
        blpapi_Service_addRef(d_handle);
    }
}


void .release()
{
    if (d_handle) {
        blpapi_Service_release(d_handle);
    }
}


    Request createRequest(string operation)
    {
        blpapi_Request_t *request;
        blpapi_Service_createRequest(d_handle, &request, cast(const(char*))operation) );
        return Request(request);
    }

    Request createAuthorizationRequest(string authorizationOperation)
    {
        blpapi_Request_t *request;
        blpapi_Service_createAuthorizationRequest(d_handle, &request, authorizationOperation);
        return Request(request);
    }

    blpapi_Event_t* createPublishEvent()
    {
        blpapi_Event_t* event;
        blpapi_Service_createPublishEvent(d_handle, &event));
        return event;
    }


    blpapi_Event_t* createAdminEvent()
    {
        blpapi_Event_t* event;
        blpapi_Service_createAdminEvent(d_handle, &event));
        return event;
    }


    blpapi_Event_t* createResponseEvent(const CorrelationId* correlationId)
    {
        blpapi_Event_t* event;
        blpapi_Service_createResponseEvent(d_handle, &correlationId.impl(), &event);
        return event;
    }


    blpapi_Service_t* .handle() const
    {
        return d_handle;
    }


    bool .isValid() const
    {
        return (d_handle != 0);
    }


    const char* .name() const
    {
        return blpapi_Service_name(d_handle);
    }



    const char* .description() const
    {
        return blpapi_Service_description(d_handle);
    }



    size_t .numOperations() const
    {
        return blpapi_Service_numOperations(d_handle);
    }


    bool .hasOperation(const char* operationName) const
    {
        blpapi_Operation_t *operation;
        return
          blpapi_Service_getOperation(d_handle, &operation, operationName, 0) == 0;
    }


    bool .hasOperation(const Name& operationName) const
    {
        blpapi_Operation_t *operation;
        return blpapi_Service_getOperation(d_handle,
                                           &operation,
                                           0,
                                           operationName.impl()) == 0;
    }


    Operation .getOperation(size_t index) const
    {
        blpapi_Operation_t *operation;
        throwOnError(
                blpapi_Service_getOperationAt(d_handle, &operation, index));
        return operation;
    }


    Operation .getOperation(const char* operationName) const
    {
        blpapi_Operation_t *operation;
        throwOnError(
              blpapi_Service_getOperation(d_handle, &operation, operationName, 0));
        return operation;
    }


    Operation getOperation(const Name* operationName)
    {
        blpapi_Operation_t *operation;
        throwOnError(
            blpapi_Service_getOperation(d_handle,
                                        &operation,
                                        0,
                                        operationName.impl()));
        return operation;
    }


    int .numEventDefinitions() const
    {
        return blpapi_Service_numEventDefinitions(d_handle);
    }



    bool .hasEventDefinition(const char* definitionName) const
    {
        blpapi_SchemaElementDefinition_t *eventDefinition;

        return blpapi_Service_getEventDefinition(
                d_handle, &eventDefinition, definitionName, 0) == 0 ? true : false;
    }


    bool .hasEventDefinition(const Name& definitionName) const
    {
        blpapi_SchemaElementDefinition_t *eventDefinition;

        return blpapi_Service_getEventDefinition(d_handle,
                                                 &eventDefinition,
                                                 0,
                                                 definitionName.impl()) == 0
               ? true : false;
    }



    SchemaElementDefinition .getEventDefinition(size_t index) const
    {
        blpapi_SchemaElementDefinition_t *eventDefinition;

        throwOnError(
                blpapi_Service_getEventDefinitionAt(
                    d_handle, &eventDefinition, index));
        return SchemaElementDefinition(eventDefinition);
    }



    SchemaElementDefinition .getEventDefinition(
                                                  const char* definitionName) const
    {
        blpapi_SchemaElementDefinition_t *eventDefinition;
        throwOnError(
            blpapi_Service_getEventDefinition(
                d_handle,
                &eventDefinition,
                definitionName,
                0));
        return SchemaElementDefinition(eventDefinition);
    }


    SchemaElementDefinition .getEventDefinition(
                                                  const Name& definitionName) const
    {
        blpapi_SchemaElementDefinition_t *eventDefinition;
        throwOnError(
            blpapi_Service_getEventDefinition(
                d_handle,
                &eventDefinition,
                0,
                definitionName.impl()));
        return SchemaElementDefinition(eventDefinition);
    }


    const char* .authorizationServiceName() const
    {
        return blpapi_Service_authorizationServiceName(d_handle);
    }


    std::ostream& .print(
            std::ostream& stream,
            int level,
            int spacesPerLevel) const
    {
        blpapi_Service_print(d_handle,
                             StreamProxyOstream::writeToStream,
                             &stream,
                             level,
                             spacesPerLevel);
        return stream;
    }


    std::ostream& operator<<(std::ostream& stream, const Service& service)
    {
        return service.print(stream, 0, -1);
    }

    }  // close namespace blpapi
    }  // close namespace BloombergLP

    #endif // #ifdef __cplusplus
    #endif // #ifndef INCLUDED_BLPAPI_SERVICE



        // ACCESSORS

        const char* name() const;
            // Returns a pointer to a null-terminated, read-only string
            // which contains the name of this operation. The pointer
            // remains valid until this Operation is destroyed.

        const char* description() const;
            // Returns a pointer to a null-terminated, read-only string
            // which contains a human readable description of this
            // Operation. The pointer returned remains valid until this
            // Operation is destroyed.

        SchemaElementDefinition requestDefinition() const;
            // Returns a read-only SchemaElementDefinition which defines
            // the schema for this Operation.

        int numResponseDefinitions() const;
            // Returns the number of the response types that can be
            // returned by this Operation.

        SchemaElementDefinition responseDefinition(size_t index) const;
            // Returns a read-only SchemaElementDefinition which defines
            // the schema for the response that this Operation delivers.

        blpapi_Operation_t* handle() const;

        bool isValid() const;
            // TBD - no default ctor so no need for this?
    };
                             // =============
                             // class Service
                             // =============

    class Service {
        blpapi_Service_t *d_handle;
        void addRef();
        void release();
        Service(blpapi_Service_t *handle);

        Request createRequest(const char* operation) const;
            // Returns a empty Request object for the specified
            // 'operation'. If 'operation' does not identify a valid
            // operation in the Service then an exception is thrown.
            //
            // An application must populate the Request before issuing it
            // using Session::sendRequest().

        Request createAuthorizationRequest(
                                       const char* authorizationOperation=0) const;
            // Returns an empty Request object for the specified
            // 'authorizationOperation'. If the 'authorizationOperation'
            // does not identify a valid operation for this Service then
            // an exception is thrown.
            //
            // An application must populate the Request before issuing it
            // using Session::sendAuthorizationRequest().

        blpapi_Event_t* createPublishEvent() const;
            // Create an Event suitable for publishing to this Service.
            // Use an EventFormatter to add Messages to the Event and set fields.

        blpapi_Event_t* createAdminEvent() const;
            // Create an Admin Event suitable for publishing to this Service.
            // Use an EventFormatter to add Messages to the Event and set fields.

        blpapi_Event_t* createResponseEvent(
                                         const CorrelationId& correlationId) const;
            // Create a response Event to answer the request.
            // Use an EventFormatter to add a Message to the Event and set fields.

        const char* name() const;
            // Returns a pointer to a null-terminated, read-only string
            // which contains the name of this Service. The pointer
            // remains valid until this Service object is destroyed.

        const char* description() const;
            // Returns a pointer to a null-terminated, read-only string
            // which contains a human-readable description of this
            // Service. The pointer remains valid until this Service
            // object is destroyed.

        size_t numOperations() const;
            // Returns the number of Operations defined by this Service.

        bool hasOperation(const char* name) const;
            // Returns true if the specified 'name' identifies a valid
            // Operation in this Service. Otherwise returns false.

        bool hasOperation(const Name& name) const;
            // Returns true if the specified 'name' identifies a valid
            // Operation in this Service. Otherwise returns false.

        Operation getOperation(size_t index) const;
            // Returns the specified 'index'th Operation in this
            // Service. If 'index'>=numOperations() then an exception is
            // thrown.

        Operation getOperation(const char* name) const;
            // Return the definition of the Operation identified by the
            // specified 'name'. If this Service does not define an
            // operation 'name' an exception is thrown.

        Operation getOperation(const Name& name) const;
            // Return the definition of the Operation having the specified
            // 'name'. Throw exception if no such Operation exists in this
            // service.

        int numEventDefinitions() const;
            // Returns the number of unsolicited events defined by this
            // Service.

        bool hasEventDefinition(const char* name) const;
            // Returns true if the specified 'name' identifies a valid
            // event in this Service.

        bool hasEventDefinition(const Name& name) const;
            // Returns true if the specified 'name' identifies a valid
            // event in this Service.

        SchemaElementDefinition getEventDefinition(size_t index) const;
            // Returns the SchemaElementDefinition of the specified
            // 'index'th unsolicited event defined by this service. If
            // 'index'>=numEventDefinitions() an exception is thrown.

        SchemaElementDefinition getEventDefinition(const char* name) const;
            // Return the SchemaElementDefinition of the unsolicited event
            // defined by this Service identified by the specified
            // 'name'. If this Service does not define an unsolicited
            // event 'name' an exception is thrown.

        SchemaElementDefinition getEventDefinition(const Name& name) const;
            // Return the definition of the unsolicited message having the
            // specified 'name' defined by this service.  Throw exception of the no
            // unsolicited message having the specified 'name' is defined by this
            // service.

        const char* authorizationServiceName() const;
            // Returns the name of the Service which must be used in order
            // to authorize access to restricted operations on this
            // Service. If no authorization is required to access
            // operations on this service an empty string is
            // returned. Authorization services never require
            // authorization to use.

        bool isValid() const;
            // Returns true if this Service is valid. That is, it was
            // returned from a Session.

        blpapi_Service_t* handle() const;

        std::ostream& print(std::ostream& stream,
                            int level=0,
                            int spacesPerLevel=4) const;
            // Format this Service schema to the specified output 'stream' at
            // (absolute value specified for) the optionally specified indentation
            // 'level' and return a reference to 'stream'. If 'level' is
            // specified, optionally specify 'spacesPerLevel', the number
            // of spaces per indentation level for this and all of its
            // nested objects. If 'level' is negative, suppress indentation
            // of the first line. If 'spacesPerLevel' is negative, format
            // the entire output on one line, suppressing all but the
            // initial indentation (as governed by 'level').
    };





class Message {
    // A handle to a single message.
    //
    // Message objects are obtained from a MessageIterator. Each
    // Message is associated with a Service and with one or more
    // CorrelationId values. The Message contents are represented as
    // an Element and some convenient shortcuts are supplied to the
    // Element accessors.
    //
    // A Message is a handle to a single underlying protocol
    // message. The underlying messages are reference counted - the
    // underlying Message object is freed when the last Message object
    // which references it is destroyed.

    blpapi_Message_t *d_handle;
    Element           d_elements;
    bool              d_isCloned;

  public:
    enum Fragment {
        // A message could be split into more than one fragments to reduce
        // each message size. This enum is used to indicate whether a message
        // is a fragmented message and the position in the fragmented messages.

        FRAGMENT_NONE = 0, // message is not fragmented
        FRAGMENT_START, // the first fragmented message
        FRAGMENT_INTERMEDIATE, // intermediate fragmented messages
        FRAGMENT_END // the last fragmented message
    };


    this(blpapi_Message_t *handle, bool clonable): d_handle(handle), d_isCloned(clonable)
    {
        if (handle) {
            d_elements = Element(blpapi_Message_elements(handle));
        }
    }


    Message(const Message& original) : d_handle(original.d_handle) , d_elements(original.d_elements) , d_isCloned(true)
    {
        if (d_handle) {
            BLPAPI_CALL_MESSAGE_ADDREF(d_handle);
        }
    }


    ~Message()
    {
        if (d_isCloned && d_handle) {
            BLPAPI_CALL_MESSAGE_RELEASE(d_handle);
        }
    }
    // MANIPULATORS

    Message& operator=(const Message& rhs)
    {

        if (this == &rhs) {
            return *this;
        }

        if (d_isCloned && (d_handle == rhs.d_handle)) {
            return *this;
        }

        if (d_isCloned && d_handle) {
            BLPAPI_CALL_MESSAGE_RELEASE(d_handle);
        }
        d_handle = rhs.d_handle;
        d_elements = rhs.d_elements;
        d_isCloned = true;

        if (d_handle) {
            BLPAPI_CALL_MESSAGE_ADDREF(d_handle);
        }

        return *this;
    }

    // ACCESSORS

    Name messageType() const
    {
        return Name(blpapi_Message_messageType(d_handle));
    }


    const char* topicName() const
    {
        return blpapi_Message_topicName(d_handle);
    }


    Service service() const
    {
        return Service(blpapi_Message_service(d_handle));
    }


    int numCorrelationIds() const
    {
        return blpapi_Message_numCorrelationIds(d_handle);
    }


    CorrelationId correlationId(size_t index) const
    {
        if (index >= (size_t)numCorrelationIds())
            throw IndexOutOfRangeException("index >= numCorrelationIds");
        return CorrelationId(blpapi_Message_correlationId(d_handle, index));
    }


    bool hasElement(string name, bool excludeNullElements)
    {
        return d_elements.hasElement(name, excludeNullElements);
    }


    size_t numElements()
    {
        return d_elements.numElements();
    }


    const Element getElement(const Name& name) const
    {
        return d_elements.getElement(name);
    }


    const Element getElement(const char* nameString) const
    {
        return d_elements.getElement(nameString);
    }


    bool getElementAsBool(const Name& name) const
    {
        return d_elements.getElementAsBool(name);
    }


    bool getElementAsBool(const char* name) const
    {
        return d_elements.getElementAsBool(name);
    }


    char getElementAsChar(const Name& name) const
    {
        return d_elements.getElementAsChar(name);
    }


    char getElementAsChar(const char* name) const
    {
        return d_elements.getElementAsChar(name);
    }


    Int32 getElementAsInt32(const Name& name) const
    {
        return d_elements.getElementAsInt32(name);
    }


    Int32 getElementAsInt32(const char* name) const
    {
        return d_elements.getElementAsInt32(name);
    }


    Int64 getElementAsInt64(const Name& name) const
    {
        return d_elements.getElementAsInt64(name);
    }


    Int64 getElementAsInt64(const char* name) const
    {
        return d_elements.getElementAsInt64(name);
    }


    Float32 getElementAsFloat32(const Name& name) const
    {
        return d_elements.getElementAsFloat32(name);
    }


    Float32 getElementAsFloat32(const char* name) const
    {
        return d_elements.getElementAsFloat32(name);
    }


    Float64 getElementAsFloat64(const Name& name) const
    {
        return d_elements.getElementAsFloat64(name);
    }


    Float64 getElementAsFloat64(const char* name) const
    {
        return d_elements.getElementAsFloat64(name);
    }


    Datetime getElementAsDatetime(const Name& name) const
    {
        return d_elements.getElementAsDatetime(name);
    }


    Datetime getElementAsDatetime(const char* name) const
    {
        return d_elements.getElementAsDatetime(name);
    }


    const char* getElementAsString(const Name& name) const
    {
        return d_elements.getElementAsString(name);
    }


    const char* getElementAsString(const char* name) const
    {
        return d_elements.getElementAsString(name);
    }


    const Element asElement() const
    {
        return d_elements;
    }


    const char *getPrivateData(size_t *size) const
    {
        return blpapi_Message_privateData(d_handle, size);
    }


    Fragment fragmentType() const
    {
        return (Fragment) BLPAPI_CALL_MESSAGE_FRAGMENTTYPE(d_handle);
    }


    int timeReceived(TimePoint *timestamp) const
    {
        return BLPAPI_CALL_MESSAGE_TIMERECEIVED(
            d_handle,
            timestamp);
    }


    std::ostream& print(
            std::ostream& stream,
            int level,
            int spacesPerLevel) const
    {
        return d_elements.print(stream, level, spacesPerLevel);
    }


    std::ostream& operator<<(std::ostream& stream, const Message &message)
    {
        return message.print(stream, 0,-1);
    }


    const blpapi_Message_t* impl() const
    {
        return d_handle;
    }


    blpapi_Message_t* impl()
    {
        return d_handle;
    }

    }  // close namespace blpapi
    }  // close namespace BloombergLP

    #endif // #ifdef __cplusplus
    #endif // #ifndef INCLUDED_BLPAPI_MESSAGE



struct VersionInfo 
{
    int d_major; // BLPAPI SDK library major version
    int d_minor; // BLPAPI SDK library minor version
    int d_patch; // BLPAPI SDK library patch version
    int d_build; // BLPAPI SDK library build version

    this VersionInfo(int major, int minor, int patch, int build)
    {  
        d_major=major;
        d_minor=minor;
        d_patch=patch;
        d_build=build;
    }
    VersionInfo headerVersion()
    {
        return VersionInfo(BLPAPI_VERSION_MAJOR, BLPAPI_VERSION_MINOR, BLPAPI_VERSION_PATCH, BLPAPI_VERSION_BUILD);
    }

    VersionInfo runtimeVersion()
    {
        int major, minor, patch, build;
        blpapi_getVersionInfo(&major, &minor, &patch, &build);
        return VersionInfo(major, minor, patch, build);
    }

    void VersionInfo()
    {
        blpapi_getVersionInfo(&d_major, &d_minor, &d_patch, &d_build);
    }

    @property int majorVersion()
    {
        return d_major;
    }

    @property int minorVersion()
    {
        return d_minor;
    }

    @property int patchVersion()
    {
        return d_patch;
    }

    @property intbuildVersion()
    {
        return d_build;
    }

    @property string versionIdentifier()
    {
        string s;
        s = "blpapi-cpp; headers " ~ to!string(headerVersion()) ~ "; runtime " ~ to!string(runtimeVersion());
        if (BLPAPI_CALL_AVAILABLE(blpapi_getVersionIdentifier)) {
            s ~= '-' ~=BLPAPI_CALL(blpapi_getVersionIdentifier)();
        }
        return s;
    }

    enum Status { //TopicList
        NOT_CREATED,
        CREATED,
        FAILURE
    }

class TopicList
{
    blpapi_TopicList_t *d_handle_p;

    TopicList()
    : d_handle_p(blpapi_TopicList_create(0))
    {
    }

    TopicList(
            const TopicList& original)
    : d_handle_p(blpapi_TopicList_create(original.d_handle_p))
    {
    }


    TopicList(
            const ResolutionList& original)
    : d_handle_p(
          blpapi_TopicList_create((blpapi_TopicList_t *)original.impl()))
    {
    }


    ~TopicList()
    {
        blpapi_TopicList_destroy(d_handle_p);
    }


    int add(string topic, CorrelationId* correlationId)
    {
        return blpapi_TopicList_add(d_handle_p, cast(const(char*))topic, &correlationId.impl());
    }


    int add(const Message* newMessage,const CorrelationId* correlationId)
    {
        return blpapi_TopicList_addFromMessage(d_handle_p, newMessage.impl(), &correlationId.impl());
    }


    CorrelationId correlationIdAt(size_t index)
    {
        blpapi_CorrelationId_t correlationId;
        blpapi_TopicList_correlationIdAt(d_handle_p, &correlationId, index));
        return CorrelationId(correlationId);
    }


    string topicString(const CorrelationId* correlationId)
    {
        char *topic;
        blpapi_TopicList_topicString(d_handle_p, &topic, &correlationId.impl()));
        return to!string(*topic);
    }


    string topicStringAt(size_t index)
    {
        const char* topic;
        throwOnError(
            blpapi_TopicList_topicStringAt(d_handle_p, &topic, index));

        return to!string(topic);
    }


    int status(const CorrelationId& correlationId) const
    {
        int result;
        throwOnError(
            blpapi_TopicList_status(d_handle_p, &result, &correlationId.impl()));

        return result;
    }


    int statusAt(size_t index) const
    {
        int result;
        throwOnError(
            blpapi_TopicList_statusAt(d_handle_p, &result, index));

        return result;
    }


    Message const message(const CorrelationId& correlationId) const
    {
        blpapi_Message_t* messageByCid;
        blpapi_TopicList_message(d_handle_p, &messageByCid, &correlationId.impl()));
        BLPAPI_CALL_MESSAGE_ADDREF(messageByCid);
        return Message(messageByCid, true);
    }


    Message const messageAt(size_t index) const
    {
        blpapi_Message_t* messageByIndex;
        blpapi_TopicList_messageAt(d_handle_p, &messageByIndex, index);
        BLPAPI_CALL_MESSAGE_ADDREF(messageByIndex);
        return Message(messageByIndex, true);
    }


    size_t size()
    {
        return blpapi_TopicList_size(d_handle_p);
    }


    const blpapi_TopicList_t* impl()
    {
        return d_handle_p;
    }


    blpapi_TopicList_t* impl()
    {
        return d_handle_p;
    }
}



class Topic {
    blpapi_Topic_t *d_handle;

    Topic() : d_handle(0)
    {}


    Topic(blpapi_Topic_t* handle) : d_handle(blpapi_Topic_create(handle))
    {}


    Topic(Topic const& original) :d_handle(blpapi_Topic_create(original.d_handle))


    ~Topic()
    {
        blpapi_Topic_destroy(d_handle);
    }

    Topic* operator=(Topic const& rhs)
    {
        if (this != &rhs) {
            blpapi_Topic_destroy(d_handle);
            d_handle = blpapi_Topic_create(rhs.d_handle);
        }
        return *this;
    }

    .
    bool isValid()
    {
        return 0 != d_handle;
    }

    .
    bool isActive()
    {
        return blpapi_Topic_isActive(d_handle) != 0;
    }

    .
    Service service()
    {
        return blpapi_Topic_service(d_handle);
    }

    .
    const blpapi_Topic_t* impl()
    {
        return d_handle;
    }

    .
    blpapi_Topic_t* impl()
    {
        return d_handle;
    }

    .
    bool operator==(Topic const& lhs, Topic const& rhs)
    {
        return blpapi_Topic_compare(lhs.impl(), rhs.impl())==0;
    }

    .
    bool operator!=(Topic const& lhs, Topic const& rhs)
    {
        return blpapi_Topic_compare(lhs.impl(), rhs.impl())!=0;
    }

    .
    bool operator<(Topic const& lhs, Topic const& rhs)
    {
        return blpapi_Topic_compare(lhs.impl(), rhs.impl())<0;
    }

}



class SubscriptionList {
    // Contains a list of subscriptions used when subscribing and
    // unsubscribing.
    //
    // A 'SubscriptionList' is used when calling 'Session::subscribe()',
    // 'Session::resubscribe()' and 'Session::unsubscribe()'.  The entries can
    // be constructed in a variety of ways.
    // The two important elements when creating a subscription are
    //: Subscription String: A subscription string represents a topic whose
    //:  updates user is interested in.  A subscription string follows a
    //:  structure as specified below.
    //: CorrelationId: the unique identifier to tag all data associated with
    //:  this subscription.
    //
    // The following table describes how various operations use the above
    // elements:
    // --------------|--------------------------------------------------------|
    //  OPERATION    |  SUBSCRIPTION STRING  |       CORRELATION ID           |
    // --------------|-----------------------+--------------------------------|
    //  'subscribe'  |Used to specify the    |Identifier for the subscription.|
    //               |topic to subscribe to. |If uninitialized correlationid  |
    //               |                       |was specified an internally     |
    //               |                       |generated correlationId will be |
    //               |                       |set for the subscription.       |
    // --------------+-----------------------+--------------------------------|
    // 'resubscribe' |Used to specify the new|Identifier of the subscription  |
    //               |topic to which the     |which needs to be modified.     |
    //               |subscription should be |                                |
    //               |modified to.           |                                |
    // --------------+-----------------------+--------------------------------|
    // 'unsubscribe' |        NOT USED       |Identifier of the subscription  |
    //               |                       |which needs to be canceled.     |
    // -----------------------------------------------------------------------|

    blpapi_SubscriptionList_t *d_handle_p;

SubscriptionList::SubscriptionList()
: d_handle_p(blpapi_SubscriptionList_create())
{
}


SubscriptionList::SubscriptionList(const SubscriptionList& original)
: d_handle_p(blpapi_SubscriptionList_create())
{
    blpapi_SubscriptionList_append(d_handle_p, original.d_handle_p);
}


SubscriptionList::~SubscriptionList()
{
    blpapi_SubscriptionList_destroy(d_handle_p);
}


int SubscriptionList::add(const char *subscriptionString)
{
    blpapi_CorrelationId_t correlationId;
    std::memset(&correlationId, 0, sizeof(correlationId));
    return blpapi_SubscriptionList_add(d_handle_p,
                                       subscriptionString,
                                       &correlationId,
                                       0,
                                       0,
                                       0,
                                       0);
}


int SubscriptionList::add(const char           *subscriptionString,
                          const CorrelationId&  correlationId)
{
    return blpapi_SubscriptionList_add(d_handle_p,
                                       subscriptionString,
                                       &correlationId.impl(),
                                       0,
                                       0,
                                       0,
                                       0);
}


add(string subscriptionString, string[] fields,string[] options,CorrelationId* correlationId)
{
    string[] tmpVector;
    const char *arena[256];
    const char **tmpArray = arena;
    size_t sizeNeeded = fields.size() + options.size();

    if (sizeNeeded > sizeof(arena)/sizeof(arena[0])) {
        tmpVector.resize(sizeNeeded);
        tmpArray = &tmpVector[0];
    }

    const char **p = tmpArray;
    for (std::vector<std::string>::const_iterator itr = fields.begin(),
            end = fields.end(); itr != end; ++itr, ++p) {
        *p = itr.c_str();
    }

    for (std::vector<std::string>::const_iterator itr = options.begin(),
            end = options.end(); itr != end; ++itr, ++p) {
        *p = itr.c_str();
    }

    return blpapi_SubscriptionList_add(d_handle_p,
                                       subscriptionString,
                                       &correlationId.impl(),
                                       tmpArray,
                                       tmpArray + fields.size(),
                                       fields.size(),
                                       options.size());
}


int SubscriptionList::add(const char           *subscriptionString,
                          const char           *fields,
                          const char           *options,
                          const CorrelationId&  correlationId)
{
    return blpapi_SubscriptionList_add(d_handle_p,
                                       subscriptionString,
                                       &correlationId.impl(),
                                       &fields,
                                       &options,
                                       fields ? 1 : 0,
                                       options ? 1 : 0 );

}


int SubscriptionList::add(const CorrelationId& correlationId)
{
    return blpapi_SubscriptionList_add(d_handle_p,
                                       "",
                                       &correlationId.impl(),
                                       0,
                                       0,
                                       0,
                                       0);
}


int SubscriptionList::addResolved(const char *subscriptionString)
{
    blpapi_CorrelationId_t correlationId;
    std::memset(&correlationId, 0, sizeof(correlationId));
    return BLPAPI_CALL_SUBSCRIPTIONLIST_ADDRESOLVED(d_handle_p,
                                                    subscriptionString,
                                                    &correlationId);
}


int SubscriptionList::addResolved(const char *subscriptionString,
                                  const CorrelationId& correlationId)
{
    return BLPAPI_CALL_SUBSCRIPTIONLIST_ADDRESOLVED(d_handle_p,
                                                    subscriptionString,
                                                    &correlationId.impl());
}


int SubscriptionList::append(const SubscriptionList& other)
{
    return blpapi_SubscriptionList_append(d_handle_p, other.d_handle_p);
}


void SubscriptionList::clear()
{
    blpapi_SubscriptionList_clear(d_handle_p);
}


SubscriptionList& SubscriptionList::operator=(const SubscriptionList& rhs)
{
    blpapi_SubscriptionList_clear(d_handle_p);
    blpapi_SubscriptionList_append(d_handle_p, rhs.d_handle_p);
    return *this;
}


size_t SubscriptionList::size() const
{
    return blpapi_SubscriptionList_size(d_handle_p);
}


CorrelationId SubscriptionList::correlationIdAt(size_t index) const
{
    blpapi_CorrelationId_t correlationId;

    throwOnError(
            blpapi_SubscriptionList_correlationIdAt(d_handle_p,
                                                    &correlationId,
                                                    index));

    return CorrelationId(correlationId);
}


const char *SubscriptionList::topicStringAt(size_t index) const
{
    const char *result;

    throwOnError(
            blpapi_SubscriptionList_topicStringAt(d_handle_p,
                                                  &result,
                                                  index));

    return result;
}


bool SubscriptionList::isResolvedTopicAt(size_t index) const
{
    int result;

    throwOnError(
            BLPAPI_CALL_SUBSCRIPTIONLIST_ISRESOLVEDAT(d_handle_p,
                                                      &result,
                                                      index));

    return result ? true : false;
}


const blpapi_SubscriptionList_t *SubscriptionList::impl() const
{
    return d_handle_p;
}

}  // close package namespace
}  // close enterprise namespace

#endif // ifdef __cplusplus


#endif // #ifndef INCLUDED_BLPAPI_SUBSCRIPTIONLIST




class Operation {
    // Defines an operation which can be performed by a Service.
    //
    // Operation objects are obtained from a Service object. They
    // provide read-only access to the schema of the Operations
    // Request and the schema of the possible response.

    blpapi_Operation_t *d_handle;

  public:
    Operation(blpapi_Operation_t *handle);

    ~Operation();
        // Destroy this Operation object.

    // ACCESSORS

    const char* name() const;
        // Returns a pointer to a null-terminated, read-only string
        // which contains the name of this operation. The pointer
        // remains valid until this Operation is destroyed.

    const char* description() const;
        // Returns a pointer to a null-terminated, read-only string
        // which contains a human readable description of this
        // Operation. The pointer returned remains valid until this
        // Operation is destroyed.

    SchemaElementDefinition requestDefinition() const;
        // Returns a read-only SchemaElementDefinition which defines
        // the schema for this Operation.

    int numResponseDefinitions() const;
        // Returns the number of the response types that can be
        // returned by this Operation.

    SchemaElementDefinition responseDefinition(size_t index) const;
        // Returns a read-only SchemaElementDefinition which defines
        // the schema for the response that this Operation delivers.

    blpapi_Operation_t* handle() const;

    bool isValid() const;
        // TBD - no default ctor so no need for this?
};
                         // =============
                         // class Service
                         // =============

class Service {
    // Defines a service which provides access to API data.
    //
    // A Service object is obtained from a Session and contains the
    // Operations (each of which contains its own schema) and the
    // schema for Events which this Service may produce. A Service
    // object is also used to create Request objects used with a
    // Session to issue requests.
    //
    // All API data is associated with a service. Before accessing API
    // data using either request-reply or subscription, the appropriate
    // Service must be opened and, if necessary, authorized.
    //
    // Provider services are created to generate API data and must be
    // registered before use.
    //
    // The Service object is a handle to the underlying data which is
    // owned by the Session. Once a Service has been successfully
    // opened in a Session it remains accessible until the Session is
    // terminated.

    blpapi_Service_t *d_handle;

    void addRef();
    void release();

// ============================================================================
//                       FUNCTION DEFINITIONS
// ============================================================================

                            // ---------------
                            // class Operation
                            // ---------------

Operation::Operation(blpapi_Operation_t *newHandle)
: d_handle(newHandle)
{
}


Operation::~Operation()
{
}


const char* Operation::name() const
{
    return blpapi_Operation_name(d_handle);
}


const char* Operation::description() const
{
    return blpapi_Operation_description(d_handle);
}


SchemaElementDefinition Operation::requestDefinition() const
{
    blpapi_SchemaElementDefinition_t *definition;

    throwOnError(
            blpapi_Operation_requestDefinition(d_handle, &definition));
    return SchemaElementDefinition(definition);
}


int Operation::numResponseDefinitions() const
{
    return blpapi_Operation_numResponseDefinitions(d_handle);
}


SchemaElementDefinition Operation::responseDefinition(size_t index) const
{
    blpapi_SchemaElementDefinition_t *definition;

    throwOnError(
            blpapi_Operation_responseDefinition(d_handle, &definition, index));
    return SchemaElementDefinition(definition);
}


blpapi_Operation_t* Operation::handle() const
{
    return d_handle;
}


bool Operation::isValid() const
{
    return d_handle != 0;
}
                            // -------------
                            // class Service
                            // -------------


Service::Service()
: d_handle(0)
{
}


Service::Service(const Service& original)
    : d_handle(original.d_handle)
{
    addRef();
}


Service::Service(blpapi_Service_t *newHandle)
    : d_handle(newHandle)
{
    addRef();
}


Service::~Service()
{
    release();
}


Service& Service::operator=(const Service& rhs)
{
    if (&rhs != this) {
        release();
        d_handle = rhs.d_handle;
        addRef();
    }
    return *this;
}


void Service::addRef()
{
    if (d_handle) {
        blpapi_Service_addRef(d_handle);
    }
}


void Service::release()
{
    if (d_handle) {
        blpapi_Service_release(d_handle);
    }
}


Request Service::createRequest(const char* operation) const
{
    blpapi_Request_t *request;
    throwOnError(
            blpapi_Service_createRequest(
                d_handle,
                &request,
                operation)
            );
    return Request(request);
}


Request Service::createAuthorizationRequest(
        const char* authorizationOperation) const
{
    blpapi_Request_t *request;
    throwOnError(
            blpapi_Service_createAuthorizationRequest(
                d_handle,
                &request,
                authorizationOperation)
            );
    return Request(request);
}


blpapi_Event_t* Service::createPublishEvent() const
{
    blpapi_Event_t* event;
    throwOnError(
        blpapi_Service_createPublishEvent(
            d_handle,
            &event));
    return event;
}


blpapi_Event_t* Service::createAdminEvent() const
{
    blpapi_Event_t* event;
    throwOnError(
        blpapi_Service_createAdminEvent(
            d_handle,
            &event));
    return event;
}


blpapi_Event_t* Service::createResponseEvent(
    const CorrelationId& correlationId) const
{
    blpapi_Event_t* event;
    throwOnError(
        blpapi_Service_createResponseEvent(
            d_handle,
            &correlationId.impl(),
            &event));
    return event;
}


blpapi_Service_t* Service::handle() const
{
    return d_handle;
}


bool Service::isValid() const
{
    return (d_handle != 0);
}


const char* Service::name() const
{
    return blpapi_Service_name(d_handle);
}



const char* Service::description() const
{
    return blpapi_Service_description(d_handle);
}



size_t Service::numOperations() const
{
    return blpapi_Service_numOperations(d_handle);
}


bool Service::hasOperation(const char* operationName) const
{
    blpapi_Operation_t *operation;
    return
      blpapi_Service_getOperation(d_handle, &operation, operationName, 0) == 0;
}


bool Service::hasOperation(const Name& operationName) const
{
    blpapi_Operation_t *operation;
    return blpapi_Service_getOperation(d_handle,
                                       &operation,
                                       0,
                                       operationName.impl()) == 0;
}


Operation Service::getOperation(size_t index) const
{
    blpapi_Operation_t *operation;
    throwOnError(
            blpapi_Service_getOperationAt(d_handle, &operation, index));
    return operation;
}


Operation Service::getOperation(const char* operationName) const
{
    blpapi_Operation_t *operation;
    throwOnError(
          blpapi_Service_getOperation(d_handle, &operation, operationName, 0));
    return operation;
}


Operation Service::getOperation(const Name& operationName) const
{
    blpapi_Operation_t *operation;
    throwOnError(
        blpapi_Service_getOperation(d_handle,
                                    &operation,
                                    0,
                                    operationName.impl()));
    return operation;
}


int Service::numEventDefinitions() const
{
    return blpapi_Service_numEventDefinitions(d_handle);
}



bool Service::hasEventDefinition(const char* definitionName) const
{
    blpapi_SchemaElementDefinition_t *eventDefinition;

    return blpapi_Service_getEventDefinition(
            d_handle, &eventDefinition, definitionName, 0) == 0 ? true : false;
}


bool Service::hasEventDefinition(const Name& definitionName) const
{
    blpapi_SchemaElementDefinition_t *eventDefinition;

    return blpapi_Service_getEventDefinition(d_handle,
                                             &eventDefinition,
                                             0,
                                             definitionName.impl()) == 0
           ? true : false;
}



SchemaElementDefinition Service::getEventDefinition(size_t index) const
{
    blpapi_SchemaElementDefinition_t *eventDefinition;

    throwOnError(
            blpapi_Service_getEventDefinitionAt(
                d_handle, &eventDefinition, index));
    return SchemaElementDefinition(eventDefinition);
}



SchemaElementDefinition Service::getEventDefinition(
                                              const char* definitionName) const
{
    blpapi_SchemaElementDefinition_t *eventDefinition;
    throwOnError(
        blpapi_Service_getEventDefinition(
            d_handle,
            &eventDefinition,
            definitionName,
            0));
    return SchemaElementDefinition(eventDefinition);
}


SchemaElementDefinition Service::getEventDefinition(
                                              const Name& definitionName) const
{
    blpapi_SchemaElementDefinition_t *eventDefinition;
    throwOnError(
        blpapi_Service_getEventDefinition(
            d_handle,
            &eventDefinition,
            0,
            definitionName.impl()));
    return SchemaElementDefinition(eventDefinition);
}


const char* Service::authorizationServiceName() const
{
    return blpapi_Service_authorizationServiceName(d_handle);
}


std::ostream& Service::print(
        std::ostream& stream,
        int level,
        int spacesPerLevel) const
{
    blpapi_Service_print(d_handle,
                         StreamProxyOstream::writeToStream,
                         &stream,
                         level,
                         spacesPerLevel);
    return stream;
}


std::ostream& operator<<(std::ostream& stream, const Service& service)
{
    return service.print(stream, 0, -1);
}

}  // close namespace blpapi
}  // close namespace BloombergLP

#endif // #ifdef __cplusplus
#endif // #ifndef INCLUDED_BLPAPI_SERVICE




struct SchemaStatus {
    // This 'struct' provides a namespace for enumerating the possible
    // deprecation statuses of a schema element or type.

    enum Value {
        ACTIVE              = BLPAPI_STATUS_ACTIVE,     // This item is current
                                                        // and may appear in
                                                        // Messages
        DEPRECATED          = BLPAPI_STATUS_DEPRECATED, // This item is current
                                                        // and may appear in
                                                        // Messages but will be
                                                        // removed in due
                                                        // course
        INACTIVE            = BLPAPI_STATUS_INACTIVE,   // This item is not
                                                        // current and will not
                                                        // appear in Messages
        PENDING_DEPRECATION = BLPAPI_STATUS_PENDING_DEPRECATION
                                                        // This item is
                                                        // expected to be
                                                        // deprecated in the
                                                        // future; clients are
                                                        // advised to migrate
                                                        // away from use of
                                                        // this item.
    };
};

class SchemaTypeDefinition;

                       // =============================
                       // class SchemaElementDefinition
                       // =============================

class SchemaElementDefinition {
    // This class implements the definition of an individual field within a
    // schema type. An element is defined by an identifer/name, a type, and the
    // number of values of that type that may be associated with the
    // identifier/name. In addition, this class offers access to metadata
    // providing a description and deprecation status for the field. Finally,
    // 'SchemaElementDefinition' provides an interface for associating
    // arbitrary user-defined data (specified as a 'void*') with an element
    // definition.
    //
    // 'SchemaElementDefinition' objects are returned by 'Service' and
    // 'Operation' objects to define the content of requests, replies and
    // events. The 'SchemaTypeDefinition' returned by
    // 'SchemaElementDefinition::typeDefinition()' may itself provide access to
    // 'SchemaElementDefinition' objects when the schema contains nested
    // elements. (See the 'SchemaTypeDefinition' documentation for more
    // information on complex types.)
    //
    // An optional element has 'minValues() == 0'.
    //
    // A mandatory element has 'minValues() >= 1'.
    //
    // An element that must constain a single value has
    // 'minValues() == maxValues() == 1'.
    //
    // An element containing an array has 'maxValues() > 1'.
    //
    // An element with no upper limit on the number of values has
    // 'maxValues() == UNBOUNDED'.
    //
    // 'SchemaElementDefinition' objects are read-only, with the exception of a
    // single 'void*' attribute for storing user data.
    // 'SchemaElementDefinition' objects have *reference* *semantics* with
    // respect to this user data field: calling 'c.setUserData(void*)' modifies
    // the user data associated with 'c', as well as that associated with all
    // copies of 'c'. As a result, functions which set or read this attribute
    // are *NOT* per-object thread-safe. Clients must syncrhonize such
    // operations across *all* *copies* of an object.
    //
    // Application clients need never create fresh 'SchemaElementDefinition'
    // objects directly; applications will typically work with copies of
    // objects returned by other 'blpapi' components.

    blpapi_SchemaElementDefinition_t *d_impl_p;

  public:
    // Constants used in the SchemaElementDefinition interface.

    enum {
        UNBOUNDED = BLPAPI_ELEMENTDEFINITION_UNBOUNDED  // Indicates an array
                                                        // has an unbounded
                                                        // number of values.
    };

    SchemaElementDefinition(blpapi_SchemaElementDefinition_t *handle);

    ~SchemaElementDefinition();
        // Destroy this object.

    // MANIPULATORS

    void setUserData(void *userData);
        // Set the user data associated with this 'SchemaElementDefinition' --
        // and all copies of this 'SchemaElementDefinition' -- to the specified
        // 'userData'. Clients are responsible for synchronizing calls to this
        // function, and to 'userData()', across all copies of this
        // 'SchemaElementDefinition' object.

    // ACCESSORS

    Name name() const;
        // Return the name identifying this element within its containing
        // structure/type.

    const char *description() const;
        // Return a null-terminated string containing a human-readable
        // description of this element. This pointer is valid until this
        // 'SchemaElementDefinition' is destroyed.

    int status() const;
        // Return the deprecation status, as a 'SchemaStatus::Value', of this
        // element.

    const SchemaTypeDefinition typeDefinition() const;
        // Return the type of values contained in this element.

    size_t minValues() const;
        // Return the minimum number of occurrences of this element. This value
        // is always greater than or equal to zero.

    size_t maxValues() const ;
        // Return the maximum number of occurrences of this element. This value
        // is always greater than or equal to one.

    size_t numAlternateNames() const;
        // Return the number of alternate names for this element.

    Name getAlternateName(size_t index) const;
        // Return the specified 'index'th alternate name for this element. If
        // 'index >=numAlternateNames()' an exception is thrown.

    void *userData() const;
        // Return the user data associated with this 'SchemaElementDefinition'.
        // If no user data has been associated with this
        // 'SchemaElementDefinition' then return 0. Clients are responsible for
        // synchronizing calls to this function with calls to
        // 'setUserData(void*)' made on not only this
        // 'SchemaElementDefinition', but also all copies of this
        // 'SchemaElementDefinition'. Note that 'SchemaElementDefinition'
        // objects have reference semantics: this function will reflect the
        // last value set on *any* copy of this 'SchemaElementDefinition'.

    std::ostream& print(std::ostream& stream,
                        int level=0,
                        int spacesPerLevel=4) const;
        // Format this SchemaElementDefinition to the specified output 'stream'
        // at the (absolute value of) the optionally specified indentation
        // 'level' and return a reference to 'stream'. If 'level' is specified,
        // optionally specify 'spacesPerLevel', the number of spaces per
        // indentation level for this and all of its nested objects. If 'level'
        // is negative, suppress indentation of the first line. If
        // 'spacesPerLevel' is negative, format the entire output on one line,
        // suppressing all but the initial indentation (as governed by
        // 'level').

    blpapi_SchemaElementDefinition_t *impl() const;
};

// FREE OPERATORS
std::ostream& operator<<(std::ostream& stream,
                         const SchemaElementDefinition& element);
    // Write the value of the specified 'element' object to the specified
    // output 'stream' in a single-line format, and return a reference to
    // 'stream'.  If 'stream' is not valid on entry, this operation has no
    // effect.  Note that this human-readable format is not fully specified,
    // can change without notice, and is logically equivalent to:
    //..
    //  print(stream, 0, -1);
    //..

                       // ==========================
                       // class SchemaTypeDefinition
                       // ==========================

class SchemaTypeDefinition {
    // This class implements a representation of a "type" that can be used
    // within a schema, including both simple atomic types (integers, dates,
    // strings, etc.) as well as "complex" types defined a sequences of or
    // choice among a collection (named) elements, each of which is in turn
    // described by another type. In addition to accessors for the type's
    // structure, this class also offers access to metadata providing a
    // description and deprecation status for the type. Finally,
    // 'SchemaTypeDefinition' provides an interface for associating arbitrary
    // user-defined data (specified as a 'void*') with a type definition.
    //
    // Each 'SchemaElementDefinition' object is associated with a single
    // 'SchemaTypeDefinition'; one 'SchemaTypeDefinition' may be used by zero,
    // one, or many 'SchemaElementDefinition' objects.
    //
    // 'SchemaTypeDefinition' objects are read-only, with the exception of a
    // single 'void*' attribute for storing user data. 'SchemaTypeDefinition'
    // objects have *reference* *semantics* with respect to this user data
    // field: calling 'c.setUserData(void*)' modifies the user data associated
    // with 'c', as well as that associated with all copies of 'c'. As a
    // result, functions which set or read this attribute are *NOT* per-object
    // thread-safe. Clients must syncrhonize such operations across *all*
    // *copies* of an object.
    //
    // Application clients need never create fresh 'SchemaTypeDefinition'
    // objects directly; applications will typically work with copies of
    // objects returned by other 'blpapi' components.

    blpapi_SchemaTypeDefinition_t *d_impl_p;

  public:
    SchemaTypeDefinition(blpapi_SchemaTypeDefinition_t *handle);

    ~SchemaTypeDefinition();
        // Destroy this object.

    // MANIPULATORS

    void setUserData(void *userData);
        // Set the user data associated with this 'SchemaTypeDefinition' -- and
        // all copies of this 'SchemaTypeDefinition' -- to the specified
        // 'userData'. Clients are responsible for synchronizing calls to this
        // function, and to 'userData()', across all copies of this
        // 'SchemaTypeDefinition' object.

    // ACCESSORS

    int datatype() const;
        // Return the 'DataType' of this 'SchemaTypeDefinition'.

    Name name() const;
        // Return the name of this 'SchemaTypeDefinition'.

    const char *description() const;
        // Return a null-terminated string which contains a human readable
        // description of this 'SchemaTypeDefinition'. The returned pointer
        // remains valid until this 'SchemaTypeDefinition' is destroyed.

    int status() const;
        // Return the deprecation status, as a 'SchemaStatus::Value', of this
        // 'SchemaTypeDefinition'.

    size_t numElementDefinitions() const;
        // Return the number of 'SchemaElementDefinition' objects contained by
        // this 'SchemaTypeDefinition'. If this 'SchemaTypeDefinition' is
        // neither a choice nor a sequence this will return 0.

    bool isComplexType() const;
        // Return 'true' if this 'SchemaTypeDefinition' represents a sequence
        // or choice type.

    bool isSimpleType() const;
        // Return 'true' if this 'SchemaTypeDefinition' represents neither a
        // sequence nor a choice type.

    bool isEnumerationType() const;
        // Return 'true' if this 'SchemaTypeDefinition' represents an enumeration
        // type.

    bool hasElementDefinition(const Name& name) const;
        // Return 'true' if this 'SchemaTypeDefinition' contains an element
        // with the specified 'name'; otherwise returns 'false'.

    bool hasElementDefinition(const char *name) const;
        // Return 'true' if this 'SchemaTypeDefinition' contains an element
        // with the specified 'name'; otherwise returns 'false'.

    SchemaElementDefinition getElementDefinition(const Name& name) const;
        // Return the definition of the element identified by the specified
        // 'name'. If 'hasElementDefinition(name) != true' then an exception is
        // thrown.

    SchemaElementDefinition getElementDefinition(const char *nameString) const;
        // Return the definition of the element identified by the specified
        // 'nameString'. If 'hasElementDefinition(nameString) != true' then an
        // exception is thrown.

    SchemaElementDefinition getElementDefinition(size_t index) const;
        // Return the definition of the element a the specified 'index' in the
        // sequence of elements. If 'index >= numElementDefinitions()' an
        // exception is thrown.

    const ConstantList enumeration() const;
        // Return a 'ConstantList' containing all possible values of the
        // enumeration defined by this type. The behavior of this function is
        // undefined unless 'isEnumerationType() == true'.

    void *userData() const;
        // Return the user data associated with this 'SchemaTypeDefinition'. If
        // no user data has been associated with this 'SchemaTypeDefinition'
        // then return 0. Clients are responsible for synchronizing calls to
        // this function with calls to 'setUserData(void*)' made on not only
        // this 'SchemaTypeDefinition', but also all copies of this
        // 'SchemaTypeDefinition'. Note that 'SchemaTypeDefinition' objects
        // have reference semantics: this function will reflect the last value
        // set on *any* copy of this 'SchemaTypeDefinition'.

    std::ostream& print(std::ostream& stream,
                        int level=0,
                        int spacesPerLevel=4) const;
        // Format this SchemaTypeDefinition to the specified output 'stream' at
        // the (absolute value of) the optionally specified indentation 'level'
        // and return a reference to 'stream'. If 'level' is specified,
        // optionally specify 'spacesPerLevel', the number of spaces per
        // indentation level for this and all of its nested objects. If 'level'
        // is negative, suppress indentation of the first line. If
        // 'spacesPerLevel' is negative, format the entire output on one line,
        // suppressing all but the initial indentation (as governed by
        // 'level').
};

// FREE OPERATORS
std::ostream& operator<<(std::ostream& stream,
                         const SchemaTypeDefinition& typeDef);
    // Write the value of the specified 'typeDef' object to the specified
    // output 'stream' in a single-line format, and return a reference to
    // 'stream'.  If 'stream' is not valid on entry, this operation has no
    // effect.  Note that this human-readable format is not fully specified,
    // can change without notice, and is logically equivalent to:
    //..
    //  print(stream, 0, -1);
    //..

// ============================================================================
//                       FUNCTION DEFINITIONS
// ============================================================================

                       // -----------------------------
                       // class SchemaElementDefinition
                       // -----------------------------


SchemaElementDefinition::SchemaElementDefinition(
    blpapi_SchemaElementDefinition_t *handle)
: d_impl_p(handle)
{
}



SchemaElementDefinition::~SchemaElementDefinition()
{
}


Name SchemaElementDefinition::name() const
{
    return Name(blpapi_SchemaElementDefinition_name(d_impl_p));
}


const char *SchemaElementDefinition::description() const
{
    return blpapi_SchemaElementDefinition_description(d_impl_p);
}


int SchemaElementDefinition::status() const
{
    return blpapi_SchemaElementDefinition_status(d_impl_p);
}


const SchemaTypeDefinition SchemaElementDefinition::typeDefinition() const
{
    return blpapi_SchemaElementDefinition_type(d_impl_p);
}


size_t SchemaElementDefinition::minValues() const
{
    return blpapi_SchemaElementDefinition_minValues(d_impl_p);
}


size_t SchemaElementDefinition::maxValues() const
{
    return blpapi_SchemaElementDefinition_maxValues(d_impl_p);
}


size_t SchemaElementDefinition::numAlternateNames() const
{
    return blpapi_SchemaElementDefinition_numAlternateNames(d_impl_p);
}


Name SchemaElementDefinition::getAlternateName(size_t index) const
{
    blpapi_Name_t *alternateName =
        blpapi_SchemaElementDefinition_getAlternateName(d_impl_p, index);
    if (alternateName == 0) {
        throwOnError(BLPAPI_ERROR_INDEX_OUT_OF_RANGE);
    }
    return alternateName;
}


std::ostream& SchemaElementDefinition::print(
        std::ostream& stream,
        int level,
        int spacesPerLevel) const
{
    blpapi_SchemaElementDefinition_print(d_impl_p,
                                         StreamProxyOstream::writeToStream,
                                         &stream,
                                         level,
                                         spacesPerLevel);
    return stream;
}


std::ostream& operator<<(
        std::ostream& stream,
        const SchemaElementDefinition& element)
{
    element.print(stream, 0, -1);
    return stream;
}


void SchemaElementDefinition::setUserData(void *newUserData)
{
    blpapi_SchemaElementDefinition_setUserData(d_impl_p, newUserData);
}


void *SchemaElementDefinition::userData() const
{
    return blpapi_SchemaElementDefinition_userData(d_impl_p);
}


blpapi_SchemaElementDefinition_t *SchemaElementDefinition::impl() const
{
    return d_impl_p;
}
                       // --------------------------
                       // class SchemaTypeDefinition
                       // --------------------------


SchemaTypeDefinition::SchemaTypeDefinition(
                                         blpapi_SchemaTypeDefinition_t *handle)
: d_impl_p(handle)
{
}


SchemaTypeDefinition::~SchemaTypeDefinition()
{
}


int SchemaTypeDefinition::datatype() const
{
    return blpapi_SchemaTypeDefinition_datatype(d_impl_p);
}


Name SchemaTypeDefinition::name() const
{
    return blpapi_SchemaTypeDefinition_name(d_impl_p);
}


const char *SchemaTypeDefinition::description() const
{
    return blpapi_SchemaTypeDefinition_description(d_impl_p);
}


int SchemaTypeDefinition::status() const
{
    return blpapi_SchemaTypeDefinition_status(d_impl_p);
}


size_t SchemaTypeDefinition::numElementDefinitions() const
{
    return blpapi_SchemaTypeDefinition_numElementDefinitions(d_impl_p);
}


bool SchemaTypeDefinition::hasElementDefinition(const Name& elementName) const
{
    return blpapi_SchemaTypeDefinition_getElementDefinition(
            d_impl_p, 0, elementName.impl()) ? true : false;
}


bool
SchemaTypeDefinition::hasElementDefinition(const char *nameString) const
{
    return blpapi_SchemaTypeDefinition_getElementDefinition(
            d_impl_p, nameString, 0) ? true : false;
}


SchemaElementDefinition
SchemaTypeDefinition::getElementDefinition(const Name& elementName) const
{
    blpapi_SchemaElementDefinition_t *def =
        blpapi_SchemaTypeDefinition_getElementDefinition(d_impl_p,
                                                         0,
                                                         elementName.impl());
    if (def == 0) {
        throwOnError(BLPAPI_ERROR_ITEM_NOT_FOUND);
    }
    return def;
}


SchemaElementDefinition
SchemaTypeDefinition::getElementDefinition(const char *nameString) const
{
    blpapi_SchemaElementDefinition_t *def =
        blpapi_SchemaTypeDefinition_getElementDefinition(d_impl_p,
                                                         nameString,
                                                         0);
    if (def == 0) {
        throwOnError(BLPAPI_ERROR_ITEM_NOT_FOUND);
    }
    return def;
}


SchemaElementDefinition
SchemaTypeDefinition::getElementDefinition(size_t index) const
{
    blpapi_SchemaElementDefinition_t *def =
        blpapi_SchemaTypeDefinition_getElementDefinitionAt(d_impl_p, index);
    if (def == 0) {
        throwOnError(BLPAPI_ERROR_INDEX_OUT_OF_RANGE);
    }
    return def;
}


bool SchemaTypeDefinition::isComplexType() const
{
    return blpapi_SchemaTypeDefinition_isComplexType(d_impl_p) ? true : false;
}


bool SchemaTypeDefinition::isSimpleType() const
{
    return blpapi_SchemaTypeDefinition_isSimpleType(d_impl_p) ? true : false;
}


bool SchemaTypeDefinition::isEnumerationType() const
{
    return blpapi_SchemaTypeDefinition_isEnumerationType(d_impl_p)
        ? true
        : false;
}


std::ostream& SchemaTypeDefinition::print(
        std::ostream& stream,
        int level,
        int spacesPerLevel) const
{
    blpapi_SchemaTypeDefinition_print(d_impl_p,
                                      StreamProxyOstream::writeToStream,
                                      &stream,
                                      level,
                                      spacesPerLevel);
    return stream;
}


std::ostream& operator<<(
        std::ostream& stream,
        const SchemaTypeDefinition& typeDef)
{
    typeDef.print(stream, 0, -1);
    return stream;
}


void SchemaTypeDefinition::setUserData(void *newUserData)
{
    blpapi_SchemaTypeDefinition_setUserData(d_impl_p, newUserData);
}


void *SchemaTypeDefinition::userData() const
{
    return blpapi_SchemaTypeDefinition_userData(d_impl_p);
}


const ConstantList SchemaTypeDefinition::enumeration() const
{
    return blpapi_SchemaTypeDefinition_enumeration(d_impl_p);
}

}  // close namespace blpapi
}  // close namespace BloombergLP

#endif // #ifdef __cplusplus

#endif // #ifndef INCLUDED_BLPAPI_SCHEMA


class ResolutionList {
    // Contains a list of topics that require resolution.
    //
    // Created from topic strings or from SUBSCRIPTION_STARTED
    // messages. This is passed to a resolve() call or resolveAsync()
    // call on a ProviderSession. It is updated and returned by the
    // resolve() call.

    blpapi_ResolutionList_t *d_handle_p;

  public:
    enum Status {
        UNRESOLVED,
        RESOLVED,
        RESOLUTION_FAILURE_BAD_SERVICE,
        RESOLUTION_FAILURE_SERVICE_AUTHORIZATION_FAILED,
        RESOLUTION_FAILURE_BAD_TOPIC,
        RESOLUTION_FAILURE_TOPIC_AUTHORIZATION_FAILED
    };

    // CLASS METHODS
    static Element extractAttributeFromResolutionSuccess(
                                                        Message const& message,
                                                        Name const& attribute);
        // Return the value of the value in the specified 'message'
        // which represents the specified 'attribute'. The 'message'
        // must be a message of type "RESOLUTION_SUCCESS". The
        // 'attribute' should be an attribute that was requested using
        // addAttribute() on the ResolutionList passed to the
        // resolve() or resolveAsync() that caused this
        // RESOLUTION_SUCCESS message. If the 'attribute' is not
        // present an empty Element is returned.

    ResolutionList();
        // Create an empty ResolutionList.

    ResolutionList(const ResolutionList& original);
        // Copy constructor.

    ~ResolutionList();
        // Destroy this ResolutionList.

    // MANIPULATORS

    int add(const char* topic,
            const CorrelationId& correlationId=CorrelationId());
        // Add the specified 'topic' to this list, optionally
        // specifying a 'correlationId'. Returns 0 on success or
        // negative number on failure. After a successful call to
        // add() the status for this entry is UNRESOLVED_TOPIC.

    int add(Message const& subscriptionStartedMessage,
            const CorrelationId& correlationId=CorrelationId());
        // Add the topic contained in the specified
        // 'subscriptionStartedMessage' to this list, optionally
        // specifying a 'correlationId'.  Returns 0 on success or a
        // negative number on failure. After a successful call to add()
        // the status for this entry is UNRESOLVED_TOPIC.

    int addAttribute(const Name& attribute);
        // Add the specified 'attribute' to the list of attributes
        // requested during resolution for each topic in this
        // ResolutionList. Returns 0 on success or a negative number
        // on failure.

    // ACCESSORS

    CorrelationId correlationIdAt(size_t index) const;
        // Returns the CorrelationId of the specified 'index'th entry in
        // this ResolutionList. If 'index' >= size() an exception is
        // thrown.

    const char* topicString(const CorrelationId& correlationId) const;
        // Returns a pointer to the topic of the entry identified by
        // the specified 'correlationId'. If the 'correlationId' does
        // not identify an entry in this ResolutionList then an
        // exception is thrown.

    const char* topicStringAt(size_t index) const;
        // Returns a pointer to the topic of the specified 'index'th
        // entry. If 'index' >= size() an exception is thrown.

    int status(const CorrelationId& correlationId) const;
        // Returns the status of the entry in this ResolutionList
        // identified by the specified 'correlationId'. This may be
        // UNRESOLVED, RESOLVED, RESOLUTION_FAILURE_BAD_SERVICE,
        // RESOLUTION_FAILURE_SERVICE_AUTHORIZATION_FAILED
        // RESOLUTION_FAILURE_BAD_TOPIC,
        // RESOLUTION_FAILURE_TOPIC_AUTHORIZATION_FAILED.  If the
        // 'correlationId' does not identify an entry in this
        // ResolutionList then an exception is thrown.

    int statusAt(size_t index) const;
        // Returns the status of the specified 'index'th entry in this
        // ResolutionList. This may be UNRESOLVED,
        // RESOLVED, RESOLUTION_FAILURE_BAD_SERVICE,
        // RESOLUTION_FAILURE_SERVICE_AUTHORIZATION_FAILED
        // RESOLUTION_FAILURE_BAD_TOPIC,
        // RESOLUTION_FAILURE_TOPIC_AUTHORIZATION_FAILED.  If 'index'
        // > size() an exception is thrown.

    Element const attribute(const Name& attribute,
                            const CorrelationId& correlationId) const;
        // Returns the value for the specified 'attribute' of the
        // entry in this ResolutionList identified by the specified
        // 'correlationId'. The Element returned may be empty if the
        // resolution service cannot provide the attribute. If
        // 'correlationId' does not identify an entry in this
        // ResolutionList or if the status of the entry identified by
        // 'correlationId' is not RESOLVED an exception is thrown.

    Element const attributeAt(const Name& attribute, size_t index) const;
        // Returns the value for the specified 'attribute' of the
        // specified 'index'th entry in this ResolutionList. The
        // Element returned may be empty if the resolution service
        // cannot provide the attribute. If 'index' >= size() or if
        // the status of the 'index'th entry is not RESOLVED an
        // exception is thrown.

    Message const message(const CorrelationId& correlationId) const;
        // Returns the value of the message received during resolution
        // of the topic identified by the specified
        // 'correlationId'. If 'correlationId' does not identify an
        // entry in this ResolutionList or if the status of the entry
        // identify by 'correlationId' is not RESOLVED an exception is
        // thrown.
        //
        // The message returned can be used when creating an instance
        // of Topic.

    Message const messageAt(size_t index) const;
        // Returns the value of the message received during resolution
        // of the specified 'index'th entry in this ResolutionList. If
        // 'index' >= size() or if the status of the 'index'th entry
        // is not RESOLVED an exception is thrown.
        //
        // The message returned can be used when creating an instance
        // of Topic.

    size_t size() const;
        // Returns the number of entries in this list.

    const blpapi_ResolutionList_t* impl() const;

    blpapi_ResolutionList_t* impl();
};

// ============================================================================
//                       FUNCTION DEFINITIONS
// ============================================================================

                            // --------------------
                            // class ResolutionList
                            // --------------------


Element ResolutionList::extractAttributeFromResolutionSuccess(
     Message const& message,
     Name const& attribute)
{
    Element result(blpapi_ResolutionList_extractAttributeFromResolutionSuccess(
                                                            message.impl(),
                                                            attribute.impl()));
    return result;
}


ResolutionList::ResolutionList()
: d_handle_p(blpapi_ResolutionList_create(0))
{
}


ResolutionList::ResolutionList(const ResolutionList& original)
: d_handle_p(blpapi_ResolutionList_create(original.d_handle_p))
{

}


ResolutionList::~ResolutionList()
{
    blpapi_ResolutionList_destroy(d_handle_p);
}


int ResolutionList::add(const char* topic,
                               const CorrelationId& correlationId)
{
    return blpapi_ResolutionList_add(d_handle_p, topic, &correlationId.impl());
}


int ResolutionList::add(Message const& subscriptionStartedMessage,
                               const CorrelationId& correlationId)
{
    return blpapi_ResolutionList_addFromMessage(
        d_handle_p, subscriptionStartedMessage.impl(),
        &correlationId.impl());
}


int ResolutionList::addAttribute(const Name& newAttribute)
{
    return blpapi_ResolutionList_addAttribute(d_handle_p, newAttribute.impl());
}


CorrelationId ResolutionList::correlationIdAt(size_t index) const
{
    blpapi_CorrelationId_t correlationId;
    throwOnError(
        blpapi_ResolutionList_correlationIdAt(d_handle_p,
                                              &correlationId,
                                              index));

    return CorrelationId(correlationId);
}


const char* ResolutionList::topicString(
                                      const CorrelationId& correlationId) const
{
    const char* topic;
    throwOnError(
        blpapi_ResolutionList_topicString(d_handle_p,
                                          &topic,
                                          &correlationId.impl()));

    return topic;
}


const char* ResolutionList::topicStringAt(size_t index) const
{
    const char* topic;
    throwOnError(
        blpapi_ResolutionList_topicStringAt(d_handle_p, &topic, index));

    return topic;
}


int ResolutionList::status(const CorrelationId& correlationId) const
{
    int result;
    throwOnError(
        blpapi_ResolutionList_status(d_handle_p,
                                     &result,
                                     &correlationId.impl()));

    return result;
}


int ResolutionList::statusAt(size_t index) const
{
    int result;
    throwOnError(
        blpapi_ResolutionList_statusAt(d_handle_p, &result, index));

    return result;
}


Element const ResolutionList::attribute(
                                     const Name& attributeName,
                                     const CorrelationId& correlationId) const
{
    blpapi_Element_t* element;
    throwOnError(
        blpapi_ResolutionList_attribute(d_handle_p,
                                        &element,
                                        attributeName.impl(),
                                        &correlationId.impl()));
    return Element(element);
}


Element const ResolutionList::attributeAt(const Name& attributeName,
                                          size_t index) const
{
    blpapi_Element_t* element;
    throwOnError(
        blpapi_ResolutionList_attributeAt(d_handle_p,
                                          &element,
                                          attributeName.impl(),
                                          index));
    return Element(element);
}


Message const ResolutionList::message(const CorrelationId& correlationId) const
{
    blpapi_Message_t* messageByCid;
    throwOnError(
        blpapi_ResolutionList_message(d_handle_p,
                                      &messageByCid,
                                      &correlationId.impl()));

    bool makeMessageCopyable = true;
    BLPAPI_CALL_MESSAGE_ADDREF(messageByCid);
    return Message(messageByCid, makeMessageCopyable);
}


Message const ResolutionList::messageAt(size_t index) const
{
    blpapi_Message_t* messageByIndex;
    throwOnError(
        blpapi_ResolutionList_messageAt(d_handle_p, &messageByIndex, index));

    bool makeMessageCopyable = true;
    BLPAPI_CALL_MESSAGE_ADDREF(messageByIndex);
    return Message(messageByIndex, makeMessageCopyable);
}


size_t ResolutionList::size() const
{
    return blpapi_ResolutionList_size(d_handle_p);
}


const blpapi_ResolutionList_t* ResolutionList::impl() const
{
    return d_handle_p;
}


blpapi_ResolutionList_t* ResolutionList::impl()
{
    return d_handle_p;
}

}  // close namespace blpapi
}  // close namespace BloombergLP

#endif // #ifdef __cplusplus
#endif // #ifndef INCLUDED_BLPAPI_RESOLUTIONLIST



class ProviderSession;
                         // ==========================
                         // class ProviderEventHandler
                         // ==========================

class ProviderEventHandler {
  public:
    virtual ~ProviderEventHandler() {}

    virtual bool processEvent(const Event& event,
                              ProviderSession *session) = 0;
};

                      // ================================
                      // class ServiceRegistrationOptions
                      // ================================

class ServiceRegistrationOptions {
    // Contains the options which the user can specify when registering
    // a service
    //
    // To use non-default options to registerService, create a
    // ServiceRegistrationOptions instance and set the required options and
    // then supply it when using the registerService interface.

    blpapi_ServiceRegistrationOptions_t *d_handle_p;
  public:

    enum ServiceRegistrationPriority {
        PRIORITY_LOW    = BLPAPI_SERVICEREGISTRATIONOPTIONS_PRIORITY_LOW,
        PRIORITY_MEDIUM = BLPAPI_SERVICEREGISTRATIONOPTIONS_PRIORITY_MEDIUM,
        PRIORITY_HIGH   = BLPAPI_SERVICEREGISTRATIONOPTIONS_PRIORITY_HIGH
    };

    enum RegistrationParts {
        // constants for specifying which part(s) of a service should be
        // registered

        PART_PUBLISHING = BLPAPI_REGISTRATIONPARTS_PUBLISHING,
            // register to receive subscribe and unsubscribe messages

        PART_OPERATIONS = BLPAPI_REGISTRATIONPARTS_OPERATIONS,
            // register to receive the request types corresponding to each
            // "operation" defined in the service metadata

        PART_SUBSCRIBER_RESOLUTION
                     = BLPAPI_REGISTRATIONPARTS_SUBSCRIBER_RESOLUTION,
            // register to receive resolution requests (with message type
            // 'PermissionRequest') from subscribers

        PART_PUBLISHER_RESOLUTION
                     = BLPAPI_REGISTRATIONPARTS_PUBLISHER_RESOLUTION,
            // register to receive resolution requests (with message type
            // 'PermissionRequest') from publishers (via
            // 'ProviderSession::createTopics')

        PART_DEFAULT    = BLPAPI_REGISTRATIONPARTS_DEFAULT
            // register the parts of the service implied by options
            // specified in the service metadata
    };

    ServiceRegistrationOptions();
        // Create ServiceRegistrationOptions with default options.

    ServiceRegistrationOptions(const ServiceRegistrationOptions& original);
        // Copy Constructor

    ~ServiceRegistrationOptions();
        // Destroy this ServiceRegistrationOptions.

    // MANIUPLATORS

    ServiceRegistrationOptions& operator=(
                                        const ServiceRegistrationOptions& rhs);
        // Assign to this object the value of the specified 'rhs' object.

    void setGroupId(const char *groupId, unsigned int groupIdLength);
        // Set the Group ID for the service to be registered to the specified
        // char array beginning at groupId with size groupIdLength.
        // If groupIdLength > MAX_GROUP_ID_SIZE (=64) only the first
        // MAX_GROUP_ID_SIZE chars are considered as Group Id.

    int setServicePriority(int priority);
        // Set the priority with which a service will be registered to
        // the non-negative value specified in priority.
        // This call returns with a non-zero value indicating error when
        // a negative priority is specified.
        // Any non-negative priority value, other than the one
        // pre-defined in ServiceRegistrationPriority can be used.
        // Default value is PRIORITY_HIGH

    void setPartsToRegister(int parts);
        // Set the parts of the service to be registered to the specified
        // 'parts', which must be a bitwise-or of the options provided in
        // 'RegistrationParts', above.  This option defaults to
        // 'RegistrationParts::PARTS_DEFAULT'.

    void addActiveSubServiceCodeRange(int begin, int end, int priority);
        // Advertise the service to be registered to receive, with the
        // specified 'priority', subscriptions that the resolver has mapped to
        // a service code between the specified 'begin' and the specified 'end'
        // values, inclusive. The behavior of this function is undefined unless
        // '0 <= begin <= end < (1 << 24)', and 'priority' is non-negative.

    void removeAllActiveSubServiceCodeRanges();
        // Remove all previously added sub-service code ranges.


    // ACCESSORS
    blpapi_ServiceRegistrationOptions_t *handle() const;

    int getGroupId(char *groupId, int *groupIdLength) const;
        // Copy the previously specified groupId at the memory location
        // specified by groupId and the set the size of the groupId returned at
        // groupIdLength. A Non-zero value indicates an error.
        // The behavior is undefined if there is not enough space to copy the
        // group Id to the specified buffer.
        // Note that the groupId is not null terminated and buffer for groupId
        // needs to be at most MAX_GROUP_ID_SIZE.

    int getServicePriority() const;
        // Return the value of the service priority in this
        // ServiceRegistrationOptions instance.

    int getPartsToRegister() const;
        // Return the parts of the service to be registered.  See
        // 'RegistrationParts', above for additional details.
};
                         // =====================
                         // class ProviderSession
                         // =====================

class ProviderSession : public AbstractSession {
    // This class provides a session that can be used for providing services.
    //
    // It inherits from AbstractSession. In addition to the AbstractSession
    // functionality a ProviderSession provides the following
    // functions to applications.
    //
    // A provider can register to provide services using
    // 'ProviderSession::registerService*'. Before registering to provide a
    // service the provider must have established its identity. Then
    // the provider can create topics and publish events on topics. It also
    // can get requests from the event queue and send back responses.
    //
    // After users have registered a service they will start receiving
    // subscription requests ('TopicSubscribed' message in 'TOPIC_STATUS') for
    // topics which belong to the service. If the resolver has specified
    // 'subServiceCode' for topics in 'PermissionResponse', then only providers
    // who have activated the 'subServiceCode' will get the subscription
    // request. Where multiple providers have registered the same service and
    // sub-service code (if any), the provider that registered the highest
    // priority for the sub-service code will receive subscription requests; if
    // multiple providers have registered the same sub-service code with the
    // same priority (or the resolver did not set a sub-service code for the
    // subscription), the subscription request will be routed to one of the
    // providers with the highest service priority.

    blpapi_ProviderSession_t    *d_handle_p;
    ProviderEventHandler        *d_eventHandler_p;

  private:
    friend void providerEventHandlerProxy(blpapi_Event_t           *event,
                                          blpapi_ProviderSession_t *session,
                                          void                     *userData);

    void dispatchEvent(const Event& event);

  private:
    // NOT IMPLEMENTED
    ProviderSession(const ProviderSession&);
    ProviderSession& operator=(const ProviderSession&);

  public:
    enum ResolveMode {
      AUTO_REGISTER_SERVICES = BLPAPI_RESOLVEMODE_AUTO_REGISTER_SERVICES,
              // Try to register services found in ResolutionList if necessary.
      DONT_REGISTER_SERVICES = BLPAPI_RESOLVEMODE_DONT_REGISTER_SERVICES
              // Fail to resolve a topic if the service has not already been
              // registered.
    };

    ProviderSession(const SessionOptions&  options = SessionOptions(),
                    ProviderEventHandler  *eventHandler=0,
                    EventDispatcher       *eventDispatcher=0);
        // Construct a Session using the optionally specified
        // 'options', the optionally specified 'eventHandler' and the
        // optionally specified 'eventDispatcher'.
        //
        // See the SessionOptions documentation for details on what
        // can be specified in the 'options'.
        //
        // If 'eventHandler' is not 0 then this Session will operation
        // in asynchronous mode, otherwise the Session will operate in
        // synchronous mode.
        //
        // If 'eventDispatcher' is 0 then the Session will create a
        // default EventDispatcher for this Session which will use a
        // single thread for dispatching events. For more control over
        // event dispatching a specific instance of EventDispatcher
        // can be supplied. This can be used to share a single
        // EventDispatcher amongst multiple Session objects.
        //
        // If an 'eventDispatcher' is supplied which uses more than
        // one thread the Session will ensure that events which should
        // be ordered are passed to callbacks in a correct order. For
        // example, partial response to a request or updates to a
        // single subscription.
        //
        // If 'eventHandler' is 0 and the 'eventDispatcher' is not
        // 0 an exception is thrown.
        //
        // Each EventDispatcher uses its own thread or pool of
        // threads so if you want to ensure that a session which
        // receives very large messages and takes a long time to
        // process them does not delay a session that receives small
        // messages and processes each one very quickly then give each
        // one a separate EventDispatcher.

    explicit ProviderSession(blpapi_ProviderSession_t *handle);

    virtual ~ProviderSession();
        // Destructor.

    // MANIPULATORS
    virtual bool start();
        // See start().

    virtual bool startAsync();
        // See startAsync().

    virtual void stop();
        // See stop().

    virtual void stopAsync();
        // See stopAsync().

    virtual Event nextEvent(int timeout=0);
        // See nextEvent().

    virtual int tryNextEvent(Event *event);
        // See tryNextEvent()

    bool registerService(
                        const char                        *serviceName,
                        const Identity&                    providerIdentity
                            = Identity(),
                        const ServiceRegistrationOptions&  registrationOptions
                            = ServiceRegistrationOptions());
        // Attempt to register the service identified by the specified
        // 'serviceName' and block until the service is either registered
        // successfully or has failed to be registered. The optionally
        // specified 'providerIdentity' is used to verify permissions
        // to provide the service being registered. The optionally
        // specified 'registrationOptions' is used to specify the
        // group ID and service priority of the service being registered.
        // Returns 'true' if the service is registered successfully and
        // 'false' if the service cannot be registered successfully.
        //
        // The 'serviceName' must be a full qualified service name. That is it
        // must be of the form '//<namespace>/<local-name>'.
        //
        // This function does not return until a SERVICE_STATUS event has been
        // generated. Note that if the session was created in asynchronous
        // mode, the event may be processed before the function returns.

    void activateSubServiceCodeRange(const char *serviceName,
                                     int         begin,
                                     int         end,
                                     int         priority);
        // Register to receive, with the specified 'priority', subscriptions
        // for the specified 'service' that the resolver has mapped to a
        // service code between the specified 'begin' and the specified 'end'
        // values, inclusive. The behavior of this function is undefined unless
        // 'service' has already been successfully registered,
        // '0 <= begin <= end < (1 << 24)', and 'priority' is non-negative.

    void deactivateSubServiceCodeRange(const char *serviceName,
                                       int         begin,
                                       int         end);
        // De-register to receive subscriptions for the specified 'service'
        // that the resolver has mapped to a service code between the specified
        // 'begin' and the specified 'end' values, inclusive. The behavior of
        // this function is undefined unless 'service' has already been
        // successfully registered and '0 <= begin <= end < (1 << 24)'.

    CorrelationId registerServiceAsync(
                        const char                        *serviceName,
                        const Identity&                    providerIdentity
                            = Identity(),
                        const CorrelationId&               correlationId
                            = CorrelationId(),
                        const ServiceRegistrationOptions&  registrationOptions
                            = ServiceRegistrationOptions());
        // Begin the process of registering the service identified by
        // the specified 'serviceName' and return immediately. The optionally
        // specified 'providerIdentity' is used to verify permissions
        // to provide the service being registered. The optionally
        // specified 'correlationId' is used to track 'Event' objects generated
        // as a result of this call. Return the actual 'CorrelationId' object
        // that will identify 'Event' objects. The optionally specified
        // 'registrationOptions' is used to specify the group ID and service
        // priority of the service being registered.
        //
        // The 'serviceName' must be a full qualified service name. That is it
        // must be of the form '//<namespace>/<local-name>'.
        //
        // The application must monitor events for a SERVICE_STATUS
        // Event which will be generated once the service has been
        // successfully registered or registration has failed.

    bool deregisterService(const char *serviceName);
        // Deregister the service, including all registered parts, identified
        // by the specified 'serviceName'. The identity in the service
        // registration is reused to verify permissions for deregistration. If
        // the service is not registered nor in pending registration, return
        // false; return true otherwise. If the service is in pending
        // registration, cancel the pending registration. If the service is
        // registered, send a deregistration request; generate TOPIC_STATUS
        // events containing a TopicUnsubscribed message for each subscribed
        // topic, a TopicDeactivated message for each active topic and a
        // TopicDeleted for each created topic; generate REQUEST_STATUS events
        // containing a RequestFailure message for each pending incoming
        // request; and generate a SERVICE_STATUS Event containing a
        // ServiceDeregistered message. All published events on topics created
        // on this service will be ignored after this method returns.

    void resolve(ResolutionList *resolutionList,
                 ResolveMode     resolveMode=DONT_REGISTER_SERVICES,
                 Identity        providerIdentity=Identity());
        // Resolves the topics in the specified 'resolutionList' and
        // updates the 'resolutionList' with the results of the
        // resolution process. If the specified 'resolveMode' is
        // DONT_REGISTER_SERVICES (the default) then all the services
        // referenced in the topics in the 'resolutionList' must
        // already have been registered using registerService(). If
        // 'resolveMode' is AUTO_REGISTER_SERVICES then the specified
        // 'providerIdentity' should be supplied and ProviderSession
        // will automatically attempt to register any services
        // reference in the topics in the 'resolutionList' that have
        // not already been registered. Once resolveSync() returns
        // each entry in the 'resolutionList' will have been updated
        // with a new status.
        //
        // Before resolveSync() returns one or more RESOLUTION_STATUS
        // events and, if 'resolveMode' is AUTO_REGISTER_SERVICES,
        // zero or more SERVICE_STATUS events are generated. If this
        // is an asynchronous ProviderSession then these Events may be
        // processed by the registered EventHandler before resolve()
        // has returned.

    void resolveAsync(const ResolutionList& resolutionList,
                      ResolveMode           resolveMode=DONT_REGISTER_SERVICES,
                      const Identity&       providerIdentity=Identity());
        // Begin the resolution of the topics in the specified
        // 'resolutionList'. If the specified 'resolveMode' is
        // DONT_REGISTER_SERVICES (the default) then all the services
        // referenced in the topics in the 'resolutionList' must
        // already have been registered using registerService(). If
        // 'resolveMode' is AUTO_REGISTER_SERVICES then the specified
        // 'providerIdentity' should be supplied and ProviderSession
        // will automatically attempt to register any services
        // reference in the topics in the 'resolutionList' that have
        // not already been registered.
        //
        // One or more RESOLUTION_STATUS events will be delivered with
        // the results of the resolution. These events may be
        // generated before or after resolve() returns. If
        // AUTO_REGISTER_SERVICES is specified SERVICE_STATUS events
        // may also be generated before or after resolve() returns.

    Topic createTopic(const Message& message);
        // DEPRECATED
        // Create a topic from the specified 'message', which must be of type
        // 'ResolutionSuccess'. This method is deprecated; use 'createTopics'
        // or 'createTopicsAsync', which handle resolution automatically.

    Topic getTopic(const Message& message);
        // Finds a previously created Topic object based on the specified
        // 'message'. The 'message' must be one of the following
        // types: TopicCreated, TopicActivated, TopicDeactivated,
        // TopicSubscribed, TopicUnsubscribed, TopicRecap.
        // If the 'message' is not valid then invoking isValid() on the
        // returned Topic will return false.

    Topic createServiceStatusTopic(const Service& service);
        // Creates a Service Status Topic which is to be used to provide
        // service status. On success invoking isValid() on the returned Topic
        // will return false.

    void publish(const Event& event);
        // Publish messages contained in the specified 'event'.

    void sendResponse(const Event& event, bool isPartialResponse = false);
        // Send the response event for previously received request

    void createTopics(TopicList   *topicList,
                      ResolveMode  resolveMode=DONT_REGISTER_SERVICES,
                      Identity     providerIdentity=Identity());
        // Creates the topics in the specified 'topicList' and
        // updates the 'topicList' with the results of the
        // creation process. If service needs to be registered,
        // 'providerIdentity' should be supplied.
        // Once a call to this function returns,
        // each entry in the 'topicList' will have been updated
        // with a new topic creation status.
        //
        // Before createTopics() returns one or more RESOLUTION_STATUS
        // events, zero or more SERVICE_STATUS events and one or more
        // TOPIC_STATUS events are generated.
        // If this is an asynchronous ProviderSession then these
        // Events may be processed by the registered EventHandler
        // before createTopics() has returned.

    void createTopicsAsync(const TopicList& topicList,
                           ResolveMode      resolveMode=DONT_REGISTER_SERVICES,
                           const Identity&  providerIdentity=Identity());
        // Creates the topics in the specified 'topicList' and
        // updates the 'topicList' with the results of the
        // creation process. If service needs to be registered,
        // 'providerIdentity' should be supplied.
        //
        // One or more RESOLUTION_STATUS events, zero or more
        // SERVICE_STATUS events and one or more TOPIC_STATUS
        // events are generated.
        // If this is an asynchronous ProviderSession then these
        // Events may be processed by the registered EventHandler
        // before createTopics() has returned.

    void deleteTopic(const Topic& topic);
        // Remove one reference from the specified 'topic'. If this function
        // has been called the same number of times that 'topic' was created
        // by 'createTopics', then 'topic' is deleted: a 'TopicDeleted'
        // message is delivered, preceded by 'TopicUnsubscribed' and
        // 'TopicDeactivated' if 'topic' was subscribed. (See "Topic
        // Life Cycle", above, for additional details.) The behavior of this
        // function is undefined if 'topic' has already been deleted the same
        // number of times that it has been created. Further, the behavior is
        // undefined if a provider attempts to publish a message on a deleted
        // topic.

    void deleteTopics(const std::vector<Topic>& topics);
        // Delete each topic in the specified 'topics'. See
        // 'deleteTopic(const Topic&)' for additional details.

    void deleteTopics(const Topic* topics,
                      size_t       numTopics);
        // Delete the first 'numTopics' elements of the specified 'topics'
        // array. See 'deleteTopic(const Topic&)' for additional details.

    blpapi_ProviderSession_t *handle() const;
        // Return the handle to this provider session
};

//=============================================================================
//                            FUNCTION DEFINITIONS
//=============================================================================

                            // ---------------------
                            // class ProviderSession
                            // ---------------------


ProviderSession::ProviderSession(const SessionOptions&  parameters,
                                 ProviderEventHandler  *handler,
                                 EventDispatcher       *dispatcher)
    : d_eventHandler_p(handler)
{
    d_handle_p = blpapi_ProviderSession_create(parameters.handle(),
        handler ? (blpapi_ProviderEventHandler_t)providerEventHandlerProxy : 0,
        dispatcher ? dispatcher.impl() : 0,
        this);
    initAbstractSessionHandle(
        blpapi_ProviderSession_getAbstractSession(d_handle_p));
}


ProviderSession::ProviderSession(blpapi_ProviderSession_t *newHandle)
    : d_handle_p(newHandle)
{
    initAbstractSessionHandle(
        blpapi_ProviderSession_getAbstractSession(d_handle_p));
}


ProviderSession::~ProviderSession()
{
    blpapi_ProviderSession_destroy(d_handle_p);
}


bool ProviderSession::start()
{
    return blpapi_ProviderSession_start(d_handle_p) ? false : true;
}


bool ProviderSession::startAsync()
{
    return blpapi_ProviderSession_startAsync(d_handle_p) ? false : true;
}


void  ProviderSession::stop()
{
    blpapi_ProviderSession_stop(d_handle_p);
}


 void  ProviderSession::stopAsync()
{
    blpapi_ProviderSession_stopAsync(d_handle_p);
}


Event ProviderSession::nextEvent(int timeout)
{
    blpapi_Event_t *event;
    throwOnError(
        blpapi_ProviderSession_nextEvent(d_handle_p, &event, timeout));
    return Event(event);
}


int ProviderSession::tryNextEvent(Event *event)
{
    blpapi_Event_t *impl;
    int ret = blpapi_ProviderSession_tryNextEvent(
                            d_handle_p, &impl);
    if(0 == ret) {
        *event = Event(impl);
    }
    return ret;
}


bool ProviderSession::registerService(
                        const char                        *serviceName,
                        const Identity&                    identity,
                        const ServiceRegistrationOptions&  registrationOptions)
{
    return blpapi_ProviderSession_registerService(
               d_handle_p,
               serviceName,
               identity.handle(),
               registrationOptions.handle()) ? false : true;
}

void ProviderSession::activateSubServiceCodeRange(const char *serviceName,
                                     int begin, int end, int priority)
{
    throwOnError(
        BLPAPI_CALL_PROVIDERSESSION_ACTIVATESUBSERVICECODERANGE(d_handle_p,
                                                                serviceName,
                                                                begin,
                                                                end,
                                                                priority));
}


void ProviderSession::deactivateSubServiceCodeRange(const char *serviceName,
                                                    int begin, int end)
{
    throwOnError(
        BLPAPI_CALL_PROVIDERSESSION_DEACTIVATESUBSERVICECODERANGE(d_handle_p,
                                                                  serviceName,
                                                                  begin,
                                                                  end));
}


CorrelationId ProviderSession::registerServiceAsync(
                        const char                        *serviceName,
                        const Identity&                    identity,
                        const CorrelationId&               correlationId,
                        const ServiceRegistrationOptions&  registrationOptions)
{
    blpapi_CorrelationId_t retv = correlationId.impl();
    throwOnError(
        blpapi_ProviderSession_registerServiceAsync(
            d_handle_p, serviceName, identity.handle(),
            &retv, registrationOptions.handle())
        );

    return retv;
}


bool ProviderSession::deregisterService(const char *serviceName)
{
    return BLPAPI_CALL_PROVIDERSESSION_DEREGISTERSERVICE(
            d_handle_p,
            serviceName) == 0 ? true : false;
}


void ProviderSession::resolve(ResolutionList* resolutionList,
                              ResolveMode resolveMode,
                              Identity identity)
{
    throwOnError(blpapi_ProviderSession_resolve(
                                    d_handle_p,
                                    resolutionList.impl(),
                                    resolveMode,
                                    identity.handle()));
    return;
}


void ProviderSession::resolveAsync(const ResolutionList& resolutionList,
                                   ResolveMode resolveMode,
                                   const Identity& identity)
{
    throwOnError(blpapi_ProviderSession_resolveAsync(
                                    d_handle_p,
                                    resolutionList.impl(),
                                    resolveMode,
                                    identity.handle()));
    return;
}


Topic ProviderSession::createTopic(const Message& message)
{
    blpapi_Topic_t* topic;
    throwOnError(
        blpapi_ProviderSession_createTopic(
        d_handle_p, message.impl(), &topic));

    return Topic(topic);
}


Topic ProviderSession::getTopic(const Message& message)
{
    blpapi_Topic_t* topic;
    throwOnError(
        blpapi_ProviderSession_getTopic(
        d_handle_p, message.impl(), &topic));

    return Topic(topic);
}


Topic ProviderSession::createServiceStatusTopic(const Service& service)
{
    blpapi_Topic_t* topic;
    throwOnError(
        blpapi_ProviderSession_createServiceStatusTopic(
        d_handle_p, service.handle(), &topic));

    return Topic(topic);
}


void ProviderSession::createTopics(TopicList* topicList,
                                   ResolveMode resolveMode,
                                   Identity identity)
{
    throwOnError(blpapi_ProviderSession_createTopics(
                                    d_handle_p,
                                    topicList.impl(),
                                    resolveMode,
                                    identity.handle()));
    return;
}


void ProviderSession::createTopicsAsync(const TopicList& topicList,
                                        ResolveMode resolveMode,
                                        const Identity& identity)
{
    throwOnError(blpapi_ProviderSession_createTopicsAsync(
                                    d_handle_p,
                                    topicList.impl(),
                                    resolveMode,
                                    identity.handle()));
    return;
}


void ProviderSession::deleteTopic(const Topic& topic)
{
    const blpapi_Topic_t* topicImpl = topic.impl();
    throwOnError(BLPAPI_CALL_PROVIDERSESSION_DELETETOPICS(
                                    d_handle_p,
                                    &topicImpl,
                                    1));
}


void ProviderSession::deleteTopics(const std::vector<Topic>& topics)
{
    if (topics.size() == 0) {
        return;
    }
    std::vector<const blpapi_Topic_t *> topicImplList;
    topicImplList.reserve(topics.size());
    for (std::vector<Topic>::const_iterator it = topics.begin();
         it != topics.end();
         ++it) {
        topicImplList.push_back(it.impl());
    }
    throwOnError(BLPAPI_CALL_PROVIDERSESSION_DELETETOPICS(
            d_handle_p,
            &topicImplList[0],
            topicImplList.size()));
}


void ProviderSession::deleteTopics(const Topic* topics,
                                   size_t       numTopics)
{
    if (numTopics == 0) {
        return;
    }
    std::vector<const blpapi_Topic_t *> topicImplList;
    topicImplList.reserve(numTopics);
    for (size_t i = 0; i < numTopics; ++i) {
        topicImplList.push_back(topics[i].impl());
    }
    throwOnError(BLPAPI_CALL_PROVIDERSESSION_DELETETOPICS(
            d_handle_p,
            &topicImplList[0],
            topicImplList.size()));
}


void ProviderSession::publish(const Event& event)
{
    throwOnError(
        blpapi_ProviderSession_publish(d_handle_p, event.impl()));
    return;
}


void ProviderSession::sendResponse(
    const Event& event,
    bool isPartialResponse)
{
    throwOnError(
        blpapi_ProviderSession_sendResponse(
            d_handle_p, event.impl(), isPartialResponse));
    return;
}


blpapi_ProviderSession_t* ProviderSession::handle() const
{
    return d_handle_p;
}


void ProviderSession::dispatchEvent(const Event& event)
{
    d_eventHandler_p.processEvent(event, this);
}
                      // --------------------------------
                      // class ServiceRegistrationOptions
                      // --------------------------------


ServiceRegistrationOptions::ServiceRegistrationOptions()
{
    d_handle_p = blpapi_ServiceRegistrationOptions_create();
}


ServiceRegistrationOptions::ServiceRegistrationOptions(
                                    const ServiceRegistrationOptions& original)
{
    d_handle_p = blpapi_ServiceRegistrationOptions_duplicate(
        original.handle());
}


ServiceRegistrationOptions::~ServiceRegistrationOptions()
{
    blpapi_ServiceRegistrationOptions_destroy(d_handle_p);
}


ServiceRegistrationOptions&  ServiceRegistrationOptions::operator=(
                                         const ServiceRegistrationOptions& rhs)
{
    blpapi_ServiceRegistrationOptions_copy(this.handle(), rhs.handle());
    return *this;
}

// SUBSERVICE CODES

void ServiceRegistrationOptions::addActiveSubServiceCodeRange(int begin,
                                                              int end,
                                                              int priority)
{
    throwOnError(
        BLPAPI_CALL_SERVICEREGISTRATIONOPTIONS_ADDACTIVATESUBSERVICECODERANGE(
            d_handle_p,
            begin,
            end,
            priority));
}


void ServiceRegistrationOptions::removeAllActiveSubServiceCodeRanges()
{
    BLPAPI_CALL_SERVICEREGISTRATIONOPTIONS_REMOVEALLACTIVESUBSERVICECODERANGES(
        d_handle_p);
}


void ServiceRegistrationOptions::setGroupId(const char* groupId,
                                            unsigned int groupIdLength)
{
    blpapi_ServiceRegistrationOptions_setGroupId(d_handle_p, groupId,
                                                 groupIdLength);
}


int ServiceRegistrationOptions::setServicePriority(int priority)
{
    return blpapi_ServiceRegistrationOptions_setServicePriority(
            d_handle_p, priority);
}


void ServiceRegistrationOptions::setPartsToRegister(int parts)
{
    BLPAPI_CALL_SERVICEREGISTRATIONOPTIONS_SETPARTSTOREGISTER(d_handle_p,
                                                              parts);
}


int ServiceRegistrationOptions::getGroupId(char *groupIdBuffer,
                                           int  *groupIdLength) const
{
    return blpapi_ServiceRegistrationOptions_getGroupId(d_handle_p,
                                                        groupIdBuffer,
                                                        groupIdLength);
}


int ServiceRegistrationOptions::getServicePriority() const
{
    return blpapi_ServiceRegistrationOptions_getServicePriority(d_handle_p);
}


int ServiceRegistrationOptions::getPartsToRegister() const
{
    return BLPAPI_CALL_SERVICEREGISTRATIONOPTIONS_GETPARTSTOREGISTER(
                                                                   d_handle_p);
}


blpapi_ServiceRegistrationOptions_t* ServiceRegistrationOptions::handle() const
{
    return d_handle_p;
}

                            // --------------------------
                            // class ProviderEventHandler
                            // --------------------------

static void providerEventHandlerProxy(blpapi_Event_t           *event,
                                      blpapi_ProviderSession_t *,
                                      void                     *userData)
{
    reinterpret_cast<ProviderSession*>(userData).dispatchEvent(Event(event));
}

}  // close namespace blpapi
}  // close namespace BloombergLP


#endif // #ifdef __cplusplus
#endif // #ifndef INCLUDED_BLPAPI_PROVIDERSESSION



                                 // ==========

class Name {
    // 'Name' represents a string in a form which is efficient for hashing and
    // comparison, thus providing efficient lookup when used as a key in either
    // ordered or hash-based containers.
    //
    // 'Name' objects are used to identify and access the classes which define
    // a schema - 'SchemaTypeDefinition', 'SchemaElementDefinition',
    // 'Constant', and 'ConstantList'.  They are also used to access the values
    // in 'Element' objects and 'Message' objects.
    //
    // The 'Name' class is an efficient substitute for a string when used as a
    // key, providing constant-time hashing and comparision.  Two 'Name'
    // objects constructed from strings for which 'strcmp()' would return 0
    // will always compare equal.
    //
    // The ordering of 'Name' objects (as defined by 'operator<(Name,Name)') is
    // consistent during a particular instance of a single application.
    // However, the ordering is not lexical and is not necessarily consistent
    // with the ordering of the same 'Name' objects in any other process.
    //
    // Where possible, 'Name' objects should be initialized once and then
    // reused.  Creating a 'Name' object from a 'const char*' involves a search
    // in a container requiring multiple string comparison operations.
    //
    // Note: Each 'Name' instance refers to an entry in a global static table.
    // 'Name' instances for identical strings will refer to the same data.
    // There is no provision for removing entries from the static table so
    // 'Name' objects should be used only when the set of input strings is
    // bounded.
    //
    // For example, creating a 'Name' for every possible field name and type in
    // a data model is reasonable (in fact, the API will do this whenever it
    // receives schema information).  Converting sequence numbers from incoming
    // messages to strings and creating a 'Name' from each one of those
    // strings, however, will cause the static table to grow in an unbounded
    // manner, and is tantamount to a memory leak.

    blpapi_Name_t *d_impl_p;

  public:
    // CLASS METHODS

    static Name findName(const char *nameString);
        // If a 'Name' already exists which matches the specified
        // 'nameString', then return a copy of that 'Name'; otherwise return a
        // 'Name' which will compare equal to a 'Name' created using the
        // default constructor. The behavior is undefined if 'nameString' does
        // not point to a null-terminated string.

    static bool hasName(const char *nameString);
        // Return 'true' if a 'Name' has been created which matches the
        // specified 'nameString'; otherwise return 'false'. The behavior is
        // undefined if 'nameString' does not point to a null-terminated
        // string.

    Name();
        // Construct an uninitialized 'Name'. An uninitialized 'Name' can be
        // assigned to, destroyed, or tested for equality. The behavior for all
        // other operations is undefined.

    Name(blpapi_Name_t *handle);

    Name(const Name& original);
        // Create a 'Name' object having the same value as the specified
        // 'original'.

    explicit Name(const char* nameString);
        // Construct a 'Name' from the specified 'nameString'. The behavior is
        // undefined unless 'nameString' is a null-terminated string. Note that
        // any null-terminated string can be specified, including an empty
        // string. Note also that constructing a 'Name' from a 'const char *'
        // is a relatively expensive operation. If a 'Name' will be used
        // repeatedly it is preferable to create it once and re-use (or copy)
        // the object.

    ~Name();
        // Destroy this object.

    // MANIPULATORS

    Name& operator=(const Name& rhs);
        // Assign to this object the value of the specified 'rhs', and return a
        // reference to this modifiable object.

    // ACCESSORS

    const char *string() const;
        // Return a pointer to the null-terminated string value of this 'Name'.
        // The pointer returned will be valid at least until main() exits.

    size_t length() const;
        // Return the length of the string value of this 'Name',
        // (excluding a terminating null). Note that 'name.length()' is
        // logically equivalent to 'strlen(name.string())', however the former
        // is potentially more efficient.

    size_t hash() const;
        // Return an integral value such that for two 'Name' objects 'a' and
        // 'b', if 'a == b' then 'a.hash() == b.hash()', and if 'a != b' then
        // it is unlikely that 'a.hash() == b.hash()'.

    blpapi_Name_t* impl() const;
};

// FREE OPERATORS
bool operator==(const Name& lhs, const Name& rhs);
    // Return true if the specified 'lhs' and 'rhs' name objects have
    // the same value, and false otherwise. Two 'Name' objects 'a' and 'b' have
    // the same value if and only if 'strcmp(a.string(), b.string()) == 0'.

bool operator!=(const Name& lhs, const Name& rhs);
    // Return false if the specified 'lhs' and 'rhs' name objects have the same
    // value, and true otherwise. Two 'Name' objects 'a' and 'b' have the same
    // value if and only if 'strcmp(a.string(), b.string()) == 0'.  Note that
    // 'lhs != rhs' is equivalent to '!(lhs==rhs)'.

bool operator==(const Name& lhs, const char *rhs);
    // Return true if the specified 'lhs' and 'rhs' have the same value, and
    // false otherwise. A 'Name' object 'a' and a null-terminated string 'b'
    // have the same value if and only if 'strcmp(a.string(), b) == 0'. The
    // behavior is undefined unless 'rhs' is a null-terminated string.

bool operator!=(const Name& lhs, const char *rhs);
    // Return false if the specified 'lhs' and 'rhs' have the same value, and
    // true otherwise. A 'Name' object 'a' and a null-terminated string 'b'
    // have the same value if and only if 'strcmp(a.string(), b) == 0'. The
    // behavior is undefined unless 'rhs' is a null-terminated string.

bool operator==(const char *lhs, const Name& rhs);
    // Return true if the specified 'lhs' and 'rhs' have the same value, and
    // false otherwise. A 'Name' object 'a' and a null-terminated string 'b'
    // have the same value if and only if 'strcmp(a.string(), b) == 0'. The
    // behavior is undefined unless 'lhs' is a null-terminated string.

bool operator!=(const char *lhs, const Name& rhs);
    // Return false if the specified 'lhs' and 'rhs' have the same value, and
    // true otherwise. A 'Name' object 'a' and a null-terminated string 'b'
    // have the same value if and only if 'strcmp(a.string(), b) == 0'. The
    // behavior is undefined unless 'lhs' is a null-terminated string.

bool operator<(const Name& lhs, const Name& rhs);
    // Return 'true' if the specified 'lhs' is ordered before the specified
    // 'rhs', and 'false' otherwise. The ordering used is stable within the
    // lifetime of a single process and is compatible with
    // 'operator==(const Name&, const Name&)', however this order is neither
    // guaranteed to be consistent across different processes (including
    // repeated runs of the same process), nor guaranteed to be lexical (i.e.
    // compatible with 'strcmp').

bool operator<=(const Name& lhs, const Name& rhs);
    // Return 'false' if the specified 'rhs' is ordered before the specified
    // 'lhs', and 'true' otherwise. The ordering used is stable within the
    // lifetime of a single process and is compatible with
    // 'operator==(const Name&, const Name&)', however this order is neither
    // guaranteed to be consistent across different processes (including
    // repeated runs of the same process), nor guaranteed to be lexical (i.e.
    // compatible with 'strcmp').

bool operator>(const Name& lhs, const Name& rhs);
    // Return 'true' if the specified 'rhs' is ordered before the specified
    // 'lhs', and 'false' otherwise. The ordering used is stable within the
    // lifetime of a single process and is compatible with
    // 'operator==(const Name&, const Name&)', however this order is neither
    // guaranteed to be consistent across different processes (including
    // repeated runs of the same process), nor guaranteed to be lexical (i.e.
    // compatible with 'strcmp').

bool operator>=(const Name& lhs, const Name& rhs);
    // Return 'false' if the specified 'lhs' is ordered before the specified
    // 'rhs', and 'true' otherwise. The ordering used is stable within the
    // lifetime of a single process and is compatible with
    // 'operator==(const Name&, const Name&)', however this order is neither
    // guaranteed to be consistent across different processes (including
    // repeated runs of the same process), nor guaranteed to be lexical (i.e.
    // compatible with 'strcmp').

std::ostream& operator<<(std::ostream& stream, const Name& name);
    // Write the value of the specified 'name' object to the specified output
    // 'stream', and return a reference to 'stream'.  Note that this
    // human-readable format is not fully specified and can change without
    // notice.

//=============================================================================
//                            FUNCTION DEFINITIONS
//=============================================================================

                            // ----------
                            // class Name
                            // ----------


Name::Name(blpapi_Name_t *handle)
: d_impl_p(handle)
{
}


Name::Name()
: d_impl_p(0)
{
}


Name::Name(const Name& original)
: d_impl_p(blpapi_Name_duplicate(original.d_impl_p))
{
}


Name::Name(const char *nameString)
{
    d_impl_p = blpapi_Name_create(nameString);
}


Name::~Name()
{
    if (d_impl_p) {
        blpapi_Name_destroy(d_impl_p);
    }
}


Name& Name::operator=(const Name& rhs)
{
    if (&rhs != this) {
        Name tmp(rhs);
        std::swap(tmp.d_impl_p, d_impl_p);
    }
    return *this;
}


const char *Name::string() const
{
    return blpapi_Name_string(d_impl_p);
}


size_t Name::length() const
{
    return blpapi_Name_length(d_impl_p);
}


blpapi_Name_t *Name::impl() const
{
    return d_impl_p;
}


Name Name::findName(const char *nameString)
{
    return Name(blpapi_Name_findName(nameString));
}


bool Name::hasName(const char *nameString)
{
    return blpapi_Name_findName(nameString) ? true : false;
}


size_t Name::hash() const
{
    return reinterpret_cast<size_t>(impl());
}

}  // close namespace blpapi


bool blpapi::operator==(const Name& lhs, const Name& rhs)
{
    return (lhs.impl() == rhs.impl());
}


bool blpapi::operator!=(const Name& lhs, const Name& rhs)
{
    return !(lhs == rhs);
}


bool blpapi::operator==(const Name& lhs, const char *rhs)
{
    return blpapi_Name_equalsStr(lhs.impl(), rhs) != 0;
}


bool blpapi::operator!=(const Name& lhs, const char *rhs)
{
    return !(lhs == rhs);
}


bool blpapi::operator==(const char *lhs, const Name& rhs)
{
    return rhs == lhs;
}


bool blpapi::operator!=(const char *lhs, const Name& rhs)
{
    return !(rhs == lhs);
}


bool blpapi::operator<(const Name& lhs, const Name& rhs)
{
    return lhs.impl() < rhs.impl();
}


bool blpapi::operator<=(const Name& lhs, const Name& rhs)
{
    return !(rhs < lhs);
}


bool blpapi::operator>(const Name& lhs, const Name& rhs)
{
    return rhs < lhs;
}


bool blpapi::operator>=(const Name& lhs, const Name& rhs)
{
    return !(lhs < rhs);
}


std::ostream& blpapi::operator<<(std::ostream& stream, const Name& name)
{
    return stream << name.string();
}

}  // close namespace BloombergLP

#endif // __cplusplus

#endif // #ifndef INCLUDED_BLPAPI_NAME


namespace BloombergLP {
namespace blpapi {
                         // =============
                         // class Message
                         // =============

class Message {
    // A handle to a single message.
    //
    // Message objects are obtained from a MessageIterator. Each
    // Message is associated with a Service and with one or more
    // CorrelationId values. The Message contents are represented as
    // an Element and some convenient shortcuts are supplied to the
    // Element accessors.
    //
    // A Message is a handle to a single underlying protocol
    // message. The underlying messages are reference counted - the
    // underlying Message object is freed when the last Message object
    // which references it is destroyed.

    blpapi_Message_t *d_handle;
    Element           d_elements;
    bool              d_isCloned;

  public:
    enum Fragment {
        // A message could be split into more than one fragments to reduce
        // each message size. This enum is used to indicate whether a message
        // is a fragmented message and the position in the fragmented messages.

        FRAGMENT_NONE = 0, // message is not fragmented
        FRAGMENT_START, // the first fragmented message
        FRAGMENT_INTERMEDIATE, // intermediate fragmented messages
        FRAGMENT_END // the last fragmented message
    };

  public:
    // CREATORS
    Message(blpapi_Message_t *handle, bool clonable = false);
        // Construct the Message with the specified 'handle' and set the
        // isCloned flag with the specified value of 'clonable'. This flag
        // will used to release reference on message handle when the
        // destructor is called.

    Message(const Message& original);
        // Construct the message using the handle of the original. This will
        // add a reference to the handle and set the d_isCloned flag to true,
        // to ensure that release reference is called when destructor is
        // invoked.

    ~Message();
        // Destroy this message. Call release reference on handle if the
        // d_isCloned is set.

    // MANIUPLATORS
    Message& operator=(const Message& rhs);
        // Copies the message specified by 'rhs' into the current message and
        // set the d_isCloned flag with the specified value of 'true'. This
        // flag will used to release reference on message handle when the
        // destructor is called.

    // ACCESSORS
    Name messageType() const;
        // Returns the type of this message.

    const char* topicName() const;
        // Returns a pointer to a null-terminated string containing
        // the topic string associated with this message. If there is
        // no topic associated with this message then an empty string
        // is returned. The pointer returned remains valid until the
        // Message is destroyed.

    Service service() const;
        // Returns the service which sent this Message.

    int numCorrelationIds() const;
        // Returns the number of CorrelationIds associated with this
        // message.
        //
        // Note: A Message will have exactly one CorrelationId unless
        // 'allowMultipleCorrelatorsPerMsg' option was enabled for the
        // Session this Message came from. When
        // 'allowMultipleCorrelatorsPerMsg' is disabled (the default)
        // and more than one active subscription would result in the
        // same Message the Message is delivered multiple times
        // (without making physical copied). Each Message is
        // accompanied by a single CorrelationId. When
        // 'allowMultipleCorrelatorsPerMsg' is enabled and more than
        // one active subscription would result in the same Message
        // the Message is delivered once with a list of corresponding
        // CorrelationId values.

    CorrelationId correlationId(size_t index=0) const;
        // Returns the specified 'index'th CorrelationId associated
        // with this message. If 'index'>=numCorrelationIds()
        // then an exception is thrown.

    bool hasElement(const Name& name, bool excludeNullElements=false) const;
    bool hasElement(const char* name, bool excludeNullElements=false) const;
        // Equivalent to asElement().hasElement(name).

    size_t numElements() const;
        // Equivalent to asElement().numElements().

    const Element getElement(const Name& name) const;
        // Equivalent to asElement().getElement(name).

    const Element getElement(const char* name) const;
        // Equivalent to asElement().getElement(name).

    bool getElementAsBool(const Name& name) const;
    bool getElementAsBool(const char* name) const;
        // Equivalent to asElement().getElementAsBool(name).

    char getElementAsChar(const Name& name) const;
    char getElementAsChar(const char* name) const;
        // Equivalent to asElement().getElementAsChar(name).

    Int32 getElementAsInt32(const Name& name) const;
    Int32 getElementAsInt32(const char* name) const;
        // Equivalent to asElement().getElementAsInt32(name).

    Int64 getElementAsInt64(const Name& name) const;
    Int64 getElementAsInt64(const char* name) const;
        // Equivalent to asElement().getElementAsInt64(name).

    Float32 getElementAsFloat32(const Name& name) const;
    Float32 getElementAsFloat32(const char* name) const;
        // Equivalent to asElement().getElementAsFloat32(name).

    Float64 getElementAsFloat64(const Name& name) const;
    Float64 getElementAsFloat64(const char* name) const;
        // Equivalent to asElement().getElementAsFloat64(name).

    Datetime getElementAsDatetime(const Name& name) const;
    Datetime getElementAsDatetime(const char* name) const;
        // Equivalent to asElement().getElementAsDatetime(name).

    const char* getElementAsString(const Name& name) const;
    const char* getElementAsString(const char* name) const;
        // Equivalent to asElement().getElementAsString(name).

    const Element asElement() const;
        // Returns the contents of this Message as a read-only
        // Element. The Element returned remains valid until this
        // Message is destroyed.

    const char *getPrivateData(size_t *size) const;
        // Return a raw pointer to the message private data if it had any. If
        // 'size' is a valid pointer (not 0), it will be filled with the size
        // of the private data. If the message has no private data attached to
        // it the return value is 0 and the 'size' pointer (if valid) is set to
        // 0.

    Fragment fragmentType() const;
        // Return fragment type of this message. The return value is a value
        // of enum Fragment to indicate whether it is a fragmented message of a
        // big message and its positions in fragmentation if it is.

    int timeReceived(TimePoint *timestamp) const;
        // Load into the specified 'timestamp', the time when the message was
        // received by the sdk. This method will fail if there is no timestamp
        // associated with Message. On failure, the 'timestamp' is not
        // modified. Return 0 on success and a non-zero value otherwise.
        // Note that by default the subscription data messages are not
        // timestamped (but all the other messages are). To enable recording
        // receive time for subscription data, set
        // 'SessionOptions::recordSubscriptionDataReceiveTimes'.

    std::ostream& print(std::ostream& stream,
                        int level=0,
                        int spacesPerLevel=4) const;
        // Format this Message to the specified output 'stream' at the
        // (absolute value of) the optionally specified indentation
        // 'level' and return a reference to 'stream'. If 'level' is
        // specified, optionally specify 'spacesPerLevel', the number
        // of spaces per indentation level for this and all of its
        // nested objects. If 'level' is negative, suppress indentation
        // of the first line. If 'spacesPerLevel' is negative, format
        // the entire output on one line, suppressing all but the
        // initial indentation (as governed by 'level').

    const blpapi_Message_t* impl() const;
        // Returns the internal implementation.

    blpapi_Message_t* impl();
        // Returns the internal implementation.
};

// FREE OPERATORS
std::ostream& operator<<(std::ostream& stream, const Message &message);
    // Write the value of the specified 'message' object to the specified
    // output 'stream' in a single-line format, and return a reference to
    // 'stream'.  If 'stream' is not valid on entry, this operation has no
    // effect.  Note that this human-readable format is not fully specified,
    // can change without notice, and is logically equivalent to:
    //..
    //  print(stream, 0, -1);
    //..

// ============================================================================
//                       AND TEMPLATE FUNCTION IMPLEMENTATIONS
// ============================================================================

                            // -------------
                            // class Message
                            // -------------
// CREATORS

Message::Message(blpapi_Message_t *handle, bool clonable)
: d_handle(handle)
, d_isCloned(clonable)
{
    if (handle) {
        d_elements = Element(blpapi_Message_elements(handle));
    }
}


Message::Message(const Message& original)
: d_handle(original.d_handle)
, d_elements(original.d_elements)
, d_isCloned(true)
{
    if (d_handle) {
        BLPAPI_CALL_MESSAGE_ADDREF(d_handle);
    }
}


Message::~Message()
{
    if (d_isCloned && d_handle) {
        BLPAPI_CALL_MESSAGE_RELEASE(d_handle);
    }
}
// MANIPULATORS

Message& Message::operator=(const Message& rhs)
{

    if (this == &rhs) {
        return *this;
    }

    if (d_isCloned && (d_handle == rhs.d_handle)) {
        return *this;
    }

    if (d_isCloned && d_handle) {
        BLPAPI_CALL_MESSAGE_RELEASE(d_handle);
    }
    d_handle = rhs.d_handle;
    d_elements = rhs.d_elements;
    d_isCloned = true;

    if (d_handle) {
        BLPAPI_CALL_MESSAGE_ADDREF(d_handle);
    }

    return *this;
}

// ACCESSORS

Name Message::messageType() const
{
    return Name(blpapi_Message_messageType(d_handle));
}


const char* Message::topicName() const
{
    return blpapi_Message_topicName(d_handle);
}


Service Message::service() const
{
    return Service(blpapi_Message_service(d_handle));
}


int Message::numCorrelationIds() const
{
    return blpapi_Message_numCorrelationIds(d_handle);
}


CorrelationId Message::correlationId(size_t index) const
{
    if (index >= (size_t)numCorrelationIds())
        throw IndexOutOfRangeException("index >= numCorrelationIds");
    return CorrelationId(blpapi_Message_correlationId(d_handle, index));
}


bool Message::hasElement(const char* name,
                         bool excludeNullElements) const
{
    return d_elements.hasElement(name, excludeNullElements);
}


bool Message::hasElement(const Name& name,
                         bool excludeNullElements) const
{
    return d_elements.hasElement(name, excludeNullElements);
}


size_t Message::numElements() const
{
    return d_elements.numElements();
}


const Element Message::getElement(const Name& name) const
{
    return d_elements.getElement(name);
}


const Element Message::getElement(const char* nameString) const
{
    return d_elements.getElement(nameString);
}


bool Message::getElementAsBool(const Name& name) const
{
    return d_elements.getElementAsBool(name);
}


bool Message::getElementAsBool(const char* name) const
{
    return d_elements.getElementAsBool(name);
}


char Message::getElementAsChar(const Name& name) const
{
    return d_elements.getElementAsChar(name);
}


char Message::getElementAsChar(const char* name) const
{
    return d_elements.getElementAsChar(name);
}


Int32 Message::getElementAsInt32(const Name& name) const
{
    return d_elements.getElementAsInt32(name);
}


Int32 Message::getElementAsInt32(const char* name) const
{
    return d_elements.getElementAsInt32(name);
}


Int64 Message::getElementAsInt64(const Name& name) const
{
    return d_elements.getElementAsInt64(name);
}


Int64 Message::getElementAsInt64(const char* name) const
{
    return d_elements.getElementAsInt64(name);
}


Float32 Message::getElementAsFloat32(const Name& name) const
{
    return d_elements.getElementAsFloat32(name);
}


Float32 Message::getElementAsFloat32(const char* name) const
{
    return d_elements.getElementAsFloat32(name);
}


Float64 Message::getElementAsFloat64(const Name& name) const
{
    return d_elements.getElementAsFloat64(name);
}


Float64 Message::getElementAsFloat64(const char* name) const
{
    return d_elements.getElementAsFloat64(name);
}


Datetime Message::getElementAsDatetime(const Name& name) const
{
    return d_elements.getElementAsDatetime(name);
}


Datetime Message::getElementAsDatetime(const char* name) const
{
    return d_elements.getElementAsDatetime(name);
}


const char* Message::getElementAsString(const Name& name) const
{
    return d_elements.getElementAsString(name);
}


const char* Message::getElementAsString(const char* name) const
{
    return d_elements.getElementAsString(name);
}


const Element Message::asElement() const
{
    return d_elements;
}


const char *Message::getPrivateData(size_t *size) const
{
    return blpapi_Message_privateData(d_handle, size);
}


Message::Fragment Message::fragmentType() const
{
    return (Message::Fragment) BLPAPI_CALL_MESSAGE_FRAGMENTTYPE(d_handle);
}


int Message::timeReceived(TimePoint *timestamp) const
{
    return BLPAPI_CALL_MESSAGE_TIMERECEIVED(
        d_handle,
        timestamp);
}


std::ostream& Message::print(
        std::ostream& stream,
        int level,
        int spacesPerLevel) const
{
    return d_elements.print(stream, level, spacesPerLevel);
}


std::ostream& operator<<(std::ostream& stream, const Message &message)
{
    return message.print(stream, 0,-1);
}


const blpapi_Message_t* Message::impl() const
{
    return d_handle;
}


blpapi_Message_t* Message::impl()
{
    return d_handle;
}

}  // close namespace blpapi
}  // close namespace BloombergLP

#endif // #ifdef __cplusplus
#endif // #ifndef INCLUDED_BLPAPI_MESSAGE



class Element;
                         // ==============
                         // class Identity
                         // ==============

class Identity {
    // Provides access to the entitlements for a specific user.
    //
    // An unauthorized Identity is created using
    // Session::createIdentity(). Once a Identity has been created
    // it can be authorized using
    // Session::sendAuthorizationRequest(). The authorized Identity
    // can then be queried or used in Session::subscribe() or
    // Session::sendRequest() calls.
    //
    // Once authorized a Identity has access to the entitlements of
    // the user which it was validated for.
    //
    // The Identity is a reference counted handle, copying it or
    // assigning it does not duplicate the underlying entitlement
    // data. Once the last Identity referring to the underlying
    // entitlement data is destroyed that entitlement data is
    // discarded and can only be re-established using
    // Session::sendAuthorizationRequest() again.

    blpapi_Identity_t *d_handle_p;

    void addRef();
    void release();

  public:
    enum SeatType {
        INVALID_SEAT = BLPAPI_SEATTYPE_INVALID_SEAT,
        BPS = BLPAPI_SEATTYPE_BPS, // Bloomberg Professional Service
        NONBPS = BLPAPI_SEATTYPE_NONBPS
    };

  public:
    Identity(blpapi_Identity_t *handle);
        // Assume ownership of the raw handle

    Identity();
        // Create an uninitialized Identity. The only valid operations
        // on an uninitialized Identity are assignment, isValid() and
        // destruction.

    Identity(const Identity& original);
        // Copy constructor

    ~Identity();
        // Destructor. Destroying the last Identity for a specific
        // user cancels any authorizations associated with it.

    // MANIPULATORS

    Identity& operator=(const Identity&);
        // Assignment operator.

    // ACCESSORS
    bool hasEntitlements(const Service& service,
                         const int *entitlementIds,
                         size_t numEntitlements) const;
        // Return true if this 'Identity' is authorized for the specified
        // 'service' and the first 'numEntitlements' elements of the specified
        // 'entitlementIds' array; otherwise return false. The behavior is
        // undefined unless 'entitlementIds' is an array containing at least
        // 'numEntitlements' elements.

    bool hasEntitlements(const Service& service,
                         const int *entitlementIds,
                         size_t numEntitlements,
                         int *failedEntitlements,
                         int *failedEntitlementsCount) const;
        // Return true if this 'Identity' is authorized for the specified
        // 'service' and the first 'numEntitlements' elements of the specified
        // 'entitlementIds' array; otherwise fill the specified
        // 'failedEntitlements' array with the subset of 'entitlementIds' this
        // 'Identity' is not authorized for, load the number of such
        // entitlements into the specified 'failedEntitlementsCount', and
        // return false. The behavior is undefined unless 'entitlementIds' and
        // 'failedEntitlements' are arrays containing at least
        // 'numEntitlements' elements, and 'failedEntitlementsCount' is
        // non-null.

    bool hasEntitlements(const Service& service,
                         const Element& entitlementIds,
                         int *failedEntitlements,
                         int *failedEntitlementsCount) const;
        // Return true if this 'Identity' is authorized for the specified
        // 'service' and for each of the entitlement IDs contained in the
        // specified 'entitlementIds', which must be an 'Element' which is an
        // array of integers; otherwise, fill the specified
        // 'failedEntitlements' array with the subset of entitlement IDs this
        // 'Identity' is not authorized for, load the number of such
        // entitlements into the specified 'failedEntitlementsCount', and
        // return false. The behavior is undefined unless 'failedEntitlements'
        // is an array containing at least 'entitlementIds.numValues()'
        // elements and 'failedEntitlementsCount' is non-null.

    bool isValid() const;
        // Return true if this 'Identity' is valid; otherwise return false.
        // Note that a valid 'Identity' has not necessarily been authorized.
        // This function is deprecated.

    bool isAuthorized(const Service& service) const;
        // Return true if this 'Identity' is authorized for the specified
        // 'service'; otherwise return false.

    SeatType getSeatType() const;
        // Return the seat type of this 'Identity'.

    blpapi_Identity_t* handle() const;
};

//=============================================================================
//                            FUNCTION DEFINITIONS
//=============================================================================

                         // --------------
                         // class Identity
                         // --------------


Identity::Identity()
    : d_handle_p(0)
{
}


Identity::Identity(blpapi_Identity_t *newHandle)
    : d_handle_p(newHandle)
{
}


Identity::Identity(const Identity& original)
    : d_handle_p(original.d_handle_p)
{
    addRef();
}


Identity::~Identity()
{
    release();
}


Identity& Identity::operator=(const Identity& rhs)
{
    if (&rhs != this) {
        release();
        d_handle_p = rhs.d_handle_p;
        addRef();
    }
    return *this;
}


void Identity::addRef()
{
    if (d_handle_p) {
        blpapi_Identity_addRef(d_handle_p);
    }
}


void Identity::release()
{
    if (d_handle_p) {
        blpapi_Identity_release(d_handle_p);
    }
}


bool Identity::hasEntitlements(
        const Service& service,
        const int *entitlementIds,
        size_t numEntitlements) const
{
    return blpapi_Identity_hasEntitlements(
            d_handle_p,
            service.handle(),
            0,
            entitlementIds,
            numEntitlements,
            0,
            0) ? true : false;
}


bool Identity::hasEntitlements(
        const Service& service,
        const int *entitlementIds,
        size_t numEntitlements,
        int *failedEntitlements,
        int *failedEntitlementsCount) const
{
    return blpapi_Identity_hasEntitlements(
            d_handle_p,
            service.handle(),
            0,
            entitlementIds,
            numEntitlements,
            failedEntitlements,
            failedEntitlementsCount) ? true : false;
}


bool Identity::hasEntitlements(
        const Service& service,
        const Element& entitlementIds,
        int *failedEntitlements,
        int *failedEntitlementsCount) const
{
    return blpapi_Identity_hasEntitlements(
            d_handle_p,
            service.handle(),
            entitlementIds.handle(),
            0,
            0,
            failedEntitlements,
            failedEntitlementsCount) ? true : false;
}


bool Identity::isValid() const
{
    return (d_handle_p != 0);
}


bool Identity::isAuthorized(const Service& service) const
{
    return blpapi_Identity_isAuthorized(d_handle_p,
                                        service.handle()) ? true : false;
}


Identity::SeatType Identity::getSeatType() const
{
    int seatType = BLPAPI_SEATTYPE_INVALID_SEAT;
    throwOnError(
            blpapi_Identity_getSeatType(d_handle_p, &seatType));
    return static_cast<SeatType>(seatType);
}


blpapi_Identity_t* Identity::handle() const
{
    return d_handle_p;
}

}  // close namespace blpapi
}  // close namespace BloombergLP

#endif // #ifdef __cplusplus
#endif // #ifndef INCLUDED_BLPAPI_IDENTITY




namespace BloombergLP {
namespace blpapi {
                          // ==========================
                          // struct HighResolutionClock
                          // ==========================

struct HighResolutionClock {
    // This utility struct provides a source for the current moment in time as
    // a 'blpapi::TimePoint' object. This is currently intended for use
    // primarily in conjunction with the 'blpapi::Message::timeReceived'
    // interfaces, to allow measurement of the amount of time a message spends
    // in the client event queue.

    static TimePoint now();
        // Return the current moment in time as a 'TimePoint' value.
};

// ============================================================================
//                       AND TEMPLATE FUNCTION IMPLEMENTATIONS
// ============================================================================

                          // --------------------------
                          // struct HighResolutionClock
                          // --------------------------

TimePoint HighResolutionClock::now()
{
    TimePoint tp;
    BLPAPI_CALL_HIGHRESOLUTIONCLOCK_NOW(&tp);
    return tp;
}

}  // close namespace blpapi
}  // close namespace BloombergLP

#endif // #ifdef __cplusplus
#endif // #ifndef INCLUDED_BLPAPI_HIGHRESOLUTIONCLOCK




namespace BloombergLP {
namespace blpapi {
                            // ===============
                            // class Exception
                            // ===============

class Exception : public std::exception {
    // This class defines a base exception for blpapi operations.  Objects of
    // this class contain the error description for the exception.

    // DATA
    const std::string d_description;

  private:
    // NOT IMPLEMENTED
    Exception& operator=(const Exception&);  // = delete

  public:
    // CREATORS
    explicit Exception(const std::string& description);
        // Create an exception object initialized with the specified
        // 'description'.

    // ACCESSORS
    const std::string& description() const throw();
        // Return the error description supplied at construction.

    virtual const char* what() const throw();
        // Return the error description supplied at construction as a
        // null-terminated character sequence.

    virtual ~Exception() throw();
        // Destroy this object.
};
                   // =====================================
                   // class DuplicateCorrelationIdException
                   // =====================================

class DuplicateCorrelationIdException : public Exception {
    // The class defines an exception for non unqiue 'blpapi::CorrelationId'.
  public:
    // CREATORS
    explicit DuplicateCorrelationIdException(const std::string &description);
        // Create an exception object initialized with the specified
        // 'description'.
};

                        // ===========================
                        // class InvalidStateException
                        // ===========================

class InvalidStateException: public Exception {
    // This class defines an exception for calling methods on an object that is
    // not in a valid state.
  public:
    // CREATORS
    explicit InvalidStateException(const std::string &description);
        // Create an exception object initialized with the specified
        // 'description'.
};

                       // ==============================
                       // class InvalidArgumentException
                       // ==============================

class InvalidArgumentException: public Exception {
    // This class defines an exception for invalid arguments on method
    // invocations.
  public:
    // CREATORS
    explicit InvalidArgumentException(const std::string& description);
        // Create an exception object initialized with the specified
        // 'description'.
};

                      // ================================
                      // class InvalidConversionException
                      // ================================

class InvalidConversionException: public Exception {
    // This class defines an exception for invalid conversion of data.
  public:
    // CREATORS
    explicit InvalidConversionException(const std::string& description);
        // Create an exception object initialized with the specified
        // 'description'.
};

                       // ==============================
                       // class IndexOutOfRangeException
                       // ==============================

class IndexOutOfRangeException: public Exception {
    // This class defines an exception to capture the error when an invalid
    // index is used for an operation that needs index.
  public:
    // CREATORS
    explicit IndexOutOfRangeException(const std::string& description);
        // Create an exception object initialized with the specified
        // 'description'.
};

                        // ============================
                        // class FieldNotFoundException
                        // ============================

class FieldNotFoundException: public Exception {
    // This class defines an exception to capture the error when an invalid
    // field is used for operation.
    // DEPRECATED
  public:
    // CREATORS
    explicit FieldNotFoundException(const std::string& description);
        // Create an exception object initialized with the specified
        // 'description'.
};

                        // ===========================
                        // class UnknownErrorException
                        // ===========================

class UnknownErrorException: public Exception {
    // This class defines an exception for errors that do not fall in any
    // predefined category.
  public:
    // CREATORS
    explicit UnknownErrorException(const std::string& description);
        // Create an exception object initialized with the specified
        // 'description'.
};

                    // ===================================
                    // class UnsupportedOperationException
                    // ===================================

class UnsupportedOperationException: public Exception {
    // This class defines an exception for unsupported operations.
  public:
    // CREATORS
    explicit UnsupportedOperationException(const std::string& description);
        // Create an exception object initialized with the specified
        // 'description'.
};

                          // =======================
                          // class NotFoundException
                          // =======================

class NotFoundException: public Exception {
    // This class defines an exception to capture the error when an item is
    // not found for an operation.
  public:
    // CREATORS
    explicit NotFoundException(const std::string& description);
        // Create an exception object initialized with the specified
        // 'description'.
};

                            // ===================
                            // class ExceptionUtil
                            // ===================

class ExceptionUtil {
    // This class provides a namespace for utility functions that convert
    // C-style error codes to 'blpapi::Exception' objects.

  private:
    static void throwException(int errorCode);
        // Throw the appropriate exception for the specified 'errorCode'.

  public:
    static void throwOnError(int errorCode);
        // Throw the appropriate exception for the specified 'errorCode' if the
        // errorCode is not 0.
};

// ============================================================================
//                         FUNCTION DEFINITIONS
// ============================================================================

                              // ---------------
                              // class Exception
                              // ---------------


Exception::Exception(const std::string& newDescription)
: d_description(newDescription)
{
}


Exception::~Exception() throw()
{
}


const std::string& Exception::description() const throw()
{
    return d_description;
}


const char* Exception::what() const throw()
{
    return description().c_str();
}

                   // -------------------------------------
                   // class DuplicateCorrelationIdException
                   // -------------------------------------


DuplicateCorrelationIdException::DuplicateCorrelationIdException(
                                             const std::string& newDescription)
: Exception(newDescription)
{
}

                        // ---------------------------
                        // class InvalidStateException
                        // ---------------------------


InvalidStateException::InvalidStateException(const std::string& newDescription)
: Exception(newDescription)
{
}

                       // ------------------------------
                       // class InvalidArgumentException
                       // ------------------------------


InvalidArgumentException::InvalidArgumentException(
                                             const std::string& newDescription)
: Exception(newDescription)
{
}

                      // --------------------------------
                      // class InvalidConversionException
                      // --------------------------------


InvalidConversionException::InvalidConversionException(
                                             const std::string& newDescription)
: Exception(newDescription)
{
}

                       // ------------------------------
                       // class IndexOutOfRangeException
                       // ------------------------------


IndexOutOfRangeException::IndexOutOfRangeException(
                                             const std::string& newDescription)
: Exception(newDescription)
{
}

                        // ----------------------------
                        // class FieldNotFoundException
                        // ----------------------------


FieldNotFoundException::FieldNotFoundException(
                                             const std::string& newDescription)
: Exception(newDescription)
{
}

                        // ---------------------------
                        // class UnknownErrorException
                        // ---------------------------


UnknownErrorException::UnknownErrorException(const std::string& newDescription)
: Exception(newDescription)
{
}

                    // -----------------------------------
                    // class UnsupportedOperationException
                    // -----------------------------------


UnsupportedOperationException::UnsupportedOperationException(
                                             const std::string& newDescription)
: Exception(newDescription)
{
}

                          // -----------------------
                          // class NotFoundException
                          // -----------------------


NotFoundException::NotFoundException(const std::string& newDescription)
: Exception (newDescription)
{
}

                            // -------------------
                            // class ExceptionUtil
                            // -------------------


void throwException(int errorCode)
{
    const char* description = blpapi_getLastErrorDescription(errorCode);
    if (!description) {
        description = "Unknown";
    }

    if (BLPAPI_ERROR_DUPLICATE_CORRELATIONID == errorCode) {
        throw DuplicateCorrelationIdException(description);
    }

    switch (BLPAPI_RESULTCLASS(errorCode))
      case BLPAPI_INVALIDSTATE_CLASS: {
        throw InvalidStateException(description);
      case BLPAPI_INVALIDARG_CLASS:
        throw InvalidArgumentException(description);
      case BLPAPI_CNVERROR_CLASS:
        throw InvalidConversionException(description);
      case BLPAPI_BOUNDSERROR_CLASS:
        throw IndexOutOfRangeException(description);
      case BLPAPI_FLDNOTFOUND_CLASS:
        throw FieldNotFoundException(description);
      case BLPAPI_UNSUPPORTED_CLASS:
        throw UnsupportedOperationException(description);
      case BLPAPI_NOTFOUND_CLASS:
        throw NotFoundException(description);
      default:
        throw Exception(description);
    }
}


void throwOnError(int errorCode)
{
    if (errorCode) {
        throwException(errorCode);
    }
}

}  // close namespace blpapi {
}  // close namespace BloombergLP {

#endif

#endif // #ifndef INCLUDED_BLPAPI_EXCEPTION



class EventFormatter {
    // EventFormatter is used to populate 'Event's for publishing.
    //
    // An EventFormatter is created from an Event obtained from
    // createPublishEvent() on Service. Once the Message or Messages have been
    // appended to the Event using the EventFormatter the Event can be
    // published using publish() on the ProviderSession.
    //
    // EventFormatter objects cannot be copied or assigned so as to ensure
    // there is no ambiguity about what happens if two 'EventFormatter's are
    // both formatting the same 'Event'.
    //
    // The EventFormatter supportes appending message of the same type multiple
    // time in the same 'Event'. However the 'EventFormatter' supports write
    // once only to each field. It is an error to call setElement() or
    // pushElement() for the same name more than once at a particular level of
    // the schema when creating a message.

    blpapi_EventFormatter_t *d_handle;

  private:
    // NOT IMPLEMENTED
    EventFormatter& operator=(const EventFormatter&);
    EventFormatter(const EventFormatter&);
    EventFormatter();

  public:


this(Event* event)
{
    d_handle = blpapi_EventFormatter_create(event.impl());
}


~this()
{
    blpapi_EventFormatter_destroy(d_handle);
}


void appendMessage(string messageType, const Topic* topic)
{
    throwOnError(blpapi_EventFormatter_appendMessage(d_handle, cast(const(char*))messageType, 0, topic.impl()));
}


void appendMessage(const Name* messageType, const Topic* topic)
{
    throwOnError(blpapi_EventFormatter_appendMessage(d_handle, 0, messageType.impl(), topic.impl()));
}


void appendMessage(string messageType, const Topic* topic, unsigned int  sequenceNumber)
{
    throwOnError(BLPAPI_CALL_EVENTFORMATTER_APPENDMESSAGESEQ(d_handle, cast(const(char*))messageType, 0,
                                    topic.impl(), sequenceNumber, 0));
}


void appendMessage(const Name*  messageType, const Topic* topic, unsigned int sequenceNumber)
{
    throwOnError(BLPAPI_CALL_EVENTFORMATTER_APPENDMESSAGESEQ(d_handle, 0, messageType.impl(), topic.impl(), sequenceNumber, 0));
}


void appendResponse(string opType)
{
    blpapi_EventFormatter_appendResponse(d_handle, cast(const(char*))opType, 0));
}


void appendResponse(const Name* opType)
{
    blpapi_EventFormatter_appendResponse(d_handle, 0, opType.impl()));
}


void appendRecapMessage(const Topic* topic, const CorrelationId *cid)
{
    blpapi_EventFormatter_appendRecapMessage(d_handle, topic.impl(), cid ? &cid.impl() : 0));
}


void appendRecapMessage(const Topic&         topic,
                                        unsigned int         sequenceNumber,
                                        const CorrelationId *cid)
{

    throwOnError(
        BLPAPI_CALL_EVENTFORMATTER_APPENDRECAPMESSAGESEQ(
            d_handle,
            topic.impl(),
            cid ? &cid.impl() : 0,
            sequenceNumber,
            0));

}


void setElement(const char *name, bool value)
{
    throwOnError(blpapi_EventFormatter_setValueBool(
                                    d_handle,
                                    name, 0,
                                    value));
}


void setElement(const char *name, char value)
{
    throwOnError(blpapi_EventFormatter_setValueChar(
                                    d_handle,
                                    name, 0,
                                    value));
}


void setElement(const char *name, Int32 value)
{
    throwOnError(blpapi_EventFormatter_setValueInt32(
                                    d_handle,
                                    name, 0,
                                    value));
}


void setElement(const char *name, Int64 value)
{
    throwOnError(blpapi_EventFormatter_setValueInt64(
                                    d_handle,
                                    name, 0,
                                    value));
}


void setElement(const char *name, Float32 value)
{
    throwOnError(blpapi_EventFormatter_setValueFloat32(
                                    d_handle,
                                    name, 0,
                                    value));
}


void setElement(const char *name, Float64 value)
{
    throwOnError(blpapi_EventFormatter_setValueFloat64(
                                    d_handle,
                                    name, 0,
                                    value));
}


void setElement(const char *name, const Datetime& value)
{
    throwOnError(blpapi_EventFormatter_setValueDatetime(
                                    d_handle,
                                    name, 0,
                                    &value.rawValue()));

}


void setElement(const char *name, const char *value)
{
    throwOnError(blpapi_EventFormatter_setValueString(
                                    d_handle,
                                    name, 0,
                                    value));
}


void setElement(const char *name, const Name& value)
{
    throwOnError(blpapi_EventFormatter_setValueFromName(
                                    d_handle,
                                    name, 0,
                                    value.impl()));
}


void setElementNull(const char *name)
{
    throwOnError(
        BLPAPI_CALL_EVENTFORMATTER_SETVALUENULL(d_handle,
                                                name,
                                                0));
}


void setElement(const Name& name, bool value)
{
    throwOnError(blpapi_EventFormatter_setValueBool(
                                    d_handle,
                                    0, name.impl(),
                                    value));
}


void setElement(const Name& name, char value)
{
    throwOnError(blpapi_EventFormatter_setValueChar(
                                    d_handle,
                                    0, name.impl(),
                                    value));
}


void setElement(const Name& name, Int32 value)
{
    throwOnError(blpapi_EventFormatter_setValueInt32(
                                    d_handle,
                                    0, name.impl(),
                                    value));
}


void setElement(const Name& name, Int64 value)
{
    throwOnError(blpapi_EventFormatter_setValueInt64(
                                    d_handle,
                                    0, name.impl(),
                                    value));
}


void setElement(const Name& name, Float32 value)
{
    throwOnError(blpapi_EventFormatter_setValueFloat32(
                                    d_handle,
                                    0, name.impl(),
                                    value));
}

void setElement(const Name& name, Float64 value)
{
    throwOnError(blpapi_EventFormatter_setValueFloat64(
                                    d_handle,
                                    0, name.impl(),
                                    value));
}

void setElement(const Name& name, const Datetime& value)
{
    throwOnError(blpapi_EventFormatter_setValueDatetime(
                                    d_handle,
                                    0, name.impl(),
                                    &value.rawValue()));
}

void setElement(const Name& name, const char *value)
{
    throwOnError(blpapi_EventFormatter_setValueString(
                                    d_handle,
                                    0, name.impl(),
                                    value));
}

void setElement(const Name& name, const Name& value)
{
    throwOnError(blpapi_EventFormatter_setValueFromName(
                                    d_handle,
                                    0, name.impl(),
                                    value.impl()));
}


void setElementNull(const Name& name)
{
    throwOnError(
        BLPAPI_CALL_EVENTFORMATTER_SETVALUENULL(d_handle,
                                                0,
                                                name.impl()));
}


void pushElement(const char *name)
{
    throwOnError(blpapi_EventFormatter_pushElement(
                                    d_handle, name, 0));
}


void pushElement(const Name& name)
{
    throwOnError(blpapi_EventFormatter_pushElement(
                                    d_handle, 0, name.impl()));
}


void popElement()
{
    throwOnError(blpapi_EventFormatter_popElement(
                                    d_handle));
}


void appendValue(bool value)
{
    throwOnError(blpapi_EventFormatter_appendValueBool(
                                    d_handle,
                                    value));
}


void appendValue(char value)
{
    throwOnError(blpapi_EventFormatter_appendValueChar(
                                    d_handle,
                                    value));
}


void appendValue(Int32 value)
{
    throwOnError(blpapi_EventFormatter_appendValueInt32(
                                    d_handle,
                                    value));
}


void appendValue(Int64 value)
{
    throwOnError(blpapi_EventFormatter_appendValueInt64(
                                    d_handle,
                                    value));
}


void appendValue(Float32 value)
{
    throwOnError(blpapi_EventFormatter_appendValueFloat32(
                                    d_handle,
                                    value));
}


void appendValue(Float64 value)
{
    throwOnError(blpapi_EventFormatter_appendValueFloat64(
                                    d_handle,
                                    value));
}



void appendValue(const Datetime& value)
{
    throwOnError(blpapi_EventFormatter_appendValueDatetime(
                                    d_handle,
                                    &value.rawValue()));

}

void appendValue(const char *value)
{
    throwOnError(blpapi_EventFormatter_appendValueString(
                                    d_handle,
                                    value));
}

void appendValue(const Name& value)
{
    throwOnError(blpapi_EventFormatter_appendValueFromName(
                                    d_handle,
                                    value.impl()));
}


void appendElement()
{
    throwOnError(blpapi_EventFormatter_appendElement(
                                   d_handle));
}


}  // close namespace blpapi
}  // close namespace BloombergLP

#endif // #ifdef __cplusplus
#endif // #ifndef INCLUDED_BLPAPI_EVENTFORMATTER



                         // =====================
                         // class EventDispatcher
                         // =====================

class EventDispatcher {
    // Dispatches events from one or more Sessions through callbacks
    //
    // EventDispatcher objects are optionally specified when Session
    // objects are constructed. A single EventDispatcher can be shared
    // by multiple Session objects.
    //
    // The EventDispatcher provides an event-driven interface,
    // generating callbacks from one or more internal threads for one
    // or more sessions.

    blpapi_EventDispatcher_t *d_impl_p;

  private:
    // NOT IMPLEMENTED
    EventDispatcher(const EventDispatcher&);
    EventDispatcher &operator=(const EventDispatcher&);

  public:
    EventDispatcher(size_t numDispatcherThreads = 1);
        // Construct an EventDispatcher with the specified
        // 'numDispatcherThreads'. If 'numDispatcherThreads' is 1 (the
        // default) then a single internal thread is created to
        // dispatch events. If 'numDispatcherThreads' is greater than
        // 1 then an internal pool of 'numDispatcherThreads' threads
        // is created to dispatch events. The behavior is undefined
        // if 'numDispatcherThreads' is 0.

    ~EventDispatcher();
        // Destructor.

    int start();
        // Start generating callbacks for events from sessions
        // associated with this EventDispatcher. Return 0 on success
        // and a non zero value otherwise.

    int stop(bool async = false);
        // Shutdown this event dispatcher object and stop generating
        // callbacks for events from sessions associated with it.
        // If the specified 'async' is false (the default) then this
        // method blocks until all current callbacks which were dispatched
        // through this EventDispatcher have completed.
        // Return 0 on success and a non zero value otherwise.
        //
        // Note: Calling stop with 'async' of false from within a callback
        // dispatched by this EventDispatcher is undefined and may result
        // in a deadlock.

    blpapi_EventDispatcher_t *impl() const;
        // Returns the internal implementation.
};

// ============================================================================
//                       AND TEMPLATE FUNCTION IMPLEMENTATIONS
// ============================================================================

                            // ---------------------
                            // class EventDispatcher
                            // ---------------------



EventDispatcher::EventDispatcher(size_t numDispatcherThreads)
    : d_impl_p(blpapi_EventDispatcher_create(numDispatcherThreads))
{
}


EventDispatcher::~EventDispatcher()
{
    blpapi_EventDispatcher_destroy(d_impl_p);
}


int EventDispatcher::start()
{
    return blpapi_EventDispatcher_start(d_impl_p);
}


int EventDispatcher::stop(bool async)
{
    return blpapi_EventDispatcher_stop(d_impl_p, async);
}


blpapi_EventDispatcher_t *EventDispatcher::impl() const
{
    return d_impl_p;
}

struct Event
{
    // A single event resulting from a subscription or a request.
    //
    // Event objects are created by the API and passed to the
    // application either through a registered EventHandler or
    // EventQueue or returned from the Session::nextEvent()
    // method. Event objects contain Message objects which can be
    // accessed using a MessageIterator.
    //
    // The Event object is a handle to an event. The event is the
    // basic unit of work provided to applications. Each Event object
    // consists of an EventType attribute and zero or more Message
    // objects. The underlying event data including the messages is
    // reference counted - as long as at least one Event object still
    // exists then the underlying data will not be freed.

    blpapi_Event_t *d_impl_p;

  public:
    enum EventType {
      // The possible types of event
      ADMIN                 = BLPAPI_EVENTTYPE_ADMIN,
        // Admin event
      SESSION_STATUS        = BLPAPI_EVENTTYPE_SESSION_STATUS,
        // Status updates for a session.
      SUBSCRIPTION_STATUS   = BLPAPI_EVENTTYPE_SUBSCRIPTION_STATUS,
        // Status updates for a subscription.
      REQUEST_STATUS        = BLPAPI_EVENTTYPE_REQUEST_STATUS,
        // Status updates for a request.
      RESPONSE              = BLPAPI_EVENTTYPE_RESPONSE,
        // The final (possibly only) response to a request.
      PARTIAL_RESPONSE      = BLPAPI_EVENTTYPE_PARTIAL_RESPONSE,
        // A partial response to a request.
      SUBSCRIPTION_DATA     = BLPAPI_EVENTTYPE_SUBSCRIPTION_DATA,
        // Data updates resulting from a subscription.
      SERVICE_STATUS        = BLPAPI_EVENTTYPE_SERVICE_STATUS,
        // Status updates for a service.
      TIMEOUT               = BLPAPI_EVENTTYPE_TIMEOUT,
        // An Event returned from nextEvent() if it timed out.
      AUTHORIZATION_STATUS  = BLPAPI_EVENTTYPE_AUTHORIZATION_STATUS,
        // Status updates for user authorization.
      RESOLUTION_STATUS     = BLPAPI_EVENTTYPE_RESOLUTION_STATUS,
        // Status updates for a resolution operation.
      TOPIC_STATUS          = BLPAPI_EVENTTYPE_TOPIC_STATUS,
        // Status updates about topics for service providers.
      TOKEN_STATUS          = BLPAPI_EVENTTYPE_TOKEN_STATUS,
        // Status updates for a generate token request.
      REQUEST               = BLPAPI_EVENTTYPE_REQUEST,
        // Request event
      UNKNOWN               = -1
    };

    Event();
        // Construct an uninitialized Event. The only valid operations
        // on an uninitialized Event are assignment, isValid() and
        // destruction.

    Event(blpapi_Event_t *handle);

    Event(const Event& original);
        // Copy constructor. This performs a shallow copy, increasing
        // the reference count on the actual data underlying this
        // handle.

    ~Event();
        // Destructor. If this is the last reference to this Event
        // then the underlying data (including all Messages associated
        // with the Event) are invalidated.

    // MANIPULATORS

    Event& operator=(const Event& rhs);
        // Assignment operator. This performs a shallow assignment,
        // increasing the reference count on the actual data
        // underlying this handle.

    // ACCESSORS

    EventType eventType() const;
        // Returns the type of messages contained by this Event.

    bool isValid() const;
        // Returns true if this Event is a valid event.

    blpapi_Event_t* impl() const;
};

                         // ================
                         // class EventQueue
                         // ================

class EventQueue {
    // A construct used to handle replies to request synchronously.
    //
    // An EventQueue can be supplied when using Session::sendRequest()
    // and Session::sendAuthorizationRequest() methods.
    //
    // When a request is submitted an application can either handle
    // the responses asynchronously as they arrive or use an
    // EventQueue to handle all responses for a given request or
    // requests synchronously. The EventQueue will only deliver
    // responses to the request(s) it is associated with.

    blpapi_EventQueue_t *d_handle_p;

  public:
    EventQueue();
        // Construct an empty event queue.

    ~EventQueue();
        // Destroy this event queue and cancel any pending request
        // that are linked to this queue.

    // MANIPULATORS

    Event nextEvent(int timeout=0);
        // Returns the next Event available from the EventQueue. If
        // the specified 'timeout' is zero this will wait forever for
        // the next event. If the specified 'timeout' is non zero then
        // if no Event is available within the specified 'timeout' an
        // Event with a type() of TIMEOUT will be returned.

    int tryNextEvent(Event *event);
        // If the EventQueue is non-empty, load the next Event available
        // into event and return 0 indicating success. If the EventQueue is
        // empty, return a non-zero value with no effect on event or the
        // the state of EventQueue. This method never blocks.

    void purge();
        // Purges any Event objects in this EventQueue which have not
        // been processed and cancel any pending requests linked to
        // this EventQueue. The EventQueue can subsequently be
        // re-used for a subsequent request.

    blpapi_EventQueue_t* handle() const;
};

                         // =====================
                         // class MessageIterator
                         // =====================

class MessageIterator {
    // An iterator over the Message objects within an Event.
    //
    // MessageIterator objects are used to process the individual
    // Message objects in an Event received in an EventHandler, from
    // EventQueue::nextEvent() or from Session::nextEvent().
    //
    // This class is used to iterate over each message in an
    // Event. The user must ensure that the Event this iterator is
    // created for is not destroyed before the iterator.

    blpapi_MessageIterator_t *d_impl_p;
    blpapi_Message_t         *d_current_p;

  private:
    // NOT IMPLEMENTED
    MessageIterator(const MessageIterator&);
    MessageIterator& operator=(const MessageIterator&);

  public:
    MessageIterator(const Event& event);
        // Construct a forward iterator to iterate over the message in
        // the specified 'event' object. The MessageIterator is
        // created in a state where next() must be called to advance
        // it to the first item.

    ~MessageIterator();
        // Destructor.

    // MANIPULATORS

    bool next();
        // Attempts to advance this MessageIterator to the next
        // Message in this Event. Returns 0 on success and non-zero if
        // there are no more messages. After next() returns 0
        // isValid() returns true, even if called repeatedly until the
        // next call to next(). After next() returns non-zero then
        // isValid() always returns false.

    // ACCESSORS

    bool isValid() const;
        // Returns true if this iterator is currently positioned on a
        // valid Message.  Returns false otherwise.

    Message message(bool createClonable=false) const;
        // Returns the Message at the current position of this iterator. If the
        // specified 'createClonable' flag is set, the internal handle of the
        // message returned is added a reference and the message can outlive
        // the call to next(). If the 'createClonable' flag is set to false,
        // the use of message outside the scope of the iterator or after the
        // next() call is undefined.
        // The behavior is undefined if isValid() returns false.
};

//=============================================================================
//                            FUNCTION DEFINITIONS
//=============================================================================

                            // -----------
                            // class Event
                            // -----------


Event::Event()
: d_impl_p(0)
{
}


Event::Event(blpapi_Event_t *handle)
: d_impl_p(handle)
{
}


Event::Event(const Event& original)
: d_impl_p(original.d_impl_p)
{
    if (d_impl_p) {
        blpapi_Event_addRef(d_impl_p);
    }
}


Event::~Event()
{
    if (d_impl_p) {
        blpapi_Event_release(d_impl_p);
    }
}


Event& Event::operator=(const Event& rhs)
{
    if (this == &rhs) {
        return *this;
    }
    if (d_impl_p) {
        blpapi_Event_release(d_impl_p);
    }
    d_impl_p = rhs.d_impl_p;
    if (d_impl_p) {
        blpapi_Event_addRef(d_impl_p);
    }
    return *this;
}


Event::EventType Event::eventType() const
{
    return (EventType) blpapi_Event_eventType(d_impl_p);
}


bool Event::isValid() const
{
    return d_impl_p ? true : false;
}


blpapi_Event_t* Event::impl() const
{
    return d_impl_p;
}

                            // ----------------
                            // class EventQueue
                            // ----------------


EventQueue::EventQueue()
{
    d_handle_p = blpapi_EventQueue_create();
}


EventQueue::~EventQueue()
{
    blpapi_EventQueue_destroy(d_handle_p);
}


Event EventQueue::nextEvent(int timeout)
{
    return blpapi_EventQueue_nextEvent(d_handle_p, timeout);
}


int EventQueue::tryNextEvent(Event *event)
{
    blpapi_Event_t *impl;
    int ret = blpapi_EventQueue_tryNextEvent(d_handle_p, &impl);
    if(0 == ret) {
        *event = Event(impl);
    }
    return ret;
}


void EventQueue::purge()
{
    blpapi_EventQueue_purge(d_handle_p);
}


blpapi_EventQueue_t* EventQueue::handle() const
{
    return d_handle_p;
}

                            // ---------------------
                            // class MessageIterator
                            // ---------------------


MessageIterator::MessageIterator(const Event& event)
: d_impl_p(0)
, d_current_p(0)
{
    d_impl_p = blpapi_MessageIterator_create(event.impl());
}


MessageIterator::~MessageIterator()
{
    blpapi_MessageIterator_destroy(d_impl_p);
}


bool MessageIterator::next()
{
    return !blpapi_MessageIterator_next(d_impl_p, &d_current_p);
}


bool MessageIterator::isValid() const
{
    return d_current_p ? true : false;
}


Message MessageIterator::message(bool createClonable) const
{
    if (createClonable) {
        BLPAPI_CALL_MESSAGE_ADDREF(d_current_p);
    }
    return Message(d_current_p, createClonable);
}


}  // close namespace blpapi
}  // close namespace BloombergLP

#endif // #ifdef __cplusplus
#endif // #ifndef INCLUDED_BLPAPI_EVENT



    // =============

struct  Element {
    // Element represents an item in a message.
    // An Element can represent: a single value of any data type supported by
    blpapi_Element_t *d_handle_p;
    // FREE OPERATORS
    Element()
    : d_handle_p(0)
    {
    }

    Element(blpapi_Element_t *newHandle)
    : d_handle_p(newHandle)
    {
    }

    void rebind(blpapi_Element_t *element)
    {
        d_handle_p = element;
    }

    void setElement(string elementName, bool value)
    {
        blpapi_Element_setElementBool(d_handle_p, elementName, 0, value ? 1 : 0));
    }

    void setElement(T)(string elementName, T value)
    {
        blpapi_Element_setElementChar(d_handle_p, elementName, 0 , value));
    }

    void setElement(string elementName, const Datetime* value)
    {
        BLPAPI_CALL_ELEMENT_SETELEMENTHIGHPRECISIONDATETIME(d_handle_p, elementName, 0, &value.rawHighPrecisionValue());
    }


    void setValue(T)(T value, size_t index)
    {
        blpapi_Element_setValueBool(d_handle_p, value, index));
    }


    void setValue(const Datetime* value, size_t index)
    {
        BLPAPI_CALL_ELEMENT_SETVALUEHIGHPRECISIONDATETIME(d_handle_p, &value.rawHighPrecisionValue(), index)
    }


    void appendValue(T)(T value)
    {
        blpapi_Element_setValueBool(d_handle_p, value, BLPAPI_ELEMENT_INDEX_END));
    }


    void appendValue(const Datetime* value)
    {
        BLPAPI_CALL_ELEMENT_SETVALUEHIGHPRECISIONDATETIME(d_handle_p, &value.rawHighPrecisionValue(), BLPAPI_ELEMENT_INDEX_END)
        );
    }

    Element appendElement()
    {
        blpapi_Element_t *appendedElement;
        blpapi_Element_appendElement(d_handle_p, &appendedElement));
        return Element(appendedElement);
    }


    Element setChoice(T)(T selectionName)
    {
        blpapi_Element_t *resultElement; 
        blpapi_Element_setChoice(d_handle_p, &resultElement, selectionName, 0, 0);
        return Element(resultElement);
    }

    blpapi_Element_t* handle()
    {
        return d_handle_p;
    }


    Name name() const
    {
        return blpapi_Element_name(d_handle_p);
    }


    int getElement(Element* element, const char *nameString) const
    {
        blpapi_Element_t *fldt;
        int rc = blpapi_Element_getElement(d_handle_p, &fldt, nameString, 0);
        if (!rc) {
            element.rebind(fldt);
        }

        return rc;
    }


    int getElement(Element* element, const Name& elementName) const
    {
        blpapi_Element_t *fldt;
        int rc
            = blpapi_Element_getElement(d_handle_p, &fldt, 0, elementName.impl());
        if (!rc) {
            element.rebind(fldt);
        }

        return rc;
    }


    int getElement(Element *element, size_t position) const
    {
        blpapi_Element_t *fldt;
        int rc = blpapi_Element_getElementAt(d_handle_p, &fldt, position);
        if (!rc) {
            element.rebind(fldt);
        }

        return rc;
    }


    int datatype() const
    {
        return blpapi_Element_datatype(d_handle_p);
    }


    bool isComplexType() const
    {
        return blpapi_Element_isComplexType(d_handle_p) ? true : false;
    }


    bool isArray() const
    {
        return blpapi_Element_isArray(d_handle_p) ? true : false;
    }


    bool isNull() const
    {
        return blpapi_Element_isNull(d_handle_p) ? true : false;
    }


    bool isReadOnly() const
    {
        return blpapi_Element_isReadOnly(d_handle_p) ? true : false;
    }


    SchemaElementDefinition elementDefinition() const
    {
        return blpapi_Element_definition(d_handle_p);
    }


    size_t numValues() const
    {
        return blpapi_Element_numValues(d_handle_p);
    }


    size_t numElements() const
    {
        return blpapi_Element_numElements(d_handle_p);
    }


    bool isValid() const
    {
        return d_handle_p  ? true : false;
    }


    bool isNullValue(size_t position) const
    {
        int rc = blpapi_Element_isNullValue(d_handle_p, position);
        if (rc != 0 && rc != 1) {
            throwOnError(rc);
        }
        return rc ? true : false;
    }


    bool hasElement(const char* nameString,
                                    bool excludeNullElements) const
    {
        if (excludeNullElements) {
            return (blpapi_Element_hasElementEx(d_handle_p,
                  nameString, 0, excludeNullElements, 0) ? true : false);
        }
        return blpapi_Element_hasElement(d_handle_p, nameString, 0) ? true : false;
    }


    bool hasElement(const Name& elementName,
                             bool excludeNullElements) const
    {
        if (excludeNullElements) {
            return (blpapi_Element_hasElementEx(d_handle_p, 0,
                    elementName.impl(), excludeNullElements, 0) ? true : false);
        }
        return blpapi_Element_hasElement(d_handle_p, 0, elementName.impl())
                                         ? true
                                         : false;
    }


    Element getElement(const Name& elementName) const
    {
        blpapi_Element_t *fldt;
        throwOnError(
                    blpapi_Element_getElement(
                        d_handle_p,
                        &fldt,
                        0,
                        elementName.impl()));
        return Element(fldt);
    }


    Element getElement(const char* elementName) const
    {
        blpapi_Element_t *fldt;
        throwOnError(
                blpapi_Element_getElement(
                    d_handle_p,
                    &fldt,
                    elementName,
                    0));
        return Element(fldt);
    }


    Element getElement(size_t position) const
    {
        blpapi_Element_t *element;
        throwOnError(
                blpapi_Element_getElementAt(
                    d_handle_p,
                    &element,
                    position));
        return Element(element);
    }


    int getValueAs(bool* buffer, size_t index) const
    {
        blpapi_Bool_t tmp=false;

        int res = blpapi_Element_getValueAsBool(d_handle_p, &tmp, index);
        *buffer = tmp ? true : false;
        return res;
    }


    int getValueAs(char* buffer, size_t index) const
    {
        return blpapi_Element_getValueAsChar(d_handle_p, buffer, index);
    }


    int getValueAs(Int32* buffer, size_t index) const
    {
        return blpapi_Element_getValueAsInt32(d_handle_p, buffer, index);
    }


    int getValueAs(Int64* buffer, size_t index) const
    {
        return blpapi_Element_getValueAsInt64(d_handle_p,buffer, index);
    }


    int getValueAs(Float32* buffer, size_t index) const
    {
        return blpapi_Element_getValueAsFloat32(d_handle_p,buffer, index);
    }


    int getValueAs(Float64* buffer, size_t index) const
    {
        return blpapi_Element_getValueAsFloat64(d_handle_p,buffer, index);
    }


    int getValueAs(Datetime* buffer, size_t index) const
    {
        BLPAPI_CALL_ELEMENT_GETVALUEASHIGHPRECISIONDATETIME(d_handle_p,
                                                            buffer,
                                                            index);
    }


    int getValueAs(std::string* result, size_t index) const
    {
        const char* buffer;
        int rc = blpapi_Element_getValueAsString(d_handle_p,&buffer, index);
        if (!rc) {
            *result = buffer;
        }
        return rc;
    }


    int getValueAs(Element *buffer, size_t index) const
    {
        return blpapi_Element_getValueAsElement(
                d_handle_p,
                &buffer.d_handle_p,
                index);
    }


    int getValueAs(Name *buffer, size_t index) const
    {
        blpapi_Name_t* tmpName;
        int res = blpapi_Element_getValueAsName(d_handle_p,
                                                &tmpName,
                                                index);
        if (!res) {
            *buffer = Name(tmpName);
        }
        return res;
    }


    bool getValueAsBool(size_t index) const
    {
        bool value;
        throwOnError(getValueAs(&value, index));
        return value;
    }


    char getValueAsChar(size_t index) const
    {
        char value;
        throwOnError(getValueAs(&value, index));
        return value;
    }


    Int32 getValueAsInt32(size_t index) const
    {
        Int32 value;
        throwOnError(getValueAs(&value, index));
        return value;
    }


    Int64 getValueAsInt64(size_t index) const
    {
        Int64 value;
        throwOnError(getValueAs(&value, index));
        return value;
    }


    Float32 getValueAsFloat32(size_t index) const
    {
        Float32 value;
        throwOnError(getValueAs(&value, index));
        return value;
    }


    Float64 getValueAsFloat64(size_t index) const
    {
        Float64 value;
        throwOnError(getValueAs(&value, index));
        return value;
    }


    Datetime getValueAsDatetime(size_t index) const
    {
        Datetime value;
        throwOnError(getValueAs(&value, index));
        return value;
    }


    const char* getValueAsString(size_t index) const
    {
        const char* tmpStringBuffer;
        throwOnError(blpapi_Element_getValueAsString(
                                    d_handle_p,
                                    &tmpStringBuffer,
                                    index));
        return tmpStringBuffer;
    }


    Element getValueAsElement(size_t index) const
    {
        blpapi_Element_t *element;
        throwOnError(blpapi_Element_getValueAsElement(d_handle_p,
                                                                     &element,
                                                                     index));
        return Element(element);
    }


    Name getValueAsName(size_t index) const
    {
        blpapi_Name_t *nameValue;
        throwOnError(blpapi_Element_getValueAsName(d_handle_p,
                                                                  &nameValue,
                                                                  index));
        return nameValue;
    }


    Element getChoice() const
    {
        blpapi_Element_t *element;
        throwOnError(blpapi_Element_getChoice(d_handle_p,
                                                             &element));
        return Element(element);
    }


    bool getElementAsBool(const char* elementName) const
    {
        return getElement(elementName).getValueAsBool();
    }


    bool getElementAsBool(const Name& elementName) const
    {
        return getElement(elementName).getValueAsBool();
    }


    char getElementAsChar(const char* elementName) const
    {
        return getElement(elementName).getValueAsChar();
    }


    char getElementAsChar(const Name& elementName) const
    {
        return getElement(elementName).getValueAsChar();
    }


    Int32 getElementAsInt32(const char* elementName) const
    {
        return getElement(elementName).getValueAsInt32();
    }


    Int32 getElementAsInt32(const Name& elementName) const
    {
        return getElement(elementName).getValueAsInt32();
    }


    Int64 getElementAsInt64(const char* elementName) const
    {
        return getElement(elementName).getValueAsInt64();
    }


    Int64 getElementAsInt64(const Name& elementName) const
    {
        return getElement(elementName).getValueAsInt64();
    }


    Float32 getElementAsFloat32(const char* elementName) const
    {
        return getElement(elementName).getValueAsFloat32();
    }


    Float32 getElementAsFloat32(const Name& elementName) const
    {
        return getElement(elementName).getValueAsFloat32();
    }


    Float64 getElementAsFloat64(const char* elementName) const
    {
        return getElement(elementName).getValueAsFloat64();
    }


    Float64 getElementAsFloat64(const Name& elementName) const
    {
        return getElement(elementName).getValueAsFloat64();
    }


    Datetime getElementAsDatetime(const char* elementName) const
    {
        return getElement(elementName).getValueAsDatetime();
    }


    Datetime getElementAsDatetime(const Name& elementName) const
    {
        return getElement(elementName).getValueAsDatetime();
    }


    const char* getElementAsString(const char* elementName) const
    {
        return getElement(elementName).getValueAsString();
    }


    const char* getElementAsString(const Name& elementName) const
    {
        return getElement(elementName).getValueAsString();
    }


    Name getElementAsName(const char* elementName) const
    {
        return getElement(elementName).getValueAsName();
    }


    Name getElementAsName(const Name& elementName) const
    {
        return getElement(elementName).getValueAsName();
    }


    const blpapi_Element_t* handle() const
    {
        return d_handle_p;
    }


    toString()
    std::ostream& print(
            std::ostream& stream,
            int level,
            int spacesPerLevel) const
    {
        blpapi_Element_print(d_handle_p,
                             StreamProxyOstream::writeToStream,
                             &stream,
                             level,
                             spacesPerLevel);
        return stream;
    }


    std::ostream& operator<<(std::ostream& stream, const Element& element)
    {
        element.print(stream, 0, -1);
        return stream;
    }

    }  // close namespace blpapi
    }  // close namespace BloombergLP

    #endif // #ifdef __cplusplus
    #endif // #ifndef INCLUDED_BLPAPI_ELEMENT




    class Datetime {
        // Represents a date and/or time.
        //
        // Datetime can represent a date and/or a time or any combination of the
        // components of a date and time.  The value is represented as eight parts
        // which can be set or queried independently.
        //
        // These parts are: year; month (from January as 1 to December as 12); day
        // (of month, from 1 to 31); hour (from 0 to 23); minute (0 to 59); second
        // (0 to 59); fraction-of-second (logically representing arbitrary
        // precision, with the current interface providing picosecond resolution);
        // and offset (time zone as minutes ahead of UTC).
        //
        // Methods are provided to set and query the parts individually and in
        // groups, e.g. 'setDate()' and 'setTime()'.  It is also possible to
        // determine which parts of the 'Datetime' have been set (via the 'parts()'
        // method).

        blpapi_HighPrecisionDatetime_t d_value;

        static bool isLeapYear(int year);

        struct TimeTag {};
        Datetime(unsigned hours,
                 unsigned minutes,
                 unsigned seconds,
                 TimeTag);
            // Create a 'Datetime' object having the value representing the
            // specified 'hours', 'minutes', and 'seconds'.  The
            // behavior is undefined unless 'hours', 'minutes', and 'seconds'
            // represent a valid time as specified by the 'isValidTime' function.
            // The resulting 'Datetime' object has the parts specified by 'TIME'
            // set, and all other parts unset.  In particular, the 'FRACSECONDS'
            // part is unset.
            // Note that the final 'TimeTag' parameter is used purely to
            // disambiguate this constructor from that for year, month, and day.
            // A constuctor for 4 PM would be written as follows:
            //..
            //  Datetime dt = Datetime(16, 0, 0, TimeTag());
            //..
            // Note that this constructor is intended for internal use only; client
            // code should use the 'createTime' interface.

      public:
        struct Milliseconds {
            int d_msec;
            explicit Milliseconds(int milliseconds);
                // The behavior is undefined unless '0 <= milliseconds < 1000'.
        };
        struct Microseconds {
            int d_usec;
            explicit Microseconds(int microseconds);
                // The behavior is undefined unless
                // '0 <= microseconds < 1,000,000'.
        };
        struct Nanoseconds {
            int d_nsec;
            explicit Nanoseconds(int nanoseconds);
                // The behavior is undefined unless
                // '0 <= nanoseconds < 1,000,000,000'.
        };
        struct Picoseconds {
            long long d_psec;
            explicit Picoseconds(long long picoseconds);
                // The behavior is undefined unless
                // '0 <= picoseconds < 1,000,000,000,000'.
        };
        struct Offset {
            short d_minutesAheadOfUTC;
            explicit Offset(short minutesAheadOfUTC);
                // The behavior is undefined unless
                // '-840 <= minutesAheadOfUTC <= 840'.
        };

        static bool isValidDate(int year, int month, int day);
            // Return 'true' if the specified 'year', 'month', and 'day' represent
            // a valid calendar date, and 'false' otherwise.  Note that many
            // functions within 'Datetime' provide defined behavior only when valid
            // dates are provided as arguments.

        static bool isValidTime(int          hours,
                                int          minutes,
                                int          seconds);
        static bool isValidTime(int          hours,
                                int          minutes,
                                int          seconds,
                                int          milliSeconds);
        static bool isValidTime(int          hours,
                                int          minutes,
                                int          seconds,
                                Milliseconds fractionOfSecond);
        static bool isValidTime(int          hours,
                                int          minutes,
                                int          seconds,
                                Microseconds fractionOfSecond);
        static bool isValidTime(int          hours,
                                int          minutes,
                                int          seconds,
                                Nanoseconds  fractionOfSecond);
        static bool isValidTime(int          hours,
                                int          minutes,
                                int          seconds,
                                Picoseconds  fractionOfSecond);
            // Return 'true' if the specified 'hours', 'minutes', 'seconds', and
            // (optionally specified) 'milliseconds' or 'fractionOfSecond'
            // represent a valid time of day, and 'false' otherwise.  Note that
            // many functions within 'Datetime' provide defined behavior only when
            // valid times are provided as arguments.

        // CREATORS
        static Datetime createDatetime(unsigned year,
                                       unsigned month,
                                       unsigned day,
                                       unsigned hours,
                                       unsigned minutes,
                                       unsigned seconds);
            // Create a 'Datetime' object having the value representing the
            // specified 'year', 'month', 'day', 'hours', 'minutes', and 'seconds'
            // parts.  The behavior is undefined unless 'year', 'month', and 'day'
            // represent a valid date as specified by the 'isValidDate' function,
            // and 'hours', 'minutes', and 'seconds' represent a valid time as
            // specified by the 'isValidTime' function.  The resulting 'Datetime'
            // object has the parts specified by 'DATE' and 'TIME' set, and the
            // 'OFFSET' and 'FRACSECONDS' parts unset.

        static Datetime createDatetime(unsigned year,
                                       unsigned month,
                                       unsigned day,
                                       unsigned hours,
                                       unsigned minutes,
                                       unsigned seconds,
                                       Offset   offset);
            // Create a 'Datetime' object having the value representing the
            // specified 'year', 'month', 'day', 'hours', 'minutes', 'seconds', and
            // 'offset' parts.  The behavior is undefined unless 'year', 'month',
            // and 'day' represent a valid date as specified by the 'isValidDate'
            // function, and 'hours', 'minutes', and 'seconds' represent a valid
            // time as specified by the 'isValidTime' function.  The resulting
            // 'Datetime' object has the parts specified by 'DATE', 'TIME', and
            // 'OFFSET' set, and the 'FRACSECONDS' part unset.

        static Datetime createDatetime(unsigned     year,
                                       unsigned     month,
                                       unsigned     day,
                                       unsigned     hours,
                                       unsigned     minutes,
                                       unsigned     seconds,
                                       Milliseconds fractionOfSecond);
        static Datetime createDatetime(unsigned     year,
                                       unsigned     month,
                                       unsigned     day,
                                       unsigned     hours,
                                       unsigned     minutes,
                                       unsigned     seconds,
                                       Microseconds fractionOfSecond);
        static Datetime createDatetime(unsigned    year,
                                       unsigned    month,
                                       unsigned    day,
                                       unsigned    hours,
                                       unsigned    minutes,
                                       unsigned    seconds,
                                       Nanoseconds fractionOfSecond);
        static Datetime createDatetime(unsigned    year,
                                       unsigned    month,
                                       unsigned    day,
                                       unsigned    hours,
                                       unsigned    minutes,
                                       unsigned    seconds,
                                       Picoseconds fractionOfSecond);
            // Create a 'Datetime' object having the value representing the
            // specified 'year', 'month', 'day', 'hours', 'minutes', 'seconds', and
            // 'fractionOfSecond'.  The behavior is undefined unless 'year',
            // 'month', and 'day' represent a valid date as specified by the
            // 'isValidDate' function, and 'hours', 'minutes', 'seconds', and
            // 'fractionOfSecond' represent a valid time as specified by the
            // 'isValidTime' function.  The resulting 'Datetime' object has the
            // parts specified by 'DATE' and 'TIMEFRACSECONDS' set, and the
            // 'OFFSET' part unset.

        static Datetime createDatetime(unsigned     year,
                                       unsigned     month,
                                       unsigned     day,
                                       unsigned     hours,
                                       unsigned     minutes,
                                       unsigned     seconds,
                                       Milliseconds fractionOfSecond,
                                       Offset       offset);
        static Datetime createDatetime(unsigned     year,
                                       unsigned     month,
                                       unsigned     day,
                                       unsigned     hours,
                                       unsigned     minutes,
                                       unsigned     seconds,
                                       Microseconds fractionOfSecond,
                                       Offset       offset);
        static Datetime createDatetime(unsigned     year,
                                       unsigned     month,
                                       unsigned     day,
                                       unsigned     hours,
                                       unsigned     minutes,
                                       unsigned     seconds,
                                       Nanoseconds  fractionOfSecond,
                                       Offset       offset);
        static Datetime createDatetime(unsigned     year,
                                       unsigned     month,
                                       unsigned     day,
                                       unsigned     hours,
                                       unsigned     minutes,
                                       unsigned     seconds,
                                       Picoseconds  fractionOfSecond,
                                       Offset       offset);
            // Create a 'Datetime' object having the value representing the
            // specified 'year', 'month', 'day', 'hours', 'minutes', 'seconds',
            // 'fractionOfSecond', and 'offset'.  The behavior is undefined unless
            // 'year', 'month', and 'day' represent a valid date as specified by
            // the 'isValidDate' function, and 'hours', 'minutes', 'seconds', and
            // 'fractionOfSecond' represent a valid time as specified by the
            // 'isValidTime' function.  The resulting 'Datetime' object has all
            // parts set.

        static Datetime createDate(unsigned year,
                                   unsigned month,
                                   unsigned day);
            // Create a 'Datetime' object having the value representing the
            // specified 'year', 'month', and 'day'.  The behavior is undefined
            // unless 'year', 'month', and 'day' represent a valid date as
            // specified by the 'isValidDate' function.  The resulting 'Datetime'
            // object has the parts specified by 'DATE' set, and all other parts
            // unset.

        static Datetime createTime(unsigned hours,
                                   unsigned minutes,
                                   unsigned seconds);
            // Create a 'Datetime' object having the value representing the
            // specified 'hours', 'minutes', and 'seconds'.  The
            // behavior is undefined unless 'hours', 'minutes', and 'seconds'
            // represent a valid time as specified by the 'isValidTime' function.
            // The resulting 'Datetime' object has the parts specified by 'TIME'
            // set, and all other parts unset.  Note that the 'FRACSECONDS' part is
            // unset.

        static Datetime createTime(unsigned hours,
                                   unsigned minutes,
                                   unsigned seconds,
                                   Offset   offset);
            // Create a 'Datetime' object having the value representing the
            // specified 'hours', 'minutes', 'seconds', and 'offset'.  The
            // behavior is undefined unless 'hours', 'minutes', and 'seconds'
            // represent a valid time as specified by the 'isValidTime' function.
            // The resulting 'Datetime' object has the parts specified by 'TIME'
            // and 'OFFSET' set, and all other parts unset.  Note that the
            // 'FRACSECONDS' part is unset.

        static Datetime createTime(unsigned hours,
                                   unsigned minutes,
                                   unsigned seconds,
                                   unsigned milliseconds);
            // Create a 'Datetime' object having the value representing the
            // specified 'hours', 'minutes', 'seconds', and 'milliseconds'.  The
            // behavior is undefined unless 'hours', 'minutes', 'seconds', and
            // 'milliseconds' represent a valid time as specified by the
            // 'isValidTime' function.  The resulting 'Datetime' object has the
            // parts specified by 'TIMEFRACSECONDS' set, and all other parts unset.

        static Datetime createTime(unsigned hours,
                                   unsigned minutes,
                                   unsigned seconds,
                                   unsigned milliseconds,
                                   Offset   offset);
            // Create a 'Datetime' object having the value representing the
            // specified 'hours', 'minutes', 'seconds', 'milliseconds', and
            // 'offset'.  The behavior is undefined unless 'hours', 'minutes',
            // 'seconds', and 'milliseconds' represent a valid time as specified by
            // the 'isValidTime' function.  The resulting 'Datetime' object has the
            // parts specified by 'TIMEFRACSECONDS' and 'OFFSET' set, and all other
            // parts unset.

        static Datetime createTime(unsigned     hours,
                                   unsigned     minutes,
                                   unsigned     seconds,
                                   Milliseconds fractionOfSecond);
        static Datetime createTime(unsigned     hours,
                                   unsigned     minutes,
                                   unsigned     seconds,
                                   Microseconds fractionOfSecond);
        static Datetime createTime(unsigned     hours,
                                   unsigned     minutes,
                                   unsigned     seconds,
                                   Nanoseconds  fractionOfSecond);
        static Datetime createTime(unsigned     hours,
                                   unsigned     minutes,
                                   unsigned     seconds,
                                   Picoseconds  fractionOfSecond);
            // Create a 'Datetime' object having the value representing the
            // specified 'hours', 'minutes', 'seconds', and 'fractionOfSecond'.
            // The behavior is undefined unless 'hours', 'minutes', 'seconds', and
            // 'fractionOfSecond' represent a valid time as specified by the
            // 'isValidTime' function.  The resulting 'Datetime' object has the
            // parts specified by 'TIMEFRACSECONDS' set, and all other
            // parts unset.

        static Datetime createTime(unsigned     hours,
                                   unsigned     minutes,
                                   unsigned     seconds,
                                   Milliseconds fractionOfSecond,
                                   Offset       offset);
        static Datetime createTime(unsigned     hours,
                                   unsigned     minutes,
                                   unsigned     seconds,
                                   Microseconds fractionOfSecond,
                                   Offset       offset);
        static Datetime createTime(unsigned     hours,
                                   unsigned     minutes,
                                   unsigned     seconds,
                                   Nanoseconds  fractionOfSecond,
                                   Offset       offset);
        static Datetime createTime(unsigned     hours,
                                   unsigned     minutes,
                                   unsigned     seconds,
                                   Picoseconds  fractionOfSecond,
                                   Offset       offset);
            // Create a 'Datetime' object having the value representing the
            // specified 'hours', 'minutes', 'seconds', 'fractionOfSecond', and
            // 'offset'.  The behavior is undefined unless 'hours', 'minutes',
            // 'seconds', and 'fractionOfSecond' represent a valid time as
            // specified by the 'isValidTime' function.  The resulting 'Datetime'
            // object has the parts specified by 'TIMEFRACSECONDS' and 'OFFSET'
            // set, and all other parts unset.

        Datetime();
            // Construct a 'Datetime' object with all parts unset.

        Datetime(const Datetime& original);
            // Copy constructor.

        Datetime(const blpapi_Datetime_t& rawValue);

        explicit Datetime(const blpapi_HighPrecisionDatetime_t& rawValue);

        Datetime(unsigned year,
                 unsigned month,
                 unsigned day,
                 unsigned hours,
                 unsigned minutes,
                 unsigned seconds);
            // Create a 'Datetime' object having the value representing the
            // specified 'year', 'month', 'day', 'hours', 'minutes', and 'seconds'
            // parts.  The behavior is undefined unless 'year', 'month', and 'day'
            // represent a valid date as specified by the 'isValidDate' function,
            // and 'hours', 'minutes', and 'seconds' represent a valid time as
            // specified by the 'isValidTime' function.  The resulting 'Datetime'
            // object has the parts specified by 'DATE' and 'TIME' set, and the
            // 'OFFSET' and 'FRACSECONDS' parts unset.
            // Use of this function is discouraged; use 'createDatetime' instead.

        Datetime(unsigned year,
                 unsigned month,
                 unsigned day,
                 unsigned hours,
                 unsigned minutes,
                 unsigned seconds,
                 unsigned milliseconds);
            // Create a 'Datetime' object having the value representing the
            // specified 'year', 'month', 'day', 'hours', 'minutes', 'seconds', and
            // 'milliseconds'.  The behavior is undefined unless 'year', 'month',
            // and 'day' represent a valid date as specified by the 'isValidDate'
            // function, and 'hours', 'minutes', 'seconds', and 'milliseconds'
            // represent a valid time as specified by the 'isValidTime' function.
            // The resulting 'Datetime' object has the parts specified by 'DATE'
            // and 'TIMEFRACSECONDS' set, and the 'OFFSET' part unset.
            // Use of this function is discouraged; use 'createDatetime' instead.

        Datetime(unsigned     year,
                 unsigned     month,
                 unsigned     day,
                 unsigned     hours,
                 unsigned     minutes,
                 unsigned     seconds,
                 Milliseconds fractionOfSecond);
        Datetime(unsigned     year,
                 unsigned     month,
                 unsigned     day,
                 unsigned     hours,
                 unsigned     minutes,
                 unsigned     seconds,
                 Microseconds fractionOfSecond);
        Datetime(unsigned    year,
                 unsigned    month,
                 unsigned    day,
                 unsigned    hours,
                 unsigned    minutes,
                 unsigned    seconds,
                 Nanoseconds fractionOfSecond);
        Datetime(unsigned    year,
                 unsigned    month,
                 unsigned    day,
                 unsigned    hours,
                 unsigned    minutes,
                 unsigned    seconds,
                 Picoseconds fractionOfSecond);
            // Create a 'Datetime' object having the value representing the
            // specified 'year', 'month', 'day', 'hours', 'minutes', 'seconds', and
            // 'fractionOfSecond'.  The behavior is undefined unless 'year',
            // 'month', and 'day' represent a valid date as specified by the
            // 'isValidDate' function, and 'hours', 'minutes', 'seconds', and
            // 'fractionOfSecond' represent a valid time as specified by the
            // 'isValidTime' function.  The resulting 'Datetime' object has the
            // parts specified by 'DATE' and 'TIMEFRACSECONDS' set, and the
            // 'OFFSET' part unset.
            // Use of these functions is discouraged; use 'createDatetime' instead.

        Datetime(unsigned year,
                 unsigned month,
                 unsigned day);
            // Create a 'Datetime' object having the value representing the
            // specified 'year', 'month', and 'day'.  The behavior is undefined
            // unless 'year', 'month', and 'day' represent a valid date as
            // specified by the 'isValidDate' function.  The resulting 'Datetime'
            // object has the parts specified by 'DATE' set, and all other parts
            // unset.
            // Note that constructing a 'Datetime' from three integers produces a
            // date; to create a time from hour, minute, and second (without the
            // fraction-of-second part unset) use the constructor taking a
            // 'TimeTag'.
            // Use of this function is discouraged; use 'createDate' instead.


        Datetime(unsigned hours,
                 unsigned minutes,
                 unsigned seconds,
                 unsigned milliseconds);
            // Create a 'Datetime' object having the value representing the
            // specified 'hours', 'minutes', 'seconds', and 'milliseconds'.  The
            // behavior is undefined unless 'hours', 'minutes', 'seconds', and
            // 'milliseconds' represent a valid time as specified by the
            // 'isValidTime' function.  The resulting 'Datetime' object has the
            // parts specified by 'TIMEFRACSECONDS' set, and all other parts unset.
            // Note that removing the final argument from a call to this function
            // results in a constructor creating a date, not a time.

        Datetime(unsigned     hours,
                 unsigned     minutes,
                 unsigned     seconds,
                 Milliseconds fractionOfSecond);
        Datetime(unsigned     hours,
                 unsigned     minutes,
                 unsigned     seconds,
                 Microseconds fractionOfSecond);
        Datetime(unsigned     hours,
                 unsigned     minutes,
                 unsigned     seconds,
                 Nanoseconds  fractionOfSecond);
        Datetime(unsigned     hours,
                 unsigned     minutes,
                 unsigned     seconds,
                 Picoseconds  fractionOfSecond);
            // Create a 'Datetime' object having the value representing the
            // specified 'hours', 'minutes', 'seconds', and 'fractionOfSecond'.
            // The behavior is undefined unless 'hours', 'minutes', 'seconds', and
            // 'fractionOfSecond' represent a valid time as specified by the
            // 'isValidTime' function.  The resulting 'Datetime' object has the
            // parts specified by 'TIMEFRACSECONDS' set, and all other parts unset.
            // Note that removing the final argument from a call to this function
            // results in a constructor creating a date, not a time.

        // MANIPULATORS

        Datetime& operator=(const Datetime& rhs);
            // Assignment operator.

        void setDate(unsigned year,
                     unsigned month,
                     unsigned day);
            // Set the 'DATE' parts of this 'Datetime' object to the specified
            // 'year', 'month', and 'day'.  The behavior is undefined unless
            // 'isValidDate(year, month, day)' would return 'true'.

        void setTime(unsigned hours,
                     unsigned minutes,
                     unsigned seconds);
            // Set the 'TIME' parts of this 'Datetime' object to the specified
            // 'hours', 'minutes', and 'seconds', and mark the 'FRACSECONDS' part
            // of this 'Datetime' as unset.  The behavior is undefined unless
            // 'isValidTime(hours, minutes, seconds)' would return 'true'.

        void setTime(unsigned hours,
                     unsigned minutes,
                     unsigned seconds,
                     unsigned milliseconds);
            // Set the 'TIMEFRACSECONDS' parts of this 'Datetime' object to the
            // specified 'hours', 'minutes', 'seconds', and 'milliseconds'.  The
            // behavior is undefined unless
            // 'isValidTime(hours, minutes, seconds, milliseconds)' would return
            // 'true'.

        void setTime(unsigned     hours,
                     unsigned     minutes,
                     unsigned     seconds,
                     Milliseconds fractionOfSecond);
        void setTime(unsigned     hours,
                     unsigned     minutes,
                     unsigned     seconds,
                     Microseconds fractionOfSecond);
        void setTime(unsigned    hours,
                     unsigned    minutes,
                     unsigned    seconds,
                     Nanoseconds fractionOfSecond);
        void setTime(unsigned    hours,
                     unsigned    minutes,
                     unsigned    seconds,
                     Picoseconds fractionOfSecond);
            // Set the 'TIMEFRACSECONDS' parts of this 'Datetime' object to the
            // specified 'hours', 'minutes', 'seconds', and 'fractionOfSecond'.
            // The behavior is undefined unless
            // 'isValidTime(hours, minutes, seconds, fractionOfSecond)' would
            // return 'true'.

        void setOffset(short minutesAheadOfUTC);
            // Set the 'OFFSET' (i.e. timezone) part of this 'Datetime' object to
            // the specified 'minutesAheadOfUTC'.
            // The behavior is undefined unless '-840 <= minutesAheadOfUTC <= 840'.

        void setYear(unsigned value);
            // Set the 'YEAR' part of this 'Datetime' object to the specified
            // 'value'.
            // The behavior is undefined unless '1 <= value <= 9999', and either
            // the 'MONTH' part is not set, the 'DAY' part is not set, or
            // 'isValidDate(value. this.month(), this.day()) == true'.

        void setMonth(unsigned value);
            // Set the 'MONTH' part of this 'Datetime' object to the specified
            // 'value'.
            // The behavior is undefined unless '1 <= value <= 12', and either the
            // 'DAY' part is not set, the 'YEAR' part is not set, or
            // 'isValidDate(this.year(). value, this.day()) == true'.

        void setDay(unsigned value);
            // Set the 'DAY' part of this 'Datetime' object to the specified
            // 'value'.
            // The behavior is undefined unless '1 <= value <= 31', and either the
            // 'MONTH' part is not set, the 'YEAR' part is not set, or
            // 'isValidDate(this.year(). this.month(), value) == true'.

        void setHours(unsigned value);
            // Set the 'HOURS' part of this 'Datetime' object to the specified
            // 'value'.
            // The behavior is undefined unless '0 <= value <= 23'.

        void setMinutes(unsigned value);
            // Set the 'MINUTES' part of this 'Datetime' object to the specified
            // 'value'.
            // The behavior is undefined unless '0 <= value <= 59'.

        void setSeconds(unsigned value);
            // Set the 'SECONDS' part of this 'Datetime' object to the specified
            // 'value'.
            // The behavior is undefined unless '0 <= value <= 59'.

        void setMilliseconds(unsigned milliseconds);
            // Set the 'FRACSECONDS' part of this 'Datetime' object to the
            // specified 'milliseconds'.
            // The behavior is undefined unless '0 <= value <= 999'.

        void setFractionOfSecond(Milliseconds value);
            // Set the 'FRACSECONDS' part of this 'Datetime' object to the
            // Set the fraction of a second of the value of this object to the
            // specified 'value'.  Note that the behavior is undefined unless
            // '0 <= value <= 999 ms'.

        void setFractionOfSecond(Microseconds value);
            // Set the 'FRACSECONDS' part of this 'Datetime' object to the
            // specified 'value'. Note that the behavior is undefined unless
            // '0 <= value <= 999,999 us'.

        void setFractionOfSecond(Nanoseconds value);
            // Set the 'FRACSECONDS' part of this 'Datetime' object to the
            // specified 'value'.  Note that the behavior is undefined unless
            // '0 <= value <= 999,999,999 ns'.

        void setFractionOfSecond(Picoseconds value);
            // Set the 'FRACSECONDS' part of this 'Datetime' object to the
            // specified 'value'.  Note that the behavior is undefined unless
            // '0 <= value <= 999,999,999,999 ps'.

        blpapi_Datetime_t& rawValue();
            // Return a (modifiable) reference to the millisecond-resolution C
            // struct underlying this object.  Behavior of the object is undefined
            // if the returned struct is modified concurrently with other non-const
            // methods of this object, or if the fields of the 'blpapi_Datetime_t'
            // are modified such that the 'isValid' methods of this class
            // would return 'false' when passed those fields of the struct whose
            // bits are set in the struct's 'parts' field.  Further, direct setting
            // of the 'FRACSECONDS' bit in the returned struct's 'parts' field will
            // cause this 'Datetime' object to compute its fraction-of-second part
            // not just from the struct's 'milliSeconds' field, but also from the
            // 'picoseconds' field of the the struct returned from
            // 'rawHighPrecisionValue()'; if neither that field nor this 'Datetime'
            // objects' fraction-of-second part have been initialized, then
            // the behavior of setting the 'FRACSECONDS' bit directly is undefined.

        blpapi_HighPrecisionDatetime_t& rawHighPrecisionValue();
            // Return a (modifiable) reference to the high-resolution C struct
            // underlying this object.  Behavior of the object is undefined if the
            // returned struct is modified concurrently with other non-const
            // methods of this object, or if the fields of the
            // 'blpapi_HighPrecisionDatetime_t' are modified such that the
            // 'isValid*' methods of this class would return 'false' when
            // passed those fields of the struct whose bits are set in the struct's
            // 'parts' field.

        // ACCESSORS
        bool hasParts(unsigned parts) const;
            // Return true if this 'Datetime' object has all of the specified
            // 'parts' set.  The 'parts' parameter must be constructed by or'ing
            // together values from the 'DatetimeParts' enum.

        unsigned parts() const;
            // Return a bitmask of all parts that are set in this 'Datetime'
            // object.  This can be compared to the values in the 'DatetimeParts'
            // enum using bitwise operations.

        unsigned year() const;
            // Return the year value of this 'Datetime' object.  The result is
            // undefined unless the 'YEAR' part of this object is set.

        unsigned month() const;
            // Return the month value of this 'Datetime' object.  The result is
            // undefined unless the 'MONTH' part of this object is set.

        unsigned day() const;
            // Return the day value of this 'Datetime' object.  The result is
            // undefined unless the 'DAY' part of this object is set.

        unsigned hours() const;
            // Return the hours value of this 'Datetime' object.  The result is
            // undefined unless the 'HOURS' part of this object is set.

        unsigned minutes() const;
            // Return the minutes value of this 'Datetime' object.  The result is
            // undefined unless the 'MINUTES' part of this object is set.

        unsigned seconds() const;
            // Return the seconds value of this 'Datetime' object.  The result is
            // undefined unless the 'SECONDS' part of this object is set.

        unsigned milliSeconds() const;
            // Return the milliseconds value of this 'Datetime' object.  The result
            // is undefined unless the 'FRACSECONDS' part of this object is set.
            // This function is deprecated; use 'milliseconds()' instead.

        unsigned milliseconds() const;
            // Return the number of (whole) milliseconds in the
            // fraction-of-a-second part of the value of this object.  The result
            // is undefined unless the 'FRACSECONDS' part of this object is set.

        unsigned microseconds() const;
            // Return the number of (whole) microseconds in the
            // fraction-of-a-second part of the value of this object.  The result
            // is undefined unless the 'FRACSECONDS' part of this object is set.

        unsigned nanoseconds() const;
            // Return the number of (whole) nanoseconds in the fraction-of-a-second
            // part of the value of this object.  The result is undefined unless
            // the 'FRACSECONDS' part of this object is set.

        unsigned long long picoseconds() const;
            // Return the number of (whole) picoseconds in the fraction-of-a-second
            // part of the value of this object.  The result is undefined unless
            // the 'FRACSECONDS' part of this object is set.

        short offset() const;
            // Return the number of minutes this 'Datetime' object is ahead of UTC.
            // The result is undefined unless the 'OFFSET' part of this object is
            // set.

        const blpapi_Datetime_t& rawValue() const;
            // Return a (read-only) reference to the millisecond-resolution C
            // struct underlying this object.

        const blpapi_HighPrecisionDatetime_t& rawHighPrecisionValue() const;
            // Return a (read-only) reference to the high-precision C struct
            // underlying this object.

        bool isValid() const;
            // Check whether the value of this 'Datetime' is valid.  The behaviour
            // is undefined unless this object represents a date (has YEAR, MONTH
            // and DAY part set) or time (has HOURS, MINUTES, SECONDS and
            // MILLISECONDS part set).  Note that in almost all cases where this
            // function returns 'false', prior member function calls have had
            // undefined behavior.
            // This function is deprecated; use 'isValidDate' and/or 'isValidTime'
            // directly instead.

        std::ostream& print(std::ostream& stream,
                            int           level = 0,
                            int           spacesPerLevel = 4) const;
            // Write the value of this object to the specified output 'stream' in
            // a human-readable format, and return a reference to 'stream'.
            // Optionally specify an initial indentation 'level', whose absolute
            // value is incremented recursively for nested objects.  If 'level' is
            // specified, optionally specify 'spacesPerLevel', whose absolute
            // value indicates the number of spaces per indentation level for this
            // and all of its nested objects.  If 'level' is negative, suppress
            // indentation of the first line.  If 'spacesPerLevel' is negative,
            // format the entire output on one line, suppressing all but the
            // initial indentation (as governed by 'level').  If 'stream' is not
            // valid on entry, this operation has no effect.  Note that this
            // human-readable format is not fully specified, and can change
            // without notice.

    };

    // FREE OPERATORS
    bool operator==(const Datetime& lhs, const Datetime& rhs);
        // Return 'true' if the specified 'lhs' and 'rhs' have the same value, and
        // 'false' otherwise.  Two 'Datetime' objects have the same value if they
        // have the same parts set, and the same values for each of those parts.

    bool operator!=(const Datetime& lhs, const Datetime& rhs);
        // Return 'true' if the specified 'lhs' and 'rhs' do not have the same
        // value, and 'false' otherwise.  Two 'Datetime' objects have the same
        // value if they have the same parts set, and the same values for each of
        // those parts.

    bool operator<(const Datetime& lhs, const Datetime& rhs);
    bool operator<=(const Datetime& lhs, const Datetime& rhs);
    bool operator>(const Datetime& lhs, const Datetime& rhs);
    bool operator>=(const Datetime& lhs, const Datetime& rhs);
        // Compare the specified 'lhs' and 'rhs'.  The ordering used is temporal,
        // with earlier moments comparing less than later moments, in the case that
        // 'lhs.parts() == rhs.parts()' and 'parts()' is one of 'DATE', 'TIME',
        // 'TIMEFRACSECONDS', 'DATE | TIME', and 'DATE | TIMEFRACSECONDS'; the
        // ordering in all other cases is unspecified, but guaranteed stable within
        // process.

    std::ostream& operator<<(std::ostream& stream, const Datetime& datetime);
        // Write the value of the specified 'datetime' object to the specified
        // output 'stream' in a single-line format, and return a reference to
        // 'stream'.  If 'stream' is not valid on entry, this operation has no
        // effect.  Note that this human-readable format is not fully specified,
        // can change without notice, and is logically equivalent to:
        //..
        //  print(stream, 0, -1);
        //..

                                // ===================
                                // struct DatetimeUtil
                                // ===================

    struct DatetimeUtil {
        // This provides a namespace for 'Datetime' utility functions.

        static Datetime fromTimePoint(const TimePoint& timePoint,
                                    Offset offset = Offset(0));
            // Create and return a 'Datetime' object having the value of the
            // specified 'timePoint' and the optionally specified timezone
            // 'offset', 0 by default. The resulting 'Datetime' object has the
            // parts specified by 'DATE', 'TIMEFRACSECONDS', and 'OFFSET' set.
    };

    // ============================================================================
    //                       FUNCTION DEFINITIONS
    // ============================================================================

                                // --------------
                                // class Datetime
                                // --------------


    bool isLeapYear(int y)
    {
        return 0 == y % 4 && (y <= 1752 || 0 != y % 100 || 0 == y % 400);
    }


    Datetime(unsigned newHours, unsigned newMinutes, unsigned newSeconds, TimeTag)
    {
        std::memset(&d_value, 0, sizeof(d_value));
        setTime(newHours, newMinutes, newSeconds);
    }


    Milliseconds::Milliseconds(int milliseconds)
    : d_msec(milliseconds)
    {
    }


    Microseconds::Microseconds(int microseconds)
    : d_usec(microseconds)
    {
    }


    Nanoseconds::Nanoseconds(int nanoseconds)
    : d_nsec(nanoseconds)
    {
    }


    Picoseconds::Picoseconds(long long picoseconds)
    : d_psec(picoseconds)
    {
    }


    Offset::Offset(short minutesAheadOfUTC)
    : d_minutesAheadOfUTC(minutesAheadOfUTC)
    {
    }


    bool isValidDate(int year,
                               int month,
                               int day)
    {
        if ((year <= 0) || (year > 9999) ||
            (month <= 0) || (month > 12) ||
            (day <= 0) || (day > 31) ) {
            return false;
        }
        if (day < 29) {
            return true;
        }
        if (year == 1752) {
            if (month == 9 && day > 2 && day < 14) {
                return false;
            }
        }
        switch (month) {
          case 1:
          case 3:
          case 5:
          case 7:
          case 8:
          case 10:
          case 12:
            return true;

          case 4:
          case 6:
          case 9:
          case 11: {
            if (day > 30) {
                return false;
            }
            else {
                return true;
            }
          }
          case 2: {
            if (isLeapYear(year)) {
                if (day > 29) {
                    return false;
                }
                else {
                    return true;
                }
            }
            else if (day > 28) {
                return false;
            }
            else {
                return true;
            }
          }
          default: {
            return true;
          }
        }
    }


    bool isValidTime(int hours, int minutes, int seconds)
    {
        return (hours >= 0) && (hours < 24)
            && (minutes >= 0) && (minutes < 60)
            && (seconds >= 0) && (seconds < 60);
    }


    bool isValidTime(int hours, int minutes, int seconds, int milliSeconds)
    {
        return (hours >= 0) && (hours < 24)
            && (minutes >= 0) && (minutes < 60)
            && (seconds >= 0) && (seconds < 60)
            && (milliSeconds >= 0) && (milliSeconds < 1000);
    }


    bool isValidTime(int hours, int minutes, int seconds, Milliseconds fractionOfSecond)
    {
        return isValidTime(hours, minutes, seconds, fractionOfSecond.d_msec);
    }


    bool isValidTime(int hours, int minutes, int seconds, Microseconds fractionOfSecond)
    {
        return (hours >= 0) && (hours < 24)
            && (minutes >= 0) && (minutes < 60)
            && (seconds >= 0) && (seconds < 60)
            && (fractionOfSecond.d_usec >= 0)
            && (fractionOfSecond.d_usec < 1000 * 1000);
    }

    bool isValidTime(int hours, int minutes, int seconds, Nanoseconds fractionOfSecond)
    {
        return (hours >= 0) && (hours < 24)
            && (minutes >= 0) && (minutes < 60)
            && (seconds >= 0) && (seconds < 60)
            && (fractionOfSecond.d_nsec >= 0)
            && (fractionOfSecond.d_nsec < 1000 * 1000 * 1000);
    }

    bool isValidTime(int hours, int minutes, int seconds, Picoseconds fractionOfSecond)
    {
        return (hours >= 0) && (hours < 24)
            && (minutes >= 0) && (minutes < 60)
            && (seconds >= 0) && (seconds < 60)
            && (fractionOfSecond.d_psec >= 0)
            && (fractionOfSecond.d_psec < 1000LL * 1000 * 1000 * 1000);
    }

    Datetime createDatetime(unsigned year, unsigned month, unsigned day, unsigned hours, unsigned minutes, unsigned seconds)
    {
        return Datetime(year, month, day, hours, minutes, seconds);
    }


    Datetime createDatetime(unsigned year, unsigned month, unsigned day, unsigned hours, unsigned minutes, unsigned seconds, Offset  offset)
    {
        Datetime dt(year, month, day, hours, minutes, seconds);
        dt.setOffset(offset.d_minutesAheadOfUTC);
        return dt;
    }


    Datetime createDatetime(unsigned year, unsigned month, unsigned day, unsigned hours, unsigned  minutes, unsigned seconds,
        Milliseconds fractionOfSecond)
    {
        return Datetime(year, month, day, hours, minutes, seconds, fractionOfSecond);
    }


    Datetime createDatetime(unsigned year, unsigned month, unsigned day, unsigned hours, unsigned minutes,
                                      unsigned     seconds, Microseconds fractionOfSecond)
    {
        return Datetime(year, month, day, hours, minutes, seconds, fractionOfSecond);
    }


    Datetime createDatetime(unsigned year, unsigned month, unsigned day, unsigned hours, unsigned minutes,
                                        unsigned seconds, Nanoseconds fractionOfSecond)
    {
        return Datetime(year, month, day, hours, minutes, seconds, fractionOfSecond);
    }


    Datetime createDatetime(unsigned year, unsigned month, unsigned day, unsigned hours, unsigned minutes,
                                      unsigned seconds, Picoseconds fractionOfSecond)
    {
        return Datetime(year, month, day, hours, minutes, seconds, fractionOfSecond);
    }


    Datetime createDatetime(unsigned year, unsigned month, unsigned day, unsigned hours, unsigned minutes, unsigned seconds,
                                      Milliseconds fractionOfSecond, Offset offset)
    {
        Datetime dt(year, month, day, hours, minutes, seconds, fractionOfSecond);
        dt.setOffset(offset.d_minutesAheadOfUTC);
        return dt;
    }

    Datetime createDatetime(unsigned year, uint month, unsigned  day, unsigned hours, unsigned minutes,
                                      unsigned seconds, Microseconds fractionOfSecond, Offset offset)
    {
        Datetime dt(year, month, day, hours, minutes, seconds, fractionOfSecond);
        dt.setOffset(offset.d_minutesAheadOfUTC);
        return dt;
    }

    Datetime createDatetime(uint year, uint month, uint day, uint hours, uint minutes, uint seconds, Nanoseconds fractionOfSecond,
                                      Offset offset)
    {
        Datetime dt(year, month, day, hours, minutes, seconds, fractionOfSecond);
        dt.setOffset(offset.d_minutesAheadOfUTC);
        return dt;
    }

    Datetime createDatetime(uint    year,
                                      uint    month,
                                      uint    day,
                                      uint    hours,
                                      uint    minutes,
                                      uint    seconds,
                                      Picoseconds  fractionOfSecond,
                                      Offset       offset)
    {
        Datetime dt(year, month, day, hours, minutes, seconds, fractionOfSecond);
        dt.setOffset(offset.d_minutesAheadOfUTC);
        return dt;
    }


    Datetime createDate(uintyear,
                                  uint month,
                                  uint day)
    {
        return Datetime(year, month, day);
    }


    Datetime createTime(uint hours,
                                  uint minutes,
                                  uint seconds)
    {
        return Datetime(hours, minutes, seconds, TimeTag());
    }


    Datetime createTime(uint hours,
                                  uint minutes,
                                  uint seconds,
                                  Offset   offset)
    {
        Datetime dt(hours, minutes, seconds, TimeTag());
        dt.setOffset(offset.d_minutesAheadOfUTC);
        return dt;
    }


    Datetime createTime(uint hours,
                                  uint minutes,
                                  uint seconds,
                                  uint milliseconds)
    {
        return Datetime(hours, minutes, seconds, milliseconds);
    }



    Datetime createTime(uint hours,
                                  uint minutes,
                                  uint seconds,
                                  uint milliseconds,
                                  Offset   offset)
    {
        Datetime dt(hours, minutes, seconds, milliseconds);
        dt.setOffset(offset.d_minutesAheadOfUTC);
        return dt;
    }


    Datetime createTime(uint     hours,
                                  uint     minutes,
                                  uint     seconds,
                                  Milliseconds fractionOfSecond)
    {
        return Datetime(hours, minutes, seconds, fractionOfSecond);
    }


    Datetime createTime(uint     hours,
                                  uint     minutes,
                                  uint     seconds,
                                  Microseconds fractionOfSecond)
    {
        return Datetime(hours, minutes, seconds, fractionOfSecond);
    }


    Datetime createTime(uint     hours,
                                  uint     minutes,
                                  uint     seconds,
                                  Nanoseconds  fractionOfSecond)
    {
        return Datetime(hours, minutes, seconds, fractionOfSecond);
    }


    Datetime createTime(uint     hours,
                                  uint     minutes,
                                  uint     seconds,
                                  Picoseconds  fractionOfSecond)
    {
        return Datetime(hours, minutes, seconds, fractionOfSecond);
    }


    Datetime createTime(uint     hours,
                                  uint     minutes,
                                  uint     seconds,
                                  Milliseconds fractionOfSecond,
                                  Offset       offset)
    {
        Datetime dt(hours, minutes, seconds, fractionOfSecond);
        dt.setOffset(offset.d_minutesAheadOfUTC);
        return dt;
    }


    Datetime createTime(uint     hours,
                                  uint     minutes,
                                  uint     seconds,
                                  Microseconds fractionOfSecond,
                                  Offset       offset)
    {
        Datetime dt(hours, minutes, seconds, fractionOfSecond);
        dt.setOffset(offset.d_minutesAheadOfUTC);
        return dt;
    }


    Datetime createTime(uint     hours,
                                  uint     minutes,
                                  uint     seconds,
                                  Nanoseconds  fractionOfSecond,
                                  Offset       offset)
    {
        Datetime dt(hours, minutes, seconds, fractionOfSecond);
        dt.setOffset(offset.d_minutesAheadOfUTC);
        return dt;
    }


    Datetime createTime(uint     hours,
                                  uint     minutes,
                                  uint     seconds,
                                  Picoseconds  fractionOfSecond,
                                  Offset       offset)
    {
        Datetime dt(hours, minutes, seconds, fractionOfSecond);
        dt.setOffset(offset.d_minutesAheadOfUTC);
        return dt;
    }



    Datetime()
    {
        std::memset(&d_value, 0, sizeof(d_value));
        d_value.datetime.year = 1;
        d_value.datetime.month = 1;
        d_value.datetime.day = 1;
    }


    Datetime(const Datetime& original)
    : d_value(original.d_value)
    {
    }


    Datetime(const blpapi_Datetime_t& newRawValue)
    {
        d_value.datetime = newRawValue;
        d_value.picoseconds = 0;
    }


    Datetime(const blpapi_HighPrecisionDatetime_t& newRawValue)
    : d_value(newRawValue)
    {
    }


    Datetime(uint newYear,
                       uint newMonth,
                       uint newDay,
                       uint newHours,
                       uint newMinutes,
                       uint newSeconds)
    {
        d_value.datetime.offset = 0;
        d_value.datetime.year = static_cast<blpapi_UInt16_t>(newYear);
        d_value.datetime.month = static_cast<blpapi_UChar_t>(newMonth);
        d_value.datetime.day = static_cast<blpapi_UChar_t>(newDay);
        d_value.datetime.hours = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds = 0;
        d_value.picoseconds = 0;
        d_value.datetime.parts = DatetimeParts::DATE | DatetimeParts::TIME;
    }


    Datetime(uint newYear,
                       uint newMonth,
                       uint newDay,
                       uint newHours,
                       uint newMinutes,
                       uint newSeconds,
                       uint newMilliSeconds)
    {
        d_value.datetime.offset = 0;
        d_value.datetime.year = static_cast<blpapi_UInt16_t>(newYear);
        d_value.datetime.month = static_cast<blpapi_UChar_t>(newMonth);
        d_value.datetime.day = static_cast<blpapi_UChar_t>(newDay);
        d_value.datetime.hours = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(newMilliSeconds);
        d_value.picoseconds = 0;
        d_value.datetime.parts
            = DatetimeParts::DATE | DatetimeParts::TIMEFRACSECONDS;
    }


    Datetime(uint     newYear,
                       uint     newMonth,
                       uint     newDay,
                       uint     newHours,
                       uint     newMinutes,
                       uint     newSeconds,
                       Milliseconds fractionOfSecond)
    {
        d_value.datetime.offset = 0;
        d_value.datetime.year = static_cast<blpapi_UInt16_t>(newYear);
        d_value.datetime.month = static_cast<blpapi_UChar_t>(newMonth);
        d_value.datetime.day = static_cast<blpapi_UChar_t>(newDay);
        d_value.datetime.hours = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(fractionOfSecond.d_msec);
        d_value.picoseconds = 0;
        d_value.datetime.parts
            = DatetimeParts::DATE | DatetimeParts::TIMEFRACSECONDS;
    }


    Datetime(uint     newYear,
                       uint     newMonth,
                       uint     newDay,
                       uint     newHours,
                       uint     newMinutes,
                       uint     newSeconds,
                       Microseconds fractionOfSecond)
    {
        d_value.datetime.offset = 0;
        d_value.datetime.year = static_cast<blpapi_UInt16_t>(newYear);
        d_value.datetime.month = static_cast<blpapi_UChar_t>(newMonth);
        d_value.datetime.day = static_cast<blpapi_UChar_t>(newDay);
        d_value.datetime.hours = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(fractionOfSecond.d_usec / 1000);
        d_value.picoseconds = (fractionOfSecond.d_usec % 1000) * 1000 * 1000;
        d_value.datetime.parts
            = DatetimeParts::DATE | DatetimeParts::TIMEFRACSECONDS;
    }


    Datetime(uint    newYear,
                       uint    newMonth,
                       uint    newDay,
                       uint    newHours,
                       uint    newMinutes,
                       uint    newSeconds,
                       Nanoseconds fractionOfSecond)
    {
        d_value.datetime.offset = 0;
        d_value.datetime.year = static_cast<blpapi_UInt16_t>(newYear);
        d_value.datetime.month = static_cast<blpapi_UChar_t>(newMonth);
        d_value.datetime.day = static_cast<blpapi_UChar_t>(newDay);
        d_value.datetime.hours = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(fractionOfSecond.d_nsec / 1000 / 1000);
        d_value.picoseconds = (fractionOfSecond.d_nsec % (1000 * 1000)) * 1000;
        d_value.datetime.parts
            = DatetimeParts::DATE | DatetimeParts::TIMEFRACSECONDS;
    }


    Datetime(uint    newYear,
                       uint    newMonth,
                       uint    newDay,
                       uint    newHours,
                       uint    newMinutes,
                       uint    newSeconds,
                       Picoseconds fractionOfSecond)
    {
        d_value.datetime.offset = 0;
        d_value.datetime.year = static_cast<blpapi_UInt16_t>(newYear);
        d_value.datetime.month = static_cast<blpapi_UChar_t>(newMonth);
        d_value.datetime.day = static_cast<blpapi_UChar_t>(newDay);
        d_value.datetime.hours = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds = static_cast<blpapi_UInt16_t>(
                                     fractionOfSecond.d_psec / 1000 / 1000 / 1000);
        d_value.picoseconds
            = static_cast<blpapi_UInt32_t>(
                  fractionOfSecond.d_psec % (1000 * 1000 * 1000));
        d_value.datetime.parts
            = DatetimeParts::DATE | DatetimeParts::TIMEFRACSECONDS;
    }


    Datetime(uint newYear,
                       uint newMonth,
                       uint newDay)
    {
        std::memset(&d_value, 0, sizeof(d_value));
        setDate(newYear, newMonth, newDay);
    }


    Datetime(uint newHours,
                       uint newMinutes,
                       uint newSeconds,
                       uint newMilliSeconds)
    {
        std::memset(&d_value, 0, sizeof(d_value));
        setTime(newHours, newMinutes, newSeconds, newMilliSeconds);
    }


    Datetime(uint     newHours,
                       uint     newMinutes,
                       uint     newSeconds,
                       Milliseconds fractionOfSecond)
    {
        std::memset(&d_value, 0, sizeof(d_value));
        setTime(newHours, newMinutes, newSeconds, fractionOfSecond);
    }


    Datetime(uint     newHours,
                       uint     newMinutes,
                       uint     newSeconds,
                       Microseconds fractionOfSecond)
    {
        std::memset(&d_value, 0, sizeof(d_value));
        setTime(newHours, newMinutes, newSeconds, fractionOfSecond);
    }


    Datetime(uint    newHours,
                       uint    newMinutes,
                       uint    newSeconds,
                       Nanoseconds fractionOfSecond)
    {
        std::memset(&d_value, 0, sizeof(d_value));
        setTime(newHours, newMinutes, newSeconds, fractionOfSecond);
    }


    Datetime(uint    newHours,
                       uint    newMinutes,
                       uint    newSeconds,
                       Picoseconds fractionOfSecond)
    {
        std::memset(&d_value, 0, sizeof(d_value));
        setTime(newHours, newMinutes, newSeconds, fractionOfSecond);
    }


    Datetime& operator=(const Datetime& rhs)
    {
        d_value = rhs.d_value;
        return *this;
    }


    void setDate(uint newYear,
                           uint newMonth,
                           uint newDay)
    {
        d_value.datetime.day   = static_cast<blpapi_UChar_t>(newDay);
        d_value.datetime.month = static_cast<blpapi_UChar_t>(newMonth);
        d_value.datetime.year  = static_cast<blpapi_UInt16_t>(newYear);
        d_value.datetime.parts |= DatetimeParts::DATE;
    }


    void setTime(uint newHours,
                           uint newMinutes,
                           uint newSeconds)
    {
        d_value.datetime.hours        = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes      = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds      = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds = 0;
        d_value.picoseconds           = 0;
        d_value.datetime.parts        =  (d_value.datetime.parts
                                        & ~DatetimeParts::FRACSECONDS)
                                        | DatetimeParts::TIME;
    }



    void setTime(uint newHours,
                           uint newMinutes,
                           uint newSeconds,
                           uint newMilliSeconds)
    {
        d_value.datetime.hours        = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes      = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds      = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(newMilliSeconds);
        d_value.picoseconds           = 0;
        d_value.datetime.parts       |= DatetimeParts::TIMEFRACSECONDS;
    }



    void setTime(uint     newHours,
                           uint     newMinutes,
                           uint     newSeconds,
                           Milliseconds fractionOfSecond)
    {
        d_value.datetime.hours        = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes      = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds      = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(fractionOfSecond.d_msec);
        d_value.picoseconds           = 0;
        d_value.datetime.parts       |= DatetimeParts::TIMEFRACSECONDS;
    }



    void setTime(uint     newHours,
                           uint     newMinutes,
                           uint     newSeconds,
                           Microseconds fractionOfSecond)
    {
        d_value.datetime.hours        = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes      = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds      = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(fractionOfSecond.d_usec / 1000);
        d_value.picoseconds           = fractionOfSecond.d_usec % 1000
                                                                * 1000
                                                                * 1000;
        d_value.datetime.parts       |= DatetimeParts::TIMEFRACSECONDS;
    }



    void setTime(uint    newHours,
                           uint    newMinutes,
                           uint    newSeconds,
                           Nanoseconds fractionOfSecond)
    {
        d_value.datetime.hours        = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes      = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds      = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(fractionOfSecond.d_nsec / 1000 / 1000);
        d_value.picoseconds           = fractionOfSecond.d_nsec % (1000 * 1000)
                                                                * 1000;
        d_value.datetime.parts       |= DatetimeParts::TIMEFRACSECONDS;
    }



    void setTime(uint    newHours,
                           uint    newMinutes,
                           uint    newSeconds,
                           Picoseconds fractionOfSecond)
    {
        d_value.datetime.hours        = static_cast<blpapi_UChar_t>(newHours);
        d_value.datetime.minutes      = static_cast<blpapi_UChar_t>(newMinutes);
        d_value.datetime.seconds      = static_cast<blpapi_UChar_t>(newSeconds);
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(fractionOfSecond.d_psec / 1000
                                                                   / 1000
                                                                   / 1000);
        d_value.picoseconds
            = static_cast<blpapi_UInt32_t>(
                  fractionOfSecond.d_psec % (1000 * 1000 * 1000));
        d_value.datetime.parts       |= DatetimeParts::TIMEFRACSECONDS;
    }



    void setOffset(short value)
    {
        d_value.datetime.offset = value;
        d_value.datetime.parts |= DatetimeParts::OFFSET;
    }



    void setYear(uint value)
    {
        d_value.datetime.year   = static_cast<blpapi_UInt16_t>(value);
        d_value.datetime.parts |= DatetimeParts::YEAR;
    }



    void setMonth(uint value)
    {
        d_value.datetime.month  = static_cast<blpapi_UChar_t>(value);
        d_value.datetime.parts |= DatetimeParts::MONTH;
    }



    void setDay(uint value)
    {
        d_value.datetime.day    = static_cast<blpapi_UChar_t>(value);
        d_value.datetime.parts |= DatetimeParts::DAY;
    }



    void setHours(uint value)
    {
        d_value.datetime.hours  = static_cast<blpapi_UChar_t>(value);
        d_value.datetime.parts |= DatetimeParts::HOURS;
    }



    void setMinutes(uint value)
    {
        d_value.datetime.minutes  = static_cast<blpapi_UChar_t>(value);
        d_value.datetime.parts   |= DatetimeParts::MINUTES;
    }



    void setSeconds(uint value)
    {
        d_value.datetime.seconds  = static_cast<blpapi_UChar_t>(value);
        d_value.datetime.parts   |= DatetimeParts::SECONDS;
    }



    void setMilliseconds(uint value)
    {
        d_value.datetime.milliSeconds = static_cast<blpapi_UInt16_t>(value);
        d_value.picoseconds           = 0;
        d_value.datetime.parts       |= DatetimeParts::FRACSECONDS;
    }


    void setFractionOfSecond(Milliseconds value)
    {
        d_value.datetime.milliSeconds = static_cast<blpapi_UInt16_t>(value.d_msec);
        d_value.picoseconds           = 0;
        d_value.datetime.parts       |= DatetimeParts::FRACSECONDS;
    }


    void setFractionOfSecond(Microseconds value)
    {
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(value.d_usec / 1000);
        d_value.picoseconds           = value.d_usec % 1000 * 1000 * 1000;
        d_value.datetime.parts       |= DatetimeParts::FRACSECONDS;
    }


    void setFractionOfSecond(Nanoseconds value)
    {
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(value.d_nsec / 1000 / 1000);
        d_value.picoseconds           = value.d_nsec % (1000 * 1000) * 1000;
        d_value.datetime.parts       |= DatetimeParts::FRACSECONDS;
    }


    void setFractionOfSecond(Picoseconds value)
    {
        d_value.datetime.milliSeconds
            = static_cast<blpapi_UInt16_t>(value.d_psec / 1000 / 1000 / 1000);
        d_value.picoseconds
            = static_cast<blpapi_UInt32_t>(value.d_psec % (1000 * 1000 * 1000));
        d_value.datetime.parts       |= DatetimeParts::FRACSECONDS;
    }


    blpapi_Datetime_t& rawValue()
    {
        return d_value.datetime;
    }


    blpapi_HighPrecisionDatetime_t& rawHighPrecisionValue()
    {
        return d_value;
    }


    bool hasParts(uint newParts) const
    {
        return newParts == (d_value.datetime.parts & newParts);
    }


    uint parts() const
    {
        return d_value.datetime.parts;
    }


    uint year() const
    {
        return d_value.datetime.year;
    }


    uint month() const
    {
        return d_value.datetime.month;
    }


    uint day() const
    {
        return d_value.datetime.day;
    }


    uint hours() const
    {
        return d_value.datetime.hours;
    }


    uint minutes() const
    {
        return d_value.datetime.minutes;
    }


    uint seconds() const
    {
        return d_value.datetime.seconds;
    }


    uint milliSeconds() const
    {
        return d_value.datetime.milliSeconds;
    }


    uint milliseconds() const
    {
        return d_value.datetime.milliSeconds;
    }


    uint microseconds() const
    {
        return   d_value.datetime.milliSeconds * 1000
               + d_value.picoseconds / 1000 / 1000;
    }


    uint nanoseconds() const
    {
        return   d_value.datetime.milliSeconds * 1000 * 1000
               + d_value.picoseconds / 1000;
    }


    uint long long picoseconds() const
    {
        return   d_value.datetime.milliSeconds * 1000LL * 1000 * 1000
               + d_value.picoseconds;
    }


    short offset() const
    {
        return d_value.datetime.offset;
    }


    const blpapi_Datetime_t& rawValue() const
    {
        return d_value.datetime;
    }


    const blpapi_HighPrecisionDatetime_t& rawHighPrecisionValue() const
    {
        return d_value;
    }


    bool isValid() const
    {
        if ( (hasParts(DatetimeParts::YEAR)
              || hasParts(DatetimeParts::MONTH)
              || hasParts(DatetimeParts::DAY) )
             && !isValidDate(year(), month(), day()) ) {
            return false;
        }
        if ( (hasParts(DatetimeParts::HOURS)
              || hasParts(DatetimeParts::MINUTES)
              || hasParts(DatetimeParts::SECONDS)
              || hasParts(DatetimeParts::MILLISECONDS))
             && !isValidTime(hours(), minutes(), seconds(), milliSeconds()) ) {
            return false;
        }
        if (   hasParts(DatetimeParts::FRACSECONDS)
            && (picoseconds() >= 1000LL * 1000 * 1000 * 1000)) {
            return false;
        }
        return true;
    }


    std::ostream& print(std::ostream& stream,
                                  int           level,
                                  int           spacesPerLevel) const
    {
        BLPAPI_CALL_HIGHPRECISIONDATETIME_PRINT(&d_value,
                                                StreamProxyOstream::writeToStream,
                                                &stream,
                                                level,
                                                spacesPerLevel);
        return stream;
    }


    bool operator==(const Datetime& lhs, const Datetime& rhs)
    {
        if (lhs.parts() == rhs.parts()) {
            return (BLPAPI_CALL_HIGHPRECISIONDATETIME_COMPARE(
                                                      &lhs.rawHighPrecisionValue(),
                                                      &rhs.rawHighPrecisionValue())
                    == 0);
        }
        return false;
    }



    bool operator!=(const Datetime& lhs, const Datetime& rhs)
    {
        return !(lhs == rhs);
    }


    bool operator<(const Datetime& lhs, const Datetime& rhs)
    {
        return (BLPAPI_CALL_HIGHPRECISIONDATETIME_COMPARE(
                                                  &lhs.rawHighPrecisionValue(),
                                                  &rhs.rawHighPrecisionValue())
                < 0);
    }


    bool operator<=(const Datetime& lhs, const Datetime& rhs)
    {
        return !(rhs < lhs);
    }


    bool operator>(const Datetime& lhs, const Datetime& rhs)
    {
        return rhs < lhs;
    }


    bool operator>=(const Datetime& lhs, const Datetime& rhs)
    {
        return !(lhs < rhs);
    }


    std::ostream& operator<<(std::ostream& stream, const Datetime& datetime)
    {
        return datetime.print(stream, 0, -1);
    }

                                // ------------------
                                // class DatetimeUtil
                                // ------------------


    Datetime DatetimeUtil::fromTimePoint(const TimePoint& timePoint,
                                         Offset offset)
    {
        blpapi_HighPrecisionDatetime_t highPrecisionDatetime;
        BLPAPI_CALL_HIGHPRECISIONDATETIME_FROMTIMEPOINT(
                          &highPrecisionDatetime,
                          &timePoint,
                          offset.d_minutesAheadOfUTC);
        return Datetime(highPrecisionDatetime);
    }

    }  // close namespace blpapi
    }  // close namespace BloombergLP

                 // ==============
                                 // class Constant
                                 // ==============
    class Constant {
        // Represents the value of a schema enumeration constant.
        //
        // Constants can be any of the following DataTypes: BOOL, CHAR, BYTE,
        // INT32, INT64, FLOAT32, FLOAT64, STRING, DATE, TIME, DATETIME. This class
        // provides access to not only the constant value, but also the symbolic
        // name, the description, and the status of the constant. It also provides
        // an interface for associating arbitrary user-defined data (specified as
        // a 'void*') with a 'Constant'.
        //
        // 'Constant' objects are read-only, with the exception of a single
        // 'void*' attribute for storing user data. 'Constant' objects have
        // *reference* *semantics* with respect to this user data field: calling
        // 'c.setUserData(void*)' modifies the user data associated with 'c', as
        // well as that associated with all copies of 'c'. As a result, functions
        // which set or read this field are *NOT* per-object thread-safe. Clients
        // must syncrhonize such operations across *all* *copies* of an object.
        //
        // Application clients need never create fresh 'Constant' objects directly;
        // applications will typically work with copies of objects returned by
        // other 'blpapi' components.

        blpapi_Constant_t *d_impl_p;

    Constant::Constant(blpapi_Constant_t *handle)
    : d_impl_p(handle)
    {
    }


    Constant::Constant(
        const Constant& original)
    : d_impl_p(original.d_impl_p)
    {
    }


    Name Constant::name() const
    {
        return blpapi_Constant_name(d_impl_p);
    }


    const char *Constant::description() const
    {
        return blpapi_Constant_description(d_impl_p);
    }


    int Constant::status() const
    {
        return blpapi_Constant_status(d_impl_p);
    }


    int Constant::datatype() const
    {
        return blpapi_Constant_datatype(d_impl_p);
    }


    const blpapi_Constant_t *Constant::impl() const
    {
        return d_impl_p;
    }


    int Constant::getValueAs(char *buffer) const
    {
        return blpapi_Constant_getValueAsChar(d_impl_p, buffer);
    }


    int Constant::getValueAs(Int32 *buffer) const
    {
        return blpapi_Constant_getValueAsInt32(d_impl_p, buffer);
    }


    int Constant::getValueAs(Int64 *buffer) const
    {
        return blpapi_Constant_getValueAsInt64(d_impl_p, buffer);
    }


    int Constant::getValueAs(Float32 *buffer) const
    {
        return blpapi_Constant_getValueAsFloat32(d_impl_p, buffer);
    }


    int Constant::getValueAs(Float64 *buffer) const
    {
        return blpapi_Constant_getValueAsFloat64(d_impl_p, buffer);
    }


    int Constant::getValueAs(Datetime *buffer) const
    {
        return blpapi_Constant_getValueAsDatetime(d_impl_p, &buffer.rawValue());
    }


    int Constant::getValueAs(std::string *result) const
    {
        const char *buffer;
        int rc = blpapi_Constant_getValueAsString(d_impl_p, &buffer);
        if (!rc) {
            *result = buffer;
        }
        return rc;
    }



    char Constant::getValueAsChar() const
    {
        char value;
        throwOnError(getValueAs(&value));
        return value;
    }


    Int32 Constant::getValueAsInt32() const
    {
        int value;
        throwOnError(getValueAs(&value));
        return value;
    }


    Int64 Constant::getValueAsInt64() const
    {
        Int64 value;
        throwOnError(getValueAs(&value));
        return value;
    }


    float Constant::getValueAsFloat32() const
    {
        Float32 value;
        throwOnError(getValueAs(&value));
        return value;
    }


    double Constant::getValueAsFloat64() const
    {
        Float64 value;
        throwOnError(getValueAs(&value));
        return value;
    }


    Datetime Constant::getValueAsDatetime() const
    {
        Datetime value;
        throwOnError(getValueAs(&value));
        return value;
    }


    std::string Constant::getValueAsString() const
    {
        std::string value;
        throwOnError(getValueAs(&value));
        return value;
    }


    void Constant::setUserData(void *newUserData)
    {
        blpapi_Constant_setUserData(d_impl_p, newUserData);
    }


    void *Constant::userData() const
    {
        return blpapi_Constant_userData(d_impl_p);
    }




    ConstantList::ConstantList(
            blpapi_ConstantList_t *handle)
    : d_impl_p(handle)
    {
    }


    ConstantList::ConstantList(
        const ConstantList& original)
    : d_impl_p(original.d_impl_p)
    {
    }


    Name ConstantList::name() const
    {
        return blpapi_ConstantList_name(d_impl_p);
    }


    const char* ConstantList::description() const
    {
        return blpapi_ConstantList_description(d_impl_p);
    }


    int ConstantList::status() const
    {
        return blpapi_ConstantList_status(d_impl_p);
    }


    int ConstantList::datatype() const
    {
        return blpapi_ConstantList_datatype(d_impl_p);
    }


    int ConstantList::numConstants() const
    {
        return blpapi_ConstantList_numConstants(d_impl_p);
    }


    Constant ConstantList::getConstant(const Name& constantName) const
    {
        return blpapi_ConstantList_getConstant(d_impl_p, 0, constantName.impl());
    }


    Constant ConstantList::getConstant(const char *nameString) const
    {
        return blpapi_ConstantList_getConstant(d_impl_p, nameString, 0 );
    }


    Constant ConstantList::getConstantAt(size_t index) const
    {
        return blpapi_ConstantList_getConstantAt(d_impl_p, index);
    }


    const blpapi_ConstantList_t *ConstantList::impl() const
    {
        return d_impl_p;
    }


    void ConstantList::setUserData(void *newUserData)
    {
        blpapi_ConstantList_setUserData(d_impl_p, newUserData);
    }


    void *ConstantList::userData() const
    {
        return blpapi_ConstantList_userData(d_impl_p);
    }

    }  // close namespace blpapi
    }  // close namespace BloombergLP


    struct AbstractSession {   
        blpapi_AbstractSession_t            *d_handle_p;

      
        void
        initAbstractSessionHandle(blpapi_AbstractSession_t *handle)
        {
            d_handle_p = handle;
        }


        Service getService(string serviceIdentifier)
        {
            blpapi_Service_t *service;
            throwOnError(
                    blpapi_AbstractSession_getService(d_handle_p,
                                                      &service,
                                                      serviceIdentifier));
            return service;
        }


        CorrelationId sendAuthorizationRequest(
                                            const Request&        authorizationRequest,
                                            Identity             *identity,
                                            const CorrelationId&  correlationId,
                                            EventQueue           *eventQueue)
        {
            CorrelationId retCorrelationId(correlationId);

            throwOnError(
                blpapi_AbstractSession_sendAuthorizationRequest(
                    d_handle_p,
                    authorizationRequest.handle(),
                    identity.handle(),
                    const_cast<blpapi_CorrelationId_t *>(&retCorrelationId.impl()),
                    eventQueue ? eventQueue.handle() : 0, 0, 0));

            return retCorrelationId;
        }


        void cancel(const CorrelationId& correlationId)
        {
            blpapi_AbstractSession_cancel(d_handle_p, &correlationId.impl(), 1, 0, 0);
        }


        void cancel(CorrelationId[] correlationIds)
        {
            if (!correlationIds.length()) {
                return;
            }
            cancel(&correlationIds[0], correlationIds.length());
        }


        void cancel(const CorrelationId *correlationIds, size_t numCorrelationIds)
        {
            blpapi_AbstractSession_cancel(d_handle_p, cast(const(blpapi_CorrelationId_t*)(correlationIds),
                    numCorrelationIds, 0, 0);
        }


        CorrelationId generateToken(CorrelationId*  correlationId, EventQueue* eventQueue)
        {
            CorrelationId retCorrelationId(correlationId);

            blpapi_AbstractSession_generateToken(d_handle_p, cast(blpapi_CorrelationId_t *)(&retCorrelationId.impl()),
                    eventQueue ? eventQueue.handle() : 0));
            return retCorrelationId;
        }


        bool openService(string serviceIdentifier)
        {
            return blpapi_AbstractSession_openService(d_handle_p, cast(const(char*))serviceIdentifier) ? false : true;
        }

        CorrelationId openServiceAsync(string serviceIdentifier, CorrelationId*  correlationId)
        {
            blpapi_CorrelationId_t retv = correlationId.impl();
            blpapi_AbstractSession_openServiceAsync(d_handle_p, cast(char*)serviceIdentifier, &retv);
            return retv;
        }

        UserHandle createUserHandle()
        {
            return blpapi_AbstractSession_createIdentity(d_handle_p);
        }

        Identity createIdentity()
        {
            return blpapi_AbstractSession_createIdentity(d_handle_p);
        }

        blpapi_AbstractSession_t *abstractSessionHandle()
        {
            return d_handle_p;
        }
}