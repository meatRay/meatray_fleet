module fleet.render.geometry;

import derelict.opengl3.gl3;
import gl3n.linalg;

class Shape  /+ Replace with a `Renderer` class with options as data objects? +/
{
	public Vector!(float,3) Colour;
	public int Triangles;
	private uint _vertexBuffer;
	public void LoadVertices( float[] vertices )
	{
		this.Triangles =vertices.length /3;
		glGenBuffers( 1, &_vertexBuffer );
		glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer );
		glBufferData( GL_ARRAY_BUFFER, vertices.length *float.sizeof, vertices.ptr, GL_STATIC_DRAW );
	}
	package void BindBuffer()
		{ glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer ); }
}
class Render
{
	private uint _objectBuffer;
	private Shape _shape;
	
	public void LoadObject( Shape shape/+uint vertex_buffer /+How the fuck does that work?+/+/) /+ Pass in Shape and Texture? +/
	{
		shape.BindBuffer();
		this._shape =shape;
		glGenVertexArrays( 1, &_objectBuffer );
		glBindVertexArray( _objectBuffer );
		glEnableVertexAttribArray( 0 );
		glBindBuffer( GL_ARRAY_BUFFER, _objectBuffer );
		glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, 0, null );
	}
	public void Render( int _transformUniform ,int _colourUniform )
	{
		glBindVertexArray( _objectBuffer );
		glUniform3fv( _colourUniform, 1, _shape.Colour.value_ptr );
		glDrawArrays( GL_TRIANGLES, 0, _shape.Triangles );
	}
}
class Texture
{
	private uint _textureBuffer;
	/+ Texture Buffer +/
}