import java.net.* ;
import java.nio.* ;

class Client {
  private DatagramSocket socket;
  private InetAddress host;
  private int port;
  private DatagramPacket packet;
  private byte[] data;
  private int sendType = 1;
  private String encoding = "UTF-8";
  private boolean appendNewLineChar = false;   
  private int intMsg;
  private String strMsg;
  private boolean fixedMsg = false;

  Client(String hostname) { 

    try {
      host = InetAddress.getByName(hostname);
      socket = new DatagramSocket() ;
    } 
    catch( Exception e )
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
    case 5:
      send5();
      break;
    default: 
      break;
    }
  }

  /*send string*/
  void send1(String msg) {
    if (appendNewLineChar)
      msg += '\n';

    try {
      data = msg.getBytes(encoding);
    } 
    catch ( Exception e) {
      System.out.println("Client.send : Unsupported character set");
    }
    packet = new DatagramPacket( data, data.length, host, port ) ;
    sendPacket();
  }

  /*send integer from string (e.g. string read from params file)*/
  void send2(String msg) {
    int number = Integer.parseInt(msg);
    //send single uint8 byte*
    byte data[] = new byte[1];
    data[0] = (byte) (number & 0xFF);
    packet = new DatagramPacket( data, data.length, host, port ) ;
    sendPacket();  
    //send 4-byte int
    //byte[] data = new byte[] {
    //  (byte) (number >>> 24), 
    //  (byte) (number >>> 16), 
    //  (byte) (number >>> 8), 
    //  (byte) (number)};
    //packet = new DatagramPacket( data, data.length, host, port ) ;
    //sendPacket();
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
  
  /*append date & time to fixed msg prefix*/
  void send5() {
    int sec = second(); int min = minute(); int h = hour();
    String now = String.format("%s_%s_%02d%02d%02d",strMsg,today,h,min,sec);
    send1(now);
  }

  void sendPacket() {
    // Send it
    try {       
      socket.send( packet ) ;
    }  
    catch( Exception e ) {
      println( e ) ;
    }
  }

  void close() {
    socket.close();
  }
}
