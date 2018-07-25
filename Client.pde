import java.net.* ;
import java.nio.* ;

class Client {
    DatagramSocket socket;
    InetAddress host;
    int port;
    DatagramPacket packet;
    byte[] data;
    int sendType = 1;
    String msg;
    String encoding = "UTF-8";
    boolean appendNewLineChar = false;   
    int intMsg;
    String strMsg;
    boolean fixedMsg = false;
 
    Client(String hostname) { 
   
      try {
        host = InetAddress.getByName(hostname);
        socket = new DatagramSocket() ;
      } catch( Exception e )
      {
        System.out.println( e ) ;
      }
    }
    
    void setPort(int port_) {
      port = port_;
    }
    
    void setSendType(int sendType_) {
      sendType = sendType_;
    }
    
    void setFixedIntMsg(int number) {
      intMsg = number;
      fixedMsg = true;
    }
    
    void setFixedStrMsg(String msg) {
     strMsg = msg;
     fixedMsg = true;
    }
    
    void setEncoding(String encoding_) {
      encoding = encoding_;
    }
    
    void setAddNewLine(boolean addnewline) {
      appendNewLineChar = addnewline;
    }
    
    /*send a string or int msg (the other arg is ignored)*/
    void send(String str_, int int_) {
      switch (sendType) {
        case 1:
          if (fixedMsg) send1(strMsg);
          else send1(str_);
          break;
        case 2:
          if (fixedMsg) send2(strMsg);
          else send2(str_);
          break;
        case 3:
          if (fixedMsg) send3(intMsg);
          else send3(int_);
          break;
        case 4:
          if (fixedMsg) send4(intMsg);
          else send4(int_);
          break;
      }
      
    }
 
   /*send string*/
   void send1(String msg) {
     if (appendNewLineChar)
       msg += '\n';
       
     try {
     data = msg.getBytes(encoding);
     } catch ( Exception e) {
      System.out.println("Client.send : Unsupported character set");
     }
     packet = new DatagramPacket( data, data.length, host, port ) ;
     sendPacket();
   }
   
   /*send integer from string*/
    void send2(String msg) {
      int number = Integer.parseInt(msg);

      byte[] data = new byte[] {
            (byte) (number >>> 24),
            (byte) (number >>> 16),
            (byte) (number >>> 8),
            (byte) (number)};
      packet = new DatagramPacket( data, data.length, host, port ) ;
      sendPacket();
    }
    
   /*send integer from int*/
    void send3(int number) {
      
      byte[] data = new byte[] {
            (byte) (number >>> 24),
            (byte) (number >>> 16),
            (byte) (number >>> 8),
            (byte) (number)};
      packet = new DatagramPacket( data, data.length, host, port ) ;
      sendPacket();
    }
    
   /*send string from int*/
    void send4(int number) {      
      send1(String.valueOf(number));
    }
    
  void sendPacket() {
      // Send it
      try {       
        socket.send( packet ) ;
      }  catch( Exception e ) {
        println( e ) ;
      }    
    
  }
   
  void close() {
      socket.close();
  }
  
    
}