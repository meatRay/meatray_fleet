module fleet.space;

import fleet.stage;

import std.container;
import core.thread;
import core.time;

void main()
{
	Stage stage =CreateStage();
	/+ Thread.sleep(dur!"seconds"(4)); +/
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