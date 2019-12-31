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
			return
		}
		message = strings.TrimSuffix(message, "\n")

		if !nameWasAccepted {
			clientName = message
			nameIndexChannel := make(chan string)
			nameChannel <- nameIndexChannel
			nameIndexChannel <- "i" + clientName
			result := <-nameIndexChannel

			if result == "-1" {
				c.Write([]byte("0"))
				nameChannel <- nameIndexChannel
				nameIndexChannel <- "a" + clientName
			} else {
				c.Write([]byte("1"))
			}
		}
	}
}

/*
====================
   Game Handlers
====================
*/

func handleGame() {

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
