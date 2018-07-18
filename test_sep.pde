
Flock flock;  
FlowField field;
int tileSize = 100;
float dir = 3*PI/2.;
float dirStd = 0.1;

int patt = 3;
int radius = 4;
int sepNrads = 12;
int sep_px = sepNrads*radius;
float sepWeight = 2.5;

int borderw = 60;
int myheight;
int mywidth;

boolean move = false;
boolean noSep = true;
float posStd = 0.;
boolean inter1, inter2, trial;
int inter1Len, inter2Len, trialLen;

//debug tools
boolean showBorders, showField, showGrid;
boolean usepshape = true;

void setup() {
  frameRate(60);
  size(800,600);
  randomSeed(0);
  
  myheight = height - 2*borderw;
  mywidth = width - 2*borderw;

  field = new FlowField(tileSize, dir, dirStd);
  
  int dotColor = 255;
  int bgColor = 0;
  float mxspeed = .75*radius;
  flock = new Flock(field, sep_px, sepWeight, posStd, 
            patt, radius, dotColor, bgColor, dir, mxspeed, usepshape);

  
} 

void draw () {

  flock.run(move,noSep);
  
  if (showBorders) drawBorders();
  if (showField) field.drawField(); 
  if (showGrid) flock.drawBinGrid();
  
  stroke(255);
  textSize(12);
  text("Frame rate: " + int(frameRate), 10, 20);
  
}

void drawBorders() {
  stroke(120,0,0);
  noFill();
  rect(borderw,borderw,mywidth-1,myheight-1);
  
}

void keyPressed() {
  switch (key) {
    case 's':
      noSep = !noSep;
      break;
    case 'm':
      move = !move;
      break;
    case 'b':
      showBorders = !showBorders;
      break;
    case 'f':
      showField = !showField;
      break;
    case 'g':
      showGrid = !showGrid;
    default:
      break;
  }  
}
