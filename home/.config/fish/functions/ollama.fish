function ollama
    switch $argv[1]
        case up start
            docker start ollama
            docker start open-webui
        case stop
            docker stop ollama
            docker stop open-webui
        case down
            docker rm ollama
            docker rm open-webui
        case help '*'
            echo 'Usage: ollama [up|start|stop|down]'
    end
end
