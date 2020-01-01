void refreshLobbies(){
    lobbyClient.write("r\n");
    receiveLobbies();
}

void receiveLobbies(){
    selectedLobby = null;
    lobbies.clear();
    String current = receive();
    while(current != ""){
        lobbies.add(new GameLobby(current.split(",")));
        current = receive();
    }
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
    lobbyClient.write('n' + r + '\n');
    while(lobbyClient.available() == 0){
    }
    String success = lobbyClient.readString();
    if(success.equals("1")){
        hostError = "Lobby name matches existing lobby";
        return;
    }
    joinLobby(boxes[2].text);
    for(int i = 2; i < 7; i++){
        boxes[i].text = "";
    }
}

void joinLobby(String name){
    lobbyClient.write("j"+name+'\n');
    while(lobbyClient.available() == 0){
    }
    char c = lobbyClient.readChar();
    if(c == '0'){
        while(lobbyClient.available() == 0){
        }
        int index = Integer.parseInt(String.valueOf(lobbyClient.readChar()));
        receiveLobbies();
        for(GameLobby l : lobbies){
            if(name.equals(l.name)){
                currentGame = l;
                break;
            }
        }
        currentGame.index = index;
        setInGameStatus();
        
    }
}
