module nuke {
  export def split_targets [file : string] {
    open $file 
    | lines
    | each {|line| 
        if $line =~ "^#.*" {
          # use first one as separator
          [ $line, (" " + $line) ]
        } else { 
          [($line | str trim)]
        }
      }
    | flatten
    | split list -r "^#.*"
    | each {|target| 
        { name: ($target | get 0 | str trim | str trim -c "#" | str trim )
        , commands: ($target | last (($target | length) - 1))
        }
      }
  }

  export def run [command : string] {
    split_targets "sample.nuke"
    | filter {|target| $target.name == $command }
    | each {|target|
          $target.commands
          | each {|command| call_command $command }

        }
    | first
    
  }

  export def call_command [command : string] {
    run-external "nu" "-c" $command
  }
}

use nuke
