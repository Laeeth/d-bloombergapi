// All Bloomberg C header files ported to D Lang (2014) by Laeeth Isharc
// I took decision to reformat according to my own preference in order to keep the file short and sweet
// One can be the master of a 1,000 line header file. It's tough to know what is going on in a 14,000 line file

BLPAPI_EXPORT void blpapi_UserHandle_release(blpapi_UserHandle_t *handle);
BLPAPI_EXPORT int blpapi_UserHandle_addRef(blpapi_UserHandle_t *handle);
BLPAPI_EXPORT int blpapi_UserHandle_hasEntitlements(const blpapi_UserHandle_t* handle, const blpapi_Service_t* service,
    const blpapi_Element_t* eidElement,const int* entitlementIds, size_t numEntitlements, int* failedEntitlements, int* failedEntitlementsCount);
BLPAPI_EXPORT int blpapi_AbstractSession_cancel(blpapi_AbstractSession_t* session, const blpapi_CorrelationId_t *correlationIds,
    size_t numCorrelationIds, const char* requestLabel, int requestLabelLen);
BLPAPI_EXPORT int blpapi_AbstractSession_sendAuthorizationRequest(blpapi_AbstractSession_t *session, const blpapi_Request_t* request,
    blpapi_Identity_t* identity, blpapi_CorrelationId_t* correlationId, blpapi_EventQueue_t * eventQueue, const char* requestLabel, int requestLabelLen);
BLPAPI_EXPORT int blpapi_AbstractSession_openService(blpapi_AbstractSession_t *session, const char* serviceIdentifier);
BLPAPI_EXPORT int blpapi_AbstractSession_openServiceAsync(blpapi_AbstractSession_t *session, const char   *serviceIdentifier, blpapi_CorrelationId_t *correlationId);
BLPAPI_EXPORT int blpapi_AbstractSession_generateToken(blpapi_AbstractSession_t *session, blpapi_CorrelationId_t *correlationId, blpapi_EventQueue_t *eventQueue);
BLPAPI_EXPORT int blpapi_AbstractSession_getService(blpapi_AbstractSession_t *session, blpapi_Service_t  **service, const char   *serviceIdentifier);
BLPAPI_EXPORT blpapi_Identity_t *blpapi_AbstractSession_createIdentity(blpapi_AbstractSession_t *session);
BLPAPI_EXPORT void blpapi_Constant_setUserData(blpapi_Constant_t *constant, void * userdata);
BLPAPI_EXPORT blpapi_Name_t* blpapi_Constant_name(const blpapi_Constant_t *constant);
BLPAPI_EXPORT const char* blpapi_Constant_description(const blpapi_Constant_t *constant);
BLPAPI_EXPORT int blpapi_Constant_status(const blpapi_Constant_t *constant);
BLPAPI_EXPORT int blpapi_Constant_datatype(const blpapi_Constant_t *constant);
BLPAPI_EXPORT int blpapi_Constant_getValueAsChar(const blpapi_Constant_t *constant, blpapi_Char_t *buffer);
BLPAPI_EXPORT int blpapi_Constant_getValueAsInt32(const blpapi_Constant_t *constant, blpapi_Int32_t *buffer);
BLPAPI_EXPORT int blpapi_Constant_getValueAsInt64(const blpapi_Constant_t *constant, blpapi_Int64_t *buffer);
BLPAPI_EXPORT int blpapi_Constant_getValueAsFloat32(const blpapi_Constant_t *constant, blpapi_Float32_t *buffer);
BLPAPI_EXPORT int blpapi_Constant_getValueAsFloat64(const blpapi_Constant_t *constant, blpapi_Float64_t *buffer);
BLPAPI_EXPORT int blpapi_Constant_getValueAsDatetime(const blpapi_Constant_t *constant, blpapi_Datetime_t *buffer);
BLPAPI_EXPORT int blpapi_Constant_getValueAsString(const blpapi_Constant_t *constant, const char **buffer);
BLPAPI_EXPORT void * blpapi_Constant_userData(const blpapi_Constant_t *constant);
BLPAPI_EXPORT void blpapi_ConstantList_setUserData(blpapi_ConstantList_t *constant, void * userdata);
BLPAPI_EXPORT blpapi_Name_t* blpapi_ConstantList_name(const blpapi_ConstantList_t *list);
BLPAPI_EXPORT const char* blpapi_ConstantList_description(const blpapi_ConstantList_t *list);
BLPAPI_EXPORT int blpapi_ConstantList_numConstants(const blpapi_ConstantList_t *list);
BLPAPI_EXPORT int blpapi_ConstantList_datatype(const blpapi_ConstantList_t *constant);
BLPAPI_EXPORT int blpapi_ConstantList_status(const blpapi_ConstantList_t *list);
BLPAPI_EXPORT blpapi_Constant_t* blpapi_ConstantList_getConstant(const blpapi_ConstantList_t *constant, const char *nameString, const blpapi_Name_t *name);
BLPAPI_EXPORT blpapi_Constant_t* blpapi_ConstantList_getConstantAt(const blpapi_ConstantList_t *constant, size_t index);
BLPAPI_EXPORT void * blpapi_ConstantList_userData(const blpapi_ConstantList_t *constant);

struct blpapi_ManagedPtr_t_;
blpapi_ManagedPtr_t_ blpapi_ManagedPtr_t;

blpapi_ManagedPtr_ManagerFunction_t=int function( blpapi_ManagedPtr_t *managedPtr, const blpapi_ManagedPtr_t *srcPtr, int operation);
union {
    int intValue;
    void *ptr;
} blpapi_ManagedPtr_t_data_;

struct blpapi_ManagedPtr_t_ {
 void *pointer;
 blpapi_ManagedPtr_t_data_ userData[4];
 blpapi_ManagedPtr_ManagerFunction_t manager;
};

struct blpapi_CorrelationId_t_ {
 unsigned int size:8;  // fill in the size of this struct
 unsigned int valueType:4; // type of value held by this correlation id
 unsigned int classId:16; // user defined classification id
 unsigned int reserved:4; // for internal use must be 0

 union {
  blpapi_UInt64_t intValue;
  blpapi_ManagedPtr_t ptrValue;
 } value;
};
blpapi_CorrelationId_t_ blpapi_CorrelationId_t;

struct blpapi_Datetime_tag {
 blpapi_UChar_t parts;  // bitmask of date/time parts that are set
 blpapi_UChar_t hours;
 blpapi_UChar_t minutes;
 blpapi_UChar_t seconds;
 blpapi_UInt16_t milliSeconds;
 blpapi_UChar_t month;
 blpapi_UChar_t day;
 blpapi_UInt16_t year;
 blpapi_Int16_t offset;  // (signed) minutes ahead of UTC
};

blpapi_Datetime_tag blpapi_Datetime_t;

struct blpapi_HighPrecisionDatetime_tag {
 blpapi_Datetime_t datetime;
 blpapi_UInt32_t picoseconds; // picosecond offset into current
      // *millisecond* i.e. the picosecond offset
      // into the current full second is
      // '1000000000LL * milliSeconds + picoSeconds'
};

blpapi_HighPrecisionDatetime_tag blpapi_HighPrecisionDatetime_t;

BLPAPI_EXPORT int blpapi_Datetime_compare(blpapi_Datetime_t lhs, blpapi_Datetime_t rhs);
BLPAPI_EXPORT int blpapi_Datetime_print(const blpapi_Datetime_t *datetime, blpapi_StreamWriter_t streamWriter, void *stream, int level,
     int spacesPerLevel);

BLPAPI_EXPORT int blpapi_HighPrecisionDatetime_compare(const blpapi_HighPrecisionDatetime_t *lhs, const blpapi_HighPrecisionDatetime_t *rhs);
BLPAPI_EXPORT int blpapi_HighPrecisionDatetime_print(const blpapi_HighPrecisionDatetime_t *datetime, blpapi_StreamWriter_t    streamWriter, void      *stream, int       level, int       spacesPerLevel);
BLPAPI_EXPORT int blpapi_HighPrecisionDatetime_fromTimePoint(blpapi_HighPrecisionDatetime_t *datetime, const blpapi_TimePoint_t  *timePoint, short     offset);
enum BLPAPI
{
 CORRELATION_TYPE_UNSET =0,
 CORRELATION_TYPE_INT  =1,
 CORRELATION_TYPE_POINTER =2,
 CORRELATION_TYPE_AUTOGEN =3,
 CORRELATION_MAX_CLASS_ID =((1 << 16)-1),

 MANAGEDPTR_COPY =1,
 MANAGEDPTR_DESTROY =(-1),

 DATETIME_YEAR_PART  =0x1,
 DATETIME_MONTH_PART  =0x2,
 DATETIME_DAY_PART  =0x4,
 DATETIME_OFFSET_PART  =0x8,
 DATETIME_HOURS_PART  =0x10,
 DATETIME_MINUTES_PART =0x20,
 DATETIME_SECONDS_PART =0x40,
 DATETIME_MILLISECONDS_PART =0x80,
 DATETIME_FRACSECONDS_PART =0x80,
 DATETIME_DATE_PART  =(BLPAPI_DATETIME_YEAR_PART|BLPAPI_DATETIME_MONTH_PART|BLPAPI_DATETIME_DAY_PART),
 DATETIME_TIME_PART  =(BLPAPI_DATETIME_HOURS_PART|BLPAPI_DATETIME_MINUTES_PART|BLPAPI_DATETIME_SECONDS_PART),
 DATETIME_TIMEMILLI_PART =(BLPAPI_DATETIME_TIME_PART|BLPAPI_DATETIME_MILLISECONDS_PART),
 DATETIME_TIMEFRACSECONDS_PART =(BLPAPI_DATETIME_TIME_PART|BLPAPI_DATETIME_FRACSECONDS_PART),


 EVENTTYPE_ADMIN    =1,
 EVENTTYPE_SESSION_STATUS  =2,
 EVENTTYPE_SUBSCRIPTION_STATUS = 3,
 EVENTTYPE_REQUEST_STATUS  =4,
 EVENTTYPE_RESPONSE   =5,
 EVENTTYPE_PARTIAL_RESPONSE =6,
 EVENTTYPE_SUBSCRIPTION_DATA  =8,
 EVENTTYPE_SERVICE_STATUS  =9,
 EVENTTYPE_TIMEOUT   =10,
 EVENTTYPE_AUTHORIZATION_STATUS =11,
 EVENTTYPE_RESOLUTION_STATUS  =12,
 EVENTTYPE_TOPIC_STATUS  =13,
 EVENTTYPE_TOKEN_STATUS  =14,
 EVENTTYPE_REQUEST   =15,


 ELEMENT_INDEX_END =0xffffffff,

 STATUS_ACTIVE   =0,
 STATUS_DEPRECATED  =1,
 STATUS_INACTIVE   =2,
 STATUS_PENDING_DEPRECATION =3,

 SUBSCRIPTIONSTATUS_UNSUBSCRIBED  =0,
 SUBSCRIPTIONSTATUS_SUBSCRIBING   =1,
 SUBSCRIPTIONSTATUS_SUBSCRIBED  =2,
 SUBSCRIPTIONSTATUS_CANCELLED   =3,
 SUBSCRIPTIONSTATUS_PENDING_CANCELLATION =4,

 CLIENTMODE_AUTO  =0,
 CLIENTMODE_DAPI  =1,
 CLIENTMODE_SAPI  =2,
 CLIENTMODE_COMPAT_33X =16,

 ELEMENTDEFINITION_UNBOUNDED =-1,

 RESOLVEMODE_DONT_REGISTER_SERVICES =0,
 RESOLVEMODE_AUTO_REGISTER_SERVICES =1,

 SEATTYPE_INVALID_SEAT =-1,
 SEATTYPE_BPS =0,
 SEATTYPE_NONBPS =1,

 SERVICEREGISTRATIONOPTIONS_PRIORITY_LOW =0,
 SERVICEREGISTRATIONOPTIONS_PRIORITY_MEDIUM= INT_MAX/2,
 SERVICEREGISTRATIONOPTIONS_PRIORITY_HIGH =INT_MAX,

 REGISTRATIONPARTS_DEFAULT =0x1,
 REGISTRATIONPARTS_PUBLISHING =0x2,
 REGISTRATIONPARTS_OPERATIONS= 0x4,
 REGISTRATIONPARTS_SUBSCRIBER_RESOLUTION =0x8,
 REGISTRATIONPARTS_PUBLISHER_RESOLUTION =0x10,
 VERSION_MAJOR=3,
 VERSION_MINOR=8,
 VERSION_PATCH=5,
 VERSION_BUILD=1,
}
BLPAPI_EXPORT int blpapi_DiagnosticsUtil_memoryInfo(char *buffer, size_t bufferLength);

// Forward declarations
struct blpapi_EventFormatter;
blpapi_EventFormatter blpapi_EventFormat_t;
struct blpapi_Topic;
blpapi_Topic blpapi_Topic_t;
struct blpapi_Message;
blpapi_Message blpapi_Message_t;
struct blpapi_Request;
blpapi_Request blpapi_Request_t;
struct blpapi_HighPrecisionDatetime_tag;
blpapi_HighPrecisionDatetime_tag blpapi_HighPrecisionDatetime_t;
struct blpapi_TimePoint;
blpapi_TimePoint blpapi_TimePoint_t;
struct blpapi_SubscriptionList;
blpapi_SubscriptionList blpapi_SubscriptionList_t;
struct blpapi_ServiceRegistrationOptions;
blpapi_ServiceRegistrationOptions blpapi_ServiceRegistrationOptions_t;
// End Forward declarations

// Function dispatch table declaration
struct blpapi_FunctionEntries {
 extern (C) alias blpapi_EventFormatter_appendMessageSeq = int function (blpapi_EventFormatter_t* formatter,char const* typeString, blpapi_Name_t* typeName,
  const blpapi_Topic_t* topic,unsigned int sequenceNumber,unsigned int);
 extern (C) alias int blpapi_EventFormatter_appendRecapMessageSeq=int function(blpapi_EventFormatter_t* formatter,const blpapi_Topic_t *topic,
  const blpapi_CorrelationId_t *cid, unsigned int sequenceNumber, unsigned int);
 extern (C) alias blpapi_Message_addRef=int function(const blpapi_Message_t* message);
 extern (C) alias blpapi_Message_release=int function(const blpapi_Message_t* message);
 extern (C) alias blpapi_SessionOptions_setMaxEventQueueSize=void function(blpapi_SessionOptions_t *parameters,size_t maxEventQueueSize);
 extern (C) alias blpapi_SessionOptions_setSlowConsumerWarningHiWaterMark=int function(blpapi_SessionOptions_t *parameters,float hiWaterMark);
 extern (C) alias blpapi_SessionOptions_setSlowConsumerWarningLoWaterMark=void function(blpapi_SessionOptions_t *parameters,float loWaterMark);
 extern (C) alias blpapi_Request_setPreferredRoute=void function(blpapi_Request_t *request,blpapi_CorrelationId_t *correlationId);
 extern (C) alias blpapi_Message_fragmentType=int function(const blpapi_Message_t *message);
 extern (C) alias blpapi_SessionOptions_maxEventQueueSize=size_t function(blpapi_SessionOptions_t *parameters);
 extern (C) alias blpapi_SessionOptions_slowConsumerWarningHiWaterMark=float function(blpapi_SessionOptions_t *parameters);
 extern (C) alias blpapi_SessionOptions_slowConsumerWarningLoWaterMark=float function(blpapi_SessionOptions_t *parameters);
 extern (C) alias blpapi_SessionOptions_setDefaultKeepAliveInactivityTime=int function(blpapi_SessionOptions_t *parameters,int inactivityTime);
 extern (C) alias blpapi_SessionOptions_setDefaultKeepAliveResponseTimeout=int function(blpapi_SessionOptions_t *parameters,int responseTimeout);
 extern (C) alias blpapi_SessionOptions_defaultKeepAliveInactivityTime=int function(blpapi_SessionOptions_t *parameters);
 extern (C) alias blpapi_SessionOptions_defaultKeepAliveResponseTimeout=int function(blpapi_SessionOptions_t *parameters);
 extern (C) alias blpapi_HighPrecisionDatetime_compare=int function (const blpapi_HighPrecisionDatetime_t*,const blpapi_HighPrecisionDatetime_t*);
 extern (C) alias blpapi_HighPrecisionDatetime_print)int function(const blpapi_HighPrecisionDatetime_t*,blpapi_StreamWriter_t,void*,int,int);
 extern (C) alias blpapi_Element_getValueAsHighPrecisionDatetime)int function(const blpapi_Element_t*,blpapi_HighPrecisionDatetime_t*,size_t);
 extern (C) alias blpapi_Element_setValueHighPrecisionDatetime=int function(blpapi_Element_t*,const blpapi_HighPrecisionDatetime_t*,size_t);
 extern (C) alias blpapi_Element_setElementHighPrecisionDatetime=int function(blpapi_Element_t*, const char*, const blpapi_Name_t*, const blpapi_HighPrecisionDatetime_t*);
 extern (C) alias blpapi_Session_resubscribeWithId=int function(blpapi_Session_t*, const blpapi_SubscriptionList_t*, int, const char*, int);
 extern (C) alias blpapi_EventFormatter_setValueNull=int function(blpapi_EventFormatter_t *, const char *, const blpapi_Name_t *); int (*blpapi_DiagnosticsUtil_memoryInfo)(char *, size_t);
 extern (C) alias blpapi_SessionOptions_setKeepAliveEnabled=int function(blpapi_SessionOptions_t *, int);
 extern (C) alias blpapi_SessionOptions_keepAliveEnabled=int function(blpapi_SessionOptions_t *);
 extern (C) alias blpapi_SubscriptionList_addResolved=int function(blpapi_SubscriptionList_t *, const char *, const blpapi_CorrelationId_t *);
 extern (C) alias blpapi_SubscriptionList_isResolvedAt=int function(blpapi_SubscriptionList_t *, int *, size_t);
 extern (C) alias blpapi_ProviderSession_deregisterService=int function(blpapi_ProviderSession_t *session, const char* serviceName); 
 extern (C) alias blpapi_ServiceRegistrationOptions_setPartsToRegister=void function(blpapi_ServiceRegistrationOptions_t *session, int parts);
 extern (C) alias blpapi_ServiceRegistrationOptions_getPartsToRegister=int function(blpapi_ServiceRegistrationOptions_t *session); int (*blpapi_ProviderSession_deleteTopics)(
  blpapi_ProviderSession_t* session, const blpapi_Topic_t** topics, size_t numTopics);
 extern (C) alias blpapi_ProviderSession_activateSubServiceCodeRange=int function(blpapi_ProviderSession_t *session, const char* serviceName, int begin,
  int end, int priority);
 extern (C) alias blpapi_ProviderSession_deactivateSubServiceCodeRange=int function(blpapi_ProviderSession_t *session, const char* serviceName, int begin,
  int end);
 extern (C) alias blpapi_ServiceRegistrationOptions_addActiveSubServiceCodeRange=int function(blpapi_ServiceRegistrationOptions_t *parameters, int start,
  int end, int priority);
 extern (C) alias blpapi_ServiceRegistrationOptions_removeAllActiveSubServiceCodeRanges=void function(blpapi_ServiceRegistrationOptions_t *parameters);
 extern (C) alias blpapi_Logging_logTestMessage=void function(blpapi_Logging_Severity_t severity); const char *(*blpapi_getVersionIdentifier)();
 extern (C) alias blpapi_Message_timeReceived=int function(const blpapi_Message_t *message, blpapi_TimePoint_t *timeReceived);
 extern (C) alias blpapi_SessionOptions_recordSubscriptionDataReceiveTimes=int function(blpapi_SessionOptions_t *parameters);
 extern (C) alias blpapi_SessionOptions_setRecordSubscriptionDataReceiveTimes=void function(blpapi_SessionOptions_t *parameters, int shouldRecord);
 extern (C) alias blpapi_TimePointUtil_nanosecondsBetween=long function(const blpapi_TimePoint_t *start, const blpapi_TimePoint_t *end);
 extern (C) alias blpapi_HighResolutionClock_now=int function (blpapi_TimePoint_t *timePoint);
 extern (C) alias blpapi_HighPrecisionDatetime_fromTimePoint=int function(blpapi_HighPrecisionDatetime_t *datetime, const blpapi_TimePoint_t *timePoint, short offset);
} blpapi_FunctionEntries_t;

BLPAPI_EXPORT extern size_t    g_blpapiFunctionTableSize;
BLPAPI_EXPORT extern blpapi_FunctionEntries_t g_blpapiFunctionEntries;
BLPAPI_EXPORT blpapi_Name_t* blpapi_Element_name(const blpapi_Element_t *element);
BLPAPI_EXPORT const char* blpapi_Element_nameString(const blpapi_Element_t *element);
BLPAPI_EXPORT blpapi_SchemaElementDefinition_t* blpapi_Element_definition(const blpapi_Element_t* element);
BLPAPI_EXPORT int blpapi_Element_datatype (const blpapi_Element_t* element);
BLPAPI_EXPORT int blpapi_Element_isComplexType(const blpapi_Element_t* element);
BLPAPI_EXPORT int blpapi_Element_isArray(const blpapi_Element_t* element);
BLPAPI_EXPORT int blpapi_Element_isReadOnly(const blpapi_Element_t* element);
BLPAPI_EXPORT size_t blpapi_Element_numValues(const blpapi_Element_t* element);
BLPAPI_EXPORT size_t blpapi_Element_numElements(const blpapi_Element_t* element);
BLPAPI_EXPORT int blpapi_Element_isNullValue(const blpapi_Element_t* element, size_t position);
BLPAPI_EXPORT int blpapi_Element_isNull(const blpapi_Element_t* element);
BLPAPI_EXPORT int blpapi_Element_print(const blpapi_Element_t* element, blpapi_StreamWriter_t streamWriter, void *stream, int level, int spacesPerLevel);
BLPAPI_EXPORT int blpapi_Element_getElementAt(const blpapi_Element_t* element, blpapi_Element_t **result, size_t position);
BLPAPI_EXPORT int blpapi_Element_getElement(const blpapi_Element_t *element, blpapi_Element_t **result, const char* nameString, const blpapi_Name_t *name);
BLPAPI_EXPORT int blpapi_Element_hasElement(const blpapi_Element_t *element, const char* nameString, const blpapi_Name_t *name);
BLPAPI_EXPORT int blpapi_Element_hasElementEx(const blpapi_Element_t *element, const char* nameString, const blpapi_Name_t *name, int excludeNullElements, int reserved);
BLPAPI_EXPORT int blpapi_Element_getValueAsBool(const blpapi_Element_t *element, blpapi_Bool_t *buffer, size_t index);
BLPAPI_EXPORT int blpapi_Element_getValueAsChar(const blpapi_Element_t *element, blpapi_Char_t *buffer, size_t index);
BLPAPI_EXPORT int blpapi_Element_getValueAsInt32(const blpapi_Element_t *element, blpapi_Int32_t *buffer, size_t index);
BLPAPI_EXPORT int blpapi_Element_getValueAsInt64(const blpapi_Element_t *element, blpapi_Int64_t *buffer, size_t index);
BLPAPI_EXPORT int blpapi_Element_getValueAsFloat32(const blpapi_Element_t *element, blpapi_Float32_t *buffer, size_t index);
BLPAPI_EXPORT int blpapi_Element_getValueAsFloat64(const blpapi_Element_t *element, blpapi_Float64_t *buffer, size_t index);
BLPAPI_EXPORT int blpapi_Element_getValueAsString(const blpapi_Element_t *element, const char **buffer, size_t index);
BLPAPI_EXPORT int blpapi_Element_getValueAsDatetime(const blpapi_Element_t *element, blpapi_Datetime_t *buffer, size_t index);
BLPAPI_EXPORT int blpapi_Element_getValueAsHighPrecisionDatetime(const blpapi_Element_t *element, blpapi_HighPrecisionDatetime_t *buffer, size_t index);
BLPAPI_EXPORT int blpapi_Element_getValueAsElement(const blpapi_Element_t *element, blpapi_Element_t **buffer, size_t index);
BLPAPI_EXPORT int blpapi_Element_getValueAsName(const blpapi_Element_t *element, blpapi_Name_t **buffer, size_t index);
BLPAPI_EXPORT int blpapi_Element_getChoice(const blpapi_Element_t *element, blpapi_Element_t **result);
BLPAPI_EXPORT int blpapi_Element_setValueBool(blpapi_Element_t *element, blpapi_Bool_t value, size_t index);
BLPAPI_EXPORT int blpapi_Element_setValueChar(blpapi_Element_t *element, blpapi_Char_t value, size_t index);
BLPAPI_EXPORT int blpapi_Element_setValueInt32(blpapi_Element_t *element, blpapi_Int32_t value, size_t index);
BLPAPI_EXPORT int blpapi_Element_setValueInt64(blpapi_Element_t *element, blpapi_Int64_t value, size_t index);
BLPAPI_EXPORT int blpapi_Element_setValueFloat32(blpapi_Element_t *element, blpapi_Float32_t value, size_t index);
BLPAPI_EXPORT int blpapi_Element_setValueFloat64(blpapi_Element_t *element, blpapi_Float64_t value, size_t index);
BLPAPI_EXPORT int blpapi_Element_setValueString(blpapi_Element_t *element, const char *value, size_t index);
BLPAPI_EXPORT int blpapi_Element_setValueDatetime(blpapi_Element_t *element, const blpapi_Datetime_t *value, size_t index);
BLPAPI_EXPORT int blpapi_Element_setValueHighPrecisionDatetime(blpapi_Element_t *element, const blpapi_HighPrecisionDatetime_t *value, size_t index);
BLPAPI_EXPORT int blpapi_Element_setValueFromElement(blpapi_Element_t *element, blpapi_Element_t *value, size_t index);
BLPAPI_EXPORT int blpapi_Element_setValueFromName (blpapi_Element_t *element, const blpapi_Name_t *value, size_t index);
BLPAPI_EXPORT int blpapi_Element_setElementBool(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Bool_t value);
BLPAPI_EXPORT int blpapi_Element_setElementChar(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Char_t value);
BLPAPI_EXPORT int blpapi_Element_setElementInt32(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Int32_t value);
BLPAPI_EXPORT int blpapi_Element_setElementInt64(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Int64_t value);
BLPAPI_EXPORT int blpapi_Element_setElementFloat32(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Float32_t value);
BLPAPI_EXPORT int blpapi_Element_setElementFloat64(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Float64_t value);
BLPAPI_EXPORT int blpapi_Element_setElementString(blpapi_Element_t *element, const char *nameString, const blpapi_Name_t* name, const char *value);
BLPAPI_EXPORT int blpapi_Element_setElementDatetime(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, const blpapi_Datetime_t *value);
BLPAPI_EXPORT int blpapi_Element_setElementHighPrecisionDatetime(blpapi_Element_t *element, const char *nameString, const blpapi_Name_t *name, const blpapi_HighPrecisionDatetime_t *value);
BLPAPI_EXPORT int blpapi_Element_setElementFromField(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Element_t *sourcebuffer);
BLPAPI_EXPORT int blpapi_Element_setElementFromName (blpapi_Element_t *element, const char* elementName, const blpapi_Name_t* name, const blpapi_Name_t *buffer);
BLPAPI_EXPORT int blpapi_Element_appendElement (blpapi_Element_t *element, blpapi_Element_t **appendedElement);
BLPAPI_EXPORT int blpapi_Element_setChoice (blpapi_Element_t *element, blpapi_Element_t **resultElement, const char* nameCstr, const blpapi_Name_t* name, size_t index);

auto BLPAPI_RESULTCODE(auto res)
{
 return ((res) & 0xffff);
}
auto BLPAPI_RESULTCLASS(auto res)
{
 return((res) & 0xff0000);
}

enum BLPAPI
{
 UNKNOWN_CLASS   =0x00000;
 INVALIDSTATE_CLASS   =0x10000;
 INVALIDARG_CLASS   =0x20000;
 IOERROR_CLASS   =0x30000;
 CNVERROR_CLASS   =0x40000;
 BOUNDSERROR_CLASS  =0x50000;
 NOTFOUND_CLASS   =0x60000;
 FLDNOTFOUND_CLASS  =0x70000;
 UNSUPPORTED_CLASS  =0x80000;

 ERROR_UNKNOWN    =(BLPAPI_UNKNOWN_CLASS | 1);
 ERROR_ILLEGAL_ARG   =(BLPAPI_INVALIDARG_CLASS | 2);
 ERROR_ILLEGAL_ACCESS  =(BLPAPI_UNKNOWN_CLASS | 3);
 ERROR_INVALID_SESSION  =(BLPAPI_INVALIDARG_CLASS | 4);
 ERROR_DUPLICATE_CORRELATIONID =(BLPAPI_INVALIDARG_CLASS | 5);
 ERROR_INTERNAL_ERROR  =(BLPAPI_UNKNOWN_CLASS | 6);
 ERROR_RESOLVE_FAILED  =(BLPAPI_IOERROR_CLASS | 7);
 ERROR_CONNECT_FAILED  =(BLPAPI_IOERROR_CLASS | 8);
 ERROR_ILLEGAL_STATE   =(BLPAPI_INVALIDSTATE_CLASS| 9);
 ERROR_CODEC_FAILURE   =(BLPAPI_UNKNOWN_CLASS | 10);
 ERROR_INDEX_OUT_OF_RANGE =(BLPAPI_BOUNDSERROR_CLASS | 11);
 ERROR_INVALID_CONVERSION =(BLPAPI_CNVERROR_CLASS | 12);
 ERROR_ITEM_NOT_FOUND  =(BLPAPI_NOTFOUND_CLASS | 13);
 ERROR_IO_ERROR   =(BLPAPI_IOERROR_CLASS | 14);
 ERROR_CORRELATION_NOT_FOUND =(BLPAPI_NOTFOUND_CLASS | 15);
 ERROR_SERVICE_NOT_FOUND  =(BLPAPI_NOTFOUND_CLASS | 16);
 ERROR_LOGON_LOOKUP_FAILED  =(BLPAPI_UNKNOWN_CLASS | 17);
 ERROR_DS_LOOKUP_FAILED  =(BLPAPI_UNKNOWN_CLASS | 18);
 ERROR_UNSUPPORTED_OPERATION =(BLPAPI_UNSUPPORTED_CLASS | 19);
 ERROR_DS_PROPERTY_NOT_FOUND =(BLPAPI_NOTFOUND_CLASS | 20);
}

BLPAPI_EXPORT const char* blpapi_getLastErrorDescription(int resultCode);

} // extern (C)

BLPAPI_EXPORT int blpapi_Event_eventType(const blpapi_Event_t *event);
BLPAPI_EXPORT int blpapi_Event_addRef(const blpapi_Event_t *event);
BLPAPI_EXPORT int blpapi_Event_release(const blpapi_Event_t *event);
BLPAPI_EXPORT blpapi_EventQueue_t* blpapi_EventQueue_create(void);
BLPAPI_EXPORT int blpapi_EventQueue_destroy(blpapi_EventQueue_t* eventQueue);
BLPAPI_EXPORT blpapi_Event_t* blpapi_EventQueue_nextEvent(blpapi_EventQueue_t *eventQueue, int timeout);
BLPAPI_EXPORT int blpapi_EventQueue_purge(blpapi_EventQueue_t *eventQueue);
BLPAPI_EXPORT int blpapi_EventQueue_tryNextEvent(blpapi_EventQueue_t *eventQueue, blpapi_Event_t **eventPointer);
BLPAPI_EXPORT blpapi_MessageIterator_t* blpapi_MessageIterator_create(const blpapi_Event_t *event);
BLPAPI_EXPORT void blpapi_MessageIterator_destroy(blpapi_MessageIterator_t* iterator);
BLPAPI_EXPORT int blpapi_MessageIterator_next(blpapi_MessageIterator_t* iterator, blpapi_Message_t** result);
BLPAPI_EXPORT blpapi_EventFormatter_t *blpapi_EventFormatter_create(blpapi_Event_t *event);
BLPAPI_EXPORT void blpapi_EventFormatter_destroy(blpapi_EventFormatter_t *victim);
BLPAPI_EXPORT int blpapi_EventFormatter_appendMessage(blpapi_EventFormatter_t *formatter, const char   *typeString, blpapi_Name_t   *typeName, const blpapi_Topic_t *topic);
BLPAPI_EXPORT int blpapi_EventFormatter_appendMessageSeq(blpapi_EventFormatter_t *formatter, const char   *typeString, blpapi_Name_t   *typeName, const blpapi_Topic_t *topic, unsigned int   sequenceNumber, unsigned    int);
BLPAPI_EXPORT int blpapi_EventFormatter_appendResponse(blpapi_EventFormatter_t *formatter, const char   *typeString, blpapi_Name_t   *typeName);
BLPAPI_EXPORT int blpapi_EventFormatter_appendRecapMessage(blpapi_EventFormatter_t *formatter, const blpapi_Topic_t  *topic, const blpapi_CorrelationId_t *cid);
BLPAPI_EXPORT int blpapi_EventFormatter_appendRecapMessageSeq(blpapi_EventFormatter_t *formatter, const blpapi_Topic_t  *topic, const blpapi_CorrelationId_t *cid,
      unsigned int   sequenceNumber, unsigned    int);
BLPAPI_EXPORT int blpapi_EventFormatter_setValueBool(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, blpapi_Bool_t  value);
BLPAPI_EXPORT int blpapi_EventFormatter_setValueChar(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, char    value);
BLPAPI_EXPORT int blpapi_EventFormatter_setValueInt32(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, blpapi_Int32_t   value);
BLPAPI_EXPORT int blpapi_EventFormatter_setValueInt64(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, blpapi_Int64_t   value);
BLPAPI_EXPORT int blpapi_EventFormatter_setValueFloat32(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, blpapi_Float32_t  value);
BLPAPI_EXPORT int blpapi_EventFormatter_setValueFloat64(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, blpapi_Float64_t  value);
BLPAPI_EXPORT int blpapi_EventFormatter_setValueDatetime(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName,
       const blpapi_Datetime_t *value);

BLPAPI_EXPORT int blpapi_EventFormatter_setValueString(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, const char   *value);
BLPAPI_EXPORT int blpapi_EventFormatter_setValueFromName(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName,
       const blpapi_Name_t  *value);
BLPAPI_EXPORT int blpapi_EventFormatter_setValueNull(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName);
BLPAPI_EXPORT int blpapi_EventFormatter_pushElement(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName);
BLPAPI_EXPORT int blpapi_EventFormatter_popElement(blpapi_EventFormatter_t *formatter);
BLPAPI_EXPORT int blpapi_EventFormatter_appendValueBool(blpapi_EventFormatter_t *formatter, blpapi_Bool_t  value);
BLPAPI_EXPORT int blpapi_EventFormatter_appendValueChar(blpapi_EventFormatter_t *formatter, char    value);
BLPAPI_EXPORT int blpapi_EventFormatter_appendValueInt32(blpapi_EventFormatter_t *formatter, blpapi_Int32_t   value);
BLPAPI_EXPORT int blpapi_EventFormatter_appendValueInt64(blpapi_EventFormatter_t *formatter, blpapi_Int64_t   value);
BLPAPI_EXPORT int blpapi_EventFormatter_appendValueFloat32(blpapi_EventFormatter_t *formatter, blpapi_Float32_t  value);
BLPAPI_EXPORT int blpapi_EventFormatter_appendValueFloat64(blpapi_EventFormatter_t *formatter, blpapi_Float64_t  value);
BLPAPI_EXPORT int blpapi_EventFormatter_appendValueDatetime(blpapi_EventFormatter_t *formatter, const blpapi_Datetime_t *value);
BLPAPI_EXPORT int blpapi_EventFormatter_appendValueString(blpapi_EventFormatter_t *formatter, const char   *value);
BLPAPI_EXPORT int blpapi_EventFormatter_appendValueFromName(blpapi_EventFormatter_t *formatter, const blpapi_Name_t  *value);
BLPAPI_EXPORT int blpapi_EventFormatter_appendElement(blpapi_EventFormatter_t *formatter);

struct blpapi_ErrorInfo {
 int exceptionClass;
 char description[256];
};

blpapi_ErrorInfo blpapi_ErrorInfo_t;

BLPAPI_EXPORT int blpapi_getErrorInfo(blpapi_ErrorInfo_t *buffer, int errorCode);
BLPAPI_EXPORT blpapi_Name_t* blpapi_Message_messageType(const blpapi_Message_t *message);
BLPAPI_EXPORT const char* blpapi_Message_typeString(const blpapi_Message_t *message);
BLPAPI_EXPORT const char* blpapi_Message_topicName(const blpapi_Message_t *message);
BLPAPI_EXPORT blpapi_Service_t* blpapi_Message_service(const blpapi_Message_t *message);
BLPAPI_EXPORT int blpapi_Message_numCorrelationIds(const blpapi_Message_t *message);
BLPAPI_EXPORT blpapi_CorrelationId_t blpapi_Message_correlationId(const blpapi_Message_t *message, size_t index);
BLPAPI_EXPORT blpapi_Element_t* blpapi_Message_elements(const blpapi_Message_t *message);
BLPAPI_EXPORT const char *blpapi_Message_privateData(const blpapi_Message_t *message, size_t *size); 
BLPAPI_EXPORT int blpapi_Message_fragmentType(const blpapi_Message_t *message);
BLPAPI_EXPORT int blpapi_Message_addRef(const blpapi_Message_t *message); 
BLPAPI_EXPORT int blpapi_Message_release(const blpapi_Message_t *message);
BLPAPI_EXPORT int blpapi_Message_timeReceived(const blpapi_Message_t *message, blpapi_TimePoint_t *timeReceived);
BLPAPI_EXPORT blpapi_Name_t* blpapi_Name_create(const char* nameString);
BLPAPI_EXPORT void blpapi_Name_destroy(blpapi_Name_t *name);
BLPAPI_EXPORT blpapi_Name_t* blpapi_Name_duplicate(const blpapi_Name_t *src);
BLPAPI_EXPORT int blpapi_Name_equalsStr(const blpapi_Name_t *name, const char *string);
BLPAPI_EXPORT const char* blpapi_Name_string(const blpapi_Name_t *name);
BLPAPI_EXPORT size_t blpapi_Name_length(const blpapi_Name_t *name);
BLPAPI_EXPORT blpapi_Name_t* blpapi_Name_findName(const char* nameString); 
struct blpapi_ServiceRegistrationOptions;
blpapi_ServiceRegistrationOptions blpapi_ServiceRegistrationOptions_t;
blpapi_ProviderEventHandler_t=void function(blpapi_Event_t* event, blpapi_ProviderSession_t* session, void* userData);
BLPAPI_EXPORT blpapi_ProviderSession_t *blpapi_ProviderSession_create(blpapi_SessionOptions_t *parameters, blpapi_ProviderEventHandler_t handler, blpapi_EventDispatcher_t *dispatcher, void *userData);
BLPAPI_EXPORT void blpapi_ProviderSession_destroy(blpapi_ProviderSession_t *session);
BLPAPI_EXPORT int blpapi_ProviderSession_start(blpapi_ProviderSession_t *session);
BLPAPI_EXPORT int blpapi_ProviderSession_startAsync(blpapi_ProviderSession_t *session);
BLPAPI_EXPORT int blpapi_ProviderSession_stop(blpapi_ProviderSession_t *session);
BLPAPI_EXPORT int blpapi_ProviderSession_stopAsync(blpapi_ProviderSession_t *session);
BLPAPI_EXPORT int blpapi_ProviderSession_nextEvent(blpapi_ProviderSession_t *session, blpapi_Event_t **eventPointer, unsigned int timeoutInMilliseconds);
BLPAPI_EXPORT int blpapi_ProviderSession_tryNextEvent(blpapi_ProviderSession_t *session, blpapi_Event_t **eventPointer);
BLPAPI_EXPORT int blpapi_ProviderSession_registerService(blpapi_ProviderSession_t *session, const char *serviceName, const blpapi_Identity_t *identity, blpapi_ServiceRegistrationOptions_t *registrationOptions);
BLPAPI_EXPORT int blpapi_ProviderSession_activateSubServiceCodeRange(blpapi_ProviderSession_t *session, const char* serviceName, int begin, int end, int priority);
BLPAPI_EXPORT int blpapi_ProviderSession_deactivateSubServiceCodeRange(blpapi_ProviderSession_t *session, const char* serviceName, int begin, int end);
BLPAPI_EXPORT int blpapi_ProviderSession_registerServiceAsync(blpapi_ProviderSession_t *session, const char *serviceName, const blpapi_Identity_t *identity, blpapi_CorrelationId_t *correlationId, blpapi_ServiceRegistrationOptions_t *registrationOptions);
BLPAPI_EXPORT int blpapi_ProviderSession_deregisterService(blpapi_ProviderSession_t *session, const char *serviceName);
BLPAPI_EXPORT int blpapi_ProviderSession_resolve(blpapi_ProviderSession_t *session, blpapi_ResolutionList_t *resolutionList, int resolveMode, const blpapi_Identity_t *identity);
BLPAPI_EXPORT int blpapi_ProviderSession_resolveAsync(blpapi_ProviderSession_t *session, const blpapi_ResolutionList_t *resolutionList, int resolveMode, const blpapi_Identity_t *identity);
BLPAPI_EXPORT int blpapi_ProviderSession_createTopics(blpapi_ProviderSession_t *session, blpapi_TopicList_t *topicList, int resolveMode, const blpapi_Identity_t *identity);
BLPAPI_EXPORT int blpapi_ProviderSession_createTopicsAsync(blpapi_ProviderSession_t *session, const blpapi_TopicList_t *topicList, int resolveMode, const blpapi_Identity_t *identity);
BLPAPI_EXPORT int blpapi_ProviderSession_getTopic(blpapi_ProviderSession_t *session, const blpapi_Message_t *message, blpapi_Topic_t **topic);
BLPAPI_EXPORT int blpapi_ProviderSession_createTopic(blpapi_ProviderSession_t *session, const blpapi_Message_t *message, blpapi_Topic_t **topic);
BLPAPI_EXPORT int blpapi_ProviderSession_createServiceStatusTopic(blpapi_ProviderSession_t *session, const blpapi_Service_t *service, blpapi_Topic_t **topic);
BLPAPI_EXPORT int blpapi_ProviderSession_deleteTopics(blpapi_ProviderSession_t* session, const blpapi_Topic_t** topics, size_t numTopics);
BLPAPI_EXPORT int blpapi_ProviderSession_publish(blpapi_ProviderSession_t *session, blpapi_Event_t *event);
BLPAPI_EXPORT int blpapi_ProviderSession_sendResponse(blpapi_ProviderSession_t *session, blpapi_Event_t *event, int isPartialResponse);
BLPAPI_EXPORT blpapi_AbstractSession_t *blpapi_ProviderSession_getAbstractSession(blpapi_ProviderSession_t *session);
BLPAPI_EXPORT blpapi_ServiceRegistrationOptions_t* blpapi_ServiceRegistrationOptions_create(void);
BLPAPI_EXPORT blpapi_ServiceRegistrationOptions_t* blpapi_ServiceRegistrationOptions_duplicate(const blpapi_ServiceRegistrationOptions_t *parameters);
BLPAPI_EXPORT void blpapi_ServiceRegistrationOptions_destroy(blpapi_ServiceRegistrationOptions_t *parameters);
BLPAPI_EXPORT void blpapi_ServiceRegistrationOptions_copy(blpapi_ServiceRegistrationOptions_t *lhs, const blpapi_ServiceRegistrationOptions_t *rhs);
BLPAPI_EXPORT int blpapi_ServiceRegistrationOptions_addActiveSubServiceCodeRange(blpapi_ServiceRegistrationOptions_t *parameters, int start, int end, int priority);
BLPAPI_EXPORT void blpapi_ServiceRegistrationOptions_removeAllActiveSubServiceCodeRanges(blpapi_ServiceRegistrationOptions_t *parameters);
BLPAPI_EXPORT void blpapi_ServiceRegistrationOptions_setGroupId(blpapi_ServiceRegistrationOptions_t *parameters, const char *groupId, unsigned int groupIdLength);
BLPAPI_EXPORT int blpapi_ServiceRegistrationOptions_setServicePriority(blpapi_ServiceRegistrationOptions_t *parameters, int priority);
BLPAPI_EXPORT void blpapi_ServiceRegistrationOptions_setPartsToRegister(blpapi_ServiceRegistrationOptions_t *parameters, int parts);
BLPAPI_EXPORT int blpapi_ServiceRegistrationOptions_getGroupId(blpapi_ServiceRegistrationOptions_t *parameters, char *groupdIdBuffer, int *groupIdLength);
BLPAPI_EXPORT int blpapi_ServiceRegistrationOptions_getServicePriority(blpapi_ServiceRegistrationOptions_t *parameters);
BLPAPI_EXPORT int blpapi_ServiceRegistrationOptions_getPartsToRegister(blpapi_ServiceRegistrationOptions_t *parameters);
struct blpapi_Request;
blpapi_Request blpapi_Request_t;
struct blpapi_ResolutionList;
blpapi_ResolutionList blpapi_ResolutionList_t;
BLPAPI_EXPORT blpapi_Element_t* blpapi_ResolutionList_extractAttributeFromResolutionSuccess(const blpapi_Message_t* message, const blpapi_Name_t* attribute);
BLPAPI_EXPORT blpapi_ResolutionList_t* blpapi_ResolutionList_create(blpapi_ResolutionList_t* from);
BLPAPI_EXPORT void blpapi_ResolutionList_destroy(blpapi_ResolutionList_t *list);
BLPAPI_EXPORT int blpapi_ResolutionList_add(blpapi_ResolutionList_t* list, const char* topic, const blpapi_CorrelationId_t *correlationId);
BLPAPI_EXPORT int blpapi_ResolutionList_addFromMessage(blpapi_ResolutionList_t* list, const blpapi_Message_t* topic, const blpapi_CorrelationId_t *correlationId);
BLPAPI_EXPORT int blpapi_ResolutionList_addAttribute(blpapi_ResolutionList_t* list, const blpapi_Name_t* name);
BLPAPI_EXPORT int blpapi_ResolutionList_correlationIdAt(const blpapi_ResolutionList_t* list, blpapi_CorrelationId_t* result, size_t index);
BLPAPI_EXPORT int blpapi_ResolutionList_topicString(const blpapi_ResolutionList_t* list, const char** topic, const blpapi_CorrelationId_t* id);
BLPAPI_EXPORT int blpapi_ResolutionList_topicStringAt(const blpapi_ResolutionList_t* list, const char** topic, size_t index);
BLPAPI_EXPORT int blpapi_ResolutionList_status(const blpapi_ResolutionList_t* list, int* status, const blpapi_CorrelationId_t* id);
BLPAPI_EXPORT int blpapi_ResolutionList_statusAt(const blpapi_ResolutionList_t* list, int* status, size_t index);
BLPAPI_EXPORT int blpapi_ResolutionList_attribute(const blpapi_ResolutionList_t* list, blpapi_Element_t** element, const blpapi_Name_t* attribute, const blpapi_CorrelationId_t* id);
BLPAPI_EXPORT int blpapi_ResolutionList_attributeAt(const blpapi_ResolutionList_t* list, blpapi_Element_t** element, const blpapi_Name_t* attribute, size_t index);
BLPAPI_EXPORT int blpapi_ResolutionList_message(const blpapi_ResolutionList_t* list, blpapi_Message_t** element, const blpapi_CorrelationId_t* id);
BLPAPI_EXPORT int blpapi_ResolutionList_messageAt(const blpapi_ResolutionList_t* list, blpapi_Message_t** element, size_t index);
BLPAPI_EXPORT int blpapi_ResolutionList_size(const blpapi_ResolutionList_t* list);
BLPAPI_EXPORT blpapi_Name_t *blpapi_SchemaElementDefinition_name(const blpapi_SchemaElementDefinition_t *field);
BLPAPI_EXPORT const char *blpapi_SchemaElementDefinition_description(const blpapi_SchemaElementDefinition_t *field);
BLPAPI_EXPORT int blpapi_SchemaElementDefinition_status(const blpapi_SchemaElementDefinition_t *field);
BLPAPI_EXPORT blpapi_SchemaTypeDefinition_t *blpapi_SchemaElementDefinition_type(const blpapi_SchemaElementDefinition_t *field);
BLPAPI_EXPORT size_t blpapi_SchemaElementDefinition_numAlternateNames(const blpapi_SchemaElementDefinition_t *field);
BLPAPI_EXPORT blpapi_Name_t *blpapi_SchemaElementDefinition_getAlternateName(const blpapi_SchemaElementDefinition_t *field, size_t index);
BLPAPI_EXPORT size_t blpapi_SchemaElementDefinition_minValues(const blpapi_SchemaElementDefinition_t *field);
BLPAPI_EXPORT size_t blpapi_SchemaElementDefinition_maxValues(const blpapi_SchemaElementDefinition_t *field);
BLPAPI_EXPORT int blpapi_SchemaElementDefinition_print(const blpapi_SchemaElementDefinition_t *element, blpapi_StreamWriter_t streamWriter, void *userStream, int level, int spacesPerLevel);
BLPAPI_EXPORT void blpapi_SchemaElementDefinition_setUserData(blpapi_SchemaElementDefinition_t *field, void *userdata);
BLPAPI_EXPORT void *blpapi_SchemaElementDefinition_userData(const blpapi_SchemaElementDefinition_t *field);
BLPAPI_EXPORT blpapi_Name_t *blpapi_SchemaTypeDefinition_name(const blpapi_SchemaTypeDefinition_t *type);
BLPAPI_EXPORT const char *blpapi_SchemaTypeDefinition_description(const blpapi_SchemaTypeDefinition_t *type);
BLPAPI_EXPORT int blpapi_SchemaTypeDefinition_status(const blpapi_SchemaTypeDefinition_t *type);
BLPAPI_EXPORT int blpapi_SchemaTypeDefinition_datatype(const blpapi_SchemaTypeDefinition_t *type);
BLPAPI_EXPORT int blpapi_SchemaTypeDefinition_isComplexType(const blpapi_SchemaTypeDefinition_t *type);
BLPAPI_EXPORT int blpapi_SchemaTypeDefinition_isSimpleType(const blpapi_SchemaTypeDefinition_t *type);
BLPAPI_EXPORT int blpapi_SchemaTypeDefinition_isEnumerationType(const blpapi_SchemaTypeDefinition_t *type);
BLPAPI_EXPORT int blpapi_SchemaTypeDefinition_isComplex(const blpapi_SchemaTypeDefinition_t *type);
BLPAPI_EXPORT int blpapi_SchemaTypeDefinition_isSimple(const blpapi_SchemaTypeDefinition_t *type);
BLPAPI_EXPORT int blpapi_SchemaTypeDefinition_isEnumeration(const blpapi_SchemaTypeDefinition_t *type);
BLPAPI_EXPORT size_t blpapi_SchemaTypeDefinition_numElementDefinitions(const blpapi_SchemaTypeDefinition_t *type);
BLPAPI_EXPORT blpapi_SchemaElementDefinition_t* blpapi_SchemaTypeDefinition_getElementDefinition(const blpapi_SchemaTypeDefinition_t *type, const char *nameString, const blpapi_Name_t *name);
BLPAPI_EXPORT blpapi_SchemaElementDefinition_t* blpapi_SchemaTypeDefinition_getElementDefinitionAt(const blpapi_SchemaTypeDefinition_t *type, size_t index);
BLPAPI_EXPORT int blpapi_SchemaTypeDefinition_print(const blpapi_SchemaTypeDefinition_t *element, blpapi_StreamWriter_t streamWriter, void *userStream, int level, int spacesPerLevel);
BLPAPI_EXPORT void blpapi_SchemaTypeDefinition_setUserData(blpapi_SchemaTypeDefinition_t *element, void *userdata);
BLPAPI_EXPORT void *blpapi_SchemaTypeDefinition_userData(const blpapi_SchemaTypeDefinition_t *element);
BLPAPI_EXPORT blpapi_ConstantList_t* blpapi_SchemaTypeDefinition_enumeration(const blpapi_SchemaTypeDefinition_t *element);
BLPAPI_EXPORT const char* blpapi_Operation_name(blpapi_Operation_t *service);
BLPAPI_EXPORT const char* blpapi_Operation_description(blpapi_Operation_t *service);
BLPAPI_EXPORT int blpapi_Operation_requestDefinition(blpapi_Operation_t *service, blpapi_SchemaElementDefinition_t **requestDefinition);
BLPAPI_EXPORT int blpapi_Operation_numResponseDefinitions(blpapi_Operation_t *service);
BLPAPI_EXPORT int blpapi_Operation_responseDefinition(blpapi_Operation_t *service, blpapi_SchemaElementDefinition_t **responseDefinition, size_t index);
BLPAPI_EXPORT const char* blpapi_Service_name(blpapi_Service_t *service);
BLPAPI_EXPORT const char* blpapi_Service_description(blpapi_Service_t *service);
BLPAPI_EXPORT int blpapi_Service_numOperations(blpapi_Service_t *service);
BLPAPI_EXPORT int blpapi_Service_numEventDefinitions(blpapi_Service_t *service); 
BLPAPI_EXPORT int blpapi_Service_addRef(blpapi_Service_t *service);
BLPAPI_EXPORT void blpapi_Service_release(blpapi_Service_t *service);
BLPAPI_EXPORT const char* blpapi_Service_authorizationServiceName(blpapi_Service_t *service);
BLPAPI_EXPORT int blpapi_Service_getOperation(blpapi_Service_t *service, blpapi_Operation_t **operation, const char* nameString, const blpapi_Name_t *name);
BLPAPI_EXPORT int blpapi_Service_getOperationAt(blpapi_Service_t *service, blpapi_Operation_t **operation, size_t index);
BLPAPI_EXPORT int blpapi_Service_getEventDefinition(blpapi_Service_t *service, blpapi_SchemaElementDefinition_t **result, const char* nameString, const blpapi_Name_t *name);
BLPAPI_EXPORT int blpapi_Service_getEventDefinitionAt(blpapi_Service_t *service, blpapi_SchemaElementDefinition_t **result, size_t index);
BLPAPI_EXPORT int blpapi_Service_createRequest(blpapi_Service_t* service, blpapi_Request_t** request, const char *operation);
BLPAPI_EXPORT int blpapi_Service_createAuthorizationRequest(blpapi_Service_t* service, blpapi_Request_t** request, const char *operation);
BLPAPI_EXPORT int blpapi_Service_createPublishEvent(blpapi_Service_t* service, blpapi_Event_t** event);
BLPAPI_EXPORT int blpapi_Service_createAdminEvent(blpapi_Service_t* service, blpapi_Event_t** event);
BLPAPI_EXPORT int blpapi_Service_createResponseEvent(blpapi_Service_t* service, const blpapi_CorrelationId_t* correlationId, blpapi_Event_t** event);
BLPAPI_EXPORT int blpapi_Service_print(const blpapi_Service_t* service, blpapi_StreamWriter_t streamWriter, void *stream, int level, int spacesPerLevel);
BLPAPI_EXPORT blpapi_SessionOptions_t *blpapi_SessionOptions_create(void);
BLPAPI_EXPORTblpapi_SessionOptions_t *blpapi_SessionOptions_duplicate(const blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT void blpapi_SessionOptions_copy(blpapi_SessionOptions_t  *lhs, const blpapi_SessionOptions_t *rhs);
BLPAPI_EXPORT void blpapi_SessionOptions_destroy(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_setServerHost(blpapi_SessionOptions_t *parameters, const char   *serverHost);
BLPAPI_EXPORT int blpapi_SessionOptions_setServerPort(blpapi_SessionOptions_t *parameters, unsigned short   serverPort);
BLPAPI_EXPORT int blpapi_SessionOptions_setServerAddress(blpapi_SessionOptions_t *parameters, const char   *serverHost, unsigned short   serverPort, size_t    index);
BLPAPI_EXPORT int blpapi_SessionOptions_removeServerAddress(blpapi_SessionOptions_t *parameters, size_t    index);
BLPAPI_EXPORT int blpapi_SessionOptions_setConnectTimeout(blpapi_SessionOptions_t *parameters, unsigned int   timeoutInMilliseconds);
BLPAPI_EXPORT int blpapi_SessionOptions_setDefaultServices(blpapi_SessionOptions_t *parameters, const char   *defaultServices);
BLPAPI_EXPORT int blpapi_SessionOptions_setDefaultSubscriptionService(blpapi_SessionOptions_t *parameters, const char   *serviceIdentifier);
BLPAPI_EXPORT void blpapi_SessionOptions_setDefaultTopicPrefix(blpapi_SessionOptions_t *parameters, const char   *prefix);
BLPAPI_EXPORT void blpapi_SessionOptions_setAllowMultipleCorrelatorsPerMsg(blpapi_SessionOptions_t *parameters, int    allowMultipleCorrelatorsPerMsg);
BLPAPI_EXPORT void blpapi_SessionOptions_setClientMode(blpapi_SessionOptions_t *parameters, int    clientMode);
BLPAPI_EXPORT void blpapi_SessionOptions_setMaxPendingRequests(blpapi_SessionOptions_t *parameters, int    maxPendingRequests);
BLPAPI_EXPORT void blpapi_SessionOptions_setAutoRestartOnDisconnection(blpapi_SessionOptions_t *parameters, int    autoRestart);
BLPAPI_EXPORT void blpapi_SessionOptions_setAutoRestart(blpapi_SessionOptions_t *parameters, int    autoRestart);
BLPAPI_EXPORT void blpapi_SessionOptions_setAuthenticationOptions(blpapi_SessionOptions_t *parameters, const char   *authOptions);
BLPAPI_EXPORT void blpapi_SessionOptions_setNumStartAttempts(blpapi_SessionOptions_t *parameters, int    numStartAttempts);
BLPAPI_EXPORT void blpapi_SessionOptions_setMaxEventQueueSize(blpapi_SessionOptions_t *parameters, size_t    maxEventQueueSize);
BLPAPI_EXPORT int blpapi_SessionOptions_setSlowConsumerWarningHiWaterMark(blpapi_SessionOptions_t *parameters, float    hiWaterMark);
BLPAPI_EXPORT int blpapi_SessionOptions_setSlowConsumerWarningLoWaterMark(blpapi_SessionOptions_t *parameters, float    loWaterMark);
BLPAPI_EXPORT int blpapi_SessionOptions_setDefaultKeepAliveInactivityTime(blpapi_SessionOptions_t *parameters, int    inactivityMsecs);
BLPAPI_EXPORT int blpapi_SessionOptions_setDefaultKeepAliveResponseTimeout(blpapi_SessionOptions_t *parameters, int    timeoutMsecs);
BLPAPI_EXPORT int blpapi_SessionOptions_setKeepAliveEnabled(blpapi_SessionOptions_t *parameters, int    isEnabled);
BLPAPI_EXPORT void blpapi_SessionOptions_setRecordSubscriptionDataReceiveTimes(blpapi_SessionOptions_t *parameters, int    shouldRecord);
BLPAPI_EXPORT const char *blpapi_SessionOptions_serverHost(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT unsigned int blpapi_SessionOptions_serverPort(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_numServerAddresses(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_getServerAddress(blpapi_SessionOptions_t *parameters, const char   **serverHost, unsigned short   *serverPort, size_t    index);
BLPAPI_EXPORT unsigned int blpapi_SessionOptions_connectTimeout(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT const char *blpapi_SessionOptions_defaultServices(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT const char *blpapi_SessionOptions_defaultSubscriptionService(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT const char *blpapi_SessionOptions_defaultTopicPrefix(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_allowMultipleCorrelatorsPerMsg(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_clientMode(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_maxPendingRequests(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_autoRestartOnDisconnection(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_autoRestart(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT const char *blpapi_SessionOptions_authenticationOptions(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_numStartAttempts(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT size_t blpapi_SessionOptions_maxEventQueueSize(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT float blpapi_SessionOptions_slowConsumerWarningHiWaterMark(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT float blpapi_SessionOptions_slowConsumerWarningLoWaterMark(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_defaultKeepAliveInactivityTime(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_defaultKeepAliveResponseTimeout(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_keepAliveEnabled(blpapi_SessionOptions_t *parameters);
BLPAPI_EXPORT int blpapi_SessionOptions_recordSubscriptionDataReceiveTimes(blpapi_SessionOptions_t *parameters);
blpapi_StreamWriter_t=int function(const char* data, int length, void *stream);
struct blpapi_SubscriptionList;
blpapi_SubscriptionList blpapi_SubscriptionList_t;
BLPAPI_EXPORT blpapi_SubscriptionList_t *blpapi_SubscriptionList_create(void);
BLPAPI_EXPORT void blpapi_SubscriptionList_destroy(blpapi_SubscriptionList_t *list);
BLPAPI_EXPORT int blpapi_SubscriptionList_add(blpapi_SubscriptionList_t  *list, const char    *subscriptionString, const blpapi_CorrelationId_t *correlationId, const char    **fields, const char    **options, size_t     numfields, size_t     numOptions);
BLPAPI_EXPORT int blpapi_SubscriptionList_addResolved(blpapi_SubscriptionList_t *list, const char    *subscriptionString, const blpapi_CorrelationId_t *correlationId);
BLPAPI_EXPORT int blpapi_SubscriptionList_clear(blpapi_SubscriptionList_t *list);
BLPAPI_EXPORT int blpapi_SubscriptionList_append(blpapi_SubscriptionList_t  *dest, const blpapi_SubscriptionList_t *src);
BLPAPI_EXPORT int blpapi_SubscriptionList_size(const blpapi_SubscriptionList_t *list);
BLPAPI_EXPORT int blpapi_SubscriptionList_correlationIdAt(const blpapi_SubscriptionList_t *list, blpapi_CorrelationId_t  *result, size_t     index);
BLPAPI_EXPORT int blpapi_SubscriptionList_topicStringAt(blpapi_SubscriptionList_t *list, const char   **result, size_t    index);
BLPAPI_EXPORT int blpapi_SubscriptionList_isResolvedAt(blpapi_SubscriptionList_t *list, int     *result, size_t    index);

struct blpapi_TimePoint {
 blpapi_Int64_t d_value;
}
blpapi_TimePoint blpapi_TimePoint_t;
struct blpapi_Topic;
blpapi_Topic blpapi_Topic_t;
BLPAPI_EXPORT blpapi_Topic_t* blpapi_Topic_create(blpapi_Topic_t* from);
BLPAPI_EXPORT void blpapi_Topic_destroy(blpapi_Topic_t* victim);
BLPAPI_EXPORT int blpapi_Topic_compare(const blpapi_Topic_t* lhs, const blpapi_Topic_t* rhs);
BLPAPI_EXPORT blpapi_Service_t* blpapi_Topic_service(const blpapi_Topic_t *topic);
BLPAPI_EXPORT int blpapi_Topic_isActive(const blpapi_Topic_t *topic);
struct blpapi_TopicList;
blpapi_TopicList blpapi_TopicList_t;
BLPAPI_EXPORT blpapi_TopicList_t* blpapi_TopicList_create(blpapi_TopicList_t* from);
BLPAPI_EXPORT void blpapi_TopicList_destroy(blpapi_TopicList_t *list);
BLPAPI_EXPORT int blpapi_TopicList_add(blpapi_TopicList_t* list, const char* topic, const blpapi_CorrelationId_t *correlationId);
BLPAPI_EXPORT int blpapi_TopicList_addFromMessage(blpapi_TopicList_t* list, const blpapi_Message_t* topic, const blpapi_CorrelationId_t *correlationId);
BLPAPI_EXPORT int blpapi_TopicList_correlationIdAt(const blpapi_TopicList_t* list, blpapi_CorrelationId_t* result, size_t index);
BLPAPI_EXPORT int blpapi_TopicList_topicString(const blpapi_TopicList_t* list, const char** topic, const blpapi_CorrelationId_t* id);
BLPAPI_EXPORT int blpapi_TopicList_topicStringAt(const blpapi_TopicList_t* list, const char** topic, size_t index);
BLPAPI_EXPORT int blpapi_TopicList_status(const blpapi_TopicList_t* list, int* status, const blpapi_CorrelationId_t* id);
BLPAPI_EXPORT int blpapi_TopicList_statusAt(const blpapi_TopicList_t* list, int* status, size_t index);
BLPAPI_EXPORT int blpapi_TopicList_message(const blpapi_TopicList_t* list, blpapi_Message_t** element, const blpapi_CorrelationId_t* id);
BLPAPI_EXPORT int blpapi_TopicList_messageAt(const blpapi_TopicList_t* list, blpapi_Message_t** element, size_t index);
BLPAPI_EXPORT int blpapi_TopicList_size(const blpapi_TopicList_t* list);
alias blpapi_Bool_t = int;
alias blpapi_Char_t=char;
alias blpapi_UChar_t=uchar;
alias blpapi_Int16_t=short;
alias blpapi_UInt16_t=ushort
alias blpapi_Int32_t =int; 
alias blpapi_UInt32_t=uint;
alias blpapi_Int64_t = long;
alias blpapi_UInt64_t = ulong;
alias blpapi_Float32_t=floar;
alias blpapi_Float64_t =double;

enum blpapi_DataType
{
  BOOL   = 1,  // Bool
  CHAR   = 2,  // Char
  BYTE   = 3,  // Unsigned 8 bit value
  INT32  = 4,  // 32 bit Integer
  INT64  = 5,  // 64 bit Integer
  FLOAT32  = 6,  // 32 bit Floating point - IEEE
  FLOAT64  = 7,  // 64 bit Floating point - IEEE
  STRING  = 8,  // ASCIIZ string
  BYTEARRAY = 9,  // Opaque binary data
  DATE   = 10, // Date
  TIME   = 11, // Timestamp
  DECIMAL  = 12, //
  DATETIME  = 13, // Date and time
  ENUMERATION = 14, // An opaque enumeration
  SEQUENCE  = 15, // Sequence type
  CHOICE  = 16, // Choice type
  CORRELATION_ID = 17, // Used for some internal messages
};

enum blpapi_Logging_Severity
{
 OFF = 0,
 FATAL = 1,
 ERROR = 2,
 WARN = 3,
 INFO = 4,
 DEBUG = 5,
 TRACE = 6
}

struct blpapi_AbstractSession;
blpapi_AbstractSession blpapi_AbstractSession_t;

struct blpapi_Constant;
blpapi_Constant blpapi_Constant_t;

struct blpapi_ConstantList;
blpapi_ConstantList blpapi_ConstantList_t;

struct blpapi_Element;
blpapi_Element blpapi_Element_t;

struct blpapi_Event;
blpapi_Event blpapi_Event_t;

struct blpapi_EventDispatcher;
blpapi_EventDispatcher blpapi_EventDispatcher_t;

struct blpapi_EventFormatter;
blpapi_EventFormatter blpapi_EventFormatter_t;

struct blpapi_EventQueue;
blpapi_EventQueue blpapi_EventQueue_t;

struct blpapi_MessageIterator;
blpapi_MessageIterator blpapi_MessageIterator_t;

struct blpapi_Name;
blpapi_Name blpapi_Name_t;

struct blpapi_Operation;
blpapi_Operation blpapi_Operation_t;

struct blpapi_ProviderSession;
blpapi_ProviderSession blpapi_ProviderSession_t;

struct blpapi_Service;
blpapi_Service blpapi_Service_t;

struct blpapi_Session;
blpapi_Session blpapi_Session_t;

struct blpapi_SessionOptions;
blpapi_SessionOptions blpapi_SessionOptions_t;

struct blpapi_SubscriptionItrerator;
blpapi_SubscriptionItrerator blpapi_SubscriptionIterator_t;

struct blpapi_Identity;
blpapi_Identity blpapi_UserHandle;
blpapi_Identity blpapi_UserHandle_t;

struct blpapi_Identity;
blpapi_Identity blpapi_Identity_t;

BLPAPI_EXPORT void blpapi_getVersionInfo(int *majorVersion, int *minorVersion, int *patchVersion, int *buildVersion);
BLPAPI_EXPORT const char *blpapi_getVersionIdentifier(void);

// will make it a template later
long BLPAPI_MAKE_VERSION(long MAJOR, long MINOR, long PATCH)
{
 return((MAJOR) * 65536 + (MINOR) * 256 + (PATCH));
}
 
alias BLPAPI_SDK_VERSION=BLPAPI_MAKE_VERSION( BLPAPI_VERSION_MAJOR, BLPAPI_VERSION_MINOR, BLPAPI_VERSION_PATCH);
