 

## A Simple TO-DO List

> 一个使用Bash脚本实现的简单 TO-DO List App

### First Time

下载Git目录中的[todo.sh](https://github.com/arxim-lab/A_Simple_Todo_list/raw/main/todo.sh)文件，放置到任意文件夹下。

> 需要一个支持Bash的环境来运行这个脚本文件，比如任意的Linux发行版、MacOS、WSL、Git Bash等。
> 
> ~~尚未测试Windows PowerShell对脚本的兼容性~~

从Github中下载脚本的用户可执行`install`指令将脚本安装到系统目录，使用`uninstall`指令卸载脚本

```bash
wget https://github.com/arxim-lab/A_Simple_Todo_list/raw/main/todo.sh | sudo ./todo.sh install
```

安装完成后可直接使用`todo`操作

```bash
todo addlist first_list
todo add first_event
todo check
```

### Usage

可通过`help`指令查看帮助信息

##### 指令列表

- `addlist (ListName)` 添加一个名为ListName的TO-DO list，默认名为Default

  list名称只能包含大小写英文字母、数字、英文短横线`-`以及英文下划线`_`！

- `select (ListName)` (快捷指令:`s`) 选择名为ListName的TO-DO list

  在对TO-DO list内事件的操作前必须先进行选择操作，可单独使用`select`或`s`查看当前选中的list

- `add SthToDo` (快捷指令:`a`) 在当前list内添加一条事件，内容为SthToDo

- `check` (快捷指令:`c`) 查看当前list内所有的事件

- `done TodoID` (快捷指令:`d`) 标记当前list内ID为TodoID的事件为已完成

  TodoID为执行check指令后对应事件前标注的数字

- `undo TodoID` (快捷指令:`u`) 标记当前list内ID为TodoID的事件为未完成

- `clear (ListName)` 彻底删除当前list内所有已完成的事件，可附加ListName指定list
- `delete` 彻底删除已选中的整个list
- `delete TodoID` 删除当前list内ID为TodoID的事件
- `list` (快捷指令:`l`)查看本地保存的所有list
- `editraw` 使用系统编辑器打开数据文件 (手动编辑)
- `backup (/path/to/file)`  将数据文件备份到指定位置，默认为~/TODO_LIST.bak
- `recover /path/to/file` 从指定位置恢复数据文件
- `help` (快捷指令:`h`) 查看该帮助信息
- `uninstall` 卸载该脚本并删除数据文件 (仅限shell安装)

> 推荐搭配Yakuake使用，效果更佳。

### Screenshots

![Screenshot 1](./src/screenshot-1.png)

![Screenshot](./src/screenshot-2.png)

![Screenshot](./src/screenshot-3.png)

### Known Issues

`2020.1.2`

目前已知的程序中存在的 ~~features~~ BUGS :

- 事件内容不能包含空格，否则会导致事件录入错误或显示错误
- 假如list中存在同名事件，clear时会被一并清除
- 事件添加操作add目前还不能检查输入合法性

### TO-DOs

- [ ] 添加新功能：事件执行倒计时&执行时限（Deadline）以及提醒功能
- [ ] 添加新功能：config
- [ ] 丰富显示效果
- [ ] 修复BUG：事件内容不能包含空格
- [ ] 修复BUG：同名事件会被删除
- [ ] 修复BUG：add输入合法性

### Update Information

- v0.0.1_20200102 - First Version
  - 第一个版本

- v0.1.1_20200102 - Fix
  - 修正了脚本帮助信息
  - 修正了check的快捷指令为c
  - 完善了delete、clear功能
  - 添加了undo、install、uninstall、backup、recover等功能
  - 无指令给派时默认执行check操作