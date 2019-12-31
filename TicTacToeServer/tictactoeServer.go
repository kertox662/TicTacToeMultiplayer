package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

/*
====================
	  Globals
====================
*/
var clientNames []string
var clientAddrs []string

const maxClients int = 1000

func getNameIndex(name string) int {
	for i := 0; i < len(clientNames); i++ {
		if clientNames[i] == name {
			return i
		}
	}
	return -1
}
func addName(name string) {
	clientNames = append(clientNames, name)
	fmt.Println("Added", name, "to clients.")
	fmt.Println("Clients:", clientNames)
}

func deleteName(name string) {
	index := getNameIndex(name)
	if index == -1 {
		return
	}
	clientNames = append(clientNames[:index], clientNames[index+1:]...)
	fmt.Println("Removed", name, "from clients.")
}

var nameChannel chan chan string

func handleNames() {
	var commandChannel chan string
	var command string
	for {
		commandChannel = <-nameChannel
		command = <-commandChannel
		if command[0] == 'i' {
			commandChannel <- strconv.Itoa(getNameIndex(command[1:]))
		} else if command[0] == 'a' {
			addName(command[1:])
		} else if command[0] == 'd' {
			deleteName(command[1:])
		}

	}
}

/*
====================
	  Logging
====================
*/

var logWriter *bufio.Writer

func log(message string) { //Writes the given message to the log file with a timestamp
	t := time.Now()
	logWriter.WriteString(t.Format("2006-01-02-03_04_05") + ":::")
	logWriter.WriteString(message + "\n")
	logWriter.Flush()
}

func logError(e error) { //Logs the error that passed in with an error syntax
	log(fmt.Sprintf("ERROR:::%s", e))
}

/*
====================
	 Main Lobby
====================
*/

func handleConnection(c net.Conn) {
	log(fmt.Sprintf("%s has Connected", c.RemoteAddr().String()))
	fmt.Printf("%s has Connected\n", c.RemoteAddr().String())
	defer log(fmt.Sprintf("%s has Disconnected", c.RemoteAddr().String()))
	defer c.Close()

	nameWasAccepted := false
	clientName := ""

	for {
		message, err := bufio.NewReader(c).ReadString('\n')
		if err != nil {
			logError(err)
			nameIndexChannel := make(chan string)
			nameChannel <- nameIndexChannel
			nameIndexChannel <- "d" + clientName
			return
		}
		fmt.Print(c.RemoteAddr().String(), ":::", message)
		message = strings.TrimSuffix(message, "\n")

		if !nameWasAccepted { //If Connection first started, the first thing the client will send is the requested username
			clientName = message
			nameIndexChannel := make(chan string)
			nameChannel <- nameIndexChannel
			nameIndexChannel <- "i" + clientName
			result := <-nameIndexChannel

			if result == "-1" {
				c.Write([]byte("0"))
				nameChannel <- nameIndexChannel
				nameIndexChannel <- "a" + clientName
				nameWasAccepted = true
			} else {
				c.Write([]byte("1"))
			}
		} else {
			switch message[0] {
			case 'r': //Request Lobbies
				lobbyList := getLobbyList()
				fmt.Print(lobbyList)
				c.Write([]byte(lobbyList))
				break
			case 'j': //Request Join Lobby
				break
			case 'n': //Request New Lobby
				data := strings.Split(message[1:], ",")
				gl := newGameLobbyFromString(data)
				success := addNewLobby(&gl)
				c.Write([]byte(strconv.Itoa(success)))
				if success == 0 {
					gl.addPlayer(&c, clientName)
					handleGame(&gl)
				}
				break
			}

		}
	}
}

/*
====================
   Game Handlers
====================
*/

var lobbies []*gameLobby

const maxLobbies = 512

type gameLobby struct {
	name                            string
	numPlayer, maxPlayer, curPlayer int
	gridSize, mode                  int
	grid                            [][]int
	started                         bool
	playerNames                     []string
	connections                     []*net.Conn
}

func (gl *gameLobby) encode() string {
	data := []string{gl.name, strconv.Itoa(gl.numPlayer), strconv.Itoa(gl.maxPlayer), strconv.Itoa(gl.mode), strconv.Itoa(gl.gridSize)}
	return strings.Join(data, ",")
}

func (gl *gameLobby) addPlayer(c *net.Conn, name string) {
	for i := 0; i < len(gl.playerNames); i++ {
		if gl.playerNames[i] == name {
			return
		}
	}

	for i := 0; i < len(gl.playerNames); i++ {
		if gl.connections[i] == nil {
			gl.connections[i] = c
			gl.playerNames[i] = name
			break
		}
	}
}

func (gl *gameLobby) removePlayer(c net.Conn, name string) {
	for i := 0; i < len(gl.playerNames); i++ {
		if gl.playerNames[i] == name {
			gl.connections[i] = nil
			gl.playerNames[i] = ""
			break
		}
	}
}

func newGameLobby(name string, maxPlayer, gridSize, mode int) gameLobby {
	newLobby := gameLobby{name, 0, maxPlayer, 0, gridSize, mode, nil, false, nil, nil}

	emptyGrid := make([][]int, gridSize)
	for i := 0; i < gridSize; i++ {
		row := make([]int, gridSize)
		emptyGrid[i] = row
	}
	newLobby.grid = emptyGrid

	players := make([]string, maxPlayer)
	newLobby.playerNames = players

	conns := make([]*net.Conn, maxPlayer)
	newLobby.connections = conns

	return newLobby
}
func newGameLobbyFromString(data []string) gameLobby {
	maxPlayer, _ := strconv.Atoi(data[1])
	gridSize, _ := strconv.Atoi(data[2])
	mode, _ := strconv.Atoi(data[3])
	return newGameLobby(data[0], maxPlayer, gridSize, mode)
}

func addNewLobby(gl *gameLobby) int {
	for i := 0; i < len(lobbies); i++ {
		if lobbies[i].name == gl.name {
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

func deleteLobby(gl *gameLobby) {
	for i := 0; i < len(lobbies); i++ {
		if lobbies[i].name == gl.name {
			lobbies = append(lobbies[:i], lobbies[i+1:]...)
			break
		}
	}
}

func getLobbyList() string {
	list := ""
	for i := 0; i < len(lobbies); i++ {
		if !lobbies[i].started {
			list += lobbies[i].encode() + "\n"
		}
		// fmt.Println("Lobby", i+1, ":", lobbies[i].encode())
	}
	if list == "" {
		list = "\n"
	}
	return list + "\n"
}

func handleGame(game *gameLobby) {
	fmt.Println(game.name, game.numPlayer, game.maxPlayer, game.mode, game.gridSize)
	for {

	}
}

/*
====================
	   Main
====================
*/

func main() {
	dir, err := filepath.Abs(filepath.Dir(os.Args[0])) //Gets directory for making the logfile
	if err != nil {
		fmt.Println(err)
	}
	os.Chdir(dir)

	startTime := time.Now() //Creates log file
	logName := "logs/" + startTime.Format("2006-01-02-03_04_05") + ".log"
	logFile, err := os.Create(logName)
	defer log("Terminating")
	defer logFile.Close()
	if err != nil {
		fmt.Println("Error occurred when creating log:")
		fmt.Println(err)
		return
	}
	logWriter = bufio.NewWriter(logFile) //Creates writer to ouput to log file
	log("Started")
	fmt.Println("Made Log File...")

	PORT := ":42069" //Default port
	arguments := os.Args
	if len(arguments) > 1 {
		PORT = ":" + arguments[1]
	}

	clientNames = make([]string, 0, maxClients) //Set Up Globals
	clientAddrs = make([]string, 0, maxClients)

	nameChannel = make(chan chan string)
	go handleNames()

	lobbies = make([]*gameLobby, 0, maxLobbies)

	for i := 1; i < 5; i++ {
		gl := newGameLobby("Lobby"+strconv.Itoa(i), i, i*i, i%2+1)
		addNewLobby(&gl)
	}

	// for i := 0; i < len(lobbies); i++ {
	// 	fmt.Println(lobbies[i].encode())
	// }

	listener, err := net.Listen("tcp4", PORT) //Starts listener on the chosen port
	defer listener.Close()
	if err != nil {
		logError(err)
		return
	}
	fmt.Println("Started Listener...")
	fmt.Println("Listening on port " + PORT[1:] + "...")
	log("Listening on port " + PORT[1:])

	for { //Infinite loop to accept incoming connections
		conn, err := listener.Accept()
		if err != nil {
			logError(err)
			continue
		}
		go handleConnection(conn)
	}
}
