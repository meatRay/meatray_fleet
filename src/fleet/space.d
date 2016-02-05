/++Authors: meatRay+/
module fleet.space;

import fleet.ship;

import theatre;
import theatre.input;
import theatre.logging;
import theatre.rendering;

import gl3n.linalg;
debug import derelict.opengl3.gl3;	

import std.container;
debug import std.stdio;
import std.math;

/+Annotated for a friend+/
void main()
{
	/+Create a Stage+/
	Stage stage =CreateStage("theatre_example", 800, 640);
	/+Create a Scene of Objects, rendered Orthographically+/
	stage.SetScene( new Scene(Scene.View.Ortho, 40f, 40f ) );
	
	/+Handy Dandy spaceship builder+/
	auto ship = FromFormatHelper("#####\n#####\n# # #\n  #\n #G#\n #E#\n");
	/+Since `Ship` exposes a Renderer, we can just add it to the scene+/
	stage.CurrentScene.AddProp( ship );
	
	/+We're just doing something every second+/
	float accum_tick =1f;
	
	/+Create a Shape and Texture to assign to nodes in our Path+/
	auto path_tex =CreateTexture( "circle.png" );
	auto path_shape =new Shape( Shape.Primitives.SquareVertices, Shape.Primitives.SquareMap );
	
	/+Just Geometry for drawing our path+/
	float last_angle =float.nan;
	vec2 last_path;
	
	stage.OnUpdate =(delta_time)
	{
		ship.Update(delta_time);
		
		/+We're just going to be keeping track of the mouse, and altering the Ship's path.+/
		accum_tick +=delta_time;
		if( stage.CurMouse.LeftDown && accum_tick >= 0.04f )
		{
			auto vec_new =WinToStage(
				vec2i(stage.CurMouse.X,stage.CurMouse.Y),
				vec2i(800,640),
				vec2(40f, 40f)
			);
			if( last_angle is float.nan )
			{
				auto delta = ship.Controller.Position.xy - vec_new;
				last_angle = atan2( delta.y, delta.x );
			}
			else
			{
				auto delta = last_path - vec_new;
				float nangle = 0f;
				if( accum_tick > 0.4 || abs((nangle =atan2( delta.y, delta.x )) - last_angle) > 0.4f )
				{
					if( nangle != 0f )
					debug writefln( "NANGLE %f", nangle );
					last_angle = nangle;
					last_path = vec_new;
					debug writeln( vec_new.as_string );
					auto dbg = new Render();
					dbg.Position = vec3( vec_new, 0f );
					dbg.LoadObject( path_shape,path_tex );
					ship.Path_Debug_Render.insertAfter( ship.Path_Debug_Render[], dbg );
					ship.Path.insertAfter( ship.Path[], vec_new );
					accum_tick = 0f;
				}
			}
		}
	};
	stage.OnKeyDown =(k)
	{/+
		DEBUG removing something from the ship.+/
		debug
		{
			auto rm = ship.Chunks[0].Rooms[0];
			writefln("Removed Room X: %f, Y: %f", rm.Renderer.Position.x, rm.Renderer.Position.y);
			ship.Chunks = DEBUG_FractureChunk( ship.Chunks[0].Rooms[4] );
			DEBUG_ShipFindController( ship );
		}
	};
	stage.OnKeyUp =(k){};
	
	foreach( room ; ship.Chunks[0].Rooms )
	{
		if( room.Renderer is null )
		{ debug writefln("WEE WOO NULL POLICE AT %s", room.FormatLog() ); }
	}
	
	stage.Start();
}

vec2 WinToStage( vec2i mouse, vec2i win_bounds, vec2 stage_bounds, vec2 camera =vec2(0f,0f) )
{
	vec2 ratio =vec2( win_bounds.x /stage_bounds.x, win_bounds.y /stage_bounds.y );
	return vec2( ((mouse.x -(win_bounds.x /2)) /ratio.x), ((-mouse.y +(win_bounds.y /2) )/ratio.y) );
}

class Space
{
	public Ship[] Ships;
}
