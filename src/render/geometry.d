module fleet.render.geometry;

import derelict.opengl3.gl3;
import gl3n.linalg;
import derelict.sdl2.image, derelict.sdl2.sdl;

import std.string;
import std.stdio;

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
		//UV.u =u; UV.v =v;
	}
	Vector!(float,3) Position;
	//Vector!(ushort,2) UV;
}

class Shape  /+ Replace with a `Renderer` class with options as data objects? +/
{
	public Vector!(float,3) Colour;
	public int Points;
	private uint _vertexBuffer, _mapBuffer;
	public void LoadVertices( Location[] vertices, TexPoint[] map )
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
	package void BindBuffer()
		{ glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer ); }
	package void SetAttributes()
	{
		glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer );
		glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, 0, null );
		glBindBuffer( GL_ARRAY_BUFFER, _mapBuffer );
		glVertexAttribPointer( 1, 2, GL_UNSIGNED_SHORT, GL_FALSE, 0, null );
	}
}

interface IRenderable
{
	@property public Render Renderer();
}
class Render
{
	private uint _objectBuffer;
	private Shape _shape;
	private Texture _texture;
	public void LoadObject( Shape shape, Texture texture) /+ Pass in Shape and Texture? +/
	{
		this._shape =shape;
		this._texture =texture;
		glGenVertexArrays( 1, &_objectBuffer );
		glBindVertexArray( _objectBuffer );
		glEnableVertexAttribArray( 0 );
		glEnableVertexAttribArray( 1 );
		glBindBuffer( GL_ARRAY_BUFFER, _objectBuffer );
		shape.SetAttributes();
		
	}
	public void Render( int _transformUniform ,int _colourUniform )
	{
		_texture.BindBuffer();
		glBindVertexArray( _objectBuffer );
		glUniform3fv( _colourUniform, 1, _shape.Colour.value_ptr );
		glDrawArrays( GL_TRIANGLES, 0, _shape.Points );
	}
}

public Texture CreateTexture( string path )
{
	Texture tex =null;
	SDL_Surface* s_sur =IMG_Load( toStringz(path) );
	if( s_sur == null )
		{ debug writefln("Error loading image at '%s'\nSDL Error %s", path, IMG_GetError()); }
	else
	{
		uint tex_buf =0;
		glGenTextures(1, &tex_buf);
		glBindTexture(GL_TEXTURE_2D, tex_buf);
		int mode =GL_RGB;
		if( s_sur.format.BytesPerPixel == 4 )
			{ mode =GL_RGBA; }
		debug writefln("Width:%d\nHeight:%d\n", s_sur.w,s_sur.h);
		glTexImage2D( GL_TEXTURE_2D, 0, mode, s_sur.w, s_sur.h, 0, mode, GL_UNSIGNED_BYTE, s_sur.pixels );
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		tex =new Texture( tex_buf );
	}
	SDL_FreeSurface( s_sur );
	return tex;
}
class Texture
{
private:
	uint _textureBuffer;
public: /+----    Functions    ----+/
	this( uint texture_buffer )
		{ this._textureBuffer =texture_buffer; }
	~this()
		{ glDeleteTextures(1, &_textureBuffer); }
	void BindBuffer()
		{ glBindTexture(GL_TEXTURE_2D, _textureBuffer); }
	@property string AsOutput(){ return format("Texture[ buffer:%d ]}", _textureBuffer); }
}