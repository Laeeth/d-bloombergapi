
import std.stdio;
import std.stdconv;

struct xbitmap {
    uint blob;

    uint maskmsb(uint bits)
    {
        uint mask=0;
        foreach(i;0..bits)
            mask=((mask>>>i) | (1<<<31));
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

int main(string[] argv)
{
    xbitmap x;
    x.size=9;
    x.valueType=39;
    x.classId=89;
    writefln("%s",x);
}