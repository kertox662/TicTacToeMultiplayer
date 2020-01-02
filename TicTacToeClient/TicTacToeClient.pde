import processing.net.*;

//final String IP = "kiki.cubetex.net";
final String IP = "127.0.0.1";
final int PORT = 42069;

final int MAX_PLAYERS = 4;
final int MAX_GRID = 32;
int gridSpace = 520;
//int gridSpace = 620;

final String[] symbols = {"","X","O","\u25b2", "\u25C6"};
final color[] colors = {color(255),color(231, 76, 60), color(52, 152, 219), color(46, 204, 113), color(247, 220, 111)};
final String[] colorNames = {"", "Red", "Blue", "Green", "Yellow"};

int gridSize = 32;
int offset = 40;
//int offset = 0;
int target = 4;
//int[][] grid;

int playerTurn = 1, numPlayers = 2;
int mode = 1; //1 = Character, 2 = Color
int winner = 0;

String status = "unconnected";

GameLobby curGame = null;

NetworkLock lock;

void settings(){
    //Window Setup
    size(800,640);
    pixelDensity(displayDensity());
}

void setup(){
    frameRate(60);
    
    makeNameBox();
    makeChatBox();
    makeHostBoxes();
    makeRefresh();
    makeJoin();
    makeHostButton();
    
    selectedBox = nameBox;
    nameBox.isSelected = true;
    
    lobbies = new ArrayList<GameLobby>();
    lock = new NetworkLock();
}

void draw(){
    background(255);
    if(inLobby){
        for(int i = 0; i < lobbies.size(); i++){
            GameLobby gl = lobbies.get(i);
            gl.displayInfo(i);
        }
        outLineGrid();
        drawHostBoxes();
        drawHostError();
        drawJoinError();
        drawLobbyButtons();
        drawUserName();
        drawAmountOnline();
    } else if(inGameLobby){
        while(lobbyClient.available() > 0 && inGameLobby){
            currentGame.handleServerMessage(receive());
        }
        currentGame.display();
        chatBox.display();
    }
    else{
        drawNameBox();
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
            if(2<=i && i <=6 && selectedLobby != null){
                selectedLobby.selected = false;
                selectedLobby = null;
            }
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
    if(inGameLobby){
        try{
            currentGame.handleGridClick();
            currentGame.leaveButton.handleClick();
            if(currentGame.leaveButton.framesClicked > 0){
                currentGame.leaveLobby();
            }
            currentGame.startButton.handleClick();
            if(currentGame.startButton.framesClicked > 0){
                sendStart();
            }
        } catch(NullPointerException e){
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
                    lobbyName = nameBox.text;
                    setLobbyStatus();
                    refreshLobbies();
                }
            } else if(selectedBox == chatBox && chatBox.text.length() > 0){
                sendMessage();
            } else if(selectedLobby != null && inLobby){
                joinLobby(selectedLobby.name);
            }else if(inLobby){
                for(int i = 2; i <= 6; i++){
                    if(selectedBox == boxes[i]){
                        hostLobby();
                        break;
                    }
                }
            }
            break;
            
        default:
            if(key != CODED && selectedBox != null){
                selectedBox.addChar(key);
            }else{
                if(key == 'r' && inLobby){
                    refreshLobbies();
                }
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
