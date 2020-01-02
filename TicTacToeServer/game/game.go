package game

import (
	"fmt"
	"strconv"
	"strings"
	"sync"
	"time"

	"../lobby"
)

const emptyTimeAllowed = 1000 * time.Second

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
				if game.Started {
					commandChan <- "-2"
					break
				}
				i, foundSpace := game.AddPlayer(request[1:])

				if !foundSpace {
					commandChan <- "-1"
					break
				}
				commandChan <- "0"
				commandChan <- strconv.Itoa(i + 1)
				broadcastChan := <-game.CommChan
				game.ReverseChans[i] = broadcastChan
				game.NumPlayer++
				broadcast(game, "j"+request[1:])
				broadcast(game, "m"+request[1:]+" has joined the lobby")
				lastEmptyCheck = time.Now()
				break
			case 's':
				//Start Game
				name := request[1:]
				if name == game.PlayerNames[game.Leader-1] {
					game.Started = true
					broadcast(game, "s")
				}
				break
			case 'p': //Play Move
				move := request[1:]
				moveStrings := strings.Split(move, ",")
				r, _ := strconv.Atoi(moveStrings[0])
				c, _ := strconv.Atoi(moveStrings[1])
				index, _ := strconv.Atoi(moveStrings[2])
				if index != game.CurPlayer {
					break
				}
				game.Grid[r][c] = index
				broadcast(game, move)
				winnerInd := game.CheckWinner(r, c)
				if winnerInd > 0 {
					broadcast(game, "w"+strconv.Itoa(winnerInd))
				}
				hasMultPlayers := game.NextPlayerTurn()
				if !hasMultPlayers {
					broadcast(game, "w"+strconv.Itoa(game.CurPlayer))
				} else {
					broadcast(game, "t"+strconv.Itoa(game.CurPlayer))
				}

				break
			case 'm': //Player Chat message Message
				broadcast(game, request)
				break
			case 'l': //Player Leave
				needNewLeader := false
				if game.PlayerNames[game.Leader-1] == request[1:] {
					if !game.Started {
						endGame(game.Name)
						go broadcast(game, "e"+game.Name)
						return
					}
					needNewLeader = true

				}

				var endingWG sync.WaitGroup
				broadcastConc(game, "l"+request[1:], &endingWG)
				endingWG.Wait()
				index := game.RemovePlayer(request[1:])
				fmt.Println(index, "has left", game.Name)
				go broadcast(game, "mSERVER:::"+request[1:]+" has left the lobby")
				game.NumPlayer--

				if needNewLeader {
					if game.NumPlayer == 0 {
						endGame(game.Name)
						return
					}
					game.Leader = 0
					for i := 0; i < game.MaxPlayer; i++ {
						if game.PlayerNames[i] != "" {
							game.Leader = i + 1
							break
						}
					}
					var wg sync.WaitGroup
					broadcastConc(game, "n"+strconv.Itoa(game.Leader), &wg)
					wg.Wait()
					broadcast(game, "mSERVER:::"+strconv.Itoa(game.Leader)+" is the new Leader")
				}
				lastEmptyCheck = time.Now()
				break
			}
		}
	}
}

func broadcast(game *lobby.GameLobby, message string) {
	for i := 0; i < game.MaxPlayer; i++ {
		if game.ReverseChans[i] != nil {
			go send(game, message, i)
		}
	}
}

func send(game *lobby.GameLobby, message string, index int) {
	game.ReverseChans[index] <- message
}

func broadcastConc(game *lobby.GameLobby, message string, wg *sync.WaitGroup) {
	for i := 0; i < game.MaxPlayer; i++ {
		fmt.Println("I:", i)
		if game.ReverseChans[i] != nil {
			fmt.Println("FOUND:", i)
			wg.Add(1)
			go sendConc(game, message, i, wg)
		}
	}
}

func sendConc(game *lobby.GameLobby, message string, index int, wg *sync.WaitGroup) {
	game.ReverseChans[index] <- message
	wg.Done()
}

func endGame(name string) {
	endChan := make(chan string)
	lobby.LobbyChannel <- endChan
	endChan <- "d" + name
}
