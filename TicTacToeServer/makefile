build:tictactoeServer.go
	env GOOS="darwin" go build -o tictactoeBin tictactoeServer.go

buildLinux:tictactoeServer.go
	env GOOS="linux" go build -o tictactoeBin tictactoeServer.go

buildMac:tictactoeServer.go
	env GOOS="darwin" go build -o tictactoeBin tictactoeServer.go

toremote:tictactoeBin
	scp ./tictactoeBin kiki:~/TicTacToeServer