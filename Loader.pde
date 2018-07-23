static class Loader {
  
 static float loadFloat(String p, String pname, PrintWriter out) {
   float myvar = float(p);
   out.print(pname+" ");
   out.println(myvar);
   return myvar;
 }
 
 static int loadInt(String p, String pname, PrintWriter out) {
   int myvar = int(p);
   out.print(pname+" ");
   out.println(myvar);
   return myvar;
 }
 
 static boolean loadBool(String p, String pname, PrintWriter out) {
   boolean myvar = false;
   if (int(p) == 1) {
     myvar = true;
   }
   out.print(pname+" ");
   out.println(myvar);
   return myvar;
 }
 
 static int loadMultiInt(String[] list, String pname, PrintWriter out,
                         ArrayList<Integer> varlist) {
   int myvar = int(list[1]);
   varlist.add(myvar);
   out.print(pname+" ");
   out.print(myvar);
   
   //if there's more after the int and it's not a comment
   if (list.length > 2 && list[2].charAt(0) != '#') {
     

     for (int i = 2; i < list.length && list[i].charAt(0) != '#'; i++) {    
       try {
           assert (Character.isDigit(list[i].charAt(0)));
           varlist.add(int(list[i]));
           out.print(' ');
           out.print(varlist.get(i-1));

       } catch( Exception e ) {
       System.out.println(e);
       System.out.printf("Bad input for %sin params file.\n", pname) ;
       out.close();
       System.exit(1);
       }
     
     }
     out.println();
     return varlist.size();
   } else {
     out.println();
     return 1;
   }
 }
 
 static int loadMultiFloat(String[] list, String pname, PrintWriter out,
                         ArrayList<Float> varlist) {
   float myvar = float(list[1]);
   varlist.add(myvar);
   out.print(pname+" ");
   out.print(myvar);
   
   
   //if there's more after the int and it's not a comment 
   if (list.length > 2 && list[2].charAt(0) != '#') {
     

     for (int i = 2; i < list.length && list[i].charAt(0) != '#'; i++) {    
       try {
           assert (Character.isDigit(list[i].charAt(0)));
           varlist.add(float(list[i]));
           out.print(' ');
           out.print(varlist.get(i-1));

       } catch( Exception e ) {
       System.out.println(e);
       System.out.printf("Bad input for %sin params file.\n", pname) ;
       out.close();
       System.exit(1);
       }
     
     }
     out.println();
     return varlist.size();
   } else {
     out.println();
     return 1;
   }
 }
 
 static float loadDepMultiFloat(String[] list, String pname, PrintWriter out,
                         ArrayList<Float> varlist, int minN) {
   int n = Loader.loadMultiFloat(list,pname,out,varlist);
   try {
     assert(n >= minN);
   } catch( Exception e ) {
     System.out.println(e);
     System.out.printf( "Not enough values for %sprovided.", pname) ;
     out.close();
     System.exit(1);
   }      
   return varlist.get(0);
 }
 
 static int loadDepMultiInt(String[] list, String pname, PrintWriter out,
                         ArrayList<Integer> varlist, int minN) {
   int n = Loader.loadMultiInt(list,pname,out,varlist);
   try {
     assert(n >= minN);
   } catch( Exception e ) {
     System.out.println(e);
     System.out.printf( "Not enough values for %sprovided.", pname) ;
     out.close();
     System.exit(1);
   }      
   return varlist.get(0);
 }
 
 static void loadClient(Client client, String[] list, String pname, PrintWriter out_params) {
   assert list.length >= 5;
   out_params.print(pname+" ");
   out_params.println(list[1]);
   int port = Loader.loadInt(list[2]," port ",out_params);
   client.setPort(port);
   int msgType = Loader.loadInt(list[3]," msgType ",out_params);   
   client.setSendType(msgType);
   //load msg now
   if (msgType <= 2) { //str
     out_params.print(" msg ");
     out_params.println(list[4]);           
     client.setFixedStrMsg(list[4]);
   } else { //int
     int intMsg = Loader.loadInt(list[4]," msg ",out_params);
     client.setFixedIntMsg(intMsg);
   }
   if (list.length > 5 && list[5].charAt(0) != '#') {
     //add new line
     boolean addNL = Loader.loadBool(list[5]," addNewline ",out_params);
     client.setAddNewLine(addNL);
     if (list.length > 6 && list[6].charAt(0) != '#') {
       out_params.print(" encoding ");
       out_params.println(list[6]);
       client.setEncoding(list[6]);
     }
   }
 }
 
 static float loadClientInterval(Client client, String[] list, String pname, PrintWriter out_params) {
   assert list.length >= 5;
   out_params.print(pname+" ");
   out_params.println(list[1]);
   int port = Loader.loadInt(list[2]," port ",out_params);
   client.setPort(port);
   int msgType = Loader.loadInt(list[3]," msgType ",out_params);   
   client.setSendType(msgType);
   //load time interval 
   float interval = Loader.loadFloat(list[4]," interval ",out_params);
   if (list.length > 5 && list[5].charAt(0) != '#') {
     //add new line
     boolean addNL = Loader.loadBool(list[5]," addNewline ",out_params);
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
