Minim minim;

AudioPlayer joinSound, leaveSound, startSound, winSound, moveSound, messageSound;

//boolean skipMessage;

void loadSounds(){
    minim = new Minim(this);
    joinSound = minim.loadFile("join.mp3");
    leaveSound = minim.loadFile("leave.mp3");
    startSound = minim.loadFile("start.mp3");
    winSound = minim.loadFile("winner.mp3");
    moveSound = minim.loadFile("move.mp3");
    messageSound = minim.loadFile("chat.mp3");
    //skipMessage = false;
}

void playSound(AudioPlayer sound){
    //if(sound == messageSound && skipMessage) return;
    sound.rewind();
    sound.play();
    //while(sound.isPlaying()){}
    //if(sound == joinSound || sound == leaveSound) skipMessage = false;
}

void playJoin(){
    playSound(joinSound);
}

void playLeave(){
    playSound(leaveSound);
}

void playMove(){
    playSound(moveSound);
}

void playMessage(){
    playSound(messageSound);
}

void playStart(){
    playSound(startSound);
}

void playWin(){
    playSound(winSound);
}
