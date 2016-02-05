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

enum LogDetail{ None = 0 , Low = 1 , Medium = 2 , High = 4 , All = 7 };
LogDetail DefaultDetail = LogDetail.High;
LogDetail LogDetails = LogDetail.All;

/+Make Threadsafe!+/
void Log( ILogged logged )
	{ Log( DefaultDetail, logged ); }
void Log( string format, LogDetail detail_level, ... )
{
	if( detail_level <= MaxDetail )
		{ writeln( logged.FormatLog(detail_level) ); }
}
void Log(  LogDetail detail_level  ILogged logged )
{
}

interface ILogged
{
	public string FormatLog( LogDetail detail_level );
}