module impl {

  export def split_targets [file : string] {
    open $file 
    | lines
    | each {|line| 
        if $line =~ "^#.*" {
          # use first one as separator
          [ $line, (" " + $line) ]
        } else { 
          [ $line ]
        }
      }
    | flatten
    | split list -r "^#.*"
    | each {|target| 
        { name: ($target | get 0 | str trim | str trim -c "#" | str trim )
        , commands: ($target | last (($target | length) - 1) | each {|l| $l | str trim})
        }
      }
  }


  export def call_command [command : string] {
    print ("> " + $command)
    run-external "nu" "-c" $command
    print ""
  }
}

module nuke {
  use impl
  export def run [command : string] {
    impl split_targets "tests/sample.nuke"
    | filter {|target| $target.name == $command }
    | each {|target|
          $target.commands
          | each {|command| impl call_command $command }

        }
    # ignore return value
    | first
    | $in out> /dev/null
    
  }
}

use nuke

use std assert
#[test]
def test_split_targets [] {
  use impl
  print (impl split_targets "tests/sample.nuke")
  let expected = [ {name: "hello_world", commands: ['echo "hello world"', "^ls -l"]}
                 , {name: "install", commands: 
                     [ "# # on the head of the line means target declaration" 
                     , "# these lines are comments" 
                     , "source ./nuke.nu" ]} 
                 ]
  impl split_targets "tests/sample.nuke"
   | assert equal $expected $in
}

#[test]
def test_run [] {
  nuke run "hello_world"
}
