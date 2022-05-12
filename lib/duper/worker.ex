defmodule Duper.Worker do
    require Logger
    use GenServer, restart: :transient
    
    def start_link(_) do
        Logger.info "Worker Server Started"
        GenServer.start_link(__MODULE__, :no_args)
    end

    def init(:no_args) do
        Process.send_after(self(), :do_one_file, 0)
        {:ok, nil}
    end

    def handle_info(:do_one_file, _) do
        pid = self()
        Duper.PathFinder.next_path(pid)
        |> add_result()
    end

    defp add_result(nil) do
        Logger.info "Worker.add_result/1 Called"
        Duper.Gatherer.done()
        {:stop, :normal, nil}
    end

    defp add_result(path) do
        Logger.info "Worker.add_result/1 Called"
        Duper.Gatherer.result(path, hash_of_file_at(path))
        send(self(), :do_one_file)
        {:noreply, nil}
    end

    defp hash_of_file_at(path) do
        File.stream!(path, [], 1024*1024)
        |>Enum.reduce(
            :crypto.hash_init(:md5),
            fn (block, hash) ->
                :crypto.hash_update(hash,block)
            end)
        |>:crypto.hash_final()    
    end

end
