module fleet.theatre.stage;

import fleet.theatre.rendering;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl3;
import gl3n.linalg;

import core.thread, core.time;
import std.container;
import std.string;
import std.range, std.algorithm;

debug import std.stdio;

public static Stage CreateStage()
{
	import std.exception :enforce;
	DerelictGL3.load();
	DerelictSDL2.load();
	DerelictSDL2Image.load();
	
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
	return new Stage( window, glContext, 640, 480 );
}

/++ Definitions on how to Render Scene Objects ++/
class Stage
{
public: /+----    Variables    ----+/
	/+ I spent way too long debating gross camelCase or PascalCase.  Got to be consistent. +/ 
	@property float AspectRatio(){ return this._aspectRatio; }
	@property Scene CurrentScene(){ return this._currentScene; }
	Scene SetScene(Scene scene){ return this._currentScene =scene; }
	
private:
	Scene _currentScene;
	bool _isRunning;
	
	/+Currently lock all Stages to the same Context+/
	static SDL_Window* _window;
	static SDL_GLContext _glContext;
	
	uint shader, vertex_shader, fragment_shader;
	int _width, _height;
	float _aspectRatio;
	int _pvmLocation, _colourLocation;
	
public: /+----    Functions    ----+/
	this( SDL_Window* window, SDL_GLContext glcontext, int width, int height )
	{
		this.OnStart ={};
		this.OnQuit ={};
		this._window =window;
		this._glContext =glcontext;
		this._width =width;
		this._height =height;
		this._aspectRatio =cast(float)_width /height;
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
		/+ Move this shader stuff out of here ASAP +/
		const char* vertex_script =	"#version 400\n"
"uniform mat4 pvm;"
"layout(location = 0) in vec3 vp;"
"layout(location = 1) in vec2 v_uv;"
"out vec2 uv;"
"void main () {"
"  uv =v_uv;"
"  gl_Position = pvm *vec4(vp, 1.0);"
"}";
	
		/+Replace with texels for Spritesheet Accuracy!+/
		const char* fragment_script ="#version 400\n"
"uniform vec3 model_colour;"
"in vec2 uv;"
"uniform sampler2D model_texture;"
"out vec4 frag_colour;"
"void main () {"
"  frag_colour = texture(model_texture, uv) *vec4 (model_colour, 1.0);"
"}";
		vertex_shader =LoadShader( GL_VERTEX_SHADER, vertex_script );
		fragment_shader =LoadShader( GL_FRAGMENT_SHADER, fragment_script );
		
		shader =glCreateProgram();
		glAttachShader( shader, vertex_shader );
		glAttachShader( shader, fragment_shader );
		glLinkProgram( shader );
		this._pvmLocation =glGetUniformLocation( shader, "pvm" );
		this._colourLocation =glGetUniformLocation( shader, "model_colour" );
		
		_texid =glGetUniformLocation(shader, "model_texture");
		
		debug writefln("Texture Uniform: %d\nColour Uniform: %d\nMatrix Uniform: %d\n",
			_texid, _colourLocation, _pvmLocation );
		this.OnStart();
		this._isRunning =true;
		UpdateLoop();
	}
	void delegate() OnStart, OnQuit;
private:
	uint _texid;
	void RenderLoop()
	{
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
		glUseProgram( shader );
		glActiveTexture(GL_TEXTURE0);
		glUniform1i(_texid, 0);

		foreach( render; _currentScene.Props )
			{ render.Render(_currentScene.Perspective, _pvmLocation, _colourLocation); }
		
		SDL_GL_SwapWindow( _window );
	}
	void ParseKey( SDL_KeyboardEvent evnt )
	{
		if( evnt.state == SDL_PRESSED && evnt.keysym.sym == SDLK_ESCAPE )
			{ _isRunning =false; }
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
					case SDL_KEYDOWN:
					case SDL_KEYUP:
						ParseKey( windowEvent.key );
						break;
					default:
						break;
				}
			}
			debug
			{
				auto error =glGetError();
				if( error ){ writefln("OPENGL ERROR CODE %d", error); }
			}
			RenderLoop();
			Thread.sleep(dur!"msecs"(20));
		}
	}
	/+ networkLoop? +/
}

private uint LoadShader( uint shaderType, const char* shader )
{
		uint shader_buf =glCreateShader( shaderType );
		glShaderSource( shader_buf, 1, &shader, null );
		glCompileShader( shader_buf );
		return shader_buf;
}

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
