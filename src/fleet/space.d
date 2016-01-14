module fleet.space;

import fleet.ship;

import theatre;
import theatre.input;
import theatre.rendering;

import gl3n.linalg;
debug import derelict.opengl3.gl3;	

import std.container;
debug import std.stdio;

void main()
{
	Stage stage =CreateStage();
	stage.SetScene( new Scene(Scene.View.Ortho, 10f, 10f /stage.AspectRatio ) );
	
	auto ship =FromFormatHelper("#####\n#####\n# # #\n  #\n ###\n ###\n");
	stage.CurrentScene.AddProp( ship.Chunks/+[0]+/ );
	
	/+
	auto shape =new Shape( Shape.Primitives.SquareVertices, Shape.Primitives.SquareMap );
	auto tex =CreateTexture( "box.png" );
	Render mc =new Render();
	mc.LoadObject( shape, tex );
	mc.Colour =Vector!(float,3)(1f,0f,0f);
	mc.Position =Vector!(float,3)(0f,0f,0f);
	stage.CurrentScene.AddProp( mc );

	auto render =new Render();
	render.LoadObject( shape, tex );
	render.Colour =Vector!(float,3)(0f,1f,0f);
	render.Position =Vector!(float,3)(-1f,0f,0f);
	stage.CurrentScene.AddProp( render );
	+/
	stage.OnUpdate =()
	{ /+Key is lifted from SDLK Currently+/
		/+Bundle into 'Keyboard' owned by Stage.  Check Key states instead.+/
		if ( stage.Cur_Keyboard.keyDown(Key.W) )
			{ ship.Chunks/+[0]+/.Position.y +=0.1f; }
		else if ( stage.Cur_Keyboard.keyDown(Key.S) )
			{ ship.Chunks/+[0]+/.Position.y -=0.1f; }
		if ( stage.Cur_Keyboard.keyDown(Key.A) )
			{ ship.Chunks/+[0]+/.Position.x -=0.1f; }
		else if ( stage.Cur_Keyboard.keyDown(Key.D) )
			{ ship.Chunks/+[0]+/.Position.x +=0.1f; }
	};
	stage.OnKeyDown =(k){};
	stage.OnKeyUp =(k){};
	
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
