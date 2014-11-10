import std.bitmanip;
/**
 Copyright 2012. Bloomberg Finance L.P.
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following condAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTitions:  The above
  copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.NY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CM, DHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR LAITHE USE OR OTHER DEALINGS
  IN THE SOFTWARE.

Ported to D-lang by Laeeth Isharc (2014).  Do with this as you wish, but at your own risk.
*/

// All Bloomberg C header files ported to D Lang (2014) by Laeeth Isharc
// I took decision to reformat according to my own preference in order to keep the file short and sweet
// One can be the master of a 1,000 line header file. It's tough to know what is going on in a 14,000 line file
extern(Windows)
{

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
   
  alias blpapi_Datetime_t=blpapi_Datetime_tag ;
  // Forward declarationss
  struct blpapi_EventFormatter;
  alias blpapi_EventFormatter_t = blpapi_EventFormatter;
  struct blpapi_Topic;
  alias blpapi_Topic_t= blpapi_Topic ;
  struct blpapi_Message;
  alias blpapi_Message_t=blpapi_Message ;
  struct blpapi_Request;
  alias blpapi_Request_t=blpapi_Request ;
  alias blpapi_TimePoint_t = blpapi_TimePoint ;
  struct blpapi_SubscriptionList;
  alias blpapi_SubscriptionList_t = blpapi_SubscriptionList ;
  struct blpapi_ServiceRegistrationOptions;
  alias blpapi_ServiceRegistrationOptions_t = blpapi_ServiceRegistrationOptions;
  // End Forward declarations

  alias blpapi_ManagedPtr_t =  blpapi_ManagedPtr_t_ ;
  alias blpapi_ManagedPtr_ManagerFunction_t=int function(blpapi_ManagedPtr_t *managedPtr, const blpapi_ManagedPtr_t *srcPtr, int operation);

  union blpapi_ManagedPtr_t_data_u {
      int   intValue;
      void *ptr;
  }

  alias blpapi_ManagedPtr_t_data_ =  blpapi_ManagedPtr_t_data_u ;

  struct blpapi_ManagedPtr_t_ {
   void *pointer;
   blpapi_ManagedPtr_t_data_ userData[4];
   blpapi_ManagedPtr_ManagerFunction_t manager;
  }

  struct xbitmap {
    uint blob;

    uint maskmsb(uint bits)
    {
        uint mask=0;
        foreach(i;0..bits)
            mask=(mask>>>i) | (1<<<31);
        return mask;
    }

    uint extract(uint startpos, uint endpos)
    {
      uint retval;
      int head,tail;
      if ((endpos<=startpos) || (startpos<0) ||(endpos>32))
        throw new Exception("Invalid bitfield parameters " ~ to!string(startpos) ~ to!string(endpos));
      return ((blob>>>startpos) & (~maskmsb(32-endpos)))
    }

    void maskset(uint startpos, uint enmdpos, uint param)
    {
      uint mask=0;
      foreach(i;startpos..endpos)
          mask~=(1<<<i);
      return (blob & ~mask) | (param<<<startpos);
    }

    @property
    {
      uint size()
      {
        return cast(ubyte)*extract(0,8);
      }
      void size(uint paramsize)
      {
        blob=maskset(0,8,paramsize);
      }
      uint valueType()
      {
        return cast(uint)*extract(8,12);
      }
      void valueType(uint param)
      {
        blob=maskset(8,12,param);
      }
      uint classId()
      {
        return cast(uint)*extract(12,28);
      }
      void classId(uint param)
      {
        blob=maskset(12,28,param)
      }
    }
  }

  struct blpapi_CorrelationId_t_ {
      uint x;                           //bit fields cause problems with linkage
        
      union _value {
          blpapi_UInt64_t      intValue;
          blpapi_ManagedPtr_t  ptrValue;
      };
      _value value;

      extern(Windows) xbitmap* xx()
      {
        return cast(xbitmap*)&x;
      }
  }

  alias blpapi_CorrelationId_t=blpapi_CorrelationId_t_ ;


  struct blpapi_HighPrecisionDatetime_tag {
   blpapi_Datetime_t datetime;
   blpapi_UInt32_t picoseconds; // picosecond offset into current
        // *millisecond* i.e. the picosecond offset
        // into the current full second is
        // '1000000000LL * milliSeconds + picoSeconds'
  };

  extern(Windows) alias blpapi_HighPrecisionDatetime_t= blpapi_HighPrecisionDatetime_tag ;
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
   DATETIME_DATE_PART  =(BLPAPI.DATETIME_YEAR_PART|BLPAPI.DATETIME_MONTH_PART|BLPAPI.DATETIME_DAY_PART),
   DATETIME_TIME_PART  =(BLPAPI.DATETIME_HOURS_PART|BLPAPI.DATETIME_MINUTES_PART|BLPAPI.DATETIME_SECONDS_PART),
   DATETIME_TIMEMILLI_PART =(BLPAPI.DATETIME_TIME_PART|BLPAPI.DATETIME_MILLISECONDS_PART),
   DATETIME_TIMEFRACSECONDS_PART =(BLPAPI.DATETIME_TIME_PART|BLPAPI.DATETIME_FRACSECONDS_PART),


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
   SERVICEREGISTRATIONOPTIONS_PRIORITY_MEDIUM= int.max/2,
   SERVICEREGISTRATIONOPTIONS_PRIORITY_HIGH =int.max,

   REGISTRATIONPARTS_DEFAULT =0x1,
   REGISTRATIONPARTS_PUBLISHING =0x2,
   REGISTRATIONPARTS_OPERATIONS= 0x4,
   REGISTRATIONPARTS_SUBSCRIBER_RESOLUTION =0x8,
   REGISTRATIONPARTS_PUBLISHER_RESOLUTION =0x10,
   VERSION_MAJOR=3,
   VERSION_MINOR=8,
   VERSION_PATCH=5,
   VERSION_BUILD=1,

   UNKNOWN_CLASS   =0x00000,
   INVALIDSTATE_CLASS   =0x10000 ,
   INVALIDARG_CLASS   =0x20000 ,
   IOERROR_CLASS   =0x30000 ,
   CNVERROR_CLASS   =0x40000 ,
   BOUNDSERROR_CLASS  =0x50000 ,
   NOTFOUND_CLASS   =0x60000 ,
   FLDNOTFOUND_CLASS  =0x70000 ,
   UNSUPPORTED_CLASS  =0x80000 ,

   ERROR_UNKNOWN    =(BLPAPI.UNKNOWN_CLASS | 1) ,
   ERROR_ILLEGAL_ARG   =(BLPAPI.INVALIDARG_CLASS | 2) ,
   ERROR_ILLEGAL_ACCESS  =(BLPAPI.UNKNOWN_CLASS | 3) ,
   ERROR_INVALID_SESSION  =(BLPAPI.INVALIDARG_CLASS | 4) ,
   ERROR_DUPLICATE_CORRELATIONID =(BLPAPI.INVALIDARG_CLASS | 5) ,
   ERROR_INTERNAL_ERROR  =(BLPAPI.UNKNOWN_CLASS | 6) ,
   ERROR_RESOLVE_FAILED  =(BLPAPI.IOERROR_CLASS | 7) ,
   ERROR_CONNECT_FAILED  =(BLPAPI.IOERROR_CLASS | 8) ,
   ERROR_ILLEGAL_STATE   =(BLPAPI.INVALIDSTATE_CLASS| 9) ,
   ERROR_CODEC_FAILURE   =(BLPAPI.UNKNOWN_CLASS | 10) ,
   ERROR_INDEX_OUT_OF_RANGE =(BLPAPI.BOUNDSERROR_CLASS | 11) ,
   ERROR_INVALID_CONVERSION =(BLPAPI.CNVERROR_CLASS | 12) ,
   ERROR_ITEM_NOT_FOUND  =(BLPAPI.NOTFOUND_CLASS | 13) ,
   ERROR_IO_ERROR   =(BLPAPI.IOERROR_CLASS | 14) ,
   ERROR_CORRELATION_NOT_FOUND =(BLPAPI.NOTFOUND_CLASS | 15) ,
   ERROR_SERVICE_NOT_FOUND  =(BLPAPI.NOTFOUND_CLASS | 16) ,
   ERROR_LOGON_LOOKUP_FAILED  =(BLPAPI.UNKNOWN_CLASS | 17) ,
   ERROR_DS_LOOKUP_FAILED  =(BLPAPI.UNKNOWN_CLASS | 18) ,
   ERROR_UNSUPPORTED_OPERATION =(BLPAPI.UNSUPPORTED_CLASS | 19) ,
   ERROR_DS_PROPERTY_NOT_FOUND =(BLPAPI.NOTFOUND_CLASS | 20) ,
  }

  void blpapi_UserHandle_release(blpapi_UserHandle_t *handle);
  int blpapi_UserHandle_addRef(blpapi_UserHandle_t *handle);
  int blpapi_UserHandle_hasEntitlements(const blpapi_UserHandle_t* handle, const blpapi_Service_t* service, const blpapi_Element_t* eidElement,const int* entitlementIds, size_t numEntitlements, int* failedEntitlements, int* failedEntitlementsCount);
  int blpapi_AbstractSession_cancel(blpapi_AbstractSession_t* session, const blpapi_CorrelationId_t *correlationIds, size_t numCorrelationIds, const char* requestLabel, int requestLabelLen);
  int blpapi_AbstractSession_sendAuthorizationRequest(blpapi_AbstractSession_t *session, const blpapi_Request_t* request, blpapi_Identity_t* identity, blpapi_CorrelationId_t* correlationId, blpapi_EventQueue_t * eventQueue, const char* requestLabel, int requestLabelLen);
  int blpapi_AbstractSession_openService(blpapi_AbstractSession_t *session, const char* serviceIdentifier);
  int blpapi_AbstractSession_openServiceAsync(blpapi_AbstractSession_t *session, const char   *serviceIdentifier, blpapi_CorrelationId_t *correlationId);
  int blpapi_AbstractSession_generateToken(blpapi_AbstractSession_t *session, blpapi_CorrelationId_t *correlationId, blpapi_EventQueue_t *eventQueue);
  int blpapi_AbstractSession_getService(blpapi_AbstractSession_t *session, blpapi_Service_t  **service, const char   *serviceIdentifier);
  blpapi_Identity_t *blpapi_AbstractSession_createIdentity(blpapi_AbstractSession_t *session);
  void blpapi_Constant_setUserData(blpapi_Constant_t *constant, void * userdata);
  blpapi_Name_t* blpapi_Constant_name(const blpapi_Constant_t *constant);
  const(char*) blpapi_Constant_description(const blpapi_Constant_t *constant);
  int blpapi_Constant_status(const blpapi_Constant_t *constant);
  int blpapi_Constant_datatype(const blpapi_Constant_t *constant);
  int blpapi_Constant_getValueAsChar(const blpapi_Constant_t *constant, blpapi_Char_t *buffer);
  int blpapi_Constant_getValueAsInt32(const blpapi_Constant_t *constant, blpapi_Int32_t *buffer);
  int blpapi_Constant_getValueAsInt64(const blpapi_Constant_t *constant, blpapi_Int64_t *buffer);
  int blpapi_Constant_getValueAsFloat32(const blpapi_Constant_t *constant, blpapi_Float32_t *buffer);
  int blpapi_Constant_getValueAsFloat64(const blpapi_Constant_t *constant, blpapi_Float64_t *buffer);
  int blpapi_Constant_getValueAsDatetime(const blpapi_Constant_t *constant, blpapi_Datetime_t *buffer);
  int blpapi_Constant_getValueAsString(const blpapi_Constant_t *constant, const char **buffer);
  const(void *) blpapi_Constant_userData(const blpapi_Constant_t *constant);
  void blpapi_ConstantList_setUserData(blpapi_ConstantList_t *constant, void * userdata);
  blpapi_Name_t* blpapi_ConstantList_name(const blpapi_ConstantList_t *list);
  const(char*) blpapi_ConstantList_description(const blpapi_ConstantList_t *list);
  int blpapi_ConstantList_numConstants(const blpapi_ConstantList_t *list);
  int blpapi_ConstantList_datatype(const blpapi_ConstantList_t *constant);
  int blpapi_ConstantList_status(const blpapi_ConstantList_t *list);
  blpapi_Constant_t* blpapi_ConstantList_getConstant(const blpapi_ConstantList_t *constant, const char *nameString, const blpapi_Name_t *name);
  blpapi_Constant_t* blpapi_ConstantList_getConstantAt(const blpapi_ConstantList_t *constant, size_t index);
  const(void *) blpapi_ConstantList_userData(const blpapi_ConstantList_t *constant);
  int blpapi_Datetime_compare(blpapi_Datetime_t lhs, blpapi_Datetime_t rhs);
  int blpapi_Datetime_print(const blpapi_Datetime_t *datetime, blpapi_StreamWriter_t streamWriter, void *stream, int level, int spacesPerLevel);
  int blpapi_HighPrecisionDatetime_compare(const blpapi_HighPrecisionDatetime_t *lhs, const blpapi_HighPrecisionDatetime_t *rhs);
  int blpapi_HighPrecisionDatetime_print(const blpapi_HighPrecisionDatetime_t *datetime, blpapi_StreamWriter_t    streamWriter, void      *stream, int       level, int       spacesPerLevel);
  int blpapi_HighPrecisionDatetime_fromTimePoint(blpapi_HighPrecisionDatetime_t *datetime, const blpapi_TimePoint_t  *timePoint, short     offset);


  int blpapi_DiagnosticsUtil_memoryInfo(char *buffer, size_t bufferLength);


  // Function dispatch table declaration
  struct blpapi_FunctionEntries {
   alias blpapi_EventFormatter_appendMessageSeq = int function (blpapi_EventFormatter_t* formatter,const char* typeString, blpapi_Name_t* typeName, const blpapi_Topic_t* topic,uint sequenceNumber,uint);
   alias blpapi_EventFormatter_appendRecapMessageSeq=int function(blpapi_EventFormatter_t* formatter,const blpapi_Topic_t *topic, const blpapi_CorrelationId_t *cid, uint sequenceNumber, uint);
   alias blpapi_Message_addRef=int function(const blpapi_Message_t* message);
   alias blpapi_Message_release=int function(const blpapi_Message_t* message);
   alias blpapi_SessionOptions_setMaxEventQueueSize=void function(blpapi_SessionOptions_t *parameters,size_t maxEventQueueSize);
   alias blpapi_SessionOptions_setSlowConsumerWarningHiWaterMark=int function(blpapi_SessionOptions_t *parameters,float hiWaterMark);
   alias blpapi_SessionOptions_setSlowConsumerWarningLoWaterMark=void function(blpapi_SessionOptions_t *parameters,float loWaterMark);
   alias blpapi_Request_setPreferredRoute=void function(blpapi_Request_t *request,blpapi_CorrelationId_t *correlationId);
   alias blpapi_Message_fragmentType=int function(const blpapi_Message_t *message);
   alias blpapi_SessionOptions_maxEventQueueSize=size_t function(blpapi_SessionOptions_t *parameters);
   alias blpapi_SessionOptions_slowConsumerWarningHiWaterMark=float function(blpapi_SessionOptions_t *parameters);
   alias blpapi_SessionOptions_slowConsumerWarningLoWaterMark=float function(blpapi_SessionOptions_t *parameters);
   alias blpapi_SessionOptions_setDefaultKeepAliveInactivityTime=int function(blpapi_SessionOptions_t *parameters,int inactivityTime);
   alias blpapi_SessionOptions_setDefaultKeepAliveResponseTimeout=int function(blpapi_SessionOptions_t *parameters,int responseTimeout);
   alias blpapi_SessionOptions_defaultKeepAliveInactivityTime=int function(blpapi_SessionOptions_t *parameters);
   alias blpapi_SessionOptions_defaultKeepAliveResponseTimeout=int function(blpapi_SessionOptions_t *parameters);
   alias blpapi_HighPrecisionDatetime_compare=int function (const blpapi_HighPrecisionDatetime_t*,const blpapi_HighPrecisionDatetime_t*);
   alias blpapi_HighPrecisionDatetime_print=int function(const blpapi_HighPrecisionDatetime_t*,blpapi_StreamWriter_t,void*,int,int);
   alias blpapi_Element_getValueAsHighPrecisionDatetime=int function(const blpapi_Element_t*,blpapi_HighPrecisionDatetime_t*,size_t);
   alias blpapi_Element_setValueHighPrecisionDatetime=int function(blpapi_Element_t*,const blpapi_HighPrecisionDatetime_t*,size_t);
   alias blpapi_Element_setElementHighPrecisionDatetime=int function(blpapi_Element_t*, const char*, const blpapi_Name_t*, const blpapi_HighPrecisionDatetime_t*);
   alias blpapi_Session_resubscribeWithId=int function(blpapi_Session_t*, const blpapi_SubscriptionList_t*, int, const char*, int);
   alias blpapi_EventFormatter_setValueNull=int function(blpapi_EventFormatter_t *, const char *, const blpapi_Name_t *);
   alias blpapi_DiagnosticsUtil_memoryInfo=int function(char *, size_t);
   alias blpapi_SessionOptions_setKeepAliveEnabled=int function(blpapi_SessionOptions_t *, int);
   alias blpapi_SessionOptions_keepAliveEnabled=int function(blpapi_SessionOptions_t *);
   alias blpapi_SubscriptionList_addResolved=int function(blpapi_SubscriptionList_t *, const char *, const blpapi_CorrelationId_t *);
   alias blpapi_SubscriptionList_isResolvedAt=int function(blpapi_SubscriptionList_t *, int *, size_t);
   alias blpapi_ProviderSession_deregisterService=int function(blpapi_ProviderSession_t *session, const char* serviceName); 
   alias blpapi_ServiceRegistrationOptions_setPartsToRegister=void function(blpapi_ServiceRegistrationOptions_t *session, int parts);
   alias blpapi_ServiceRegistrationOptions_getPartsToRegister=int function(blpapi_ServiceRegistrationOptions_t *session);
   alias blpapi_ProviderSession_deleteTopics= int function(blpapi_ProviderSession_t* session, const blpapi_Topic_t** topics, size_t numTopics);
   alias blpapi_ProviderSession_activateSubServiceCodeRange=int function(blpapi_ProviderSession_t *session, const char* serviceName, int begin, int end, int priority);
   alias blpapi_ProviderSession_deactivateSubServiceCodeRange=int function(blpapi_ProviderSession_t *session, const char* serviceName, int begin, int end);
   alias blpapi_ServiceRegistrationOptions_addActiveSubServiceCodeRange=int function(blpapi_ServiceRegistrationOptions_t *parameters, int start, int end, int priority);
   alias blpapi_ServiceRegistrationOptions_removeAllActiveSubServiceCodeRanges=void function(blpapi_ServiceRegistrationOptions_t *parameters);
   alias blpapi_Logging_logTestMessage=void function(blpapi_Logging_Severity_t severity);
   alias blpapi_getVersionIdentifier=const char function();
   alias blpapi_Message_timeReceived=int function(const blpapi_Message_t *message, blpapi_TimePoint_t *timeReceived);
   alias blpapi_SessionOptions_recordSubscriptionDataReceiveTimes=int function(blpapi_SessionOptions_t *parameters);
   alias blpapi_SessionOptions_setRecordSubscriptionDataReceiveTimes=void function(blpapi_SessionOptions_t *parameters, int shouldRecord);
   alias blpapi_TimePointUtil_nanosecondsBetween=long function(const blpapi_TimePoint_t *start, const blpapi_TimePoint_t *end);
   alias blpapi_HighResolutionClock_now=int function (blpapi_TimePoint_t *timePoint);
   alias blpapi_HighPrecisionDatetime_fromTimePoint=int function(blpapi_HighPrecisionDatetime_t *datetime, const blpapi_TimePoint_t *timePoint, short offset);
  }

   blpapi_FunctionEntries blpapi_FunctionEntries_t;
  alias blpapi_SchemaElementDefinition_t =void*;
  alias blpapi_SchemaTypeDefinition_t=void*;

   extern size_t    g_blpapiFunctionTableSize;
   alias g_blpapiFunctionEntries= blpapi_FunctionEntries_t ;
   blpapi_Name_t* blpapi_Element_name(const blpapi_Element_t *element);
   char* blpapi_Element_nameString(const blpapi_Element_t *element);
   blpapi_SchemaElementDefinition_t* blpapi_Element_definition(const blpapi_Element_t* element);
   int blpapi_Element_datatype (const blpapi_Element_t* element);
   int blpapi_Element_isComplexType(const blpapi_Element_t* element);
   int blpapi_Element_isArray(const blpapi_Element_t* element);
   int blpapi_Element_isReadOnly(const blpapi_Element_t* element);
   size_t blpapi_Element_numValues(const blpapi_Element_t* element);
   size_t blpapi_Element_numElements(const blpapi_Element_t* element);
   int blpapi_Element_isNullValue(const blpapi_Element_t* element, size_t position);
   int blpapi_Element_isNull(const blpapi_Element_t* element);
   int blpapi_Element_print(const blpapi_Element_t* element, blpapi_StreamWriter_t streamWriter, void *stream, int level, int spacesPerLevel);
   int blpapi_Element_getElementAt(const blpapi_Element_t* element, blpapi_Element_t **result, size_t position);
   int blpapi_Element_getElement(const blpapi_Element_t *element, blpapi_Element_t **result, const char* nameString, const blpapi_Name_t *name);
   int blpapi_Element_hasElement(const blpapi_Element_t *element, const char* nameString, const blpapi_Name_t *name);
   int blpapi_Element_hasElementEx(const blpapi_Element_t *element, const char* nameString, const blpapi_Name_t *name, int excludeNullElements, int reserved);
   int blpapi_Element_getValueAsBool(const blpapi_Element_t *element, blpapi_Bool_t *buffer, size_t index);
   int blpapi_Element_getValueAsChar(const blpapi_Element_t *element, blpapi_Char_t *buffer, size_t index);
   int blpapi_Element_getValueAsInt32(const blpapi_Element_t *element, blpapi_Int32_t *buffer, size_t index);
   int blpapi_Element_getValueAsInt64(const blpapi_Element_t *element, blpapi_Int64_t *buffer, size_t index);
   int blpapi_Element_getValueAsFloat32(const blpapi_Element_t *element, blpapi_Float32_t *buffer, size_t index);
   int blpapi_Element_getValueAsFloat64(const blpapi_Element_t *element, blpapi_Float64_t *buffer, size_t index);
   int blpapi_Element_getValueAsString(const blpapi_Element_t *element, const char **buffer, size_t index);
   int blpapi_Element_getValueAsDatetime(const blpapi_Element_t *element, blpapi_Datetime_t *buffer, size_t index);
   int blpapi_Element_getValueAsHighPrecisionDatetime(const blpapi_Element_t *element, blpapi_HighPrecisionDatetime_t *buffer, size_t index);
   int blpapi_Element_getValueAsElement(const blpapi_Element_t *element, blpapi_Element_t **buffer, size_t index);
   int blpapi_Element_getValueAsName(const blpapi_Element_t *element, blpapi_Name_t **buffer, size_t index);
   int blpapi_Element_getChoice(const blpapi_Element_t *element, blpapi_Element_t **result);
   int blpapi_Element_setValueBool(blpapi_Element_t *element, blpapi_Bool_t value, size_t index);
   int blpapi_Element_setValueChar(blpapi_Element_t *element, blpapi_Char_t value, size_t index);
   int blpapi_Element_setValueInt32(blpapi_Element_t *element, blpapi_Int32_t value, size_t index);
   int blpapi_Element_setValueInt64(blpapi_Element_t *element, blpapi_Int64_t value, size_t index);
   int blpapi_Element_setValueFloat32(blpapi_Element_t *element, blpapi_Float32_t value, size_t index);
   int blpapi_Element_setValueFloat64(blpapi_Element_t *element, blpapi_Float64_t value, size_t index);
   int blpapi_Element_setValueString(blpapi_Element_t *element, const char *value, size_t index);
   int blpapi_Element_setValueDatetime(blpapi_Element_t *element, const blpapi_Datetime_t *value, size_t index);
   int blpapi_Element_setValueHighPrecisionDatetime(blpapi_Element_t *element, const blpapi_HighPrecisionDatetime_t *value, size_t index);
   int blpapi_Element_setValueFromElement(blpapi_Element_t *element, blpapi_Element_t *value, size_t index);
   int blpapi_Element_setValueFromName (blpapi_Element_t *element, const blpapi_Name_t *value, size_t index);
   int blpapi_Element_setElementBool(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Bool_t value);
   int blpapi_Element_setElementChar(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Char_t value);
   int blpapi_Element_setElementInt32(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Int32_t value);
   int blpapi_Element_setElementInt64(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Int64_t value);
   int blpapi_Element_setElementFloat32(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Float32_t value);
   int blpapi_Element_setElementFloat64(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Float64_t value);
   int blpapi_Element_setElementString(blpapi_Element_t *element, const char *nameString, const blpapi_Name_t* name, const char *value);
   int blpapi_Element_setElementDatetime(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, const blpapi_Datetime_t *value);
   int blpapi_Element_setElementHighPrecisionDatetime(blpapi_Element_t *element, const char *nameString, const blpapi_Name_t *name, const blpapi_HighPrecisionDatetime_t *value);
   int blpapi_Element_setElementFromField(blpapi_Element_t *element, const char* nameString, const blpapi_Name_t* name, blpapi_Element_t *sourcebuffer);
   int blpapi_Element_setElementFromName (blpapi_Element_t *element, const char* elementName, const blpapi_Name_t* name, const blpapi_Name_t *buffer);
   int blpapi_Element_appendElement (blpapi_Element_t *element, blpapi_Element_t **appendedElement);
   int blpapi_Element_setChoice (blpapi_Element_t *element, blpapi_Element_t **resultElement, const char* nameCstr, const blpapi_Name_t* name, size_t index);

  ulong BLPAPI_RESULTCODE(ulong res)
  {
   return ((res) & 0xffff);
  }
  ulong BLPAPI_RESULTCLASS(ulong res)
  {
   return((res) & 0xff0000);
  }


   char* blpapi_getLastErrorDescription(int resultCode);


   extern(Windows) int blpapi_Event_eventType(const blpapi_Event_t *event);
   int blpapi_Event_addRef(const blpapi_Event_t *event);
   int blpapi_Event_release(const blpapi_Event_t *event);
   blpapi_EventQueue_t* blpapi_EventQueue_create();
   int blpapi_EventQueue_destroy(blpapi_EventQueue_t* eventQueue);
   blpapi_Event_t* blpapi_EventQueue_nextEvent(blpapi_EventQueue_t *eventQueue, int timeout);
   int blpapi_EventQueue_purge(blpapi_EventQueue_t *eventQueue);
   int blpapi_EventQueue_tryNextEvent(blpapi_EventQueue_t *eventQueue, blpapi_Event_t **eventPointer);
   blpapi_MessageIterator_t* blpapi_MessageIterator_create(const blpapi_Event_t *event);
   void blpapi_MessageIterator_destroy(blpapi_MessageIterator_t* iterator);
   int blpapi_MessageIterator_next(blpapi_MessageIterator_t* iterator, blpapi_Message_t** result);
   blpapi_EventFormatter_t *blpapi_EventFormatter_create(blpapi_Event_t *event);
   void blpapi_EventFormatter_destroy(blpapi_EventFormatter_t *victim);
   int blpapi_EventFormatter_appendMessage(blpapi_EventFormatter_t *formatter, const char   *typeString, blpapi_Name_t   *typeName, const blpapi_Topic_t *topic);
   int blpapi_EventFormatter_appendMessageSeq(blpapi_EventFormatter_t *formatter, const char   *typeString, blpapi_Name_t   *typeName, const blpapi_Topic_t *topic, uint   sequenceNumber, uint);
   int blpapi_EventFormatter_appendResponse(blpapi_EventFormatter_t *formatter, const char   *typeString, blpapi_Name_t   *typeName);
   int blpapi_EventFormatter_appendRecapMessage(blpapi_EventFormatter_t *formatter, const blpapi_Topic_t  *topic, const blpapi_CorrelationId_t *cid);
   int blpapi_EventFormatter_appendRecapMessageSeq(blpapi_EventFormatter_t *formatter, const blpapi_Topic_t  *topic, const blpapi_CorrelationId_t *cid,
        uint   sequenceNumber,uint);
   int blpapi_EventFormatter_setValueBool(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, blpapi_Bool_t  value);
   int blpapi_EventFormatter_setValueChar(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, char    value);
   int blpapi_EventFormatter_setValueInt32(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, blpapi_Int32_t   value);
   int blpapi_EventFormatter_setValueInt64(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, blpapi_Int64_t   value);
   int blpapi_EventFormatter_setValueFloat32(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, blpapi_Float32_t  value);
   int blpapi_EventFormatter_setValueFloat64(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, blpapi_Float64_t  value);
   int blpapi_EventFormatter_setValueDatetime(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName,
         const blpapi_Datetime_t *value);

   int blpapi_EventFormatter_setValueString(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName, const char   *value);
   int blpapi_EventFormatter_setValueFromName(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName,
         const blpapi_Name_t  *value);
   int blpapi_EventFormatter_setValueNull(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName);
   int blpapi_EventFormatter_pushElement(blpapi_EventFormatter_t *formatter, const char   *typeString, const blpapi_Name_t  *typeName);
   int blpapi_EventFormatter_popElement(blpapi_EventFormatter_t *formatter);
   int blpapi_EventFormatter_appendValueBool(blpapi_EventFormatter_t *formatter, blpapi_Bool_t  value);
   int blpapi_EventFormatter_appendValueChar(blpapi_EventFormatter_t *formatter, char    value);
   int blpapi_EventFormatter_appendValueInt32(blpapi_EventFormatter_t *formatter, blpapi_Int32_t   value);
   int blpapi_EventFormatter_appendValueInt64(blpapi_EventFormatter_t *formatter, blpapi_Int64_t   value);
   int blpapi_EventFormatter_appendValueFloat32(blpapi_EventFormatter_t *formatter, blpapi_Float32_t  value);
   int blpapi_EventFormatter_appendValueFloat64(blpapi_EventFormatter_t *formatter, blpapi_Float64_t  value);
   int blpapi_EventFormatter_appendValueDatetime(blpapi_EventFormatter_t *formatter, const blpapi_Datetime_t *value);
   int blpapi_EventFormatter_appendValueString(blpapi_EventFormatter_t *formatter, const char   *value);
   int blpapi_EventFormatter_appendValueFromName(blpapi_EventFormatter_t *formatter, const blpapi_Name_t  *value);
   int blpapi_EventFormatter_appendElement(blpapi_EventFormatter_t *formatter);

  struct blpapi_ErrorInfo {
   int exceptionClass;
   char description[256];
  };

  alias blpapi_ErrorInfo_t=blpapi_ErrorInfo ;

   int blpapi_getErrorInfo(blpapi_ErrorInfo_t *buffer, int errorCode);
   blpapi_Name_t* blpapi_Message_messageType(const blpapi_Message_t *message);
   const(char*) blpapi_Message_typeString(const blpapi_Message_t *message);
   char* blpapi_Message_topicName(const blpapi_Message_t *message);
   blpapi_Service_t* blpapi_Message_service(const blpapi_Message_t *message);
   int blpapi_Message_numCorrelationIds(const blpapi_Message_t *message);
   blpapi_CorrelationId_t blpapi_Message_correlationId(const blpapi_Message_t *message, size_t index);
   blpapi_Element_t* blpapi_Message_elements(const blpapi_Message_t *message);
   char *blpapi_Message_privateData(const blpapi_Message_t *message, size_t *size); 
   int blpapi_Message_fragmentType(const blpapi_Message_t *message);
   int blpapi_Message_addRef(const blpapi_Message_t *message); 
   int blpapi_Message_release(const blpapi_Message_t *message);
   int blpapi_Message_timeReceived(const blpapi_Message_t *message, blpapi_TimePoint_t *timeReceived);
   blpapi_Name_t* blpapi_Name_create(const char* nameString);
   void blpapi_Name_destroy(blpapi_Name_t *name);
   blpapi_Name_t* blpapi_Name_duplicate(const blpapi_Name_t *src);
   int blpapi_Name_equalsStr(const blpapi_Name_t *name, const char *string);
   char* blpapi_Name_string(const blpapi_Name_t *name);
   size_t blpapi_Name_length(const blpapi_Name_t *name);
   blpapi_Name_t* blpapi_Name_findName(const char* nameString); 
   alias blpapi_ProviderEventHandler_t=void function(blpapi_Event_t* event, blpapi_ProviderSession_t* session, void* userData);
   blpapi_ProviderSession_t* blpapi_ProviderSession_create(blpapi_SessionOptions_t *parameters, blpapi_ProviderEventHandler_t handler, blpapi_EventDispatcher_t *dispatcher, void *userData);
   void blpapi_ProviderSession_destroy(blpapi_ProviderSession_t *session);
   int blpapi_ProviderSession_start(blpapi_ProviderSession_t *session);
   int blpapi_ProviderSession_startAsync(blpapi_ProviderSession_t *session);
   int blpapi_ProviderSession_stop(blpapi_ProviderSession_t *session);
   int blpapi_ProviderSession_stopAsync(blpapi_ProviderSession_t *session);
   int blpapi_ProviderSession_nextEvent(blpapi_ProviderSession_t *session, blpapi_Event_t **eventPointer, uint timeoutInMilliseconds);
   int blpapi_ProviderSession_tryNextEvent(blpapi_ProviderSession_t *session, blpapi_Event_t **eventPointer);
   int blpapi_ProviderSession_registerService(blpapi_ProviderSession_t *session, const char *serviceName, const blpapi_Identity_t *identity, blpapi_ServiceRegistrationOptions_t *registrationOptions);
   int blpapi_ProviderSession_activateSubServiceCodeRange(blpapi_ProviderSession_t *session, const char* serviceName, int begin, int end, int priority);
   int blpapi_ProviderSession_deactivateSubServiceCodeRange(blpapi_ProviderSession_t *session, const char* serviceName, int begin, int end);
   int blpapi_ProviderSession_registerServiceAsync(blpapi_ProviderSession_t *session, const char *serviceName, const blpapi_Identity_t *identity, blpapi_CorrelationId_t *correlationId, blpapi_ServiceRegistrationOptions_t *registrationOptions);
   int blpapi_ProviderSession_deregisterService(blpapi_ProviderSession_t *session, const char *serviceName);
   int blpapi_ProviderSession_resolve(blpapi_ProviderSession_t *session, blpapi_ResolutionList_t *resolutionList, int resolveMode, const blpapi_Identity_t *identity);
   int blpapi_ProviderSession_resolveAsync(blpapi_ProviderSession_t *session, const blpapi_ResolutionList_t *resolutionList, int resolveMode, const blpapi_Identity_t *identity);
   int blpapi_ProviderSession_createTopics(blpapi_ProviderSession_t *session, blpapi_TopicList_t *topicList, int resolveMode, const blpapi_Identity_t *identity);
   int blpapi_ProviderSession_createTopicsAsync(blpapi_ProviderSession_t *session, const blpapi_TopicList_t *topicList, int resolveMode, const blpapi_Identity_t *identity);
   int blpapi_ProviderSession_getTopic(blpapi_ProviderSession_t *session, const blpapi_Message_t *message, blpapi_Topic_t **topic);
   int blpapi_ProviderSession_createTopic(blpapi_ProviderSession_t *session, const blpapi_Message_t *message, blpapi_Topic_t **topic);
   int blpapi_ProviderSession_createServiceStatusTopic(blpapi_ProviderSession_t *session, const blpapi_Service_t *service, blpapi_Topic_t **topic);
   int blpapi_ProviderSession_deleteTopics(blpapi_ProviderSession_t* session, const blpapi_Topic_t** topics, size_t numTopics);
   int blpapi_ProviderSession_publish(blpapi_ProviderSession_t *session, blpapi_Event_t *event);
   int blpapi_ProviderSession_sendResponse(blpapi_ProviderSession_t *session, blpapi_Event_t *event, int isPartialResponse);
   blpapi_AbstractSession_t *blpapi_ProviderSession_getAbstractSession(blpapi_ProviderSession_t *session);
   blpapi_ServiceRegistrationOptions_t* blpapi_ServiceRegistrationOptions_create();
   blpapi_ServiceRegistrationOptions_t* blpapi_ServiceRegistrationOptions_duplicate(const blpapi_ServiceRegistrationOptions_t *parameters);
   void blpapi_ServiceRegistrationOptions_destroy(blpapi_ServiceRegistrationOptions_t *parameters);
   void blpapi_ServiceRegistrationOptions_copy(blpapi_ServiceRegistrationOptions_t *lhs, const blpapi_ServiceRegistrationOptions_t *rhs);
   int blpapi_ServiceRegistrationOptions_addActiveSubServiceCodeRange(blpapi_ServiceRegistrationOptions_t *parameters, int start, int end, int priority);
   void blpapi_ServiceRegistrationOptions_removeAllActiveSubServiceCodeRanges(blpapi_ServiceRegistrationOptions_t *parameters);
   void blpapi_ServiceRegistrationOptions_setGroupId(blpapi_ServiceRegistrationOptions_t *parameters, const char *groupId, uint groupIdLength);
   int blpapi_ServiceRegistrationOptions_setServicePriority(blpapi_ServiceRegistrationOptions_t *parameters, int priority);
   void blpapi_ServiceRegistrationOptions_setPartsToRegister(blpapi_ServiceRegistrationOptions_t *parameters, int parts);
   int blpapi_ServiceRegistrationOptions_getGroupId(blpapi_ServiceRegistrationOptions_t *parameters, char *groupdIdBuffer, int *groupIdLength);
   int blpapi_ServiceRegistrationOptions_getServicePriority(blpapi_ServiceRegistrationOptions_t *parameters);
   int blpapi_ServiceRegistrationOptions_getPartsToRegister(blpapi_ServiceRegistrationOptions_t *parameters);
  struct blpapi_ResolutionList;
  alias blpapi_ResolutionList_t=blpapi_ResolutionList ;
   blpapi_Element_t* blpapi_ResolutionList_extractAttributeFromResolutionSuccess(const blpapi_Message_t* message, const blpapi_Name_t* attribute);
   blpapi_ResolutionList_t* blpapi_ResolutionList_create(blpapi_ResolutionList_t* from);
   void blpapi_ResolutionList_destroy(blpapi_ResolutionList_t *list);
   int blpapi_ResolutionList_add(blpapi_ResolutionList_t* list, const char* topic, const blpapi_CorrelationId_t *correlationId);
   int blpapi_ResolutionList_addFromMessage(blpapi_ResolutionList_t* list, const blpapi_Message_t* topic, const blpapi_CorrelationId_t *correlationId);
   int blpapi_ResolutionList_addAttribute(blpapi_ResolutionList_t* list, const blpapi_Name_t* name);
   int blpapi_ResolutionList_correlationIdAt(const blpapi_ResolutionList_t* list, blpapi_CorrelationId_t* result, size_t index);
   int blpapi_ResolutionList_topicString(const blpapi_ResolutionList_t* list, const char** topic, const blpapi_CorrelationId_t* id);
   int blpapi_ResolutionList_topicStringAt(const blpapi_ResolutionList_t* list, const char** topic, size_t index);
   int blpapi_ResolutionList_status(const blpapi_ResolutionList_t* list, int* status, const blpapi_CorrelationId_t* id);
   int blpapi_ResolutionList_statusAt(const blpapi_ResolutionList_t* list, int* status, size_t index);
   int blpapi_ResolutionList_attribute(const blpapi_ResolutionList_t* list, blpapi_Element_t** element, const blpapi_Name_t* attribute, const blpapi_CorrelationId_t* id);
   int blpapi_ResolutionList_attributeAt(const blpapi_ResolutionList_t* list, blpapi_Element_t** element, const blpapi_Name_t* attribute, size_t index);
   int blpapi_ResolutionList_message(const blpapi_ResolutionList_t* list, blpapi_Message_t** element, const blpapi_CorrelationId_t* id);
   int blpapi_ResolutionList_messageAt(const blpapi_ResolutionList_t* list, blpapi_Message_t** element, size_t index);
   int blpapi_ResolutionList_size(const blpapi_ResolutionList_t* list);
   blpapi_Name_t *blpapi_SchemaElementDefinition_name(const blpapi_SchemaElementDefinition_t *field);
   char *blpapi_SchemaElementDefinition_description(const blpapi_SchemaElementDefinition_t *field);
   int blpapi_SchemaElementDefinition_status(const blpapi_SchemaElementDefinition_t *field);
   blpapi_SchemaTypeDefinition_t *blpapi_SchemaElementDefinition_type(const blpapi_SchemaElementDefinition_t *field);
   size_t blpapi_SchemaElementDefinition_numAlternateNames(const blpapi_SchemaElementDefinition_t *field);
   blpapi_Name_t *blpapi_SchemaElementDefinition_getAlternateName(const blpapi_SchemaElementDefinition_t *field, size_t index);
   size_t blpapi_SchemaElementDefinition_minValues(const blpapi_SchemaElementDefinition_t *field);
   size_t blpapi_SchemaElementDefinition_maxValues(const blpapi_SchemaElementDefinition_t *field);
   int blpapi_SchemaElementDefinition_print(const blpapi_SchemaElementDefinition_t *element, blpapi_StreamWriter_t streamWriter, void *userStream, int level, int spacesPerLevel);
   void blpapi_SchemaElementDefinition_setUserData(blpapi_SchemaElementDefinition_t *field, void *userdata);
   void *blpapi_SchemaElementDefinition_userData(const blpapi_SchemaElementDefinition_t *field);
   blpapi_Name_t *blpapi_SchemaTypeDefinition_name(const blpapi_SchemaTypeDefinition_t *type);
   char *blpapi_SchemaTypeDefinition_description(const blpapi_SchemaTypeDefinition_t *type);
   int blpapi_SchemaTypeDefinition_status(const blpapi_SchemaTypeDefinition_t *type);
   int blpapi_SchemaTypeDefinition_datatype(const blpapi_SchemaTypeDefinition_t *type);
   int blpapi_SchemaTypeDefinition_isComplexType(const blpapi_SchemaTypeDefinition_t *type);
   int blpapi_SchemaTypeDefinition_isSimpleType(const blpapi_SchemaTypeDefinition_t *type);
   int blpapi_SchemaTypeDefinition_isEnumerationType(const blpapi_SchemaTypeDefinition_t *type);
   int blpapi_SchemaTypeDefinition_isComplex(const blpapi_SchemaTypeDefinition_t *type);
   int blpapi_SchemaTypeDefinition_isSimple(const blpapi_SchemaTypeDefinition_t *type);
   int blpapi_SchemaTypeDefinition_isEnumeration(const blpapi_SchemaTypeDefinition_t *type);
   size_t blpapi_SchemaTypeDefinition_numElementDefinitions(const blpapi_SchemaTypeDefinition_t *type);
   blpapi_SchemaElementDefinition_t* blpapi_SchemaTypeDefinition_getElementDefinition(const blpapi_SchemaTypeDefinition_t *type, const char *nameString, const blpapi_Name_t *name);
   blpapi_SchemaElementDefinition_t* blpapi_SchemaTypeDefinition_getElementDefinitionAt(const blpapi_SchemaTypeDefinition_t *type, size_t index);
   int blpapi_SchemaTypeDefinition_print(const blpapi_SchemaTypeDefinition_t *element, blpapi_StreamWriter_t streamWriter, void *userStream, int level, int spacesPerLevel);
   void blpapi_SchemaTypeDefinition_setUserData(blpapi_SchemaTypeDefinition_t *element, void *userdata);
   void *blpapi_SchemaTypeDefinition_userData(const blpapi_SchemaTypeDefinition_t *element);
   blpapi_ConstantList_t* blpapi_SchemaTypeDefinition_enumeration(const blpapi_SchemaTypeDefinition_t *element);
   char* blpapi_Operation_name(blpapi_Operation_t *service);
   char* blpapi_Operation_description(blpapi_Operation_t *service);
   int blpapi_Operation_requestDefinition(blpapi_Operation_t *service, blpapi_SchemaElementDefinition_t **requestDefinition);
   int blpapi_Operation_numResponseDefinitions(blpapi_Operation_t *service);
   int blpapi_Operation_responseDefinition(blpapi_Operation_t *service, blpapi_SchemaElementDefinition_t **responseDefinition, size_t index);
   char* blpapi_Service_name(blpapi_Service_t *service);
   char* blpapi_Service_description(blpapi_Service_t *service);
   int blpapi_Service_numOperations(blpapi_Service_t *service);
   int blpapi_Service_numEventDefinitions(blpapi_Service_t *service); 
   int blpapi_Service_addRef(blpapi_Service_t *service);
   void blpapi_Service_release(blpapi_Service_t *service);
   char* blpapi_Service_authorizationServiceName(blpapi_Service_t *service);
   int blpapi_Service_getOperation(blpapi_Service_t *service, blpapi_Operation_t **operation, const char* nameString, const blpapi_Name_t *name);
   int blpapi_Service_getOperationAt(blpapi_Service_t *service, blpapi_Operation_t **operation, size_t index);
   int blpapi_Service_getEventDefinition(blpapi_Service_t *service, blpapi_SchemaElementDefinition_t **result, const char* nameString, const blpapi_Name_t *name);
   int blpapi_Service_getEventDefinitionAt(blpapi_Service_t *service, blpapi_SchemaElementDefinition_t **result, size_t index);
   int blpapi_Service_createRequest(blpapi_Service_t* service, blpapi_Request_t** request, const char *operation);
   int blpapi_Service_createAuthorizationRequest(blpapi_Service_t* service, blpapi_Request_t** request, const char *operation);
   int blpapi_Service_createPublishEvent(blpapi_Service_t* service, blpapi_Event_t** event);
   int blpapi_Service_createAdminEvent(blpapi_Service_t* service, blpapi_Event_t** event);
   int blpapi_Service_createResponseEvent(blpapi_Service_t* service, const blpapi_CorrelationId_t* correlationId, blpapi_Event_t** event);
   int blpapi_Service_print(const blpapi_Service_t* service, blpapi_StreamWriter_t streamWriter, void *stream, int level, int spacesPerLevel);
   extern(Windows)blpapi_SessionOptions_t *blpapi_SessionOptions_create();
   blpapi_SessionOptions_t *blpapi_SessionOptions_duplicate(const blpapi_SessionOptions_t *parameters);
   void blpapi_SessionOptions_copy(blpapi_SessionOptions_t  *lhs, const blpapi_SessionOptions_t *rhs);
   void blpapi_SessionOptions_destroy(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_setServerHost(blpapi_SessionOptions_t *parameters, const char   *serverHost);
   int blpapi_SessionOptions_setServerPort(blpapi_SessionOptions_t *parameters, ushort   serverPort);
   int blpapi_SessionOptions_setServerAddress(blpapi_SessionOptions_t *parameters, const char   *serverHost, ushort   serverPort, size_t    index);
   int blpapi_SessionOptions_removeServerAddress(blpapi_SessionOptions_t *parameters, size_t    index);
   int blpapi_SessionOptions_setConnectTimeout(blpapi_SessionOptions_t *parameters, uint   timeoutInMilliseconds);
   int blpapi_SessionOptions_setDefaultServices(blpapi_SessionOptions_t *parameters, const char   *defaultServices);
   int blpapi_SessionOptions_setDefaultSubscriptionService(blpapi_SessionOptions_t *parameters, const char   *serviceIdentifier);
   void blpapi_SessionOptions_setDefaultTopicPrefix(blpapi_SessionOptions_t *parameters, const char   *prefix);
   void blpapi_SessionOptions_setAllowMultipleCorrelatorsPerMsg(blpapi_SessionOptions_t *parameters, int    allowMultipleCorrelatorsPerMsg);
   void blpapi_SessionOptions_setClientMode(blpapi_SessionOptions_t *parameters, int    clientMode);
   void blpapi_SessionOptions_setMaxPendingRequests(blpapi_SessionOptions_t *parameters, int    maxPendingRequests);
   void blpapi_SessionOptions_setAutoRestartOnDisconnection(blpapi_SessionOptions_t *parameters, int    autoRestart);
   void blpapi_SessionOptions_setAutoRestart(blpapi_SessionOptions_t *parameters, int    autoRestart);
   void blpapi_SessionOptions_setAuthenticationOptions(blpapi_SessionOptions_t *parameters, const char   *authOptions);
   void blpapi_SessionOptions_setNumStartAttempts(blpapi_SessionOptions_t *parameters, int    numStartAttempts);
   void blpapi_SessionOptions_setMaxEventQueueSize(blpapi_SessionOptions_t *parameters, size_t    maxEventQueueSize);
   int blpapi_SessionOptions_setSlowConsumerWarningHiWaterMark(blpapi_SessionOptions_t *parameters, float    hiWaterMark);
   int blpapi_SessionOptions_setSlowConsumerWarningLoWaterMark(blpapi_SessionOptions_t *parameters, float    loWaterMark);
   int blpapi_SessionOptions_setDefaultKeepAliveInactivityTime(blpapi_SessionOptions_t *parameters, int    inactivityMsecs);
   int blpapi_SessionOptions_setDefaultKeepAliveResponseTimeout(blpapi_SessionOptions_t *parameters, int    timeoutMsecs);
   int blpapi_SessionOptions_setKeepAliveEnabled(blpapi_SessionOptions_t *parameters, int    isEnabled);
   void blpapi_SessionOptions_setRecordSubscriptionDataReceiveTimes(blpapi_SessionOptions_t *parameters, int    shouldRecord);
    char *blpapi_SessionOptions_serverHost(blpapi_SessionOptions_t *parameters);
   uint blpapi_SessionOptions_serverPort(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_numServerAddresses(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_getServerAddress(blpapi_SessionOptions_t *parameters, const char   **serverHost, ushort   *serverPort, size_t    index);
   uint blpapi_SessionOptions_connectTimeout(blpapi_SessionOptions_t *parameters);
   char *blpapi_SessionOptions_defaultServices(blpapi_SessionOptions_t *parameters);
   char *blpapi_SessionOptions_defaultSubscriptionService(blpapi_SessionOptions_t *parameters);
   char *blpapi_SessionOptions_defaultTopicPrefix(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_allowMultipleCorrelatorsPerMsg(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_clientMode(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_maxPendingRequests(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_autoRestartOnDisconnection(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_autoRestart(blpapi_SessionOptions_t *parameters);
   char *blpapi_SessionOptions_authenticationOptions(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_numStartAttempts(blpapi_SessionOptions_t *parameters);
   size_t blpapi_SessionOptions_maxEventQueueSize(blpapi_SessionOptions_t *parameters);
   float blpapi_SessionOptions_slowConsumerWarningHiWaterMark(blpapi_SessionOptions_t *parameters);
   float blpapi_SessionOptions_slowConsumerWarningLoWaterMark(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_defaultKeepAliveInactivityTime(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_defaultKeepAliveResponseTimeout(blpapi_SessionOptions_t *parameters);
   int blpapi_SessionOptions_keepAliveEnabled(blpapi_SessionOptions_t *parameters);
  int blpapi_SessionOptions_recordSubscriptionDataReceiveTimes(blpapi_SessionOptions_t *parameters);
  alias blpapi_StreamWriter_t=int function(const char* data, int length, void *stream);
   blpapi_SubscriptionList_t *blpapi_SubscriptionList_create();
   void blpapi_SubscriptionList_destroy(blpapi_SubscriptionList_t *list);
   int blpapi_SubscriptionList_add(blpapi_SubscriptionList_t  *list, const char    *subscriptionString, const blpapi_CorrelationId_t *correlationId, const char    **fields, const char    **options, size_t     numfields, size_t     numOptions);
   int blpapi_SubscriptionList_addResolved(blpapi_SubscriptionList_t *list, const char    *subscriptionString, const blpapi_CorrelationId_t *correlationId);
   int blpapi_SubscriptionList_clear(blpapi_SubscriptionList_t *list);
   int blpapi_SubscriptionList_append(blpapi_SubscriptionList_t  *dest, const blpapi_SubscriptionList_t *src);
   int blpapi_SubscriptionList_size(const blpapi_SubscriptionList_t *list);
   int blpapi_SubscriptionList_correlationIdAt(const blpapi_SubscriptionList_t *list, blpapi_CorrelationId_t  *result, size_t     index);
   int blpapi_SubscriptionList_topicStringAt(blpapi_SubscriptionList_t *list, const char   **result, size_t    index);
   int blpapi_SubscriptionList_isResolvedAt(blpapi_SubscriptionList_t *list, int     *result, size_t    index);

  struct blpapi_TimePoint {
   blpapi_Int64_t d_value;
  }
   blpapi_Topic_t* blpapi_Topic_create(blpapi_Topic_t* from);
   void blpapi_Topic_destroy(blpapi_Topic_t* victim);
   int blpapi_Topic_compare(const blpapi_Topic_t* lhs, const blpapi_Topic_t* rhs);
   blpapi_Service_t* blpapi_Topic_service(const blpapi_Topic_t *topic);
   int blpapi_Topic_isActive(const blpapi_Topic_t *topic);
  struct blpapi_TopicList;
  alias blpapi_TopicList_t = blpapi_TopicList;
   blpapi_TopicList_t* blpapi_TopicList_create(blpapi_TopicList_t* from);
   void blpapi_TopicList_destroy(blpapi_TopicList_t *list);
   int blpapi_TopicList_add(blpapi_TopicList_t* list, const char* topic, const blpapi_CorrelationId_t *correlationId);
   int blpapi_TopicList_addFromMessage(blpapi_TopicList_t* list, const blpapi_Message_t* topic, const blpapi_CorrelationId_t *correlationId);
   int blpapi_TopicList_correlationIdAt(const blpapi_TopicList_t* list, blpapi_CorrelationId_t* result, size_t index);
   int blpapi_TopicList_topicString(const blpapi_TopicList_t* list, const char** topic, const blpapi_CorrelationId_t* id);
   int blpapi_TopicList_topicStringAt(const blpapi_TopicList_t* list, const char** topic, size_t index);
   int blpapi_TopicList_status(const blpapi_TopicList_t* list, int* status, const blpapi_CorrelationId_t* id);
   int blpapi_TopicList_statusAt(const blpapi_TopicList_t* list, int* status, size_t index);
   int blpapi_TopicList_message(const blpapi_TopicList_t* list, blpapi_Message_t** element, const blpapi_CorrelationId_t* id);
   int blpapi_TopicList_messageAt(const blpapi_TopicList_t* list, blpapi_Message_t** element, size_t index);
   int blpapi_TopicList_size(const blpapi_TopicList_t* list);
  alias blpapi_Bool_t = int;
  alias blpapi_Char_t=byte;
  alias blpapi_UChar_t=ubyte;
  alias blpapi_Int16_t=short;
  alias blpapi_UInt16_t=ushort;
  alias blpapi_Int32_t =int; 
  alias blpapi_UInt32_t=uint;
  alias blpapi_Int64_t = long;
  alias blpapi_UInt64_t = ulong;
  alias blpapi_Float32_t=float;
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

  enum blpapi_Logging_Severity_t
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
  alias blpapi_AbstractSession_t= blpapi_AbstractSession ;

  struct blpapi_Constant;
  alias blpapi_Constant_t=blpapi_Constant ;

  struct blpapi_ConstantList;
  alias blpapi_ConstantList_t=blpapi_ConstantList ;

  struct blpapi_Element;
  alias blpapi_Element_t=blpapi_Element ;

  struct blpapi_Event;
  alias blpapi_Event_t=blpapi_Event ;

  struct blpapi_EventDispatcher;
  alias blpapi_EventDispatcher_t=blpapi_EventDispatcher ;

  struct blpapi_EventQueue;
  alias blpapi_EventQueue_t=blpapi_EventQueue;

  struct blpapi_MessageIterator;
  alias blpapi_MessageIterator_t=blpapi_MessageIterator ;

  struct blpapi_Name;
  alias blpapi_Name_t=blpapi_Name ;

  struct blpapi_Operation;
  alias blpapi_Operation_t=blpapi_Operation ;

  struct blpapi_ProviderSession;
  alias blpapi_ProviderSession_t=blpapi_ProviderSession ;

  struct blpapi_Service;
  alias  blpapi_Service_t=blpapi_Service;

  struct blpapi_Session;
  alias blpapi_Session_t=blpapi_Session ;

  struct blpapi_SessionOptions;
  alias blpapi_SessionOptions_t = blpapi_SessionOptions ;

  struct blpapi_SubscriptionItrerator;
  alias blpapi_SubscriptionIterator_t = blpapi_SubscriptionItrerator ;

  struct blpapi_Identity;
  alias blpapi_UserHandle=blpapi_Identity;
  alias blpapi_UserHandle_t= blpapi_Identity;
  alias blpapi_Identity_t = blpapi_Identity ;

   void blpapi_getVersionInfo(int *majorVersion, int *minorVersion, int *patchVersion, int *buildVersion);
    char *blpapi_getVersionIdentifier();

  // will make it a template later
  long BLPAPI_MAKE_VERSION(long MAJOR, long MINOR, long PATCH)
  {
   return((MAJOR) * 65536 + (MINOR) * 256 + (PATCH));
  }
   
  long BLPAPI_SDK_VERSION()
  {
      return BLPAPI_MAKE_VERSION(BLPAPI.VERSION_MAJOR, BLPAPI.VERSION_MINOR, BLPAPI.VERSION_PATCH);
  }
  
  alias blpapi_EventHandler_t= void function(blpapi_Event_t* event, blpapi_Session_t* session, void *userData);
}
  extern(Windows)
  {
  blpapi_Session_t* blpapi_Session_create(blpapi_SessionOptions_t *parameters, blpapi_EventHandler_t handler, blpapi_EventDispatcher_t* dispatcher, void *userData);
  extern(Windows) void blpapi_Session_destroy(blpapi_Session_t *session);
  extern(Windows) int blpapi_Session_start(blpapi_Session_t *session);
  int blpapi_Session_startAsync(blpapi_Session_t *session);
  int blpapi_Session_stop(blpapi_Session_t* session);
  int blpapi_Session_stopAsync(blpapi_Session_t* session);
  int blpapi_Session_nextEvent(blpapi_Session_t* session, blpapi_Event_t **eventPointer, uint timeoutInMilliseconds);
  int blpapi_Session_tryNextEvent(blpapi_Session_t* session, blpapi_Event_t **eventPointer);
  int blpapi_Session_subscribe(blpapi_Session_t *session, const blpapi_SubscriptionList_t *subscriptionList, const blpapi_Identity_t* handle, const char *requestLabel, int requestLabelLen);
  int blpapi_Session_resubscribe(blpapi_Session_t *session, const blpapi_SubscriptionList_t *resubscriptionList, const char *requestLabel, int requestLabelLen);
  int blpapi_Session_resubscribeWithId(blpapi_Session_t *session, const blpapi_SubscriptionList_t *resubscriptionList, int resubscriptionId, const char *requestLabel, int requestLabelLen);
  int blpapi_Session_unsubscribe(blpapi_Session_t *session, const blpapi_SubscriptionList_t *unsubscriptionList, const char *requestLabel, int requestLabelLen);
  int blpapi_Session_cancel(blpapi_Session_t *session, const blpapi_CorrelationId_t *correlationIds, size_t numCorrelationIds, const char *requestLabel, int requestLabelLen);
  int blpapi_Session_setStatusCorrelationId(blpapi_Session_t *session, const blpapi_Service_t *service, const blpapi_Identity_t *identity, const blpapi_CorrelationId_t *correlationId);
  int blpapi_Session_sendRequest(blpapi_Session_t *session, const blpapi_Request_t *request, blpapi_CorrelationId_t *correlationId, blpapi_Identity_t *identity, blpapi_EventQueue_t *eventQueue, const char *requestLabel, int requestLabelLen);
  int blpapi_Session_sendAuthorizationRequest(blpapi_Session_t *session, const blpapi_Request_t *request, blpapi_Identity_t *identity, blpapi_CorrelationId_t *correlationId, blpapi_EventQueue_t *eventQueue, const char *requestLabel, int requestLabelLen);
  int blpapi_Session_openService(blpapi_Session_t *session, const char* serviceName);
  int blpapi_Session_openServiceAsync(blpapi_Session_t *session, const char* serviceName, blpapi_CorrelationId_t *correlationId);
  int blpapi_Session_generateToken(blpapi_Session_t *session, blpapi_CorrelationId_t *correlationId, blpapi_EventQueue_t *eventQueue);
  int blpapi_Session_getService(blpapi_Session_t *session, blpapi_Service_t **service, const char* serviceName);
  blpapi_UserHandle_t* blpapi_Session_createUserHandle(blpapi_Session_t *session);
  blpapi_Identity_t* blpapi_Session_createIdentity(blpapi_Session_t *session);
  blpapi_AbstractSession_t* blpapi_Session_getAbstractSession(blpapi_Session_t* session);
  blpapi_SubscriptionIterator_t* blpapi_SubscriptionItr_create(blpapi_Session_t *session);
  void blpapi_SubscriptionItr_destroy(blpapi_SubscriptionIterator_t *iterator);
  int blpapi_SubscriptionItr_next(blpapi_SubscriptionIterator_t *iterator, const char** subscriptionString, blpapi_CorrelationId_t *correlationId, int *status);
  int blpapi_SubscriptionItr_isValid(const blpapi_SubscriptionIterator_t *iterator);

  void blpapi_Request_destroy(blpapi_Request_t *request);
  blpapi_Element_t* blpapi_Request_elements(blpapi_Request_t *request);
  void blpapi_Request_setPreferredRoute(blpapi_Request_t *request, blpapi_CorrelationId_t *correlationId);
} // extern (Windows)
