package network

import (
	"bufio"
	"fmt"
	"net"
	"strings"

	"../game"
	"../lobby"
	"../logging"
	"../naming"
)

var clientAddrs []string

//HandleConnection - Handles the interaction between the server and incoming clients as they enter the lobby
func HandleConnection(c net.Conn) {
	logging.Log(fmt.Sprintf("%s has Connected", c.RemoteAddr().String()))
	fmt.Printf("%s has Connected\n", c.RemoteAddr().String())
	defer logging.Log(fmt.Sprintf("%s has Disconnected", c.RemoteAddr().String()))
	defer c.Close()

	nameWasAccepted := false
	clientName := ""

	for {
		message, err := bufio.NewReader(c).ReadString('\n')
		if err != nil {
			logging.LogError(err)
			if nameWasAccepted {
				nameIndexChannel := make(chan string)
				naming.NameChannel <- nameIndexChannel
				nameIndexChannel <- "d" + clientName
			}
			return
		}
		fmt.Print(c.RemoteAddr().String(), ":::", message)
		message = strings.TrimSuffix(message, "\n")

		if !nameWasAccepted { //If Connection first started, the first thing the client will send is the requested username
			nameWasAccepted, clientName = handleNaming(c, message)
		} else {
			switch message[0] {
			case 'r': //Request Lobbies
				handleLobbyRequests(c, 'r', "")
				break
			case 'j': //Request Join Lobby
				handleLobbyRequests(c, 'j', message)
				break
			case 'n': //Request New Lobby
				handleLobbyRequests(c, 'n', message)
				break
			}

		}
	}
}

func handleNaming(c net.Conn, message string) (bool, string) {
	clientName := message
	nameIndexChannel := make(chan string)
	naming.NameChannel <- nameIndexChannel
	nameIndexChannel <- "i" + clientName
	result := <-nameIndexChannel

	if result == "-1" {
		c.Write([]byte("0"))
		naming.NameChannel <- nameIndexChannel
		nameIndexChannel <- "a" + clientName
		return true, clientName
	}

	c.Write([]byte("1"))
	return false, ""

}

func handleLobbyRequests(c net.Conn, command rune, message string) {
	lobbyChan := make(chan string)
	switch command {
	case 'r':
		lobby.LobbyChannel <- lobbyChan
		lobbyChan <- "r"
		lobbyList := <-lobbyChan
		// fmt.Println(lobbyList)
		c.Write([]byte(lobbyList))

	case 'j':
		break
	case 'n':
		lobby.LobbyChannel <- lobbyChan
		lobbyChan <- message
		success := <-lobbyChan
		c.Write([]byte(success))
		if success == "0" {
			gl := <-lobby.GameChan
			game.HandleGame(&gl)
		}
		break
	}
}

//InitConnSlice - Makes the slice with maxClient capacity
func InitConnSlice(maxClients int) {
	clientAddrs = make([]string, 0, maxClients)
}
