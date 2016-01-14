module fleet.ship;

import theatre.rendering;
import gl3n.linalg;

debug import std.stdio;
import std.math;
import std.algorithm;
import std.container: SList;

class Ship
{
	const float SPEED =8f;
	public SList!(Vector!(float,2)) Path;
	public Chunk Chunks;
	float tick=1f;
	public void Update( float delta_time )
	{
		if( !Path.empty )
		{
			auto delta =Path.front -Chunks.Position.xy;
			float ang =(atan2( delta.y, delta.x ) -PI_2);
			ang =fmod( ang, (2f *PI) );
			Chunks.Z_Rotation +=(ang -Chunks.Z_Rotation) *delta_time;
			//Chunks.Z_Rotation +=0.01;
			tick +=delta_time;
			if( tick >= 0.4f )
			{
				debug writeln( ang );
				debug writeln(1f /(1f +abs(ang -Chunks.Z_Rotation)));
				tick =0f;
			}
			float n_speed =SPEED /(1f +abs(ang -Chunks.Z_Rotation));
			//Chunks.Z_Rotation +=0.01f;
			//Chunks.Position += vec3(((Path.front -Chunks.Position.xy).normalized *delta_time *SPEED),0);
			if( abs( ang -Chunks.Z_Rotation ) < PI_2 )
			{
				Chunks.Position.y +=cos( Chunks.Z_Rotation ) *delta_time *n_speed;
				Chunks.Position.x +=sin( -Chunks.Z_Rotation ) *delta_time *n_speed;
			}
			if( (Path.front -Chunks.Position.xy).magnitude < SPEED )
				{
				debug writefln("Arrived within range, magnitude %f", (Path.front -Chunks.Position.xy).magnitude);
				debug writefln("Position %s", Chunks.Position.as_string);
				Path.removeFront(1); }
		}
	}
}

Ship FromFormatHelper( string formatted_input )
{
	Room[][] rooms =new Room[][5];
	for( int i =0; i < rooms.length; ++i )
		{ rooms[i] =new Room[6]; }
	int x, y;
	
	auto shape =new Shape( Shape.Primitives.SquareVertices, Shape.Primitives.SquareMap );
	auto tex =CreateTexture( "box.png" );
	
	int cnt_at =0;
	foreach( c; formatted_input )
	{
		debug writefln( "%d, %d", x, y );
		switch( c )
		{
			case '\n':
				x =0; ++y;
				break;
			case '#':
				rooms[x][y] =new Room();
				if( x > 0 && rooms[x-1][y] !is null )
				{
					rooms[x-1][y].Right =rooms[x][y];
					rooms[x][y].Left =rooms[x-1][y];
				}
				if( y > 0 && rooms[x][y-1] !is null )
				{
					rooms[x][y-1].Down =rooms[x][y];
					rooms[x][y].Up =rooms[x][y-1];
				}
				rooms[x][y].MyRender =new Render();
				rooms[x][y].MyRender.LoadObject( shape, tex );
				rooms[x][y].MyRender.Colour =Vector!(float,3)(1f /x,1f /y,0f);
				rooms[x][y].MyRender.Position =Vector!(float,3)(x -2.5,y -3,0f);
				goto default;
			default:
				++x;
				break;
		}
		//if( cnt_at++ == 3 )
		//	{ break; }
	}
	Ship ship =new Ship();
	ship.Chunks =/+[+/ new Chunk() /+]+/;
	Room[] fin_rooms =new Room[ rooms.map!( r => r.count!"a !is null" ).sum() ];
	int at;
	foreach( ray; rooms )
		foreach( room; ray )
			if( room !is null )
				{ fin_rooms[at++] =room; }
	ship.Chunks/+[0]+/.Rooms =fin_rooms;
	return ship;
}

//Position Management
class Chunk :IRenderable
{
	public this()
	{
		this._renders =new ChunkRenders();
		this._renders.InsideChunk =this;
		this.Position =vec3(0f,0f,0f);
	}
	private ChunkRenders _renders;
	@property public Render Renderer(){ return this._renders; }
	public vec3 Position;
	public float Z_Rotation =0f;
	/+More memory expensive than just storing the Root.+/
	public Room[] Rooms;
}
class ChunkRenders :RotateRender
{
	/+Circular References never did anything wrong, right?+/
	public Chunk InsideChunk;
	
	public this(){}
	
	override public void Render( mat4 pv, int _transformUniform ,int _colourUniform )
	{
		pv =pv *mat4.translation( InsideChunk.Position );
		pv =pv *mat4.zrotation(InsideChunk.Z_Rotation);
		foreach( Room room; InsideChunk.Rooms )
			{ room.Renderer.Render(pv, _transformUniform, _colourUniform); }
	}
}

class Room :IRenderable
{
	public Render MyRender;
	@property public Render Renderer(){ return MyRender; }
	public Room Up, Down, Left, Right;
}