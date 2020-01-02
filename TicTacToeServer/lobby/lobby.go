package lobby

import (
	"strconv"
	"strings"
)

var lobbies []*GameLobby

//MaxClients - Maximum amount of clients allowed
const MaxClients int = 1000

//maxLobbies - Maximum amount of lobbies allowed
const maxLobbies = 500

//maxChanBuffer - Max size for a buffer on a channel
const maxChanBuffer = 50

const maxChatLog = 20

//LobbyChannel - The channel to communicate with to access lobby data
var LobbyChannel chan chan string

//GameChan - The channel to send valid games over
var GameChan chan *GameLobby

//GameLobby - A Data object that holds the information for a game lobby
type GameLobby struct {
	Name                            string
	NumPlayer, MaxPlayer, CurPlayer int
	Leader                          int
	GridSize, Mode, Target          int
	Grid                            [][]int
	Started                         bool
	PlayerNames                     []string
	CommChan                        chan chan string
	ReverseChans                    []chan string
	ended                           bool
}

//Encode - Turns the GameLobby data into a string
func (gl *GameLobby) Encode() string {
	data := []string{gl.Name, strconv.Itoa(gl.NumPlayer), strconv.Itoa(gl.MaxPlayer), strconv.Itoa(gl.Mode), strconv.Itoa(gl.GridSize), strconv.Itoa(gl.Target)}
	if gl.Started {
		data = append(data, "1")
	} else {
		data = append(data, "0")
	}
	return strings.Join(data, ",")
}

//EncodeMin - Encodes the minimum data needed for a GameLobby
func (gl *GameLobby) EncodeMin() string {
	data := []string{gl.Name, strconv.Itoa(gl.MaxPlayer), strconv.Itoa(gl.Mode), strconv.Itoa(gl.GridSize), strconv.Itoa(gl.Target)}
	return strings.Join(data, ",")
}

//NextPlayerTurn - Calculates the next player turn for the game lobby
func (gl *GameLobby) NextPlayerTurn() bool {
	initPlayer := gl.CurPlayer
	noLoop := true
	for i := gl.CurPlayer; i != initPlayer || noLoop; {
		i = (i % gl.MaxPlayer) + 1
		if gl.PlayerNames[i-1] != "" {
			gl.CurPlayer = i
			return true
		}
		noLoop = false
	}
	return false
}

//AddPlayer - Adds a connection object and name to matching indices in the GameLobby object if they do not yet exist
func (gl *GameLobby) AddPlayer(name string) (int, bool) {
	if gl.NumPlayer >= gl.MaxPlayer {
		return 0, false
	}
	for i := 0; i < len(gl.PlayerNames); i++ {
		if gl.PlayerNames[i] == name {
			return 0, false
		}
	}

	for i := 0; i < len(gl.PlayerNames); i++ {
		if gl.PlayerNames[i] == "" {
			gl.PlayerNames[i] = name
			return i, true
		}
	}
	return 0, false
}

//RemovePlayer - Removes a Channel object and name in the GameLobby object
func (gl *GameLobby) RemovePlayer(name string) (string, int) {
	playerName := ""
	for i := 0; i < len(gl.PlayerNames); i++ {
		if gl.PlayerNames[i] == name {
			playerName = gl.PlayerNames[i]
			gl.PlayerNames[i] = ""
			gl.ReverseChans[i] = nil
			return playerName, i
		}
	}
	return "", -1
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

//IsEnded - returns if the given GameLobby has ended
func (gl *GameLobby) IsEnded() bool {
	return gl.ended
}

//Reset - Puts the necessary values back to default
func (gl *GameLobby) Reset() {
	gl.CurPlayer = 0
	gl.Started = false
	for i := 0; i < gl.GridSize; i++ {
		for j := 0; j < gl.GridSize; j++ {
			gl.Grid[i][j] = 0
		}
	}
}

//NewGameLobby - Minimum constructor for a GameLobby Object
func NewGameLobby(name string, maxPlayer, gridSize, mode, target int) GameLobby {
	newLobby := GameLobby{name, 0, maxPlayer, 0, 1, gridSize, mode, target, nil, false, nil, nil, nil, false}

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
func NewGameLobbyFromString(dataString string) (GameLobby, bool) {
	var dummyLobby GameLobby

	data := strings.Split(dataString, ",")
	if len(data) != 5 {
		return dummyLobby, true
	}
	maxPlayer, err1 := strconv.Atoi(data[1])
	mode, err2 := strconv.Atoi(data[2])
	gridSize, err3 := strconv.Atoi(data[3])
	target, err4 := strconv.Atoi(data[4])
	if err1 != nil || err2 != nil || err3 != nil || err4 != nil {
		return dummyLobby, true
	}
	return NewGameLobby(data[0], maxPlayer, gridSize, mode, target), false
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

//CheckWinner - Calculates if from the given location there is a winner for a game. If there is, outputs index, otherwise 0.
func (gl *GameLobby) CheckWinner(i, j int) int {
	val := gl.Grid[i][j]
	var dist [3][3]int
	dist[1][1] = 1
	for dy := -1; dy <= 1; dy++ {
		for dx := -1; dx <= 1; dx++ {
			if dy == 0 && dx == 0 {
				continue
			}
			y := i + dy
			x := j + dx
			for y >= 0 && y < gl.GridSize && x >= 0 && x < gl.GridSize && gl.Grid[y][x] == val {
				dist[dy+1][dx+1]++
				y += dy
				x += dx
			}
		}
	}
	var vert, horz, diag1, diag2 int
	for r := 0; r < 3; r++ {
		vert += dist[r][1]
		horz += dist[1][r]
		diag1 += dist[r][r]
		diag2 += dist[r][2-r]
	}
	// fmt.Println(vert, horz, diag1, diag2)
	if vert >= gl.Target || horz >= gl.Target || diag1 >= gl.Target || diag2 >= gl.Target {
		return val
	}
	return 0
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
			continue
		}
		if lobbies[i].Name == lobbyName {
			lobbies[i].ended = true
			lobbies = append(lobbies[:i], lobbies[i+1:]...)
			break
		}
	}
}

func getLobbyList() string {
	list := ""
	for i := 0; i < len(lobbies); i++ {
		if lobbies[i] != nil {
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
			gl, err := NewGameLobbyFromString(request[1:])
			if err {
				comChan <- "2"
				break
			}
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
