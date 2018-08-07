interface Stim {
  
  void init();
  void shuffleDirs(int seed);
  void cleanUp();
  
  void run(boolean show);
  
  String getStimInfo();
  
  String getSimpleStimInfo();
  
  int getScrShotNo();
  
}
