import processing.net.*;

//final String IP = "kiki.cubetex.net"; //The IP the client Connects to
final String IP = "127.0.0.1";
final int PORT = 42069; //The port at which the client connects at

final int MAX_PLAYERS = 4; //Limits for hosting textboxes
final int MAX_GRID = 32;


int gridSpace = 520; //Space that the grid and lobbies will occupy
//int gridSpace = 620;

//Markings to represent players
final String[] symbols = {"","X","O","\u25b2", "\u25C6"};
final color[] colors = {color(255),color(231, 76, 60), color(52, 152, 219), color(46, 204, 113), color(247, 220, 111)};
final String[] colorNames = {"", "Red", "Blue", "Green", "Yellow"}; //DEPRECATED

int offset = 40; // How far in to display Board and Lobbies
//int offset = 0;

GameLobby curGame = null;

NetworkLock lock; //To stop the client from sending and expecting input at the same time (Not quite perfect yet)

void settings(){
    //Window Setup
    size(800,640); //Should theoretically work for any size larger than this
    pixelDensity(displayDensity()); //For high dpi screens (Macbook Retina)
}

void setup(){
    frameRate(60);
    
    //Sets up buttons and TextBoxes
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
    if(inLobby){ //Displays Lobby Window
        for(int i = 0; i < lobbies.size(); i++){ //Displays lobby information
            GameLobby gl = lobbies.get(i);
            gl.displayInfo(i);
        }
        //Draws Lobby window
        outLineGrid();
        drawHostBoxes();
        drawHostError();
        drawJoinError();
        drawLobbyButtons();
        drawUserName();
        drawAmountOnline();
    } else if(inGameLobby){//Game Lobby Display
        //long timeStamp = System.nanoTime();
        //lock.addAccess(timeStamp);
        //while(lock.peekFront() != timeStamp){}
        //lock.popFront();
        while(lobbyClient.available() > 0 && inGameLobby){//Get all server input and process it
            currentGame.handleServerMessage(receive());
        }
        currentGame.display(); //Display Grid
        chatBox.display();
    }
    else{//Before Connecting, display nameBox
        drawNameBox();
    }
}

void outLineGrid(){ //Outlines based on gridSpace
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
        selectedBox.isSelected = false; //Unselected any selected textbox
    selectedBox = null;
    for(int i = 0; i < boxes.length; i++){
        if(boxes[i].isClicked(mouseX,mouseY)){//Checks if box is clicked
            selectedBox = boxes[i]; //If it is, make it the selected one
            selectedBox.isSelected = true;
            if(2<=i && i <=6 && selectedLobby != null){ //If in lobby window, deselect selected Lobby
                selectedLobby.selected = false;
                selectedLobby = null;
            }
        }
    }
    
    if(inLobby){
        if(mouseX >= offset/2 && mouseX <= gridSpace - offset/2 && mouseY >= 0 && mouseY <= gridSpace){//Checks lobby selection
            int trueY = mouseY + pixelsUp; //Shifts up mouseY to be relative to the lobby list
            int ind = trueY / LOBBY_HEIGHT; //Gets which lobby index is clicked
            if(ind < lobbies.size()){ //If valid index select the lobby
                if(selectedLobby != null){
                    selectedLobby.selected = false;
                }
                selectedLobby = lobbies.get(ind);
                selectedLobby.selected = true;
            }
        }
        //Handle Button Clicks, Do actions based on button
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
        try{//Something was breaking due to updates so here's a try/catch
            currentGame.handleGridClick(); //Get Square Clicked in Grid
            
            //Game Button Clicks
            currentGame.leaveButton.handleClick();
            if(currentGame.leaveButton.framesClicked > 0){
                currentGame.leaveLobby();
            }
            currentGame.startButton.handleClick();
            if(currentGame.startButton.framesClicked > 0){
                sendStart();
            }
            currentGame.resetButton.handleClick();
            if(currentGame.resetButton.framesClicked > 0){
                sendReset();
            }
        } catch(NullPointerException e){
        }
    }
}

void keyPressed(){
    
    if(key != CODED){
        switch(key){
        case BACKSPACE: //For TextBoxes
            if(selectedBox != null){
                selectedBox.deleteChar();
            }
            break;
        case RETURN:
        case ENTER:
            if(selectedBox == nameBox && nameBox.text.length() > 0){//For nameBox
                lobbyClient = connectMain(nameBox.text);
                if(lobbyClient != null){
                    lobbyName = nameBox.text;
                    setLobbyStatus();
                    refreshLobbies();
                }
            } else if(selectedBox == chatBox && chatBox.text.length() > 0){//For chatBox
                sendMessage();
            } else if(selectedLobby != null && inLobby){//Shortcut to join lobby
                joinLobby(selectedLobby.name);
            }else if(inLobby){//Shortcut to host lobby
                for(int i = 2; i <= 6; i++){
                    if(selectedBox == boxes[i]){
                        hostLobby();
                        break;
                    }
                }
            }
            break;
            
        default:
            if(key != CODED && selectedBox != null){ //If not a special key, add it to the selected textBox
                selectedBox.addChar(key);
            }else{
                if(key == 'r' && inLobby){ //If no selected and in lobby, refresh shortcut
                    refreshLobbies();
                }
            }
            break;
        }
    }
    
    else{ //Moves around selectedBox cursor
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

void mouseWheel(MouseEvent e){ //If in gridSpace, then update pixels up
    if(mouseX >= 0 && mouseX <= gridSpace && mouseY >= 0 && mouseY <= gridSpace && inLobby){
        pixelsUp += e.getCount();
        pixelsUp = max(min(pixelsUp, lobbies.size()*LOBBY_HEIGHT - gridSpace),0);
    }
}
