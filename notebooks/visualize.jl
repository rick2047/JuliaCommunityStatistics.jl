### A Pluto.jl notebook ###
# v0.16.4

using Markdown
using InteractiveUtils

# ╔═╡ 8952762c-3810-11ec-33d4-9f44a17217c4
begin
	using Pkg
	Pkg.activate("..")
end

# ╔═╡ 19e810a5-da40-4fec-98cc-6c838bb0ad53
begin
	using JLD2
	using DataFrames
	using Plots
	using Dates
	using PrettyTables
	using PlutoUI
	using Statistics
	using StatsBase
end

# ╔═╡ 22370722-2285-43c2-97f5-998540a610bd
md"""
# Looking at Julia Development
Notebook to analize julia development over the years. Used GitHub.jl to gather PR information stored as a dataframe in data/ directory. Did not save actual objects and that seemed a bit risky from a PII standpoint. 
"""

# ╔═╡ 375fa75c-5261-49f7-ba5d-d7dc1321e303
md"""
## Load Packages
Using outside enviornment instead of Pluto Pkg manager because GitHub.jl is yet to merge my PR
"""

# ╔═╡ e2fa7a94-2dc9-4f6f-8029-065d58fd696e
md"""
## Data Engineering
"""

# ╔═╡ 3505b1c1-1c67-4606-b647-e6b83dc1799e
df = load("../data/df.jld2")["df"];

# ╔═╡ 54c8fd9f-e6ca-4a61-8e07-ae91af05786c
md"""
Round off dates to days
"""

# ╔═╡ 78ddf957-ca20-41a1-9837-812b3b5c3bf3
safedate(x) = isnothing(x) ? x : Date(x)

# ╔═╡ 8d6ea0a9-2f81-44bf-8c84-7a06f6f9da5a
begin
	datecols = [:closed_at,:created_at,:updated_at, :merged_at]
	transform!(df, datecols .=> (x->safedate.(x)) .=> datecols)
end

# ╔═╡ da8dad6f-74bb-467b-bec3-4a3de25181c7
df_closed = df[df.state.=="closed",:];

# ╔═╡ 4ecc8970-0075-4a6f-97aa-74eed9f42f02
df_closed_per_month = combine(groupby(transform(df_closed, :closed_at .=> (x->floor.(x, Month)) .=> :closed_at), :closed_at), nrow=>:count);

# ╔═╡ 919edb83-990e-49d4-8d66-65e6e63fac5d
begin
	bar(df_closed_per_month.closed_at, df_closed_per_month.count; legend=false)
	vline!([Date(2018,8,9)])
	annotate!(Date(2018,8,9),350, text("v1.0.0",10,:left))
end

# ╔═╡ 7c0d339e-07cb-4f3c-ad1b-327dfab1f52c
with_terminal() do 
	pretty_table(
		first(sort(combine(groupby(df, :owner), nrow=>:count), :count, rev=true), 25),
		tf=tf_markdown
	)
end

# ╔═╡ dd1e9e73-60f4-48ca-9bbf-7144c81bf38c
df2 = combine(x->only(x).changed_files, 
	groupby(df[Not(isempty.(df.changed_files)),:],Not(:changed_files)))

# ╔═╡ baefdcf1-8006-484b-adb9-cba1ef4ea351
cfdf= combine(groupby(df2, :file),:number=>length=>:prs,:changes=>sum=>:changes)

# ╔═╡ 69c993a3-fb0a-4d2c-9afe-7610de9568d2
with_terminal() do 
	pretty_table(
		first(sort(cfdf, :prs, rev=true),50),
		tf=tf_markdown);
end

# ╔═╡ 2c82ed83-3aba-4226-af2c-6cf6db9059e1
bar(filter(p->(p.second>40) && (p.first !="") ,countmap(last.(splitext.(cfdf.file))));legend=false)

# ╔═╡ 6c44e520-1b84-41f9-94ad-306a0be35078
bar(filter(p->p.second>50,countmap(first.(splitpath.(cfdf.file))));legend=false,xrotation=90)

# ╔═╡ 8113d6f1-aa26-4f4f-995f-f9ff21c2e181
days_open = ceil.(df_closed.closed_at .- df_closed.created_at, Dates.Day)

# ╔═╡ c8b105ce-1f47-4255-8c65-d669cd68aa8e
μ_days_open = mean(Dates.value.(days_open))

# ╔═╡ c23948c9-43fc-4245-964b-54bc61d6228f
median_days_open = median(Dates.value.(days_open))

# ╔═╡ cf96819f-8641-4821-af6c-e3a925d7762f
std_days_open = std(Dates.value.(days_open))

# ╔═╡ 3f682cd1-07de-4cf6-927f-9e2cb2e90ce2
begin
	hdo = histogram(days_open; xlims=[0,50],legend=false)
	sdo = scatter(df_closed.created_at,days_open;xrotation=45)
	plot(hdo, sdo;legend=false)
end

# ╔═╡ cb369955-fa62-4948-9348-d8a6380fdd77
scatter(df_closed.created_at,days_open;legend=false)

# ╔═╡ a9fe8e66-b98c-428f-9fbe-5b2c9ff96f27
begin
	hc = histogram(size.(df.commits,1);xlims=[-1,50],title="# Commits")
	hcf = histogram(size.(df.changed_files,1), title="# Changed files")
	plot(hc, hcf;legend=false)
end

# ╔═╡ Cell order:
# ╟─22370722-2285-43c2-97f5-998540a610bd
# ╠═375fa75c-5261-49f7-ba5d-d7dc1321e303
# ╠═8952762c-3810-11ec-33d4-9f44a17217c4
# ╠═19e810a5-da40-4fec-98cc-6c838bb0ad53
# ╠═e2fa7a94-2dc9-4f6f-8029-065d58fd696e
# ╠═3505b1c1-1c67-4606-b647-e6b83dc1799e
# ╟─54c8fd9f-e6ca-4a61-8e07-ae91af05786c
# ╠═78ddf957-ca20-41a1-9837-812b3b5c3bf3
# ╠═8d6ea0a9-2f81-44bf-8c84-7a06f6f9da5a
# ╠═da8dad6f-74bb-467b-bec3-4a3de25181c7
# ╠═4ecc8970-0075-4a6f-97aa-74eed9f42f02
# ╠═919edb83-990e-49d4-8d66-65e6e63fac5d
# ╠═7c0d339e-07cb-4f3c-ad1b-327dfab1f52c
# ╠═dd1e9e73-60f4-48ca-9bbf-7144c81bf38c
# ╠═baefdcf1-8006-484b-adb9-cba1ef4ea351
# ╠═69c993a3-fb0a-4d2c-9afe-7610de9568d2
# ╠═2c82ed83-3aba-4226-af2c-6cf6db9059e1
# ╠═6c44e520-1b84-41f9-94ad-306a0be35078
# ╠═8113d6f1-aa26-4f4f-995f-f9ff21c2e181
# ╠═c8b105ce-1f47-4255-8c65-d669cd68aa8e
# ╠═c23948c9-43fc-4245-964b-54bc61d6228f
# ╠═cf96819f-8641-4821-af6c-e3a925d7762f
# ╠═3f682cd1-07de-4cf6-927f-9e2cb2e90ce2
# ╠═cb369955-fa62-4948-9348-d8a6380fdd77
# ╠═a9fe8e66-b98c-428f-9fbe-5b2c9ff96f27
