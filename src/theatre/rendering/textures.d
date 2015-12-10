module theatre.rendering.textures;

import derelict.sdl2.image;
import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

import std.string;

debug import std.stdio;

public Texture CreateTexture( string path )
{
	Texture tex =null;
	SDL_Surface* s_sur =IMG_Load( toStringz(path) );
	if( s_sur == null )
		{ debug writefln("Error loading image at '%s'\nSDL Error %s", path, IMG_GetError()); }
	else
	{
		uint tex_buf =0;
		glGenTextures(1, &tex_buf);
		glBindTexture(GL_TEXTURE_2D, tex_buf);
		int mode =GL_RGB;
		if( s_sur.format.BytesPerPixel == 4 )
			{ mode =GL_RGBA; }
		debug writefln("Width:%d\nHeight:%d\n", s_sur.w,s_sur.h);
		glTexImage2D( GL_TEXTURE_2D, 0, mode, s_sur.w, s_sur.h, 0, mode, GL_UNSIGNED_BYTE, s_sur.pixels );
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		tex =new Texture( tex_buf );
	}
	SDL_FreeSurface( s_sur );
	return tex;
}
class Texture
{
private:
	uint _textureBuffer;
public: /+----    Functions    ----+/
	this( uint texture_buffer )
		{ this._textureBuffer =texture_buffer; }
	~this()
		{ glDeleteTextures(1, &_textureBuffer); }
	void BindBuffer()
		{ glBindTexture(GL_TEXTURE_2D, _textureBuffer); }
	@property string AsOutput(){ return format("Texture[ buffer:%d ]}", _textureBuffer); }
}