//give the option of wiggling vs. rigid
//wiggling activates sep and a flow field during trial (params chosen based on dot radius)
//rigid deactivates those when trial begins 

//if posStd set to 0, wiggle needs to be deactivate from the start (preStim)
//if posStd > 0 and noWiggle, activate wiggle and deactivate it during trial

//make ellipsoidal distance radius for separation of 3-dots?

//use same seed for multiple Flock trials (reproducible option): could be done in main, before each
  //new trial block --- NO! only if classes are re-initialized!


Stim stim;  
Stim[] stims;

float dir_ = 3*PI/2.;
float dirStd_ = 0.08;


int radius = 10;
int sepNrads = 4;
int sep_px = sepNrads*radius;
int patt = 3;


int tileSize_ = sep_px;
float sepWeight = 1.5;//use higher val if frameRate = 30, e.g., 4.0
float posStd_ = 0.1;

int frameWidth = 0;
int myheight;
int mywidth;

//boolean move_, separate_, follow_;

int FRAME_RATE = 60;
int fadeRate;
boolean postStim, preStim, trial;
float preStimLenSec = .5;
float postStimLenSec = .5;
float trialLenSec = 2;

int preStimLen = (int) (preStimLenSec*FRAME_RATE);
int postStimLen = (int) (postStimLenSec*FRAME_RATE);
int trialLen = (int) (trialLenSec*FRAME_RATE);

int currentLen, frameCounter, trialNo, totalTrials;
int totalTrialBlocks = 1;

boolean makeMovie = true;
boolean singleSeed = true;

//debug tools
boolean showBorders, showField, showGrid;
boolean usepshape = false;

boolean wiggle_;

void setup() {
  frameRate(FRAME_RATE);
  size(800,600,P2D);
  randomSeed(0);
  
  myheight = height - 2*frameWidth;
  mywidth = width - 2*frameWidth;
  
  stims = new Stim[3];
  
  int fadeframes = 3;
  fadeRate = ceil(255./fadeframes);
  
  
  /*SETTING PARAMS SET FOR EACH FLOW STIM*/
  if (patt > 1) radius = int(radius/sqrt(patt));
  int dotColor1 = 255;
  int dotColor2 = 128;
  
  int bgColor1 = 0;
  int bgColor2 = 0;
  
  int gray1 = 128;
  int gray2 = 120;
  float maxspeed = 2;
  
  wiggle_ = true;
  if (posStd_ == 0) wiggle_ = false;
  
  stims[0] = new Flock(tileSize_, dir_, dirStd_, sep_px, sepWeight, posStd_, 
            patt, radius, dotColor1, bgColor1, gray1, maxspeed, wiggle_, usepshape);
  stims[1] = new Flock(tileSize_, dir_, dirStd_, sep_px, sepWeight, posStd_, 
            patt, radius, dotColor2, bgColor2, gray2, maxspeed, wiggle_, usepshape);
  
  /*SETTING PARAMS SET FOR EACH GRAT STIM*/
  int dirdegs = 45;//(int) degrees(dir_);
  int fg = 255;
  int bg = 0;
  int gray = 128;
  int barwid = 30;
  int spacwid = 60;
  float phas = 0; 
  
  ////POPULATE STIMS ARRAY  

  stims[2] = new Grating(dirdegs, fg, bg, gray, barwid, spacwid, maxspeed, phas); 

  //setup trial variables for movie to begin
  preStim = true;
  currentLen = preStimLen;
  frameCounter = 0;
  trialNo = 0;
  totalTrials = totalTrialBlocks*stims.length;
} 

void draw () {
  if (frameCounter == currentLen) {//if ending a period
       updateState();
  }
  
  if (frameCounter == 0) { //if starting a period
    if (preStim || (trial && preStimLen == 0)) {
      
      //check if new trial block
      if ((trialNo % stims.length) == 0) {
        if (trialNo == totalTrials) {
          //end movie
          exit();
        } 
      } 
      println("trial",trialNo,"/",totalTrials);
      //load new stim
      println("Loading "+trialNo % stims.length + "/" + stims.length);
      stim = stims[trialNo % stims.length];

    } else if (postStim) {
      ;
    } else {//end of trial
      ;
    }
  }

  if (trial) stim.run(true);
  else stim.run(false);
  
  if (makeMovie) saveFrame("movieframes/######.tga");
  
  frameCounter++;

  
  if (showBorders) drawBorders();
  if (showField && ((Flock) stim).flow != null) ((Flock) stim).flow.drawField(); 
  if (showGrid) ((Flock) stim).drawBinGrid();
  
  //stroke(255);
  //textSize(12);
  //text("Frame rate: " + int(frameRate), 10, 20);
  
  
}

void updateState() {
  frameCounter = 0;
  
  if (preStim) {
    
    println("preStim->trial");
    preStim = false;
    trial = true;
    currentLen = trialLen;
    
  } else if (postStim) {
    
    postStim = false;
    trialNo++;
    if (preStimLen == 0) {
      println("postStim->preStim->trial");
      trial = true;
      currentLen = trialLen;
    } else {
      println("postStim->preStim");      
      preStim = true;
      currentLen = preStimLen;
    }
    
  } else {
    
    assert trial == true;      
    if (postStimLen == 0) {
      trialNo++;
      if (preStimLen > 0) {
        println("trial->postStim->preStim");
        trial = false;
        preStim = true;
        currentLen = preStimLen;
      }
      //else keep it as it is!
      else println("trial->postStim->preStim->trial");
      
    } else {
      println("trial->postStim");
      trial = false;
      postStim = true;
      currentLen = postStimLen;
    }
  }
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
