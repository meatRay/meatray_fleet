/++Authors: meatRay+/
module theatre.input.mouse;

class Mouse
{
public:
	bool LeftDown() const @property
		{ return _leftDown; }
	bool RightDown() const @property
		{ return _leftDown; }
	int X() const @property
		{ return this._x; }
	int Y() const @property
		{ return this._y; }
/+package:+/
	void UpdatePosition( int x, int y )
	{
		this._x =x; this._y =y;
	}
	void SetLeft( bool state )
		{ _leftDown =state; }
	void SetRight( bool state )
		{ _rightDown =state; }
private:
	int _x, _y;
	bool _leftDown =false;
	bool _rightDown =false;
}