TextBox nameBox = null;
String serverError = "";

void drawNameBox(){
    textSize(16);
    textAlign(CENTER);
    text(serverError, width/2, height - 50);
    text("Type a username in the box:",width/2, height/2-50);
    text("Press ENTER to submit and attempt to connect to server!", width/2, height/2+50);
    nameBox.display();
}

//private class LobbyWindow extends PApplet{
//    void settings(){
//        size(400,400);
//    }
//    void draw(){
//        background(255,0,0);
//    }
//}
