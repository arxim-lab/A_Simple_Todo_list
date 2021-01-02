#!/bin/bash
echo -e "\e[32mINFO\e[0m:  This application has not been installed.\n       Try 'install' for installation."
if [[ ${1} = 'install' ]]; then
    cp ${0} ./.todo_exec;
    sed '2,13d' ./.todo_exec -i
    sed '/^COMMANDS=/d' ./.todo_exec -i
    sed 's/^##@onekeysignal#&//g' ./.todo_exec -i
    sudo cp ./.todo_exec /usr/bin/todo
    rm ./.todo_exec
    sudo chmod +x /usr/bin/todo
    echo Installed to /usr/bin/todo
    exit
fi
#
#Usage:
# todo [COMMANDS] [OPTIONS] [arguments] 
#
#Commands:
#    addlist    ListName
#  s|select     (ListName)
#  a|add        SthToDo
#  c|check      (ListName)
#  d|done       TodoID
#  u|undo       TodoID
#    clear      (ListName)
#  d|delete     TodoID
#    delete
#  l|list
#  h|help
#    config [key] [value]
#    editraw
#    backup     (FilePath)
#    recover    FilePath
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

COMMANDS=(addlist select add check done undo clear delete list help editraw backup recover)
##@onekeysignal#&COMMANDS=(addlist select add check done undo clear delete list help editraw backup recover uninstall)

MSG_INIT() {

ERROR_MSG[2]="Unknown Command: ${Para_[1]}\nUse 'help' for a list of commands."
ERROR_MSG[3]="No TODO list has been selected.\nUse 'select' or add '-l' option for selection.\nTry 'help' for more information"
ERROR_MSG[4]="List $([[ ${Para_[2]} != '' ]] && echo ${Para_[2]} || echo 'Default') is existed."
ERROR_MSG[5]="List $([[ ${Para_[2]} != '' ]] && echo ${Para_[2]} || echo 'Default') is not existed."
ERROR_MSG[6]="Unsupported character.\nList name may only contain alphanumeric characters, hyphens, and underscore."
ERROR_MSG[7]="Blank characters are not supported.\nCheck your input and try again."
ERROR_MSG[8]="Event ${Para_[2]} is not existed or has been finished."
ERROR_MSG[9]="Event ${Para_[2]} is not existed or unfinished."
ERROR_MSG[10]="Event ${Para_[2]} is not existed."
ERROR_MSG[11]="This event is empty."
ERROR_MSG[12]="FilePath is necessary when you perform recover operation."

WARN_MSG[1]="It will delete the selected TODO list from the TODOList file.\n       This action is unrecoverable."
WARN_MSG[2]="It will remove all the data on the existed data file.\n       This action is unrecoverable."

HELP_MSG="Usage: todo [COMMANDS] [OPTIONS] [arguments]\n\n\
Commands:\n\
 addlist\t(ListName)\tCreate a new TODO list and select it\n\
 s|select\t(ListName)\tSelect a TODO list for further action\n\
 a|add\t\tSthToDo\t\tAdd a new event to the selected list\n\
 c|check\t(ListName)\tDisplay all the events in the list or the list offered\n\
 d|done\t\tTodoID\t\tSign the event as finished\n\
 u|undo\t\tTodoID\t\tSign the event as unfinished\n\
 clear\t\t(ListName)\tDelete all the finished events in the list or the list offered\n\
 delete\t\tTodoID\t\tDelete the event by force\n\
 delete\t\t\t\tDelete the TODO list\n\
 l|list\t\t\t\tDisplay all the TODO list in the file\n\
 h|help\t\t\t\tDisplay this help text and exit\n\
 editraw\t\t\tOpen the TODOlist file with VIM text editor\n\
 backup\t\t(FilePath)\tBackup the data file to filepath or ~/TODO_List.bak\n\
 recover\tFilePath\tRecover the data file from filepath\n\n\
"

CL_MSG="Created a new TODO list named $([[ ${Para_[2]} != '' ]] && echo ${Para_[2]} || echo 'Default')."
SL_MSG="Selected the list named $([[ ${Para_[2]} != '' ]] && echo ${Para_[2]} || echo ${TODO_SELECTED_NOW})."
AE_MSG="Added a new event in List ${TODO_SELECTED_NOW}.\n${Para_[2]}"
BK_MSG="Data file has been copied to $([[ ${Para_[2]} != '' ]] && echo ${Para_[2]} || echo ~/TODO_LIST.bak)."
RC_MSG="Data file has been recovered."
}

# err Code
err() {
    if [[ ${1} != 1 ]]; then
        echo -e "\e[31mERROR\e[0m: ${ERROR_MSG[$1]}"
    else
        echo -e ${ERROR_MSG[$1]}
    fi
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

# checkNow inSelected
checkNow() {
    if [[ ${1} = '' ]]; then
        cat ${TODO_LISTS_FILE} | grep -G "^${TODO_SELECTED_NOW}\$" > /dev/null
    else
        cat ${TODO_LISTS_FILE} | grep -G "^${1}\$" > /dev/null
    fi
    return ${?}
}

# selectCheck
selectCheck() {
    checkNow
    if [[ ${?} != 0 ]]; then
        if [[ ${TODO_SELECTED_NOW} = '' ]]; then
            err 3
        else
            echo '' > ${TODO_SELECTED_FILE}
            err 5
        fi
    fi
}

Todo_addlist() {
    checkNow ${Para_[2]}
    if [[ ${?} != 0 && ${Para_[2]} != '' ]]; then
        echo ${Para_[2]} | grep -E "^[A-Za-z0-9_-]+\$" > /dev/null
        if [[ ${?} == 0 ]]; then
            echo ${Para_[2]} >> ${TODO_LISTS_FILE}
            echo -e ${CL_MSG}
            echo ${Para_[2]} > ${TODO_SELECTED_FILE}
        else
            err 6
        fi
    elif [[ ${Para_[2]} = '' ]]; then
        checkNow 'Default'
        if [[ ${?} != 0 ]]; then
            echo 'Default' >> ${TODO_LISTS_FILE}
            echo -e ${CL_MSG}
            echo 'Default' > ${TODO_SELECTED_FILE}
        else
            err 4
        fi
    else
        err 4
    fi
}
Todo_select() {
    if [[ ${Para_[2]} = '' ]]; then
        selectCheck
    else
        checkNow ${Para_[2]}
        if [[ ${?} == 0 ]]; then
            echo ${Para_[2]} > ${TODO_SELECTED_FILE}
            TODO_SELECTED_NOW=${Para_[2]}
        else
            err 5
        fi
    fi
    echo -e ${SL_MSG}
}
Todo_add() {
    selectCheck
    # 无法进行输入验证
    if [[ ${Para_[2]} = '' ]]; then err 11; fi
    echo "${TODO_SELECTED_NOW}#\"${Para_[2]}\"" >> ${TODO_LISTS_FILE}
    echo -e ${AE_MSG}
}
Todo_check() {
#     local EventList_raw=($(cat ${TODO_LISTS_FILE} | grep -E "^(@)?${TODO_SELECTED_NOW}#" | awk -F'#"' '{print $2}' | sed 's/"$//g' | sed 's/"/\\"/g' | awk '{print "\""$0"\""}'| sed 's/\n/\ /g'))
    # 不能做到Event内容中加入空格
    if [[ ${Para_[2]} = '' ]]; then
        selectCheck
    else
        checkNow ${Para_[2]}
        if [[ ${?} == 0 ]]; then
            echo ${Para_[2]} > ${TODO_SELECTED_FILE}
            TODO_SELECTED_NOW=${Para_[2]}
        else
            err 5
        fi
    fi
    local EventList_raw=($(cat ${TODO_LISTS_FILE} | grep -E "^(@)?${TODO_SELECTED_NOW}#"))
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
    # 假如存在同名Event,会被一同done
    sed "s/^${EventList_raw[${Para_[2]}]}$/@${EventList_raw[${Para_[2]}]}/g" ${TODO_LISTS_FILE} -i
    echo Finished
}
Todo_undo() {
    # Undo存在与Done同样的问题
    selectCheck
    local EventList_raw=($(cat ${TODO_LISTS_FILE} | grep -E "^(@)?${TODO_SELECTED_NOW}#"))
    echo ${Para_[2]} | grep -E "^[0-9]+\$" > /dev/null
    local isIDaN=${?}
    echo ${EventList_raw[${Para_[2]}]} | grep -E "^@" > /dev/null
    local isDone=${?}
    if [[ ${isIDaN} != 0 || ${isDone} == 1 || ${EventList_raw[${Para_[2]}]} = '' ]]; then
        err 9
    fi
    # 假如存在同名Event,会被一同Undo
    sed "s/^${EventList_raw[${Para_[2]}]}$/${EventList_raw[${Para_[2]}]#@}/g" ${TODO_LISTS_FILE} -i
    echo Finished
}
Todo_clear() {
    if [[ ${Para_[2]} = '' ]]; then
        selectCheck
    else
        checkNow ${Para_[2]}
        if [[ ${?} == 0 ]]; then
            echo ${Para_[2]} > ${TODO_SELECTED_FILE}
            TODO_SELECTED_NOW=${Para_[2]}
        else
            err 5
        fi
    fi
    sed "/^@${TODO_SELECTED_NOW}#/d" ${TODO_LISTS_FILE} -i
    echo Finished
}
Todo_delete() {
    selectCheck
    if [[ ${Para_[2]} != '' ]]; then
        local EventList_raw=($(cat ${TODO_LISTS_FILE} | grep -E "^(@)?${TODO_SELECTED_NOW}#"))
        echo ${Para_[2]} | grep -E "^[0-9]+\$" > /dev/null
        if [[ ${?} == 0 && ${EventList_raw[${Para_[2]}]} != '' ]]; then
            sed -E "/^${EventList_raw[${Para_[2]}]}$/d" ${TODO_LISTS_FILE} -i
            return
        else
            err 10
        fi
    fi
    warn 1
    if [[ ${?} == 0 ]]; then
        echo "deleting the selected TODO list '${TODO_SELECTED_NOW}'..."
        sed -E "/^(@)?${TODO_SELECTED_NOW}/d" ${TODO_LISTS_FILE} -i
        echo Finished
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
    if [[ $? != 0 ]]; then nano ${TODO_LISTS_FILE}; fi
    if [[ $? != 0 ]]; then vi ${TODO_LISTS_FILE}; fi
}
Todo_backup() {
    if [[ ${Para_[2]} = '' ]]; then
        cp ${TODO_LISTS_FILE} ~/TODO_LIST.bak
    else
        cp ${TODO_LISTS_FILE} ${Para_[2]}
    fi
    echo -e ${BK_MSG}
}
Todo_recover() {
    if [[ ${Para_[2]} = '' ]]; then
        err 12
    else
        warn 1
        if [[ ${?} == 0 ]]; then
            cp ${Para_[2]} ${TODO_LISTS_FILE}
            echo -e ${RC_MSG}
        else
            echo Cancelled
        fi
    fi
}
##@onekeysignal#&Todo_uninstall() {
##@onekeysignal#&    sudo rm /usr/bin/todo
##@onekeysignal#&    rm ${TODO_LISTS_FILE}
##@onekeysignal#&    rm ${TODO_SELECTED_FILE}
##@onekeysignal#&}

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
if [[ ${TODO_LISTS_FILE} = '' ]]; then
    ls -a ~ | grep '.todo_list' > /dev/null
    if [[ $? != 0 ]]; then
        touch ~/.todo_list
    fi
    TODO_LISTS_FILE=~/.todo_list
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
if [[ ${Para_[1]} = 'a' ]]; then isCMDDone=1; Todo_add; fi
if [[ ${Para_[1]} = 's' ]]; then isCMDDone=1; Todo_select; fi
if [[ ${Para_[1]} = 'c' ]]; then isCMDDone=1; Todo_check; fi
if [[ ${Para_[1]} = 'd' ]]; then isCMDDone=1; Todo_done; fi
if [[ ${Para_[1]} = 'u' ]]; then isCMDDone=1; Todo_undo; fi
if [[ ${Para_[1]} = 'l' ]]; then isCMDDone=1; Todo_list; fi
if [[ ${Para_[1]} = 'h' ]]; then isCMDDone=1; Todo_help; fi

if [[ ${isCMDDone} == 0 ]]; then Todo_check; fi

unset isCMDDone
