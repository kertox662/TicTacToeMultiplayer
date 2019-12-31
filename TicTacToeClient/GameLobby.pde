final int LOBBY_HEIGHT = 30;

boolean inGameLobby = false;
TextBox chatBox = null;

ArrayList<GameLobby> lobbies;

void refreshLobbies(){
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
    println("Done Refreshing");
}

private class GameLobby{
    String name;
    int curPlayers, maxPlayers, playerTurn;
    int mode;
    int gridSize;
    int[][] grid;
    String[] players;
    
    GameLobby(String name, int curP, int maxP, int mode, int gridSize){
        this.name = name;
        this.curPlayers = curP;
        this.maxPlayers = maxP;
        this.mode = mode;
        this.gridSize = gridSize;
    }
    
    GameLobby(String[] info){
        this(info[0], Integer.parseInt(info[1]), Integer.parseInt(info[2]),Integer.parseInt(info[3]),Integer.parseInt(info[4]));
    }
    
    void displayInfo(int index){
        stroke(0);
        noFill();
        rectMode(CORNER);
        rect(offset/2, index * LOBBY_HEIGHT - pixelsUp, gridSpace - offset, LOBBY_HEIGHT);
        
        fill(0);
        textAlign(LEFT, CENTER);
        textSize(16);
        text(this.name, offset/2 + 10, index*LOBBY_HEIGHT + LOBBY_HEIGHT/2 - pixelsUp);
        String info = "";
        info += this.curPlayers + "/" + this.maxPlayers + "      " + gridSize + "x" + gridSize + " " + mode;
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
