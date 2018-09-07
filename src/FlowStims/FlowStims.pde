String VERSION = "1.0";

//default movie params
int monitor = 1;
int scrWidthPx = 800;
int scrHeightPx= 600;
float scrWidthCm = 40;
float scrDistCm = 25;
boolean fastRendering = true, antiAlias = true;
int FRAME_RATE = 60;
int globalSeed = -1;

int nDirs, dirDegShift;

PrintWriter out_params, out_trials;

Stim stim;
Stim[] stims;
int nStims;
IntList stimIdxs;

ArrayList<Client> clientStartList, clientEndList;
Client clientTrialStart, clientTrialEnd, clientTimeStamp;
int tStampInterval, tStampCounter = 0;
long timestamp, start_time;

int myheight;
int mywidth;


boolean postStim, preStim, trial;
float preStimLenSec = 1.;
float postStimLenSec = 1;
float trialLenSec = 2.;
int preStimLen, postStimLen, trialLen; //in frames

int currentLen, periodFrameCount, trialIndex, totalTrials;
int nTrialBlocks = 1;

String[] lines;

boolean makeMovie = false;
boolean saveTrialScrShots = false;

String today;

//debugging tools
//boolean showBorders, showField, showGrid;
boolean usePShape = false;
int frameWidth = 0;
boolean fullScr = true;

void settings() {
  selectInput("Please select a parameters file:", "selectParamsFile");
  while (lines == null) delay(100);
  
  int d = day();  int m = month();  int y = year(); int min = minute(); int h = hour(); 
  today = String.valueOf(y-2000)+String.format("%02d",m)+String.format("%02d",d);
  String now = String.format("%02d",h)+String.format("%02d",min);
  out_params = createWriter(today+"_"+now+"_params.log");
  out_trials = createWriter(today+"_"+now+"_trials.log");

  loadSettingsParams(lines);
  
  if (!fullScr) {
    if (fastRendering) size(scrWidthPx,scrHeightPx,P2D);
    else size(scrWidthPx,scrHeightPx);
    
  } else{
    if (fastRendering) fullScreen(P2D,monitor);
    else fullScreen(monitor);
  }
  
  if (!antiAlias) noSmooth();

}

void setup() {
  //default stim params  
  loadSetupParams(lines);
  
  preStimLen = (int) (preStimLenSec*FRAME_RATE);
  postStimLen = (int) (postStimLenSec*FRAME_RATE);
  trialLen = (int) (trialLenSec*FRAME_RATE);
  
  frameRate(FRAME_RATE);
  if (globalSeed < 0) globalSeed = (int) random(1000);
  randomSeed(globalSeed);

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
  periodFrameCount = 0;
  trialIndex = 0;
  totalTrials = nTrialBlocks*nStims*nDirs;
  
  //write header to trials log
  out_trials.println("Frame Time Period TrialNo Stimulus");
  
  start_time = -1;
  if (nStims > 0 && clientStartList != null) {
    for (int cl = 0; cl < clientStartList.size(); cl++)
      clientStartList.get(cl).send("",0);
  }
} 

void draw () {

  boolean endOfTrial = false;
  
  if (nStims == 0) quit();
  
  if (clientTimeStamp != null) {
    tStampCounter++;
    if (tStampCounter == tStampInterval) {//send cam packet every 6*1/60 s, or .1 s
      tStampCounter = 0;//reset counter
      int timer = int(System.currentTimeMillis() - start_time);
      clientTimeStamp.send("",timer);
    }
  }
  
  if (periodFrameCount == currentLen) {//if current period ended
   endOfTrial = updateState();
    if (endOfTrial && saveTrialScrShots) {
      String fname = stim.getSimpleStimInfo();
      saveFrame(String.format("trialScrShots/%s/%s_%02d.png",fname,fname,stim.getScrShotNo())); 
    }
  }
  
  if (periodFrameCount == 0) { //if starting a period

    if (preStim || (trial && preStimLen == 0)) {//if about to load a new stim
      
      if (stim != null) stim.cleanUp();

      //check if new trial block
      if ((trialIndex % (nStims*nDirs)) == 0) {
        if (trialIndex == totalTrials) {
          //Send "End" trigger
          if (clientEndList != null) {
            for (int cl = 0; cl < clientEndList.size(); cl++)
              clientEndList.get(cl).send("",0);//0 = End msg is fixed
          }
          quit();
        }
     
        //else, reshuffle stim dirs for this new block
        for (int i = 0; i < nStims; i++) {
          stims[i].shuffleDirs(this);
        }
        
      }
      //reshuffle stims
      if ((trialIndex % nStims) == 0) {
        stimIdxs.shuffle(this);
      }         
       

      //load new stim
      stim = stims[stimIdxs.get(trialIndex % nStims)];
      stim.init();
    }
  }

  if (trial) stim.run(true);
  else stim.run(false);
  
  if (makeMovie) saveFrame("movieframes/######.png");
  
  if (endOfTrial && clientTrialEnd != null) clientTrialEnd.send("",0);

  if (periodFrameCount == 0) {//log trial immediately before end of draw() (i.e. when graphics are displayed)
    
    if (start_time < 0) start_time = System.currentTimeMillis();
    timestamp = System.currentTimeMillis() - start_time;
    
    if (trial) {
      String stimInfo = stim.getStimInfo();      
      out_trials.println(String.format("%d %d TRIAL %d %s",frameCount,timestamp,trialIndex+1,stimInfo));
      if (clientTrialStart != null) clientTrialStart.send("",0);
    } else if (preStim) {
      //record start of preStim interval 
      out_trials.println(String.format("%d %d PRESTIM",frameCount,timestamp));            
    } else if (postStim) {
      //record start of postStim interval
      out_trials.println(String.format("%d %d POSTSTIM",frameCount,timestamp));
    }
  }
  
  periodFrameCount++;
  
  
  //stroke(0);
  //textSize(16);
  //text("Frame rate: " + int(frameRate), 10, 20);
  
  
}

boolean updateState() {
 
  periodFrameCount = 0;
  boolean trialEnded = false;
  
  if (preStim) {   
    preStim = false;
    trial = true;
    currentLen = trialLen;
    
  } else if (postStim) {    
    postStim = false;
    trialIndex++;
    if (preStimLen == 0) {     
      trial = true;
      currentLen = trialLen;
    } else {           
      preStim = true;
      currentLen = preStimLen;
    }
    
  } else {
    //assert trial == true;
    trialEnded = true;
    if (postStimLen == 0) {
      trialIndex++;
      if (preStimLen > 0) {
        trial = false;
        preStim = true;
        currentLen = preStimLen;
      }
      //else keep it as it is!
            
    } else {    
      trial = false;
      postStim = true;
      currentLen = postStimLen;
    }
  }
  return trialEnded;
}


void selectParamsFile(final File f) {
  if (f == null || f.isDirectory()) {
    println("Window was closed or user hit cancel.");
    System.exit(0);
  }
  final String paramsPath = f.getPath();
  lines = loadStrings(paramsPath);
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
        case "fullScreen": fullScr = loader.loadBool(list[1],list[0],out_params); break;
        case "fastRendering": fastRendering = loader.loadBool(list[1],list[0],out_params); break;
        case "antiAlias": antiAlias = loader.loadBool(list[1],list[0],out_params); break;
        case "frameRate": FRAME_RATE = loader.loadInt(list[1],list[0],out_params); break;
        case "saveMovieFrames": makeMovie = loader.loadBool(list[1],list[0],out_params); break;
        case "saveTrialScrShots": saveTrialScrShots = loader.loadBool(list[1],list[0],out_params); break;
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
        case "randomSeed": globalSeed = loader.loadInt(list[1],list[0],out_params); break;
        case "nTrialBlocks": nTrialBlocks = loader.loadInt(list[1],list[0],out_params); break;
        case "scrDistCm": scrDistCm = loader.loadFloat(list[1],list[0],out_params); break;
        case "scrWidthCm": scrWidthCm = loader.loadFloat(list[1],list[0],out_params); break;
        case "trialLenSec": trialLenSec = loader.loadFloat(list[1],list[0],out_params); break;
        case "preStimLenSec": preStimLenSec = loader.loadFloat(list[1],list[0],out_params); break;
        case "postStimLenSec": postStimLenSec = loader.loadFloat(list[1],list[0],out_params); break;
        case "clientStart":
          if (!makeMovie) {//preventing accidentally leaving network info on when making movie 
            if (clientStartList == null) clientStartList = new ArrayList<Client>();
            clientStartList.add(new Client(list[1]));
            loader.loadClient(clientStartList.get(clientStartList.size()-1),list,list[0],out_params);
          } break;
        case "clientEnd":
          if (!makeMovie) {
            if (clientEndList == null) clientEndList = new ArrayList<Client>();
            clientEndList.add(new Client(list[1]));
            loader.loadClient(clientEndList.get(clientEndList.size()-1),list,list[0],out_params);
          } break;
        case "clientTrialStart":
          if (!makeMovie) {
            clientTrialStart = new Client(list[1]);
            loader.loadClient(clientTrialStart,list,list[0],out_params);
          } break;
        case "clientTrialEnd":
          if (!makeMovie) {
            clientTrialEnd = new Client(list[1]);
            loader.loadClient(clientTrialEnd,list,list[0],out_params);
          } break;
        case "clientTimeStamp":
          if (!makeMovie) {
            clientTimeStamp = new Client(list[1]);
            tStampInterval = max(1,int(FRAME_RATE * loader.loadClientInterval(clientTimeStamp,list,list[0],out_params)));
          } break;       
         default: break;
      }
    }
  }
}

void quit() {
  //close output file
  out_trials.flush();
  out_trials.close();
  //end movie
  noLoop();
  exit();
}

void keyPressed() {
  if (key == ESC){
    if (clientEndList != null) {
      for (int cl = 0; cl < clientEndList.size(); cl++)
        clientEndList.get(cl).send("",0);
    }
    quit();    
  }
}
