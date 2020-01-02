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
