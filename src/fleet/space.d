module fleet.space;

import theatre;
import theatre.input;
import theatre.rendering;

import std.container;
debug import std.stdio;

void main()
{
	Stage stage =CreateStage();
	stage.SetScene( new Scene(Scene.View.Ortho, 10f, 10f /stage.AspectRatio ) );
	
	
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
		
	stage.OnUpdate =()
	{ /+Key is lifted from SDLK Currently+/
		/+Bundle into 'Keyboard' owned by Stage.  Check Key states instead.+/
		if ( stage.Cur_Keyboard.keyDown(Key.W) )
		{	mc.Position.y +=0.01f; }
		else if ( stage.Cur_Keyboard.keyDown(Key.S) )
		{mc.Position.y -=0.01f; }
		if ( stage.Cur_Keyboard.keyDown(Key.A) )
		{	mc.Position.x -=0.01f; }
		else if ( stage.Cur_Keyboard.keyDown(Key.D) )
		{mc.Position.x +=0.01f; }
	};
	stage.OnKeyDown =(k){};
	stage.OnKeyUp =(k){};
	
	stage.Start();
}
class Space
{
	public Ship[] Ships;
}

class Ship
{
	public Chunk[] Chunks;
}

//Position Management
class Chunk
{
	public Room Root;
}

class Room
{
	public class Blueprint
	{
		
	}
	public Blueprint Design;
	public Room[4] Neighbours;
}
