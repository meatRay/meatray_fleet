module fleet.debughelpers;

import fleet.ship;
import theatre.rendering;
import theatre.logging;

debug import std.string;
import std.algorithm;
import std.container: SList;
import std.array;

void DEBUG_ShipFindController( Ship ship )
{
	ship.Controller = ship.Chunks[0];
}

Ship FromFormatHelper( string formatted_input )
{
	Room[][] rooms = new Room[][5];
	for( int i = 0; i < rooms.length; ++i )
		{ rooms[i] = new Room[6]; }
	int x, y;
	
	auto shape = new Shape( Shape.Primitives.SquareVertices, Shape.Primitives.SquareMap );
	auto tex = CreateTexture( "box.png" );
	
	int cnt_at = 0;
	Ship ship = new Ship();
	ship.Chunks = [ new Chunk() ];
	foreach( c; formatted_input )
	{
		debug Log( LogDetail.Low, format("%d, %d", x, y) );
		if( c == '\n' )
		{
			++y; x = 0;
			continue;
		}
		else if( c == ' ' )
		{
			++x;
			continue;
		}
		
		rooms[x][y] = new Room();
		rooms[x][y].Type = RoomType.Blank;
		switch( c )
		{
			case 'E':
			rooms[x][y].Type = RoomType.Engine;
				ship.Chunks[0].Engine = rooms[x][y];
				goto case '#';
			case 'G':
				rooms[x][y].Type = RoomType.Gyro;
				ship.Chunks[0].Gyro = rooms[x][y];
				goto case '#';
			case '#':
				if( x > 0 && rooms[x-1][y] !is null )
				{
					rooms[x-1][y].Right = rooms[x][y];
					rooms[x][y].Left = rooms[x-1][y];
				}
				if( y > 0 && rooms[x][y-1] !is null )
				{
					rooms[x][y-1].Down = rooms[x][y];
					rooms[x][y].Up = rooms[x][y-1];
				}
				rooms[x][y].MyRender = new Render();
				rooms[x][y].MyRender.LoadObject( shape, tex );
				rooms[x][y].MyRender.Colour = Vector!(float,3)(1f /x,1f /y,0f);
				rooms[x][y].MyRender.Position = Vector!(float,3)(x -2.5,y -3,0f);
				goto default;
			default:
				++x;
				break;
		}
	}
	Room[] fin_rooms = new Room[ rooms.map!( r => r.count!"a !is null" ).sum() ];
	int at;
	foreach( ray; rooms )
		foreach( room; ray )
			if( room !is null )
				{ fin_rooms[at++] = room; }
	ship.Chunks[0].Rooms = fin_rooms;
	ship.Controller = ship.Chunks[0];
	return ship;
}

Chunk[] DEBUG_FractureChunk( Room removed )
{
	Chunk[] new_chunks = new Chunk[4];
	int at = 0;
	if( removed.Up !is null )
		{ removed.Up.Down = null; }
	if( removed.Right !is null && !new_chunks.any!(c => c !is null && !c.Rooms.find(removed.Right).empty ) )
		{ removed.Right.Left = null; }
	if( removed.Down !is null && !new_chunks.any!(c => c !is null && !c.Rooms.find(removed.Down).empty ) )
		{ removed.Down.Up = null; }
	if( removed.Left !is null && !new_chunks.any!(c => c !is null && !c.Rooms.find(removed.Left).empty ) )
		{ removed.Left.Right = null; }
	foreach( nbr; removed.Neighbours )
	if( nbr !is null )
	{
		new_chunks[at] = new Chunk();
		new_chunks[at].Rooms = array(DEBUG_CollectRooms( nbr ));
		new_chunks[at].Gyro = new_chunks[at].Rooms.find!(r => r.Type == RoomType.Gyro ).front;
		/+This needs to be WAY more clever+/
		//new_chunks[at].Position = 
		at++;
	}
	return new_chunks[0..at];
}

SList!Room DEBUG_CollectRooms( Room root, SList!Room rooms =SList!Room() )
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
