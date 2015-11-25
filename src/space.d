module fleet.space;

import fleet.render.stage;

import std.container;

void main()
{
	Stage stage =CreateStage();
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
