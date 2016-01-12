module theatre.rendering.renderer;

import theatre.rendering.textures;
import theatre.rendering.geometry;

import derelict.opengl3.gl3;
import gl3n.linalg;
public import gl3n.linalg: Vector;

debug import std.stdio;

interface IRenderable
{
	@property public Render Renderer();
}
class Render
{
	public bool Visible =true;
	public Vector!(float,3) Colour;
	public this()
		{ Position =vec3(0f,0f,0f); }
	public vec3 Position;
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
		
		debug writefln("_objectBuffer: %d", _objectBuffer );
		glBindBuffer( GL_ARRAY_BUFFER, _objectBuffer );
		shape.SetAttributes();
		
	}
	/+Pass mat4 as pointer?  Kind of dangerous.+/
	public void Render( mat4 pv, int _transformUniform ,int _colourUniform )
	{
		if( Visible )
		{
			_texture.BindBuffer();
			glBindVertexArray( _objectBuffer );
			glUniform3fv( _colourUniform, 1, Colour.value_ptr );
			pv =pv *mat4.translation( Position );
			glUniformMatrix4fv( _transformUniform, 1, GL_TRUE, pv.value_ptr);
			glDrawArrays( GL_TRIANGLES, 0, _shape.Points );
		}
	}
}