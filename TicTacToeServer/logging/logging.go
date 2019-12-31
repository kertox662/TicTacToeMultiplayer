package logging

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

//LogFile - The .log file that corresonds to the current session
var LogFile *os.File

//LogWriter - The Writer to send log date to the LogFile
var LogWriter *bufio.Writer

//Log - Logs message to the log file connected to logWriter variable
func Log(message string) {
	t := time.Now()
	LogWriter.WriteString(t.Format("2006-01-02-03_04_05") + ":::")
	LogWriter.WriteString(message + "\n")
	LogWriter.Flush()
}

//LogError - Wraps an error to the logging functions
func LogError(e error) { //Logs the error that passed in with an error syntax
	Log(fmt.Sprintf("ERROR:::%s", e))
}

//MakeWriter - Initializes the Writer and creates the file
func MakeWriter() {
	dir, err := filepath.Abs(filepath.Dir(os.Args[0])) //Gets directory for making the logfile
	if err != nil {
		fmt.Println(err)
	}
	os.Chdir(dir)

	startTime := time.Now() //Creates log file
	logName := "logs/" + startTime.Format("2006-01-02-03_04_05") + ".log"
	LogFile, err = os.Create(logName)
	defer Log("Terminating")
	if err != nil {
		fmt.Println("Error occurred when creating log:")
		fmt.Println(err)
		return
	}
	LogWriter = bufio.NewWriter(LogFile) //Creates writer to ouput to log file
	Log("Started")
	fmt.Println("Made Log File...")
}
