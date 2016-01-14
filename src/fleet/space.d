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

void main()
{
	Stage stage =CreateStage();
	stage.SetScene( new Scene(Scene.View.Ortho, 40f, 40f/+10f *stage.AspectRatio+/ ) );
	
	auto ship =FromFormatHelper("#####\n#####\n# # #\n  #\n ###\n ###\n");
	stage.CurrentScene.AddProp( ship.Chunks/+[0]+/ );
	stage.msecs_frame =16;
	
	stage.OnUpdate =()
	{ /+Key is lifted from SDLK Currently+/
		ship.Update(stage.msecs_frame /1000f);
	};
	stage.OnKeyDown =(k)
	{
		//debug ship.Chunks.Z_Rotation +=PI_4;
	};
	stage.OnKeyUp =(k){};

	ship.Path.insert( vec2(-8f, 3f) );
	ship.Path.insert( vec2(-10f, -10f) );
	ship.Path.insert( vec2(10f, -10f) );	
	
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
