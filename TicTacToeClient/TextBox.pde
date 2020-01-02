final int cursorBlinkSpeed = 45; //How quick the cursor blinks
TextBox selectedBox = null;

TextBox[] boxes = {null,null,null,null,null,null,null}; //Storage of textboxes for looping through them

void makeNameBox(){ //Makes the name box
    int boxW = 150, boxH = 15;
    nameBox = new TextBox(width/2 - boxW/2, height/2 - boxH/2, boxW, boxH,35);
    nameBox.active = true;
    nameBox.extendUp = true;
    boxes[0] = nameBox;
}

void makeChatBox(){ //Makes the chat box
    //int boxW = 150, boxH = 12;
    int boxW = width - gridSpace - 10, boxH = 12;
    //chatBox = new TextBox(width - boxW - 5, height - boxH - 5, boxW, boxH);
    chatBox = new TextBox(gridSpace + 5, height - boxH - 5, boxW, boxH);
    boxes[1] = chatBox;
    chatBox.extendUp = true;
    chatBox.limit = 140;
    chatBox.active = false;
}


void makeHostBoxes(){ //Makes the hosting boxes
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

private class TextBox{ //Holds text which can be added to or subtracted from
    String text;
    int x,y,w,h;
    int numLines;
    
    boolean isSelected, active;
    int curIndex = 0;
    int limit; //How many characters the text box can hold
    boolean extendUp = false; //can this text box be extended up for more space?
    
    TextBox(int x,int y,int w,int h){
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.text = "";
        active = false;
        limit = w/h * 2; //Default limit
        numLines = 1;
    }
    
    TextBox(int x,int y,int w,int h, int lim){ //initialize with limit
        this(x,y,w,h);
        limit = lim;
    }
    
    void displayLegacy(){ //OLD WAY OF DISPLAYING STUFF, DEPRECATED
        ArrayList<String> lines = new ArrayList<String>();
        stroke(0);
        noFill();
        textSize(h-1);
        rectMode(CORNER);
        textAlign(LEFT);
        if(extendUp){ //If extending is possible
           try{ //Without this, editing the string may cause problems
                String line = "";
                for(int i = 0; i < text.length(); i++){ //Get all of the lines for the textbox
                    if(textWidth(line + text.charAt(i)) < w){
                        line += text.charAt(i);
                    }else{
                        lines.add(line);
                        line = ""+text.charAt(i);
                    }
                }
                if(!line.equals("")) lines.add(line);
                rect(x,y-h*(max(lines.size()-1,0)), w, (max(lines.size(),1))*h);//Draws the textbox rectangle with extended height
                fill(0);
                for(int i = 0; i < lines.size(); i++){ //Draws the text at certain heights within the rectangle
                    String l = lines.get(i);
                    text(l, x+2, y+h*4/5 - h*(lines.size()-i-1));
                }
                
                if(isSelected && frameCount%cursorBlinkSpeed < cursorBlinkSpeed/2){ //If the box is selected, draw the cursor (a line)
                    int cursInd = 0, totalIndex = 0;
                    while(cursInd < lines.size() && curIndex > totalIndex + lines.get(cursInd).length()){
                        totalIndex += lines.get(cursInd).length();
                        cursInd++;
                    } 
                    float dist = textWidth(text.substring(totalIndex,curIndex));
                    line(x + dist + 3, y - h*(max(lines.size() - cursInd-1,0)), x + dist + 3, y - h*(max(lines.size() - cursInd-1,0))+h);
                }
            }catch(StringIndexOutOfBoundsException e){
            }
        }
        else{ //Same idea as above, but with single string
            rect(x,y,w,h);
            fill(0);
            text(this.text, x + 2, y + h*4/5);
            if(isSelected && frameCount%cursorBlinkSpeed < cursorBlinkSpeed/2){
                float dist = textWidth(text.substring(0,curIndex));
                line(x + dist + 3, y + 2, x + dist + 3, y + h - 2);
            }    
        }
        
    }
    
    void display(){ //Displays the rectangle, text, and cursor
        stroke(0);
        fill(255);
        textSize(h-1);
        rectMode(CORNER);
        textAlign(LEFT);
        if(extendUp){ //If extending is possible
           try{ //Without this, editing the string may cause problems
                String[] words = text.split(" ");
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
                if(!cur.equals("")) lines.append(cur);
                
                numLines = max(lines.size(), 1);
                rect(x,y-h*(numLines-1), w, numLines * h);//Draws the textbox rectangle with extended height
                fill(0);
                for(int i = 0; i < lines.size(); i++){ //Draws the text at certain heights within the rectangle
                    String l = lines.get(i);
                    text(l, x+2, y+h*4/5 - h*(lines.size()-i-1));
                }
                
                if(isSelected && frameCount%cursorBlinkSpeed < cursorBlinkSpeed/2){ //If the box is selected, draw the cursor (a line)
                    int cursInd = 0, totalIndex = 0;
                    while(cursInd < lines.size() && curIndex > totalIndex + lines.get(cursInd).length()){
                        totalIndex += lines.get(cursInd).length();
                        cursInd++;
                    } 
                    float dist = 0;
                    if(lines.size() > 0)
                        dist = textWidth(lines.get(lines.size()-1));
                    line(x + dist + 3, y  + 2, x + dist + 3, y + h - 2);
                }
            }catch(StringIndexOutOfBoundsException e){
            }
        }
        else{ //Same idea as above, but with single string
            rect(x,y,w,h);
            fill(0);
            text(this.text, x + 2, y + h*4/5);
            if(isSelected && frameCount%cursorBlinkSpeed < cursorBlinkSpeed/2){
                float dist = textWidth(text.substring(0,curIndex));
                line(x + dist + 3, y + 2, x + dist + 3, y + h - 2);
            }    
        }
        
    }
    
    void addChar(char c){ //Adds character if it wouldn't go over limit
        if(text.length() == limit) return;
        text = text.substring(0,curIndex) + c + text.substring(curIndex);
        curIndex++;
    }
    
    void deleteChar(){ //Deletes the character behind the cursor if any exist
        if(curIndex > 0){
            text = text.substring(0,curIndex-1) + text.substring(curIndex);
            curIndex--;
        }
    }
    String getText(){ //Returns string and resets textbox
        String t = this.text;
        this.text = "";
        this.curIndex = 0;
        return t;
    }
    
    boolean isClicked(int x, int y){ //Returns if a point is in the textBox
        if(x >= this.x && x <= this.x + this.w && y >= this.y && y <= this.y+this.h) return true;
        return false;
    }
}
