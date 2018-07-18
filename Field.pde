class FlowField {
  
  float mean;
  float stdev;

  float[][] field;//array containing directions of each tile
  int cols, rows; 
  int tileSize; // side of each square tile of the flow field

  FlowField(int res, float mu, float std) {
    mean = -mu;
    stdev = std;
    tileSize = res;
    // get number of columns and rows
    cols = ceil(mywidth/float(tileSize));
    rows = ceil(myheight/float(tileSize));
    field = new float[cols][rows];

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
          field[i][j] = mean + stdev*randomGaussian();
      }
    }
  }
  
  float getDirection(PVector pos) {
    int column = (int) constrain((pos.x-borderw)/tileSize, 0, cols-1);
    int row = (int) constrain((pos.y-borderw)/tileSize, 0, rows-1);
    return field[column][row];
  }
  
  void drawField() {
    //draw grid
    stroke(127,127,127,128);

    for (int i = 0; i < cols+1; i++)
      line(borderw+i*tileSize, borderw, borderw+i*tileSize, borderw+rows*tileSize);
    
    for (int i = 0; i < rows+1; i++)
      line(borderw, borderw+i*tileSize, borderw+cols*tileSize, borderw+i*tileSize);
    
    
    //draw direction "arrows"
    float x, y, dir;
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        x = borderw + j*tileSize + tileSize/2.;
        y = borderw + i*tileSize + tileSize/2.;
        dir = field[j][i];
        line(x - cos(dir)*tileSize/4., y - sin(dir)*tileSize/4.,
            x + cos(dir)*tileSize/4., y + sin(dir)*tileSize/4.);
            
              
      }
    }

    
  }

}
