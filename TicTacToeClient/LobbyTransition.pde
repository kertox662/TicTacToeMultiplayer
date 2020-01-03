void setLobbyStatus(){ //Sets variables for lobby mode
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
    currentGame = null;
    chatBox.active = false;
    refreshLobbies();
    showLastMove = false;
}

void setInGameStatus(){ //Sets variables for gaming mode
    //Lobby Stuff
    inLobby = false;
    refresh.active = false;
    joinLobby.active = false;
    hostButton.active = false;
    hostButton.framesClicked = 0;
    joinLobby.framesClicked = 0;
    refresh.framesClicked = 0;
    for(int i = 2; i < 6; i++){
        boxes[i].active = false;
    }
    //GameLobby Stuff
    chatBox.active = true;
    inGameLobby = true;
    currentGame.leaveButton.active = true;
    currentGame.leaveButton.framesClicked = 0;
    showLastMove = false;
}
