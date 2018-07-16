
Flock flock;  
FlowField field;
int tileSize = 100;
float dir = 3*PI/2.;
float dirStd = 0.1;

int patt = 3;
int radius = 4;
int sepNrads = 12;
int sepPx = sepNrads*radius;
float sepWeight = 2.5;

int borderw = 0;
int myheight;
int mywidth;

boolean move = false;
boolean noSep = true;
float posStd = 0.;



void setup() {
  frameRate(60);
  size(800,600);
  randomSeed(0);
  
  myheight = height - 2*borderw;
  mywidth = width - 2*borderw;

  field = new FlowField(tileSize, dir, dirStd);
  flock = new Flock(field, sepPx, sepWeight, posStd, patt, radius, 255, dir, .75*radius);


} 

void draw () {
  background(0);
  flock.run(move,noSep);
  //field.drawField();

  stroke(120,0,0);
  noFill();
  rect(borderw,borderw,mywidth,myheight);
  
  stroke(255,255,0,128);
  int i= 0;
  for (i = flock.myborders[0]; i < flock.myborders[1]; i += sepPx)
    line(i,borderw,i,borderw+myheight);
  line(i,borderw,i,borderw+myheight);
  i = 0;
  for (i = flock.myborders[2]; i < flock.myborders[3]; i += sepPx)
    line(borderw,i,borderw+mywidth,i);
  line(borderw,i,borderw+mywidth,i);
  
  //stroke(255);
  //textSize(12);
  //text("Frame rate: " + int(frameRate), 10, 20);
  
}

void keyPressed() {
  if (key == 's'){
    noSep = !noSep;
  }
  else if (key == 'm'){
    move = !move;
  }  
}
