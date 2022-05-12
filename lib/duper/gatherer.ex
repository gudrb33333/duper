defmodule Duper.Gatherer do
    require Logger
    use GenServer

    @me Gatherer

    #API

    def start_link(worker_count) do
        Logger.info "Gatherer server startd"
        GenServer.start_link(__MODULE__, worker_count, name: @me)
    end

    def done() do
        Logger.info "Gatherer.done/1 Called"
        GenServer.cast(@me, :done)
    end

    def result(path, hash) do
        Logger.info "Gatherer.result/2 Called"
        GenServer.cast(@me, {:result, path, hash})
    end

    #서버

    def init(worker_count) do
        #send_after 함수 호출,send_after는 메시지를 서버의 메시지큐에 집어넣는다.
        #init 함수의 실행이 끝나면 서버는 이 메시지를 접수해 handle_info 콜백을 실행시킨다.
        Process.send_after(self(), :kickoff, 0 )
        {:ok, worker_count}
    end

    def handle_info(:kickoff, worker_count) do
        Logger.info "Gatherer :kickoff Called"
        1..worker_count
        |> Enum.each(fn _ -> Duper.WorkerSupervisor.add_worker() end)
        {:noreply, worker_count}
    end

    def handle_cast(:done, _worker_count = 1) do
        report_results()
        System.halt(0)
    end

    def handle_cast(:done, worker_count) do
        {:noreply, worker_count - 1}
    end

    def handle_cast({:result, path, hash}, worker_count) do
        Duper.Results.add_hash_for(path, hash)
        {:noreply, worker_count}
    end

    defp report_results() do
        IO.puts "Results: \n"
        Duper.Results.find_duplicates()
        |> Enum.each(&IO.inspect/1)
    end
end
