interface Stim {
  void init();
  void cleanUp();
  void run(boolean show);
  String getStimInfo();
  String getSimpleStimInfo();
  int getScrShotNo();
}
