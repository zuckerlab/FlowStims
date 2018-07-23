//give the option of wiggling vs. rigid
//wiggling activates sep and a flow field during trial (params chosen based on dot radius)
//rigid deactivates those when trial begins 

//if posStd set to 0, wiggle needs to be deactivate from the start (preStim)
//if posStd > 0 and noWiggle, activate wiggle and deactivate it during trial

//make ellipsoidal distance radius for separation of 3-dots?

//if movie mode, instead of sending packets need to output a log with frameNo -> event

Stim stim;
StimMaker stimp;
StimMaker[] stimParams;
int nStims;
IntList stimIdxs;

int origSeed;

float dir_ = 3*PI/2.;
float dirStd_ = 0.09;

int radius = 10;
int sepNrads = 4;
int sep_px = sepNrads*radius;

int tileSize_ = sep_px*3;
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

int currentLen, frameCounter, trialIndex, totalTrials;
int totalTrialBlocks = 4;

boolean makeMovie = true;
boolean singleSeed = true;

//debug tools
boolean showBorders, showField, showGrid;
boolean usepshape = false;

boolean wiggle_;

void setup() {
  frameRate(FRAME_RATE);
  size(800,600,P2D);
  origSeed = 19;
  randomSeed(origSeed);

  
  myheight = height - 2*frameWidth;
  mywidth = width - 2*frameWidth;
  
  stimParams = new StimMaker[3];
  
  int fadeframes = 3;
  fadeRate = ceil(255./fadeframes);
  
  
  /*SETTING PARAMS SET FOR EACH FLOW STIM*/
  int patt1 = 3;
  int radius1 = radius;
  if (patt1 > 1) radius1 = int(radius1/sqrt(patt1));
  int patt2 = 1;
  int radius2 = radius;
  if (patt2 > 1) radius2 = int(radius2/sqrt(patt2));
  
  boolean fixRand1 = true;
  int seed1 = -1;
  if (fixRand1) seed1 = (int) random(1000);
  boolean fixRand2 = false;
  int seed2 = -1;
  if (fixRand2) seed2 = (int) random(1000);

  
  int dotColor1 = 255;
  int dotColor2 = 255;
  
  int bgColor1 = 0;
  int bgColor2 = 0;
  
  int gray1 = 128;
  int gray2 = 120;
  float maxspeed = 2;
  
  wiggle_ = true;
  if (posStd_ == 0) wiggle_ = false;
  
  stimParams[0] = new FlockMaker(seed1,tileSize_, dir_, dirStd_, sep_px, sepWeight, posStd_, 
            patt1, radius1, dotColor1, bgColor1, gray1, maxspeed, wiggle_, usepshape);
  stimParams[1] = new FlockMaker(seed2,tileSize_, dir_, dirStd_, sep_px, sepWeight, posStd_, 
            patt2, radius2, dotColor2, bgColor2, gray2, maxspeed, wiggle_, usepshape);
  
  /*SETTING PARAMS SET FOR EACH GRAT STIM*/
  int dirdegs = 45;//(int) degrees(dir_);
  int fg = 255;
  int bg = 0;
  int gray = 128;
  int barwid = 30;
  int spacwid = 60;
  float phas = -1; 
  
  ////POPULATE STIMS ARRAY  

  stimParams[2] = new GratingMaker(dirdegs, fg, bg, gray, barwid, spacwid, maxspeed, phas); 

  //store stim indices
  nStims = stimParams.length;
  stimIdxs = new IntList();
  for (int i = 0; i < nStims; i++) stimIdxs.append(i);
  println(stimIdxs);
  //setup trial variables for movie to begin
  preStim = true;
  currentLen = preStimLen;
  frameCounter = 0;
  trialIndex = 0;
  totalTrials = totalTrialBlocks*stimParams.length;
  


} 

void draw () {
  if (frameCounter == currentLen) {//if ending a period
       updateState();
  }
  
  if (frameCounter == 0) { //if starting a period
    if (preStim || (trial && preStimLen == 0)) {
      println("trialIndex",trialIndex);
      if (trialIndex > 0) {
        assert stimp != null;
        stimp.delete();
      }
      
      //check if new trial block
      if ((trialIndex % nStims) == 0) {
        if (trialIndex == totalTrials) {
          //println("END");
          //end movie
          noLoop();
          exit();
        }
        //else, reshuffle stims for this new block
        stimIdxs.shuffle();
        println(stimIdxs);
      } 
      println("trial",trialIndex+1,"/",totalTrials);
      //load new stim
      println("Loading "+trialIndex % nStims + "/" + nStims);
      stimp = stimParams[stimIdxs.get(trialIndex % nStims)];
      stimp.init();

    } else if (postStim) {
      ;
    } else {//end of trial
      ;
    }
  }

  if (trial) stimp.run(true);
  else stimp.run(false);
  
  if (makeMovie) saveFrame("movieframes/######.tga");
  
  frameCounter++;

  
  if (showBorders) drawBorders();
  if (showField && (stimp instanceof FlockMaker)) ((FlockMaker) stimp).stim.flow.drawField(); 
  if (showGrid && (stimp instanceof FlockMaker)) ((FlockMaker) stimp).stim.drawBinGrid();
  
  //stroke(255);
  //textSize(12);
  //text("Frame rate: " + int(frameRate), 10, 20);
  
  
}

void updateState() {
  frameCounter = 0;
  
  if (preStim) {
    
    //println("preStim->trial");
    preStim = false;
    trial = true;
    currentLen = trialLen;
    
  } else if (postStim) {
    
    postStim = false;
    trialIndex++;
    if (preStimLen == 0) {
      //println("postStim->preStim->trial");
      trial = true;
      currentLen = trialLen;
    } else {
      //println("postStim->preStim");      
      preStim = true;
      currentLen = preStimLen;
    }
    
  } else {
    
    assert trial == true;      
    if (postStimLen == 0) {
      trialIndex++;
      if (preStimLen > 0) {
        //println("trial->postStim->preStim");
        trial = false;
        preStim = true;
        currentLen = preStimLen;
      }
      //else keep it as it is!
      //else println("trial->postStim->preStim->trial");
      
    } else {
      //println("trial->postStim");
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
