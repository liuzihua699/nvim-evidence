# NVIM-EVIDENCE

## Status

The project is under development

## Aim

Knowledge Memory Warehouse

## Reference

[free-spaced-repetition-scheduler](https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler)

## Usage Scene

### Hydra

- a: add

将缓冲区内容添加到数据库

- x: start

初始化FSRS

- d: del

删除当前卡片

- s: switchTable

切换table 

- e: edit

将缓冲区的内容更新到当前卡片里

- i: info

打印当前缓冲区卡片和对应表的详细信息

- q: quality

给当前卡片打分, 二次输入

- f: telescope

开启搜索

### Telescope

- 移动 ctrl+j/k

- 输入框模糊搜索卡片内容

- 将选中卡片内容设置在缓冲区中 enter

## Module Design

Models (FSRS, SqlTable)
Controller
Views (WinBuf, Telescope, Hydra)

## User Interface

```lua
--- 初始化开始
function setup()
end

--- 切换卡组
function switch_table()
end

---修改当前卡片
function add_card()
end

---修改当前卡片
function edit_now_card()
end

---删除当前卡片
function del_now_card()
end

---删除一些卡片
function del_card()
end

---给当前卡片打分
function score_now_card()
end

--- 跳转到下一个卡片
function switch_next_card()
judge_next()
end

--- 根据内容来查找匹配的卡片
function get_cards_by_content()
end

--- 打印当前卡片详细信息
function print_now_card_info()
end
```

## Private Interface

```lua
---将指定卡片作为当前buffer的卡片, 重置卡片上下文
function reset_now_card(card)
end


--- 返回下一个卡片(策略)
function judge_next_card()
  return get_min_due_card()
end

--- 获取最先到期的卡片
---@return Card
function get_min_due_card()
end

--- 获取随机卡片 P3
function get_rand_card()
end

--- 获取新卡片 P3
function get_new_card()
end

--- 打开侧边buffer
function open_split_win()
end
```
