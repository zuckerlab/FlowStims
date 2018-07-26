class Flock implements Stim {
  
  boolean debug = true;
  int n1 = 50;
  
  ArrayList<Boid> boids;
  DoublyLinkedList[] binGrid;
  int[] myBorders, nbrArray;
  int binSize, binrows, bincols, xLen, yLen;
  int pattern, D, boidColor, boidAlpha, bgColor, grayColor;
  float xHalfLen, yHalfLen, baseSep, sepSq, posStd, radius, origDdeg;
  int sepFreq, fadeRate;
  
  FlowField flow;

  
  float meanTheta, maxSpeed, tempFreq, maxForce, sepWeight;
  int meanThetaDeg;
  PVector v0;
  
  boolean wiggle, move, separate, follow;
  PShape boid;
  
  int mySeed;


  Flock(int myseed, int tilesize, float meantheta, int dirdeg, float dirstd, float basesep, int sepPx, float posstd, int ndots, 
        int diam, float diamdeg, int boidcolor, int bgcolor, int gray, float maxsp, float tempfreq,
        boolean wiggle_, float maxforce, float sepweight, int faderate) {
          
    mySeed = myseed;
    if (dirstd > 0) flow = new FlowField(tilesize, meantheta, dirstd);
    
    nbrArray = new int[9];//single array shared by all boids
    meanThetaDeg = dirdeg;
    meanTheta = -meantheta;
    pattern = ndots;
    
    origDdeg = diamdeg;
    D = diam;
    if (pattern > 1) D = round(D/sqrt(pattern));
    radius = D/2.;
    
    boidColor = boidcolor;
    bgColor = bgcolor;
    grayColor = gray;
    
    if (gray == -1) {//if grayscr set to auto
      float spacing = float(sepPx)/diam;
      float dotArea = width*height*PI/(spacing*spacing*4);          
      float bgArea = width*height - dotArea;
      float avgColor = (dotArea*boidColor+bgArea*bgColor)/( width*height );
      grayColor = int(avgColor);
    }
    

    wiggle = wiggle_;
    maxForce = maxforce;
    sepWeight = sepweight;
    fadeRate = faderate;
    posStd = posstd;
    
    if (posStd == 0) assert !wiggle;
    else setWiggle(true);//if posStd we want scrambled boids, so turn wiggle on during pre-trial
    

    if (usePShape) createBoidShape();
    
    move = true;
    maxSpeed = maxsp;
    tempFreq = tempfreq;

    v0 = PVector.fromAngle(meanTheta);
    v0.mult(maxSpeed);
    
    float sepRadius = sepPx+1;//+1 takes care of fractional pixels
    sepSq = sq(sepRadius);//squaring since using sqeuclidean dist below
    sepFreq = 5;
    if (debug) sepFreq = 1;
    binSize = sepPx;
    baseSep = basesep;

    binrows = myheight/binSize + 1;
    bincols = mywidth/binSize + 1;

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
    xHalfLen = xLen/2.;
    yLen = myBorders[3] - myBorders[2];
    yHalfLen = yLen/2.;
    
  }
  
  void init() {
    if (mySeed < 0) {
      origSeed += 1000;
      randomSeed(origSeed);
    } else randomSeed(mySeed);
    binGrid = new DoublyLinkedList[binrows*bincols];
    for (int i = 0; i < binrows*bincols; i++) {
        binGrid[i] = new DoublyLinkedList();
    }
    boids = new ArrayList<Boid>();
    int borderx = frameWidth + binSize*(bincols);
    int bordery = frameWidth + binSize*(binrows);
    int c = 0;
    for (int i = myBorders[2]; i < bordery; i += binSize) {
      for (int j = myBorders[0]; j < borderx; j += binSize) {
        boids.add(new Boid(j+posStd*binSize*randomGaussian(),i+posStd*binSize*randomGaussian(),c,c % sepFreq));
        c++;
      }
    }
  }
  
  void cleanUp() {
    binGrid = null;
    boids = null;
  }
  
  void setWiggle(boolean state) {
    separate = state;
    follow = state;
  }
  //create a Freeze method to set move to false?

  void run(boolean show) {
    
    if (show) {
      boidAlpha = min(255,boidAlpha + fadeRate);
      setWiggle(wiggle);
    } else boidAlpha = max(0,boidAlpha - fadeRate);

    float alphafrac = boidAlpha/255.;
    background(bgColor*alphafrac + grayColor*(1. - alphafrac));

    for (Boid b : boids) {         
      b.run();        
    }            
  }
  
  void createBoidShape() {
  
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
  
  void drawBinGrid() {//for debugging purposes
    stroke(255,255,0,128);

    for (int i = myBorders[0]; i <= myBorders[1]; i += binSize)
      line(i,myBorders[2],i,myBorders[3]);

    for (int i = myBorders[2]; i <= myBorders[3]; i += binSize)
      line(myBorders[0],i,myBorders[1],i);

  }
  
  String getStimInfo() {
    String stiminfo = String.format(
        "FLOW nDots=%d dir=%d tfreq=%.1f diam=%.2f spac=%.1f dotLvl=%d bgLvl=%d interLvl=%d rigid=%d posStd=%.2f",
        pattern, meanThetaDeg, tempFreq, origDdeg, baseSep, boidColor, bgColor, grayColor, int(!wiggle), posStd);
    return stiminfo;
  }
  
  public class Boid {
  
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
   
    
    int getBinIndex() {
      bin_x = (int) (position.x-myBorders[0])/binSize;
      bin_y = (int) (position.y-myBorders[2])/binSize;
      
      return bin_y*bincols + bin_x;
    }
    void updateBinNeighbors() {
      
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
    
    //void testSepDist() {
    //  int bin_idx = getBinIndex();
    //  updateBinNeighbors();
    //  PVector sep = separate();
    //}
    
    void run() {
      
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
  
    PVector followField() {
      //update theta: lookup direction at that position in the flow field
      theta = flow.getDirection(position);     
  
      desired = PVector.fromAngle(theta);//unit vector
      desired.mult(maxSpeed);
      //steering force = desired - velocity
      desired.sub(velocity);    
      desired.limit(maxForce);    
      
      return desired;
  
    }
    
    void flock() {
      
      if (!separate && !follow) {//noWiggle
        velocity.set(v0);
        desired.set(v0);
        desired.limit(maxForce);
        acceleration.add(desired); 
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
          acceleration.add(followField());  
        } else { //allows boids to still separate without any flow field (mostly for debugging reasons)
          desired.set(v0);
          desired.sub(velocity);    
          desired.limit(maxForce); 
          acceleration.add(desired);      
        }
      }
      
      //update theta for a smoother change in heading when patt > 1 -- not sure it looks better, though
      //theta = PVector.add(velocity,steer).heading();
  
    }
  
    //update boid position
    void update() {
  
      velocity.add(acceleration);
      velocity.limit(maxSpeed);
      //if (node.id == n1) print(velocity.y," ");
      position.add(velocity);
      
      //reset acceleration after each cycle
      acceleration.set(0,0);
    }
    
    // wraparound borders
    void borders() {
      int factor = pattern;
      if (position.x < myBorders[0]-factor*radius) position.x += xLen;
      if (position.y < myBorders[2]-factor*radius) position.y += yLen;
      if (position.x > myBorders[1]-factor*radius) position.x -= xLen;
      if (position.y > myBorders[3]-factor*radius) position.y -= yLen;
    }
    
    void drawBoidShape() {//when using PShape rendering
      pushMatrix();
      translate(position.x,position.y);
      if (pattern > 1)
        rotate(theta - HALF_PI);
      shape(boid);
      popMatrix();    
    }
  
    void drawBoid() {
      
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
        } else {
          rectMode(CENTER);
          rect(0,0,pattern*D,D);
        }
      
        popMatrix();
          
      }
      
    }
    
    //check for nearby boids
    PVector separate() {
  
      float dx, dy, d2;
      PVector steer = new PVector(0,0);
      PVector diff = new PVector(0,0);
  
      Node other;
      
      //look at each neighboring bin, in turn
  
      if (debug && (node.id == n1)) {
        fill(255,255,0,64);
        rectMode(CORNER);
        noStroke();
        rect(myBorders[0]+bin_x*binSize,myBorders[2]+bin_y*binSize,binSize,binSize);
        noFill();
        stroke(255,128);
        float D = 2*sqrt(sepSq);
        ellipse(position.x,position.y,D,D);
      }
  
      for (int nbr_idx : nbrArray) {
  
        if (nbr_idx == -1) continue;
        
        if (debug && (node.id == n1)) {
          fill(255,0,0,64);
          int nbr_x = nbr_idx % bincols;
          int nbr_y = nbr_idx / bincols;
          rectMode(CORNER);
          noStroke();
          rect(myBorders[0]+nbr_x*binSize,myBorders[2]+nbr_y*binSize,binSize,binSize);
        }
        
  
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
  
            d2 = dx*dx + dy*dy;//distance squared
            
            if (debug && (node.id == n1)) {
              noFill();
              stroke(255,0,0,160);
              rectMode(RADIUS);
              rect(other.item.position.x,other.item.position.y,radius,radius);
            }
            
            if (d2 > 0 && d2 < sepSq) {
              
              diff.set(dx,dy);
              diff.setMag(1./d2);
              steer.add(diff);
              
              if (debug && (node.id == n1)) {
                noFill();
                stroke(255,255,0);
                ellipse(other.item.position.x,other.item.position.y,2*radius*1.5,2*radius*1.5);
              }
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
  
  
  
  public class DoublyLinkedList {
      private int n;        
      private Node head;     
      private Node last;  
      private Node curr;
  
      public DoublyLinkedList() {
        //circular DL list
        head = new Node();
        head.id = -2;
        head.next = head;
        head.prev = head;
        last = head;
  
      }
  
      public boolean isEmpty()    { return n == 0; }
      public int size()           { return n;      }
  
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
        if (curr == head)
          return null;
  
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
