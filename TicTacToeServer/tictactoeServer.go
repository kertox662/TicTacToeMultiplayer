package main

import (
	"fmt"
	"net"
	"os"

	"github.com/kertox662/TicTacToeMultiplayer/TicTacToeServer/lobby"
	"github.com/kertox662/TicTacToeMultiplayer/TicTacToeServer/logging"
	"github.com/kertox662/TicTacToeMultiplayer/TicTacToeServer/naming"
	"github.com/kertox662/TicTacToeMultiplayer/TicTacToeServer/network"
)

func main() {
	logging.MakeWriter()
	defer logging.LogFile.Close()

	lobby.LobbyChannel = make(chan chan string)
	naming.NameChannel = make(chan chan string)

	PORT := ":42069" //Default port, nice
	arguments := os.Args
	if len(arguments) > 1 {
		PORT = ":" + arguments[1]
	}

	naming.InitNameSlice(lobby.MaxClients)
	network.InitConnSlice(lobby.MaxClients)

	go naming.HandleNames()
	go lobby.HandleLobbies()

	// lobbyChan := make(chan string)
	// for i := 1; i < 5; i++ {
	// 	gl := lobby.NewGameLobby("Lobby"+strconv.Itoa(i), i, i*i+6, i%2+1, i+2)
	// 	lobby.LobbyChannel <- lobbyChan
	// 	lobbyChan <- "n" + gl.EncodeMin()
	// 	s := <-lobbyChan
	// 	gl2 := <-lobby.GameChan
	// 	go game.HandleGame(gl2)
	// 	s += "3"
	// }

	listener, err := net.Listen("tcp4", PORT) //Starts listener on the chosen port
	defer listener.Close()
	if err != nil {
		logging.LogError(err)
		return
	}
	fmt.Println("Started Listener...")
	fmt.Println("Listening on port " + PORT[1:] + "...")
	logging.Log("Listening on port " + PORT[1:])

	for { //Infinite loop to accept incoming connections
		conn, err := listener.Accept()
		if err != nil {
			logging.LogError(err)
			continue
		}
		go network.HandleConnection(conn)
	}
}
