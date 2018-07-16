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
    int column = (int) min(max((pos.x-borderw)/tileSize,0),cols-1);
    int row = (int) min(max((pos.y-borderw)/tileSize,0),rows-1);
    return field[column][row];
  }
  
  void drawField() {
    stroke(255,255,0,128);
    int i = 0;
    for (i = 0; i < cols; i++)
      line(borderw+i*tileSize,borderw,borderw+i*tileSize,borderw+myheight);
    line(borderw+i*tileSize,borderw,borderw+i*tileSize,borderw+myheight);
    for (i = 0; i < rows; i++)
      line(borderw,borderw+i*tileSize,borderw+mywidth,borderw+i*tileSize);
    line(borderw,borderw+i*tileSize,borderw+mywidth,borderw+i*tileSize);
    float x, y, dir;
    for (i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        x = borderw+j*tileSize+tileSize/2.;
        y = borderw+i*tileSize+tileSize/2.;
        dir = field[j][i];
        line(x-cos(dir)*tileSize/4.,y-sin(dir)*tileSize/4.,
            x+cos(dir)*tileSize/4.,y+sin(dir)*tileSize/4.);
            
              
      }
    }

    
  }

}
