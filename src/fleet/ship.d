module fleet.ship;

import theatre.rendering;
import gl3n.linalg;

debug import std.stdio;
import std.algorithm;

class Ship
{
	public Chunk[] Chunks;
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
				rooms[x][y].MyRender.Position =Vector!(float,3)(x,y,0f);
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
	/+More memory expensive than just storing the Root.+/
	public Room[] Rooms;
}
class ChunkRenders :Render
{
	/+Circular References never did anything wrong, right?+/
	public Chunk InsideChunk;
	
	public this(){}
	
	override public void Render( mat4 pv, int _transformUniform ,int _colourUniform )
	{
		pv =pv *mat4.translation( InsideChunk.Position );
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