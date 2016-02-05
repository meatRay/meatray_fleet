/++Authors: meatRay+/
module theatre.logging;

import std.stdio :writeln;

/+
 + Big Qs!
 + Should LogDetail = highs get "downgraded" or "ignored"?
 + Should allow string formatting?  
 +  - Maybe allow just /a/ string?
 + Should LogDetail be flags?  <- Yes that's fucking radical
 +/

enum LogDetail{ None = 0, Low = 1, Medium = 2, High = 4, Ingore_High = 3, Ignore_Low = 6, All = 7  };
LogDetail DefaultDetail = LogDetail.High;
LogDetail LogDetails = LogDetail.All;

private LogDetail HighestDetail (LogDetail detail)
{
    if (!detail)
    	return LogDetail.None;
    LogDetail roller = LogDetail.Low;
    while (detail >>= 1)
    	{ roller <<= 1; }
    return roller;
}

/+
 + Logs should just be writefln++ that allows for dif. detail on LogDetail
 +/

/+Make Threadsafe!+/
void Log( ILogged logged )
	{ Log( DefaultDetail, logged ); }
/+Merge too?+/
void Log( string logged )
	{ Log( DefaultDetail, logged ); }
void Log( LogDetail detail_level, ILogged logged ) 
in{ assert(detail_level == DetailLevel.Low || detail_level == DetailLevel.Medium || detail_level == DetailLevel.High); }
body
{
	detail_level = HighestDetail( detail_level & LogDetails );
	if( detail_level )
		{ writeln( logged.FormatLog(detail_level) ); }
}
/+Compact with above using sneak D swizzling+/
void Log( LogDetail detail_level, string logged )
{
	detail_level = HighestDetail( detail_level & LogDetails );
	if( detail_level )
		{ writeln( logged ); }
}

interface ILogged
{
	public string FormatLog( LogDetail detail_level );
}