module JuliaCommunityStatistics

using GitHub
using ProgressMeter
using Memoize
using Dates
import GitHub: rate_limit

export jlrepo, auth, rate_limit
const auth = authenticate(ENV["GH_AUTH"])
const jlrepo = repo("JuliaLang/julia"; auth=auth)

@memoize Dict function get_commits_for_pr(pr)
    cs, _ = commits(jlrepo, pr;auth=auth)
    cs
end

export get_all_prs
function get_all_prs(;state="all")
    prs = PullRequest[]
    @showprogress 1 "Fetching... " for iP = 1:1000
        thisprs, _ = pull_requests(jlrepo; auth=auth, page_limit=1, params = Dict("state"=>state, "page"=>iP))
        !isempty(thisprs) || break;
        prs = append!(prs, thisprs)
    end
    prs
end

export get_commits
function get_commits(prs)
    prd = Dict()
    @showprogress 1 "Fetching... " for iPR in prs
        try
            prd[iPR] = get_commits_for_pr(iPR)
        catch
            sleep_till_reset()
            prd[iPR] = get_commits_for_pr(iPR)
        end
    end
    prd
end

export sleep_till_reset
function sleep_till_reset()
    rate_lim = rate_limit(auth=auth)["rate"]
    if rate_lim["remaining"] > 0
        return
    end
    reset_time = Dates.unix2datetime(rate_lim["reset"])
    sleeptime = Dates.Millisecond(reset_time - now()) + Dates.Millisecond(2000)
    println("Sleeping for $(sleeptime)")
    sleep(sleeptime)
end
end
