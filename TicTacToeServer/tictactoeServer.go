package main

import (
	"fmt"
	"net"
	"os"
	"strconv"

	"./lobby"
	"./logging"
	"./naming"
	"./network"
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

	lobbyChan := make(chan string)
	for i := 1; i < 5; i++ {
		gl := lobby.NewGameLobby("Lobby"+strconv.Itoa(i), i, i*i, i%2+1, i)
		lobby.LobbyChannel <- lobbyChan
		lobbyChan <- "n" + gl.EncodeMin()
		s := <-lobbyChan
		s += "3"
	}

	// for i := 0; i < len(lobbies); i++ {
	// 	fmt.Println(lobbies[i].encode())
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
