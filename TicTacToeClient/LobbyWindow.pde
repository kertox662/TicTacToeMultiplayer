TextBox nameBox = null;
String serverError = "";

int pixelsUp = 0;

void drawNameBox(){
    textSize(16);
    textAlign(CENTER);
    text(serverError, width/2, height - 50);
    text("Type a username in the box:",width/2, height/2-50);
    text("Press ENTER to submit and attempt to connect to server!", width/2, height/2+50);
    nameBox.display();
}

void drawHostBoxes(){
    fill(0);
    int y = boxes[2].y;
    textSize(24);
    textAlign(CENTER);
    text("HOST GAME", boxes[2].x + boxes[2].w/2, y/2);
    String [] labels = {"Lobby Name", "Max Players (Min 2, Max 4)", "Mode (1 for Characters, 2 for colors)", "GridSize (Max 32)"};
    for(int i = 2; i < 6; i++){
        boxes[i].display();
        textSize(14);
        textAlign(CENTER);
        text(labels[i-2], boxes[i].x + boxes[i].w/2, boxes[i].y - 8);
    }
}



//private class LobbyWindow extends PApplet{
//    void settings(){
//        size(400,400);
//    }
//    void draw(){
//        background(255,0,0);
//    }
//}
