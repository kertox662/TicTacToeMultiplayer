final int clickedFrames = 5;

Button refresh, joinLobby, hostButton;

void makeRefresh(){
    int w = 120, h = 15;
    refresh = new Button((gridSpace-w)/2, gridSpace + 5, w,h, "Refresh Lobbies");
}

void makeJoin(){
    int w = 60, h = 15;
    joinLobby = new Button((gridSpace-w)/2, gridSpace + h + 10, w,h, "Join!");
}

void makeHostButton(){
    int w = 60, h = 15;
    int x = boxes[2].x + boxes[2].w/2 - w/2, y = boxes[2].y + 4 * 45 + h*2;
    hostButton = new Button(x, y, w,h, "Host!");
}

Button makeLeave(){
    int w = 120, h = 15;
    Button leaveButton = new Button(10,gridSpace + 10, w,h, "Leave Game");
    return leaveButton;
}

Button makeStart(){
    int w = 120, h = 15;
    Button startButton = new Button(140, gridSpace + 10, w, h, "Start Game");
    return startButton;
}

Button makeReset(){
    int w = 120, h = 15;
    Button resetButton = new Button(140, gridSpace + 10, w, h, "Reset Game");
    return resetButton;
}

private class Button{
    int x,y,w,h;
    String text;
    boolean active, actionTaken;
    int framesClicked;
    Button(int x, int y, int w, int h, String label){
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.text = label;
        this.active = false;
        this.actionTaken = true;
        this.framesClicked = 0;
    }
    
    void display(){
        noFill();
        stroke(0);
        if(framesClicked > 0){
            fill(52, 152, 219);
            framesClicked--;
        }
        if(isHovered()){
            stroke(247, 220, 111);
        }
        rectMode(CORNER);
        rect(x,y,w,h);
        fill(0);
        textSize(h-1);
        textAlign(CENTER,CENTER);
        text(this.text, x + w/2,y + h/2 - 2);
    }
    
    boolean isHovered(){
        if(mouseX >= x && mouseX <= x+w && mouseY >= y && mouseY <= y+h) return true;
        return false;
    }
    
    void handleClick(){
        if(!active) {
            framesClicked = 0;
            return;
        }
        if(isHovered()){
            framesClicked = clickedFrames;
            actionTaken = false;
        }
    }
}
