package lobby

import (
	"net"
	"strconv"
	"strings"
)

var lobbies []*GameLobby

//MaxClients - Maximum amount of clients allowed
const MaxClients int = 1000

//maxLobbies - Maximum amount of lobbies allowed
const maxLobbies = 500

//LobbyChannel - The channel to communicate with to access lobby data
var LobbyChannel chan chan string

//GameChan - The channel to send valid games over
var GameChan chan GameLobby

//GameLobby - A Data object that holds the information for a game lobby
type GameLobby struct {
	Name                            string
	NumPlayer, MaxPlayer, CurPlayer int
	GridSize, Mode, Target          int
	Grid                            [][]int
	Started                         bool
	PlayerNames                     []string
	Connections                     []net.Conn
	CommChan                        chan chan string
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
func (gl *GameLobby) AddPlayer(c net.Conn, name string) {
	for i := 0; i < len(gl.PlayerNames); i++ {
		if gl.PlayerNames[i] == name {
			return
		}
	}

	for i := 0; i < len(gl.PlayerNames); i++ {
		if gl.Connections[i] == nil {
			gl.Connections[i] = c
			gl.PlayerNames[i] = name
			break
		}
	}
}

//RemovePlayer - Removes a connection object and name in the GameLobby object
func (gl *GameLobby) RemovePlayer(c net.Conn, name string) {
	for i := 0; i < len(gl.Connections); i++ {
		if gl.Connections[i] == c {
			gl.Connections[i] = nil
			gl.PlayerNames[i] = ""
			break
		}
	}
}

//NewGameLobby - Minimum constructor for a GameLobby Object
func NewGameLobby(name string, maxPlayer, gridSize, mode, target int) GameLobby {
	newLobby := GameLobby{name, 0, maxPlayer, 0, gridSize, mode, target, nil, false, nil, nil}

	emptyGrid := make([][]int, gridSize)
	for i := 0; i < gridSize; i++ {
		row := make([]int, gridSize)
		emptyGrid[i] = row
	}
	newLobby.Grid = emptyGrid

	players := make([]string, maxPlayer)
	newLobby.PlayerNames = players

	conns := make([]net.Conn, maxPlayer)
	newLobby.Connections = conns

	newLobby.CommChan = make(chan chan string, 16)

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
	GameChan = make(chan GameLobby)
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

			}
			break
		case 'd':
			deleteLobby(request[1:])
		}
	}
}
