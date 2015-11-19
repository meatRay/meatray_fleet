module fleet.stage;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

debug import std.stdio;

public static Stage CreateStage()
{
	import std.exception :enforce;
	DerelictGL3.load();
	DerelictSDL2.load();
	
	SDL_Window* window;
	SDL_GLContext glContext;
	
	debug writeln( "Initializing SDL /OpenGL3 Components" );
	/+ Create static SDL rendering threads for instantiated GL Render contexts? +/
	enforce( SDL_Init( SDL_INIT_VIDEO ) >=0, "Error initializing SDL" );
	enforce(
		(window =SDL_CreateWindow("meatray_fleet", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 640, 480, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN))
		!is null,
		"SDL ->OpenGL display creation failed!"
	);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);

	enforce( (glContext =SDL_GL_CreateContext(window)) !is null, "OpenGL context creation failed!" );
	
	auto versn =DerelictGL3.reload();
	debug writefln( "Loaded GL version %d", versn );
	
	return new Stage( window, glContext );
}

/++ Definitions on how to Render Scene Objects ++/
class Stage
{
public: /+----    Variables    ----+/
	/+ I spent way too long debating gross camelCase or PascalCase.  Got to be consistent. +/ 
	@property Scene CurrentScene(){ return this._currentScene; }
	Scene SetScene(Scene scene){ return this._currentScene =scene; }
	
private:
	Scene _currentScene;
	bool _isRunning;
	
	static SDL_Window* _window;
	static SDL_GLContext _glContext;
	
	uint shader, vertex_shader, fragment_shader;
	uint vertex_buffer, vertex_object;
	
	
public: /+----    Functions    ----+/
	this( SDL_Window* window, SDL_GLContext glcontext )
	{
		this.OnStart ={};
		this.OnQuit ={};
		_window =window;
		_glContext =glcontext;
	}
	~this()
	{
		SDL_GL_DeleteContext( _glContext );
		SDL_DestroyWindow( _window );
		SDL_Quit(); /+ Likely does nasty things in case of multiple Stages running +/
	}
	void Quit()
	{
		this.OnQuit();
		this._isRunning =false; 
	}
	void Start()
	{ 
		auto verts =[0f,.5f,0f, .5f,-.5f,0f, -.5f,-.5f,0f];
		glGenBuffers( 1, &vertex_buffer );
		glBindBuffer( GL_ARRAY_BUFFER, vertex_buffer );
		glBufferData( GL_ARRAY_BUFFER, 9U *float.sizeof, verts.ptr, GL_STATIC_DRAW );
		
		/+ Draw a cool triangle for now +/
		
		glGenVertexArrays( 1, &vertex_object );
		glBindVertexArray( vertex_object );
		glEnableVertexAttribArray( 0 );
		glBindBuffer( GL_ARRAY_BUFFER, vertex_object );
		glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, 0, null );
		
		/+ Move this shader stuff out of here ASAP +/
		const char* vertex_script =	"#version 400\n"
"in vec3 vp;"
"void main () {"
"  gl_Position = vec4 (vp, 1.0);"
"}";
		const char* fragment_script ="#version 400\n"
"out vec4 frag_colour;"
"void main () {"
"  frag_colour = vec4 (0.5, 0.0, 0.5, 1.0);"
"}";
		vertex_shader =glCreateShader( GL_VERTEX_SHADER );
		glShaderSource( vertex_shader, 1, &vertex_script, null );
		glCompileShader( vertex_shader );
		fragment_shader =glCreateShader( GL_FRAGMENT_SHADER );
		glShaderSource( fragment_shader, 1, &fragment_script, null );
		glCompileShader( fragment_shader );
		
		shader =glCreateProgram();
		glAttachShader( shader, vertex_shader );
		glAttachShader( shader, fragment_shader );
		glLinkProgram( shader );
		
		this.OnStart();
		this._isRunning =true;
		UpdateLoop();
	}
	void delegate() OnStart, OnQuit;
private:
	void RenderLoop()
	{
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
		glUseProgram( shader );
		glBindVertexArray( vertex_object );
		glDrawArrays( GL_TRIANGLES, 0, 3 );
		
		SDL_GL_SwapWindow( _window );
	}
	void UpdateLoop()
	{
		SDL_Event windowEvent;
		while( _isRunning )
		{
			if( SDL_PollEvent(&windowEvent) )
			{
				switch( windowEvent.type )
				{
					case SDL_QUIT:
						this._isRunning =false;
						break;
					default:
						break;
				}
			}
			RenderLoop();
		}
	}
	/+ networkLoop? +/
}

/++ Contains Collections of Items to be rendered ++/
class Scene
{
	/+ Stage Reference? +/
}
interface IRenderable  /+ Replace with a `Renderer` class with options as data objects? +/
{
	void Render();
}
