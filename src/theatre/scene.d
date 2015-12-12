module theatre.scene;

import theatre.rendering.renderer;

import gl3n.linalg;

import std.container;
import std.range, std.algorithm;

/++ Contains Collections of Items to be rendered ++/
class Scene
{
	enum View{ None, Ortho };
	private View _view;
	@property public View CurrentView(){ return this._view; }
	public this( View view_type, float width, float height )
	{
		this.Location =vec3(0f,0f,0f);
		SetView( view_type, width, height );
	}
	public void SetView( View view_type, float width, float height )
	{
		_view =view_type;
		switch( view_type )
		{
			case View.Ortho:
				Perspective =mat4.orthographic( width /-2f, width /2f, height /-2f, height /2f, 0f, 1f );
				return;			
			default:
				Perspective =mat4.identity;
				return;
		}
	}
	package mat4 Perspective;
	package vec3 Location;
	/+ Stage Reference? +/
	package DList!Render Props;
	public void AddProp( IRenderable renderable )
		{ this.Props.insert( renderable.Renderer ); }
	public void AddProp( Render render )
		{ this.Props.insert( render ); }
	public void RemoveProp( IRenderable renderable )
		{ this.Props.linearRemove( Props[].find(renderable.Renderer).take(1) ); }
	public void RemoveProp( Render render )
		{ this.Props.linearRemove( Props[].find(render).take(1) ); }
}