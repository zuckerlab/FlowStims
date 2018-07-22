//https://stackoverflow.com/questions/1320745/abstract-class-in-java
interface Stim {
  
  void run(boolean show);
  
}

interface StimMaker {
  
  Stim init(int seed);
  void delete();
  
}
