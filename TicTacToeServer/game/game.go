package game

import (
	"fmt"

	"../lobby"
)

//HandleGame - Goroutine that will handle the processes of the game
func HandleGame(game *lobby.GameLobby) {
	fmt.Println(game.Name, game.NumPlayer, game.MaxPlayer, game.Mode, game.GridSize)
	// for {

	// }
}
