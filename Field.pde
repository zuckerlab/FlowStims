abstract class Field {
  float mean;
  float stdev;
  
  
  float getStd() {
    return stdev;
  }
  

  abstract void init(int wdth, int hght, int x1, int y1, float mu, float std);
  

  
  
  abstract float lookup(PVector pos);
   //return field orientation for a certain posistion on the screen 
  
  
  abstract void getBorders(PVector pos, int[] borders);
   //return field borders 

  
}

class TiledField extends Field {

  // The flow field is a 2-d array of directions
  float[][] field;
  int cols, rows; 
  int resolution; // side of each square tile of the flow field
  int indivMeans;

  TiledField(int res, int individMus, float mu, float std) {
    init(0, 0, res, individMus, mu, std);
  }

  void init(int a, int b, int res, int individMus, float mu, float std) {
    mean = -mu;
    stdev = std;
    resolution = res;
    indivMeans = individMus;
    // get number of columns and rows
    cols = ceil((width+0.)/resolution);
    rows = ceil((height+0.)/resolution);
    field = new float[cols][rows];

    float theta;
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {

        //assign direction to each tile
        if (indivMeans != 0)
          theta = int(random(indivMeans))*(TWO_PI/float(indivMeans));
        else
          theta = mean + stdev*randomGaussian();
        
        
        field[i][j] = theta;
        
      }
    }
  }
  
  float lookup(PVector pos) {
    int column = int(constrain(pos.x/float(resolution),0,cols-1));
    int row = int(constrain(pos.y/float(resolution),0,rows-1));
    return field[column][row];
  }
  
  
  void getBorders(PVector pos, int[] borders) {
    
    //int padding = int(float(resolution)/5.);

    int column = int(constrain(pos.x/float(resolution),0,cols-1));
    //left_edge
    borders[0] = column*resolution;// + padding;
    //right edge
    borders[1] = (column+1)*resolution;// - padding;
    
    int row = int(constrain(pos.y/float(resolution),0,rows-1));
    //top edge
    borders[2] = row*resolution;// + padding;
    //bottom edge
    borders[3] = (row+1)*resolution;// - padding;

  }


}
