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
    StringList chat;
    int leader;
    boolean started;
    
    
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
        chat = new StringList();
        leader = 1;
        started = false;
        players = new String[maxP];
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
        displayInfo();
        displayPlayers();
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
        textAlign(LEFT,BOTTOM);
        textSize(12);
        int h = 0;
        for(int i = chat.size()-1; i >= 0; i--){
            String m = chat.get(i);
            h += ceil(textWidth(m) / chatBox.w);
            text(m, gridSpace + 5, height - chatBox.h - h*13 - 5);
        }
    }
    
    void displayPlayers(){
        textAlign(CENTER);
        text("Players",gridSpace/2, gridSpace + 10);
        textSize(12);
        for(int i = 0; i < maxPlayers; i++){
            if(mode == 1){
                drawName(players[i], symbols[i+1], gridSpace/2, gridSpace + 30 + i*20);
            } else if(mode == 2){
                drawName(players[i], colors[i+1], gridSpace/2, gridSpace + 30 + i*20);
            }
        }
    }
    
    void displayInfo(){
        textAlign(10);
        textAlign(LEFT);
        text("Lobby: " + this.name, 10, gridSpace + 40);
        text("Connect: " + this.target, 10, gridSpace + 55);
        text("Size: " + this.gridSize + "x" + this.gridSize, 10, gridSpace + 70);
        String currentPlayer;
        if(!started)
            currentPlayer = "N/A";
        else
            currentPlayer = symbols[playerTurn];
        text("Current Player: " + currentPlayer, 10, gridSpace + 85);
        text("Status: " + ((started)?"Playing":"Waiting to begin"), 10, gridSpace + 100 );
    }
    
    void leaveLobby(){
        if(currentGame != this) return;
        lobbyClient.write("l" + lobbyName + '\n');
        currentGame = null;
        if(index == 1){
            String myLeaveMessage = receive();
            println("Leave Message:", myLeaveMessage);
        }
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
            playerTurn = 0;
        }
    }
    
    void handleServerMessage(String message){
        println("Received from game:",message);
        char command = message.charAt(0);
        if(command == 'e'){ //End of Game
            while(lobbyClient.available() > 0)
                message = receive();
            setLobbyStatus();
        }
        else if(command == 'm'){ //Chat Message
            chat.append(message.substring(1));
            if(chat.size() > MAX_CHAT_SIZE){
                chat.remove(0);
            }
        }
        else if(command == 'n'){ //New Leader
            this.leader = Integer.parseInt(message.substring(1));
        }
        else if(command == 'l'){ //Player Leave
            String playerName = message.substring(1);
            for(int i = 0; i < maxPlayers; i++){
                if(playerName.equals(players[i])){
                    players[i] = "";
                    break;
                }
            }
        }
        else if(command == 'p'){ //Player Move
            String[] move = message.substring(1).split(",");
            int y = Integer.parseInt(move[0]), x = Integer.parseInt(move[1]);
            grid[y][x] = playerTurn;
        }
        else if(command == 'w'){ //Winner Declared
            winner = Integer.parseInt(message.substring(1));
        }
        else if(command == 'j'){ //Player Join
            String[] info = message.substring(1).split(",");
            String playerName = info[0];
            int index = Integer.parseInt(info[1]);
            players[index] = playerName;
        }
        else if(command == 't'){ //Player Turn
            playerTurn = Integer.parseInt(message.substring(1));
        }
        else if(command == 's'){ //Start of Game
            started = true;
        }
    }
}

void drawName(String name, color c, int x, int y){
    stroke(0);
    fill(c);
    rectMode(CENTER);
    textSize(12);
    textAlign(LEFT);
    rect(x,y,12,12);
    if(name != null)
        text(name, x + 10, y);
}
void drawName(String name, String c, int x, int y){
    textSize(12);
    textAlign(CENTER);
    String nameText;
    if(name == null)
        nameText = c + ":";
    else 
        nameText = c + ":" + name;
    text(nameText, x, y);
}
