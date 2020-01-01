import processing.net.*;

final int MAX_PLAYERS = 4;
final int MAX_GRID = 32;
final int gridSpace = 520;

final String[] symbols = {"","X","O","\u25b2", "\u25C6"};
final color[] colors = {color(255),color(231, 76, 60), color(52, 152, 219), color(46, 204, 113), color(247, 220, 111)};
final String[] colorNames = {"", "Red", "Blue", "Green", "Yellow"};

int gridSize = 32, offset = 40, cellSize;
int target = 4;
int[][] grid;

int playerTurn = 1, numPlayers = 2;
int mode = 1; //1 = Character, 2 = Color
int winner = 0;

String status = "unconnected";

GameLobby curGame = null;

void settings(){
    //Window Setup
    size(800,640);
    pixelDensity(displayDensity());
}

void setup(){
    frameRate(60);
    
    //Grid Setup
    grid = new int[gridSize][gridSize];
    cellSize = (gridSpace-offset) / gridSize;
    
    makeNameBox();
    makeChatBox();
    makeHostBoxes();
    makeRefresh();
    makeJoin();
    makeHostButton();
    
    selectedBox = nameBox;
    nameBox.isSelected = true;
    
    lobbies = new ArrayList<GameLobby>();
    
    //Connect To Server
    //lobbyClient = connectMain();
    //if(lobbyClient == null){
    //    println("Could not Connect, Connection Timed Out");
    //    exit();
    //}
    //else{
    //    println(lobbyClient.ip(), lobbyClient.toString());
        
    //}
}

void draw(){
    background(255);
    if(!inLobby){
        drawNameBox();
    }
    else if(!inGameLobby){
        for(int i = 0; i < lobbies.size(); i++){
            GameLobby gl = lobbies.get(i);
            gl.displayInfo(i);
        }
        outLineGrid();
        drawHostBoxes();
        drawHostError();
        drawLobbyButtons();
        drawUserName();
        //println(hostButton.isHovered());
    }
}

void outLineGrid(){
    stroke(0);
    fill(255);
    beginShape();
    vertex(0,gridSpace);
    vertex(gridSpace,gridSpace);
    vertex(gridSpace,0);
    vertex(width, 0);
    vertex(width, height);
    vertex(0,height);
    endShape(CLOSE);
    
}

void mouseClicked(){
    if(selectedBox != null)
        selectedBox.isSelected = false;
    selectedBox = null;
    for(int i = 0; i < boxes.length; i++){
        if(boxes[i].isClicked(mouseX,mouseY)){
            selectedBox = boxes[i];
            selectedBox.isSelected = true;
        }
    }
    
    if(inLobby){
        if(mouseX >= offset/2 && mouseX <= gridSpace - offset/2 && mouseY >= 0 && mouseY <= gridSpace){
            int trueY = mouseY + pixelsUp;
            int ind = trueY / LOBBY_HEIGHT;
            if(ind < lobbies.size()){
                if(selectedLobby != null){
                    selectedLobby.selected = false;
                }
                selectedLobby = lobbies.get(ind);
                selectedLobby.selected = true;
            }
            println(ind);
        }
        refresh.handleClick();
        if(refresh.framesClicked > 0 && !refresh.actionTaken){
            refreshLobbies();
            refresh.actionTaken = true;
        }
        joinLobby.handleClick();
        if(joinLobby.framesClicked > 0 && !joinLobby.actionTaken){
            if(selectedLobby != null){
                joinLobby(selectedLobby.name);
                joinLobby.actionTaken = true;
            }
        }
        hostButton.handleClick();
        if(hostButton.framesClicked > 0 && !hostButton.actionTaken){
            hostLobby();
            hostButton.actionTaken = true;
        }
    }
}

void keyPressed(){
    if(key != CODED){
        switch(key){
        case BACKSPACE:
            if(selectedBox != null){
                selectedBox.deleteChar();
            }
            break;
        case RETURN:
        case ENTER:
            if(selectedBox == nameBox && nameBox.text.length() > 0){
                lobbyClient = connectMain(nameBox.text);
                if(lobbyClient != null){
                    inLobby = true;
                    pixelsUp = 0;
                    lobbyName = nameBox.text;
                    nameBox.active = false;
                    refresh.active = true;
                    joinLobby.active = true;
                    hostButton.active = true;
                    for(int i = 2; i < 6; i++){
                        boxes[i].active = true;
                    }
                    refreshLobbies();
                }
            }
            break;
            
        default:
            if(key != CODED && selectedBox != null){
                selectedBox.addChar(key);
            }
            break;
        }
    }
    
    else{
        switch(keyCode){
        case LEFT:
            if(selectedBox != null){
                selectedBox.curIndex = max(0,selectedBox.curIndex-1);
                //println(selectedBox.curIndex);
            }
            break;
        
        case RIGHT:
            if(selectedBox != null){
                selectedBox.curIndex = min(selectedBox.text.length(),selectedBox.curIndex+1);
                //println(selectedBox.curIndex);
            }
            break;
        }
    }
}

void mouseWheel(MouseEvent e){
    if(mouseX >= 0 && mouseX <= gridSpace && mouseY >= 0 && mouseY <= gridSpace && inLobby){
        pixelsUp += e.getCount();
        pixelsUp = max(min(pixelsUp, lobbies.size()*LOBBY_HEIGHT - gridSpace),0);
    }
}

boolean checkWinner(int i, int j){
    int val = grid[i][j];
    int[][] dist = new int[3][3];
    dist[1][1] = 1;
    for(int dy = -1; dy <= 1; dy++){
        for(int dx = -1; dx <= 1; dx++){
            if(dy == 0 && dx == 0) continue;
            int y = i + dy, x = j + dx;
            while(y >= 0 && y < gridSize && x >= 0 && x < gridSize && grid[y][x] == val){
                dist[dy+1][dx+1]++;
                y += dy;
                x += dx;
            }
        }
    }
    
    int vert = 0, horz = 0, diag1 = 0, diag2 = 0;
    for(int r = 0; r < 3; r++){
        vert += dist[r][1];
        horz += dist[1][r];
        diag1 += dist[r][r];
        diag2 += dist[r][2-r];
    }
    
    if(vert == target || horz == target || diag1 == target || diag2 == target) return true;
    return false;
    
}

//Click Checker, add back in later
    //if(winner != 0) return;
    //if(winner == 0) return;
    //if(mouseX >= offset/2 && mouseX <= gridSpace-offset/2 && mouseY >= offset/2 && mouseY <= gridSpace-offset/2){
    //    int x = (mouseX - offset/2)/cellSize, y = (mouseY - offset/2)/cellSize;
    //    if(grid[y][x] != 0) 
    //        return;
    //    grid[y][x] = playerTurn;
    //    if(checkWinner(y,x)){
    //        winner = playerTurn;
    //        if(mode == 1)
    //            println("Player",winner,"playing", symbols[winner] ,"Wins!");
    //        else 
    //            println("Player",winner,"playing", colorNames[winner] ,"Wins!");
    //    };
    //    playerTurn = playerTurn%numPlayers + 1;
    //}
