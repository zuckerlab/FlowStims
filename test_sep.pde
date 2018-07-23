//give the option of wiggling vs. rigid
//wiggling activates sep and a flow field during trial (params chosen based on dot radius)
//rigid deactivates those when trial begins 

//if posStd set to 0, wiggle needs to be deactivate from the start (preStim)
//if posStd > 0 and noWiggle, activate wiggle and deactivate it during trial

//make ellipsoidal distance radius for separation of 3-dots?

//if movie mode, instead of sending packets need to output a log with frameNo -> event


//make Loader method for checking comment next to val
String VERSION = "12";

//default movie params
int monitor = 1;
int scrWidthPx = 800;
int scrHeightPx= 600;
boolean fastRendering = true;
int origSeed = 1;
//default stim params
int nDirs = 1;


PrintWriter out_params;

Stim stim;
Stim[] stims;
int nStims;
IntList stimIdxs;


float dirStd_ = 0.09;
float sepWeight = 2.;//use higher val if FRAME_RATE = 30
float maxForce = .04;
float posStd_ = 0.1;

int frameWidth = 0;
int myheight;
int mywidth;

int FRAME_RATE = 60;
int fadeRate;
boolean postStim, preStim, trial;
float preStimLenSec = 1.;
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


void settings() {
  int d = day();  int m = month();  int y = year(); int min = minute(); int h = hour(); 
  String today = String.valueOf(y-2000)+String.format("%02d",m)+String.format("%02d",d);
  String now = String.format("%02d",h)+String.format("%02d",min);
  out_params = createWriter(today+"_"+now+"_params.log"); 

  String[] lines = loadStrings("params.txt");
  loadParams(lines);
  size(scrWidthPx,scrHeightPx,P2D);
  if (fastRendering) {
    fullScreen(P2D,monitor);
  } else {
    fullScreen(monitor);
  }
  
  frameRate(FRAME_RATE);

}

void setup() {  

  preStimLen = (int) (preStimLenSec*FRAME_RATE);
  postStimLen = (int) (postStimLenSec*FRAME_RATE);
  trialLen = (int) (trialLenSec*FRAME_RATE);
  
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
 
  
  /*SETTING PARAMS SET FOR EACH STIM*/

  
  
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
              //println(dirdeg,maxspeed,ndots,diam_px,sep_px,tilesize,fgcolor,bgcolor,gray,seed);
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
            //println(dirdeg,maxspeed,barwid,fgcolor,bgcolor,gray);
            stims[s] = new Grating(dirdeg, fgcolor, bgcolor, gray, barwid, maxspeed, gratphas); 
            s++;
        }
      }
    }
  }


  //store stim indices
  stimIdxs = new IntList();
  for (int i = 0; i < nStims; i++) stimIdxs.append(i);
  
  //setup trial variables for movie to begin
  preStim = true;
  currentLen = preStimLen;
  frameCounter = 0;
  trialIndex = 0;
  totalTrials = totalTrialBlocks*nStims;
  
} 

void draw () {

  if (frameCounter == currentLen) {//if ending a period
       updateState();
  }
  
  if (frameCounter == 0) { //if starting a period
    if (preStim || (trial && preStimLen == 0)) {
      //println("trialIndex",trialIndex);
      //if (trialIndex > 0) {
      //  assert stimp != null;
      //  stimp.delete();
      //}
      
      //check if new trial block
      if ((trialIndex % nStims) == 0) {
        if (trialIndex == totalTrials) {
          //end movie
          noLoop();
          exit();
        }
        //else, reshuffle stims for this new block
        stimIdxs.shuffle(this);
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

void loadParams(String[] lines) {
  if (lines == null || lines.length == 0) {
    System.out.printf("Invalid params.txt file!\n");
    out_params.close();
    System.exit(1);
  }
  for (int p = 0; p < lines.length; p++) {
    String line = lines[p];
    if (line.length() > 0 && line.charAt(0) != '#') {
      String[] list = split(line, ' ');
      if (list.length < 2) continue;
      switch(list[0]) {
         case "FlowStims": //check version of params file          
           if (!list[1].equals(VERSION)) {
             System.out.printf("Incompatible version of params.txt file! Should be %s\n",VERSION);
             out_params.close();
             System.exit(1);            
           }
           out_params.print("FlowStims ");
           out_params.println(list[1]);
           break;
        case "scrWidthPx": scrWidthPx = Loader.loadInt(list[1],list[0],out_params); break;
        case "scrHeightPx": scrHeightPx = Loader.loadInt(list[1],list[0],out_params); break;
        case "monitor": monitor = Loader.loadInt(list[1],list[0],out_params); break;
        case "fastRendering": fastRendering = Loader.loadBool(list[1],list[0],out_params); break;
        case "frameRate": FRAME_RATE = Loader.loadInt(list[1],list[0],out_params); break;
        case "randSeed": origSeed = Loader.loadInt(list[1],list[0],out_params); break;
        case "nDirs": nDirs = Loader.loadInt(list[1],list[0],out_params); break;
                 case "nTrialBlocks":
           nTrials = Loader.loadInt(list[1],"nTrials ",out_params);
           break;
                    case "scrWidthCm":
           scrWidthCm = Loader.loadFloat(list[1],"scrWidthCm ",out_params);
           break;
         case "scrDistCm":
           scrDistCm = Loader.loadFloat(list[1],"scrDistCm ",out_params);
           break;
         case "pxPerDeg":
           pxPerDeg = Loader.loadFloat(list[1],"pxPerDeg ",out_params);
           break;
              case "maxForce":
           maxForce = Loader.loadFloat(list[1],"maxForce ",out_params);
           break;
            case "gratPhase":
           gratPhase = Loader.loadFloat(list[1],"gratPhase ",out_params);
           break;
          case "dotColor":
           dotColorList = new ArrayList<Integer>();
           nDotColors = Loader.loadMultiInt(list,"dotColor ",out_params,dotColorList);
           dotColor = dotColorList.get(0);
           if (nDotColors > 1)
             multiDotColors = true;
           break;
         case "dotBgColor":
           bgColorList = new ArrayList<Integer>();    
           dotBgColor = Loader.loadDepMultiInt(list,"dotBgColor ",out_params,bgColorList,nDotColors);
           break;
         case "dotGrayScrLvl":
           grayLvlList = new ArrayList<Integer>(); 
           dotGrayScrLvl = Loader.loadDepMultiInt(list,"dotGrayScrLvl ",out_params,grayLvlList,nDotColors);
           break;
           //booleans: show Gratings, show Flows 
         case "gratSF":
           gratSFList = new ArrayList<Float>();
           nGratSizes = Loader.loadMultiFloat(list,"gratSF ",out_params,gratSFList);
           gratSF = gratSFList.get(0);
           if (nGratSizes > 1)
             multiGratSizes = true;
           break;
        case "gratColor":
           gratColorList = new ArrayList<Integer>();
           nGratColors = Loader.loadMultiInt(list,"gratColor ",out_params,gratColorList);
           gratColor = gratColorList.get(0);
           if (nGratColors > 1)
             multiGratColors = true;
           break;
         case "gratBgColor":
           gratBgColorList = new ArrayList<Integer>();    
           gratBgColor = Loader.loadDepMultiInt(list,"gratBgColor ",out_params,gratBgColorList,nGratColors);
           break;
         case "gratGrayScrLvl":
           gratGrayLvlList = new ArrayList<Integer>(); 
           gratGrayScrLvl = Loader.loadDepMultiInt(list,"gratGrayScrLvl ",out_params,gratGrayLvlList,nGratColors);
           break;
         case "dotType":
           dotTypeList = new ArrayList<Integer>();
           nDotTypes = Loader.loadMultiInt(list,"dotType ",out_params,dotTypeList);
           dotType = dotTypeList.get(0);
           if (nDotTypes > 1)
             multiDotTypes = true;
           break;
         case "dotSize":
           dotSizeList = new ArrayList<Float>();
           nDotSizes = Loader.loadMultiFloat(list,"dotSize ",out_params,dotSizeList);
           dotSize = dotSizeList.get(0);
           if (nDotSizes > 1)
             multiDotSizes = true;
           break;
         case "dotSpacing":
           baseSpacList = new ArrayList<Float>();
           baseSpacing = Loader.loadDepMultiFloat(list,"dotSpacing ",out_params,baseSpacList,nDotSizes);
           baseSpacing = baseSpacList.get(0);
           break;
         case "dotSeparation":
           dotSeparation = Loader.loadFloat(list[1],"dotSeparation ",out_params);
           break; 
         case "dotSeparationTrial":
           dotSeparationTrial = Loader.loadFloat(list[1],"dotSeparationTrial ",out_params);
           break;  
         case "fadeRate":
           fadeRate = Loader.loadFloat(list[1],"fadeRate ",out_params);
           break; 
         case "tileSize":
           tileSizeList = new ArrayList<Integer>();
           tileSize = Loader.loadDepMultiInt(list,"tileSize ",out_params,tileSizeList,nDotTypes);
           break;
         case "tempFreq":
           speedList = new ArrayList<Float>();
           nSpeeds = Loader.loadMultiFloat(list,"tempFreq ",out_params,speedList);
           tempFreq = speedList.get(0);
           if (nSpeeds > 1)
             multiSpeeds = true;
           break;
         case "posStd":
           posStd = Loader.loadFloat(list[1],"posStd ",out_params);
           break;
         case "trialLength":
           trialLength = Loader.loadInt(list[1],"trialLength ",out_params);
           break;           
         case "grayScrLength":
           grayScrLength = Loader.loadInt(list[1],"grayScrLength ",out_params);
           break;
         case "clientStart":
           clientStart = new Client(list[1]);
           Loader.loadClient(clientStart,list,"clientStart ",out_params);
           break;
         case "clientEnd":
           clientEnd = new Client(list[1]);
           Loader.loadClient(clientEnd,list,"clientEnd ",out_params);
           break;
         case "clientTrialStart":
           clientTrialStart = new Client(list[1]);
           Loader.loadClient(clientTrialStart,list,"clientTrialStart ",out_params);
           break;
         case "clientTrialEnd":
           clientTrialEnd = new Client(list[1]);
           Loader.loadClient(clientTrialEnd,list,"clientTrialEnd ",out_params);
           break;
         case "clientTimeStamp":
           clientTimeStamp = new Client(list[1]);
           tStampInterval = int(FRAME_RATE * Loader.loadClientInterval(clientTimeStamp,list,"clientTimeStamp ",out_params));
           break;
         default:
           break;
      }
    }
  }
}



void keyPressed() {
  switch (key) {
    case ESC:
      noLoop();
      exit();
    case 'm':
      if (stim instanceof Flock) ((Flock) stim).move = !((Flock) stim).move;
      break;
    case 's':
      if (stim instanceof Flock) ((Flock) stim).separate = !((Flock) stim).separate;
      break;
    case 'w':
      wiggle = !wiggle;
      if (stim instanceof Flock) ((Flock) stim).setWiggle(wiggle);
      break;
    case 'f':
      if (stim instanceof Flock) ((Flock) stim).follow = !((Flock) stim).follow;
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
