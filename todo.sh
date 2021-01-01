#!/bin/bash
#
#Usage:
# todo [COMMANDS] [OPTIONS] [arguments] 
#
#Commands:
#    createlist ListName
#  s|select ListName
#  c|create (-l ListName) SthToDo
# ck|check (ListName)
#  d|done TodoID
#    clear
#    delete TodoID
#    delete ListName
#    list
#    help
#    config [key] [value]
#    editraw
#
#Global Options
# -c /path/to/file
#
#Config:
# undobgcolor
# undocolor
# donebgcolor
# donecolor
#

# Initializing Parameters
i=1
for para_ in ${*}; do
    Para_[$i]=${para_}
    i=$(expr ${i} + 1)
done
unset para_
unset i

COMMANDS=(addlist select add check done clear delete list help config editraw)

MSG_INIT() {
ERROR_MSG[1]="Usage: todo [COMMANDS] [OPTIONS] [arguments]\nTry 'help' for more information."
ERROR_MSG[2]="Unknown Command: ${Para_[1]}\nUse 'help' for a list of commands."
ERROR_MSG[3]="No TODO list has been selected.\nUse 'select' or add '-l' option for selection.\nTry 'help' for more information"
ERROR_MSG[4]="List existed."
ERROR_MSG[5]="List not existed."
ERROR_MSG[6]="Unsupported character.\nList name may only contain alphanumeric characters, hyphens, and underscore."
ERROR_MSG[7]="Blank characters are not supported.\nCheck your input and try again."
ERROR_MSG[8]="Event ${Para_[2]} is not existed or has been finished."

WARN_MSG[1]="It will delete the selected TODO list from the TODOList file.\n       This action is unrecoverable."

HELP_MSG="Usage: todo [COMMANDS] [OPTIONS] [arguments]\n\n\
Commands:\n\
   addlist    ListName        Create a new TODO list and select it\n\
 s|select     ListName        Select a TODO list for further action\n\
 a|add        SthToDo         Add a new event to the selected list\n\
ck|check                      Display all the TODO list in the file\n\
 d|done       TodoID          Sign the event as finished\n\
   clear                      Delete all the finished events in the list\n\
   delete     TodoID          Delete the event by force\n\
   delete                     Delete the TODO list\n\
   list                       Display all the events in the list\n\
   help                       Display this help text and exit\n\
   config [key] [value]\n\
   editraw                    Open the TODOlist file with VIM text editor\n\n\
Global Options\n\
-c /path/to/list\n\
-l ListName\n\n\
Config:\n\
 undobgcolor\n\s
 undocolor\n\
 donebgcolor\n\
 donecolor\n"

CL_MSG="Created a new TODO list named ${Para_[2]}."
SL_MSG="Selected the list named ${Para_[2]}."
AE_MSG="Added a new event in List ${TODO_SELECTED_NOW}.\n${Para_[2]}"
}

# err Code
err() {
    echo -e "\e[31mERROR\e[0m: ${ERROR_MSG[$1]}"
    exit $1
}

# warn Code
warn() {
    echo -en "\e[33mWARN\e[0m:  ${WARN_MSG[$1]}\nDo you want to continue? (y/N)"
    read _check
    echo
    if [[ ${_check} = 'y' || ${_check} = 'Y' ]]; then
        unset _check
        return 0
    else
        unset _check
        return 1
    fi
}

# readVar inParameter inVar
readVar() {
    local inVar=$2
    local inParameter=$1
    for p_ in $(seq ${#Para_[*]}); do
        if [[ ${Para_[${p_}]} = ${inParameter} ]]; then
            export ${inVar}=${Para_[$(expr ${p_} + 1 )]}
            break
        fi
    done
    unset p_s
}

# checkNow inSelected
checkNow() {
    if [[ ${1} = '' ]]; then
        cat ${TODO_LISTS_FILE} | grep -G "^${TODO_SELECTED_NOW}\$" > /dev/null
    else
        cat ${TODO_LISTS_FILE} | grep -G "^${1}\$" > /dev/null
    fi
    return ${?}
}

# addtionalSelect
addtionalSelectCheck() {
    readVar -l AddtionalSelectedList
    if [[ ${AddtionalSelectedList} != '' ]]; then
        checkNow ${AddtionalSelectedList}
        if [[ ${?} == 0 ]]; then
            echo ${AddtionalSelectedList} > ${TODO_SELECTED_FILE}
            TODO_SELECTED_NOW=${AddtionalSelectedList}
            unset AddtionalSelectedList
            return 0
        fi
    else
        unset AddtionalSelectedList
        return 1
    fi
}

# selectCheck
selectCheck() {
    addtionalSelectCheck
    if [[ ${?} != 0 ]]; then
        checkNow
        if [[ ${?} != 0 ]]; then
            if [[ ${TODO_SELECTED_NOW} = '' ]]; then
                err 3
            else
                echo '' > ${TODO_SELECTED_FILE}
                err 5
            fi
        fi
    fi
}

Todo_addlist() {
    checkNow ${Para_[2]}
    if [[ ${?} != 0 ]]; then
        echo ${Para_[2]} | grep -E "^[A-Za-z0-9_-]+\$" > /dev/null
        if [[ ${?} == 0 ]]; then
            echo ${Para_[2]} >> ${TODO_LISTS_FILE}
            echo -e ${CL_MSG}
            echo ${Para_[2]} > ${TODO_SELECTED_FILE}
        else
            err 6
        fi
    else
        err 4
    fi
}
Todo_select() {
    if [[ ${Para_[2]} = '' ]]; then
        selectCheck
        echo -e "Selected a list named ${TODO_SELECTED_NOW}."
    else
        checkNow ${Para_[2]}
        if [[ ${?} == 0 ]]; then
            echo ${Para_[2]} > ${TODO_SELECTED_FILE}
            TODO_SELECTED_NOW=${Para_[2]}
            echo -e ${SL_MSG}
        else
            err 5
        fi
    fi
}
Todo_add() {
    selectCheck
    echo "${TODO_SELECTED_NOW}#\"${Para_[2]}\"" >> ${TODO_LISTS_FILE}
    echo -e ${AE_MSG}
}
Todo_check() {
    # 不能做到Event内容中加入空格
    selectCheck
    local EventList_raw=($(cat ${TODO_LISTS_FILE} | grep -E "^(@)?${TODO_SELECTED_NOW}#"))
#     local EventList_raw=($(cat ${TODO_LISTS_FILE} | grep -E "^(@)?${TODO_SELECTED_NOW}#" | awk -F'#"' '{print $2}' | sed 's/"$//g' | sed 's/"/\\"/g' | awk '{print "\""$0"\""}'| sed 's/\n/\ /g'))
    for i_ in $(seq ${#EventList_raw[*]}); do
        i_=$(expr ${i_} - 1)
        echo ${EventList_raw[$i_]} | grep -E "^@" > /dev/null
        if [[ $? == 0 ]]; then
            echo -en "[ x ]"
        else
            echo -en "[ \e[31m.\e[0m ]"
        fi
        printf " \e[34m%$(expr length ${#EventList_raw[*]})d\e[0m. " ${i_}
        echo ${EventList_raw[$i_]} | awk -F'#"' '{print $2}' | sed 's/"$//g'
    done
    unset i_
}
Todo_done() {
    selectCheck
    local EventList_raw=($(cat ${TODO_LISTS_FILE} | grep -E "^(@)?${TODO_SELECTED_NOW}#"))
    echo ${Para_[2]} | grep -E "^[0-9]+\$" > /dev/null
    local isIDaN=${?}
    echo ${EventList_raw[${Para_[2]}]} | grep -E "^@" > /dev/null
    local isDone=${?}
    if [[ ${isIDaN} != 0 || ${isDone} == 0 || ${EventList_raw[${Para_[2]}]} = '' ]]; then
        err 8
    fi
    # 假如存在同名Event,会被一同清除
    sed "s/^${EventList_raw[${Para_[2]}]}$/@${EventList_raw[${Para_[2]}]}/g" ${TODO_LISTS_FILE} -i
    echo finished
}
Todo_clear() {
    selectCheck
    sed "/^@${TODO_SELECTED_NOW}#/d" ${TODO_LISTS_FILE} -i
    echo finished
}
Todo_delete() {
    selectCheck
    warn 1
    if [[ ${?} == 0 ]]; then
        echo "deleting the selected TODO list '${TODO_SELECTED_NOW}'..."
        sed -E "/^(@)?${TODO_SELECTED_NOW}/d" ${TODO_LISTS_FILE} -i
        echo finished
        echo '' > ${TODO_SELECTED_FILE}
        echo "Selection Clear"
    else
        echo Cancelled
    fi
}
Todo_list() {
    local List_raw=($(cat ${TODO_LISTS_FILE} | grep -E "^[A-Za-z0-9_-]+\$"))
    for i_ in $(seq ${#List_raw[*]}); do
        i_=$(expr ${i_} - 1)
        printf " \e[34m%$(expr length ${#EventList_raw[*]})d\e[0m. " ${i_}
        echo ${List_raw[$i_]}
    done
    unset i_
}
Todo_help() {
    echo -e ${HELP_MSG}
}
# Todo_config() {
# }
Todo_editraw() {
    vim ${TODO_LISTS_FILE}
}

# Initialize
#Checking selected list
ls -a ~ | grep '.todo_now' > /dev/null
if [[ $? != 0 ]]; then
    touch ~/.todo_now
fi
TODO_SELECTED_FILE=~/.todo_now
TODO_SELECTED_NOW=$(cat ${TODO_SELECTED_FILE})

MSG_INIT

# Execute Command
#Checking TODO list file
readVar -c TODO_LISTS_FILE
if [[ ${TODO_LISTS_FILE} = '' ]]; then
    ls -a ~ | grep '.todo_list' > /dev/null
    if [[ $? != 0 ]]; then
        touch ~/.todo_list
    fi
    TODO_LISTS_FILE=~/.todo_list
fi

if [[ ${Para_[1]} = '' ]]; then
    err 1
fi
isCMDDone=0
for cmd_ in ${COMMANDS[*]}; do
    if [[ ${cmd_} = ${Para_[1]} ]]; then
        Todo_${cmd_}
        isCMDDone=1
    fi
done
unset cmd_

# Alias
if [[ ${Para_[1]} = 'a' ]];  then isCMDDone=1; Todo_add; fi
if [[ ${Para_[1]} = 's' ]];  then isCMDDone=1; Todo_select; fi
if [[ ${Para_[1]} = 'ck' ]]; then isCMDDone=1; Todo_check; fi
if [[ ${Para_[1]} = 'd' ]];  then isCMDDone=1; Todo_done; fi

if [[ ${isCMDDone} == 0 ]]; then
    err 2
fi
unset isCMDDone
