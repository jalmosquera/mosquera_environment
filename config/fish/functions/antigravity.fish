function antigravity --description "Open a directory with the platform file manager"
    set -l target $argv[1]
    if test -z "$target"
        set target .
    end

    if test (uname) = Darwin
        open "$target"
    else if type -q xdg-open
        xdg-open "$target"
    else
        echo "No file manager launcher found for $target" >&2
        return 1
    end
end
