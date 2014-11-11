module blputils;

import std.stdio : writefln;

version(Windows)
{
	extern(C) int kbhit();
	extern(C) int getch();

	char wait_key()
	{
    	while(!kbhit())
    	{
	        // keep polling
    	    // might use Thread.Sleep here to avoid taxing the cpu.
    	}
	    return cast(char)getch();
	}
}

else // version(!Windows)
{
	import std.c.stdio;
	import std.c.linux.termios;
	extern(C) void cfmakeraw(termios *termios_p);

	char wait_key() 
	{
	    termios  ostate;                 /* saved tty state */
	    termios  nstate;                 /* values for editor mode */

   	    // Open stdin in raw mode
    	/* Adjust output channel        */
	    tcgetattr(1, &ostate);                       /* save old state */
	    tcgetattr(1, &nstate);                       /* get base of new state */
	    cfmakeraw(&nstate);
	    tcsetattr(1, TCSADRAIN, &nstate);      /* set mode */

	      // Read characters in raw mode
	    char c=cast(char)fgetc(stdin);
	       // Close
	    tcsetattr(1, TCSADRAIN, &ostate);       // return to original mode
	    return c;
	}
}