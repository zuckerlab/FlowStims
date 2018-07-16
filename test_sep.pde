
Flock flock;  
FlowField field;
int tileSize = 60;
float dir1 = PI/4.;
float stdev = 0;
int radius = 4;
int sepNrads = 10;
int sepPx = sepNrads*radius;

int borderw = 50;
int myheight;
int mywidth;

boolean move = false;
boolean noSep = true;
float posStd = 0.1;

float sep;

void setup() {
  frameRate(60);
  size(800,600);
  randomSeed(0);
  
  myheight = height - 2*borderw;
  mywidth = width - 2*borderw;
  
  sep = 1.5;
  
  field = new FlowField(tileSize, dir1, stdev);
  flock = new Flock(field, sepPx, posStd, 1, radius, 255, dir1);


} 

void draw () {
  background(0);
  flock.run(sep,move,noSep);
  
  
  stroke(255,255,0,128);
  int i= 0;
  for (i = borderw; i < borderw+mywidth; i += tileSize)
    line(i,borderw,i,borderw+myheight);
  line(i,borderw,i,borderw+myheight);
  i = 0;
  for (i = borderw; i < borderw+myheight; i += tileSize)
    line(borderw,i,borderw+mywidth,i);
  line(borderw,i,borderw+mywidth,i);

  stroke(120,0,0);
  noFill();
  rect(borderw,borderw,mywidth,myheight);
  
  //stroke(255,255,0,128);
  //int i= 0;
  //for (i = flock.myborders[0]; i < flock.myborders[1]; i += sepPx)
  //  line(i,borderw,i,borderw+myheight);
  //line(i,borderw,i,borderw+myheight);
  //i = 0;
  //for (i = flock.myborders[2]; i < flock.myborders[3]; i += sepPx)
  //  line(borderw,i,borderw+mywidth,i);
  //line(borderw,i,borderw+mywidth,i);
  
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
