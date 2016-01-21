module fleet.ship;

import theatre.rendering;
import gl3n.linalg;

debug import std.stdio;
import std.math;
import std.algorithm;
import std.container: SList;
import std.array;

class Ship :IRenderer
{
	const float TURNS =0.5f *PI;
	const float SPEED =8f;
	public SList!(Vector!(float,2)) Path;
	public SList!IRenderer Path_Debug_Render;
	public Chunk[] Chunks;
	public Chunk Controller;
	float tick=1f;
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
			auto delta =Path.front -Controller.Position.xy;
			
			float ang =(atan2( delta.y, delta.x ) -PI_2);
			float a2 =ang -(2f *PI);
			float a3 =ang +(2f *PI);
			if( tick >= 0.4f )
			{
				/+Doesn't happen often, but take this out of debug ticks+/
				Controller.Z_Rotation =fmod(Controller.Z_Rotation, PI *2f);
				
				debug writefln( "%f,%f,%f", a2, ang, a3 );
			}
			
			/+Find the closest 'wraparound angle' so we're not always bobbing between +1 and -1.
			 +TODO: Cleanup+/
			if( abs(a2 -Controller.Z_Rotation) < abs(ang -Controller.Z_Rotation) )
			{
				if( abs(a2 -Controller.Z_Rotation) < abs(a3 -Controller.Z_Rotation) )
					{ ang =a2; }
				else if( abs(a3 -Controller.Z_Rotation) < abs(a2 -Controller.Z_Rotation) )
					{ ang =a3; }
			}
			else if ( abs(a3 -Controller.Z_Rotation) < abs(ang -Controller.Z_Rotation) )
				{ ang =a3; }
				
				
			float n_speed =SPEED /(1f +abs(ang -Controller.Z_Rotation));					
			if( tick >= 0.4f )
			{
				debug writeln(ang);
				debug writeln((SPEED /2f) /n_speed);
				tick =0f;
			}
			Controller.Z_Rotation +=(ang -Controller.Z_Rotation) *delta_time *TURNS;
			tick +=delta_time;

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
void DEBUG_ShipFindController( Ship ship )
{
	ship.Controller =ship.Chunks[0];
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
				rooms[x][y].Neighbours =new Room[4];
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
	ship.Chunks =[ new Chunk() ];
	Room[] fin_rooms =new Room[ rooms.map!( r => r.count!"a !is null" ).sum() ];
	int at;
	foreach( ray; rooms )
		foreach( room; ray )
			if( room !is null )
				{ fin_rooms[at++] =room; }
	ship.Chunks[0].Rooms =fin_rooms;
	ship.Controller =ship.Chunks[0];
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
Chunk[] DEBUG_FractureChunk( Room removed )
{
	Chunk[] new_chunks =new Chunk[4];
	int at =0;
	if( removed.Up !is null )
		{ removed.Up.Down =null; }
	if( removed.Right !is null && !new_chunks.any!(c => c !is null && !c.Rooms.find(removed.Right).empty ) )
		{ removed.Right.Left =null; }
	if( removed.Down !is null && !new_chunks.any!(c => c !is null && !c.Rooms.find(removed.Down).empty ) )
		{ removed.Down.Up =null; }
	if( removed.Left !is null && !new_chunks.any!(c => c !is null && !c.Rooms.find(removed.Left).empty ) )
		{ removed.Left.Right =null; }
	foreach( nbr; removed.Neighbours )
		if( nbr !is null )
		{
			new_chunks[at] =new Chunk();
			new_chunks[at++].Rooms =array(DEBUG_CollectRooms( nbr ));
		}
	return new_chunks[0..at];
}
SList!Room DEBUG_CollectRooms( Room root, SList!Room rooms =SList!Room() ) /+ACCESS VIOLATION+/
{
	foreach( room; root.Neighbours )
	{
		if( room !is null && rooms[].find(room).empty )
		{ 
			rooms.insert(room);
			rooms =DEBUG_CollectRooms( room, rooms );
		}
	}
	return rooms;
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
	public Room[] Neighbours;
	
	@property Room Up(){return Neighbours[0];}
	@property Room Right(){return Neighbours[1];}
	@property Room Down(){return Neighbours[2];}
	@property Room Left(){return Neighbours[3];}
	
	@property Room Up(Room up){return Neighbours[0] =up;}
	@property Room Right(Room right){return Neighbours[1] =right;}
	@property Room Down(Room down){return Neighbours[2] =down;}
	@property Room Left(Room left){return Neighbours[3] =left;}
}