interface Stim {
  
  void init();
  void shuffleDirs(PApplet main);
  void cleanUp();
  
  void run(boolean show);
  
  String getStimInfo();
  
  String getSimpleStimInfo();
  
  int getScrShotNo();
  
}
