void refreshLobbies(){
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("r\n");
    receiveLobbies();
    lock.popFront();
}

void receiveLobbies(){
    selectedLobby = null;
    lobbies.clear();
    String current = receive();
    while(current != ""){
        lobbies.add(new GameLobby(current.split(",")));
        current = receive();
    }
    current = receive();
    if(!current.equals(""))
        numPlayersOnline = Integer.parseInt(current);
    else
        numPlayersOnline = Integer.parseInt(receive());
}

void hostLobby(){
    hostError = "";
    ArrayList<String> data = new ArrayList<String>();
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
        switch(i){
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
        data.add(dataPiece);
    }
    String r = "";
    for(int i = 0; i < data.size(); i++){
        r += data.get(i);
        if(i < data.size()-1) r += ',';
    }
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write('n' + r + '\n');
    while(lobbyClient.available() == 0){
    }
    String success = lobbyClient.readString();
    println(success);
    if(success.equals("1")){
        hostError = "Lobby name matches existing lobby";
        return;
    }
    lock.popFront();
    refreshLobbies();
    joinLobby(boxes[2].text);
    for(int i = 2; i < 7; i++){
        boxes[i].text = "";
        boxes[i].curIndex = 0;
    }
}

void joinLobby(String name){
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("j"+name+'\n');
    while(lobbyClient.available() == 0){
    }
    char c = lobbyClient.readChar();
    joinError = "";
    if(c == '0'){
        while(lobbyClient.available() == 0){
        }
        int index = Integer.parseInt(String.valueOf(lobbyClient.readChar()));
        receiveLobbies();
        for(GameLobby l : lobbies){
            if(name.equals(l.name)){
                currentGame = l;
                l.index = index;
                break;
            }
        }
        lock.popFront();
        setInGameStatus();
        return;
    }
    lock.popFront();
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

void sendStart(){
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("s"+lobbyName+"\n");
    lock.popFront();
}

void sendMessage(){
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("m" + lobbyName + ":" + chatBox.getText() + "\n");
    lock.popFront();
}

void sendMove(int y, int x, int index){
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("p"+ y + "," + x + "," + index + "\n");
    lock.popFront();
}

void sendLeave(){
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("l" + lobbyName + '\n');
    lock.popFront();
}

void sendReset(){
    long timeStamp = System.nanoTime();
    lock.addAccess(timeStamp);
    while(lock.peekFront() != timeStamp){
        //Pass
    }
    lobbyClient.write("u" + lobbyName + "\n");
    lock.popFront();
}
