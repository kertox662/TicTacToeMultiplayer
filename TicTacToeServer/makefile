tictactoeBin:tictactoeServer.go
	env GOOS="linux" go build -o tictactoeBin tictactoeServer.go

build:tictactoeServer.go
	env GOOS="linux" go build -o tictactoeBin tictactoeServer.go

buildLinux:build

buildMac:tictactoeServer.go
	env GOOS="darwin" go build -o tictactoeBin tictactoeServer.go

toremote:tictactoeBin
	scp ./tictactoeBin kiki:~/TicTacToeServer