/++Authors: meatRay+/
module theatre.rendering.renderer;

import theatre.rendering.textures;
import theatre.rendering.geometry;

import derelict.opengl3.gl3;
import gl3n.linalg;
public import gl3n.linalg: Vector;

debug import std.stdio;

interface IRenderable
{
	@property public IRenderer Renderer();
}
interface IRenderer
{
	public void Render( mat4 pv, int _transformUniform ,int _colourUniform );
}
class Render :IRenderer
{
public: 
	bool Visible = true;
	Vector!(float,3) Colour = vec3(1f,1f,1f);
	this()
		{ Position = vec3(0f,0f,0f); }
	~this()
	{
		glDeleteVertexArrays(1, &_objectBuffer);
		debug writeln("Render freed.");
	}
	public vec3 Position;
	private uint _objectBuffer;
	private Shape _shape;
	private Texture _texture;
	public void LoadObject( Shape shape, Texture texture) /+ Pass in Shape and Texture? +/
	{
		this._shape = shape;
		this._texture = texture;
		glGenVertexArrays( 1, &_objectBuffer );
		glBindVertexArray( _objectBuffer );
		glEnableVertexAttribArray( 0 );
		glEnableVertexAttribArray( 1 );
		debug writefln("_objectBuffer: %d", _objectBuffer );
		//glBindBuffer( GL_ARRAY_BUFFER, _objectBuffer );
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
			pv = pv *mat4.translation( Position );
			glUniformMatrix4fv( _transformUniform, 1, GL_TRUE, pv.value_ptr);
			glDrawArrays( GL_TRIANGLES, 0, _shape.Points );
		}
	}
}

class RotateRender :Render
{
	public Vector!(float,3) Rotation;
	public this()
	{ 
		Rotation = vec3(0f,0f,0f);
		super();
	}
		
	/+Pass mat4 as pointer?  Kind of dangerous.+/
	override public void Render( mat4 pv, int _transformUniform ,int _colourUniform )
	{
		if( Visible )
		{
			_texture.BindBuffer();
			glBindVertexArray( _objectBuffer );
			glUniform3fv( _colourUniform, 1, Colour.value_ptr );
			/+Make this nice, sometime.+/
			pv.rotatex(Rotation.x);
			pv.rotatey(Rotation.y);
			pv.rotatez(Rotation.z);
			pv = pv *mat4.translation( Position );
			glUniformMatrix4fv( _transformUniform, 1, GL_TRUE, pv.value_ptr);
			glDrawArrays( GL_TRIANGLES, 0, _shape.Points );
		}
	}
}