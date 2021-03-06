TextBox nameBox = null;
String serverError = "", hostError = "", joinError = "";

int pixelsUp = 0;

int numPlayersOnline = 0;

void drawNameBox(){ //Draws the name box and labels
    textSize(16);
    textAlign(CENTER);
    text(serverError, width/2, height - 50);
    text("Type a username in the box:",width/2, height/2-50);
    text("Press ENTER to submit and attempt to connect to server!", width/2, height/2+50);
    nameBox.display();
}

void drawHostBoxes(){ //Draws all of the hosting textBoxes and respective labels
    fill(0);
    textSize(24);
    textAlign(CENTER);
    text("HOST GAME", boxes[2].x + boxes[2].w/2, boxes[2].y/2);
    textSize(14);
    String [] labels = {"Lobby Name", "Max Players (Min 2, Max 4)", "Mode (1 for Characters, 2 for colors)", "GridSize (Min 3, Max 32)", "Number to connect"};
    for(int i = 2; i < 7; i++){
        boxes[i].display();
        textAlign(CENTER);
        text(labels[i-2], boxes[i].x + boxes[i].w/2, boxes[i].y - 8);
    }
}

void drawHostError(){ //Draws the host error if it exists
    fill(220, 20,20);
    stroke(220, 20,20);
    textSize(12);
    textAlign(CENTER,CENTER);
    if(!hostError.equals("")){
        text("Hosting Error:", boxes[2].x + boxes[2].w/2, boxes[2].y + 45*6 - 27);
        text(hostError, boxes[2].x + boxes[2].w/2, boxes[2].y + 45*6);
    }
}

void drawLobbyButtons(){ //Draws all of the lobby buttons
    refresh.display();
    hostButton.display();
    if(selectedLobby == null || (!selectedLobby.started && !selectedLobby.isFull())){
        joinLobby.text = "Join!";
    } else{
        joinLobby.text = "Spectate!";
    }
    joinLobby.display();
}

void drawUserName(){ //Draws the client's username in the bottom right
    String s = "Logged in as " + lobbyName;
    fill(0);
    textSize(16);
    textAlign(RIGHT);
    text(s, width - 6, height - 6);
}

void drawJoinError(){ //Draws the join error if it exists
    fill(220, 20,20);
    stroke(220, 20,20);
    textSize(12);
    textAlign(CENTER,CENTER);
    if(!joinError.equals("")){
        text("Error While Joining:", joinLobby.x + joinLobby.w/2, joinLobby.y + 25);
        text(joinError, joinLobby.x + joinLobby.w/2, joinLobby.y + 40);
    }
}

void drawAmountOnline(){ //Draws how many players were online the last time you refreshed
    fill(0);
    textAlign(RIGHT);
    textSize(16);
    text(Integer.toString(numPlayersOnline) + " Players Online", width-6,height-20);
}
