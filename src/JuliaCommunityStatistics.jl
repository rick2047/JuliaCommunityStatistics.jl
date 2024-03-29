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

function get_pr_info_df(pr)
    prdf = pr_to_df(pr)
    cs, _ = commits(jlrepo, pr;auth=auth)
    cfs = pull_request_files(jlrepo, pr;auth=auth)
    cdfs = commit_to_df.(cs)
    cfdfs = changed_file_to_df.(cfs)
    insertcols!(prdf, :commits=>[cdfs], :changed_files=>[cfdfs])
end

export get_all_pr_info_df
function get_all_pr_info_df(prs)
    df = DataFrame()
    @showprogress 1 "Fetching... " for pr in prs
        try
            prdf = get_pr_info_df(pr)
            df = vcat(df, prdf)
        catch
            sleep_till_reset()
            prdf = get_pr_info_df(pr)
            df = vcat(df, prdf)
        end
    end
    df
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

export commit_to_df
function commit_to_df(c)
    DataFrame(
        sha = c.sha,
        author = name(c.author)
    )
end

export changed_file_to_df
function changed_file_to_df(cf)
    DataFrame(
        file = cf.filename,
        status = cf.status,
        changes = cf.changes,
        additions = cf.additions,
        deletions = cf.deletions
    )
end
end
