module JuliaCommunityStatistics

using GitHub
using ProgressMeter
using Dates
using DataFrames
import GitHub: name


export jlrepo, auth
const auth = authenticate(ENV["GH_AUTH"])
const jlrepo = repo("JuliaLang/julia"; auth=auth)

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
            prd[iPR], _ = commits(jlrepo, pr;auth=auth)
        catch
            sleep_till_reset()
            prd[iPR], _ = commits(jlrepo, pr;auth=auth)
        end
    end
    prd
end

export get_changed_files
function get_changed_files(prs)
    prd = Dict()
    @showprogress 1 "Fetching... " for iPR in prs
        try
            prd[iPR] = pull_request_files(jlrepo, iPR;auth=auth)
        catch
            sleep_till_reset()
            prd[iPR] = pull_request_files(jlrepo, iPR;auth=auth)
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

export pr_to_df
function pr_to_df(pr)
    DataFrame(
        number = pr.number,
        state = pr.state,
        owner = name(pr.user),
        created_at = pr.created_at,
        closed_at = pr.closed_at,
        updated_at = pr.updated_at,
        merged_at = pr.merged_at,
        base = name(pr.base),
        head = name(pr.head),
        merge_commit = pr.merge_commit_sha
    )
end
end
