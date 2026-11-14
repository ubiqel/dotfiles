#!/usr/bin/env fish
#
# unused-pkgs.sh - read-only report of installed packages you probably do not use.
#
# This script never modifies the system. It only reads pacman's database,
# pacman.log, filesystem access times and your shell history, then prints a
# shortlist you can review and remove yourself.
#
# pacman has no "used" flag, so the report combines several weak signals:
#
#   orphans         installed as a dependency, nothing requires them (provable)
#   explicit leaves you installed it directly and nothing depends on it
#   access times    when the package's files were last read (relatime)
#   pacman.log      when the package was last installed or upgraded
#   shell history   whether one of the package's binaries was ever run
#
# "upd" means the last access time is just the timestamp of the last package
# upgrade: the files were rewritten, not used. That is the strongest hint that
# a package has gone untouched since the system last touched it.
#

# Documentation, locales, completions, icons and desktop metadata are read by
# the system without the user ever "using" the package, so ignore them.
# Sorting by access time and taking the newest file answers: when was any
# functional part of this package last read?
set -g __up_exclude '^/usr/(share/(doc|man|info|licenses|help|gtk-doc|locale|applications|icons|mime|glib-2\.0|bash-completion|fish|zsh)/|include/)|^/usr/lib/(locale|firmware|modules/[^/]+/build)/|^/var/(cache|log|lib)/'

function __up_usage
    printf '%s\n' \
        'Usage: unused-pkgs.sh [options]' \
        '' \
        'Read-only report of installed packages that look unused. Nothing is removed.' \
        '' \
        'Options:' \
        '  -d, --days N     flag packages not accessed for N days (default: 90)' \
        '      --json       machine-readable output (requires jq)' \
        '      --no-history do not scan shell history for used binaries' \
        '      --no-color   disable colored output' \
        '  -h, --help       show this help' \
        '' \
        'Columns:' \
        '  FLAG      stale     no file read in >= N days' \
        '            upd       files only touched by the last package update (unused)' \
        '            stale+upd both of the above' \
        '            meta      no non-documentation files (metapackage)' \
        '  LAST ACCESS  most recent atime of any non-documentation file' \
        '  UPDATED      last time pacman installed/upgraded the package (pacman.log)' \
        '  AGE          days since LAST ACCESS' \
        '  HIST         y if one of its /usr/bin executables appears in your history' \
        '  SIZE         installed size' \
        '  REPO         local = not in the sync databases (AUR / manually built)'
end

function __up_human -a bytes
    set -l units B KiB MiB GiB TiB
    set -l i 1
    set -l v (math "$bytes + 0")
    while test (math "floor($v / 1024)") -gt 0; and test $i -lt 5
        set v (math "$v / 1024")
        set i (math "$i + 1")
    end
    if test $i -eq 1
        printf '%d %s' (math "floor($v)") $units[$i]
    else
        printf '%.1f %s' $v $units[$i]
    end
end

# Prints "<package><TAB><newest atime>"; used both directly and as the
# per-package worker spawned by xargs below.
function __up_analyze -a pkg
    set -l files (pacman -Qlq $pkg 2>/dev/null \
        | grep -v '/$' \
        | grep -vE $__up_exclude)

    set -l at 0
    if test (count $files) -gt 0
        set at (printf '%s\n' $files \
            | xargs -r -d '\n' -n 200 stat -c '%X' -- 2>/dev/null \
            | sort -n \
            | tail -1)
        test -n "$at"; or set at 0
    end

    printf '%s\t%s\n' $pkg $at
end

# Internal worker mode: unused-pkgs.sh --internal-atime <package>
if set -q argv[1]; and test "$argv[1]" = --internal-atime
    __up_analyze $argv[2]
    exit 0
end

argparse -n (status filename) 'd/days=' json no-history no-color h/help -- $argv
or begin
    __up_usage >&2
    exit 2
end

set -l days 90
if set -q _flag_days
    set days $_flag_days
end
if not string match -qr '^[0-9]+$' -- "$days"
    echo 'error: --days must be a positive integer' >&2
    exit 1
end
if test "$days" -le 0
    echo 'error: --days must be greater than zero' >&2
    exit 1
end

for cmd in pacman expac gawk sort stat xargs nproc grep sed tail
    type -q $cmd; or begin
        echo "error: missing command: $cmd" >&2
        exit 1
    end
end

set -l color 0
if not set -q _flag_no_color
    if isatty stdout
        set color 1
    end
end

set -l now (date +%s)

# ---------------------------------------------------------------------------
# 1. Orphans: installed as a dependency, nothing requires them any more.
# ---------------------------------------------------------------------------
set -l orphans (pacman -Qdtq 2>/dev/null)

set -l orphan_rows
if test (count $orphans) -gt 0
    set orphan_rows (expac '%m\t%n\t%d' $orphans | sort -t\t -k1,1nr)
end

# ---------------------------------------------------------------------------
# 2. Candidates: explicit packages that nothing else depends on.
# ---------------------------------------------------------------------------
set -l leaves (pacman -Qetq 2>/dev/null)
if test (count $leaves) -eq 0
    echo 'error: no explicitly installed leaf packages found' >&2
    exit 1
end

set -l info (expac --timefmt=%s '%m\t%n\t%l\t%d' $leaves)

# Foreign packages are not in any sync database (AUR, manual builds).
set -l foreign (pacman -Qmq 2>/dev/null | sort -u)

# ---------------------------------------------------------------------------
# 3. Last install/upgrade time per package, from pacman.log.
# ---------------------------------------------------------------------------
set -l updated
if test -r /var/log/pacman.log
    set updated (gawk '
        $3 == "installed" || $3 == "upgraded" || $3 == "reinstalled" {
            if ($2 != "[ALPM]") next
            ts = $1
            gsub(/[\[\]]/, "", ts)
            if (length(ts) < 19) next
            e = mktime(substr(ts, 1, 4) " " substr(ts, 6, 2) " " substr(ts, 9, 2) \
                       " " substr(ts, 12, 2) " " substr(ts, 15, 2) " " substr(ts, 18, 2))
            if (e > 0) last[$4] = e
        }
        END { for (p in last) print p "\t" last[p] }
    ' /var/log/pacman.log 2>/dev/null)
end

# ---------------------------------------------------------------------------
# 4. Access times, one worker per package (this is the slow part).
# ---------------------------------------------------------------------------
set -l atimes (printf '%s\n' $leaves \
    | xargs -r -P (nproc) -n 1 fish (status filename) --internal-atime)

# ---------------------------------------------------------------------------
# 5. Shell history: which binaries have actually been run.
# ---------------------------------------------------------------------------
set -l hits
if not set -q _flag_no_history
    set -l hist (begin
        sed -n 's/^ *- cmd: //p' $HOME/.local/share/fish/fish_history 2>/dev/null
        sed -n 's/^: [0-9]*:[0-9]*;//p' $HOME/.zsh_history 2>/dev/null
        cat $HOME/.bash_history 2>/dev/null
    end | gawk '
        {
            i = 1
            while (i <= NF && $i ~ /^(sudo|doas|env|command|nohup|nice|time)$/) i++
            t = $i
            sub(/.*\//, "", t)
            sub(/[;&|].*$/, "", t)
            if (t ~ /^[A-Za-z0-9._+-]+$/) print t
        }
    ' | sort -u)

    set -l execs (pacman -Ql $leaves 2>/dev/null | gawk '
        $2 ~ /^\/usr\/(local\/)?s?bin\/[^\/]+$/ {
            n = $2
            sub(/.*\//, "", n)
            print $1 "\t" n
        }
    ')

    if test (count $hist) -gt 0; and test (count $execs) -gt 0
        set -l hs '@@H'
        set -a hs $hist
        set -a hs '@@E'
        set -a hs $execs
        set hits (printf '%s\n' $hs | gawk -F'\t' '
            $0 == "@@H" { m = "H"; next }
            $0 == "@@E" { m = "E"; next }
            m == "H"   { h[$1] = 1; next }
            m == "E"   { if ($2 in h) print $1 }
        ' | sort -u)
    end
end

# ---------------------------------------------------------------------------
# 6. Merge into one row per package.
#
# Datasets are concatenated into one tagged stream:
#   @@A pkg atime | @@U pkg updated | @@F pkg | @@H pkg | @@I size name installed desc
# ---------------------------------------------------------------------------
set -l stream '@@A'
set -a stream $atimes
set -a stream '@@U'
set -a stream $updated
set -a stream '@@F'
set -a stream $foreign
set -a stream '@@H'
set -a stream $hits
set -a stream '@@I'
set -a stream $info

set -l rows (printf '%s\n' $stream | gawk -F'\t' -v now=$now -v days=$days '
    $0 == "@@A" { m = "A"; next }
    $0 == "@@U" { m = "U"; next }
    $0 == "@@F" { m = "F"; next }
    $0 == "@@H" { m = "H"; next }
    $0 == "@@I" { m = "I"; next }

    m == "A" { a[$1] = $2 + 0; next }
    m == "U" { u[$1] = $2 + 0; next }
    m == "F" { foreign[$1] = 1; next }
    m == "H" { hit[$1] = 1; next }

    m == "I" {
        name = $2
        size = $1 + 0
        inst = $3 + 0
        at   = a[name] + 0
        up   = u[name] + 0

        stale   = (at > 0 && int((now - at) / 86400) >= days)
        updonly = (at > 0 && up > 0 && at <= up + 3600)
        if (at == 0)               flag = "meta"
        else if (stale && updonly) flag = "stale+upd"
        else if (stale)            flag = "stale"
        else if (updonly)          flag = "upd"
        else                       flag = ""

        age = (at > 0) ? int((now - at) / 86400) : -1
        key = (at > 0) ? at : 9999999999

        printf "%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%s\n", \
            key, size, name, flag, age, inst, at, up, \
            (name in foreign) ? "local" : "repo", \
            (name in hit) ? "y" : "-", $4
    }
' | sort -t\t -k1,1n)

# ---------------------------------------------------------------------------
# 7. Output
# ---------------------------------------------------------------------------
if set -q _flag_json
    type -q jq; or begin
        echo 'error: jq is required for --json' >&2
        exit 1
    end
    jq -n \
        --arg generated (date -Iseconds) \
        --argjson days "$days" \
        --arg orphans "$(string collect $orphan_rows)" \
        --arg rows "$(string collect $rows)" '
        def lines($t): $t | split("\n") | map(select(length > 0));
        def iso($s): if $s == "0" then null else ($s | tonumber | todate) end;
        {
            generated: $generated,
            threshold_days: $days,
            orphans: [lines($orphans)[] | split("\t") | {
                name: .[1], size_bytes: (.[0] | tonumber), description: .[2]
            }],
            packages: [lines($rows)[] | split("\t") | {
                name: .[2],
                flag: .[3],
                size_bytes: (.[1] | tonumber),
                age_days: (if .[4] == "-1" then null else (.[4] | tonumber) end),
                installed_at: iso(.[5]),
                last_access: iso(.[6]),
                last_update: iso(.[7]),
                repository: .[8],
                in_shell_history: (.[9] == "y"),
                description: .[10]
            }]
        }'
    exit 0
end

set -l orphan_bytes 0
if test (count $orphan_rows) -gt 0
    set orphan_bytes (printf '%s\n' $orphan_rows | gawk -F'\t' '{ s += $1 } END { print s + 0 }')
end

printf 'Package usage report - %s\n' (date '+%Y-%m-%d %H:%M')
printf 'Read-only. Nothing is removed.\n'
printf 'Explicit packages not required by anything, least recently accessed first.\n'
printf 'Threshold: %s days.  Explicit leaves: %d.\n' $days (count $leaves)

printf '\nORPHANS - installed as a dependency, nothing requires them: %d (%s)\n' \
    (count $orphans) (__up_human $orphan_bytes)
if test (count $orphan_rows) -gt 0
    printf '%s\n' $orphan_rows | gawk -F'\t' '
        function hs(b,  u, i) {
            split("B KiB MiB GiB TiB", u, " ")
            i = 1
            while (b >= 1024 && i < 5) { b /= 1024; i++ }
            return (i == 1) ? sprintf("%d %s", b, u[i]) : sprintf("%.1f %s", b, u[i])
        }
        { printf "  %-34.34s %10s  %s\n", $2, hs($1), $3 }
    '
else
    printf '  none\n'
end

printf '\nEXPLICIT LEAVES\n'

printf '%s\n' $rows | gawk -F'\t' -v color=$color -v days=$days '
    function hs(b,  u, i) {
        split("B KiB MiB GiB TiB", u, " ")
        i = 1
        while (b >= 1024 && i < 5) { b /= 1024; i++ }
        return (i == 1) ? sprintf("%d %s", b, u[i]) : sprintf("%.1f %s", b, u[i])
    }
    {
        row[NR] = $0
        if (length($3) > namew) namew = length($3)
    }
    END {
        if (namew > 34) namew = 34
        printf "  %-9s %-12s %-12s %5s %4s %9s %-5s %-*s %s\n", \
            "FLAG", "LAST ACCESS", "UPDATED", "AGE", "HIST", "SIZE", "REPO", \
            namew, "PACKAGE", "DESCRIPTION"

        for (i = 1; i <= NR; i++) {
            split(row[i], f, "\t")
            flag = f[4]
            at   = f[7] + 0
            up   = f[8] + 0
            age  = f[5] + 0

            stale_n += (flag ~ /^stale/) ? 1 : 0
            stale_sz += (flag ~ /^stale/) ? f[2] : 0
            upd_n   += (flag == "upd" || flag == "stale+upd") ? 1 : 0

            la = (at > 0) ? strftime("%Y-%m-%d", at) : "never"
            ud = (up > 0) ? strftime("%Y-%m-%d", up) : "-"
            ag = (age < 0) ? "-" : age "d"

            fp = sprintf("%-9s", flag)
            if (color) {
                if (flag ~ /^stale/)      c = "\033[31m"
                else if (flag == "upd")   c = "\033[33m"
                else if (flag == "meta")  c = "\033[90m"
                else                      c = ""
                if (c != "") fp = c fp "\033[0m"
            }

            printf "  %s %-12s %-12s %5s %4s %9s %-5s %-*.*s %.*s\n", \
                fp, la, ud, ag, f[10], hs(f[2]), f[9], \
                namew, namew, f[3], 58, f[11]
        }

        printf "\n"
        printf "  not accessed >= %s days: %d package(s), %s\n", days, stale_n, hs(stale_sz)
        printf "  no access since last update: %d package(s)\n", upd_n
    }
'

printf '\nNotes\n'
printf '  * "upd" = atime matches the last upgrade, so the files were rewritten, not read.\n'
printf '  * atimes come from the filesystem (relatime, day granularity); noatime breaks them.\n'
printf '  * backups and indexers that read files bump atimes, which can mask old packages.\n'
printf '  * HIST is only a hint: history is trimmed, aliases and GUI launches are invisible.\n'
printf '  * Nothing was removed. Review the list, then for example:\n'
if test (count $orphans) -gt 0
    printf '      sudo pacman -Rns %s\n' (string join ' ' $orphans)
end
printf '      paccache -r          # trim the package cache\n'
printf '      lostfiles            # files left behind by removed packages\n'
