/+++/
module theatre.stage;

import theatre.scene;
import theatre.rendering;
import theatre.input;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl3;

import gl3n.linalg;

import core.thread, core.time;
import std.string;

debug import std.stdio;

static this()
{
	DerelictGL3.load();
	DerelictSDL2.load();
	DerelictSDL2Image.load();
}

/++ Create a Stage and initialize an OpenGL 4.0 Context
 + Throws: Detailed Exception upon SDL or OpenGL 4.0 initializing error.
++/
public static Stage CreateStage( const char* stage_name ="meatray_Theatre", int width =800, int height =640 )
{
	import std.exception : enforce;
	SDL_Window* window;
	SDL_GLContext gl_context;
	
debug writeln( "Initializing SDL /OpenGL3 Components" );
	/+ Create static SDL rendering threads for instantiated GL Render contexts? +/
	enforce( SDL_Init( SDL_INIT_VIDEO ) >= 0, "Error initializing SDL2 [ SDL_INIT_VIDEO ]" );
	enforce(
		(window =SDL_CreateWindow(stage_name, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN))
		!is null,
		"SDL -> OpenGL display creation failed!"
	);
	SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );
	SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 4 );
	SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 0 );

	enforce( (gl_context = SDL_GL_CreateContext(window)) !is null, "OpenGL context creation failed!" );
	auto gl_version = DerelictGL3.reload();
debug writefln( "Loaded GL version %d", gl_version );
	return new Stage( window, gl_context, width, height );
}

/++ Definitions on how to Render Scene Objects ++/
class Stage
{
public: /+----    Variables    ----+/
	/+ I spent way too long debating gross camelCase or PascalCase.  Got to be consistent. +/ 
		/+ 1/27/16 THE DEBATE CONTINUES+/
	@property float AspectRatio() { return this._AspectRatio; }
	@property Scene CurrentScene() { return this._CurrentScene; }
	Scene SetScene(Scene scene) { return this._CurrentScene = scene; }
	Keyboard CurKeyboard;
	Mouse CurMouse;
	long msecs_frame = 20;	
private:
	Scene _CurrentScene;
	bool _IsRunning;
	
	/+Currently lock all Stages to the same Context+/
	static SDL_Window* _Window;
	static SDL_GLContext _GLContext;
	
	uint _Shader, _VertShader, _FragShader, _TextureLocation;
	int _Width, _Height;
	float _AspectRatio;
	int _PVMLocation, _ColourLocation;
	
public: /+----    Functions    ----+/
	this( SDL_Window* window, SDL_GLContext gl_context, int width, int height )
	{
		/+Inputs should be assigned by GL thread, and act as state machines+/
		this.CurMouse = new Mouse();
		this.CurKeyboard = new Keyboard();
		this.OnStart = {}; this.OnQuit = {};
		this.OnUpdate = (d){};
		this.OnKeyDown = (k){}; this.OnKeyUp = (k){};
		
		this._Window = window;
		this._GLContext = gl_context;
		this._Width = width;
		this._Height = height;
		this._AspectRatio = cast(float)width / height;
	}
	~this()
	{
		SDL_GL_DeleteContext( _GLContext );
		SDL_DestroyWindow( _Window );
		SDL_Quit(); /+ Likely does nasty things in case of multiple Stages running +/
	}
	void Quit()
	{
		this.OnQuit();
		this._IsRunning = false; 
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
"  uv = v_uv;"
"  gl_Position = pvm * vec4(vp, 1.0);"
"}";
	
		/+Replace with texels for Spritesheet Accuracy!+/
			/+Update: Accuracy pretty slick at the moment, actually+/
		const char* fragment_script ="#version 400\n"
"uniform vec3 model_colour;"
"in vec2 uv;"
"uniform sampler2D model_texture;"
"out vec4 frag_colour;"
"void main () {"
"  frag_colour = texture(model_texture, uv) * vec4(model_colour, 1.0);"
"}";
		this._VertShader = LoadShader( GL_VERTEX_SHADER, vertex_script );
		this._FragShader = LoadShader( GL_FRAGMENT_SHADER, fragment_script );
		
		this._Shader = glCreateProgram();
		glAttachShader( _Shader, _VertShader );
		glAttachShader( _Shader, _FragShader );
		glLinkProgram( _Shader );
		
		glEnable( GL_BLEND );
		glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
		
		this._PVMLocation = glGetUniformLocation( _Shader, "pvm" );
		this._ColourLocation = glGetUniformLocation( _Shader, "model_colour" );
		
		this._TextureLocation = glGetUniformLocation( _Shader, "model_texture" );
		
	debug writefln( "Texture Uniform: %d\nColour Uniform: %d\nMatrix Uniform: %d\n", _TextureLocation, _ColourLocation, _PVMLocation );
		//_renderThrd =new Thread(&RenderLoop);
		this.OnStart();
		this._IsRunning =true;
		UpdateLoop();
	}
	void delegate(float) OnUpdate;
	void delegate() OnStart, OnQuit;
	void delegate(SDL_Keycode) OnKeyDown, OnKeyUp;
private:
	void RenderLoop()
	{
		glClear( GL_COLOR_BUFFER_BIT /+ | GL_DEPTH_BUFFER_BIT +/ );
		glUseProgram( _Shader );
		glActiveTexture( GL_TEXTURE0 );
		glUniform1i( _TextureLocation, 0 );

		foreach( render; _CurrentScene.Props )
			{ render.Render( _CurrentScene.Perspective, _PVMLocation, _ColourLocation ); }
		
		SDL_GL_SwapWindow( _Window );
		//Thread.sleep(dur!"msecs"(20));
	}
	void UpdateLoop()
	{
		SDL_Event window_event;
		while( _IsRunning )
		{
			while( SDL_PollEvent(&window_event) != 0 )
			{
				switch( window_event.type )
				{
					case SDL_MOUSEMOTION:
						CurMouse.UpdatePosition( window_event.motion.x, window_event.motion.y );
						break;
					case SDL_KEYDOWN:
						OnKeyDown( window_event.key.keysym.sym );
						break;
					case SDL_KEYUP:
						OnKeyUp( window_event.key.keysym.sym );
						break;
					case SDL_MOUSEBUTTONDOWN:
					/+Lazy lazy!!+/
						window_event.button.button == SDL_BUTTON_LEFT ? CurMouse.SetLeft(true) : CurMouse.SetRight(true);
						break;
					case SDL_MOUSEBUTTONUP:
						window_event.button.button == SDL_BUTTON_LEFT ? CurMouse.SetLeft(false) : CurMouse.SetRight(false);
						break;
					case SDL_QUIT:
						this._IsRunning = false;
						break;
					default:
						break;
				}
			}
			OnUpdate( msecs_frame / 1000f );
			RenderLoop();
			debug
			{
				auto error = glGetError();
				if( error ){ writefln("OPENGL ERROR CODE %d", error); }
			}
			Thread.sleep( dur!"msecs"(msecs_frame) );
		}
	}
	/+ networkLoop? +/
}

private uint LoadShader( uint shader_type, const char* shader )
{
		uint shader_buf = glCreateShader( shader_type );
		glShaderSource( shader_buf, 1, &shader, null );
		glCompileShader( shader_buf );
		return shader_buf;
}
