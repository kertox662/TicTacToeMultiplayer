final int cursorBlinkSpeed = 45;
TextBox selectedBox = null;

TextBox[] boxes = {null,null,null,null,null,null};

void makeNameBox(){
    int boxW = 150, boxH = 15;
    nameBox = new TextBox(width/2 - boxW/2, height/2 - boxH/2, boxW, boxH);
    nameBox.active = true;
    boxes[0] = nameBox;
}

void makeChatBox(){
    int boxW = 150, boxH = 12;
    chatBox = new TextBox(width - boxW - 5, height - boxH - 5, boxW, boxH);
    boxes[1] = chatBox;
}


void makeHostBoxes(){
    int boxW = 150, boxH = 15;
    int middle = gridSpace + (width-gridSpace)/2 - boxW/2;
    for(int i = 0; i < 4; i++){
        boxes[i+2] = new TextBox(middle, (i+2) * 45, boxW, boxH);
    }
}

private class TextBox{
    String text;
    int x,y,w,h;
    
    boolean isSelected, active;
    int curIndex = 0;
    
    TextBox(int x,int y,int w,int h){
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.text = "";
        active = false;
    }
    
    void display(){
        stroke(0);
        noFill();
        textSize(h-1);
        rectMode(CORNER);
        textAlign(LEFT);
        rect(x,y,w,h);
        fill(0);
        text(this.text, x + 2, y + h*4/5);
        if(isSelected && frameCount%cursorBlinkSpeed < cursorBlinkSpeed/2){
            float dist = textWidth(text.substring(0,curIndex));
            line(x + dist + 3, y + 2, x + dist + 3, y + h - 2);
        }
    }
    
    void addChar(char c){
        text = text.substring(0,curIndex) + c + text.substring(curIndex);
        curIndex++;
    }
    
    void deleteChar(){
        if(curIndex > 0){
            text = text.substring(0,curIndex-1) + text.substring(curIndex);
            curIndex--;
        }
    }
    
    boolean isClicked(int x, int y){
        if(x >= this.x && x <= this.x + this.w && y >= this.y && y <= this.y+this.h) return true;
        return false;
    }
}
