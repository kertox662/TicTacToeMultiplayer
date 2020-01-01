package lobby

import (
	"fmt"
	"strconv"
	"strings"
)

var lobbies []*GameLobby

//MaxClients - Maximum amount of clients allowed
const MaxClients int = 1000

//maxLobbies - Maximum amount of lobbies allowed
const maxLobbies = 500

//maxChanBuffer - Max size for a buffer on a channel
const maxChanBuffer = 20

//LobbyChannel - The channel to communicate with to access lobby data
var LobbyChannel chan chan string

//GameChan - The channel to send valid games over
var GameChan chan *GameLobby

//GameLobby - A Data object that holds the information for a game lobby
type GameLobby struct {
	Name                            string
	NumPlayer, MaxPlayer, CurPlayer int
	GridSize, Mode, Target          int
	Grid                            [][]int
	Started                         bool
	PlayerNames                     []string
	CommChan                        chan chan string
	ReverseChans                    []chan string
}

//Encode - Turns the GameLobby data into a string
func (gl *GameLobby) Encode() string {
	data := []string{gl.Name, strconv.Itoa(gl.NumPlayer), strconv.Itoa(gl.MaxPlayer), strconv.Itoa(gl.Mode), strconv.Itoa(gl.GridSize), strconv.Itoa(gl.Target)}
	return strings.Join(data, ",")
}

//EncodeMin - Encodes the minimum data needed for a GameLobby
func (gl *GameLobby) EncodeMin() string {
	data := []string{gl.Name, strconv.Itoa(gl.MaxPlayer), strconv.Itoa(gl.Mode), strconv.Itoa(gl.GridSize), strconv.Itoa(gl.Target)}
	return strings.Join(data, ",")
}

//AddPlayer - Adds a connection object and name to matching indices in the GameLobby object if they do not yet exist
func (gl *GameLobby) AddPlayer(name string) (int, bool) {
	fmt.Println("Looking for name", name)
	if gl.NumPlayer >= gl.MaxPlayer {
		fmt.Println("Too many Players")
		return 0, false
	}
	for i := 0; i < len(gl.PlayerNames); i++ {
		if gl.PlayerNames[i] == name {
			fmt.Println("Already in game")
			return 0, false
		}
	}

	for i := 0; i < len(gl.PlayerNames); i++ {
		if gl.PlayerNames[i] == "" {
			gl.PlayerNames[i] = name
			// gl.ReverseChans[i] = commChan
			fmt.Println("Found")
			return i, true
		}
	}
	fmt.Println("No space?")
	return 0, false
}

//RemovePlayer - Removes a Channel object and name in the GameLobby object
func (gl *GameLobby) RemovePlayer(name string) {
	for i := 0; i < len(gl.PlayerNames); i++ {
		if gl.PlayerNames[i] == name {
			gl.PlayerNames[i] = ""
			gl.ReverseChans[i] = nil
			break
		}
	}
}

//RemovePlayerByChan - Removes a Channel object and name in the GameLobby object by the channel index
func (gl *GameLobby) RemovePlayerByChan(commChan chan string) {
	for i := 0; i < len(gl.ReverseChans); i++ {
		if gl.ReverseChans[i] == commChan {
			gl.PlayerNames[i] = ""
			gl.ReverseChans[i] = nil
			break
		}
	}
}

//NewGameLobby - Minimum constructor for a GameLobby Object
func NewGameLobby(name string, maxPlayer, gridSize, mode, target int) GameLobby {
	newLobby := GameLobby{name, 0, maxPlayer, 0, gridSize, mode, target, nil, false, nil, nil, nil}

	emptyGrid := make([][]int, gridSize)
	for i := 0; i < gridSize; i++ {
		row := make([]int, gridSize)
		emptyGrid[i] = row
	}
	newLobby.Grid = emptyGrid

	players := make([]string, maxPlayer)
	newLobby.PlayerNames = players

	newLobby.CommChan = make(chan chan string, maxChanBuffer)
	newLobby.ReverseChans = make([]chan string, maxPlayer)

	return newLobby
}

//NewGameLobbyFromString - Makes a new GameLobby object from an encoded string
func NewGameLobbyFromString(data []string) GameLobby {
	maxPlayer, _ := strconv.Atoi(data[1])
	mode, _ := strconv.Atoi(data[2])
	gridSize, _ := strconv.Atoi(data[3])
	target, _ := strconv.Atoi(data[4])
	return NewGameLobby(data[0], maxPlayer, gridSize, mode, target)
}

//GetLobby - Returns a pointer to the game lobby with the requested name
func GetLobby(name string) *GameLobby {
	for i := 0; i < len(lobbies); i++ {
		if lobbies[i].Name == name {
			return lobbies[i]
		}
	}
	return nil
}

func addNewLobby(gl *GameLobby) int {
	for i := 0; i < len(lobbies); i++ {
		if lobbies[i].Name == gl.Name {
			return 1
		}
	}

	foundPlace := false

	for i := 0; i < len(lobbies); i++ {
		if lobbies[i] == nil {
			lobbies[i] = gl
			foundPlace = true
			break
		}
	}
	if !foundPlace {
		lobbies = append(lobbies, gl)
	}
	return 0
}

func deleteLobby(lobbyName string) {
	for i := 0; i < len(lobbies); i++ {
		if lobbies[i] == nil {
			break
		}
		if lobbies[i].Name == lobbyName {
			lobbies = append(lobbies[:i], lobbies[i+1:]...)
			break
		}
	}
}

func getLobbyList() string {
	list := ""
	for i := 0; i < len(lobbies); i++ {
		if !lobbies[i].Started {
			list += lobbies[i].Encode() + "\n"
		}
	}
	if list == "" {
		list = "\n"
	}
	return list + "\n"
}

//HandleLobbies - Handles access requests to lobby data
func HandleLobbies() {
	GameChan = make(chan *GameLobby)
	lobbies = make([]*GameLobby, 0, maxLobbies)
	for {
		comChan := <-LobbyChannel
		request := <-comChan
		switch request[0] {
		case 'r':
			comChan <- getLobbyList()
			break
		case 'j':
			break
		case 'n':
			gl := NewGameLobbyFromString(strings.Split(request[1:], ","))
			success := addNewLobby(&gl)
			comChan <- strconv.Itoa(success)
			if success == 0 {
				GameChan <- &gl
			}
			break
		case 'd':
			deleteLobby(request[1:])
		}
	}
}
