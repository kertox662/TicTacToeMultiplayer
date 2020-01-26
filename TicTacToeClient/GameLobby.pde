final int LOBBY_HEIGHT = 30; //How tall each lobby display is
final int MAX_CHAT_SIZE = 40; //How long the chat length can be (really doesn't matter, can be as tall as possible, but may slow down if too big)

boolean inGameLobby = false;
TextBox chatBox = null;

ArrayList<GameLobby> lobbies; //Store Lobby Objects
GameLobby selectedLobby = null, currentGame = null;

boolean showLastMove = false;

private class GameLobby{
    String name; //Lobby Display and connection name
    int curPlayers, maxPlayers, playerTurn, winner; //PlayerTurn and Winner are Player indices
    int mode; //1 or 2 (1 for characters like X and O, 2 for Coloured squares)
    int gridSize, target; //Target is the amount you need to connect
    int[][] grid;
    String[] players; //Player names
    boolean selected;
    Button leaveButton, startButton, resetButton;
    int index;
    StringList chat;
    int leader; //The leader of the lobby, really only matters if this client is the leader
    boolean started;
    int cellSize;
    boolean isSpectator;
    int spectators;
    int[] lastMove;
    
    
    GameLobby(String name, int curP, int maxP, int mode, int gridSize, int target, boolean isStarted){
        this.name = name;
        this.curPlayers = curP;
        this.maxPlayers = maxP;
        this.playerTurn = 0;
        this.mode = mode;
        this.gridSize = gridSize;
        this.grid = new int[gridSize][gridSize];
        this.selected = false;
        this.target = target;
        this.leaveButton = makeLeave();
        this.index = -100;
        this.winner = 0;
        this.chat = new StringList();
        this.leader = 1;
        this.started = isStarted;
        this.players = new String[maxP];
        this.startButton = makeStart();
        this.resetButton = makeReset();
        this.cellSize = (gridSpace-offset) / gridSize;
        this.isSpectator = false;
        this.spectators = 0;
        this.lastMove = new int[2];
        lastMove[0] = lastMove[1] = -50;
    }
    
    GameLobby(String[] info){//Lobby from String
        this(info[0], Integer.parseInt(info[1]), //Current Players
                      Integer.parseInt(info[2]), //Max Players
                      Integer.parseInt(info[3]), //Mode
                      Integer.parseInt(info[4]), //Size
                      Integer.parseInt(info[5]), //Connect
                      ((info[6].equals("1"))?true:false) ); //Is it started
    }
    
    void reset(){//Resets all aspects that are required for a new game
        this.grid = new int[gridSize][gridSize];
        this.winner = 0;
        started = false;
        this.playerTurn = 0;
        lastMove[0] = lastMove[1] = -50;
    }
    
    boolean isFull(){
        return curPlayers >= maxPlayers;
    }
    
    void displayInfo(int index){ //Displays the information about the lobby in main Lobby
        stroke(0);
        noFill();
        if(selected)
            fill(39, 174, 96);
        rectMode(CORNER);
        //println(name, started);
        if(started){
            fill(colors[1]);
            if(selected)
                stroke(colors[4]);
        }
        rect(offset/2, index * LOBBY_HEIGHT - pixelsUp, gridSpace - offset, LOBBY_HEIGHT); //Draws the rectangle
        fill(0);
        stroke(0);
        textAlign(LEFT, CENTER);
        textSize(16);
        text(this.name, offset/2 + 10, index*LOBBY_HEIGHT + LOBBY_HEIGHT/2 - pixelsUp); //Displays Name
        textSize(10);
        //Displays Player Status
        text(this.curPlayers + "/" + this.maxPlayers + " players", offset/2 + 200, index*LOBBY_HEIGHT + LOBBY_HEIGHT/2 - pixelsUp); 
        String info = "";
        info += gridSize + "x" + gridSize + " Connect:" + target + " Mode:" + mode;
        textAlign(RIGHT, CENTER);
        text(info, gridSpace - offset/2 - 10, index*LOBBY_HEIGHT + LOBBY_HEIGHT/2 - pixelsUp); //Displays the rest of the info
        
    }
    
    void display(){ //Game Lobby Display
        //println(isSpectator);
        displayGrid();
        displayLeave();
        if(index == this.leader && !started){
            this.startButton.active = true;
        }
        else{
            this.startButton.active = false;
        }
        if(index == this.leader && winner > 0){
            this.resetButton.active = true;
        }
        else{
            this.resetButton.active = false;
        }
        
        displayStart();
        displayReset();
        displayChat();
        displayInfo();
        displayPlayers();
        if(spectators > 0){
            displaySpectators();
        }
        if(winner > 0){
            displayWinner();
        }
    }
    
    void displayGrid(){//Draws the grid and the symbols/colors
        fill(0);
        background(255);
        textSize(cellSize);
        textAlign(CENTER,CENTER);
        rectMode(CENTER);
        
        for(int i = 0; i < gridSize; i++){
            for(int j = 0; j < gridSize; j++){
                if(mode == 1){ //Symbol Mode
                    text(symbols[this.grid[i][j]], j*cellSize + cellSize/2 + offset/2, i*cellSize + cellSize*4/10 + offset/2);
                }
                else if(mode == 2){//Color Mode
                    noStroke();
                    rectMode(CORNER);
                    fill(colors[this.grid[i][j]]);
                    rect(j*cellSize + offset/2, i*cellSize + offset/2, cellSize, cellSize);
                }
            }
        }
        
        stroke(0);
        //Draws gridlines
        for(int i = 0; i <= gridSize; i++){
          line(cellSize * i + offset/2, offset/2, cellSize* i + offset/2, cellSize*gridSize + offset/2);
          line(offset/2, cellSize * i + offset/2, cellSize*gridSize + offset/2, cellSize * i + offset/2);
        }
        
        displayLastMove();
    }
    
    void displayLastMove(){
        if(!showLastMove) return;
        if(mode == 1){
            stroke(colors[4]);
            strokeWeight(2);
        }
        else{
            if(gridSize < 10)
                strokeWeight(4);
            else
                strokeWeight(3);
        }
        noFill();
        rectMode(CORNER);
        rect(lastMove[1] * cellSize + offset/2, lastMove[0]*cellSize + offset/2, cellSize, cellSize);
        strokeWeight(1);
    }
    
    void displayLeave(){ //Leave Button
        leaveButton.display();
    }
    void displayStart(){//Start Button
        if(startButton.active){
            startButton.display();
        }
    }
    void displayReset(){//Reset Button
        if(resetButton.active){
            resetButton.display();
        }
    }
    
    void displayChatLegacy(){//OLD WAY OF DISPLAYING CHAT, DEPRECATED
        textAlign(LEFT);
        rectMode(CORNER);
        textSize(12);
        int h = 0;
        for(int i = chat.size()-1; i >= 0; i--){//For each chat message in reverse
            String m = chat.get(i);
            int c = 0;
            StringList lines = new StringList();
            while(c < m.length()-1){ //Split the string up into strings with lengths smaller than the width of the chat
                String cur = "";
                for(; c < m.length() && textWidth(cur+m.charAt(c)) < chatBox.w; c++){
                    cur += m.charAt(c);
                }
                lines.append(cur);
            }
            for(int s = lines.size()-1; s >= 0; s--){ //Display them in reverse so they some out in the right order
                h++;
                text(lines.get(s), gridSpace + 5, height - chatBox.h - h*13 - 30, chatBox.w, height - chatBox.h - (h-1)*13 - 30);
            }
            
        }
    }
    
    void displayChat(){//Displays Chat
        textAlign(LEFT);
        rectMode(CORNER);
        textSize(12);
        int h = 0;
        for(int i = chat.size()-1; i >= 0; i--){//For each chat message in reverse
            String m = chat.get(i);
            String[] words = m.split(" ");
            StringList lines = new StringList();
            String cur = "";
            for(int ind = 0; ind < words.length;){
                if(textWidth(words[ind]+cur + " ") <= chatBox.w){
                    if(!cur.equals(""))
                        cur += " ";
                    cur += words[ind];
                    ind++;
                }else if(textWidth(words[ind]) > chatBox.w){
                    if(!cur.equals("")){
                        lines.append(cur);
                    }
                    cur = "";
                    for(int c = 0; c < words[ind].length();c++){
                        if(textWidth(cur+words[ind].charAt(c)) > chatBox.w){
                            lines.append(cur);
                            words[ind] = words[ind].substring(c);
                            cur = "";
                            break;
                        } else{
                            cur += words[ind].charAt(c);
                        }
                    }
                }
                else if(textWidth(words[ind] + cur + " ") > chatBox.w){
                    if(!cur.equals(""))
                        lines.append(cur);
                    cur = words[ind];
                    ind++;
                }
            }
            if(!cur.equals(""))
                lines.append(cur);
            for(int s = lines.size()-1; s >= 0; s--){ //Display them in reverse so they some out in the right order
                h++;
                text(lines.get(s), gridSpace + 5, height - chatBox.h * chatBox.numLines - h*13 - 10, chatBox.w, height);
            }
            
        }
    }
    
    void displayPlayers(){ //Displays the player names and their corresponding characters/colors
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
    
    void displaySpectators(){
        textAlign(LEFT);
        textSize(12);
        fill(0);
        text("Spectators:" + spectators, gridSpace* 3 / 4, gridSpace + 30 + maxPlayers*20);
    }
    
    void displayInfo(){//Displays in game lobby info on the bottom left
        textAlign(10);
        textAlign(LEFT);
        text("Lobby: " + this.name, 10, gridSpace + 40);
        text("Connect: " + this.target, 10, gridSpace + 55);
        text("Size: " + this.gridSize + "x" + this.gridSize, 10, gridSpace + 70);
        String currentPlayer;
        if(!started || playerTurn == 0) //If the game hasn't started, no current player
            currentPlayer = "N/A";
        else if(mode == 1) //Otherwise show symbol or colored box
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
        text("Status: " + ((started)?"Playing":"Waiting to begin"), 10, gridSpace + 100 ); //Status of game, either waiting or started
    }
    
    void displayWinner(){//Displays the Winning character or color
        textAlign(CENTER);
        textSize(18);
        fill(0);
        if(winner <= this.maxPlayers){
            if(mode == 1)
                text(symbols[this.winner] + " is the winner!", gridSpace*3/4, height - 10);
            else if(mode == 2)
                text(colorNames[this.winner] + " is the winner!", gridSpace*3/4, height - 10);
        }
        else
            text("No more moves, tie game!", gridSpace*3/4, height - 10);
    }
    
    void leaveLobby(){ //Leaves the current game and goes back to the main lobby
        if(currentGame != this) return;
        inGameLobby = false;
        sendLeave();
        currentGame = null;
        setLobbyStatus(); //Updates to lobby status
    }
    
    void handleGridClick(){//Checks which index is clicked and sends that move if the client is the current player
        if(winner != 0) return; //If winner exists, then no more moves can be done
        if(playerTurn != index) return; //Can only play on their turn
        if(mouseX >= offset/2 && mouseX <= gridSpace-offset/2 && mouseY >= offset/2 && mouseY <= gridSpace-offset/2){
            int x = min((mouseX - offset/2)/cellSize,gridSize-1), y = min((mouseY - offset/2)/cellSize,gridSize-1);
            if(this.grid[y][x] != 0) //If the square already has something, it is an invalid click
                return;
            sendMove(y,x,index);
            playerTurn = 0; //Temporary since you'd be able to send multiple in
        }
    }
    
    void handleServerMessage(String message){
        //println("Received from game:",message);
        char command = message.charAt(0); //The first character of a message describes what the following data means (Could technically expand to more characters if required)
        if(command == 'e'){ //End of Game (Only an unstarted game)
            while(lobbyClient.available() > 0)
                message = receive(); //Takes care of all of the buffer backlog
            joinError = "Empty for too long";
            setLobbyStatus(); //Go to lobby
        }
        else if(command == 'm'){ //Chat Message -> add to chat list
            String msg = message.substring(1);
            chat.append(msg);
            if(chat.size() > MAX_CHAT_SIZE){
                chat.remove(0);
            }
            if(!msg.endsWith("Starting the game") && !msg.endsWith("has joined the lobby") && !msg.endsWith("has left the lobby"))
                thread("playMessage");
        }
        else if(command == 'n'){ //New Leader -> set leader
            this.leader = Integer.parseInt(message.substring(1));
        }
        else if(command == 'l'){ //Player Leave -> Remove player from list
            thread("playLeave");
            String playerName = message.substring(1);
            for(int i = 0; i < maxPlayers; i++){
                if(playerName.equals(players[i])){
                    players[i] = "";
                    break;
                }
            }
        }
        else if(command == 'p'){ //Player Move -> update grid
            thread("playMove");
            String[] move = message.substring(1).split(",");
            int y = Integer.parseInt(move[0]), x = Integer.parseInt(move[1]), ind = Integer.parseInt(move[2]);
            //println(y,x,"is now",ind);
            grid[y][x] = ind;
            lastMove[0] = y;
            lastMove[1] = x;
        }
        else if(command == 'w'){ //Winner Declared -> update winner
            winner = Integer.parseInt(message.substring(1));
            thread("playWin");
        }
        else if(command == 'j'){ //Player Join -> update player list
            thread("playJoin");
            String[] info = message.substring(1).split(",");
            String playerName = info[0];
            int index = Integer.parseInt(info[1]);
            players[index] = playerName;
        }
        else if(command == 't'){ //Player Turn -> update turn
            playerTurn = Integer.parseInt(message.substring(1));
        }
        else if(command == 's'){ //Start of Game -> set game to be started
            thread("playStart");
            started = true;
        }
        else if(command == 'u'){ //Reset game
            reset();
        }
        else if(command == 'o'){ //Reset game
            spectators = Integer.parseInt(message.substring(1));
        }
    }
}


//Draws name with either a certain color or symbol at a location
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
