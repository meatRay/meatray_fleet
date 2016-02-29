/++Authors: meatRay+/
module fleet.ship;

import theatre.rendering;
import theatre.logging;
import gl3n.linalg;

debug import std.stdio;
import std.math;
import std.algorithm;
import std.container: SList;
import std.array;

class Ship :IRenderer
{
public: /+----    Variables    ----+/
	 SList!(Vector!(float,2)) Path;
	 SList!IRenderer Path_Debug_Render;
	 Chunk[] Chunks;
	 Chunk Controller;
	 
private:
	const float TURNS = 0.5f *PI;
	const float SPEED = 8f;
	float _tick=1f;
	
public: /+----    Functions    ----+/
	
	public void Render( mat4 pv, int _transformUniform ,int _colourUniform )
	{
		foreach( node; Path_Debug_Render )
		{
			node.Render(pv, _transformUniform, _colourUniform);
		}
		foreach( chunk; Chunks )
		{
			chunk.Renderer.Render(pv, _transformUniform, _colourUniform);
		}
	}
	
	public void Update( float delta_time )
	{
		if( !Path.empty )
		{
			auto delta = Path.front - Controller.Position.xy;
			
			float ang = (atan2( delta.y, delta.x ) -PI_2);
			float a2 = ang -(2f *PI);
			float a3 = ang +(2f *PI);
			if( _tick >= 0.4f )
			{
				/+Doesn't happen often, but take this out of debug ticks+/
				Controller.Z_Rotation = fmod(Controller.Z_Rotation, PI *2f);
				
				debug writefln( "%f,%f,%f", a2, ang, a3 );
			}
			
			/+Find the closest 'wraparound angle' so we're not always bobbing between +1 and -1.
			 +TODO: Cleanup+/
			if( abs(a2 -Controller.Z_Rotation) < abs(ang -Controller.Z_Rotation) )
			{
				if( abs(a2 -Controller.Z_Rotation) < abs(a3 -Controller.Z_Rotation) )
					{ ang = a2; }
				else if( abs(a3 -Controller.Z_Rotation) < abs(a2 -Controller.Z_Rotation) )
					{ ang = a3; }
			}
			else if ( abs(a3 -Controller.Z_Rotation) < abs(ang -Controller.Z_Rotation) )
				{ ang = a3; }
				
				
			float n_speed = SPEED /(1f +abs(ang -Controller.Z_Rotation));					
			if( _tick >= 0.4f )
			{
				debug writeln(ang);
				debug writeln((SPEED /2f) /n_speed);
				_tick = 0f;
			}
			Controller.Z_Rotation +=(ang -Controller.Z_Rotation) *delta_time *TURNS;
			_tick +=delta_time;

			if( abs( ang -Controller.Z_Rotation ) < PI )
			{
				Controller.Position.y +=cos( Controller.Z_Rotation ) *delta_time *n_speed;
				Controller.Position.x +=sin( -Controller.Z_Rotation ) *delta_time *n_speed;
			}
			if( (Path.front -Controller.Position.xy).magnitude < (SPEED /2f) /n_speed )
			{
				debug writefln("Arrived within range, magnitude %f", (Path.front -Controller.Position.xy).magnitude);
				debug writefln("Position %s", Controller.Position.as_string);
				Path.removeFront(1); 
				Path_Debug_Render.removeFront(1);
			}
		}
	}
}

class Chunk :IRenderable
{
public: /+----    Variables    ----+/
	Room Engine, Gyro;
	vec3 Position;
	float Z_Rotation = 0f;
	Room[] Rooms;
public: /+----    Functions    ----+/
	
	public this()
	{
		this._renders = new ChunkRenders();
		this._renders.InsideChunk = this;
		this.Position = vec3(0f,0f,0f);
	}
	@property Render Renderer(){ return this._renders; }
private: /+----    Variables    ----+/
	ChunkRenders _renders;
}

class ChunkRenders :RotateRender
{
public: /+----    Variables    ----+/
	/+Circular References never did anything wrong, right?+/
	public Chunk InsideChunk;
	
public: /+----    Functions    ----+/
	
	public this(){}
	
	override public void Render( mat4 pv, int _transformUniform ,int _colourUniform )
	{
		auto pos = InsideChunk.Position;
		if( InsideChunk.Gyro !is null )
		{
			//pos += InsideChunk.Gyro.Renderer.Position; 
		}
		pv =pv *mat4.translation( pos );
		pv =pv *mat4.zrotation(InsideChunk.Z_Rotation);
		foreach( Room room; InsideChunk.Rooms )
			{ room.Renderer.Render(pv, _transformUniform, _colourUniform); }
	}
}

enum RoomType{ Blank, Gyro, Engine };

class Room :IRenderable, ILogged
{
public: /+----    Variables    ----+/
	RoomType Type;
	Render MyRender;
	Room[4] Neighbours;
public: /+----    Functions    ----+/
	@property Render Renderer(){ return MyRender; }
	override string FormatLog( LogDetail detail_level )
	{ 
		switch( detail_level )
		{
		case LogDetail.High:
			return format(`[Room]`
			`Neighbours: [%s,%s,%s,%s]`
			`Type: %s`
			`Render: %s`, Up, Right, Down, Left, Type, MyRender ); 
		default:
			return "";
		}
    }
	
	@property Room Up(){return Neighbours[0];}
	@property Room Right(){return Neighbours[1];}
	@property Room Down(){return Neighbours[2];}
	@property Room Left(){return Neighbours[3];}
	
	@property Room Up(Room up){return Neighbours[0] = up;}
	@property Room Right(Room right){return Neighbours[1] = right;}
	@property Room Down(Room down){return Neighbours[2] = down;}
	@property Room Left(Room left){return Neighbours[3] = left;}
}