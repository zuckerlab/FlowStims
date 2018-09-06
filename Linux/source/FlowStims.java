import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.net.*; 
import java.nio.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class FlowStims extends PApplet {

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
float preStimLenSec = 1.f;
float postStimLenSec = 1;
float trialLenSec = 2.f;
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
boolean fullScr = false;

public void settings() {
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

public void setup() {
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
  float scrWidthDeg = 2*atan(.5f*scrWidthCm/scrDistCm)*180/PI;
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

public void draw () {

  boolean endOfTrial = false;
  
  if (nStims == 0) quit();
  
  if (clientTimeStamp != null) {
    tStampCounter++;
    if (tStampCounter == tStampInterval) {//send cam packet every 6*1/60 s, or .1 s
      tStampCounter = 0;//reset counter
      int timer = PApplet.parseInt(System.currentTimeMillis() - start_time);
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

public boolean updateState() {
 
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


public void selectParamsFile(final File f) {
  if (f == null || f.isDirectory()) {
    println("Window was closed or user hit cancel.");
    System.exit(0);
  }
  final String paramsPath = f.getPath();
  lines = loadStrings(paramsPath);
}

public void loadSettingsParams(String[] lines) {
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

public void loadSetupParams(String[] lines) {
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
            tStampInterval = max(1,PApplet.parseInt(FRAME_RATE * loader.loadClientInterval(clientTimeStamp,list,list[0],out_params)));
          } break;       
         default: break;
      }
    }
  }
}

public void quit() {
  //close output file
  out_trials.flush();
  out_trials.close();
  //end movie
  noLoop();
  exit();
}

public void keyPressed() {
  if (key == ESC){
    if (clientEndList != null) {
      for (int cl = 0; cl < clientEndList.size(); cl++)
        clientEndList.get(cl).send("",0);
    }
    quit();    
  }
}



class Client {
  private DatagramSocket socket;
  private InetAddress host;
  private int port;
  private DatagramPacket packet;
  private byte[] data;
  private int sendType = 1;
  private String encoding = "UTF-8";
  private boolean appendNewLineChar = false;   
  private int intMsg;
  private String strMsg;
  private boolean fixedMsg = false;

  Client(String hostname) { 

    try {
      host = InetAddress.getByName(hostname);
      socket = new DatagramSocket() ;
    } 
    catch( Exception e )
    {
      System.out.println( e ) ;
    }
  }

  public void setPort(int port_) {
    port = port_;
  }

  public void setSendType(int sendType_) {
    sendType = sendType_;
  }

  public void setFixedIntMsg(int number) {
    intMsg = number;
    fixedMsg = true;
  }

  public void setFixedStrMsg(String msg) {
    strMsg = msg;
    fixedMsg = true;
  }

  public void setEncoding(String encoding_) {
    encoding = encoding_;
  }

  public void setAddNewLine(boolean addnewline) {
    appendNewLineChar = addnewline;
  }

  /*send a string or int msg (the other arg is ignored)*/
  public void send(String str_, int int_) {
    switch (sendType) {
    case 1:
      if (fixedMsg) send1(strMsg);
      else send1(str_);
      break;
    case 2:
      if (fixedMsg) send2(strMsg);
      else send2(str_);
      break;
    case 3:
      if (fixedMsg) send3(intMsg);
      else send3(int_);
      break;
    case 4:
      if (fixedMsg) send4(intMsg);
      else send4(int_);
      break;
    case 5:
      send5();
      break;
    default: 
      break;
    }
  }

  /*send string*/
  public void send1(String msg) {
    if (appendNewLineChar)
      msg += '\n';

    try {
      data = msg.getBytes(encoding);
    } 
    catch ( Exception e) {
      System.out.println("Client.send : Unsupported character set");
    }
    packet = new DatagramPacket( data, data.length, host, port ) ;
    sendPacket();
  }

  /*send integer from string (e.g. string read from params file)*/
  public void send2(String msg) {
    int number = Integer.parseInt(msg);
    //send single uint8 byte*
    byte data[] = new byte[1];
    data[0] = (byte) (number & 0xFF);
    packet = new DatagramPacket( data, data.length, host, port ) ;
    sendPacket();  
    //send 4-byte int
    //byte[] data = new byte[] {
    //  (byte) (number >>> 24), 
    //  (byte) (number >>> 16), 
    //  (byte) (number >>> 8), 
    //  (byte) (number)};
    //packet = new DatagramPacket( data, data.length, host, port ) ;
    //sendPacket();
  }

  /*send integer from int*/
  public void send3(int number) {
    byte[] data = new byte[] {
      (byte) (number >>> 24), 
      (byte) (number >>> 16), 
      (byte) (number >>> 8), 
      (byte) (number)};
    packet = new DatagramPacket( data, data.length, host, port ) ;
    sendPacket();
  }

  /*send string from int*/
  public void send4(int number) {      
    send1(String.valueOf(number));
  }
  
  /*append date & time to fixed msg prefix*/
  public void send5() {
    int sec = second(); int min = minute(); int h = hour();
    String now = String.format("%s_%s_%02d%02d%02d",strMsg,today,h,min,sec);
    send1(now);
  }

  public void sendPacket() {
    // Send it
    try {       
      socket.send( packet ) ;
    }  
    catch( Exception e ) {
      println( e ) ;
    }
  }

  public void close() {
    socket.close();
  }
}
class Flow implements Stim {
  
  IntList dirs;
  //float initSpd;
  int dirCounter;
  
  ArrayList<Boid> boids;
  DoublyLinkedList[] binGrid;
  int[] myBorders, nbrArray;
  int binSize, binrows, bincols, xLen, yLen, tileSize;
  int pattern, D, boidColor, boidAlpha, bgColor, grayColor;
  float xHalfLen, yHalfLen, baseSep, posStd, dirStd, radius, origDdeg;
  int sepFreq, fadeRate;
  float sepRadius, sepFrstTerm, sepScndTerm, sepThrdTerm;
  FlowField flow;

  
  float meanTheta, maxSpeed, tempFreq, maxForce, sepWeight;
  int meanThetaDeg;
  PVector v0;
  
  boolean wiggle, move, separate, follow;
  PShape boid;
  
  int mySeed;
  int nInfo = -1;


  Flow(int myseed, int tilesize, float dirstd, float basesep, int sepPx, float posstd, 
        int ndots, int diam, float diamdeg, int boidcolor, int bgcolor, int gray, float maxsp, float tempfreq,
        boolean wiggle_, float maxforce, float sepweight, int faderate) {

    dirs = new IntList();
    for (int dr = 0; dr < nDirs; dr++) {
      dirs.append(round(dr*(360.f/nDirs)) + dirDegShift);
    }



    mySeed = myseed;
    tileSize = tilesize;
    dirStd = dirstd;
    
    nbrArray = new int[9];//single array shared by all boids

    pattern = ndots;
    
    origDdeg = diamdeg;
    D = diam;
    radius = D/2.f;
    
    boidColor = boidcolor;
    bgColor = bgcolor;
    grayColor = gray;
    
    if (gray == -1) {//if grayscr set to auto
      float spacing = PApplet.parseFloat(sepPx)/diam;
      float dotArea = width*height*PI/(spacing*spacing*4);
      float bgArea = width*height - dotArea;
      //println("pct dotArea",dotArea/bgArea);
      float avgColor = (dotArea*boidColor+bgArea*bgColor)/( width*height );
      grayColor = PApplet.parseInt(avgColor);
    }   

    wiggle = wiggle_;
    maxForce = maxforce;
    sepWeight = sepweight;
    fadeRate = faderate;
    posStd = posstd;
    
    if (posStd > 0) setWiggle(true);//if posStd > 0 we want scrambled boids, so turn wiggle on during pre-trial
    
    if (usePShape) createBoidShape();
    
    move = true;
    maxSpeed = maxsp;
    tempFreq = tempfreq;
    
    if (tempFreq == 0) {
      //allow boids to conform to flowfield before trial starts
      wiggle = false;
      setWiggle(true);
      maxSpeed = 3;
    }
    
    sepRadius = sepPx+1;//the +1 takes care of fractional pixels
    

    sepFreq = 5;

    binSize = sepPx;
    baseSep = basesep;

    binrows = myheight/binSize + 1;
    bincols = mywidth/binSize + 1;


    
  }
  
  public void shuffleDirs(PApplet main) {
    dirs.shuffle(main);  
  }
  
  public void init() {
    
    int dirdeg = dirs.get(dirCounter);
    dirCounter = (dirCounter + 1) % nDirs;

    ///direction-related variables
    float meantheta = dirdeg*(PI/180.f);
    meanThetaDeg = dirdeg;
    meanTheta = -meantheta;
    
    //eliminate flickering of patterns > 1 along borders when two elts don't fit into the same bin
    if (meantheta == 0 || meantheta == PI)
      if (binrows*binSize - myheight < pattern*D) binrows++;

    if (meantheta == HALF_PI || meantheta == 3*HALF_PI)
      if (bincols*binSize - mywidth < pattern*D) bincols++;


    int borderx = frameWidth + binSize*(bincols);
    int bordery = frameWidth + binSize*(binrows);

    myBorders = new int[4];
    myBorders[0] = frameWidth; myBorders[1] = borderx;
    myBorders[2] = frameWidth; myBorders[3] = bordery;
    xLen = myBorders[1] - myBorders[0];
    xHalfLen = xLen/2.f;
    yLen = myBorders[3] - myBorders[2];
    yHalfLen = yLen/2.f;
    
    v0 = PVector.fromAngle(meanTheta);
    v0.mult(maxSpeed);
    //coeffs for ellipse equation (separation perimeter)
    float a = sq(sepRadius);
    if (pattern > 1) {
      float b = sq(sepRadius+radius*(pattern-1));
      float sintheta = sin(meanTheta);
      float costheta = cos(meanTheta);
      sepFrstTerm = sq(costheta)/a + sq(sintheta)/b;
      sepScndTerm = 2*costheta*sintheta*(1.f/a - 1.f/b);
      sepThrdTerm = sq(sintheta)/a + sq(costheta)/b;
    } else {
      sepFrstTerm = 1/a;
      sepScndTerm = 0;
      sepThrdTerm = sepFrstTerm;
    }    
    ///
    
    if (mySeed < 0) {
      globalSeed += 1000;
      randomSeed(globalSeed);
    } else randomSeed(mySeed);
    if (dirStd > 0) flow = new FlowField(tileSize, meanTheta, dirStd);
    binGrid = new DoublyLinkedList[binrows*bincols];
    for (int i = 0; i < binrows*bincols; i++) {
        binGrid[i] = new DoublyLinkedList();
    }
    boids = new ArrayList<Boid>();
    //int borderx = frameWidth + binSize*(bincols);
    //int bordery = frameWidth + binSize*(binrows);
    int c = 0;
    for (int i = myBorders[2]; i < bordery; i += binSize) {
      for (int j = myBorders[0]; j < borderx; j += binSize) {
        boids.add(new Boid(j+posStd*binSize*randomGaussian(),i+posStd*binSize*randomGaussian(),c,c % sepFreq));
        c++;
      }
    }
  }
  
  public void cleanUp() {
    boidAlpha = 0;
    flow = null;
    binGrid = null;
    boids = null;
  }
  
  public void setWiggle(boolean state) {
    separate = state;
    follow = state;
  }
  //create a Freeze method to set move to false?

  public void run(boolean show) {
    
    if (show) {
      boidAlpha = min(255,boidAlpha + fadeRate);
      setWiggle(wiggle);
    } else boidAlpha = max(0,boidAlpha - fadeRate);

    float alphafrac = boidAlpha/255.f;
    background(bgColor*alphafrac + grayColor*(1.f - alphafrac));

    for (Boid b : boids) {         
      b.run();        
    }            
  }
  
  public void createBoidShape() {
  
    fill(boidColor);
    noStroke();
    ellipseMode(CENTER);

    if (pattern == 1) {
      boid = createShape(ELLIPSE,0,0,D,D);      

    } else {
      boid = createShape(GROUP);
      PShape dot;
      for (int i = -(pattern-1); i < pattern; i+=2) {
        dot = createShape(ELLIPSE, i*D/2, 0, D, D);
        boid.addChild(dot);
      }        
    }
  }
  
  public void drawBinGrid() {//for debugging purposes
    stroke(255,255,0,128);

    for (int i = myBorders[0]; i <= myBorders[1]; i += binSize)
      line(i,myBorders[2],i,myBorders[3]);

    for (int i = myBorders[2]; i <= myBorders[3]; i += binSize)
      line(myBorders[0],i,myBorders[1],i);
  }
  
  public void drawField() {
    if (flow != null) flow.drawField();      
  }
  
  public String getStimInfo() {
    String stiminfo = String.format(
        "stim=FLOW nDots=%d dir=%d tfreq=%.1f diam=%.2f spac=%.2f dotLvl=%d bgLvl=%d interLvl=%d",
        pattern, meanThetaDeg, tempFreq, origDdeg, baseSep, boidColor, bgColor, grayColor);
    return stiminfo;
  }
  
  public String getSimpleStimInfo() {
    nInfo++;
    return String.format("%ddots_%d_D%.2f_sp%.1f_c%d",pattern, meanThetaDeg, origDdeg, baseSep, boidColor);
  }
  
  public int getScrShotNo() {
    return nInfo;
  }

  /*
  The Boid and FlowField classes below are an implementation of Reynold's boid with steering behavior:
  -Reynolds, C. W. 1987. Flocks, Herds, and Schools: A Distributed Behavioral Model, 
    in Computer Graphics, 21(4) (SIGGRAPH '87 Conference Proceedings). Pages 25-34.
  -Reynolds, C. W. 1999. Steering Behaviors For Autonomous Characters, 
    in the proceedings of Game Developers Conference 1999 held in San Jose, California. Pages 763-782.
  Parts of the code in these classes were adapted from the book:
  -Shiffman, Daniel. 2012. The Nature of Code. Edited by Shannon Fry. 2012 ed. New York: Daniel Shiffman.
  */

  
  class Boid {
  
    PVector position;
    PVector velocity;
    PVector acceleration;
    float theta;
    PVector desired;
    PVector sep;
    
    int sepCounter;
    
    Node node;
    int bin_x, bin_y;
  
    Boid(float x, float y, int id, int sepcount) {
  
      position = new PVector(x, y);
      //make sure it is created inside the available area
      while (x > myBorders[1]-pattern*radius) x -= xLen;
      while (x < myBorders[0]-pattern*radius) x += xLen;
      while (y > myBorders[3]-pattern*radius) y -= yLen;
      while (y < myBorders[2]-pattern*radius) y += yLen;  
      
      node = new Node();
      node.item = this;
      node.id = id;
      
      sepCounter = sepcount;
      
      binGrid[getBinIndex()].add(node);
      
      acceleration = new PVector(0, 0);
      theta = meanTheta;
      velocity = v0.copy();
      velocity.setMag(maxSpeed);
      //desired = velocity.copy();
      //desired.setMag(maxForce);
      desired = new PVector(0,0);
      sep = new PVector(0, 0);
  
    }
   
    
    public int getBinIndex() {
      bin_x = (int) (position.x-myBorders[0])/binSize;
      bin_y = (int) (position.y-myBorders[2])/binSize;
      
      return bin_y*bincols + bin_x;
    }
    public void updateBinNeighbors() {
      
      int rows_above = bin_y*bincols;
      nbrArray[0] = rows_above + bin_x;//CENTER
      //LEFT
      if (bin_x == 0) nbrArray[1] = rows_above + bincols - 1;
      else nbrArray[1] = nbrArray[0] - 1;
      //RIGHT
      if (bin_x == bincols-1) nbrArray[2] = rows_above;
      else nbrArray[2] = nbrArray[0] + 1;    
      
      //TOP
      if (bin_y == 0) {
        int add_ = bincols*binrows - bincols;
        nbrArray[3]  = nbrArray[0] + add_;//TOP
        if (bin_x == 0) {
          nbrArray[4] = -1; //top-left corner
          nbrArray[5] = nbrArray[2] + add_;//TOP RIGHT
        } else if (bin_x == bincols-1) {
          nbrArray[4] = nbrArray[1] + add_;//TOP LEFT
          nbrArray[5] = -1; //top-right corner 
        } else {
          nbrArray[4] = nbrArray[1] + add_;//TOP LEFT  
          nbrArray[5] = nbrArray[2] + add_;//TOP RIGHT       
        }
      } else {
        nbrArray[3] = nbrArray[0] - bincols;//TOP
        nbrArray[4] = nbrArray[1] - bincols;//TOP LEFT
        nbrArray[5] = nbrArray[2] - bincols;//TOP RIGHT
      }
      
      //BOTTOM
      if (bin_y == binrows-1) {
        int add_ = bincols - bincols*binrows;
        nbrArray[6] = nbrArray[0] + add_;//BOTTOM
        if (bin_x == 0) {
          nbrArray[7] = -1; //bottom-left corner
          nbrArray[8] = nbrArray[2] + add_;//BOTTOM RIGHT
        } else if (bin_x == bincols-1) {
          nbrArray[7] = nbrArray[1] + add_;//BOTTOM LEFT
          nbrArray[8] = -1; //bottom-right corner        
        } else {
          nbrArray[7] = nbrArray[1] + add_;//BOTTOM LEFT
          nbrArray[8] = nbrArray[2] + add_;//BOTTOM RIGHT        
        }
      } else {
        nbrArray[6]  = nbrArray[0] + bincols;//BOTTOM
        nbrArray[7] = nbrArray[1] + bincols;//BOTTOM LEFT
        nbrArray[8] = nbrArray[2] + bincols;//BOTTOM RIGHT
      }         
      
    }
    
    public void run() {
      
      int bin_idx = getBinIndex();
  
      updateBinNeighbors();
      
      if (move) {
        flock();
        update();     
        borders();
    
        //update bin after moving
        int new_bin_idx = getBinIndex();  
        if (new_bin_idx != bin_idx) {
          binGrid[bin_idx].remove(node);
          binGrid[new_bin_idx].add(node);
          
        } 
      }
      if (usePShape) drawBoidShape();
      else drawBoid();
      
      
    }
  
    public PVector followField() {
      //update theta: lookup direction at that position in the flow field
      theta = flow.getDirection(position);     
  
      desired = PVector.fromAngle(theta);//unit vector
      desired.mult(maxSpeed);
      //steering force = desired - velocity
      desired.sub(velocity);    
      desired.limit(maxForce);    
      
      return desired;
  
    }
    
    public void flock() {
      
      if (!separate && !follow) {//noWiggle
        if (tempFreq == 0) {
          velocity.set(0,0);
          desired.set(0,0);
        } else {
          velocity.set(v0);
          desired.set(v0);
          desired.limit(maxForce);
          acceleration.add(desired);
          theta = meanTheta;
        }
        
      } else {
        if (separate && sepWeight > 0) {
          sepCounter = (sepCounter + 1) % sepFreq;
          if (sepCounter == 0) { //separate only once every sepFreq frames   
            sep = separate();
            sep.mult(sepWeight);        
          }
          acceleration.add(sep);
        }
        if (follow && flow != null) {
          desired = followField();
          acceleration.add(desired);  
        } else { //allows boids to still separate without any flow field
          desired.set(v0);
          desired.sub(velocity);    
          desired.limit(maxForce); 
          acceleration.add(desired);      
        }
        
        //update theta for a smoother change in heading when patt > 1
        if (pattern > 1) theta = PVector.add(velocity,desired).heading();
      }
    }
  
    //update boid position
    public void update() {
  
      velocity.add(acceleration);
      velocity.limit(maxSpeed);
      //if (node.id == n1) print(velocity.y," ");
      position.add(velocity);
      
      //reset acceleration after each cycle
      acceleration.set(0,0);
    }
    
    // wraparound borders
    public void borders() {
      int factor = pattern;
      if (position.x < myBorders[0]-factor*radius) position.x += xLen;
      if (position.y < myBorders[2]-factor*radius) position.y += yLen;
      if (position.x > myBorders[1]-factor*radius) position.x -= xLen;
      if (position.y > myBorders[3]-factor*radius) position.y -= yLen;
    }
    
    public void drawBoidShape() {//when using PShape rendering
      pushMatrix();
      translate(position.x,position.y);
      if (pattern > 1)
        rotate(theta - HALF_PI);
      shape(boid);
      popMatrix();    
    }
  
    public void drawBoid() {
      
      fill(boidColor, boidAlpha);
      noStroke();
  
      if (pattern == 1) {
        ellipseMode(CENTER);
        ellipse(position.x,position.y,D,D);         
  
      } else {
        pushMatrix();
        translate(position.x, position.y);
        rotate(theta - HALF_PI);
        if (D > 2) {
          ellipseMode(CENTER); 
          for (int i = -(pattern-1); i < pattern; i+=2) {
            ellipse(i*radius,0,D,D);
          }
        } else {//if radius <= 1, draw a single rectangle instead of multiple dots
          rectMode(CENTER);
          rect(0,0,pattern*D,D);
        }      
        popMatrix();          
      }      
    }
    
    //check for nearby boids
    public PVector separate() {
  
      float dx, dy, d2;
      PVector steer = new PVector(0,0);
      PVector diff = new PVector(0,0);
  
      Node other;
  
      for (int nbr_idx : nbrArray) {
  
        if (nbr_idx == -1) continue;
          
        binGrid[nbr_idx].resetIterator();
        
        other = binGrid[nbr_idx].getNext();  
        
        while (other != null) {
  
          if (other != node) {
  
            dx = position.x - other.item.position.x;
  
            if (abs(dx) > xHalfLen) {//dx = xLen - dx;
              if (dx < 0) dx += xLen;
              else dx -= xLen;           
            }
  
            dy = position.y - other.item.position.y;
  
            if (abs(dy) > yHalfLen) {//dy = yLen - dy;
              if (dy < 0) dy += yLen;
              else dy -= yLen;          
            }

            d2 = sepFrstTerm*dx*dx + sepScndTerm*dx*dy + sepThrdTerm*dy*dy;
            
            if (d2 > 0 && d2 < 1) {
              
              diff.set(dx,dy);
              diff.setMag(1.f/d2);
              steer.add(diff);

            }
          }
          other = binGrid[nbr_idx].getNext();
        }
      }
  
      //as long as the vector is greater than 0 
      if (steer.magSq() > 0) {
  
        //steering force = desired - velocity
        steer.normalize();
        steer.mult(maxSpeed);
        steer.sub(velocity);
        steer.limit(maxForce);  
      }      
      return steer;
    }
  }
  
  class FlowField {
    
    float mean;
    float stdev;
  
    float[][] field;//array containing directions of each tile
    int cols, rows; 
    int tileSize; //side of each square tile of the flow field
  
    FlowField(int tilesize, float mu, float std) {
      mean = mu;
      stdev = std;
      tileSize = tilesize;
      // get number of columns and rows
      cols = ceil(mywidth/PApplet.parseFloat(tileSize));
      rows = ceil(myheight/PApplet.parseFloat(tileSize));
      field = new float[cols][rows];
  
      for (int i = 0; i < cols; i++) {
        for (int j = 0; j < rows; j++) {
            field[i][j] = mean + stdev*randomGaussian();
            //print(field[i][j]," ");
        }
      }
      //println();
    }
    
    public float getDirection(PVector pos) {
      int column = (int) constrain((pos.x-frameWidth)/tileSize, 0, cols-1);
      int row = (int) constrain((pos.y-frameWidth)/tileSize, 0, rows-1);
      return field[column][row];
    }
    
    public void drawField() {
      //draw grid
      stroke(0,255,0,128);
  
      for (int i = 0; i < cols+1; i++)
        line(frameWidth+i*tileSize, frameWidth, frameWidth+i*tileSize, frameWidth+rows*tileSize);
      
      for (int i = 0; i < rows+1; i++)
        line(frameWidth, frameWidth+i*tileSize, frameWidth+cols*tileSize, frameWidth+i*tileSize);
      
      
      //draw direction "arrows"
      float x, y, dir, cosdir, sindir;
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
          x = frameWidth + j*tileSize + tileSize/2.f;
          y = frameWidth + i*tileSize + tileSize/2.f;
          dir = field[j][i];
          cosdir = cos(dir); sindir = sin(dir);
          line(x - cosdir*tileSize/4.f, y - sindir*tileSize/4.f,
              x + cosdir*tileSize/4.f, y + sindir*tileSize/4.f);                          
        }
      }
    }
  }

  class DoublyLinkedList {
    int n;        
    Node head;     
    Node last;  
    Node curr;

    public DoublyLinkedList() {
      //circular DL list
      head = new Node();
      head.id = -2;
      head.next = head;
      head.prev = head;
      last = head;

    }

    // add the item to the list
    public void add(Node x) {
        x.next = head;
        x.prev = last;
        last.next = x;
        head.prev = x;
        last = x;          
        n++;
    }
    
    public void remove(Node x) {
      Node nextNode = x.next;
      Node prevNode = x.prev;
      //println("Removing",x.id," - next:",nextNode.id,", prev:",prevNode.id);
      if (last == x) {
        last = prevNode;
        //println("  new last:",prevNode.id,last.id);
      }
      prevNode.next = nextNode;
      nextNode.prev = prevNode;
      //println("  ",prevNode.id,"<->",nextNode.id);
      n--;
    }
    
    public void resetIterator() {
      curr = head;
    }
    
    public Node getNext() {
      if (n == 0) return null;
      curr = curr.next;
      if (curr == head) return null;  
      return curr;
    }

    public int printout() {
      Node x = head.next;
      while (x != head) {
          print(x.id,"..");
          x = x.next;
      }
      println("Done",n);
      return n;        
    }   
  }
  
  //linked list proxy node
  class Node {
    Boid item = null;
    int id = 0;
    Node next = null;
    Node prev = null;
  }
}
class Grating implements Stim {
  
  IntList dirs;
  float initSpd;
  int dirCounter;

  int dirDegs, direction, phase, fadeRate;
  boolean randPhase;
  float start, deltaX, deltaXspac, period;
  int barWidth, spaceWidth, bgColor, fgColor, grayColor, stimAlpha;
  float theta, speed, phaseFrac, tempFreq, widthDeg;
  

  int myheight = height;
  int mywidth = width;

  PVector p0, p1, p2, p3;
  float[] vals;
  
  int nInfo = -1;

  Grating(float tempfreq, int fg, int bg, int gray, int barwid, float widdeg, float spd, boolean randphase, int faderate) {
    
    dirs = new IntList();
    for (int dr = 0; dr < nDirs; dr++) {
      dirs.append(round(dr*(360.f/nDirs)) + dirDegShift);
    }   
    
    p0 = new PVector(0, 0);
    p1 = new PVector(0, 0);
    p2 = new PVector(0, 0);
    p3 = new PVector(0, 0);

    initSpd = spd;
    
    tempFreq = tempfreq;
    widthDeg = widdeg;
    barWidth = barwid;
    spaceWidth = barwid;

    randPhase = randphase;
    fadeRate = faderate;

    fgColor = fg;
    bgColor = bg;
    grayColor = gray;
    
    if (gray == -1) {//if grayscr set to auto
      float avgColor = (.5f*fgColor+.5f*bgColor);
      grayColor = PApplet.parseInt(avgColor);
    }

  }
  
  public void shuffleDirs(PApplet main) {
    dirs.shuffle(main);  
  }

  public void init() {
    
    int dir = dirs.get(dirCounter);
    dirCounter = (dirCounter + 1) % nDirs;
    dirDegs = dir; 
    
    ///direction-related variables
    int spdsign = 1;
    if (dir > 90 && dir < 270) {
      spdsign = -1;
      if (dir < 180)  dir += 180;
      else dir -= 180;
    }

    direction = dir;
    theta = radians(direction);
    if (direction == 90 || direction == 270) {
      speed = initSpd;
      if (direction == 270) speed = -initSpd;
      deltaX = barWidth;
      deltaXspac = spaceWidth;
    } else {
      speed = spdsign*initSpd/cos(theta);
      deltaX = round(barWidth/cos(theta));
      deltaXspac = round(spaceWidth/cos(theta));
    }
    period = deltaX + deltaXspac;
    ///
    if (randPhase) {
      phase = (int) random(barWidth+spaceWidth);
      phaseFrac = PApplet.parseFloat(phase)/(barWidth+spaceWidth);
    } else {
      phase = 0;
      phaseFrac = 0;
    }
    start = phase;
    createArrays();
  }

  public void createArrays() {

    int size;
    if (direction == 90 || direction == 270) {
      p0.x = 0.f; 
      p1.x = 0.f;
      p2.x = mywidth; 
      p3.x = mywidth;
      size = (int) ceil((myheight+period  + PApplet.parseInt(period))/period);
      vals = new float[size];
      int i = 0;
      for (int y = -PApplet.parseInt(period); y < myheight+period; y += period) {
        vals[i] = y;
        i++;
      }
    } else if (direction == 0 || direction == 180) {
      p0.y = 0.f;
      p1.y = 0.f;
      p3.x = 0;
      p3.y = myheight/cos(theta);
      p3.rotate(theta);
      p2.y = p3.y;

      size = (int) ceil((mywidth+period+period)/period);
      vals = new float[size];
      int i = 0;
      for (int x = -PApplet.parseInt(period); x < mywidth+period; x += period) {
        vals[i] = x;
        i++;
      }
    } else {
      p0.y = 0.f; 
      p1.y = 0.f;
      p3.x = 0;
      p3.y = myheight/cos(theta);

      p3.rotate(theta);
      p2.y = p3.y;

      size = PApplet.parseInt((mywidth+myheight*abs(tan(theta))+period  + myheight*abs(tan(theta))+period)/period) + 1;

      vals = new float[size];
      int i = 0;

      for (int x = -PApplet.parseInt(myheight*abs(tan(theta))+period); x < mywidth+myheight*abs(tan(theta))+period; x += period) {
        vals[i] = x;
        i++;
      }
    }
  }
  
  public void cleanUp() {
    stimAlpha = 0;
    vals = null;
  }

  public void drawGrating() {

    noStroke();
    fill(fgColor, stimAlpha);

    float y, x, p3x;

    for (int i = 0; i < vals.length; i++) {
      if (direction == 90 || direction == 270) {
        y = vals[i];
        p0.y = start + y;
        p1.y = p0.y + deltaX;

        p2.y = p1.y;
        p3.y = p0.y;

        quad(p0.x, myheight-p0.y, p1.x, myheight-p1.y, p2.x, myheight-p2.y, p3.x, myheight-p3.y);
      } else {
        x = vals[i];
        p0.x = start+x;
        p1.x = start+x+deltaX;

        p3x = p3.x + p0.x;

        p2.x = p3.x + p1.x;

        quad(p0.x, myheight-p0.y, p1.x, myheight-p1.y, p2.x, myheight-p2.y, p3x, myheight-p3.y);
      }
    }
  }

  public void run(boolean show) {
    if (show) stimAlpha = min(255, stimAlpha + fadeRate);
    else stimAlpha = max(0, stimAlpha - fadeRate);

    float alphafrac = stimAlpha/255.f;
    background(bgColor*alphafrac + grayColor*(1.f - alphafrac));

    drawGrating();

    start = (start + speed) % period;
  }
  
  public String getStimInfo() {
    String stiminfo = String.format(
        "stim=GRAT dir=%d tfreq=%.1f width=%.2f fgLvl=%d bgLvl=%d interLvl=%d phase=%.2f",
        dirDegs, tempFreq, widthDeg, bgColor, fgColor, grayColor, phaseFrac);
   return stiminfo;
  }
  
  public String getSimpleStimInfo() {
    nInfo++;
    return String.format("grats_%d_w%.2f",dirDegs, widthDeg);
  }
  
  public int getScrShotNo() {
    return nInfo;
  }
}
class Loader {

  public Stim[] loadStims(float pxPerDeg, String[] lines, PrintWriter out) {
    //default stim params
    nDirs = 1;

    int nFadeFrames = 3;

    FloatList tempFreqs = new FloatList(4.f);

    boolean useFlows = false, useGratings = false;

    //flows
    IntList nDots = new IntList(1, 3);
    IntList dotColors = new IntList(0, 255);
    IntList dotBgColors = new IntList(127, 127);
    IntList dotInterColors = dotBgColors;//new IntList(-1,-1);          
    FloatList dotDiamsDeg = new FloatList(1.5f);
    FloatList dotSeps = new FloatList(4.f);
    FloatList dotSpFqs = null;
    float dirStd = 0.08f;
    float posStd = 0.1f;  
    boolean wiggle = true;
    boolean fixRand = false;
    float sepWeight = 2.f;//use higher val if FRAME_RATE = 30
    float maxForce = .04f;
    float tileSizeFactor = 2.f;
    boolean equalArea = true;
    //grats
    FloatList gratWidthsDeg = new FloatList(12.5f, 3.125f);
    IntList gratColors = new IntList(64.f);//trick: use a float in constructor to create a single-elt list!
    IntList gratBgColors = new IntList(192.f);
    IntList gratInterColors = new IntList(127.f);
    boolean randPhase = false;


    for (int p = 0; p < lines.length; p++) {
      String line = lines[p];
      if (line.length() > 0 && line.charAt(0) != '#') {
        String[] list = split(line, ' ');
        if (list.length < 2) continue;
        switch(list[0]) {
        //ALL
          case "nDirs": nDirs = loadInt(list[1], list[0], out); break;
          case "dirDegShift": dirDegShift = loadInt(list[1], list[0], out); break;
          case "pxPerDeg": pxPerDeg = loadFloat(list[1], list[0], out); break;//overrides the calculated pxPerDeg
          case "nFadeFrames": nFadeFrames = loadInt(list[1], list[0], out); break;
          case "tempFreq": tempFreqs = loadMultiFloat(list, list[0], out, 0); break;
        //FLOWS
          case "useFlows": useFlows = loadBool(list[1], list[0], out); break;
          case "nDots": nDots = loadMultiInt(list, list[0], out, 0); break;
          case "equalArea": equalArea = loadBool(list[1], list[0], out); break;
          case "dotFgVal": dotColors = loadMultiInt(list, list[0], out, 0); break;
          case "->dotBgVal":
          case "dotBgVal": dotBgColors = loadMultiInt(list, list[0], out, dotColors.size()); break;
          case "->dotInterVal":
          case "dotInterVal": dotInterColors = loadMultiInt(list, list[0], out, dotColors.size()); break;
          case "dotDiamDeg": dotDiamsDeg = loadMultiFloat(list, list[0], out, 0); break;
          case "->dotSpacing":
          case "dotSpacing": dotSeps = loadMultiFloat(list, list[0], out, dotDiamsDeg.size()); break;
          case "->dotSpatFreq":
          case "dotSpatFreq": dotSpFqs = loadMultiFloat(list, list[0], out, dotDiamsDeg.size()); break;
          case "maxForce": maxForce = loadFloat(list[1], list[0], out); break;
          case "sepWeight": sepWeight = loadFloat(list[1], list[0], out); break;
          case "posStd": posStd = loadFloat(list[1], list[0], out); break;
          case "dirStd": dirStd = loadFloat(list[1], list[0], out); break;
          case "rigidTrans": wiggle = !loadBool(list[1], list[0], out); break;
          case "tileSize": tileSizeFactor = loadFloat(list[1], list[0], out); break;
          case "fixRandState": fixRand = loadBool(list[1], list[0], out); break;
        //GRATS
          case "useGratings": useGratings = loadBool(list[1], list[0], out); break;
          case "gratWidthDeg": gratWidthsDeg = loadMultiFloat(list, list[0], out, 0); break;
          case "gratFgVal": gratColors = loadMultiInt(list, list[0], out, 0); break;
          case "->gratBgVal":
          case "gratBgVal": gratBgColors = loadMultiInt(list, list[0], out, gratColors.size()); break;
          case "->gratInterVal":
          case "gratInterVal": gratInterColors = loadMultiInt(list, list[0], out, gratColors.size()); break;
          case "randGratPhase": randPhase = loadBool(list[1], list[0], out); break;
          default: break;
        }
      }
    }

    int fadeRate = ceil(255.f/max(1,nFadeFrames));
    if (posStd == 0) wiggle = false;


    int seed = -1;
    //if flows aren't rand, then most likely you dont want rand grating phase either
    if (fixRand && randPhase == true) randPhase = false;//(catching possibly common mistake when setting params file)

    int nStims = tempFreqs.size()*(PApplet.parseInt(useFlows)*(nDots.size()*dotColors.size()*dotDiamsDeg.size())
      + PApplet.parseInt(useGratings)*(gratWidthsDeg.size()*gratColors.size()));

    Stim[] stims = new Stim[nStims];

    float speed, diam_deg, sep, width_deg, tempfreq, spatfreq;
    int ndots, fgcolor, bgcolor, gray, diam_px, sep_px, tilesize, width_px, period_px;

    int s = 0;


      for (int sp = 0; sp < tempFreqs.size(); sp++) {
        tempfreq = tempFreqs.get(sp);

        //FLOWS
        if (useFlows) {

          for (int dt = 0; dt < nDots.size(); dt++) {
            ndots = nDots.get(dt);

            for (int sz = 0; sz < dotDiamsDeg.size(); sz++) {
              diam_deg = dotDiamsDeg.get(sz);
              diam_px = round(diam_deg*pxPerDeg);

              sep = dotSeps.get(sz);
              sep_px = round(sep*diam_px); //based on original diameter, i.e., before area correction
              tilesize = round(sep_px*tileSizeFactor);
              
              //compute corrected diam if equalArea is ON 
              if (ndots > 1 && equalArea) diam_px = round(diam_px/sqrt(ndots));

              //convert temp freqs to actual speeds (px/frame)
              if (dotSpFqs == null) period_px = sep_px;
              else {
                 spatfreq = dotSpFqs.get(sz);
                 period_px = round(pxPerDeg/spatfreq);
              }
              speed = tempfreq*period_px/FRAME_RATE;

              for (int cc = 0; cc < dotColors.size(); cc++) {
                fgcolor = dotColors.get(cc);
                bgcolor = dotBgColors.get(cc);
                gray = dotInterColors.get(cc);

                if (fixRand) seed = (int) random(1000);
                stims[s] = new Flow(seed, tilesize, dirStd, sep, sep_px, posStd, ndots, diam_px, diam_deg,
                      fgcolor, bgcolor, gray, speed, tempfreq, wiggle, maxForce, sepWeight, fadeRate);
                s++;
              }
              
            }
          }
        }
        //GRATS
        if (useGratings) {

          for (int sz = 0; sz < gratWidthsDeg.size(); sz++) {
            width_deg = gratWidthsDeg.get(sz);
            width_px = round(width_deg*pxPerDeg);
            period_px = 2*width_px;
            speed = tempfreq*period_px/FRAME_RATE;

            for (int cc = 0; cc < gratColors.size(); cc++) {
              fgcolor = gratColors.get(cc);
              bgcolor = gratBgColors.get(cc);
              gray = gratInterColors.get(cc);

              stims[s] = new Grating(tempfreq, fgcolor, bgcolor, gray, width_px, width_deg, speed, randPhase, fadeRate); 
              s++;
            }
          }
        }
      }
    

    return stims;
  }

  public float loadFloat(String p, String pname, PrintWriter out) {
    float myvar = PApplet.parseFloat(readNumber(p, pname));
    out.print(pname+" ");
    out.println(myvar);
    return myvar;
  }

  public int loadInt(String p, String pname, PrintWriter out) {
    int myvar = PApplet.parseInt(readNumber(p, pname));
    out.print(pname+" ");
    out.println(myvar);
    return myvar;
  }

  public boolean loadBool(String p, String pname, PrintWriter out) {
    boolean myvar = false;
    int boolint = PApplet.parseInt(readNumber(p, pname));
    if (boolint == 1) {
      myvar = true;
    }
    out.print(pname+" ");
    out.println(myvar);
    return myvar;
  }

  public String readNumber(String s, String pname) {

    String[] ss = s.split("#");
    try {
      assert (ss.length > 0 && ss[0].length() > 0);
    } 
    catch( Exception e ) {
      System.out.println(e);
      System.out.printf("Bad input for %sin params file.\n", pname) ;
      System.exit(1);
    }
    return ss[0];
  }

  public IntList loadMultiInt(String[] list, String pname, PrintWriter out, int minN) {   
    IntList varlist = new IntList();
    String myvar = readNumber(list[1], pname);
    varlist.append(PApplet.parseInt(myvar));
    out.print(pname+" ");
    out.print(myvar);

    int i = 2;
    while (i < list.length && list[i].charAt(0) != '#') {
      myvar = readNumber(list[i], pname);
      varlist.append(PApplet.parseInt(myvar));
      out.print(" "+myvar);
      i++;
    }
    try {
      assert(varlist.size() >= minN);
    } 
    catch( Exception e ) {
      System.out.println(e);
      System.out.printf( "Not enough values for %s.", pname) ;
      out.close();
      System.exit(1);
    }   
    out.println();
    return varlist;
  }

  public FloatList loadMultiFloat(String[] list, String pname, PrintWriter out, int minN) {   
    FloatList varlist = new FloatList();
    String myvar = readNumber(list[1], pname);
    varlist.append(PApplet.parseFloat(myvar));
    out.print(pname+" ");
    out.print(myvar);

    int i = 2;
    while (i < list.length && list[i].charAt(0) != '#') {
      myvar = readNumber(list[i], pname);
      varlist.append(PApplet.parseFloat(myvar));
      out.print(" "+myvar);
      i++;
    }
    try {
      assert(varlist.size() >= minN);
    } 
    catch( Exception e ) {
      System.out.println(e);
      System.out.printf( "Not enough values for %s.", pname) ;
      out.close();
      System.exit(1);
    }
    out.println();
    return varlist;
  }


  public void loadClient(Client client, String[] list, String pname, PrintWriter out_params) {
    assert list.length >= 5;
    out_params.print(pname+" ");
    out_params.println(list[1]);
    int port = loadInt(list[2], " port ", out_params);
    client.setPort(port);
    int msgType = loadInt(list[3], " msgType ", out_params);   
    client.setSendType(msgType);
    //load msg now
    if (msgType <= 2 || msgType == 5) { //str
      out_params.print(" msg ");
      String strmsg = list[4];
      out_params.println(strmsg);           
      client.setFixedStrMsg(strmsg);
    } else { //int
      int intMsg = loadInt(list[4], " msg ", out_params);
      client.setFixedIntMsg(intMsg);
    }
    if (list.length > 5 && list[5].charAt(0) != '#') {
      //add new line
      boolean addNL = loadBool(list[5], " addNewline ", out_params);
      client.setAddNewLine(addNL);
      if (list.length > 6 && list[6].charAt(0) != '#') {
        out_params.print(" encoding ");
        out_params.println(list[6]);
        client.setEncoding(list[6]);
      }
    }
  }

  public float loadClientInterval(Client client, String[] list, String pname, PrintWriter out_params) {
    assert list.length >= 5;
    out_params.print(pname+" ");
    out_params.println(list[1]);
    int port = loadInt(list[2], " port ", out_params);
    client.setPort(port);
    int msgType = loadInt(list[3], " msgType ", out_params);   
    client.setSendType(msgType);
    //load time interval 
    float interval = loadFloat(list[4], " interval ", out_params);
    if (list.length > 5 && list[5].charAt(0) != '#') {
      //add new line
      boolean addNL = loadBool(list[5], " addNewline ", out_params);
      client.setAddNewLine(addNL);
      if (list.length > 6 && list[6].charAt(0) != '#') {
        out_params.print(" encoding ");
        out_params.println(list[6]);
        client.setEncoding(list[6]);
      }
    }
    return interval;
  }
}
interface Stim {
  
  public void init();
  public void shuffleDirs(PApplet main);
  public void cleanUp();
  
  public void run(boolean show);
  
  public String getStimInfo();
  
  public String getSimpleStimInfo();
  
  public int getScrShotNo();
  
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#7F7F7F", "--hide-stop", "FlowStims" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
