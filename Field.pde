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

}
