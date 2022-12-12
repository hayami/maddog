```
usage: beatwatch [OPTION]... [--] COMMAND [ARG]...
options:
  --ctrl-fd <N>    If this option is used, <N> is used for control file
                   descriptor number. Using this option without <N>, or
                   this option is not used at all, 3 is used for it.

  --ctrl-log <F>   If this option is used, control log is appended to
                   a file named <F>. Using this option without <F>,
                   "ctrl.log" is used as the file name.

  --debug          Enabe debug mode.

  --on-exit <S>    If this option is used, script <S> is executed by
                   /bin/sh. At the time before the script is executed,
                   the exit status of beatwatch (watchdog) is set to the
                   $? shell variable.

  --help, --usage  Display this help and exit.
```

```mermaid
sequenceDiagram
participant H as httpd, shell<br/>or something<br/>like that
participant C as beatwatch<br/>(cmdline)
participant T as beatwatch<br/>(transient-<br/>watchdog)
participant W as beatwatch<br/>(watchdog)
participant E as beatwatch<br/>(execfunc)
participant M as monitor target

activate H
H --) C: fork()<br/>and<br/>exec()
activate C

C --) T: fork()
activate T

T --) W: daemon()
activate W

T --) C: exit status
deactivate T

W -) C: KILLPID=(pid of watchdog)

W --) E: fork()
activate E
note over E: setpgid(0, 0)
E -) W: KILLPID=(pid of execfunc)


E --) M: execvp()
activate M
deactivate E

loop Repeat 0 or more times
    opt
        M -) W: KILLPID=#35;
    end
    opt
        M -) W: EXIT=#35;
        W -) C: EXIT=#35;
    end
    opt
        M -) W: TIMEOUT=#35;
        W -) C: TIMEOUT=#35; + 5
    end
end
% deactivate C
% deactivate W
% deactivate M
alt
    % activate M
    % activate W
    % activate C
    M -) W: DETACH
    W -) C: DETACH

    C --) H: exit status
    deactivate C

    loop Repeat 0 or more times
        opt
            M -) W: KILLPID=#35;
        end
        opt
            M -) W: EXIT=#35;
        end
        opt
            M -) W: TIMEOUT=#35;
        end
    end
    % deactivate M
    % deactivate W
    alt
        % activate W
        % activate M
        note over M: exit()
        M --) W: exit status
        deactivate M
        note over W: exit()
        deactivate W
    else
        activate W
        activate M
        note over W: Timer expired
        W -) M: SIGTERM
        note over M: exit()
        M --) W: exit status
        deactivate M
        note over W: exit()
        deactivate W
    else
        activate W
        activate M
        note over W: Timer expired
        W -) M: SIGTERM
        W -) M: SIGKILL
        M --) W: exit status
        deactivate M
        note over W: exit()
        deactivate W
    else
        activate W
        activate M
        M -) W: BYE
        note over W: exit()
        deactivate W
        note over M: No longer monitored
    end

    deactivate M
else
    activate M
    activate W
    activate C
    note over M: exit()
    M --) W: exit status
    deactivate M
    note over W: exit()
    W --) C: exit status
    deactivate W
    note over C: exit()
    C --) H: exit status
    deactivate C
else
    activate M
    activate W
    activate C
    note over W: Timer expired
    W -) M: SIGTERM
    note over M: exit()
    M --) W: exit status
    deactivate M
    note over W: exit()
    W --) C: exit status
    deactivate W
    note over C: exit()
    C --) H: exit status
    deactivate C
else
    activate M
    activate W
    activate C
    note over W: Timer expired
    W -) M: SIGTERM
    W -) M: SIGKILL
    M --) W: exit status
    deactivate M
    note over W: exit()
    W --) C: exit status
    deactivate W
    note over C: exit()
    C --) H: exit status
    deactivate C
else
    activate M
    activate W
    activate C
    M -) W: BYE
    note over W: exit()
    note over M: No longer monitored
    W --) C: exit status
    deactivate W
    note over C: exit()
    C --) H: exit status
    deactivate C
    deactivate M
end
deactivate H
```
