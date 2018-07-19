//give the option of wiggling vs. rigid
//wiggling activates sep and a flow field during trial (params chosen based on dot radius)
//rigid deactivates those when trial begins 

//if posStd set to 0, wiggle needs to be deactivate from the start (inter2)
//if posStd > 0 and noWiggle, activate wiggle and deactivate it during trial

Flock flock;  
FlowField field;

float dir = 3*PI/2.;
float dirStd = 0.2;

int patt = 1;
int radius = 10;
int sepNrads = 6;
int sep_px = sepNrads*radius;
int tileSize = sep_px;
float sepWeight = 1.5;//use higher val if frameRate = 30, e.g., 4.0
float posStd = 0.;

int borderw = 50;
int myheight;
int mywidth;

boolean move_, separate_, follow_;

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
  float mxspeed = 2;
  flock = new Flock(field, sep_px, sepWeight, posStd, 
            patt, radius, dotColor, bgColor, dir, mxspeed, usepshape);

  move_ = true;
  separate_ = false;
  follow_ = separate_;

  inter2 = true;
  frameCounter = 0;
} 

void draw () {
  
  if (inter2) {
    
    if (frameCounter ==  inter2Len) {
      println("inter2->trial");
      inter2 = false;
      trial = true;
      frameCounter = 0;
    }
  } else if (inter1) {
    
    if (frameCounter ==  inter1Len) {
      println("inter1->inter2");
      inter1 = false;
      inter2 = true;
      frameCounter = 0;
    }       
  } else {
   assert trial == true;
   
    if (frameCounter ==  trialLen) {
      println("trial->inter1");
      trial = false;
      inter1 = true;
      frameCounter = 0;
    }  
  }
  
  if (trial) flock.run(move_,separate_,follow_,255);
  else flock.run(move_,separate_,follow_,0);

  
  
  if (showBorders) drawBorders();
  if (showField && field != null) field.drawField(); 
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

void toggleWiggle() {
  separate_ = !separate_;
  follow_ = !follow_;
}

void keyPressed() {
  switch (key) {
    case 'm':
      move_ = !move_;
      break;
    case 's':
      separate_ = !separate_;
      break;
    case 'w':
      toggleWiggle();
      break;
    case 'f':
      follow_ = !follow_;
      break;
    case 'b':
      showBorders = !showBorders;
      break;
    case 't':
      showField = !showField;
      break;
    case 'g':
      showGrid = !showGrid;
    default:
      break;
  }  
}
