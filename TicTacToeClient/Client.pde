Client lobbyClient = null;
long timeout = 10000;
boolean inLobby = false;
String lobbyName;


Client connectMain(String name){
    Client client = new Client(this, IP, PORT);
    client.write(name+"\n");
    String acceptance = "";
    long timeWentBy = System.currentTimeMillis();
    while(acceptance.equals("") && System.currentTimeMillis() - timeWentBy < timeout){
        if(client.available() > 0){
            acceptance = client.readString();
        }
    }
    if(System.currentTimeMillis() - timeWentBy >= timeout){
        serverError = "Could not connect to server: Connect Timed Out.";
        client.stop();
        return null;
    }
    if(acceptance.equals("1")){
        serverError = "Could not connect to server: Username Taken.";
        client.stop();
        return null;
    }
    else if(acceptance.equals("2")){
        serverError = "Could not connect to server: Server Full.";
        client.stop();
        return null;
    }
    return client;
}

String receive(){
    String message = "";
    while(true){
        if(lobbyClient.available() == 0) continue;
        char next = lobbyClient.readChar();
        if(next == '\n') break;
        message += next;
    }
    println("RECEIVED:", message);
    return message;
}
