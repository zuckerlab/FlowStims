//give the option of wiggling vs. rigid
//wiggling activates sep and a flow field during trial (params chosen based on dot radius)
//rigid deactivates those when trial begins 

//if posStd set to 0, wiggle needs to be deactivate from the start (preStim)
//if posStd > 0 and noWiggle, activate wiggle and deactivate it during trial

//send client packets
//if movie mode, instead of sending packets need to output a log with frameNo -> event
//log trials
//start from shifted 3dots when posStd > 0? (maybe check spat freq first)
 
//use rotated (theta) ellipse equation (*pattern) for separation of n dots 


String VERSION = "2";

//default movie params
int monitor = 1;
int scrWidthPx = 800;
int scrHeightPx= 600;
float scrWidthCm = 40;
float scrHeightCm = 30;
float scrDistCm = 25;
boolean fastRendering = true;
int FRAME_RATE = 60;
int origSeed = 1;

PrintWriter out_params, out_trials;

Stim stim;
Stim[] stims;
int nStims;
IntList stimIdxs;

Client clientStart, clientEnd, clientTrialStart, clientTrialEnd, clientTimeStamp;
int tStampInterval;
long timestamp;

int myheight;
int mywidth;


boolean postStim, preStim, trial;
float preStimLenSec = 1.;
float postStimLenSec = .5;
float trialLenSec = 2.;
int preStimLen, postStimLen, trialLen; //in frames

int currentLen, frameCounter, trialIndex, totalTrials;
int nTrialBlocks = 1;

String[] lines;

boolean makeMovie = false;

//debugging tools
boolean showBorders, showField, showGrid;
boolean usePShape = false;
int frameWidth = 0;

boolean fullScr = false;

void settings() {
  println(FRAME_RATE);
  int d = day();  int m = month();  int y = year(); int min = minute(); int h = hour(); 
  String today = String.valueOf(y-2000)+String.format("%02d",m)+String.format("%02d",d);
  String now = String.format("%02d",h)+String.format("%02d",min);
  out_params = createWriter(today+"_"+now+"_params.log");
  out_trials = createWriter(today+"_"+now+"_trials.log");

  lines = loadStrings("params.txt");
  loadSettingsParams(lines);
  
  if (!fullScr) {
    if (fastRendering) size(scrWidthPx,scrHeightPx,P2D);
    else size(scrWidthPx,scrHeightPx);
    
  } else{
    if (fastRendering) fullScreen(P2D,monitor);
    else fullScreen(monitor);
  }
  
  

}

void setup() {
  //default stim params  
  loadSetupParams(lines);
  
  preStimLen = (int) (preStimLenSec*FRAME_RATE);
  postStimLen = (int) (postStimLenSec*FRAME_RATE);
  trialLen = (int) (trialLenSec*FRAME_RATE);
  
  frameRate(FRAME_RATE);
  randomSeed(origSeed);

  myheight = height - 2*frameWidth;
  mywidth = width - 2*frameWidth;
  Loader loader = new Loader();

  //convert sizes from visual degrees to pixels (using scr width)
  float scrWidthDeg = 2*atan(.5*scrWidthCm/scrDistCm)*180/PI;
  float pxPerDeg = scrWidthPx/scrWidthDeg;
  
  stims = loader.loadStims(pxPerDeg, lines, out_params);
  //done reading params input file
  out_params.flush();
  out_params.close();
  
  nStims = stims.length;
  //store stim indices
  stimIdxs = new IntList();
  for (int i = 0; i < nStims; i++) stimIdxs.append(i);
  
  //setup trial variables for movie to begin
  preStim = true;
  currentLen = preStimLen;
  frameCounter = 0;
  trialIndex = 0;
  totalTrials = nTrialBlocks*nStims;
  
  if (clientStart != null) clientStart.send("",0);
} 

void draw () {
  
  if (frameCounter == currentLen) {//if current period ended
       updateState();
  }
  
  if (frameCounter == 0) { //if starting a period
    timestamp = System.currentTimeMillis();

    if (preStim || (trial && preStimLen == 0)) {
      if (stim != null) stim.cleanUp();
      //println("trialIndex",trialIndex);
      //if (trialIndex > 0) {
      //  assert stimp != null;
      //  stimp.delete();
      //}
      
      //check if new trial block
      if ((trialIndex % nStims) == 0) {
        if (trialIndex == totalTrials) {
          //close output file
          out_trials.flush();
          out_trials.close();          
          //Send "End" trigger
          if (clientEnd != null) clientEnd.send("",0); //End msg is fixed
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

    }
    if (trial) {
      String stimInfo = stim.getStimInfo();      
      out_trials.println(String.format("%d %d %s",frameCount-1,timestamp,stimInfo));      
      if (clientTrialStart != null) clientTrialStart.send("",0);      
    } else if (preStim) {
      //record start of preStim interval
      out_trials.println(String.format("%d %d PRESTIM",frameCount-1,timestamp));            
    } else if (postStim) {
      //record start of postStim interval
      out_trials.println(String.format("%d %d POSTSTIM",frameCount-1,timestamp));
      if (clientTrialEnd != null) clientTrialEnd.send("",0);
    }
  }

  if (trial) stim.run(true);
  else stim.run(false);
  
  if (makeMovie) saveFrame("movieframes/######.tga");
  
  frameCounter++;

  
  if (showBorders) drawBorders();
  if (showField && (stim instanceof Flock)) ((Flock) stim).flow.drawField(); 
  if (showGrid && (stim instanceof Flock)) ((Flock) stim).drawBinGrid();
  
  //stroke(0);
  //textSize(16);
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

void loadSettingsParams(String[] lines) {
  if (lines == null || lines.length == 0) {
    System.out.printf("Invalid params.txt file!\n");
    out_params.close();
    System.exit(1);
  }
  Loader loader = new Loader();
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
        case "scrWidthPx": scrWidthPx = loader.loadInt(list[1],list[0],out_params); break;
        case "scrHeightPx": scrHeightPx = loader.loadInt(list[1],list[0],out_params); break;
        case "monitor": monitor = loader.loadInt(list[1],list[0],out_params); break;
        case "fastRendering": fastRendering = loader.loadBool(list[1],list[0],out_params); break;
        case "frameRate": FRAME_RATE = loader.loadInt(list[1],list[0],out_params); break;
        case "saveScrShots": makeMovie = loader.loadBool(list[1],list[0],out_params); break;
        default: break;
      }
    }
  }
}
void loadSetupParams(String[] lines) {
  Loader loader = new Loader();
  for (int p = 0; p < lines.length; p++) {
    String line = lines[p];
    if (line.length() > 0 && line.charAt(0) != '#') {
      String[] list = split(line, ' ');
      if (list.length < 2) continue;
      switch(list[0]) {        
        case "randSeed": origSeed = loader.loadInt(list[1],list[0],out_params); break;
        case "nTrialBlocks": nTrialBlocks = loader.loadInt(list[1],list[0],out_params); break;
        case "scrDistCm": scrDistCm = loader.loadFloat(list[1],"scrDistCm ",out_params); break;
        case "scrWidthCm": scrWidthCm = loader.loadFloat(list[1],list[0],out_params); break;
        case "scrHeightCm": scrHeightCm = loader.loadFloat(list[1],list[0],out_params); break;
        case "trialLenSec": trialLenSec = loader.loadFloat(list[1],list[0],out_params); break;
        case "preStimLenSec": preStimLenSec = loader.loadFloat(list[1],list[0],out_params); break;
        case "postStimLenSec": postStimLenSec = loader.loadFloat(list[1],list[0],out_params); break;
         case "clientStart":
           clientStart = new Client(list[1]);
           loader.loadClient(clientStart,list,list[0],out_params); break;
         case "clientEnd":
           clientEnd = new Client(list[1]);
           loader.loadClient(clientEnd,list,list[0],out_params); break;
         case "clientTrialStart":
           clientTrialStart = new Client(list[1]);
           loader.loadClient(clientTrialStart,list,list[0],out_params); break;
         case "clientTrialEnd":
           clientTrialEnd = new Client(list[1]);
           loader.loadClient(clientTrialEnd,list,list[0],out_params); break;
         case "clientTimeStamp":
           clientTimeStamp = new Client(list[1]);
           tStampInterval = int(FRAME_RATE * loader.loadClientInterval(clientTimeStamp,list,list[0],out_params)); break;
         default: break;
      }
    }
  }
}



void keyPressed() {
  switch (key) {
    case ESC:
      out_trials.flush();
      out_trials.close();
      if (clientEnd != null) clientEnd.send("",0);
      noLoop();
      exit();
    case 'm':
      if (stim instanceof Flock) ((Flock) stim).move = !((Flock) stim).move;
      break;
    case 's':
      if (stim instanceof Flock) ((Flock) stim).separate = !((Flock) stim).separate;
      break;
    case 'w':
      if (stim instanceof Flock) ((Flock) stim).setWiggle(!(((Flock) stim).wiggle));
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
