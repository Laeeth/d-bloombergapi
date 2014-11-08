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
    const Name FIELD_ID("id");
    const Name FIELD_MNEMONIC("mnemonic");
    const Name FIELD_DATA("fieldData");
    const Name FIELD_DESC("description");
    const Name FIELD_INFO("fieldInfo");
    const Name FIELD_ERROR("fieldError");
    const Name FIELD_MSG("message");
};

int ID_LEN;
int MNEMONIC_LEN;
int DESC_LEN;
string PADDING;
string APIFLDS_SVC;
string d_host;
int d_port;

void printUsage()
{
    writefln( "Usage:\n"
         "    Retrieve reference data \n"
         "        [-ip        <ipAddress  = localhost>\n"
         "        [-p         <tcpPort    = 8194>\n");
}

bool parseCommandLine(string[] argv)
{
    foreach(i; 1..argv.length)
    {
        if (!(argv[i]=="-ip") && (i + 1 < argv.length)) {
            d_host = argv[++i];
            continue;
        }
        if (!(argv[i]=="-p") &&  (i + 1 < argv.length)) {
            d_port = atoi(argv[++i]);
            continue;
        }
        printUsage();
        return false;
    }
    return true;
}

string padString(string str, uint width)
{
    if (str.length() >= width || str.length() >= PADDING.length() ) return str;
    else return str ~ PADDING.substr(0, width-str.length());
}

void printField (const Element &field)
{
    string  fldId = field.getElementAsString(FIELD_ID);
    if (field.hasElement(FIELD_INFO)) {
        Element fldInfo          = field.getElement (FIELD_INFO) ;
        string  fldMnemonic = fldInfo.getElementAsString(FIELD_MNEMONIC);
        string fldDesc     = fldInfo.getElementAsString(FIELD_DESC);

        writefln("%s %s %s",padString(fldId, ID_LEN),padString(fldMnemonic, MNEMONIC_LEN), padString(fldDesc, DESC_LEN));
         << std::endl;
    }
    else {
        Element fldError = field.getElement(FIELD_ERROR) ;
        string  errorMsg = fldError.getElementAsString(FIELD_MSG) ;

        writefln(" ERROR: %s - %s", fldId, errorMsg);
    }
}
void printHeader ()
{
    writefln("%s %s %s",padString("FIELD ID", ID_LEN),padString("MNEMONIC", MNEMONIC_LEN),padString("DESCRIPTION", DESC_LEN));
    writefln("%s %s %s",padString("-----------", ID_LEN), padString("-----------", MNEMONIC_LEN), padString("-----------", DESC_LEN));
}


public:
SimpleFieldInfoExample():
PADDING("                                            "),
    APIFLDS_SVC("//blp/apiflds") {
        ID_LEN         = 13;
        MNEMONIC_LEN   = 36;
        DESC_LEN       = 40;
}

void run(string[] argv)
{
  d_host = "localhost";
  d_port = 8194;
  if (!parseCommandLine(argc, argv)) return;

  SessionOptions sessionOptions;
  sessionOptions.setServerHost(d_host.c_str());
  sessionOptions.setServerPort(d_port);

  writefln("Connecting to %s:%s",  d_host , d_port);
  Session session(sessionOptions);
  if (!session.start()) {
      stderr.writefln("Failed to start session.");
      return;
  }
  if (!session.openService(APIFLDS_SVC.c_str())) {
      stderr.writefln("Failed to open %s",APIFLDS_SVC);
      return;
  }

  Service fieldInfoService = session.getService(APIFLDS_SVC.c_str());
  Request request = fieldInfoService.createRequest("FieldInfoRequest");
  request.append("id", "LAST_PRICE");
  request.append("id", "pq005");
  request.append("id", "zz0002");

  request.set("returnFieldDocumentation", true);

  writefln("Sending Request: %s" ,request);
  session.sendRequest(request, CorrelationId(this));

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
          printHeader();
          for (int i=0; i < numElements; i++) {
              printField (fields.getValueAsElement(i));
          }
      }
      if (event.eventType() == Event::RESPONSE) {
          break;
      }
  }
}

int main(string[] argv)
{
    SimpleFieldInfoExample example;
    try {
        example.run(argc, argv);
    } catch (Exception &e) {
        stderr.writefln("Library Exception!!! %s", e.description());
    }
    // wait for enter key to exit application
    writefln("Press ENTER to quit");
    char dummy[2];
    std::cin.getline(dummy, 2);
    return 0;
}
