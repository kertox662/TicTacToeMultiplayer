if [ $# -eq 1 ]; then
    if [ $1 == kill  ]; then
        echo "Killing Remote Process"
        #ssh kiki ls #< killCommand;
        ssh kiki /bin/bash < killCommand;
    elif [ $1 == start ]; then
        echo "Starting Remote Process"
        echo "nohup ~/TicTacToeServer/tictactoeBin >/dev/null 2>&1 &" | ssh kiki /bin/bash;
    elif [ $1 == update ]; then
        echo "Updating Remote File"
        cd TicTacToeServer
        make;
        make toremote;
    elif [ $1 == connect ]; then
        nc kiki.cubetex.net 42069
    elif [ $1 == logs ]; then
        scp kiki:~/TicTacToeServer/logs/*.log ./logs;
    else
        echo "Please provide one of the following actions"
        echo "start:kill:update:connect:logs"
    fi;
else
    echo "Please provide and action to perform"
fi;