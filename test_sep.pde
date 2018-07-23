//give the option of wiggling vs. rigid
//wiggling activates sep and a flow field during trial (params chosen based on dot radius)
//rigid deactivates those when trial begins 

//if posStd set to 0, wiggle needs to be deactivate from the start (preStim)
//if posStd > 0 and noWiggle, activate wiggle and deactivate it during trial

//make ellipsoidal distance radius for separation of 3-dots?

//if movie mode, instead of sending packets need to output a log with frameNo -> event

Stim stim;
//StimMaker stimp;
//StimMaker[] stimParams;
Stim[] stims;
int nStims;
IntList stimIdxs;

int origSeed;

float dirStd_ = 0.09;

float sepWeight = 1.5;//use higher val if frameRate = 30, e.g., 4.0
float posStd_ = 0.1;

int frameWidth = 0;
int myheight;
int mywidth;

//boolean move_, separate_, follow_;

int FRAME_RATE;
int fadeRate;
boolean postStim, preStim, trial;
float preStimLenSec = .5;
float postStimLenSec = .5;
float trialLenSec = 2;

int preStimLen, postStimLen, trialLen;

int currentLen, frameCounter, trialIndex, totalTrials;
int totalTrialBlocks = 4;

boolean makeMovie = true;

//debug tools
boolean showBorders, showField, showGrid;
boolean usePShape = false;

boolean wiggle = true;

void setup() {
  
  size(800,600,P2D);
  FRAME_RATE = 60;
  frameRate(FRAME_RATE);
  preStimLen = (int) (preStimLenSec*FRAME_RATE);
  postStimLen = (int) (postStimLenSec*FRAME_RATE);
  trialLen = (int) (trialLenSec*FRAME_RATE);
  
  origSeed = 19;
  randomSeed(origSeed);
  
  final float PX_PER_DEG = 10.37;

  myheight = height - 2*frameWidth;
  mywidth = width - 2*frameWidth;

  int fadeframes = 3;
  fadeRate = ceil(255./fadeframes);

  if (posStd_ == 0) wiggle = false;
  
  boolean fixRand = true;
  int seed = -1;
  float gratphas = -1;
  
  //if flows arent rand, then most likely you dont want rand grating phase either
  if (fixRand && gratphas == -1) gratphas = 0;//(catching possibly common mistake when setting params file)
 
  
  /*SETTING PARAMS SET FOR EACH FLOW STIM*/
  int nDirs = 8;
  
  
  IntList nDots = new IntList();
  nDots.append(1);
  nDots.append(3);
  
  FloatList dotDiamsDeg = new FloatList();
  dotDiamsDeg.append(.8);
  
  FloatList dotSeps = new FloatList();
  dotSeps.append(3);


  IntList dotColors = new IntList();
  dotColors.append(255);
  dotColors.append(0);  
  IntList dotBgColors = new IntList();
  dotBgColors.append(0);
  dotBgColors.append(255);  
  IntList dotInterColors = new IntList();
  dotInterColors.append(128);
  dotInterColors.append(128);
  
  FloatList stimSpeeds = new FloatList();
  stimSpeeds.append(2.);
  
  IntList gratColors = new IntList();
  gratColors.append(255);
  gratColors.append(68);  
  IntList gratBgColors = new IntList();
  gratBgColors.append(0);
  gratBgColors.append(119); 
  IntList gratInterColors = new IntList();
  gratInterColors.append(128);
  gratInterColors.append(128);

  IntList gratWidths = new IntList();
  gratWidths.append(60);
  


  nStims = nDirs*stimSpeeds.size()*(nDots.size()*dotColors.size()*dotDiamsDeg.size()*dotSeps.size()
               + gratWidths.size()*gratColors.size());
  stims = new Stim[nStims];
  println("nStims",nStims);
  float dir, maxspeed, diam_deg, sep;
  int dirdeg, ndots, fgcolor, bgcolor, gray, diam_px, sep_px, tilesize, barwid;
  
  int s = 0;
  for (int dr = 0; dr < nDirs; dr++) {
    dir = dr*(TWO_PI/nDirs);
    dirdeg = round(dr*(360./nDirs)); 
    
    for (int sp = 0; sp < stimSpeeds.size(); sp++) {
      maxspeed = stimSpeeds.get(sp);
      
      //FLOWS
      for (int dt = 0; dt < nDots.size(); dt++) {
        ndots = nDots.get(dt);
        
        for (int sz = 0; sz < dotDiamsDeg.size(); sz++) {
          diam_deg = dotDiamsDeg.get(sz);
          diam_px = round(diam_deg*PX_PER_DEG);
            
          for (int se = 0; se < dotSeps.size(); se++) {
            sep = dotSeps.get(se);
            sep_px = round(sep*diam_px); //based on original diameter, i.e., before area correction
            tilesize = sep_px*3;
            
            for (int cc = 0; cc < dotColors.size(); cc++) {
              fgcolor = dotColors.get(cc);
              bgcolor = dotBgColors.get(cc);
              gray = dotInterColors.get(cc);
              
              if (fixRand) seed = (int) random(1000);
              println(dirdeg,maxspeed,ndots,diam_px,sep_px,tilesize,fgcolor,bgcolor,gray,seed);
              stims[s] = new Flock(seed, tilesize, dir, dirStd_, sep_px, posStd_, ndots, diam_px, fgcolor, bgcolor, gray, maxspeed);
              s++;

            }
          }
        }
      }
      //GRATS
      for (int sz = 0; sz < gratWidths.size(); sz++) {
        barwid = gratWidths.get(sz);
        
        for (int cc = 0; cc < gratColors.size(); cc++) {
            fgcolor = gratColors.get(cc);
            bgcolor = gratBgColors.get(cc);
            gray = gratInterColors.get(cc);
            println(dirdeg,maxspeed,barwid,fgcolor,bgcolor,gray);
            stims[s] = new Grating(dirdeg, fgcolor, bgcolor, gray, barwid, maxspeed, gratphas); 
            s++;
        }
      }
    }
  }


  //store stim indices

  stimIdxs = new IntList();
  for (int i = 0; i < nStims; i++) stimIdxs.append(i);
  println(stimIdxs);
  
  //setup trial variables for movie to begin
  preStim = true;
  currentLen = preStimLen;
  frameCounter = 0;
  trialIndex = 0;
  totalTrials = totalTrialBlocks*nStims;
  
  println("currentLen",currentLen);

} 

void draw () {

  if (frameCounter == currentLen) {//if ending a period
       updateState();
  }
  
  if (frameCounter == 0) { //if starting a period
    if (preStim || (trial && preStimLen == 0)) {
      println("trialIndex",trialIndex);
      //if (trialIndex > 0) {
      //  assert stimp != null;
      //  stimp.delete();
      //}
      
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
      stim = stims[stimIdxs.get(trialIndex % nStims)];
      stim.init();

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
  if (showField && (stim instanceof Flock)) ((Flock) stim).flow.drawField(); 
  if (showGrid && (stim instanceof Flock)) ((Flock) stim).drawBinGrid();
  
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
    trialIndex++;
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
      trialIndex++;
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
      wiggle = !wiggle;
      ((Flock) stim).setWiggle(wiggle);
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
