final int LOBBY_HEIGHT = 30;
final int MAX_CHAT_SIZE = 40;

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
    Button leaveButton, startButton;
    int index;
    StringList chat;
    int leader;
    boolean started;
    int cellSize;
    
    
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
        this.winner = 0;
        chat = new StringList();
        leader = 1;
        started = false;
        players = new String[maxP];
        startButton = makeStart();
        cellSize = (gridSpace-offset) / gridSize;
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
        if(index == this.leader && !started){
            this.startButton.active = true;
        }
        else{
            this.startButton.active = false;
        }
        displayStart();
        displayChat();
        displayInfo();
        displayPlayers();
        if(winner > 0){
            displayWinner();
        }
    }
    
    void displayGrid(){
        fill(0);
        background(255);
        //Format Setup
        textSize(cellSize);
        textAlign(CENTER,CENTER);
        //textAlign(CENTER);
        rectMode(CENTER);
        
        //for(int[] a : grid){
        //    for(int i : a){
        //        print(i," ");
        //     }
        //     print('\n');
        //}
        //println();
        
        for(int i = 0; i < gridSize; i++){
            for(int j = 0; j < gridSize; j++){
                //println(i,j,grid[i][j]);
                if(mode == 1){
                    text(symbols[this.grid[i][j]], j*cellSize + cellSize/2 + offset/2, i*cellSize + cellSize*4/10 + offset/2);
                }
                else if(mode == 2){
                    noStroke();
                    fill(colors[this.grid[i][j]]);
                    rect(j*cellSize + cellSize/2 + offset/2, i*cellSize + cellSize/2 + offset/2, cellSize, cellSize);
                }
            }
        }
        
        stroke(0);
        for(int i = 0; i <= gridSize; i++){
          line(cellSize * i + offset/2, offset/2, cellSize* i + offset/2, cellSize*gridSize + offset/2);
          line(offset/2, cellSize * i + offset/2, cellSize*gridSize + offset/2, cellSize * i + offset/2);
        }
    }
    
    void displayLeave(){
        leaveButton.display();
    }
    void displayStart(){
        if(startButton.active){
            startButton.display();
        }
    }
    
    void displayChat(){
        textAlign(LEFT);
        rectMode(CORNER);
        textSize(12);
        int h = 0;
        for(int i = chat.size()-1; i >= 0; i--){
            String m = chat.get(i);
            int c = 0;
            StringList lines = new StringList();
            while(c < m.length()-1){
                String cur = "";
                for(; c < m.length() && textWidth(cur+m.charAt(c)) < chatBox.w; c++){
                    cur += m.charAt(c);
                }
                lines.append(cur);
            }
            for(int s = lines.size()-1; s >= 0; s--){
                h++;
                text(lines.get(s), gridSpace + 5, height - chatBox.h - h*13 - 30, chatBox.w, height - chatBox.h - (h-1)*13 - 30);
            }
            
        }
    }
    
    void displayPlayers(){
        textAlign(LEFT);
        text("Players",gridSpace * 3 / 4, gridSpace + 10);
        textSize(12);
        for(int i = 0; i < maxPlayers; i++){
            if(mode == 1){
                drawName(players[i], symbols[i+1], gridSpace* 3 / 4, gridSpace + 30 + i*20);
            } else if(mode == 2){
                drawName(players[i], colors[i+1], gridSpace* 3 / 4, gridSpace + 30 + i*20);
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
        else if(mode == 1)
            currentPlayer = symbols[playerTurn];
        else{
            currentPlayer = "";
            rectMode(CENTER);
            fill(colors[playerTurn]);
            stroke(0);
            rect(textWidth("Current Player: ") + 15, gridSpace + 80, 10, 10);
        }
        fill(0);
        text("Current Player: " + currentPlayer, 10, gridSpace + 85);
        text("Status: " + ((started)?"Playing":"Waiting to begin"), 10, gridSpace + 100 );
    }
    
    void displayWinner(){
        textAlign(CENTER);
        textSize(18);
        fill(0);
        if(winner <= this.maxPlayers)
            text(symbols[this.winner] + " is the winner!", gridSpace*3/4, height - 10);
        else
            text("No more moves, tie game!", gridSpace*3/4, height - 10);
    }
    
    void leaveLobby(){
        if(currentGame != this) return;
        sendLeave();
        currentGame = null;
        setLobbyStatus();
    }
    
    void handleGridClick(){
        if(winner != 0) return;
        if(playerTurn != index) return;
        if(mouseX >= offset/2 && mouseX <= gridSpace-offset/2 && mouseY >= offset/2 && mouseY <= gridSpace-offset/2){
            int x = min((mouseX - offset/2)/cellSize,gridSize-1), y = min((mouseY - offset/2)/cellSize,gridSize-1);
            if(this.grid[y][x] != 0) 
                return;
            sendMove(y,x,index);
            playerTurn = 0;
        }
    }
    
    void handleServerMessage(String message){
        //println("Received from game:",message);
        char command = message.charAt(0);
        if(command == 'e'){ //End of Game
            while(lobbyClient.available() > 0)
                message = receive();
            joinError = "Host has left unstarted game";
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
            int y = Integer.parseInt(move[0]), x = Integer.parseInt(move[1]), ind = Integer.parseInt(move[2]);
            //println(y,x,"is now",ind);
            grid[y][x] = ind;
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
        text(name, x + 10, y+4);
}
void drawName(String name, String c, int x, int y){
    textSize(12);
    textAlign(LEFT);
    String nameText;
    if(name == null)
        nameText = c + ":";
    else 
        nameText = c + ":" + name;
    text(nameText, x, y);
}
