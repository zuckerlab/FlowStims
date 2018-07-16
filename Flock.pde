class Flock {
  boolean debug = false;
  ArrayList<Boid> boids;
  DoublyLinkedList[] binGrid;

  int tileSide;
  int binrows;
  int bincols;
  int binSize;
  int pattern;
  int fillc;
  int radius;
  float sepSq;
  int sepFreq;
  
  int[] nbrArray;//single common array to all boids!
  
  Field flow;
  int xLen, yLen;
  int[] myborders;
  float xHalfLen, yHalfLen;
  float meanTheta;
  
  float maxForce;    
  float maxSpeed;
  
  boolean move, noSep;
  float sepWeight;


  Flock(Field fl, int sepPx, int patt, int R, int fillcolor, float meanTheta_) {
    nbrArray = new int[9];
    meanTheta = -meanTheta_;
    pattern = patt;
    fillc = fillcolor;
    radius = R;
    
    maxSpeed = radius*.75;
    maxForce = .14;
    
    sepSq = sq(1.1*sepPx);//squaring since using sqeuclidean dist below
    sepFreq = 2;
    
    flow = fl;
    binSize = sepPx;
    println("binSize",binSize);

    binrows = ceil(myheight/float(binSize)) + int((myheight % binSize) == 0);
    bincols = ceil(mywidth/float(binSize)) + int((mywidth % binSize) == 0);
    println(sepPx,"binSize",binSize,binrows,bincols);
    
    //int borderx = borderw + mywidth;
    //int bordery = borderw + myheight;    
    int borderx = borderw + sepPx*(mywidth/sepPx + 1);
    int bordery = borderw + sepPx*(myheight/sepPx + 1);

    myborders = new int[4];
    myborders[0] = borderw; myborders[1] = borderx;
    myborders[2] = borderw; myborders[3] = bordery;
    xLen = myborders[1] - myborders[0];
    xHalfLen = xLen/2.;
    yLen = myborders[3] - myborders[2];
    yHalfLen = yLen/2.;

    println("xLen",xLen,"xHalfLen",xHalfLen);
    println("yLen",yLen,"yHalfLen",yHalfLen);
    
    binGrid = new DoublyLinkedList[binrows*bincols];
    for (int i = 0; i < binrows*bincols; i++) {
        binGrid[i] = new DoublyLinkedList();
    }
    boids = new ArrayList<Boid>();
    int c = 0;
    for (int i = myborders[2]; i < bordery; i += sepPx) {
      for (int j = myborders[0]; j < borderx; j += sepPx) {
        boids.add(new Boid(j,i,c,c % sepFreq));
        //print(c+":<" + j + "," + i + ">");
        c++;

      }
    }
    //println();

  }

  void run(float sep, boolean move_, boolean noSep_) {

    sepWeight = sep;
    move = move_;
    noSep = noSep_;
    for (Boid b : boids) {         
      b.run();        
    }      
      
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

  Boid(int x, int y, int id, int sepcount) {

    position = new PVector(x, y);
    //make sure it is created inside the available area
    while (x > myborders[1]-pattern*radius) x -= xLen;
    while (x < myborders[0]-pattern*radius) x += xLen;
    while (y > myborders[3]-pattern*radius) y -= yLen;
    while (y < myborders[2]-pattern*radius) y += yLen;  
    
    node = new Node();
    node.item = this;
    node.id = id;
    
    sepCounter = sepcount;
    
    binGrid[getBinIndex()].add(node);
    
    acceleration = new PVector(0, 0);
    theta = meanTheta;
    velocity = PVector.fromAngle(theta);
    desired = velocity.copy();
    desired.setMag(maxForce);
    sep = new PVector(0, 0);

  }
 
  
  int getBinIndex() {
    bin_x = (int) (position.x-myborders[0])/binSize;
    bin_y = (int) (position.y-myborders[2])/binSize;
    
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
  void run() {
    
    int bin_idx = getBinIndex();

    updateBinNeighbors();
    

    if (move) {
      flock();
      update();
  
      borders();
  
      int new_bin_idx = getBinIndex();
  
      if (new_bin_idx != bin_idx) {
        binGrid[bin_idx].remove(node);
        binGrid[new_bin_idx].add(node);
        
      } 
    }
    
    render();
    
    
  }

  PVector followField() {
    //lookup vector at that position in the flow field
    //PVector desired;
    if (flow != null) {
      float desired_angle;
  
      desired_angle = flow.lookup(position);     
      
      //apply dotsStd
      desired = PVector.fromAngle(desired_angle + 0);//mag == 1        
      //scale it by maxSpeed
      desired.mult(maxSpeed);
      //steering force = desired - velocity
      desired.sub(velocity);
      desired.limit(maxForce);  
           
    }
    return desired;

  }
  
  void flock() {
    
    sepCounter = (sepCounter + 1) % sepFreq;
    if (!noSep && sepCounter == 0) { //separate only once every sepFreq frames   
      if (sepWeight > 0) {
        PVector sep = separate();
        sep.mult(sepWeight);
        acceleration.add(sep);
      }
    }
      
    PVector steer = followField();
    acceleration.add(steer);

  }

  //update position
  void update() {
    
    velocity.add(acceleration);
    //velocity.normalize();
    //velocity.mult(maxSpeed);
    velocity.limit(maxSpeed);
    
    position.add(velocity);
    
    //reset acceleration after each cycle
    acceleration.mult(0);
  }
  
  // wraparound borders
  void borders() {
    int factor = pattern;
    if (position.x < myborders[0]-factor*radius) position.x += xLen;//= myborders[1]-factor*radius;
    if (position.y < myborders[2]-factor*radius) position.y += yLen;//= myborders[3]-factor*radius;
    if (position.x > myborders[1]-factor*radius) position.x -= xLen;//= myborders[0]-factor*radius;
    if (position.y > myborders[3]-factor*radius) position.y -= yLen;//= myborders[2]-factor*radius;
  }

  void render() {
    
    fill(fillc);
    noStroke();
    float D = 2*radius;

    if (pattern == 1) {
      ellipseMode(CENTER);
      ellipse(position.x,position.y,D,D);         

      } else {
      pushMatrix();
      translate(position.x, position.y);
      rotate(theta - radians(90));

      ellipseMode(CENTER); 
      for (int i = -(pattern-1); i < pattern; i+=2) {
        ellipse(i*radius,0,D,D);
      }
    
      popMatrix();
        
    }
    
    if (debug && node.id == 50) {
      fill(255,255,0,64);
      rectMode(CORNER);
      noStroke();
      rect(myborders[0]+bin_x*binSize,myborders[2]+bin_y*binSize,binSize,binSize);
      noFill();
      stroke(255,128);
      D = 2*sqrt(sepSq);
      ellipse(position.x,position.y,D,D);
    }
    
  }
  
  //check for nearby boids
  PVector separate() {
    
    float dx, dy, d2;
    PVector steer = new PVector(0,0);
    PVector diff = new PVector(0,0);
    //int count = 0;
    Node other;
    //look at each neighboring bin, in turn
    
    //print("\n",node.id,")");
    //for (int nbr_idx : nbrArray)
    //  print(nbr_idx,":");
    //println();
    
    
    for (int nbr_idx : nbrArray) {

      if (nbr_idx == -1) continue;
      if (debug && node.id == 50) {
        fill(255,0,0,64);
        int nbr_x = nbr_idx % bincols;
        int nbr_y = nbr_idx / bincols;
        rectMode(CORNER);
        noStroke();
        rect(myborders[0]+nbr_x*binSize,myborders[2]+nbr_y*binSize,binSize,binSize);
      }
      
      //print("["+nbr_idx+"]");
      //binGrid[nbr_idx].printout();
      
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
          
          if (debug && node.id == 50) {
            noFill();
            stroke(255,0,0,160);
            rectMode(RADIUS);
            rect(other.item.position.x,other.item.position.y,radius,radius);
          }
          
          if (d2 > 0 && d2 < sepSq) {

            if (debug && node.id == 50) {
              noFill();
              stroke(255,255,0);
              ellipse(other.item.position.x,other.item.position.y,2*radius*1.5,2*radius*1.5);
            }
            
            diff.set(dx,dy);
            diff.setMag(1./d2);
            steer.add(diff);
     

          }
        }
        other = binGrid[nbr_idx].getNext();
      }
      

    }

    //as long as the vector is greater than 0 
    if (steer.magSq() > 0) {

      //implement Reynolds: steering = desired - Velocity
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
