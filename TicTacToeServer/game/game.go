package game

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"../lobby"
)

const emptyTimeAllowed = 30 * 1000000000 //Nanoseconds

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

			lastEmptyCheck = time.Now()
		}
		// fmt.Println(len(game.CommChan))
		for len(game.CommChan) > 0 {
			commandChan := <-game.CommChan
			request := <-commandChan
			switch request[0] {
			case 'j':
				//Join Game
				fmt.Println("Processing Join!")
				if game.Started {
					commandChan <- "-2"
					break
				}
				i, foundSpace := game.AddPlayer(request[1:])

				if !foundSpace {
					commandChan <- "-1"
					break
				}
				fmt.Println("SUCCESS IN JOINING", game.Name)
				commandChan <- "0"
				commandChan <- strconv.Itoa(i)
				broadcastChan := <-game.CommChan
				game.ReverseChans[i] = broadcastChan
				game.NumPlayer++
				break
			case 's':
				//Start Game
				name := request[1:]
				if name == game.PlayerNames[0] {
					game.Started = true
					broadcast(game, "s")
				}
				break
			case 'p':
				//Play Move
				move := request[1:]
				moveStrings := strings.Split(move, ",")
				r, _ := strconv.Atoi(moveStrings[0])
				c, _ := strconv.Atoi(moveStrings[1])
				for i := 0; i < game.MaxPlayer; i++ {
					if game.ReverseChans[i] == commandChan {
						game.Grid[r][c] = i
						break
					}
				}
				break
			case 'm':
				//Message
				break
			case 'l':
				//Leave
				game.RemovePlayerByChan(commandChan)
				game.NumPlayer--
				break
			}
		}
	}
}

func broadcast(game *lobby.GameLobby, message string) {
	for i := 0; i < game.MaxPlayer; i++ {
		if game.ReverseChans[i] != nil {
			game.ReverseChans[i] <- message
		}
	}
}
