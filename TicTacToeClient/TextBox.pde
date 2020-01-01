final int cursorBlinkSpeed = 45;
TextBox selectedBox = null;

TextBox[] boxes = {null,null,null,null,null,null,null};

void makeNameBox(){
    int boxW = 150, boxH = 15;
    nameBox = new TextBox(width/2 - boxW/2, height/2 - boxH/2, boxW, boxH,35);
    nameBox.active = true;
    nameBox.extendUp = true;
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
    for(int i = 0; i < 5; i++){
        boxes[i+2] = new TextBox(middle, (i+2) * 45, boxW, boxH);
    }
    boxes[2].limit = 20;
    boxes[3].limit = 1;
    boxes[4].limit = 1;
    boxes[5].limit = 2;
    boxes[6].limit = 2;
}

private class TextBox{
    String text;
    int x,y,w,h;
    
    boolean isSelected, active;
    int curIndex = 0;
    int limit;
    boolean extendUp = false;
    
    TextBox(int x,int y,int w,int h){
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.text = "";
        active = false;
        limit = w/h * 2;
    }
    
    TextBox(int x,int y,int w,int h, int lim){
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.text = "";
        active = false;
        limit = lim;
    }
    
    void display(){
        ArrayList<String> lines = new ArrayList<String>();
        stroke(0);
        noFill();
        textSize(h-1);
        rectMode(CORNER);
        textAlign(LEFT);
        if(extendUp){
            String line = "";
            for(int i = 0; i < text.length(); i++){
                if(textWidth(line + text.charAt(i)) < w){
                    line += text.charAt(i);
                }else{
                    lines.add(line);
                    line = ""+text.charAt(i);
                }
            }
            if(!line.equals("")) lines.add(line);
            rect(x,y-h*(max(lines.size()-1,0)), w, (max(lines.size(),1))*h);
            fill(0);
            for(int i = 0; i < lines.size(); i++){
                String l = lines.get(i);
                text(l, x+2, y+h*4/5 - h*(lines.size()-i-1));
            }
            //for(String s : lines) println(s);
            if(isSelected && frameCount%cursorBlinkSpeed < cursorBlinkSpeed/2){
                int cursInd = 0, totalIndex = 0;
                while(cursInd < lines.size() && curIndex > totalIndex + lines.get(cursInd).length()){
                    totalIndex += lines.get(cursInd).length();
                    cursInd++;
                } 
                float dist = textWidth(text.substring(totalIndex,curIndex));
                line(x + dist + 3, y - h*(max(lines.size() - cursInd-1,0)), x + dist + 3, y - h*(max(lines.size() - cursInd-1,0))+h);
            }
        }
        else{
            rect(x,y,w,h);
            fill(0);
            text(this.text, x + 2, y + h*4/5);
            if(isSelected && frameCount%cursorBlinkSpeed < cursorBlinkSpeed/2){
                float dist = textWidth(text.substring(0,curIndex));
                line(x + dist + 3, y + 2, x + dist + 3, y + h - 2);
            }    
        }
        
    }
    
    void addChar(char c){
        if(text.length() == limit) return;
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
