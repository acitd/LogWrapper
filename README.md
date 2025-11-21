# LogWrapper

LogWrapper is a utility that lets you run commands while seamlessly appending messages to log files. It also supports optional file rotation based on size and date formatting.


## Features

- Append messages to any file with ease.
- Automatically rotate log files when they exceed a defined size.
- Supports date formatting in file paths and messages (using `date` syntax).
- Optionally execute commands with arguments after logging.
- Lightweight and easy to use.

## Installation

Clone this repository:

```bash
git clone https://github.com/yourusername/LogWrapper.git
cd LogWrapper
chmod +x src/main.sh
# Copy src/main.sh anywhere you like and rename it to logwrapper.
# For example:
cp src/main.sh ~/.local/bin/logwrapper
````

## Usage

```bash
logwrapper [OPTIONS] [COMMAND [ARGS...]]
```

### Options

| Option          | Description                                              |
| --------------- | -------------------------------------------------------- |
| `-m, --message` | Message to append to the file (required)                 |
| `-p, --path`    | Path to the file (required)           |
| `-s, --size`    | Max file size before rotating (e.g., `1M`, `500K`, `2G`) |
| `-h, --help`    | Show this help message and exit                          |

### Examples

Log a message with max file size rotation:

```bash
logwrapper -p ~/.local/share/log/logwrapper/hello-world/test.log -m "Hello World" -s 1M
```

Log a message with date formatting and run a command:

```bash
logwrapper --path ~/.local/share/log/logwrapper/hello-world/%Y-%m.log -m "Message at %H:%M{nl}Hello World" ls -l
```

## How It Works

1. **Date Formatting:** You can use `date` placeholders like `%Y-%m-%d` or `%H:%M` in both file paths and messages.
2. **File Rotation:** If the log file exceeds the specified size, it is renamed with a numeric suffix, and a new log file is created.
3. **Command Execution:** Any arguments after options are treated as a command to execute after logging.
4. **Message Placeholders:**
   * `{out}` replaced with the output of the executed command.
   * `{nl}`  replaced with an actual newline in the log message.

## Contributing

Feel free to fork, open issues, or submit pull requests.

## Author

Alex Costantino - [acitd.com](https://www.acitd.com/)

[Read the article](https://www.acitd.com/article/25/logwrapper)

