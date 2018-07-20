//give the option of wiggling vs. rigid
//wiggling activates sep and a flow field during trial (params chosen based on dot radius)
//rigid deactivates those when trial begins 

//if posStd set to 0, wiggle needs to be deactivate from the start (preStim)
//if posStd > 0 and noWiggle, activate wiggle and deactivate it during trial


//compute fadeRate outside stim class (applis to all stims)

Stim stim;  
Stim[] stims;

float dir_ = 3*PI/2.;
float dirStd_ = 0;//0.08;


int radius = 10;
int sepNrads = 4;
int sep_px = sepNrads*radius;
int patt = 3;


int tileSize_ = sep_px;
float sepWeight = 1.5;//use higher val if frameRate = 30, e.g., 4.0
float posStd_ = 0.1;

int frameWidth = 50;
int myheight;
int mywidth;

//boolean move_, separate_, follow_;

int FRAME_RATE = 60;

boolean postStim, preStim, trial;
float interLenSec = 0;
int currentLen;
int postStimLen = (int) interLenSec*FRAME_RATE/2;
int preStimLen = postStimLen;
float trialLenSec = 200;
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
  
  stims = new Stim[2];
  
  int fadeframes = 3;
  int fadeRate_ = ceil(255./fadeframes);
  
  
  /*SETTING PARAMS SET FOR EACH STIM*/
  if (patt > 1) radius = int(radius/sqrt(patt));
  int dotColor1 = 255;
  int dotColor2 = 128;
  int gray1 = 80;
  
  int bgColor1 = 0;
  int bgColor2 = 0;
  int gray2 = 120;
  float maxspeed = 2;
  
  wiggle_ = true;
  if (posStd_ == 0) wiggle_ = false;
  
  /*SETTING PARAMS SET FOR EACH STIM*/
  
  
  ////POPULATE STIMS ARRAY  
  stims[0] = new Flock(tileSize_, dir_, dirStd_, sep_px, sepWeight, posStd_, 
            patt, radius, dotColor1, bgColor1, gray1, maxspeed, fadeRate_, wiggle_, usepshape);
  stims[1] = new Flock(tileSize_, dir_, dirStd_, sep_px, sepWeight, posStd_, 
            patt, radius, dotColor2, bgColor2, gray2, maxspeed, fadeRate_, wiggle_, usepshape);

  //setup trial variables for movie to begin
  preStim = true;
  currentLen = preStimLen;
  frameCounter = 0;
  trialNo = 0;
} 

void draw () {
  if (frameCounter == currentLen) {//if ending a period
    frameCounter = 0;
    if (preStim) {
      println("preStim->trial");
      preStim = false;
      trial = true;
      currentLen = trialLen;
    } else if (postStim) {
      println("postStim->preStim");
      postStim = false;
      preStim = true;
      currentLen = preStimLen;
      trialNo++;
    } else {
      assert trial == true;
      println("trial->postStim");
      trial = false;
      postStim = true;
      currentLen = postStimLen;
    }        
  }
  if (frameCounter == 0) { //if starting a period
    if (preStim || preStimLen == 0) {    
        //load new stim
        println("Loading",trialNo % 2);
        stim = stims[trialNo % 2];
    } else if (postStim) {
      ;
    } else {//end of trial
      ;
    }
  }
  
  if (trial) stim.run(true);
  else stim.run(false);

  
  if (showBorders) drawBorders();
  if (showField && ((Flock) stim).flow != null) ((Flock) stim).flow.drawField(); 
  if (showGrid) ((Flock) stim).drawBinGrid();
  
  //stroke(255);
  //textSize(12);
  //text("Frame rate: " + int(frameRate), 10, 20);
  
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
      ((Flock) stim).move = !((Flock) stim).move;
      break;
    case 's':
      ((Flock) stim).separate = !((Flock) stim).separate;
      break;
    case 'w':
      wiggle_ = !wiggle_;
      ((Flock) stim).setWiggle(wiggle_);
      break;
    case 'f':
      ((Flock) stim).follow = !((Flock) stim).follow;
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
