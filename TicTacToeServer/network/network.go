package network

import (
	"bufio"
	"fmt"
	"net"
	"strconv"
	"strings"

	"../game"
	"../lobby"
	"../logging"
	"../naming"
)

var clientAddrs []string

const maxClientBuffer = 20

//HandleConnection - Handles the interaction between the server and incoming clients as they enter the lobby
func HandleConnection(c net.Conn) {
	logging.Log(fmt.Sprintf("%s has Connected", c.RemoteAddr().String()))
	fmt.Printf("%s has Connected\n", c.RemoteAddr().String())
	defer logging.Log(fmt.Sprintf("%s has Disconnected", c.RemoteAddr().String()))
	defer c.Close()

	nameWasAccepted := false
	clientName := ""
	inGameLobby := false
	prevLobbyLoop := false
	var gameLobbyChan chan chan string
	var index int
	gameLobbyComChan := make(chan string)
	broadcastChan := make(chan string)

	for {
		message, err := bufio.NewReader(c).ReadString('\n')
		if err != nil {
			logging.LogError(err)
			if nameWasAccepted {
				nameIndexChannel := make(chan string)
				naming.NameChannel <- nameIndexChannel
				nameIndexChannel <- "d" + clientName
				if inGameLobby {
					gameLobbyChan <- gameLobbyComChan
					gameLobbyComChan <- "l" + clientName
				}
			}
			return
		}
		fmt.Print(c.RemoteAddr().String(), ":::", message)
		message = strings.TrimSuffix(message, "\n")
		if !inGameLobby {
			if prevLobbyLoop {
				prevLobbyLoop = inGameLobby
				continue
			}
			if !nameWasAccepted { //If Connection first started, the first thing the client will send is the requested username
				nameWasAccepted, clientName = handleNaming(c, message)
			} else {
				switch message[0] {
				case 'r': //Request Lobbies
					handleLobbyRequests(c, 'r', "")
					break

				case 'j': //Request Join Lobby
					gameLobbyChan, index = handleJoinRequest(c, 'j', message, clientName, broadcastChan)
					if gameLobbyChan != nil {
						go handleBroadcasts(c, broadcastChan, &inGameLobby, clientName)
						inGameLobby = true
						c.Write([]byte(strconv.Itoa(index)))
						handleLobbyRequests(c, 'r', "")
					}
					break

				case 'n': //Request New Lobby
					handleLobbyRequests(c, 'n', message)
					break
				}

			}
		} else { //Let the game lobby handle the messages
			prevLobbyLoop = true
			gameLobbyChan <- gameLobbyComChan
			gameLobbyComChan <- message
		}
	}

}

func handleNaming(c net.Conn, message string) (bool, string) {
	clientName := message
	nameIndexChannel := make(chan string)
	naming.NameChannel <- nameIndexChannel
	nameIndexChannel <- "i" + clientName //Find index of specified client name request
	result := <-nameIndexChannel

	if result == "-1" { //If client name does not already exist
		c.Write([]byte("0")) //Success, new name
		naming.NameChannel <- nameIndexChannel
		nameIndexChannel <- "a" + clientName
		return true, clientName
	}

	c.Write([]byte("1")) //Name already exists
	return false, ""

}

func handleLobbyRequests(c net.Conn, command rune, message string) {
	lobbyChan := make(chan string)
	switch command {
	case 'r':
		lobby.LobbyChannel <- lobbyChan
		lobbyChan <- "r"
		lobbyList := <-lobbyChan
		c.Write([]byte(lobbyList))
		break
	case 'n':
		lobby.LobbyChannel <- lobbyChan
		lobbyChan <- message
		success := <-lobbyChan
		c.Write([]byte(success))
		if success == "0" {
			gl := <-lobby.GameChan
			go game.HandleGame(gl)
		}
		break
	}
}

func handleJoinRequest(c net.Conn, command rune, message, name string, broadcastChan chan string) (chan chan string, int) {
	lobbyChan := make(chan string)
	gl := lobby.GetLobby(message[1:])
	if gl == nil {
		c.Write([]byte("3")) //Game no longer exists
		return nil, -1
	}
	commChan := gl.CommChan
	commChan <- lobbyChan
	lobbyChan <- "j" + name
	success := <-lobbyChan
	if success == "-1" {
		c.Write([]byte("1")) //Game Full
	}
	if success == "-2" {
		c.Write([]byte("2")) //Game Already Started
	}
	if success == "0" { //SUCCESS
		c.Write([]byte("0"))
		myIndex, _ := strconv.Atoi(<-lobbyChan)
		commChan <- broadcastChan
		return commChan, myIndex
	}
	return nil, -1
}

//InitConnSlice - Makes the slice with maxClient capacity
func InitConnSlice(maxClients int) {
	clientAddrs = make([]string, 0, maxClients)
}

func handleBroadcasts(c net.Conn, broadcast chan string, inGameLobby *bool, name string) {
	for {
		message := <-broadcast
		c.Write([]byte(message))
		if message == "e" {
			// fmt.Println("Ending Game Thread")
			*inGameLobby = false
			// fmt.Println("Send Game Thread End")
			return
		}
		if message[0] == 'l' {
			fmt.Println(message[1:], "is leaving the game")
			if message[1:] == name {
				lobbyChan := make(chan string)
				lobby.LobbyChannel <- lobbyChan
				lobbyChan <- "r"
				lobbyList := <-lobbyChan
				fmt.Println("Sending lobbyList")
				fmt.Println(lobbyList)
				c.Write([]byte(lobbyList))
			} else {
				c.Write([]byte(message))
			}
		}
	}
}
