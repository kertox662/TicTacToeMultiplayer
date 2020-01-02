package game

import (
	"fmt"
	"strconv"
	"strings"
	"sync"
	"time"

	"../lobby"
	"../logging"
)

const emptyTimeAllowed = 30 * time.Second

//HandleGame - Goroutine that will handle the processes of the game
func HandleGame(game *lobby.GameLobby) {
	logging.Log(fmt.Sprintf("Started Lobby:\nSize: %dx%d\nConnect: %d\nMax Players: %d\nMode: %d",
		game.GridSize, game.GridSize, game.Target, game.MaxPlayer, game.Mode))

	game.Grid = make([][]int, game.GridSize)
	for i := 0; i < game.GridSize; i++ {
		game.Grid[i] = make([]int, game.GridSize)
	}

	numPlaced := 0
	needNewLeader := false

	lastEmptyCheck := time.Now()
	for {
		//Do Gamey Stuff
		if time.Now().Sub(lastEmptyCheck) >= emptyTimeAllowed {
			if game.NumPlayer == 0 {
				endGame(game.Name)
				return
			}

			lastEmptyCheck = time.Now()
		}
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
				index := strconv.Itoa(i)
				for j := 0; j < game.MaxPlayer; j++ {
					if game.PlayerNames[j] != "" {
						message := "j" + game.PlayerNames[j] + "," + strconv.Itoa(j)
						go send(game, message, i)
					}
				}
				send(game, "n"+strconv.Itoa(game.Leader), i)
				go broadcast(game, "j"+request[1:]+","+index)
				go broadcast(game, "m"+request[1:]+" has joined the lobby")
				if needNewLeader {
					game.Leader = i + 1
					needNewLeader = false
					go broadcast(game, "n"+strconv.Itoa(game.Leader))
				}
				logging.Log(game.Name + ":::" + request[1:] + " has joined")
				lastEmptyCheck = time.Now()
				break
			case 's':
				//Start Game
				name := request[1:]
				if name == game.PlayerNames[game.Leader-1] {
					game.Started = true
					var wg sync.WaitGroup
					broadcastConc(game, "s", &wg)
					wg.Wait()
					hasMultPlayers := game.NextPlayerTurn()
					if !hasMultPlayers {
						broadcast(game, "w"+strconv.Itoa(game.CurPlayer))
					} else {
						broadcast(game, "t"+strconv.Itoa(game.CurPlayer))
					}
					logging.Log(game.Name + ":::Has Started Playing")
					broadcast(game, "mStarting the Game")
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
				numPlaced++
				broadcast(game, "p"+move)
				logging.Log(fmt.Sprintf("%s:::Move by %d to %d,%d", game.Name, index, r, c))
				hasMultPlayers := game.NextPlayerTurn()
				winnerInd := game.CheckWinner(r, c)
				if winnerInd > 0 {
					broadcast(game, "w"+strconv.Itoa(winnerInd))
					break
				} else if !hasMultPlayers {
					broadcast(game, "w"+strconv.Itoa(game.CurPlayer))
				} else if numPlaced >= game.GridSize*game.GridSize {
					broadcast(game, "w"+strconv.Itoa(game.MaxPlayer+1))
				} else {
					broadcast(game, "t"+strconv.Itoa(game.CurPlayer))
				}

				break
			case 'm': //Player Chat message Message
				logging.Log(game.Name + ":::" + request[1:])
				broadcast(game, request)
				break
			case 'u':
				if request[1:] == game.PlayerNames[game.Leader-1] {
					game.Reset()
					var wq sync.WaitGroup
					broadcastConc(game, "u", &wq)
					wq.Wait()
					broadcast(game, "mResetting the board")
					numPlaced = 0
				}
			case 'l': //Player Leave
				needNewLeader = false
				game.NumPlayer--
				if game.PlayerNames[game.Leader-1] == request[1:] {
					needNewLeader = true
				}
				// if game.NumPlayer == 0 && !game.Started {
				// 	endGame(game.Name)
				// }

				var endingWG sync.WaitGroup
				broadcastConc(game, "l"+request[1:], &endingWG)
				endingWG.Wait()
				pName, _ := game.RemovePlayer(request[1:])
				// if game.NumPlayer == 0 && !game.Started {
				// 	go broadcast(game, "e"+game.Name)
				// 	return
				// }
				logging.Log(pName + " has left " + game.Name)
				go broadcast(game, "m"+request[1:]+" has left the lobby")

				if needNewLeader {
					if game.NumPlayer == 0 {
						break
						// endGame(game.Name)
						// return
					}
					game.Leader = 0
					for i := 0; i < game.MaxPlayer; i++ {
						if game.PlayerNames[i] != "" {
							game.Leader = i + 1
							needNewLeader = false
							break
						}
					}
					var wg sync.WaitGroup
					broadcastConc(game, "n"+strconv.Itoa(game.Leader), &wg)
					wg.Wait()
					broadcast(game, "m"+game.PlayerNames[game.Leader-1]+" is the new Leader")
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
		if game.ReverseChans[i] != nil {
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
