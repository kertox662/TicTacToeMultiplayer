void refreshLobbies(){ //Requests a refresh
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("r\n");
    receiveLobbies();
    lock.popFront();
}

void receiveLobbies(){ //Reads in lobbies from a refresh
    selectedLobby = null; //Reset selected
    lobbies.clear(); //Reset all lobbies
    String current = receive(); //Receive data, and until there's none left, add it to the list
    while(current != ""){
        lobbies.add(new GameLobby(current.split(",")));
        current = receive();
    }
    current = receive(); //For getting number of people online
    if(!current.equals(""))
        numPlayersOnline = Integer.parseInt(current);
    else
        numPlayersOnline = Integer.parseInt(receive());
}

void hostLobby(){
    hostError = ""; //Reset Host error
    StringList data = new StringList(); //Buffer for data in host boxes
    for(int i = 2; i < 7; i++){
        String dataPiece = boxes[i].text;
        if(dataPiece.equals("")){
            hostError = "Not all fields are filled in.\nPlease fill in all fields to host a game";
            return;
        }
        if(i > 2){
            try{
                int d = Integer.parseInt(dataPiece);
            }
            catch(NumberFormatException e){
                hostError = "Field that should have a number has text.";
                return;
            }
        }
        switch(i){ //Checks validity
            case 3:
                int mPlayer = Integer.parseInt(dataPiece);
                if(mPlayer < 2){
                    hostError = "Too Little Players, have at least 2";
                    return;
                } else if(mPlayer > 4){
                    hostError = "Too Many Players, have at most 4";
                    return;
                }
                break;
            case 4:
                int mode = Integer.parseInt(dataPiece);
                if(mode != 1 && mode != 2){
                    hostError = "Invalid Mode, choose 1 or 2";
                    return;
                }
                break;
            case 5:
                int gridSize = Integer.parseInt(dataPiece);
                if(gridSize < 3){
                    hostError = "Grid too small";
                    return;
                } else if(gridSize > 32){
                    hostError = "Grid too big";
                    return;
                }
                break;
            case 6:
                int target = Integer.parseInt(dataPiece);
                gridSize = Integer.parseInt(data.get(data.size()-1));
                if(target > gridSize){
                    hostError = "Target too big, make it smaller";
                    return;
                }
                break;
        }
        data.append(dataPiece);
    }
    //IF IT'S HERE, THE BOXES WERE VALID
    String r = join(data.array(),","); //Joins the data together into one string
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write('n' + r + '\n');
    while(lobbyClient.available() == 0){
    }
    String success = lobbyClient.readString(); //Gets success code of hosting a lobby
    println(success);
    if(success.equals("1")){ //If Lobby name already exists
        hostError = "Lobby name matches existing lobby";
        return;
    }
    lock.popFront();
    refreshLobbies(); //If valid, refresh
    joinLobby(boxes[2].text); //Join the new lobby
    for(int i = 2; i < 7; i++){ //update the TextBoxes
        boxes[i].text = "";
        boxes[i].curIndex = 0;
    }
}

void joinLobby(String name){ //Joins to the lobby with specified name
    if(selectedLobby != null && (selectedLobby.started || selectedLobby.isFull())){
        spectateGame(name);
        return;
    }
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("j"+name+'\n'); //Requests joining
    while(lobbyClient.available() == 0){
    }
    char c = lobbyClient.readChar(); //Success Code 
    joinError = "";
    if(c == '0'){ //If success
        while(lobbyClient.available() == 0){
        }
        int index = Integer.parseInt(String.valueOf(lobbyClient.readChar())); //Wait for your new index!
        receiveLobbies(); //Update lobby data
        for(GameLobby l : lobbies){ //Find the lobby that you just joined and set it as the current
            if(name.equals(l.name)){
                currentGame = l;
                l.index = index;
                break;
            }
        }
        lock.popFront();
        setInGameStatus(); //Sets variable for in game mode
        return;
    }
    lock.popFront();
    //Different errors that could happen
    if(c == '1'){
        joinError = "Lobby is full";
    }
    else if(c == '2'){
        joinError = "Game has started";
    }
    else if(c == '3'){
        joinError = "Lobby no longer exists";
    }
    refreshLobbies();
}

void spectateGame(String name){
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("o"+name+'\n'); //Requests Spectating
    while(lobbyClient.available() == 0){
    }
    char c = lobbyClient.readChar(); //Success Code 
    joinError = "";
    if(c == '0'){ //If success
        while(lobbyClient.available() == 0){
        }
        receiveLobbies(); //Update lobby data
        for(GameLobby l : lobbies){ //Find the lobby that you just joined and set it as the current
            if(name.equals(l.name)){
                currentGame = l;
                currentGame.isSpectator = true;
                break;
            }
        }
        setInGameStatus(); //Sets variable for in game mode
    }
    else{
        joinError = "Game no longer exists";
    }
    lock.popFront();
}

void sendStart(){ //Sends the start message to server
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("s"+lobbyName+"\n");
    lock.popFront();
}

void sendMessage(){ //Sends chat message
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("m" + lobbyName + ":" + chatBox.getText() + "\n");
    lock.popFront();
}

void sendMove(int y, int x, int index){ //Sends a move the you make
    println("SENDING MOVE", x,y,index);
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("p"+ y + "," + x + "," + index + "\n");
    lock.popFront();
}

void sendLeave(){ //Sends the fact that you're leaving
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("l" + lobbyName + '\n');
    String myLeaveMsg = receive();
    println("LEAVE:",myLeaveMsg);
    lock.popFront();
}

void sendReset(){ //Host sends a reset call
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("u" + lobbyName + "\n");
    lock.popFront();
}
