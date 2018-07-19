//give the option of wiggling vs. rigid
//wiggling activates sep and a flow field during trial (params chosen based on dot radius)
//rigid deactivates those when trial begins 

//if posStd set to 0, wiggle needs to be deactivate from the start (inter2)
//if posStd > 0 and noWiggle, activate wiggle and deactivate it during trial

Stim flock;  
FlowField field;

float dir_ = 3*PI/2.;
float dirStd_ = 0.08;

int patt = 1;
int radius = 10;
int sepNrads = 4;
int sep_px = sepNrads*radius;
int tileSize_ = sep_px;
float sepWeight = 1.5;//use higher val if frameRate = 30, e.g., 4.0
float posStd_ = 0.1;

int frameWidth = 50;
int myheight;
int mywidth;

//boolean move_, separate_, follow_;

int FRAME_RATE = 60;

boolean inter1, inter2, trial;
float interLenSec = 2;
int inter1Len = (int) interLenSec*FRAME_RATE/2;
int inter2Len = inter1Len;
float trialLenSec = 4;
int trialLen = (int) trialLenSec*FRAME_RATE;
int frameCounter, trialNo;

//debug tools
boolean showBorders, showField, showGrid;
boolean usepshape = false;

boolean wiggle_;

void setup() {
  frameRate(FRAME_RATE);
  size(800,600);
  randomSeed(0);
  
  myheight = height - 2*frameWidth;
  mywidth = width - 2*frameWidth;
  
  
  int dotColor = 255;
  int bgColor = 0;
  float maxspeed = 2;
  
  wiggle_ = false;
  if (posStd_ == 0) wiggle_ = false;
  
  flock = new Flock(tileSize_, dir_, dirStd_, sep_px, sepWeight, posStd_, 
            patt, radius, dotColor, bgColor, maxspeed, 3, wiggle_, usepshape);
  
  
  //flock.setWiggle(wiggle_);

  inter2 = true;
  frameCounter = 0;
  trialNo = 0;
} 

void draw () {
  
  if (inter2) {
    
    if (frameCounter ==  inter2Len) {//end of inter2
      println("inter2->trial");
      inter2 = false;
      trial = true;
      frameCounter = 0;
    }
  } else if (inter1) {
    
    if (frameCounter ==  inter1Len) {//end of inter1
      println("inter1->inter2");
      inter1 = false;
      inter2 = true;
      frameCounter = 0;
      
      trialNo++;
    }       
  } else {//end of trial
   assert trial == true;
   
    if (frameCounter ==  trialLen) {
      println("trial->inter1");
      trial = false;
      inter1 = true;
      frameCounter = 0;
    }  
  }
  
  if (trial) flock.run(true);
  else flock.run(false);

  
  if (showBorders) drawBorders();
  if (showField && ((Flock) flock).flow != null) ((Flock) flock).flow.drawField(); 
  if (showGrid) ((Flock) flock).drawBinGrid();
  
  stroke(255);
  textSize(12);
  text("Frame rate: " + int(frameRate), 10, 20);
  
  frameCounter++;
}

void drawBorders() {
  stroke(120,0,0);
  noFill();
  rect(frameWidth,frameWidth,mywidth-1,myheight-1); 
}



void keyPressed() {
  switch (key) {
    case 'm':
      ((Flock) flock).move = !((Flock) flock).move;
      break;
    case 's':
      ((Flock) flock).separate = !((Flock) flock).separate;
      break;
    case 'w':
      wiggle_ = !wiggle_;
      ((Flock) flock).setWiggle(wiggle_);
      break;
    case 'f':
      ((Flock) flock).follow = !((Flock) flock).follow;
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
