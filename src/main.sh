#!/usr/bin/env bash

FILE_PATH=""		# required
MESSAGE=""		  # required
SIZE=""			 # optional max size
COMMAND_ARGS=()	 # store command and its arguments

show_help() {
	cat <<EOF
Usage: $0 [OPTIONS] [COMMAND [ARGS...]]

Options:
  -m, --message MESSAGE   Message to append to the file (required)
  -p, --path FILE         Path to the file (without extension, required)
  -s, --size SIZE         Max file size before rotating (e.g., 1M, 500K, 2G)
  -h, --help              Show a help message

Any arguments after options are treated as a command to execute with its arguments.

Examples:
  $0 -p logs/output -m "Hello World" -s 1M
  $0 --path logs/%Y-%m-%d -m "Log entry %H:%M" -- ls -l
EOF
}

size_to_bytes() {
	local size="$1"
	local number="${size%%[KMG]}"
	local unit="${size##$number}"
	case "$unit" in
		K|k) echo $((number * 1024)) ;;
		M|m) echo $((number * 1024 * 1024)) ;;
		G|g) echo $((number * 1024 * 1024 * 1024)) ;;
		"") echo "$number" ;;
		*) echo "Invalid size: $size" >&2; exit 1 ;;
	esac
}

rotate_log() {
	local file="$1"
	local max_bytes="$2"

	if [[ -f "$file" ]] && [[ $(stat -c%s "$file") -ge $max_bytes ]]; then
		local i=1
		while [[ -f "${file}.${i}" ]]; do
			((i++))
		done
		mv "$file" "${file}.${i}"
	fi
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--message|-m)
			MESSAGE="$2"
			shift 2
			;;
		--path|-p)
			FILE_PATH="$2"
			shift 2
			;;
		--size|-s)
			SIZE="$2"
			shift 2
			;;
		--help|-h)
			show_help
			exit 0
			;;
		--*) 
			echo "Unknown option: $1"
			exit 1
			;;
		*) 
			COMMAND_ARGS=("$@")
			break
			;;
	esac
done

if [[ -z "$FILE_PATH" ]]; then
	echo "Error: --path is required."
	exit 1
fi
if [[ -z "$MESSAGE" ]]; then
	echo "Error: --message is required."
	exit 1
fi

if [[ "$FILE_PATH" == *%* ]]; then
	FILE_PATH_EXPANDED="$(date +"$FILE_PATH")"
else
	FILE_PATH_EXPANDED="$FILE_PATH"
fi

if [[ "$MESSAGE" == *%* ]]; then
	MESSAGE_EXPANDED="$(date +"$MESSAGE")"
else
	MESSAGE_EXPANDED="$MESSAGE"
fi

CMD_OUTPUT=""
if [[ ${#COMMAND_ARGS[@]} -gt 0 ]]; then
	CMD_OUTPUT="$("${COMMAND_ARGS[@]}")"
fi
echo "$CMD_OUTPUT"

if [[ "$MESSAGE_EXPANDED" == *"{nl}"* ]]; then
	MESSAGE_EXPANDED="${MESSAGE_EXPANDED//\{nl\}/$'\n'}"
fi
if [[ "$MESSAGE_EXPANDED" == *"{out}"* ]]; then
	MESSAGE_EXPANDED="${MESSAGE_EXPANDED//\{out\}/$CMD_OUTPUT}"
fi

mkdir -p "$(dirname "$FILE_PATH_EXPANDED")"

if [[ -n "$SIZE" ]]; then
	MAX_BYTES=$(size_to_bytes "$SIZE")
	rotate_log "$FILE_PATH_EXPANDED" "$MAX_BYTES"
fi

echo "$MESSAGE_EXPANDED" >> "$FILE_PATH_EXPANDED"
