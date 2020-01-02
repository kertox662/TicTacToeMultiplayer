Client lobbyClient = null; //Client Object
long timeout = 10000; //10s timeout on first response
boolean inLobby = false;
String lobbyName; //Client name that is selected


Client connectMain(String name){
    Client client = new Client(this, IP, PORT); //Connects to server
    client.write(name+"\n"); //Sends request
    String acceptance = "";
    long timeWentBy = System.currentTimeMillis();
    while(acceptance.equals("") && System.currentTimeMillis() - timeWentBy < timeout){ //Waiting for response with timeout in mind
        if(client.available() > 0){
            acceptance = client.readString();
        }
    }
    if(System.currentTimeMillis() - timeWentBy >= timeout){ //If timed out, stop
        serverError = "Could not connect to server: Connect Timed Out.";
        client.stop();
        return null;
    }
    if(acceptance.equals("1")){ //Error, someone already has the username
        serverError = "Could not connect to server: Username Taken.";
        client.stop();
        return null;
    }
    else if(acceptance.equals("2")){ //Error, server too full (DEPRECATED)
        serverError = "Could not connect to server: Server Full.";
        client.stop();
        return null;
    }
    return client;
}

String receive(){ //Gets the next string up to '\n'
    String message = "";
    while(true){
        if(lobbyClient.available() == 0) continue; //If buffer empty, wait some more
        char next = lobbyClient.readChar(); //Read in character and add to string
        if(next == '\n') break;//If '\n', you're done
        message += next;
    }
    //println("RECEIVED:", message);
    return message;
}
