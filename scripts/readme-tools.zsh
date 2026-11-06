#!/usr/bin/env zsh
#
# Print the Tools section of README.md, with the versions of the tools in this
# image. Runs inside the container; use `make readme` to update README.md.
#
# To add a tool, add a `row` to its category below.

source /usr/local/share/datasciencetoolbox/build-info

# The first version number in the output of a command, e.g. 1.8.1 for
# `jq --version` (jq-1.8.1) or 10.2p1 for `ssh -V` (OpenSSH_10.2p1 ...)
ver() { eval "$1" 2>&1 | grep -oE '[0-9]+(\.[0-9]+)+[a-z0-9]*' | head -n 1 }

# The upstream version of a Debian package, e.g. 0.3.3 for 1:0.3.3-1build1
deb() { dpkg-query -W -f='${Version}' "$1" | sed -E 's/^[0-9]+://; s/[-+~].*$//' }

# The version of an R package
rpkg() { Rscript -e "cat(as.character(packageVersion('$1')))" 2>/dev/null }

# The version of a Python tool installed with `uv tool install`
uvtool() { uv tool list 2>/dev/null | awk -v t="$1" '$1 == t { sub(/^v/, "", $2); print $2 }' }

category() { print "\n### $1\n\n| Tool | Version | |\n|---|---|---|" }
row() { print "| $1 | $2 |${3:+ $3} |" }

print "These are the tools in the latest image."
print "The book's [list of command-line tools](https://jeroenjanssens.com/dsatcl/list-of-command-line-tools) explains what each one does."

category Python
row Python "$(ver 'python --version')" '`python`'
row uv "$(ver 'uv --version')" '`pip` runs `uv pip`'
row "Jupyter Console" "$(ver 'jupyter console --version')" \
  "with IPython kernel $(/opt/venv/bin/python -c 'import ipykernel; print(ipykernel.__version__)')"

category R
row R "$(ver 'R --version')" ''
row tidyverse "$(rpkg tidyverse)" "includes ggplot2 $(rpkg ggplot2)"
row rush "$(rpkg rush)" 'R one-liners from the shell'
row ir "$(ver 'ir --version')" 'runs R scripts that declare their packages'
row "janitor, docopt" "$(rpkg janitor), $(rpkg docopt)" ''

category Shells
row "Z shell" "$(ver 'zsh --version')" 'default shell, with syntax highlighting'
row Bash "$(ver 'bash --version')" ''

category "Core command-line tools"
row coreutils "uutils $(ver 'ls --version')" \
  "\`cat\`, \`cut\`, \`head\`, \`sort\`, \`wc\`, and the rest; \`cp\`, \`mv\`, and \`rm\` are GNU coreutils $(ver 'cp --version')"
row grep "$(ver 'grep --version')" ''
row sed "$(ver 'sed --version')" ''
row awk "mawk $(ver 'awk -W version')" ''
row findutils "$(ver 'find --version')" '`find`'
row util-linux "$(ver 'column --version')" '`column`, `rev`'
row moreutils "$(deb moreutils)" '`sponge`, `ts`'
row "tar, gzip" "$(ver 'tar --version'), $(ver 'gzip --version')" '`zcat`'
row bc "$(ver 'bc --version')" ''
row "less, man-db" "$(less --version | grep -oE '[0-9]+' | head -n 1), $(ver 'man --version')" ''

category CSV
row csvkit "$(uvtool csvkit)" \
  '`csvcut`, `csvgrep`, `csvjoin`, `csvlook`, `csvsort`, `csvsql`, `csvstack`, `csvstat`, `in2csv`, `sql2csv`'
row xsv "$(ver 'xsv --version')" ''
row csvquote "git ${CSVQUOTE_COMMIT:0:7}" ''

category "JSON, XML, and HTML"
row jq "$(ver 'jq --version')" ''
row fx "$(ver 'fx --version')" ''
row gron "$(ver 'gron --version')" ''
row json2csv "$(ver 'json2csv --version')" ''
row xml2json "$(ver 'grep "\"version\"" /opt/node/lib/node_modules/xml2json-command/package.json')" ''
row XMLStarlet "$(ver 'xmlstarlet --version')" '`xmlstarlet`'
row pup "$(ver 'pup --version')" "git ${PUP_COMMIT:0:7}"

category "Obtaining data"
row curl "$(ver 'curl --version')" ''
row "AWS CLI" "$(ver 'aws --version')" '`aws`'
row OpenSSH "$(ver 'ssh -V')" '`ssh`, `scp`'
row telnet "$(deb telnet)" ''
row "unzip, 7-Zip, unrar-free" "$(ver 'unzip -v'), $(ver '7z i'), $(deb unrar-free)" '`unzip`, `7z`, `unrar`'

category Modeling
row "Vowpal Wabbit" "$(ver 'vw --version')" '`vw`'
row SKLL "$(uvtool skll)" '`run_experiment`, also available as `skll`'
row Tapkee "${TAPKEE_VERSION}" '`tapkee`'

category "Parallel pipelines"
row "GNU parallel" "$(parallel --version | grep -oE '[0-9]{8}' | head -n 1)" ''
row sample "$(uvtool sample-stream)" ''

category "Data Science Toolbox utilities"
row "[dsutils](https://github.com/jeroenjanssens/dsutils)" "git ${DSUTILS_COMMIT:0:7}" \
  '`body`, `cols`, `csv2vw`, `dseq`, `header`, `pbc`, `scrape`, `servewd`, `trim`, `unpack`, and more'

category "Other tools"
row bat "$(ver 'bat --version')" ''
row tldr "tealdeer $(ver 'tldr --version')" 'pages included, so it works offline'
row nano "$(ver 'nano --version')" ''
row make "$(ver 'make --version')" ''
row git "$(ver 'git --version')" ''
row tree "$(ver 'tree --version')" ''
row htop "$(ver 'htop --version')" ''
row cowsay "$(deb cowsay)" ''
row sudo "$(ver 'sudo --version')" 'user `dst` has passwordless sudo'
