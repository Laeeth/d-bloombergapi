
import std.stdio;
import std.conv;
import std.format;
import std.string;

string binarytostring(T)(T myinp)
{
  string s="";
  auto inplen=cast(ulong)myinp.sizeof*8;
  auto inp=cast(ulong)myinp;
  foreach(i;1L..inplen+1L)
  {
    debug
    {
      writefln("inp=%s,inplen-i=%s,i=%s,1<<inplen-i=%s,inp&=%s", inp,inplen-i,cast(ulong)(1L<<(inplen-i)),i,cast(ulong)(inp&(1L<<(inplen-i))));
    }

    if ((inp & (1L<<(inplen-i)))>0)
      s~="1";
    else
      s~="0";
  }
  return s;
}

struct xbitmap {
    uint blob;

    uint maskmsb(uint bits)
    {
        uint mask=0;
        foreach(i;0..bits)
            mask=((mask>>1) | (1<<31));
        debug {writefln("maskmsb: bits=%s, mask=%s or %s",bits,mask,binarytostring(mask));}
        return mask;
    }
    uint masklsb(uint bits)
    {
        uint mask=0;
        foreach(i;0..bits)
            mask=((mask<<1) | 1);
        debug {writefln("masklsb: bits=%s, mask=%s or %s",bits,mask,binarytostring(mask));}
        return mask;
    }

    uint mask(uint msbits, uint lsbits)
    {
      return (maskmsb(msbits) | masklsb(lsbits));
    }

    uint extract(uint startpos, uint endpos)
    {
      uint retval;
      if ((endpos<=startpos) || (startpos<0) ||(endpos>32))
        throw new Exception("Invalid bitfield parameters " ~ to!string(startpos) ~ to!string(endpos));
      retval=((blob & mask(startpos,endpos)) >> startpos);
      debug{writefln("extract: startpos=%s, endpos=%s, blob=%s, retval=%s",startpos,endpos,blob,retval);}
      return retval;
    }

    void maskset(uint startpos, uint endpos, uint param)
    {
      debug{writefln("maskset: startpos=%s, endpos=%s, param=%s",startpos,endpos,param);}
      debug{writefln("before=%s or %s",blob,binarytostring(blob));}
      blob=(blob & mask(32-endpos,startpos)) | (param<<startpos);
      debug{writefln("after=%s or %s",blob,binarytostring(blob));}
      return;
      }

    string toString()
    {
      return format("bitmap(size=%s,valueType=%s,classId=%s)",size,valueType,classId);
    }
    @property
    {
      uint size()
      {
        return cast(uint)extract(0,8);
      }
      void size(uint paramsize)
      {
        if ((paramsize<(1<<8)) || (paramsize<0))
          maskset(0,8,paramsize);
        else
          throw new Exception("bitmap set size "~to!string(paramsize)~" out of range for unsigned 8 bits");
      }
      uint valueType()
      {
        debug{writefln("*tricky valuetype binary raw=%s, returned=%s",binarytostring(blob),binarytostring(extract(8,12)));}
        debug{writefln("*tricky valuetype raw=%s, returned=%s",blob,extract(8,12));}
        return cast(uint)extract(8,12);
      }
      void valueType(uint param)
      {
        if ((param<(1<<4)) || (param<0))
          maskset(8,12,param);
        else
          throw new Exception("bitmap set size "~to!string(param)~" out of range for unsigned 4 bits");
        //writefln("*setting valuetype to %s, blob was %s",param,blob);
        //writefln("*now blob is %s",blob);
      }
      uint classId()
      {
        return cast(uint)extract(12,28);
      }
      void classId(uint param)
      {
        if ((param<(1<<16)) || (param<0))
          maskset(12,28,param);
        else
          throw new Exception("bitmap set size "~to!string(param)~" out of range for unsigned 16 bits");
      }
    }
  }

int main(string[] argv)
{
    debug
    {
      foreach(i;0L..64L)
        writefln("%s -> %s",i,binarytostring(i));
    }
    xbitmap x;
    x.size=255;
    x.valueType=12;
    x.classId=89;
    writefln("%s",x);
    return 0;
}