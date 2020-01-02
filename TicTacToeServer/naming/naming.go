package naming

import (
	"fmt"
	"strconv"
)

var clientNames []string

/*NameChannel - The channel to start a name based command interaction. By sending a string channel through the
NameChannel, the program says it wants to access name data*/
var NameChannel chan chan string

//getNameIndex - Return the index of a certain name in the slice or -1 if it doesn't exist
func getNameIndex(name string) int {
	for i := 0; i < len(clientNames); i++ {
		if clientNames[i] == name {
			return i
		}
	}
	return -1
}

//addName - Adds the name to the slice
func addName(name string) {
	clientNames = append(clientNames, name)
	fmt.Println("Added", name, "to clients.")
	fmt.Println("Clients:", clientNames)
}

//deleteName - If the name is in the slice, it reslices so that the name is deleted
func deleteName(name string) {
	index := getNameIndex(name)
	if index == -1 {
		return
	}
	clientNames = append(clientNames[:index], clientNames[index+1:]...)
	fmt.Println("Removed", name, "from clients.")
}

//HandleNames - The handler responsible for interacting with the name data.
func HandleNames() {
	for {
		commandChannel := <-NameChannel
		command := <-commandChannel
		if command[0] == 'i' {
			commandChannel <- strconv.Itoa(getNameIndex(command[1:]))
		} else if command[0] == 'a' {
			addName(command[1:])
		} else if command[0] == 'd' {
			deleteName(command[1:])
		} else if command[0] == 'l' {
			commandChannel <- strconv.Itoa(len(clientNames))
		}
	}
}

//InitNameSlice - Makes the slice with maxClient capacity
func InitNameSlice(maxClients int) {
	clientNames = make([]string, 0, maxClients)
}
