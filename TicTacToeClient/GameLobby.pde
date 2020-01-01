final int LOBBY_HEIGHT = 30;

boolean inGameLobby = false;
TextBox chatBox = null;

ArrayList<GameLobby> lobbies;
GameLobby selectedLobby = null;

int[] limits = {};

void refreshLobbies(){
    selectedLobby = null;
    lobbies.clear();
    lobbyClient.write("r\n");
    int numEnd = 0;
    char nextChar;
    String current = "";
    while(numEnd != 2){
        if(lobbyClient.available() == 0) continue;
        nextChar = lobbyClient.readChar();
        if(nextChar == '\n'){
            if(!current.equals("")){
                lobbies.add(new GameLobby(current.split(",")));
                current = "";
            }
            numEnd++;
        }
        else{
            numEnd = 0;
            current+=nextChar;
        }
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
    for(int i = 2; i < 7; i++){
        boxes[i].text = "";
    }
    refreshLobbies();
    joinLobby(boxes[2].text);
}

void joinLobby(String name){

}

private class GameLobby{
    String name;
    int curPlayers, maxPlayers, playerTurn;
    int mode;
    int gridSize, target;
    int[][] grid;
    String[] players;
    boolean selected;
    
    GameLobby(String name, int curP, int maxP, int mode, int gridSize, int target){
        this.name = name;
        this.curPlayers = curP;
        this.maxPlayers = maxP;
        this.mode = mode;
        this.gridSize = gridSize;
        this.selected = false;
        this.target = target;
    }
    
    GameLobby(String[] info){
        this(info[0], Integer.parseInt(info[1]), Integer.parseInt(info[2]),Integer.parseInt(info[3]),Integer.parseInt(info[4]), Integer.parseInt(info[5]));
    }
    
    void displayInfo(int index){
        //if((index+1)*LOBBY_HEIGHT - pixelsUp > gridSpace-offset/2) return;
        stroke(0);
        noFill();
        if(selected)
            fill(39, 174, 96);
        rectMode(CORNER);
        rect(offset/2, index * LOBBY_HEIGHT - pixelsUp, gridSpace - offset, LOBBY_HEIGHT);
        
        fill(0);
        textAlign(LEFT, CENTER);
        textSize(16);
        text(this.name, offset/2 + 10, index*LOBBY_HEIGHT + LOBBY_HEIGHT/2 - pixelsUp);
        textSize(10);
        text(this.curPlayers + "/" + this.maxPlayers + " players", offset/2 + 200, index*LOBBY_HEIGHT + LOBBY_HEIGHT/2 - pixelsUp);
        String info = "";
        info += gridSize + "x" + gridSize + " Connect:" + target + " Mode:" + mode;
        textAlign(RIGHT, CENTER);
        text(info, gridSpace - offset/2 - 10, index*LOBBY_HEIGHT + LOBBY_HEIGHT/2 - pixelsUp);
        
    }
    
    void displayGrid(){
        fill(0);
        background(255);
        //Format Setup
        textSize(cellSize);
        textAlign(CENTER,CENTER);
        rectMode(CENTER);
        
        for(int i = 0; i < gridSize; i++){
            for(int j = 0; j < gridSize; j++){
                if(mode == 1){
                    text(symbols[grid[i][j]], j*cellSize + cellSize/2 + offset/2, i*cellSize + cellSize*4/10 + offset/2);
                }
                else if(mode == 2){
                    noStroke();
                    fill(colors[grid[i][j]]);
                    rect(j*cellSize + cellSize/2 + offset/2, i*cellSize + cellSize/2 + offset/2, cellSize, cellSize);
                }
            }
        }
        
        stroke(0);
        for(int i = 0; i <= gridSize; i++){
          line((gridSpace-offset) * i / gridSize + offset/2, offset/2, (gridSpace-offset) * i / gridSize + offset/2, gridSpace-offset/2);
          line(offset/2, (gridSpace-offset) * i / gridSize + offset/2, gridSpace-offset/2, (gridSpace-offset) * i / gridSize + offset/2);
        }
    }
}
