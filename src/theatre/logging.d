/+++/
module theatre.logging;

import std.stdio :writeln;

/+
 + Big Qs!
 + Should LogDetail = highs get "downgraded" or "ignored"?
 + Should allow string formatting?  
 +  - Maybe allow just /a/ string?
 + Should LogDetail be flags?  <- Yes that's fucking radical
 +/

enum LogDetail{ None, Low, Medium, High };
LogDetail DefaultDetail = LogDetail.High;
LogDetail MaxDetail = LogDetail.High;

/+Make Threadsafe!+/
void Log( ILogged logged )
	{ Log( DefaultDetail, logged ); }
void Log( string format, LogDetail detail_level, ... )
{
	detail_level = detail_level > MaxDetail ? MaxDetail : detail_level;
	writeln( logged.FormatLog(detail_level) );
}
void Log(  LogDetail detail_level  ILogged logged )
{
}

interface ILogged
{
	public string FormatLog( LogDetail detail_level );
}