class Loader {

  Stim[] loadStims(float pxPerDeg, String[] lines, PrintWriter out) {
    //default stim params
    nDirs = 1;

    int nFadeFrames = 3;

    FloatList tempFreqs = new FloatList(4.);

    boolean useFlows = false, useGratings = false;

    //flows
    IntList nDots = new IntList(1, 3);
    IntList dotColors = new IntList(0, 255);
    IntList dotBgColors = new IntList(127, 127);
    IntList dotInterColors = dotBgColors;//new IntList(-1,-1);          
    FloatList dotDiamsDeg = new FloatList(1.5);
    FloatList dotSeps = new FloatList(4.);
    FloatList dotSpFqs = null;
    float dirStd = 0.09;
    float posStd = 0.1;  
    boolean wiggle = true;
    boolean fixRand = false;
    float sepWeight = 1.5;//use higher val if FRAME_RATE = 30
    float maxForce = .04;
    float tileSizeFactor = 2.5;
    boolean equalArea = true;
    //grats
    FloatList gratWidthsDeg = new FloatList(12.5, 3.125);
    IntList gratColors = new IntList(64.);//trick: use a float in constructor to create a single-elt list!
    IntList gratBgColors = new IntList(192.);
    IntList gratInterColors = new IntList(127.);
    boolean randPhase = false;


    for (int p = 0; p < lines.length; p++) {
      String line = lines[p];
      if (line.length() > 0 && line.charAt(0) != '#') {
        String[] list = split(line, ' ');
        if (list.length < 2) continue;
        switch(list[0]) {
        //ALL
          case "nDirs": nDirs = loadInt(list[1], list[0], out); break;
          case "dirDegShift": dirDegShift = loadInt(list[1], list[0], out); break;
          case "pxPerDeg": pxPerDeg = loadFloat(list[1], list[0], out); break;//overrides the calculated pxPerDeg
          case "nFadeFrames": nFadeFrames = loadInt(list[1], list[0], out); break;
          case "tempFreq": tempFreqs = loadMultiFloat(list, list[0], out, 0); break;
        //FLOWS
          case "useFlows": useFlows = loadBool(list[1], list[0], out); break;
          case "nDots": nDots = loadMultiInt(list, list[0], out, 0); break;
          case "equalArea": equalArea = loadBool(list[1], list[0], out); break;
          case "dotFgVal": dotColors = loadMultiInt(list, list[0], out, 0); break;
          case "->dotBgVal":
          case "dotBgVal": dotBgColors = loadMultiInt(list, list[0], out, dotColors.size()); break;
          case "->dotInterVal":
          case "dotInterVal": dotInterColors = loadMultiInt(list, list[0], out, dotColors.size()); break;
          case "dotDiamDeg": dotDiamsDeg = loadMultiFloat(list, list[0], out, 0); break;
          case "->dotSpacing":
          case "dotSpacing": dotSeps = loadMultiFloat(list, list[0], out, dotDiamsDeg.size()); break;
          case "->dotSpatFreq":
          case "dotSpatFreq": dotSpFqs = loadMultiFloat(list, list[0], out, dotDiamsDeg.size()); break;
          case "maxForce": maxForce = loadFloat(list[1], list[0], out); break;
          case "sepWeight": sepWeight = loadFloat(list[1], list[0], out); break;
          case "posStd": posStd = loadFloat(list[1], list[0], out); break;
          case "dirStd": dirStd = loadFloat(list[1], list[0], out); break;
          case "rigidTrans": wiggle = !loadBool(list[1], list[0], out); break;
          case "tileSize": tileSizeFactor = loadFloat(list[1], list[0], out); break;
          case "fixRandState": fixRand = loadBool(list[1], list[0], out); break;
        //GRATS
          case "useGratings": useGratings = loadBool(list[1], list[0], out); break;
          case "gratWidthDeg": gratWidthsDeg = loadMultiFloat(list, list[0], out, 0); break;
          case "gratFgVal": gratColors = loadMultiInt(list, list[0], out, 0); break;
          case "->gratBgVal":
          case "gratBgVal": gratBgColors = loadMultiInt(list, list[0], out, gratColors.size()); break;
          case "->gratInterVal":
          case "gratInterVal": gratInterColors = loadMultiInt(list, list[0], out, gratColors.size()); break;
          case "randGratPhase": randPhase = loadBool(list[1], list[0], out); break;
          default: break;
        }
      }
    }

    int fadeRate = ceil(255./max(1,nFadeFrames));
    if (posStd == 0) wiggle = false;


    int seed = -1;
    //if flows aren't rand, then most likely you dont want rand grating phase either
    if (fixRand && randPhase == true) randPhase = false;//(catching possibly common mistake when setting params file)

    int nStims = tempFreqs.size()*(int(useFlows)*(nDots.size()*dotColors.size()*dotDiamsDeg.size())
      + int(useGratings)*(gratWidthsDeg.size()*gratColors.size()));

    Stim[] stims = new Stim[nStims];

    float speed, diam_deg, sep, width_deg, tempfreq, spatfreq;
    int ndots, fgcolor, bgcolor, gray, diam_px, sep_px, tilesize, width_px, period_px;

    int s = 0;


      for (int sp = 0; sp < tempFreqs.size(); sp++) {
        tempfreq = tempFreqs.get(sp);

        //FLOWS
        if (useFlows) {

          for (int dt = 0; dt < nDots.size(); dt++) {
            ndots = nDots.get(dt);

            for (int sz = 0; sz < dotDiamsDeg.size(); sz++) {
              diam_deg = dotDiamsDeg.get(sz);
              diam_px = round(diam_deg*pxPerDeg);

              sep = dotSeps.get(sz);
              sep_px = round(sep*diam_px); //based on original diameter, i.e., before area correction
              tilesize = round(sep_px*tileSizeFactor);
              
              //compute corrected diam if equalArea is ON 
              if (ndots > 1 && equalArea) diam_px = round(diam_px/sqrt(ndots));

              //convert temp freqs to actual speeds (px/frame)
              if (dotSpFqs == null) period_px = sep_px;
              else {
                 spatfreq = dotSpFqs.get(sz);
                 period_px = round(pxPerDeg/spatfreq);
              }
              speed = tempfreq*period_px/FRAME_RATE;

              for (int cc = 0; cc < dotColors.size(); cc++) {
                fgcolor = dotColors.get(cc);
                bgcolor = dotBgColors.get(cc);
                gray = dotInterColors.get(cc);

                if (fixRand) seed = (int) random(1000);
                stims[s] = new Flow(seed, tilesize, dirStd, sep, sep_px, posStd, ndots, diam_px, diam_deg,
                      fgcolor, bgcolor, gray, speed, tempfreq, wiggle, maxForce, sepWeight, fadeRate);
                s++;
              }
              
            }
          }
        }
        //GRATS
        if (useGratings) {

          for (int sz = 0; sz < gratWidthsDeg.size(); sz++) {
            width_deg = gratWidthsDeg.get(sz);
            width_px = round(width_deg*pxPerDeg);
            period_px = 2*width_px;
            speed = tempfreq*period_px/FRAME_RATE;

            for (int cc = 0; cc < gratColors.size(); cc++) {
              fgcolor = gratColors.get(cc);
              bgcolor = gratBgColors.get(cc);
              gray = gratInterColors.get(cc);

              stims[s] = new Grating(tempfreq, fgcolor, bgcolor, gray, width_px, width_deg, speed, randPhase, fadeRate); 
              s++;
            }
          }
        }
      }
    

    return stims;
  }

  float loadFloat(String p, String pname, PrintWriter out) {
    float myvar = float(readNumber(p, pname));
    out.print(pname+" ");
    out.println(myvar);
    return myvar;
  }

  int loadInt(String p, String pname, PrintWriter out) {
    int myvar = int(readNumber(p, pname));
    out.print(pname+" ");
    out.println(myvar);
    return myvar;
  }

  boolean loadBool(String p, String pname, PrintWriter out) {
    boolean myvar = false;
    int boolint = int(readNumber(p, pname));
    if (boolint == 1) {
      myvar = true;
    }
    out.print(pname+" ");
    out.println(myvar);
    return myvar;
  }

  String readNumber(String s, String pname) {

    String[] ss = s.split("#");
    try {
      assert (ss.length > 0 && ss[0].length() > 0);
    } 
    catch( Exception e ) {
      System.out.println(e);
      System.out.printf("Bad input for %sin params file.\n", pname) ;
      System.exit(1);
    }
    return ss[0];
  }

  IntList loadMultiInt(String[] list, String pname, PrintWriter out, int minN) {   
    IntList varlist = new IntList();
    String myvar = readNumber(list[1], pname);
    varlist.append(int(myvar));
    out.print(pname+" ");
    out.print(myvar);

    int i = 2;
    while (i < list.length && list[i].charAt(0) != '#') {
      myvar = readNumber(list[i], pname);
      varlist.append(int(myvar));
      out.print(" "+myvar);
      i++;
    }
    try {
      assert(varlist.size() >= minN);
    } 
    catch( Exception e ) {
      System.out.println(e);
      System.out.printf( "Not enough values for %s.", pname) ;
      out.close();
      System.exit(1);
    }   
    out.println();
    return varlist;
  }

  FloatList loadMultiFloat(String[] list, String pname, PrintWriter out, int minN) {   
    FloatList varlist = new FloatList();
    String myvar = readNumber(list[1], pname);
    varlist.append(float(myvar));
    out.print(pname+" ");
    out.print(myvar);

    int i = 2;
    while (i < list.length && list[i].charAt(0) != '#') {
      myvar = readNumber(list[i], pname);
      varlist.append(float(myvar));
      out.print(" "+myvar);
      i++;
    }
    try {
      assert(varlist.size() >= minN);
    } 
    catch( Exception e ) {
      System.out.println(e);
      System.out.printf( "Not enough values for %s.", pname) ;
      out.close();
      System.exit(1);
    }
    out.println();
    return varlist;
  }


  void loadClient(Client client, String[] list, String pname, PrintWriter out_params) {
    assert list.length >= 5;
    out_params.print(pname+" ");
    out_params.println(list[1]);
    int port = loadInt(list[2], " port ", out_params);
    client.setPort(port);
    int msgType = loadInt(list[3], " msgType ", out_params);   
    client.setSendType(msgType);
    //load msg now
    if (msgType <= 2 || msgType == 5) { //str
      out_params.print(" msg ");
      String strmsg = list[4];
      out_params.println(strmsg);           
      client.setFixedStrMsg(strmsg);
    } else { //int
      int intMsg = loadInt(list[4], " msg ", out_params);
      client.setFixedIntMsg(intMsg);
    }
    if (list.length > 5 && list[5].charAt(0) != '#') {
      //add new line
      boolean addNL = loadBool(list[5], " addNewline ", out_params);
      client.setAddNewLine(addNL);
      if (list.length > 6 && list[6].charAt(0) != '#') {
        out_params.print(" encoding ");
        out_params.println(list[6]);
        client.setEncoding(list[6]);
      }
    }
  }

  float loadClientInterval(Client client, String[] list, String pname, PrintWriter out_params) {
    assert list.length >= 5;
    out_params.print(pname+" ");
    out_params.println(list[1]);
    int port = loadInt(list[2], " port ", out_params);
    client.setPort(port);
    int msgType = loadInt(list[3], " msgType ", out_params);   
    client.setSendType(msgType);
    //load time interval 
    float interval = loadFloat(list[4], " interval ", out_params);
    if (list.length > 5 && list[5].charAt(0) != '#') {
      //add new line
      boolean addNL = loadBool(list[5], " addNewline ", out_params);
      client.setAddNewLine(addNL);
      if (list.length > 6 && list[6].charAt(0) != '#') {
        out_params.print(" encoding ");
        out_params.println(list[6]);
        client.setEncoding(list[6]);
      }
    }
    return interval;
  }
}
