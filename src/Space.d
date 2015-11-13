module fleet.space;

import fleet.stage;

import core.thread;
import core.time;

void main()
{
	Stage stage =createStage();
	Thread.sleep(dur!"seconds"(4));
}
class Space
{
}