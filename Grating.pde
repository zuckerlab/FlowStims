class Grating implements Stim {

  int direction, phase, fadeRate;
  boolean randPhase;
  float start, deltaX, deltaXspac, period;
  int barWidth, spaceWidth, bgColor, fgColor, grayColor, stimAlpha;
  float theta, speed, phaseFrac, tempFreq, widthDeg;

  int myheight = height;
  int mywidth = width;


  PVector p0, p1, p2, p3;

  float[] vals;


  Grating(int dir, float tempfreq, int fg, int bg, int gray, int barwid, float widdeg, float spd, boolean randphase, int faderate) {

    p0 = new PVector(0, 0);
    p1 = new PVector(0, 0);
    p2 = new PVector(0, 0);
    p3 = new PVector(0, 0);

    int spdsign = 1;
    if (dir > 90 && dir < 270) {
      spdsign = -1;
      if (dir < 180)  dir += 180;
      else dir -= 180;
    }

    direction = dir;
    theta = radians(direction);
    
    tempFreq = tempfreq;
    widthDeg = widdeg;
    barWidth = barwid;
    spaceWidth = barwid;
    if (direction == 90 || direction == 270) {
      speed = spd;
      if (direction == 270) speed = -spd;

      deltaX = barWidth;
      deltaXspac = spaceWidth;
    } else {
      speed = spdsign*spd/cos(theta);
      deltaX = round(barWidth/cos(theta));
      deltaXspac = round(spaceWidth/cos(theta));
    }

    randPhase = randphase;
    fadeRate = faderate;

    fgColor = fg;
    bgColor = bg;
    grayColor = gray;
    
    if (gray == -1) {//if grayscr set to auto
      float avgColor = (.5*fgColor+.5*bgColor);
      grayColor = int(avgColor);
    }

    period = deltaX + deltaXspac;

  }

  void init() {
    if (randPhase) {
      phase = (int) random(barWidth+spaceWidth);
      phaseFrac = float(phase)/(barWidth+spaceWidth);
    } else {
      phase = 0;
      phaseFrac = 0;
    }
    start = phase;
    createArrays();
  }

  void createArrays() {

    int size;
    if (direction == 90 || direction == 270) {
      p0.x = 0.; 
      p1.x = 0.;
      p2.x = mywidth; 
      p3.x = mywidth;
      size = (int) ceil((myheight+period  + int(period))/period);
      vals = new float[size];
      int i = 0;
      for (int y = -int(period); y < myheight+period; y += period) {
        vals[i] = y;
        i++;
      }
    } else if (direction == 0 || direction == 180) {
      p0.y = 0.;
      p1.y = 0.;
      p3.x = 0;
      p3.y = myheight/cos(theta);
      p3.rotate(theta);
      p2.y = p3.y;

      size = (int) ceil((mywidth+period+period)/period);
      vals = new float[size];
      int i = 0;
      for (int x = -int(period); x < mywidth+period; x += period) {
        vals[i] = x;
        i++;
      }
    } else {
      p0.y = 0.; 
      p1.y = 0.;
      p3.x = 0;
      p3.y = myheight/cos(theta);

      p3.rotate(theta);
      p2.y = p3.y;

      size = int((mywidth+myheight*abs(tan(theta))+period  + myheight*abs(tan(theta))+period)/period) + 1;

      vals = new float[size];
      int i = 0;

      for (int x = -int(myheight*abs(tan(theta))+period); x < mywidth+myheight*abs(tan(theta))+period; x += period) {
        vals[i] = x;
        i++;
      }
    }
  }
  
  void cleanUp() {
    vals = null;
  }

  void drawGrating() {

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

  void run(boolean show) {
    if (show) stimAlpha = min(255, stimAlpha + fadeRate);
    else stimAlpha = max(0, stimAlpha - fadeRate);

    float alphafrac = stimAlpha/255.;
    background(bgColor*alphafrac + grayColor*(1. - alphafrac));

    drawGrating();

    start = (start + speed) % period;
  }
  
  String getStimInfo() {
    String stiminfo = String.format(
        "GRAT dir=%d tfreq=%.1f width=%f fgLvl=%d bgLvl=%d interLvl=%d phase=%.2f",
        direction, tempFreq, widthDeg, bgColor, fgColor, grayColor, phaseFrac);
   return stiminfo;
  }
}
