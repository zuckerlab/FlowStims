
Flock flock;  
FlowField field;
int tileSize = 25;
float dir = 3*PI/2.;
float dirStd = 0.1;

int patt = 3;
int radius = 2;
int sepNrads = 5;
int sep_px = 2*sepNrads*radius;
float sepWeight = 1.5;//use higher val if frameRate = 30, e.g., 4.0
float posStd = 0.1;

int borderw = 50;
int myheight;
int mywidth;

boolean move, separate;

int FRAME_RATE = 60;

boolean inter1, inter2, trial;
float interLenSec = 0;
int inter1Len = (int) interLenSec*FRAME_RATE;
int inter2Len = inter1Len;
float trialLenSec = 200;
int trialLen = (int) trialLenSec*FRAME_RATE;
int frameCounter;

//debug tools
boolean showBorders, showField, showGrid;
boolean usepshape = false;

void setup() {
  frameRate(FRAME_RATE);
  size(800,600,P2D);
  randomSeed(0);
  
  myheight = height - 2*borderw;
  mywidth = width - 2*borderw;
  if (dirStd > 0) field = new FlowField(tileSize, dir, dirStd);
  
  int dotColor = 255;
  int bgColor = 0;
  float mxspeed = 2;//.5*radius;
  flock = new Flock(field, sep_px, sepWeight, posStd, 
            patt, radius, dotColor, bgColor, dir, mxspeed, usepshape);

  move = false;
  separate = true;

  inter2 = true;
  frameCounter = 0;
} 

void draw () {
  
  if (inter2) {
    flock.run(move,separate,0);
    if (frameCounter ==  inter2Len) {
      println("inter2->trial");
      inter2 = false;
      trial = true;
      frameCounter = 0;
    }
  } else if (inter1) {
    flock.run(move,separate,0);
    if (frameCounter ==  inter1Len) {
      println("inter1->inter2");
      inter1 = false;
      inter2 = true;
      frameCounter = 0;
    }       
  } else {
   assert trial == true;
   flock.run(move,separate,255);
    if (frameCounter ==  trialLen) {
      println("trial->inter1");
      trial = false;
      inter1 = true;
      frameCounter = 0;
    }  
  }

  
  
  if (showBorders) drawBorders();
  if (showField) field.drawField(); 
  if (showGrid) flock.drawBinGrid();
  
  stroke(255);
  textSize(12);
  text("Frame rate: " + int(frameRate), 10, 20);
  
  frameCounter++;
}

void drawBorders() {
  stroke(120,0,0);
  noFill();
  rect(borderw,borderw,mywidth-1,myheight-1);
  
}

void keyPressed() {
  switch (key) {
    case 's':
      separate = !separate;
      break;
    case 'm':
      move = !move;
      break;
    case 'b':
      showBorders = !showBorders;
      break;
    case 'f':
      showField = !showField;
      break;
    case 'g':
      showGrid = !showGrid;
    default:
      break;
  }  
}
