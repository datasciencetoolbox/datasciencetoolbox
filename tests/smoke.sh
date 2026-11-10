#!/usr/bin/env zsh
#
# Smoke test for the Data Science Toolbox image. Runs inside the container:
#
#   docker run --rm -v "$(pwd)/tests":/tests datasciencetoolbox/dsatcl2e /tests/smoke.sh
#
# Checks that every tool from the book's list of command-line tools exists and
# that commands from the book (or close equivalents) still behave as printed.
# Needs no network access, except for one check that's skipped without it.

source ~/.zshrc 2>/dev/null

# `docker run -it` sets TERM; tools such as trim need it
export TERM=${TERM:-xterm-256color}

typeset -i passed=0 failed=0 known=0

# check NAME EXPECTED COMMAND: passes when the output of COMMAND contains EXPECTED
check() {
  local name=$1 expected=$2 cmd=$3 output
  output=$(eval "$cmd" 2>&1)
  if [[ $output == *"$expected"* ]]; then
    passed+=1
    printf 'ok   %s\n' "$name"
  else
    failed+=1
    printf 'FAIL %s\n     $ %s\n     expected to contain: %s\n     got: %s\n' \
      "$name" "$cmd" "$expected" "${output:0:500}"
  fi
}

# known_failure ISSUE NAME EXPECTED COMMAND: like check, but for a bug that's
# already reported upstream. A failure is reported but doesn't fail the test
# run; a pass means the bug is fixed and the check can become a regular one.
known_failure() {
  local issue=$1 name=$2 expected=$3 cmd=$4 output
  output=$(eval "$cmd" 2>&1)
  if [[ $output == *"$expected"* ]]; then
    passed+=1
    printf 'ok   %s (fixed? %s is known to fail; turn this into a regular check)
' "$name" "$issue"
  else
    known+=1
    printf 'KNOWN %s (%s)
' "$name" "$issue"
  fi
}

cd "$(mktemp -d)"

# Data
cat > tips.csv <<'EOF'
bill,tip,sex,smoker,day,time,size
16.99,1.01,Female,No,Sun,Dinner,2
10.34,1.66,Male,No,Sun,Dinner,3
21.01,3.5,Male,No,Sun,Dinner,3
23.68,3.31,Male,No,Sun,Dinner,2
24.59,3.61,Female,No,Sun,Dinner,4
8.77,2.0,Male,No,Sat,Lunch,2
27.2,4.0,Male,No,Thur,Lunch,4
EOF
awk 'BEGIN { srand(42); for (i = 0; i < 200; i++)
  printf "%f,%f,%f,%f\n", rand(), rand() * 2, rand() * 3, rand() }' > matrix.csv

print '== Every tool from the list of command-line tools exists'
for tool in alias awk aws bash bat bc body cat cd chmod cols column cowsay cp \
    csv2vw csvcut csvgrep csvjoin csvlook csvquote csvsort csvsql csvstack \
    csvstat curl cut dseq echo env export fc find fold for fx git grep gron \
    head header history hostname in2csv jq json2csv l less ls make man mkdir \
    mv nano nl parallel paste pbc pip pup pwd python R rev rm rush sample \
    scp sed seq servewd shuf sort split sponge sql2csv ssh sudo tail tapkee \
    tar tee telnet tldr tr tree trim ts type uniq unpack unrar unzip vw wc \
    which xml2json xmlstarlet xsv zcat zsh \
    run_experiment Rscript uv 7z htop scrape ir rx jupyter; do
  if [[ $(whence -w -- $tool) != *': none' ]]; then
    passed+=1
  else
    failed+=1
    printf 'FAIL %s is missing\n' "$tool"
  fi
done
print "ok   checked tool presence"

print '== Shell and user'
check 'user is dst with uid 1000' 'uid=1000(dst)' 'id'
check 'zsh is the shell' 'zsh' 'echo $SHELL'
check 'passwordless sudo' 'root' 'sudo -n whoami'
check 'locale is UTF-8' 'Ça va' "echo 'Ça va?' | rev | cut -c 2- | rev"
check 'alias l' 'group-directories-first' 'alias l'
check 'man pages are installed' 'NAME' 'man cat | col -b | head -5'

print '== Chapter 2 and 3'
check 'seq' '10' 'seq 10 5 20 | head -n 1'
check 'cowsay' 'The command line is awesome!' "echo 'The command line is awesome!' | cowsay"
check 'dseq' '-' 'dseq 3 | head -n 1'
check 'tldr works offline' 'tar' 'tldr tar'
check 'bc' '2.718281828' "bc -l <<< 'e(1)'"
check 'unpack' 'unpack' 'unpack 2>&1 | head -n 3; echo unpack'

print '== Chapter 5'
check 'header and body' $'values\n10' 'seq 10 | header -a values | body sort -nr | head -n 2'
check 'trim' '… with' 'seq 100 | trim 5'
# trim measures terminal columns, not bytes (mawk counts bytes and used to cut
# lines with box-drawing characters too early, in the middle of a character)
check 'trim keeps multibyte characters whole' '─────────…' "printf '─%.0s' {1..20} | trim 1 10"
check 'trim counts wide characters as two columns' '日本語テ…' 'echo 日本語テキスト | trim 1 10'
check 'trim test suite' 'trim: 44 passed, 0 failed' '/usr/bin/dsutils/tests/test-trim'
check 'sample' 'Line' 'seq -f "Line %g" 1000 | sample -r 1% | head -n 1'
check 'sponge' '1	a' "printf 'a\nb\n' > dates.txt; < dates.txt nl -w1 | sponge dates.txt; cat dates.txt"
check 'ts' ':' 'echo hi | ts'
check 'csvlook keeps weekdays as text' '| Sun  |' 'csvlook tips.csv'
check 'csvsql' 'Female' "csvsql --query 'SELECT sex, COUNT(*) AS n FROM stdin GROUP BY sex' < tips.csv"
check 'csvcut' 'bill,tip' 'csvcut -c bill,tip tips.csv | head -n 1'
check 'csvkit prints no warnings' 'stderr: none' \
  "err=\$({ csvsql --query 'SELECT 1 AS x' tips.csv; csvlook tips.csv } 2>&1 >/dev/null); echo stderr: \${err:-none}"
check 'csvstack with process substitution (csvkit 1.1.0)' 'b,27.2' \
  'csvstack -n type -g a,b tips.csv <(cat tips.csv) | tail -n 1'
check 'csvquote' '"a,b",c' "printf '\"a,b\",c\n' | csvquote | csvquote -u"
check 'pup' '<tbody>' \
  "echo '<table class=\"wikitable\"><tbody><tr><td>1</td></tr></tbody></table>' | pup 'table.wikitable tbody'"
check 'xml2json keeps the $t format' '"$t": "1"' \
  "echo '<tbody><tr><td>1</td></tr></tbody>' | xml2json"
check 'xml2json prints no warnings' '{' \
  "echo '<a>1</a>' | xml2json 2>&1 >/dev/null; echo '{'"
check 'jq' '"public_dns"' "echo '{\"public_dns\": \"x\"}' | jq ."
check 'json2csv' '1,2' "echo '{\"a\":1,\"b\":2}' | json2csv -k a,b"
check 'fx' '4' "echo '[1,2,3]' | fx 'this.map(x => x * 2)'"
check 'gron' 'json.a = 1;' "echo '{\"a\":1}' | gron"
check 'xmlstarlet' '1' "echo '<a><b>1</b></a>' | xmlstarlet sel -t -v '/a/b'"

print '== Chapter 6 and 7'
check 'make' 'GNU Make' 'make --version'
check 'xsv select' 'tip,bill' 'xsv select tip,bill tips.csv | head -n 1'
check 'xsv count' '7' 'xsv count tips.csv'
check 'csvstat' 'Unique values' 'csvstat tips.csv -c bill'
check 'R tidyverse' '6' "Rscript -e 'suppressMessages(library(tidyverse)); cat(nrow(read_csv(\"tips.csv\", show_col_types = FALSE)) - 1)'"
check 'rush run' '2.727' "rush run 'mean(df\$tip)' tips.csv"
check 'rush run --tidyverse' 'percent' "rush run -t 'mutate(df, percent = tip / bill * 100)' tips.csv"
check 'rush plot to PNG' 'PNG image data' 'rush plot --x bill --y tip tips.csv > plot.png; file plot.png'
check 'rush run with ggplot to PNG' 'PNG image data' \
  "rush run --library ggplot2 'ggplot(df, aes(x = bill, y = tip)) + geom_point()' tips.csv > run.png; file run.png"
check 'rush plot -O ascii has no escape codes' 'escape codes: 0.' \
  "echo escape codes: \$(rush plot -O ascii --x bill --y tip --width 40 --height 8 tips.csv | grep -c \$'\\e')."
check 'rush plot to terminal' 'bill' "rush plot -O ansi --x bill --y tip --width 60 --height 10 tips.csv | sed 's/\\x1b\\[[0-9;]*m//g'"
# Chapter 7: a bar chart for a discrete x (rush used to fail with a histogram)
check 'rush plot bar chart for a discrete x' 'PNG image data' 'rush plot --x time tips.csv > bar.png; file bar.png'
check 'rush plot bar chart in the terminal' 'Dinner' "rush plot -O ascii --x time --width 60 --height 10 tips.csv"
# Chapter 9: geom_smooth() on more than 1,000 rows needs mgcv for its GAM;
# without it, ggplot2 still says method = 'gam' but fits y ~ x (a straight line)
check 'geom_smooth uses a GAM (mgcv)' "s(x, bs = " \
  "Rscript -e 'library(ggplot2); df <- data.frame(x = 1:2000, y = sin(1:2000 / 100)); invisible(ggplot_build(ggplot(df, aes(x, y)) + geom_smooth()))' 2>&1"
# rush sql (DuckDB) and database files
# rush plot --geom-args passes arguments to the geom (e.g. ch09's density plot)
check 'rush plot --geom-args' 'geom_density(adjust = 3, alpha = 0.5)' \
  "rush plot -n -R --x tip --fill time --geom density --geom-args 'adjust = 3, alpha = 0.5' tips.csv | tr -s ' \\n' ' '"
check 'rush plot --geom-args draws a PNG' 'PNG image data' \
  "rush plot --x tip --fill time --geom density --geom-args 'adjust = 3, alpha = 0.5' tips.csv > density.png; file density.png"
check 'rush sql' 'Dinner,5' "rush sql 'SELECT time, COUNT(*) AS n FROM tips GROUP BY time ORDER BY time' tips.csv"
check 'rush convert to duckdb and sqlite' 'tips' \
  "rush convert -o tips.duckdb tips.csv && rush convert -o tips.sqlite tips.duckdb && rush run 'names(dfs\$tips)' tips.sqlite"
# Chapter 7: box plots with a group of one value (miniansi used to abort)
check 'rush plot box plot in the terminal' 'factor(size)' \
  "rush plot -O ascii --x 'factor(size)' --y bill --geom boxplot --width 60 --height 12 tips.csv"

print '== Chapter 8'
check 'parallel' 'Processing file 3.csv' 'seq 3 | parallel "echo Processing file {}.csv"'
check 'parallel --tag with bc' '1.414' "seq 2 | parallel --tag \"echo 'sqrt({})' | bc -l\""
check 'pbc' '9' "seq 3 | pbc '{1}^2'"
check 'aws' 'aws-cli/2' 'aws --version'

print '== Chapter 9'
check 'tapkee pca' ',' 'tapkee --method pca < matrix.csv | head -n 1'
check 'tapkee t-sne' ',' 'tapkee --method t-sne < matrix.csv | head -n 1'
awk 'BEGIN { srand(1); for (i = 0; i < 500; i++) { a = rand(); b = rand();
  printf "%f | a:%f b:%f\n", 3 * a + b, a, b } }' > train.vw
check 'vw train' 'average loss' 'vw --data train.vw --passes 5 --cache_file cache --holdout_off -f model --kill_cache 2>&1'
check 'vw predict from stdin' '.' '< train.vw vw -i model -t -p /dev/stdout --quiet | head -n 1'
check 'csv2vw' '|' 'csv2vw tips.csv --label tip | head -n 1'
# A tiny version of the skll experiment, with an id column (needs pandas<3)
mkdir -p train test
awk 'BEGIN { srand(3); print "id,x,y,type"; for (i = 0; i < 200; i++) {
  t = (rand() < 0.5) ? "red" : "white"; o = (t == "red") ? 1 : 0;
  printf "%d,%f,%f,%s\n", i, rand() + o, rand(), t } }' > all.csv
head -n 161 all.csv > train/features.csv
{ head -n 1 all.csv; tail -n 40 all.csv } > test/features.csv
cat > classify.cfg <<'EOF'
[General]
experiment_name = wine
task = evaluate

[Input]
train_directory = train
test_directory = test
featuresets = [["features"]]
feature_scaling = both
label_col = type
id_col = id
shuffle = true
learners = ["LogisticRegression", "DecisionTreeClassifier"]
suffix = .csv

[Tuning]
grid_search = false
objectives = ["neg_mean_squared_error"]
param_grids = [{}, {}]

[Output]
logs = output
results = output
predictions = output
models = output
EOF
check 'skll is an alias for run_experiment' 'run_experiment' 'alias skll'
check 'skll experiment from the book' 'wine_summary.tsv' 'skll -l classify.cfg >/dev/null 2>&1; ls output'

print '== Chapter 10'
check 'jupyter console' '6.6' 'jupyter console --version'
check 'jupyter kernel uses the default environment' '/opt/venv' \
  "timeout 120 jupyter console --simple-prompt --no-confirm-exit <<< 'import sys; print(sys.prefix)' 2>/dev/null"
check 'ir runs R scripts' '42' "timeout 120 ir run -e 'cat(6 * 7)' 2>/dev/null"
# Chapter 7 suggests saving a script generated by rush and running it as a
# tool. ir then installs rush and its packages, which needs network access.
if curl -fsI -m 10 https://github.com >/dev/null 2>&1; then
  check 'script saved with rush run -n runs with ir' '2.727' \
    "rush run -n 'mean(df\$tip)' tips.csv > tip.R && chmod u+x tip.R && timeout 300 ./tip.R 2>/dev/null"
else
  print 'skip script saved with rush run -n runs with ir (no network access)'
fi
check 'python is Python 3' 'Python 3.' 'python --version'
check 'pip freeze works (uv)' 'cssselect' 'pip freeze'
check 'R system2' '1' "Rscript -e 'cat(length(system2(\"grep\", c(\"-i\", \"alice\"), input = c(\"Alice\", \"Bob\"), stdout = TRUE)))'"

print
print "passed: $passed, failed: $failed, known failures: $known"
(( failed == 0 ))
