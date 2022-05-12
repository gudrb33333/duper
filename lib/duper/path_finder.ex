defmodule Duper.PathFinder do
    require Logger
    use GenServer

    @me PathFinder

    def start_link(root) do
        Logger.info "PathFinder Server Started"
        GenServer.start_link(__MODULE__, root, name: @me)        
    end

    def next_path(pid) do
        Logger.info "PathFinder.next_path/1 Called"
        GenServer.call(@me, {:next_path, pid})
    end

    def init(path) do
        DirWalker.start_link(path)
    end

    def handle_call({:next_path, pid}, _from, dir_walker) do
        path = case DirWalker.next(dir_walker) do
                [path] -> path
                other -> other
               end
               
        IO.puts ""
        IO.puts "Worker Pid: #{inspect pid}, Path: #{path}"
        {:reply, path, dir_walker}
    end

end
