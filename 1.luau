do
    local RepoURL = "https://raw.githubusercontent.com/beacache/executor/refs/heads/main"
    local SSI = "ud_saveinstance"
    local synsaveinstance

    env.saveinstance = function(instances, options)
        if not synsaveinstance then
            synsaveinstance = loadstring(
                game:HttpGet(RepoURL .. SSI .. ".luau", true),
                SSI
            )()
        end

        synsaveinstance(instances or {}, options or {})
    end
end
