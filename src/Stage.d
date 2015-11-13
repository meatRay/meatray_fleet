module fleet.stage;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

/+debug +/import std.stdio :writefln;

public static Stage createStage()
{
	import std.exception :enforce;
	DerelictGL3.load();
	DerelictSDL2.load();
	
	SDL_Window* window;
	SDL_GLContext glContext;
	
	enforce( SDL_Init( SDL_INIT_EVERYTHING ) >=0, "Error initializing SDL." );
	enforce(
		(window =SDL_CreateWindow("meatray_fleet", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 640, 480, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN))
		!is null,
		"SDL ->OpenGL display creation failed!"
	);
	enforce( (glContext =SDL_GL_CreateContext(window)) !is null, "OpenGL context creation failed!" );
		
	DerelictGL3.reload();
	
	return new Stage( window, glContext );
}

/++ Definitions on how to Render Scene Objects ++/
class Stage
{
	/+ I spent way too long debating gross camelCase or PascalCase.  Got to be consistent. +/ 
	@property public Scene currentScene(){ return this._currentScene; }
	public Scene setScene(Scene scene){ return this._currentScene =scene; }
	private Scene _currentScene;
	private static SDL_Window* _window;
	private static SDL_GLContext _glContext;
	public this( SDL_Window* window, SDL_GLContext glcontext )
	{
		_window =window;
		_glContext =glcontext;
	}
	public ~this()
	{
		SDL_GL_DeleteContext( _glContext );
		SDL_DestroyWindow( _window );
		SDL_Quit(); /+ Likely does nasty things in case of multiple Stages running +/
	}
	public void render()
	{}
}

/++ Contains Collections of Items to be rendered ++/
class Scene
{
	/+ Stage Reference? +/
}
interface IRenderable  /+ Replace with a `Renderer` class with options as data objects? +/
{
	void render();
}
