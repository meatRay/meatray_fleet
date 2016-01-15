module fleet.space;

import fleet.ship;

import theatre;
import theatre.input;
import theatre.rendering;

import gl3n.linalg;
debug import derelict.opengl3.gl3;	

import std.container;
debug import std.stdio;
debug import std.math;

vec2 WinToStage( vec2i mouse, vec2i win_bounds, vec2 stage_bounds, vec2 camera =vec2(0f,0f) )
{
	vec2 ratio =vec2( win_bounds.x /stage_bounds.x, win_bounds.y /stage_bounds.y );
	return vec2( ((mouse.x -(win_bounds.x /2)) /ratio.x), ((-mouse.y +(win_bounds.y /2) )/ratio.y) );
}

void main()
{
	Stage stage =CreateStage("theatre_example", 800, 640);
	stage.SetScene( new Scene(Scene.View.Ortho, 40f, 40f/+10f *stage.AspectRatio+/ ) );
	
	auto ship =FromFormatHelper("#####\n#####\n# # #\n  #\n ###\n ###\n");
	stage.CurrentScene.AddProp( ship.Chunks/+[0]+/ );
	stage.msecs_frame =16;
	
	float accum_tick =1f;
	stage.OnUpdate =(delta_time)
	{ /+Key is lifted from SDLK Currently+/
		ship.Update(stage.msecs_frame /1000f);
		accum_tick +=delta_time /1000f;
		if( stage.Cur_Mouse.LeftDown && accum_tick >= 0.4f )
		{
			auto vec_new =WinToStage(
				vec2i(stage.Cur_Mouse.X,stage.Cur_Mouse.Y),
				vec2i(800,640),
				vec2(40f, 40f)
			);
			writeln( vec_new.as_string );
			ship.Path.insertAfter( ship.Path[], vec_new );
			accum_tick =0f;
		}
	};
	stage.OnKeyDown =(k)
	{
		//debug ship.Chunks.Z_Rotation +=PI_4;
	};
	stage.OnKeyUp =(k){};

	//ship.Path.insert( vec2(-8f, 3f) );
	//ship.Path.insert( vec2(-10f, -10f) );
	//ship.Path.insert( vec2(10f, -10f) );	
	
	debug
	{
		auto error =glGetError();
		if( error ){ writefln("OPENGL ERROR CODE %d", error); }
	}
	stage.Start();
}
class Space
{
	public Ship[] Ships;
}
