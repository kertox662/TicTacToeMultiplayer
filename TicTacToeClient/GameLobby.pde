final int LOBBY_HEIGHT = 30;
final int MAX_CHAT_SIZE = 20;

boolean inGameLobby = false;
TextBox chatBox = null;

ArrayList<GameLobby> lobbies;
GameLobby selectedLobby = null, currentGame = null;

int[] limits = {};

private class GameLobby{
    String name;
    int curPlayers, maxPlayers, playerTurn, winner;
    int mode;
    int gridSize, target;
    int[][] grid;
    String[] players;
    boolean selected;
    Button leaveButton;
    int index;
    String[] chat;
    
    
    GameLobby(String name, int curP, int maxP, int mode, int gridSize, int target){
        this.name = name;
        this.curPlayers = curP;
        this.maxPlayers = maxP;
        this.mode = mode;
        this.gridSize = gridSize;
        this.grid = new int[gridSize][gridSize];
        this.selected = false;
        this.target = target;
        this.leaveButton = makeLeave();
        this.index = -1;
        this.winner = -1;
        chat = new String[MAX_CHAT_SIZE];
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
    
    void display(){
        displayGrid();
        displayLeave();
        displayChat();
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
    
    void displayLeave(){
        leaveButton.display();
    }
    
    void displayChat(){
    }
    
    void leaveLobby(){
        if(currentGame != this) return;
        lobbyClient.write("l" + lobbyName + '\n');
        currentGame = null;
        String myLeaveMessage = receive();
        setLobbyStatus();
    }
    
    void handleGridClick(){
        if(winner != 0) return;
        if(playerTurn != index) return;
        if(mouseX >= offset/2 && mouseX <= gridSpace-offset/2 && mouseY >= offset/2 && mouseY <= gridSpace-offset/2){
            int x = (mouseX - offset/2)/cellSize, y = (mouseY - offset/2)/cellSize;
            if(grid[y][x] != 0) 
                return;
            grid[y][x] = index;
            if(checkWinner(y,x)){
                winner = index;
                if(mode == 1)
                    println("Player",winner,"playing", symbols[winner] ,"Wins!");
                else 
                    println("Player",winner,"playing", colorNames[winner] ,"Wins!");
            };
            playerTurn = 0;
        }
    }
    
    void handleServerMessage(String message){
    }
}
