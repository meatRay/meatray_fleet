module fleet.theatre.rendering.renderer;

import fleet.theatre.rendering.textures;
import fleet.theatre.rendering.geometry;

import derelict.opengl3.gl3;

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