module fleet.theatre.rendering.geometry;

import derelict.opengl3.gl3;
import gl3n.linalg;

debug import std.stdio;

struct TexPoint
{
	public this( ushort u, ushort v )
		{ UV.u =u; UV.v =v; }
	Vector!(ushort,2) UV;
}

struct Location
{
	public this( float x, float y, float z )
	{
		Position.x =x; Position.y =y; Position.z =z;
	}
	Vector!(float,3) Position;
}

class Shape  /+ Replace with a `Renderer` class with options as data objects? +/
{
	public this(in Location[] vertices, in TexPoint[] map)
		{ LoadVertices(vertices, map); }
	public int Points;
	private uint _vertexBuffer, _mapBuffer;
	public void LoadVertices( in Location[] vertices, in TexPoint[] map )
	{
		this.Points =vertices.length;
		assert( vertices.length == map.length );
		glGenBuffers( 1, &_vertexBuffer );
		glGenBuffers( 1, &_mapBuffer );
		glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer );
		debug writefln("Vertices bytesize: %d", vertices.length *Location.sizeof);
		glBufferData( GL_ARRAY_BUFFER, vertices.length *Location.sizeof, cast(float*)(vertices.ptr), GL_STATIC_DRAW );
		glBindBuffer( GL_ARRAY_BUFFER, _mapBuffer );
		debug writefln("Map bytesize: %d", map.length *TexPoint.sizeof);
		glBufferData( GL_ARRAY_BUFFER, map.length *TexPoint.sizeof, cast(ushort*)(map.ptr), GL_STATIC_DRAW );
	}
	package void SetAttributes()
	{
		glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer );
		glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, 0, null );
		glBindBuffer( GL_ARRAY_BUFFER, _mapBuffer );
		glVertexAttribPointer( 1, 2, GL_UNSIGNED_SHORT, GL_FALSE, 0, null );
	}
	
	public static class Primitives
	{
		public static const Location[] SquareVertices =[
			Location(0f,0f,0f),
			Location(0f,1f,0f),
			Location(1f,0f,0f),
			Location(1f,1f,0f),
			Location(1f,0f,0f),
			Location(0f,1f,0f)
		];
		public static const TexPoint[] SquareMap =[
			TexPoint(0,1),
			TexPoint(0,0),
			TexPoint(1,1),
			TexPoint(1,0),
			TexPoint(1,1),
			TexPoint(0,0)
		];
	}
}