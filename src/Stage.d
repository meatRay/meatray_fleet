module Fleet.Stage;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

/+debug +/import std.stdio :writefln;

public static Stage Main_Stage;

private static SDL_Window* _Window;
private static SDL_GLContext _GLContext;
static this()
{
	DerelictGL3.load();
	DerelictSDL2.load();
	
	if( SDL_Init( SDL_INIT_EVERYTHING ) < 0 )
		{ writefln("Error initializing SDL!"); }
	if( (_Window = SDL_CreateWindow("3.2", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 640, 480, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN)) is null )
		{ writefln("SDL ->OpenGL display creation failed!"); }
	if( (_GLContext =SDL_GL_CreateContext(_WINDOW)) is null )
		{ writefln("OpenGL context creation failed!"); }
		
	DerelictGL3.reload();
}

void main()
{
	writef("Running!");
}

class Stage
{
	public void render()
	{}
}