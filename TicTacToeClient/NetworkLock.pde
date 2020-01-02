//The purpose of this class is to control who has access to the lobbyClient at a certain time.
//The lock in this program is only used for sending, or for functions that send and then expect a response
//It is not used for receiving server events like player moves or chat messages

//What is does is it treats an ArrayList as a queue, which holds timestamps
//Earlier time stamps get to access the network first
//Once the access point with the particular time stamp is done, it gets removed
private class NetworkLock{
    private ArrayList<Long> queue;
    NetworkLock(){
        queue = new ArrayList<Long>();
    }
    
    void addAccess(long n){
        queue.add(n);
    }
    void popFront(){
        queue.remove(0);
    }
    
    long peekFront(){
        if(queue.size() == 0){
            return 0;
        }
        return queue.get(0);
    }
}
