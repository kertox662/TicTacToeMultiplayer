void setLobbyStatus(){
    //Lobby Stuff
    inLobby = true;
    pixelsUp = 0;
    nameBox.active = false;
    refresh.active = true;
    joinLobby.active = true;
    hostButton.active = true;
    for(int i = 2; i < 6; i++){
        boxes[i].active = true;
    }
    //GameLobby Stuff
    inGameLobby = false;
    chatBox.active = false;
    refreshLobbies();
}

void setInGameStatus(){
    //Lobby Stuff
    inLobby = false;
    refresh.active = false;
    joinLobby.active = false;
    hostButton.active = false;
    for(int i = 2; i < 6; i++){
        boxes[i].active = false;
    }
    //GameLobby Stuff
    chatBox.active = true;
    inGameLobby = true;
    currentGame.leaveButton.active = true;
}
