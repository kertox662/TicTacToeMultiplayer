build:tictactoeServer.go
	env GOOS="darwin" go build -o tictactoeBin tictactoeServer.go

buildLinux:
	env GOOS="linux" go build -o tictactoeBin tictactoeServer.go

buildMac:
	env GOOS="darwin" go build -o tictactoeBin tictactoeServer.go

toremote:buildLinux
	scp ./tictactoeBin kiki:~/TicTacToeServer