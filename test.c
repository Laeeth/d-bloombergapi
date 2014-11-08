#include <stdio.h>

struct _blp {
    unsigned int  size:8;       // fill in the size of this struct
    unsigned int  valueType:4;  // type of value held by this correlation id
    unsigned int  classId:16;   // user defined classification id
    unsigned int  reserved:4;   // for internal use must be 0
};

void main()
{
	struct _blp blp;
	printf("%d\n",sizeof(blp));
	void *ptr1, *ptr2, *ptr3, *ptr4, *ptr5;
	ptr1=&blp;
	ptr2=&blp.size;
	ptr3=&blp.valueType;
	ptr4=&blp.classId;
	ptr5=&blp.reserved;
	printf("%d,%d,%d,%d",ptr2-ptr1,ptr3-ptr1,ptr4-ptr1,ptr5-ptr1);
}