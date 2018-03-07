# shellcheck disable=2148
# shipcat(1) completion

_shipcat()
{
    # shellcheck disable=2034
    local cur prev words cword
    _init_completion || return

    local -r subcommands="help validate generate shell logs graph get
                          list-regions list-services"

    local has_sub
    for (( i=0; i < ${#words[@]}-1; i++ )); do
        if [[ ${words[i]} == @(help|validate|generate|status|shell|logs|get|graph) ]]; then
            has_sub=1
        fi
    done

    # global flags
    if [[ $prev = 'shipcat' && "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W '-v -h -V --version --help' -- "$cur" ) )
        return 0
    fi
    # first subcommand
    if [[ -z "$has_sub" ]]; then
        COMPREPLY=( $(compgen -W "$subcommands" -- "$cur" ) )
        return 0
    fi

    # special subcommand completions
    local special i
    for (( i=0; i < ${#words[@]}-1; i++ )); do
        if [[ ${words[i]} == @(generate|validate|shell|logs|graph|get|list-services) ]]; then
            special=${words[i]}
        fi
    done

    if [[ -n $special ]]; then
        case $special in
            get)
                local -r regions="$(shipcat list-regions)"
                local -r resources="versions ver"
                if [[ $prev = "get" ]]; then
                    COMPREPLY=($(compgen -W "-r --region" -- "$cur"))
                elif [[ $prev == @(-r|--region) ]]; then
                    COMPREPLY=($(compgen -W "$regions" -- "$cur"))
                else
                    COMPREPLY=($(compgen -W "$resources" -- "$cur"))
                fi
                ;;
            list-services)
                local -r regions="$(shipcat list-regions)"
                COMPREPLY=($(compgen -W "$regions" -- "$cur"))
                ;;
            validate|graph)
                local -r regions="$(shipcat list-regions)"
                if [[ $prev = @(graph|validate) ]]; then
                    svcs=$(find "./services" -maxdepth 1 -mindepth 1 -type d -printf "%f " 2> /dev/null)
                    COMPREPLY=($(compgen -W "$svcs -r --region" -- "$cur"))
                elif [[ $prev == @(-r|--region) ]]; then
                    COMPREPLY=($(compgen -W "$regions" -- "$cur"))
                else
                    # Identify which region we used
                    local region i
                    for (( i=2; i < ${#words[@]}-1; i++ )); do
                        if [[ ${words[i]} != -* ]] && echo "$regions" | grep -q "${words[i]}"; then
                            region=${words[i]}
                        fi
                    done
                    local -r svcs="$(shipcat list-services "$region")"
                    COMPREPLY=($(compgen -W "$svcs" -- "$cur"))
                fi
                ;;
            generate)
                if [[ $prev = generate ]]; then
                    COMPREPLY=($(compgen -W "-r --region" -- "$cur"))
                elif [[ $prev == @(-r|--region) ]]; then
                    local -r regions="$(shipcat list-regions)"
                    COMPREPLY=($(compgen -W "$regions" -- "$cur"))
                else
                    svcs=$(find "./services" -maxdepth 1 -mindepth 1 -type d -printf "%f " 2> /dev/null)
                    COMPREPLY=($(compgen -W "$svcs" -- "$cur"))
                fi
                ;;
            shell|logs)
                svcs=$(find "./services" -maxdepth 1 -mindepth 1 -type d -printf "%f " 2> /dev/null)
                if [[ $prev = @(shell|logs) ]]; then
                    COMPREPLY=($(compgen -W "-r --region -p --pod $svcs" -- "$cur"))
                elif [[ $prev == @(-r|--region) ]]; then
                    local -r regions="$(shipcat list-regions)"
                    COMPREPLY=($(compgen -W "$regions" -- "$cur"))
                elif [[ $prev == @(-p|--pod) ]]; then
                    local -r pods="1 2 3 4 5 6"
                    COMPREPLY=($(compgen -W "$pods" -- "$cur"))
                else
                    COMPREPLY=($(compgen -W "$svcs" -- "$cur"))
                fi
                ;;
        esac
    fi

    return 0
} &&
complete -F _shipcat shipcat
