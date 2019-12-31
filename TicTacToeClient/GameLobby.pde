boolean inGameLobby = false;
TextBox chatBox = null;

private class GameLobby{
    String name;
    int curPlayers, maxPlayers, playerTurn;
    int mode;
    int gridSize;
    int[][] grid;
    String[] players;
    
    GameLobby(String name, int curP, int maxP, int mode, int gridSize){
        this.name = name;
        this.curPlayers = curP;
        this.maxPlayers = maxP;
        this.mode = mode;
        this.gridSize = gridSize;
    }
    
    void display(){
        fill(0);
        background(255);
        //Format Setup
        textSize(cellSize);
        textAlign(CENTER,CENTER);
        rectMode(CENTER);
        
        for(int i = 0; i < gridSize; i++){
            for(int j = 0; j < gridSize; j++){
                if(mode == 1){
                    text(symbols[grid[i][j]], j*cellSize + cellSize/2 + offset/2, i*cellSize + cellSize*4/10 + offset/2);
                }
                else if(mode == 2){
                    noStroke();
                    fill(colors[grid[i][j]]);
                    rect(j*cellSize + cellSize/2 + offset/2, i*cellSize + cellSize/2 + offset/2, cellSize, cellSize);
                }
            }
        }
        
        stroke(0);
        for(int i = 0; i <= gridSize; i++){
          line((gridSpace-offset) * i / gridSize + offset/2, offset/2, (gridSpace-offset) * i / gridSize + offset/2, gridSpace-offset/2);
          line(offset/2, (gridSpace-offset) * i / gridSize + offset/2, gridSpace-offset/2, (gridSpace-offset) * i / gridSize + offset/2);
        }
    }
}
