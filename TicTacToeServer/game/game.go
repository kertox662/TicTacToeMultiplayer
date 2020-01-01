package game

import (
	"fmt"
	"time"

	"../lobby"
)

const emptyTimeAllowed = 30

//HandleGame - Goroutine that will handle the processes of the game
func HandleGame(game *lobby.GameLobby) {
	fmt.Println(game.Name, game.NumPlayer, game.MaxPlayer, game.Mode, game.GridSize)
	game.Grid = make([][]int, game.GridSize)
	for i := 0; i < game.GridSize; i++ {
		game.Grid[i] = make([]int, game.GridSize)
	}
	lastEmptyCheck := time.Now()
	for {
		//Do Gamey Stuff
		if time.Now().Sub(lastEmptyCheck) >= emptyTimeAllowed {
			if game.NumPlayer == 0 {
				deleteChan := make(chan string)
				lobby.LobbyChannel <- deleteChan
				deleteChan <- "d" + game.Name
				return
			}
		}
	}
}
